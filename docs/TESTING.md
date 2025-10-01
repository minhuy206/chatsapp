# Testing Guide

## Testing Different Providers

### 1. Test OpenAI (GPT)

```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in 5 words",
    "model": "gpt-3.5-turbo"
  }'
```

### 2. Test Anthropic (Claude)

```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in 5 words",
    "model": "claude-3-haiku-20240307"
  }'
```

### 3. Test Google (Gemini)

```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Say hello in 5 words",
    "model": "gemini-1.5-flash"
  }'
```

## Expected SSE Stream Output

```
data: {"type":"metadata","conversation_id":1,"model":"gpt-3.5-turbo"}
data: {"type":"token","token":"Hello","done":false}
data: {"type":"token","token":" from","done":false}
data: {"type":"token","token":" OpenAI","done":false}
data: {"type":"token","token":"!","done":false}
data: {"type":"token","token":"","done":true,"latency_ms":1234.56}
data: {"type":"done"}
```

## Testing with JavaScript

```javascript
async function testProvider(model) {
  const response = await fetch('http://localhost:3000/api/v1/chat', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer your-api-key',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      message: 'Say hello in 5 words',
      model: model
    })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let fullResponse = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    chunk.split('\n').forEach(line => {
      if (line.startsWith('data: ')) {
        const data = JSON.parse(line.substring(6));
        if (data.type === 'token' && !data.done) {
          fullResponse += data.token;
          console.log(data.token);
        }
      }
    });
  }

  console.log('Full response:', fullResponse);
}

// Test all providers
testProvider('gpt-3.5-turbo');      // OpenAI
testProvider('claude-3-haiku-20240307');  // Anthropic
testProvider('gemini-1.5-flash');   // Google
```

## Troubleshooting

### Missing API Keys

**Error**: `OpenAI service error` or `Anthropic service error`

**Solution**: Check `.env` file has the correct API keys:
```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...
```

### Authentication Failed

**Error**: `{"error":"Unauthorized"}`

**Solution**: Ensure you're passing the correct API key in the Authorization header that matches one of the keys in your `API_KEYS` environment variable.

### Provider Detection Issues

If the wrong provider is being used:
- Check model name format (must start with `gpt-`, `claude-`, or `gemini-`)
- Verify the model name is correct and supported

### Streaming Not Working

If responses come all at once instead of streaming:
- Check that your client is reading the stream properly
- Ensure nginx or load balancer isn't buffering SSE responses
- Verify Puma is configured for threading

## Health Check

```bash
# Check API is running and providers are configured
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T10:30:00Z",
  "openai": true
}
```

## Testing Conversation History

```bash
# 1. Send first message
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "My name is Alice",
    "model": "gpt-3.5-turbo"
  }' | grep conversation_id

# Note the conversation_id from the response

# 2. Continue conversation
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is my name?",
    "model": "gpt-3.5-turbo",
    "conversation_id": 1
  }'

# 3. View conversation history
curl http://localhost:3000/api/v1/conversations/1 \
  -H "Authorization: Bearer your-api-key"
```