# AI Chat Application Setup

This is a Rails 8 chat application that allows users to chat with different AI models (OpenAI GPT and Anthropic Claude).

## Features

- 🤖 Multiple AI models support (GPT-4, GPT-3.5 Turbo, Claude 3 Sonnet, Claude 3 Haiku)
- 💬 Real-time chat interface with Hotwire/Turbo Streams
- 📱 Responsive design with TailwindCSS
- 💾 Conversation history and persistence
- ⚡ Background job processing for AI responses
- 🎨 Modern UI with message bubbles and typing indicators

## Setup Instructions

### 1. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install Node.js dependencies
yarn install
```

### 2. Database Setup

```bash
# Create and migrate the database
bin/rails db:create db:migrate
```

### 3. Configure AI API Keys

You have two options for configuring API keys:

#### Option A: Using Rails Credentials (Recommended)

```bash
# Edit credentials
bin/rails credentials:edit

# Add your API keys:
openai_api_key: your_openai_api_key_here
anthropic_api_key: your_anthropic_api_key_here
```

#### Option B: Using Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env and add your API keys
OPENAI_API_KEY=your_openai_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### 4. Get API Keys

- **OpenAI API Key**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
- **Anthropic API Key**: Get from [Anthropic Console](https://console.anthropic.com/)

### 5. Build Assets

```bash
# Build JavaScript
yarn build

# Build CSS
yarn build:css

# Or build both
bin/dev  # This watches for changes
```

### 6. Start the Application

```bash
# Development server with asset watching
bin/dev

# Or just the Rails server
bin/rails server
```

The application will be available at `http://localhost:3000`.

## Usage

1. **Home Page**: Choose an AI model and start a new conversation
2. **Chat Interface**: Send messages and receive AI responses in real-time
3. **Conversation Management**: View all conversations, delete unwanted ones
4. **Multiple Models**: Switch between different AI models for various use cases

## Architecture

- **Backend**: Rails 8 with PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus) with TailwindCSS
- **Real-time**: Turbo Streams for live updates
- **Background Jobs**: Solid Queue for AI API calls
- **AI Services**: Modular service classes for different providers

## File Structure

```
app/
├── controllers/          # Rails controllers
├── models/              # ActiveRecord models
├── services/            # AI service classes
├── jobs/                # Background jobs
├── views/               # ERB templates
└── javascript/          # Stimulus controllers

config/
└── routes.rb            # Application routes

db/
└── migrate/             # Database migrations
```

## Development

- Use `bin/dev` for development with asset watching
- Run `bin/rails test` to run the test suite
- Use `bin/rubocop` for code linting
- Use `bin/brakeman` for security scanning

## Deployment

The application is configured for deployment with Kamal and Docker. See the existing Docker and Kamal configuration files.

## Troubleshooting

1. **API Errors**: Check your API keys are correct and have sufficient credits
2. **Asset Issues**: Run `yarn build && yarn build:css` to rebuild assets
3. **Database Issues**: Run `bin/rails db:reset` to reset the database
4. **Job Queue**: Ensure Solid Queue is running for background AI responses

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request