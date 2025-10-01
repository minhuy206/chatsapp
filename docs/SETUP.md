# Setup Instructions

## Step 1: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and add your keys (add at least one provider):
```bash
# At least one of these is required
OPENAI_API_KEY=sk-your-actual-key-here
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here
GOOGLE_API_KEY=AIza-your-actual-key-here

# For API authentication
API_KEYS=test-key-123,another-key-456
```

## Step 2: Setup Database

```bash
rails db:create
rails db:migrate
```

## Step 3: Start Server

```bash
rails server
```

Server will start on http://localhost:3000

## Step 4: Test the API

### Health Check (No Auth)
```bash
curl http://localhost:3000/api/v1/health
```

### Send Chat Message

**OpenAI:**
```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer test-key-123" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, how are you?",
    "model": "gpt-3.5-turbo"
  }'
```

**Anthropic:**
```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer test-key-123" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, how are you?",
    "model": "claude-3-haiku-20240307"
  }'
```

**Google Gemini:**
```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer test-key-123" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, how are you?",
    "model": "gemini-1.5-flash"
  }'
```

**Quick Test All Providers:**
```bash
./test_providers.sh test-key-123
```

### List Conversations
```bash
curl http://localhost:3000/api/v1/conversations \
  -H "Authorization: Bearer test-key-123"
```

## Troubleshooting

### Missing gems
```bash
bundle install
```

### Database errors
```bash
rails db:drop db:create db:migrate
```

### Check routes
```bash
rails routes | grep api
```

## Next Steps

1. **Test all providers**: Run `./test_providers.sh your-api-key`
2. **Frontend integration**: See README_CHAT.md for JavaScript examples
3. **Explore models**: Try different models from each provider
4. **Review documentation**: Check TESTING.md for detailed testing guides
5. **Future enhancements**: See IMPLEMENTATION_SUMMARY.md for parallel multi-model support