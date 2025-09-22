class AiResponseJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    LoggerHelper.log_info(
      message: "Starting AI response generation",
      context: { conversation_id: conversation_id, job_id: job_id }
    )

    start_time = Time.current

    begin
      # Get the conversation
      conversation = Conversation.find(conversation_id)

      # Get the conversation history for context
      conversation_history = conversation.messages.by_creation_order

      # Get the appropriate AI service
      ai_service = AiServiceFactory.build(conversation.ai_model)

      # Generate the AI response with logging
      ai_response_content = LoggerHelper.benchmark(
        operation_name: "ai_service_chat",
        service: conversation.ai_model,
        conversation_id: conversation_id,
        message_count: conversation_history.count
      ) do
        ai_service.chat(conversation_history)
      end

      # Log AI interaction details
      LoggerHelper.log_ai_interaction(
        service: conversation.ai_model,
        action: "generate_response",
        duration: ((Time.current - start_time) * 1000).round(2),
        conversation_id: conversation_id,
        message_count: conversation_history.count,
        response_length: ai_response_content&.length
      )

      # Create the assistant's response message
      assistant_message = conversation.messages.create!(
        content: ai_response_content,
        role: "assistant"
      )

      # Update conversation timestamp
      conversation.touch

      # Broadcast the new message via Turbo Streams
      broadcast_new_message(conversation, assistant_message)

      LoggerHelper.log_info(
        message: "AI response generated successfully",
        context: {
          conversation_id: conversation_id,
          message_id: assistant_message.id,
          response_length: ai_response_content.length,
          duration_ms: ((Time.current - start_time) * 1000).round(2)
        }
      )

    rescue StandardError => e
      # Use centralized AI error handler for all provider-specific logic
      error_context = {
        job: self.class.name,
        conversation_id: conversation_id,
        job_id: job_id,
        duration_ms: ((Time.current - start_time) * 1000).round(2),
        ai_model: conversation&.ai_model,
        message_count: conversation_history&.count
      }

      AiErrorHandler.handle_error(e, error_context)

      Rails.logger.error "AI Response Job failed: #{e.message}"
      Rails.logger.error "Full backtrace: #{e.backtrace.join("\n")}"

      # Create an error message for the user
      error_message = conversation.messages.create!(
        content: "I apologize, but I'm experiencing technical difficulties right now. Please try again in a moment.",
        role: "assistant"
      )

      # Broadcast the error message
      broadcast_new_message(conversation, error_message)
    end
  ensure
    # Remove typing indicator
    broadcast_remove_typing_indicator(conversation)
  end

  private

  def broadcast_new_message(conversation, message)
    # Use Turbo Streams to add the message to the home page chat in real-time
    Turbo::StreamsChannel.broadcast_replace_to(
      "home_chat",
      target: "ai-thinking",
      partial: "shared/message",
      locals: { message: message, ai_model: conversation.ai_model }
    )
  end

  def broadcast_remove_typing_indicator(conversation)
    # Remove the typing indicator
    Turbo::StreamsChannel.broadcast_remove_to(
      "home_chat",
      target: "ai-thinking"
    )
  end
end
