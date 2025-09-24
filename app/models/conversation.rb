class Conversation < ApplicationRecord
  has_many :messages, dependent: :destroy

  validates :ai_model, presence: true, inclusion: { in: AiModels::ALL_MODELS }
  validates :title, presence: true

  # Comparison mode validations
  validates :model_a, inclusion: { in: AiModels::ALL_MODELS }, allow_blank: true
  validates :model_b, inclusion: { in: AiModels::ALL_MODELS }, allow_blank: true
  validates :model_a, presence: true, if: :comparison_mode?
  validates :model_b, presence: true, if: :comparison_mode?

  scope :recent, -> { order(updated_at: :desc) }
  scope :single_model, -> { where(comparison_mode: false) }
  scope :comparison_mode, -> { where(comparison_mode: true) }

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

  def model_a_display_name
    model_a ? AiModels.display_name(model_a) : nil
  end

  def model_b_display_name
    model_b ? AiModels.display_name(model_b) : nil
  end

  def models_for_comparison
    comparison_mode? ? [ model_a, model_b ] : [ ai_model ]
  end

  def comparison_title
    if comparison_mode?
      "#{model_a_display_name} vs #{model_b_display_name}"
    else
      ai_model_display_name
    end
  end
end
