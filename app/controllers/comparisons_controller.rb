class ComparisonsController < ApplicationController
  before_action :set_conversation, only: [ :show, :vote ]

  def index
    @conversations = Conversation.comparison_mode.recent.includes(:messages).limit(20)
  end

  def new
    @ai_models = AiModels::DISPLAY_NAMES
  end

  def create
    @conversation = Conversation.create!(
      title: generate_comparison_title(comparison_params[:model_a], comparison_params[:model_b]),
      comparison_mode: true,
      model_a: comparison_params[:model_a],
      model_b: comparison_params[:model_b],
      ai_model: comparison_params[:model_a] # Fallback for validation
    )

    @message = @conversation.messages.create!(
      content: comparison_params[:content],
      role: "user"
    )

    # Queue AI responses for both models
    ComparisonResponseJob.perform_later(@conversation.id, @message.id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("comparison-area", partial: "shared/comparison_view", locals: {
            conversation: @conversation,
            message: @message
          }),
          turbo_stream.append("comparison-messages", partial: "shared/comparison_message", locals: {
            message: @message,
            conversation: @conversation
          }),
          turbo_stream.append("comparison-messages", partial: "shared/comparison_thinking")
        ]
      end
      format.html { redirect_to comparison_path(@conversation) }
    end
  rescue => e
    Rails.logger.error "Failed to create comparison: #{e.message}"
    respond_to do |format|
      format.turbo_stream { head :unprocessable_content }
      format.html { redirect_to new_comparison_path, alert: "Failed to start comparison" }
    end
  end

  def show
    @messages = @conversation.messages.by_creation_order
    @message = Message.new
  end

  def vote
    @message = @conversation.messages.find(params[:message_id])

    if @message.update(comparison_vote: vote_params[:vote].to_i)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "vote-buttons-#{@message.id}",
            partial: "shared/vote_result",
            locals: { message: @message, conversation: @conversation }
          )
        end
        format.json { render json: { success: true } }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def comparison_params
    params.require(:comparison).permit(:content, :model_a, :model_b)
  end

  def vote_params
    params.require(:vote).permit(:vote)
  end

  def generate_comparison_title(model_a, model_b)
    content_preview = comparison_params[:content]&.truncate(30) || "Comparison"
    "#{AiModels.display_name(model_a)} vs #{AiModels.display_name(model_b)}: #{content_preview}"
  end
end