# LLM Chat Backend - Multi-Provider Single-Model Version

Rails API for LLM chat with streaming support for OpenAI, Anthropic, and Google Gemini.

## Features

✅ **Multi-provider support**: OpenAI, Anthropic (Claude), Google (Gemini)
✅ **Official SDKs**: Uses official Ruby SDKs for OpenAI and Anthropic
✅ **SSE streaming**: Real-time token-by-token responses
✅ **Conversation history**: PostgreSQL-backed storage
✅ **Simple authentication**: API key bearer tokens
✅ **Auto provider detection**: Automatically selects provider based on model name

## Quick Start

### 1. Install Dependencies

```bash
bundle install
```

### 2. Setup Environment

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:
```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...
API_KEYS=your-test-key
```

### 3. Setup Database

```bash
rails db:create
rails db:migrate
```

### 4. Start Server

```bash
rails server
```

## API Endpoints

### POST /api/v1/chat

Stream chat with any supported LLM provider.

**Request:**
```json
{
  "message": "Explain quantum computing",
  "model": "gpt-4-turbo",  // or "claude-3-opus-20240229" or "gemini-1.5-pro"
  "conversation_id": 123,
  "system_prompt": "You are a helpful assistant"
}
```

**Response:** SSE stream

```
data: {"type":"metadata","conversation_id":123,"model":"gpt-4-turbo"}
data: {"type":"token","token":"Quantum","done":false}
data: {"type":"token","token":" computing","done":false}
data: {"type":"token","token":"","done":true,"latency_ms":1234}
data: {"type":"done"}
```

### GET /api/v1/conversations

List user's conversations.

### GET /api/v1/conversations/:id

Get conversation history with all messages.

### GET /api/v1/health

Health check (no auth required).

## Frontend Example

```javascript
async function sendMessage(message, model = 'gpt-4-turbo') {
  const response = await fetch('http://localhost:3000/api/v1/chat', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer your-api-key',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ message, model })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    const chunk = decoder.decode(value);
    chunk.split('\n').forEach(line => {
      if (line.startsWith('data: ')) {
        const data = JSON.parse(line.substring(6));
        if (data.type === 'token' && !data.done) {
          console.log(data.token); // Display token
        }
      }
    });
  }
}
```

## Available Models

### OpenAI
- `gpt-4-turbo` (default)
- `gpt-4`
- `gpt-3.5-turbo`

### Anthropic
- `claude-3-opus-20240229`
- `claude-3-sonnet-20240229`
- `claude-3-haiku-20240307`

### Google Gemini
- `gemini-1.5-pro`
- `gemini-1.5-flash`
- `gemini-1.0-pro`

Provider is automatically detected from model name prefix (`gpt-` → OpenAI, `claude-` → Anthropic, `gemini-` → Google).

## Project Structure

```
app/
  controllers/
    api/v1/
      chat_controller.rb       # SSE streaming endpoint
      conversations_controller.rb  # Conversation history
      health_controller.rb     # Health check
  models/
    conversation.rb            # Conversation model
    message.rb                 # Message model
  services/
    llm_service.rb             # Multi-provider LLM integration
db/
  migrate/
    *_create_conversations.rb  # Conversations table
    *_create_messages.rb       # Messages table
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key | Required for GPT models |
| `ANTHROPIC_API_KEY` | Anthropic API key | Required for Claude models |
| `GOOGLE_API_KEY` | Google API key | Required for Gemini models |
| `API_KEYS` | Comma-separated valid API keys | Required |
| `CORS_ORIGINS` | Allowed CORS origins | `http://localhost:3001` |
| `MAX_TOKENS` | Max tokens per response | `2000` |
| `TEMPERATURE` | LLM temperature | `0.7` |

## SDK Information

- **OpenAI**: Uses official `openai` gem (v0.3+)
- **Anthropic**: Uses official `anthropic` gem (v0.3+)
- **Google Gemini**: Uses HTTP API via `faraday` (no official Ruby SDK available)

## Extending to Parallel Multi-Model

This codebase is designed to be easily extended for parallel execution. To add multi-model support:

1. Add `model_runs` table for tracking multiple concurrent responses
2. Implement threading in `ChatController` for parallel execution
3. Add mutex for SSE write synchronization
4. Update SSE format to include model identifier per token
