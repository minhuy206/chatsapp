# Central configuration for all supported AI models.
#
# This module provides a single source of truth for AI model definitions,
# reducing duplication and making it easier to add or modify model support.
#
# @example Check model type
#   AiModels.openai_model?("gpt-4o") # => true
#   AiModels.anthropic_model?("claude-3.5-sonnet") # => true
#
# @example Get all models
#   AiModels::ALL_MODELS # => ["gpt-4", "gpt-4o", ...]
module AiModels
  # OpenAI GPT model identifiers
  OPENAI_MODELS = %w[
    gpt-4
    gpt-4o
    gpt-3.5-turbo
  ].freeze

  # Anthropic Claude model identifiers
  ANTHROPIC_MODELS = %w[
    claude-3-opus
    claude-3-sonnet
    claude-3-haiku
    claude-3.5-sonnet
  ].freeze

  # All supported AI models
  ALL_MODELS = (OPENAI_MODELS + ANTHROPIC_MODELS).freeze

  # Human-readable display names for models
  DISPLAY_NAMES = {
    "gpt-4o" => "GPT-4o",
    "gpt-4" => "GPT-4",
    "gpt-3.5-turbo" => "GPT-3.5 Turbo",
    "claude-3.5-sonnet" => "Claude 3.5 Sonnet",
    "claude-3-opus" => "Claude 3 Opus",
    "claude-3-sonnet" => "Claude 3 Sonnet",
    "claude-3-haiku" => "Claude 3 Haiku"
  }.freeze

  # Check if a model is an OpenAI GPT model.
  #
  # @param model [String] The model identifier
  # @return [Boolean] True if the model is an OpenAI model
  def self.openai_model?(model)
    OPENAI_MODELS.include?(model)
  end

  # Check if a model is an Anthropic Claude model.
  #
  # @param model [String] The model identifier
  # @return [Boolean] True if the model is an Anthropic model
  def self.anthropic_model?(model)
    ANTHROPIC_MODELS.include?(model)
  end

  # Get the display name for a model.
  #
  # @param model [String] The model identifier
  # @return [String] The human-readable display name, or the model identifier if not found
  def self.display_name(model)
    DISPLAY_NAMES[model] || model
  end
end
