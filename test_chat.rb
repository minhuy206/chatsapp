#!/usr/bin/env ruby

# Simple test script to check if our chat services work
require_relative 'config/environment'

puts "Testing Chat Functionality..."
puts "=" * 50

# Test 1: Check if models are valid
puts "\n1. Testing model validation:"
begin
  conversation = Conversation.new(title: "Test", ai_model: "gpt-4o")
  if conversation.valid?
    puts "✅ GPT-4o model validation passed"
  else
    puts "❌ GPT-4o model validation failed: #{conversation.errors.full_messages}"
  end

  conversation = Conversation.new(title: "Test", ai_model: "claude-3.5-sonnet")
  if conversation.valid?
    puts "✅ Claude 3.5 Sonnet model validation passed"
  else
    puts "❌ Claude 3.5 Sonnet model validation failed: #{conversation.errors.full_messages}"
  end
rescue => e
  puts "❌ Model validation error: #{e.message}"
end

# Test 2: Check AiServiceFactory
puts "\n2. Testing AiServiceFactory:"
begin
  openai_service = AiServiceFactory.build("gpt-4o")
  puts "✅ GPT-4o service created: #{openai_service.class}"

  claude_service = AiServiceFactory.build("claude-3.5-sonnet")
  puts "✅ Claude 3.5 Sonnet service created: #{claude_service.class}"
rescue => e
  puts "❌ AiServiceFactory error: #{e.message}"
end

# Test 3: Check credentials
puts "\n3. Testing credentials:"
begin
  openai_key = Rails.application.credentials.openai_api_key
  if openai_key && openai_key.length > 0
    puts "✅ OpenAI API key found (#{openai_key.length} characters)"
  else
    puts "❌ OpenAI API key not found or empty"
  end

  claude_key = Rails.application.credentials.anthropic_api_key
  if claude_key && claude_key.length > 0
    puts "✅ Anthropic API key found (#{claude_key.length} characters)"
  else
    puts "❌ Anthropic API key not found or empty"
  end
rescue => e
  puts "❌ Credentials error: #{e.message}"
end

# Test 4: Database connectivity
puts "\n4. Testing database:"
begin
  count = Conversation.count
  puts "✅ Database connected - #{count} conversations found"
rescue => e
  puts "❌ Database error: #{e.message}"
end

puts "\n" + "=" * 50
puts "Test completed!"
