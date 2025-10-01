class LlmModel < ApplicationRecord
  PROVIDERS = %w[openai anthropic google].freeze

  validates :name, presence: true, uniqueness: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }

  scope :enabled, -> { where(enabled: true) }
  scope :by_provider, ->(provider) { where(provider: provider) }

  def self.find_by_model_name(model_name)
    enabled.find_by(name: model_name)
  end

  def self.detect_provider(model_name)
    model = find_by_model_name(model_name)
    return model.provider.to_sym if model

    # Fallback to pattern matching if not in database
    case model_name
    when /^gpt-/ then :openai
    when /^claude-/ then :anthropic
    when /^gemini-/ then :google
    else :openai
    end
  end

  def service_class
    case provider
    when "openai" then Llm::OpenaiService
    when "anthropic" then Llm::AnthropicService
    when "google" then Llm::GoogleService
    end
  end
end
