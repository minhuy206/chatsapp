class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params)
    @message.role = "user"

    if @message.save
      AiResponseJob.perform_later(@conversation, @message)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message-form", partial: "messages/form", locals: { conversation: @conversation, message: @message }) }
        format.html { redirect_to @conversation, alert: "Failed to send message." }
      end
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
