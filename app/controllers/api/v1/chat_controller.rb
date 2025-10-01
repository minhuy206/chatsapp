module Api
  module V1
    class ChatController < ApplicationController
      include ActionController::Live

      # POST /api/v1/chat
      # Body: { message: "...", model: "gpt-4-turbo", conversation_id: 123 (optional) }
      def create
        response.headers['Content-Type'] = 'text/event-stream'
        response.headers['Cache-Control'] = 'no-cache'
        response.headers['X-Accel-Buffering'] = 'no'

        user_message = params[:message]
        model_name = params[:model] || 'gpt-4-turbo'
        conversation_id = params[:conversation_id]
        system_prompt = params[:system_prompt]

        # Find or create conversation
        conversation = if conversation_id
          Conversation.find(conversation_id)
        else
          Conversation.create!(user_identifier: current_user_identifier)
        end

        # Add system message if provided
        if system_prompt && conversation.messages.where(role: 'system').empty?
          conversation.messages.create!(role: 'system', content: system_prompt)
        end

        # Create user message
        conversation.messages.create!(role: 'user', content: user_message)

        # Send metadata
        sse_write({
          type: 'metadata',
          conversation_id: conversation.id,
          model: model_name
        })

        # Stream response
        stream_response(conversation, model_name)

      rescue StandardError => e
        Rails.logger.error("Chat error: #{e.message}")
        sse_write({ type: 'error', error: e.message })
      ensure
        response.stream.close
      end

      private

      def stream_response(conversation, model_name)
        accumulated_content = ""
        start_time = Time.current

        # Get conversation history
        history = conversation.history.map { |msg|
          { role: msg.role, content: msg.content }
        }

        # Stream from LLM using factory
        llm_service = Llm::Factory.for(model_name)
        llm_service.stream_completion(
          messages: history,
          model: model_name
        ) do |token|
          accumulated_content += token
          sse_write({ type: 'token', token: token, done: false })
        end

        latency_ms = ((Time.current - start_time) * 1000).round(2)

        # Save assistant response
        conversation.messages.create!(
          role: 'assistant',
          content: accumulated_content,
          model_used: model_name
        )

        # Send completion
        sse_write({ type: 'token', token: '', done: true, latency_ms: latency_ms })
        sse_write({ type: 'done' })
      end

      def sse_write(data)
        response.stream.write("data: #{data.to_json}\n\n")
      end
    end
  end
end