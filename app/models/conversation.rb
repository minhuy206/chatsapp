class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :ai_model, presence: true, inclusion: { in: %w[gpt-4 gpt-4o gpt-3.5-turbo claude-3-opus claude-3-sonnet claude-3-haiku claude-3.5-sonnet] }
  validates :title, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  def latest_message
    messages.order(:created_at).last
  end

  def message_count
    messages.count
  end

  def self.ai_models
    {
      "gpt-4o" => "GPT-4o",
      "gpt-4" => "GPT-4",
      "gpt-3.5-turbo" => "GPT-3.5 Turbo",
      "claude-3.5-sonnet" => "Claude 3.5 Sonnet",
      "claude-3-opus" => "Claude 3 Opus",
      "claude-3-sonnet" => "Claude 3 Sonnet",
      "claude-3-haiku" => "Claude 3 Haiku"
    }
  end

  def ai_model_display_name
    self.class.ai_models[ai_model] || ai_model
  end
end
