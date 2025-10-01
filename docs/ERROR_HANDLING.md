# Centralized Error Handling System

## Overview

This Rails LLM chat backend now includes a comprehensive, centralized error handling system that provides:
- Custom error hierarchy for LLM-specific errors
- Automatic retry logic with exponential backoff
- Consistent error logging and monitoring
- User-friendly error messages
- Provider-agnostic error handling

---

## Architecture

### Error Hierarchy

```
LlmErrors::BaseError
├── LlmErrors::ProviderError (retryable)
│   ├── LlmErrors::TimeoutError
│   ├── LlmErrors::ServiceUnavailableError
│   └── LlmErrors::StreamingError
├── LlmErrors::AuthenticationError
├── LlmErrors::RateLimitError (retryable)
├── LlmErrors::InvalidRequestError
├── LlmErrors::ModelNotFoundError
└── LlmErrors::ContentFilterError
```

### Components

**1. Custom Error Classes** (`app/errors/llm_errors.rb`)
- Defines error hierarchy with specific error types
- Includes metadata (provider, retry_after, original_error)
- Provides user-friendly messages
- Indicates retryability

**2. Error Handler Concern** (`app/services/concerns/error_handler.rb`)
- Maps provider-specific errors to custom errors
- Handles OpenAI, Anthropic, and Faraday errors
- Provides structured error logging
- Extracts retry-after headers

**3. Retry Logic** (`app/services/concerns/retryable.rb`)
- Exponential backoff with configurable parameters
- Only retries retryable errors
- Logs retry attempts
- Prevents infinite retry loops

**4. Controller Error Handling** (`app/controllers/concerns/error_handling.rb`)
- Global rescue_from handlers
- Maps errors to appropriate HTTP status codes
- Formats error responses consistently
- Protects against information leakage in production

---

## Usage Examples

### Service Layer (Automatic)

Services automatically handle errors with retry logic:

```ruby
# app/services/llm/openai_service.rb
def stream_completion(messages:, model:, &block)
  with_retry(max_attempts: 3) do
    # API call here
  end
rescue StandardError => e
  log_error(e, provider: provider_name, model: model)
  handle_provider_error(e, provider: provider_name)
end
```

### Custom Error Handling

```ruby
# Raise specific error
raise LlmErrors::RateLimitError.new(
  "Rate limit exceeded",
  provider: "openai",
  retry_after: 60
)

# Check if error is retryable
if error.retryable?
  # Retry logic
end

# Get user-friendly message
error.user_message
# => "AI service rate limit reached. Please try again in 60 seconds."
```

### Controller Response

Errors are automatically caught and formatted:

```json
{
  "error": {
    "error": "RateLimitError",
    "message": "AI service rate limit reached. Please try again in 60 seconds.",
    "provider": "openai",
    "retry_after": 60
  },
  "timestamp": "2025-10-01T10:30:00Z"
}
```

---

## Error Mappings

### Provider Errors → Custom Errors

| Provider Error | Custom Error | HTTP Status | Retryable |
|----------------|--------------|-------------|-----------|
| `APIConnectionError` | `ProviderError` | 500 | ✅ |
| `RateLimitError` | `RateLimitError` | 429 | ✅ |
| `AuthenticationError` | `AuthenticationError` | 401 | ❌ |
| `APITimeoutError` | `TimeoutError` | 504 | ✅ |
| `BadRequestError` (400) | `InvalidRequestError` | 400 | ❌ |
| `NotFoundError` (404) | `ModelNotFoundError` | 404 | ❌ |
| `ServiceUnavailableError` (503) | `ServiceUnavailableError` | 503 | ✅ |
| `Faraday::TimeoutError` | `TimeoutError` | 504 | ✅ |
| `Faraday::ConnectionFailed` | `ProviderError` | 500 | ✅ |

### HTTP Status Codes

| Error Type | Status Code | Description |
|------------|-------------|-------------|
| `AuthenticationError` | 401 | Invalid API credentials |
| `InvalidRequestError` | 400 | Bad request parameters |
| `ModelNotFoundError` | 404 | Model not available |
| `ContentFilterError` | 403 | Content blocked by filters |
| `RateLimitError` | 429 | Rate limit exceeded |
| `ProviderError` | 500 | Generic provider error |
| `ServiceUnavailableError` | 503 | Service temporarily down |
| `TimeoutError` | 504 | Request timeout |

---

## Retry Configuration

### Default Settings

```ruby
with_retry(
  max_attempts: 3,           # Maximum retry attempts
  initial_delay: 1.0,        # Initial delay in seconds
  max_delay: 30.0,           # Maximum delay cap
  backoff_multiplier: 2.0    # Exponential backoff multiplier
)
```

### Retry Behavior

**Attempt 1:** Immediate
**Attempt 2:** Wait 1 second
**Attempt 3:** Wait 2 seconds (1 * 2)
**Attempt 4:** Wait 4 seconds (2 * 2)

### Custom Retry Configuration

```ruby
# More aggressive retry
with_retry(max_attempts: 5, initial_delay: 0.5) do
  # code
end

# Conservative retry
with_retry(max_attempts: 2, initial_delay: 2.0) do
  # code
end
```

---

## Logging

### Error Logs

All errors are logged with structured JSON:

```json
{
  "error_class": "LlmErrors::RateLimitError",
  "message": "Rate limit exceeded",
  "provider": "openai",
  "backtrace": ["app/services/llm/openai_service.rb:23:in `stream_completion'"],
  "model": "gpt-4-turbo"
}
```

### Retry Logs

Retry attempts are logged as warnings:

```json
{
  "message": "Retrying after error",
  "error": "LlmErrors::ProviderError",
  "attempt": 2,
  "delay": 2.0,
  "error_message": "Connection failed"
}
```

### Controller Logs

Controller errors include request context:

```json
{
  "error_class": "LlmErrors::AuthenticationError",
  "message": "Authentication failed",
  "controller": "Api::V1::ChatController",
  "action": "create",
  "params": {"message": "Hello", "model": "gpt-4-turbo"},
  "backtrace": ["..."]
}
```

---

## Testing

### Testing Error Handling

```ruby
# RSpec example
RSpec.describe Llm::OpenaiService do
  describe "#stream_completion" do
    context "when API returns rate limit error" do
      before do
        allow_any_instance_of(OpenAI::Client)
          .to receive(:chat)
          .and_raise(OpenAI::Errors::RateLimitError.new("Rate limit"))
      end

      it "raises LlmErrors::RateLimitError" do
        expect {
          service.stream_completion(messages: [], model: "gpt-4")
        }.to raise_error(LlmErrors::RateLimitError)
      end

      it "retries up to 3 times" do
        # Test retry logic
      end
    end
  end
end
```

### Testing Retry Logic

```ruby
RSpec.describe Concerns::Retryable do
  it "retries retryable errors" do
    attempts = 0

    expect {
      service.with_retry(max_attempts: 3) do
        attempts += 1
        raise LlmErrors::ProviderError.new("Temporary failure")
      end
    }.to raise_error(LlmErrors::ProviderError)

    expect(attempts).to eq(3)
  end

  it "does not retry non-retryable errors" do
    attempts = 0

    expect {
      service.with_retry(max_attempts: 3) do
        attempts += 1
        raise LlmErrors::AuthenticationError.new("Invalid key")
      end
    }.to raise_error(LlmErrors::AuthenticationError)

    expect(attempts).to eq(1)
  end
end
```

---

## Best Practices

### 1. Always Use Custom Errors

❌ **Bad:**
```ruby
raise "OpenAI error: #{e.message}"
```

✅ **Good:**
```ruby
handle_provider_error(e, provider: "openai")
```

### 2. Include Context in Errors

✅ **Good:**
```ruby
raise LlmErrors::InvalidRequestError.new(
  "Invalid model name",
  provider: provider_name,
  original_error: e
)
```

### 3. Log Before Raising

✅ **Good:**
```ruby
log_error(e, provider: provider_name, model: model)
handle_provider_error(e, provider: provider_name)
```

### 4. Use Appropriate Error Types

```ruby
# Authentication issues
raise LlmErrors::AuthenticationError

# Bad parameters
raise LlmErrors::InvalidRequestError

# Temporary failures
raise LlmErrors::ProviderError
```

### 5. Don't Leak Sensitive Information

❌ **Bad:**
```ruby
render json: { error: error.message, backtrace: error.backtrace }
```

✅ **Good:**
```ruby
render json: { error: error.user_message }
```

---

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Error Rate by Type**
   - Track `LlmErrors::RateLimitError` for capacity planning
   - Monitor `LlmErrors::AuthenticationError` for config issues
   - Watch `LlmErrors::TimeoutError` for performance degradation

2. **Retry Success Rate**
   - Percentage of requests that succeed after retry
   - Average retry attempts per request

3. **Provider Availability**
   - Error rate by provider (OpenAI, Anthropic, Google)
   - Response times per provider

### Alert Thresholds

- **Critical:** > 10% error rate overall
- **Warning:** > 5% error rate for specific provider
- **Info:** > 20% requests requiring retry

---

## Future Enhancements

### Planned Improvements

1. **Circuit Breaker Pattern**
   - Prevent cascading failures
   - Automatically disable failing providers
   - Gradual recovery with health checks

2. **Error Rate Limiting**
   - Track error patterns per user/API key
   - Implement backoff for problematic clients

3. **Dead Letter Queue**
   - Store failed requests for later analysis
   - Automatic retry of queued requests

4. **Enhanced Monitoring**
   - Integration with error tracking (Sentry, Rollbar)
   - Real-time dashboards
   - Automated alerting

5. **Error Recovery Strategies**
   - Fallback to alternative providers
   - Cached response serving during outages
   - Graceful degradation modes

---

## Configuration

### Environment Variables

```bash
# Retry configuration (optional)
LLM_MAX_RETRY_ATTEMPTS=3
LLM_INITIAL_RETRY_DELAY=1.0
LLM_MAX_RETRY_DELAY=30.0
```

### Customization

Extend error types by adding to `app/errors/llm_errors.rb`:

```ruby
module LlmErrors
  class CustomError < BaseError
    def retryable?
      true
    end

    def user_message
      "Custom error occurred"
    end
  end
end
```

---

## Troubleshooting

### Common Issues

**Issue:** Errors not being caught
- **Solution:** Ensure `Concerns::ErrorHandling` is included in ApplicationController

**Issue:** Infinite retry loops
- **Solution:** Check `retryable?` method returns false for non-retryable errors

**Issue:** Generic error messages in production
- **Solution:** This is intentional - check logs for detailed error information

**Issue:** Missing error context
- **Solution:** Use `handle_provider_error` instead of raising directly

---

## Summary

This centralized error handling system provides:

✅ **Consistent** error handling across all LLM providers
✅ **Resilient** automatic retry with exponential backoff
✅ **Informative** structured logging for debugging
✅ **User-friendly** error messages without technical details
✅ **Maintainable** single source of truth for error handling
✅ **Extensible** easy to add new error types and providers

For implementation details, see:
- `app/errors/llm_errors.rb` - Error classes
- `app/services/concerns/error_handler.rb` - Error mapping
- `app/services/concerns/retryable.rb` - Retry logic
- `app/controllers/concerns/error_handling.rb` - Controller handling
