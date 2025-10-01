# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Seed LLM Models
puts "Seeding LLM models..."

# OpenAI Models
[
  { name: "gpt-4o", provider: "openai", enabled: true, config: { max_tokens: 4096, supports_streaming: true } },
  { name: "gpt-4o-mini", provider: "openai", enabled: true, config: { max_tokens: 16384, supports_streaming: true } },
  { name: "gpt-4-turbo", provider: "openai", enabled: true, config: { max_tokens: 4096, supports_streaming: true } },
  { name: "gpt-4", provider: "openai", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "gpt-3.5-turbo", provider: "openai", enabled: true, config: { max_tokens: 4096, supports_streaming: true } }
].each do |model_attrs|
  LlmModel.find_or_create_by!(name: model_attrs[:name]) do |model|
    model.provider = model_attrs[:provider]
    model.enabled = model_attrs[:enabled]
    model.config = model_attrs[:config]
  end
end

# Anthropic Models
[
  { name: "claude-3-5-sonnet-20241022", provider: "anthropic", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "claude-3-5-haiku-20241022", provider: "anthropic", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "claude-3-opus-20240229", provider: "anthropic", enabled: true, config: { max_tokens: 4096, supports_streaming: true } },
  { name: "claude-3-sonnet-20240229", provider: "anthropic", enabled: true, config: { max_tokens: 4096, supports_streaming: true } },
  { name: "claude-3-haiku-20240307", provider: "anthropic", enabled: true, config: { max_tokens: 4096, supports_streaming: true } }
].each do |model_attrs|
  LlmModel.find_or_create_by!(name: model_attrs[:name]) do |model|
    model.provider = model_attrs[:provider]
    model.enabled = model_attrs[:enabled]
    model.config = model_attrs[:config]
  end
end

# Google Models
[
  { name: "gemini-2.0-flash-exp", provider: "google", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "gemini-1.5-pro", provider: "google", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "gemini-1.5-flash", provider: "google", enabled: true, config: { max_tokens: 8192, supports_streaming: true } },
  { name: "gemini-1.5-flash-8b", provider: "google", enabled: true, config: { max_tokens: 8192, supports_streaming: true } }
].each do |model_attrs|
  LlmModel.find_or_create_by!(name: model_attrs[:name]) do |model|
    model.provider = model_attrs[:provider]
    model.enabled = model_attrs[:enabled]
    model.config = model_attrs[:config]
  end
end

puts "Seeded #{LlmModel.count} LLM models"
