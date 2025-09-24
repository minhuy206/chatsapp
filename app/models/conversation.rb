class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :ai_model, presence: true, inclusion: { in: AiModels::ALL_MODELS }
  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  def latest_message
    messages.order(:created_at).last
  end

  def message_count
    messages.count
  end

  def self.ai_models
    AiModels::DISPLAY_NAMES
  end

  def ai_model_display_name
    AiModels.display_name(ai_model)
  end
end
