class ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show, :destroy ]

  def index
    @conversations = Conversation.recent.includes(:messages)
    @ai_models = Conversation.ai_models
  end

  def show
    @messages = @conversation.messages.by_creation_order
    @message = Message.new
  end

  def new
    @conversation = Conversation.new
    @ai_models = Conversation.ai_models
  end

  def create
    @conversation = Conversation.new(conversation_params)
    @conversation.title = generate_title if @conversation.title.blank?

    if @conversation.save
      redirect_to @conversation, notice: "Conversation was successfully created."
    else
      @ai_models = Conversation.ai_models
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_url, notice: "Conversation was successfully deleted."
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:title, :ai_model)
  end

  def generate_title
    "Chat with #{@conversation.ai_model_display_name} - #{Time.current.strftime('%m/%d %I:%M %p')}"
  end
end
