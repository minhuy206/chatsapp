# LLM Chat Backend - Frontend Integration API Documentation

Complete API reference for integrating the LLM chat backend with your frontend application.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [Chat Streaming](#chat-streaming)
5. [Error Handling](#error-handling)
6. [Code Examples](#code-examples)
7. [TypeScript Types](#typescript-types)
8. [React Integration](#react-integration)
9. [Best Practices](#best-practices)

---

## Quick Start

### Base URL
```
Development: http://localhost:3000
Production: https://your-domain.com
```

### Headers Required
```javascript
{
  'Authorization': 'Bearer YOUR_API_KEY',
  'Content-Type': 'application/json'
}
```

### Quick Example
```javascript
const response = await fetch('http://localhost:3000/api/v1/chat', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer your-api-key',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    message: 'Hello, how are you?',
    model: 'gpt-3.5-turbo'
  })
});

// Handle SSE stream
const reader = response.body.getReader();
// ... process stream
```

---

## Authentication

### API Key Authentication

All endpoints (except `/api/v1/health`) require authentication via Bearer token.

**Header Format:**
```
Authorization: Bearer YOUR_API_KEY
```

**Getting Your API Key:**
1. Contact your backend administrator
2. API keys are configured via `API_KEYS` environment variable
3. Store securely (never commit to version control)

**Security Best Practices:**
```javascript
// ✅ Good - Use environment variables
const API_KEY = process.env.REACT_APP_API_KEY;

// ❌ Bad - Hardcoded in source
const API_KEY = 'sk-12345...';
```

**Error Response (401 Unauthorized):**
```json
{
  "error": "Unauthorized"
}
```

---

## API Endpoints

### 1. Health Check

Check API availability and provider status.

**Endpoint:** `GET /api/v1/health`

**Authentication:** ❌ Not required

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-01T10:30:00.000Z",
  "openai": true
}
```

**JavaScript Example:**
```javascript
async function checkHealth() {
  const response = await fetch('http://localhost:3000/api/v1/health');
  const data = await response.json();
  console.log('API Status:', data.status);
  return data;
}
```

---

### 2. Get Available Models

Get list of all available LLM models.

**Endpoint:** `GET /api/v1/models`

**Authentication:** ✅ Required

**Response:**
```json
{
  "models": [
    {
      "name": "gpt-4o",
      "provider": "openai",
      "config": {
        "max_tokens": 4096,
        "supports_streaming": true
      }
    },
    {
      "name": "claude-3-5-sonnet-20241022",
      "provider": "anthropic",
      "config": {
        "max_tokens": 8192,
        "supports_streaming": true
      }
    }
  ],
  "count": 14
}
```

**JavaScript Example:**
```javascript
async function getAvailableModels() {
  const response = await fetch('http://localhost:3000/api/v1/models', {
    headers: {
      'Authorization': 'Bearer your-api-key'
    }
  });
  const data = await response.json();
  return data.models;
}
```

---

### 3. Get Model Details

Get details of a specific model.

**Endpoint:** `GET /api/v1/models/:name`

**Authentication:** ✅ Required

**URL Parameters:**
- `name` (string, required) - Model name (e.g., `gpt-4o`, `claude-3-5-sonnet-20241022`)

**Response (Success):**
```json
{
  "name": "gpt-4o",
  "provider": "openai",
  "enabled": true,
  "config": {
    "max_tokens": 4096,
    "supports_streaming": true
  }
}
```

**Response (Not Found):**
```json
{
  "error": "Model not found",
  "message": "Model 'invalid-model' is not available"
}
```

**JavaScript Example:**
```javascript
async function getModelDetails(modelName) {
  const response = await fetch(`http://localhost:3000/api/v1/models/${modelName}`, {
    headers: {
      'Authorization': 'Bearer your-api-key'
    }
  });

  if (!response.ok) {
    throw new Error('Model not found');
  }

  return await response.json();
}
```

---

### 4. Send Chat Message (SSE Streaming)

Send a message and receive streaming response.

**Endpoint:** `POST /api/v1/chat`

**Authentication:** ✅ Required

**Request Body:**
```json
{
  "message": "Hello, how are you?",
  "model": "gpt-3.5-turbo",
  "conversation_id": 123,
  "system_prompt": "You are a helpful assistant."
}
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `message` | string | ✅ Yes | User's message content |
| `model` | string | ✅ Yes | AI model to use (see [Supported Models](#supported-models)) |
| `conversation_id` | integer | ❌ No | Existing conversation ID (creates new if omitted) |
| `system_prompt` | string | ❌ No | System message for AI behavior (only used for new conversations) |

**Response Format (Server-Sent Events):**

The response is a stream of Server-Sent Events (SSE). Each event is a JSON object.

**Event Types:**

**1. Metadata Event:**
```json
{
  "type": "metadata",
  "conversation_id": 123,
  "model": "gpt-3.5-turbo"
}
```

**2. Token Event:**
```json
{
  "type": "token",
  "token": "Hello",
  "done": false
}
```

**3. Completion Event:**
```json
{
  "type": "token",
  "token": "",
  "done": true,
  "latency_ms": 1234.56
}
```

**4. Done Event:**
```json
{
  "type": "done"
}
```

**5. Error Event:**
```json
{
  "type": "error",
  "error": "Error message"
}
```

**JavaScript Example:**
```javascript
async function sendMessage(message, model = 'gpt-3.5-turbo') {
  const response = await fetch('http://localhost:3000/api/v1/chat', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY',
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
    const lines = chunk.split('\n');

    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = JSON.parse(line.slice(6));

        if (data.type === 'metadata') {
          console.log('Conversation ID:', data.conversation_id);
        } else if (data.type === 'token' && !data.done) {
          process.stdout.write(data.token);
        } else if (data.type === 'token' && data.done) {
          console.log('\nLatency:', data.latency_ms, 'ms');
        }
      }
    }
  }
}
```

---

### 3. List Conversations

Retrieve user's conversation history.

**Endpoint:** `GET /api/v1/conversations`

**Authentication:** ✅ Required

**Response:**
```json
{
  "conversations": [
    {
      "id": 123,
      "title": "Conversation 123",
      "created_at": "2025-10-01T10:30:00.000Z",
      "message_count": 5
    },
    {
      "id": 124,
      "title": "Conversation 124",
      "created_at": "2025-10-01T11:00:00.000Z",
      "message_count": 3
    }
  ]
}
```

**JavaScript Example:**
```javascript
async function getConversations() {
  const response = await fetch('http://localhost:3000/api/v1/conversations', {
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY'
    }
  });

  const data = await response.json();
  return data.conversations;
}
```

---

### 4. Get Conversation Details

Retrieve full conversation history with messages.

**Endpoint:** `GET /api/v1/conversations/:id`

**Authentication:** ✅ Required

**URL Parameters:**
- `id` - Conversation ID (integer)

**Response:**
```json
{
  "conversation": {
    "id": 123,
    "title": null,
    "created_at": "2025-10-01T10:30:00.000Z"
  },
  "messages": [
    {
      "id": 1,
      "role": "system",
      "content": "You are a helpful assistant.",
      "model_used": null,
      "tokens_used": null,
      "created_at": "2025-10-01T10:30:00.000Z"
    },
    {
      "id": 2,
      "role": "user",
      "content": "Hello, how are you?",
      "model_used": null,
      "tokens_used": null,
      "created_at": "2025-10-01T10:30:05.000Z"
    },
    {
      "id": 3,
      "role": "assistant",
      "content": "I'm doing well, thank you for asking!",
      "model_used": "gpt-3.5-turbo",
      "tokens_used": null,
      "created_at": "2025-10-01T10:30:07.000Z"
    }
  ]
}
```

**JavaScript Example:**
```javascript
async function getConversation(conversationId) {
  const response = await fetch(
    `http://localhost:3000/api/v1/conversations/${conversationId}`,
    {
      headers: {
        'Authorization': 'Bearer YOUR_API_KEY'
      }
    }
  );

  const data = await response.json();
  return data;
}
```

---

## Chat Streaming

### Understanding Server-Sent Events (SSE)

Server-Sent Events is a standard for server-to-client streaming. The chat endpoint uses SSE to stream AI responses in real-time.

### SSE Format

Each event follows this format:
```
data: {"type": "token", "token": "Hello", "done": false}

data: {"type": "token", "token": " there", "done": false}

data: {"type": "token", "token": "!", "done": false}

data: {"type": "token", "token": "", "done": true, "latency_ms": 1234.56}

data: {"type": "done"}
```

### Handling SSE in JavaScript

**Vanilla JavaScript:**
```javascript
async function streamChat(message, onToken, onComplete, onError) {
  try {
    const response = await fetch('http://localhost:3000/api/v1/chat', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        message,
        model: 'gpt-3.5-turbo'
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();

      if (done) {
        onComplete?.();
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = JSON.parse(line.slice(6));

          if (data.type === 'token' && !data.done) {
            onToken(data.token);
          } else if (data.type === 'error') {
            onError?.(new Error(data.error));
          } else if (data.type === 'token' && data.done) {
            console.log('Stream completed in', data.latency_ms, 'ms');
          }
        }
      }
    }
  } catch (error) {
    onError?.(error);
  }
}

// Usage
let fullResponse = '';
streamChat(
  'Hello, how are you?',
  (token) => {
    fullResponse += token;
    console.log('Received:', token);
  },
  () => {
    console.log('Complete response:', fullResponse);
  },
  (error) => {
    console.error('Error:', error);
  }
);
```

**Using Fetch API with async iteration:**
```javascript
async function* streamChatGenerator(message, model = 'gpt-3.5-turbo') {
  const response = await fetch('http://localhost:3000/api/v1/chat', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ message, model })
  });

  const reader = response.body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split('\n');
    buffer = lines.pop() || '';

    for (const line of lines) {
      if (line.startsWith('data: ')) {
        const data = JSON.parse(line.slice(6));
        if (data.type === 'token' && !data.done) {
          yield data.token;
        }
      }
    }
  }
}

// Usage with async/await
for await (const token of streamChatGenerator('Hello!')) {
  console.log(token);
}
```

---

## Error Handling

### Error Response Format

All errors follow this structure:

```json
{
  "error": {
    "error": "RateLimitError",
    "code": "llm_rate_limit_error",
    "message": "AI service rate limit reached. Please try again in 60 seconds.",
    "provider": "openai",
    "retry_after": 60
  },
  "timestamp": "2025-10-01T10:30:00.000Z"
}
```

### Error Codes

| Error Code | HTTP Status | Description | Retryable |
|------------|-------------|-------------|-----------|
| `llm_authentication_error` | 401 | Invalid API credentials | ❌ No |
| `llm_invalid_request_error` | 400 | Bad request parameters | ❌ No |
| `llm_model_not_found_error` | 404 | Model not available | ❌ No |
| `llm_content_filter_error` | 403 | Content blocked by filters | ❌ No |
| `llm_rate_limit_error` | 429 | Rate limit exceeded | ✅ Yes |
| `llm_provider_error` | 500 | Generic provider error | ✅ Yes |
| `llm_service_unavailable_error` | 503 | Service temporarily down | ✅ Yes |
| `llm_timeout_error` | 504 | Request timeout | ✅ Yes |
| `llm_streaming_error` | 500 | Streaming error | ✅ Yes |

### Error Handling Best Practices

**JavaScript Example:**
```javascript
async function sendMessageWithErrorHandling(message, model) {
  try {
    const response = await fetch('http://localhost:3000/api/v1/chat', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer YOUR_API_KEY',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ message, model })
    });

    // Handle HTTP errors
    if (!response.ok) {
      const errorData = await response.json();
      handleApiError(errorData.error);
      return;
    }

    // Process stream...
  } catch (error) {
    console.error('Network error:', error);
    // Handle network failures
  }
}

function handleApiError(error) {
  switch (error.code) {
    case 'llm_rate_limit_error':
      console.log(`Rate limited. Retry after ${error.retry_after} seconds`);
      setTimeout(() => {
        // Retry logic
      }, error.retry_after * 1000);
      break;

    case 'llm_authentication_error':
      console.error('Invalid API key');
      // Redirect to login or show auth error
      break;

    case 'llm_content_filter_error':
      console.warn('Message blocked by content filter');
      // Show user-friendly message
      break;

    case 'llm_timeout_error':
    case 'llm_provider_error':
    case 'llm_service_unavailable_error':
      console.log('Temporary error, retrying...');
      // Implement retry with exponential backoff
      break;

    default:
      console.error('Unknown error:', error.message);
  }
}
```

**Retry Logic with Exponential Backoff:**
```javascript
async function sendWithRetry(message, model, maxAttempts = 3) {
  let attempt = 0;
  let delay = 1000; // Start with 1 second

  while (attempt < maxAttempts) {
    try {
      const response = await fetch('http://localhost:3000/api/v1/chat', {
        method: 'POST',
        headers: {
          'Authorization': 'Bearer YOUR_API_KEY',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ message, model })
      });

      if (response.ok) {
        return response;
      }

      const errorData = await response.json();
      const error = errorData.error;

      // Check if error is retryable
      const retryableCodes = [
        'llm_rate_limit_error',
        'llm_provider_error',
        'llm_service_unavailable_error',
        'llm_timeout_error'
      ];

      if (!retryableCodes.includes(error.code)) {
        throw new Error(error.message);
      }

      // Use retry_after if provided, otherwise exponential backoff
      const waitTime = error.retry_after
        ? error.retry_after * 1000
        : delay;

      console.log(`Attempt ${attempt + 1} failed. Retrying in ${waitTime}ms...`);
      await new Promise(resolve => setTimeout(resolve, waitTime));

      delay *= 2; // Exponential backoff
      attempt++;

    } catch (error) {
      if (attempt === maxAttempts - 1) {
        throw error;
      }
      attempt++;
    }
  }

  throw new Error('Max retry attempts reached');
}
```

---

## Code Examples

### Complete Chat Component (Vanilla JS)

```javascript
class ChatClient {
  constructor(apiKey, baseUrl = 'http://localhost:3000') {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
  }

  async sendMessage(message, options = {}) {
    const {
      model = 'gpt-3.5-turbo',
      conversationId = null,
      systemPrompt = null,
      onToken = () => {},
      onComplete = () => {},
      onError = () => {},
      onMetadata = () => {}
    } = options;

    try {
      const body = {
        message,
        model,
        ...(conversationId && { conversation_id: conversationId }),
        ...(systemPrompt && { system_prompt: systemPrompt })
      };

      const response = await fetch(`${this.baseUrl}/api/v1/chat`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
      });

      if (!response.ok) {
        const errorData = await response.json();
        onError(errorData.error);
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();

        if (done) {
          onComplete();
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = JSON.parse(line.slice(6));

            switch (data.type) {
              case 'metadata':
                onMetadata(data);
                break;
              case 'token':
                if (!data.done) {
                  onToken(data.token);
                }
                break;
              case 'error':
                onError(data.error);
                break;
            }
          }
        }
      }
    } catch (error) {
      onError({ message: error.message });
    }
  }

  async getConversations() {
    const response = await fetch(`${this.baseUrl}/api/v1/conversations`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const data = await response.json();
    return data.conversations;
  }

  async getConversation(conversationId) {
    const response = await fetch(
      `${this.baseUrl}/api/v1/conversations/${conversationId}`,
      {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      }
    );

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    return await response.json();
  }

  async checkHealth() {
    const response = await fetch(`${this.baseUrl}/api/v1/health`);
    return await response.json();
  }

  async getAvailableModels() {
    const response = await fetch(`${this.baseUrl}/api/v1/models`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      }
    });
    const data = await response.json();
    return data.models;
  }

  async getModelDetails(modelName) {
    const response = await fetch(`${this.baseUrl}/api/v1/models/${modelName}`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`
      }
    });

    if (!response.ok) {
      throw new Error('Model not found');
    }

    return await response.json();
  }
}

// Usage Example
const client = new ChatClient('your-api-key');

// Get available models and populate dropdown
const models = await client.getAvailableModels();
console.log('Available models:', models);
// [
//   { name: 'gpt-4o', provider: 'openai', config: {...} },
//   { name: 'claude-3-5-sonnet-20241022', provider: 'anthropic', config: {...} },
//   ...
// ]

// Send message with selected model
let fullResponse = '';
client.sendMessage('Hello, how are you?', {
  model: 'gpt-4o', // Use dynamically selected model
  onToken: (token) => {
    fullResponse += token;
    document.getElementById('response').textContent = fullResponse;
  },
  onComplete: () => {
    console.log('Streaming complete!');
  },
  onError: (error) => {
    console.error('Error:', error);
  },
  onMetadata: (metadata) => {
    console.log('Conversation ID:', metadata.conversation_id);
  }
});
```

---

## TypeScript Types

```typescript
// API Types
export interface ChatRequest {
  message: string;
  model: string;
  conversation_id?: number;
  system_prompt?: string;
}

export interface SSEEvent {
  type: 'metadata' | 'token' | 'error' | 'done';
}

export interface MetadataEvent extends SSEEvent {
  type: 'metadata';
  conversation_id: number;
  model: string;
}

export interface TokenEvent extends SSEEvent {
  type: 'token';
  token: string;
  done: boolean;
  latency_ms?: number;
}

export interface ErrorEvent extends SSEEvent {
  type: 'error';
  error: string;
}

export interface DoneEvent extends SSEEvent {
  type: 'done';
}

export type ChatEvent = MetadataEvent | TokenEvent | ErrorEvent | DoneEvent;

export interface ApiError {
  error: {
    error: string;
    code: string;
    message: string;
    provider?: string;
    retry_after?: number;
  };
  timestamp: string;
}

export interface Conversation {
  id: number;
  title: string | null;
  created_at: string;
  message_count?: number;
}

export interface Message {
  id: number;
  role: 'system' | 'user' | 'assistant';
  content: string;
  model_used: string | null;
  tokens_used: number | null;
  created_at: string;
}

export interface ConversationDetail {
  conversation: {
    id: number;
    title: string | null;
    created_at: string;
  };
  messages: Message[];
}

export interface HealthResponse {
  status: 'ok' | 'error';
  timestamp: string;
  openai: boolean;
}

export interface LlmModel {
  name: string;
  provider: 'openai' | 'anthropic' | 'google';
  config: {
    max_tokens?: number;
    supports_streaming?: boolean;
    [key: string]: any;
  };
}

export interface ModelsResponse {
  models: LlmModel[];
  count: number;
}

export interface ModelDetailResponse {
  name: string;
  provider: string;
  enabled: boolean;
  config: {
    max_tokens?: number;
    supports_streaming?: boolean;
    [key: string]: any;
  };
}

// Chat Client Options
export interface ChatOptions {
  model?: string;
  conversationId?: number;
  systemPrompt?: string;
  onToken?: (token: string) => void;
  onComplete?: () => void;
  onError?: (error: ApiError['error']) => void;
  onMetadata?: (metadata: MetadataEvent) => void;
}

// TypeScript Chat Client
export class TypedChatClient {
  constructor(
    private apiKey: string,
    private baseUrl: string = 'http://localhost:3000'
  ) {}

  async sendMessage(
    message: string,
    options: ChatOptions = {}
  ): Promise<void> {
    // Implementation...
  }

  async getConversations(): Promise<Conversation[]> {
    // Implementation...
  }

  async getConversation(conversationId: number): Promise<ConversationDetail> {
    // Implementation...
  }

  async checkHealth(): Promise<HealthResponse> {
    // Implementation...
  }

  async getAvailableModels(): Promise<LlmModel[]> {
    // Implementation...
  }

  async getModelDetails(modelName: string): Promise<ModelDetailResponse> {
    // Implementation...
  }
}
```

---

## React Integration

### Basic React Hook

```typescript
// useChatStream.ts
import { useState, useCallback, useRef } from 'react';

interface UseChatStreamOptions {
  apiKey: string;
  baseUrl?: string;
  model?: string;
  conversationId?: number;
  systemPrompt?: string;
}

export function useChatStream(options: UseChatStreamOptions) {
  const {
    apiKey,
    baseUrl = 'http://localhost:3000',
    model = 'gpt-3.5-turbo',
    conversationId,
    systemPrompt
  } = options;

  const [response, setResponse] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [currentConversationId, setCurrentConversationId] = useState<number | null>(
    conversationId || null
  );

  const abortControllerRef = useRef<AbortController | null>(null);

  const sendMessage = useCallback(async (message: string) => {
    setResponse('');
    setError(null);
    setIsStreaming(true);

    abortControllerRef.current = new AbortController();

    try {
      const body = {
        message,
        model,
        ...(currentConversationId && { conversation_id: currentConversationId }),
        ...(systemPrompt && { system_prompt: systemPrompt })
      };

      const res = await fetch(`${baseUrl}/api/v1/chat`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(body),
        signal: abortControllerRef.current.signal
      });

      if (!res.ok) {
        const errorData = await res.json();
        throw new Error(errorData.error.message);
      }

      const reader = res.body!.getReader();
      const decoder = new TextDecoder();
      let buffer = '';

      while (true) {
        const { done, value } = await reader.read();

        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = JSON.parse(line.slice(6));

            if (data.type === 'metadata') {
              setCurrentConversationId(data.conversation_id);
            } else if (data.type === 'token' && !data.done) {
              setResponse(prev => prev + data.token);
            } else if (data.type === 'error') {
              throw new Error(data.error);
            }
          }
        }
      }
    } catch (err: any) {
      if (err.name !== 'AbortError') {
        setError(err.message);
      }
    } finally {
      setIsStreaming(false);
    }
  }, [apiKey, baseUrl, model, currentConversationId, systemPrompt]);

  const stopStreaming = useCallback(() => {
    abortControllerRef.current?.abort();
    setIsStreaming(false);
  }, []);

  return {
    response,
    isStreaming,
    error,
    conversationId: currentConversationId,
    sendMessage,
    stopStreaming
  };
}
```

### React Component Example

```typescript
// ChatComponent.tsx
import React, { useState } from 'react';
import { useChatStream } from './useChatStream';

export function ChatComponent() {
  const [input, setInput] = useState('');
  const {
    response,
    isStreaming,
    error,
    conversationId,
    sendMessage,
    stopStreaming
  } = useChatStream({
    apiKey: process.env.REACT_APP_API_KEY!,
    model: 'gpt-3.5-turbo'
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isStreaming) return;

    await sendMessage(input);
    setInput('');
  };

  return (
    <div className="chat-container">
      <div className="chat-header">
        <h2>LLM Chat</h2>
        {conversationId && (
          <span className="conversation-id">
            Conversation #{conversationId}
          </span>
        )}
      </div>

      <div className="chat-messages">
        {response && (
          <div className="message assistant">
            <div className="message-content">{response}</div>
          </div>
        )}
      </div>

      {error && (
        <div className="error-message">
          Error: {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="chat-input-form">
        <input
          type="text"
          value={input}
          onChange={(e) => setInput(e.target.value)}
          placeholder="Type your message..."
          disabled={isStreaming}
          className="chat-input"
        />
        <button
          type="submit"
          disabled={isStreaming || !input.trim()}
          className="send-button"
        >
          {isStreaming ? 'Streaming...' : 'Send'}
        </button>
        {isStreaming && (
          <button
            type="button"
            onClick={stopStreaming}
            className="stop-button"
          >
            Stop
          </button>
        )}
      </form>
    </div>
  );
}
```

### Complete Chat Application with History

```typescript
// FullChatApp.tsx
import React, { useState, useEffect } from 'react';
import { useChatStream } from './useChatStream';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

export function FullChatApp() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [availableModels, setAvailableModels] = useState<any[]>([]);
  const [selectedModel, setSelectedModel] = useState('gpt-4o');

  // Fetch available models on mount
  useEffect(() => {
    const fetchModels = async () => {
      try {
        const response = await fetch('http://localhost:3000/api/v1/models', {
          headers: {
            'Authorization': `Bearer ${process.env.REACT_APP_API_KEY}`
          }
        });
        const data = await response.json();
        setAvailableModels(data.models);
      } catch (err) {
        console.error('Failed to fetch models:', err);
      }
    };
    fetchModels();
  }, []);

  const {
    response,
    isStreaming,
    error,
    conversationId,
    sendMessage
  } = useChatStream({
    apiKey: process.env.REACT_APP_API_KEY!,
    model: selectedModel,
    systemPrompt: 'You are a helpful assistant.'
  });

  // Add user message and get response
  const handleSend = async () => {
    if (!input.trim() || isStreaming) return;

    const userMessage: Message = {
      role: 'user',
      content: input
    };

    setMessages(prev => [...prev, userMessage]);
    setInput('');
    await sendMessage(input);
  };

  // Add assistant response when streaming completes
  useEffect(() => {
    if (response && !isStreaming) {
      const assistantMessage: Message = {
        role: 'assistant',
        content: response
      };
      setMessages(prev => [...prev, assistantMessage]);
    }
  }, [response, isStreaming]);

  return (
    <div className="chat-app">
      <div className="messages-container">
        {messages.map((msg, index) => (
          <div key={index} className={`message ${msg.role}`}>
            <strong>{msg.role}:</strong> {msg.content}
          </div>
        ))}

        {isStreaming && response && (
          <div className="message assistant streaming">
            <strong>assistant:</strong> {response}
            <span className="streaming-indicator">▊</span>
          </div>
        )}

        {error && <div className="error">{error}</div>}
      </div>

      <div className="input-container">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          placeholder="Type a message..."
          disabled={isStreaming}
        />
        <button onClick={handleSend} disabled={isStreaming || !input.trim()}>
          Send
        </button>
      </div>
    </div>
  );
}
```

---

## Best Practices

### 1. API Key Security

✅ **Do:**
- Store API keys in environment variables
- Use `.env` files (add to `.gitignore`)
- Rotate keys regularly
- Use different keys for dev/staging/prod

❌ **Don't:**
- Hardcode API keys in source code
- Commit API keys to version control
- Share API keys in chat/email
- Expose keys in client-side code

### 2. Error Handling

✅ **Do:**
- Handle all error codes appropriately
- Implement retry logic for retryable errors
- Show user-friendly error messages
- Log errors for debugging
- Use exponential backoff for retries

❌ **Don't:**
- Ignore error codes
- Retry non-retryable errors
- Show technical error details to users
- Retry infinitely without backoff

### 3. Streaming Best Practices

✅ **Do:**
- Use `TextDecoder` for proper UTF-8 handling
- Buffer incomplete lines
- Handle connection interruptions
- Provide loading states
- Allow users to cancel streams

❌ **Don't:**
- Assume complete lines in each chunk
- Block UI during streaming
- Leave connections open indefinitely
- Ignore stream errors

### 4. Performance Optimization

✅ **Do:**
- Reuse conversation IDs for context
- Implement request debouncing
- Cache conversation history locally
- Use appropriate models for tasks
- Monitor latency metrics

❌ **Don't:**
- Create new conversations for every message
- Send requests on every keystroke
- Fetch full history repeatedly
- Always use largest/most expensive models

### 5. User Experience

✅ **Do:**
- Show typing indicators during streaming
- Display partial responses as they arrive
- Preserve conversation history
- Handle network failures gracefully
- Provide feedback for all actions

❌ **Don't:**
- Wait for complete response before showing anything
- Lose user messages on errors
- Leave users wondering if request is processing
- Ignore loading/error states

---

## Supported Models

### OpenAI Models
- `gpt-4-turbo` - Most capable, slower, more expensive
- `gpt-4` - Very capable, balanced
- `gpt-3.5-turbo` - Fast, cost-effective, good quality

### Anthropic Models
- `claude-3-opus-20240229` - Most capable
- `claude-3-sonnet-20240229` - Balanced
- `claude-3-haiku-20240307` - Fastest, most cost-effective

### Google Models
- `gemini-1.5-pro` - Most capable
- `gemini-1.5-flash` - Fast and efficient
- `gemini-1.0-pro` - Baseline model

---

## Rate Limits & Quotas

Rate limits are determined by your API provider subscriptions. When you hit a rate limit:

**Response:** HTTP 429
```json
{
  "error": {
    "code": "llm_rate_limit_error",
    "message": "AI service rate limit reached. Please try again in 60 seconds.",
    "retry_after": 60
  }
}
```

**Handling:**
```javascript
if (error.code === 'llm_rate_limit_error') {
  const retryAfter = error.retry_after * 1000;
  setTimeout(() => retryRequest(), retryAfter);
}
```

---

## Support & Troubleshooting

### Common Issues

**Issue: "Unauthorized" error**
- Solution: Check API key is correct and included in Authorization header

**Issue: SSE stream cuts off unexpectedly**
- Solution: Check network connection, implement reconnection logic

**Issue: Getting 404 for conversations**
- Solution: Verify conversation ID exists and belongs to your API key

**Issue: Model not found**
- Solution: Check model name spelling, verify model is supported

### Debug Logging

Enable debug logging to troubleshoot issues:

```javascript
const DEBUG = true;

async function debugFetch(url, options) {
  if (DEBUG) {
    console.log('Request:', { url, options });
  }

  const response = await fetch(url, options);

  if (DEBUG) {
    console.log('Response:', {
      status: response.status,
      headers: Object.fromEntries(response.headers)
    });
  }

  return response;
}
```

---

## Changelog

**v1.1.0** (2025-10-01)
- Added error codes for programmatic handling
- Added request ID to error logs
- Improved retry logic with jitter
- Enhanced error response format

**v1.0.0** (2025-09-30)
- Initial release
- SSE streaming support
- Multi-provider support (OpenAI, Anthropic, Google)
- Conversation management

---

## License

See backend repository for license information.

---

**Questions or Issues?**
Contact your backend team or file an issue in the project repository.
