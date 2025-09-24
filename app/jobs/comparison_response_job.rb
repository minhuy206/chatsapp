class ComparisonResponseJob < ApplicationJob
  queue_as :default

  def perform(conversation_id, user_message_id)
    conversation = Conversation.find(conversation_id)
    user_message = Message.find(user_message_id)

    return unless conversation.comparison_mode?

    # Get conversation history for context
    conversation_history = conversation.messages.by_creation_order.limit(50)

    # Generate responses from both models in parallel
    responses = generate_parallel_responses(conversation, conversation_history)

    # Create response messages
    create_response_messages(conversation, responses)

    # Update UI via Turbo Streams
    broadcast_comparison_responses(conversation, responses)
  rescue => e
    Rails.logger.error "Comparison response job failed: #{e.message}"
    broadcast_error(conversation_id)
  end

  private

  def generate_parallel_responses(conversation, conversation_history)
    model_a_future = Concurrent::Future.execute { generate_model_response(conversation.model_a, conversation_history) }
    model_b_future = Concurrent::Future.execute { generate_model_response(conversation.model_b, conversation_history) }

    {
      model_a: { model: conversation.model_a, content: model_a_future.value },
      model_b: { model: conversation.model_b, content: model_b_future.value }
    }
  end

  def generate_model_response(model, conversation_history)
    service = AiServiceFactory.create(model)
    service.generate_response(conversation_history)
  rescue => e
    Rails.logger.error "Failed to generate response for #{model}: #{e.message}"
    "I apologize, but I encountered an error generating a response. Please try again."
  end

  def create_response_messages(conversation, responses)
    responses.each do |side, response_data|
      conversation.messages.create!(
        content: response_data[:content],
        role: "assistant",
        model_version: response_data[:model]
      )
    end
  end

  def broadcast_comparison_responses(conversation, responses)
    # Remove thinking indicator
    Turbo::StreamsChannel.broadcast_remove_to(
      "comparison_#{conversation.id}",
      target: "comparison-thinking"
    )

    # Add both responses
    responses.each_with_index do |(side, response_data), index|
      message = conversation.messages.where(model_version: response_data[:model]).last

      Turbo::StreamsChannel.broadcast_append_to(
        "comparison_#{conversation.id}",
        target: "comparison-messages",
        partial: "shared/comparison_response",
        locals: {
          message: message,
          conversation: conversation,
          side: side,
          model: response_data[:model]
        }
      )
    end

    # Add voting interface
    user_message = conversation.messages.user_messages.last
    Turbo::StreamsChannel.broadcast_append_to(
      "comparison_#{conversation.id}",
      target: "comparison-messages",
      partial: "shared/comparison_voting",
      locals: { message: user_message, conversation: conversation }
    )
  end

  def broadcast_error(conversation_id)
    Turbo::StreamsChannel.broadcast_replace_to(
      "comparison_#{conversation_id}",
      target: "comparison-thinking",
      partial: "shared/comparison_error"
    )
  end
end