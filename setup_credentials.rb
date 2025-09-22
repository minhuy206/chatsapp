#!/usr/bin/env ruby

puts "Setting up Rails credentials for AI services"
puts "=" * 50

puts "\nTo set up your API keys, run these commands:"
puts ""
puts "# Edit Rails credentials:"
puts "EDITOR='code --wait' bin/rails credentials:edit"
puts ""
puts "# Add these keys to your credentials file:"
puts "openai_api_key: your_openai_api_key_here"
puts "anthropic_api_key: your_anthropic_api_key_here"
puts ""

# Check current Rails environment
puts "Current Rails environment: #{ENV['RAILS_ENV'] || 'development'}"

# Check if master key exists
if File.exist?('config/master.key')
  puts "✅ Master key file exists"
else
  puts "❌ Master key file missing - run 'bin/rails credentials:edit' to create"
end

# Check if credentials file exists
if File.exist?('config/credentials.yml.enc')
  puts "✅ Encrypted credentials file exists"
else
  puts "❌ Encrypted credentials file missing"
end

puts "\n" + "=" * 50
