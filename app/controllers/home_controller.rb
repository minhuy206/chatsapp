class HomeController < ApplicationController
  def index
    @conversations = Conversation.recent.includes(:messages).limit(20)
    @ai_models = Conversation.ai_models
    @current_conversation = nil
  end

  def create
    @conversation = Conversation.create!(
      title: params[:content]&.truncate(50) || "New Chat",
      ai_model: params[:ai_model] || "gpt-4o"
    )

    @message = @conversation.messages.create!(
      content: params[:content],
      role: "user"
    )

    # Queue AI response job
    AiResponseJob.perform_later(@conversation.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("conversation-list", partial: "shared/conversation_item", locals: { conversation: @conversation, current: false }),
          turbo_stream.replace("main-chat-area", partial: "shared/conversation_view", locals: { conversation: @conversation, message: @message }),
          turbo_stream.append("chat-messages", partial: "shared/ai_thinking")
        ]
      end
      format.html { redirect_to root_path }
    end
  rescue => e
    Rails.logger.error "Failed to create conversation: #{e.message}"
    respond_to do |format|
      format.turbo_stream { head :unprocessable_content }
      format.html { redirect_to root_path, alert: "Failed to send message" }
    end
  end
end
