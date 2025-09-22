# Chatsapp - AI Chat Application

A modern Rails 8.0+ chat application with multi-AI provider support, featuring OpenAI and Anthropic integration.

## Features

* **Multi-AI Provider Support**: OpenAI (GPT-4, GPT-4o, GPT-3.5) and Anthropic (Claude 3.5 Sonnet, Claude 3 Opus, Claude 3 Sonnet, Claude 3 Haiku)
* **Real-time Chat**: Hotwire (Turbo + Stimulus) for SPA-like experience
* **Modern UI**: TailwindCSS with responsive design
* **Production Ready**: Docker + Kamal deployment, comprehensive CI/CD
* **Database-backed Services**: Rails 8 Solid suite (Cache, Queue, Cable)

## Requirements

* Ruby 3.3.0
* PostgreSQL
* Node.js and Yarn
* Docker (for deployment)

## Getting Started

1. **Setup the application**:
   ```bash
   bin/setup
   ```

2. **Configure AI API keys**:
   ```bash
   # Edit Rails credentials
   EDITOR='code --wait' bin/rails credentials:edit

   # Add your API keys:
   openai_api_key: your_openai_api_key_here
   anthropic_api_key: your_anthropic_api_key_here
   ```

3. **Start the development server**:
   ```bash
   bin/dev
   ```

4. **Visit the application**:
   Open http://localhost:3000 in your browser

## Development

* **Run tests**: `bin/rails test`
* **Code linting**: `bin/rubocop`
* **Security scan**: `bin/brakeman`
* **Asset building**: `yarn build` and `yarn build:css`

## Deployment

The application is configured for deployment with Docker and Kamal:

```bash
# Deploy to production
bin/kamal deploy
```

## Architecture

* **Rails 8.0+** with modern conventions
* **PostgreSQL** with multi-database setup for production
* **Hotwire** for frontend interactivity
* **Background Jobs** with Solid Queue
* **Real-time Updates** with Solid Cable (WebSockets)
* **Centralized Logging** with structured error handling
