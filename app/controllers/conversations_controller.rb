class ConversationsController < ApplicationController
  before_action :set_conversation, only: [ :show, :destroy, :quick_show, :update_title ]

  def index
    @conversations = Conversation.recent.includes(:messages).limit(50)
    @ai_models = Conversation.ai_models
    @current_conversation = nil
  end

  def show
    @conversations = Conversation.recent.includes(:messages).limit(20)
    @messages = @conversation.messages.by_creation_order
    @message = Message.new
    @current_conversation = @conversation
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

  # AJAX endpoint for sidebar conversation loading
  def quick_show
    @messages = @conversation.messages.by_creation_order
    @message = Message.new

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("main-chat-area", partial: "shared/conversation_view", locals: {
            conversation: @conversation,
            messages: @messages,
            message: @message
          }),
          turbo_stream.update("current-conversation-title", @conversation.title)
        ]
      end
    end
  end

  def update_title
    if @conversation.update(title: params[:title])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "conversation-title-#{@conversation.id}",
            partial: "shared/conversation_title",
            locals: { conversation: @conversation }
          )
        end
      end
    else
      head :unprocessable_entity
    end
  end

  def destroy
    conversation_title = @conversation.title

    # Simple security check - in a real app you'd have proper user authentication
    # For now we'll assume all conversations can be deleted but log the action
    Rails.logger.info "Deleting conversation: #{@conversation.id} - '#{conversation_title}'"

    if @conversation.destroy
      respond_to do |format|
        format.turbo_stream do
          # Remove conversation from sidebar
          streams = [ turbo_stream.remove("conversation-item-#{@conversation.id}") ]

          # Handle main chat area based on context
          remaining_conversations = Conversation.recent.includes(:messages).limit(1)

          if remaining_conversations.any?
            # If there are other conversations, optionally load the most recent one
            # For now, just show empty chat
            streams << turbo_stream.replace("main-chat-area", partial: "shared/empty_chat")
          else
            # No conversations left, show empty state
            streams << turbo_stream.replace("main-chat-area", partial: "shared/empty_chat")
          end

          # Update the page title if we're on the conversation page
          streams << turbo_stream.update("current-conversation-title", "New Chat")

          render turbo_stream: streams
        end
        format.html do
          redirect_to root_path, notice: "\"#{conversation_title}\" was successfully deleted."
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_entity }
        format.html do
          redirect_to @conversation, alert: "Failed to delete conversation."
        end
      end
    end
  rescue => e
    Rails.logger.error "Failed to delete conversation #{@conversation.id}: #{e.message}"

    respond_to do |format|
      format.turbo_stream { head :internal_server_error }
      format.html do
        redirect_to @conversation, alert: "An error occurred while deleting the conversation."
      end
    end
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
