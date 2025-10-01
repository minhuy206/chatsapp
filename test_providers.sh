#!/bin/bash

# Quick test script for all LLM providers
# Usage: ./test_providers.sh your-api-key

API_KEY=${1:-"your-api-key"}
BASE_URL="http://localhost:3000"

echo "🧪 Testing LLM Chat Backend with Multiple Providers"
echo "=================================================="
echo ""

# Test OpenAI
echo "1️⃣ Testing OpenAI (GPT-3.5-Turbo)..."
curl -s -X POST "$BASE_URL/api/v1/chat" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in exactly 3 words",
    "model": "gpt-3.5-turbo"
  }' | head -20
echo ""
echo ""

# Test Anthropic
echo "2️⃣ Testing Anthropic (Claude-3-Haiku)..."
curl -s -X POST "$BASE_URL/api/v1/chat" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in exactly 3 words",
    "model": "claude-3-haiku-20240307"
  }' | head -20
echo ""
echo ""

# Test Google
echo "3️⃣ Testing Google (Gemini-1.5-Flash)..."
curl -s -X POST "$BASE_URL/api/v1/chat" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in exactly 3 words",
    "model": "gemini-1.5-flash"
  }' | head -20
echo ""
echo ""

# Health Check
echo "🏥 Health Check..."
curl -s "$BASE_URL/api/v1/health" | jq '.'
echo ""

echo "✅ Testing complete!"
echo ""
echo "💡 To see full streaming output, run individual tests:"
echo "   curl -X POST $BASE_URL/api/v1/chat \\"
echo "     -H \"Authorization: Bearer $API_KEY\" \\"
echo "     -H \"Content-Type: application/json\" \\"
echo "     -d '{\"message\":\"Hello\",\"model\":\"gpt-3.5-turbo\"}'"