# 🚀 LLM Chat Backend - Start Here

Welcome to your multi-provider LLM chat backend! This Rails application provides SSE streaming chat with OpenAI, Anthropic, and Google Gemini.

## 📚 Documentation Guide

Choose your path based on what you need:

### 🎯 Quick Start (5 minutes)

**File**: [`SETUP.md`](SETUP.md)

Get the app running quickly:

1. Install dependencies
2. Configure API keys
3. Setup database
4. Test with curl commands

**Start here if**: You want to get up and running immediately.

---

### 📖 Complete API Reference

**File**: [`README_CHAT.md`](README_CHAT.md)

Comprehensive documentation including:

- All API endpoints with examples
- Request/response formats
- Available models per provider
- Frontend integration examples (JavaScript)
- Project structure overview

**Start here if**: You're building a frontend or need API details.

---

### 🧪 Testing Guide

**File**: [`TESTING.md`](TESTING.md)

Test all three providers:

- curl examples for each provider
- JavaScript testing code
- Troubleshooting common issues
- Conversation history testing

**Start here if**: You want to test the system thoroughly.

---

### 🏗️ Implementation Details

**File**: [`IMPLEMENTATION_SUMMARY.md`](IMPLEMENTATION_SUMMARY.md)

Deep dive into:

- Architecture decisions
- How providers are integrated
- Request flow diagrams
- Future enhancement roadmap

**Start here if**: You want to understand the codebase or extend it.

---

## 🎬 Quick Demo

```bash
# 1. Setup (first time only)
bundle install
cp .env.example .env
# Edit .env with your API keys
rails db:create db:migrate

# 2. Start server
rails server

# 3. Test (in another terminal)
./test_providers.sh your-api-key
```

## ✨ Key Features

| Feature | Status | Details |
|---------|--------|---------|
| **OpenAI Support** | ✅ | Official SDK, GPT-3.5/4 models |
| **Anthropic Support** | ✅ | Official SDK, Claude 3 models |
| **Google Gemini Support** | ✅ | HTTP API, Gemini 1.5 models |
| **SSE Streaming** | ✅ | Real-time token delivery |
| **Auto Provider Detection** | ✅ | From model name prefix |
| **Conversation History** | ✅ | PostgreSQL storage |
| **API Authentication** | ✅ | Bearer token |

## 🗺️ Project Structure

```
.
├── app/
│   ├── controllers/api/v1/     # API endpoints
│   ├── models/                 # Conversation & Message
│   └── services/               # LlmService (multi-provider)
├── db/migrate/                 # Database migrations
├── config/                     # Rails configuration
├── SETUP.md                    # ⭐ Quick start guide
├── README_CHAT.md              # ⭐ API documentation
├── TESTING.md                  # ⭐ Testing guide
├── IMPLEMENTATION_SUMMARY.md   # ⭐ Architecture details
└── test_providers.sh           # Quick test script
```

## 🎯 Recommended Learning Path

1. **Run it**: Follow `SETUP.md` (5 min)
2. **Test it**: Use `TESTING.md` curl examples (5 min)
3. **Understand it**: Read `IMPLEMENTATION_SUMMARY.md` (10 min)
4. **Build with it**: Use `README_CHAT.md` API reference (ongoing)

## 🔑 Environment Variables

You need **at least one** provider API key:

```bash
# Choose one or more providers
OPENAI_API_KEY=sk-...              # For GPT models
ANTHROPIC_API_KEY=sk-ant-...       # For Claude models
GOOGLE_API_KEY=AIza...             # For Gemini models

# Required for API auth
API_KEYS=your-test-key,another-key
```

## 🚦 Quick Health Check

```bash
# Check if server is running
curl http://localhost:3000/api/v1/health

# Expected response:
# {"status":"ok","timestamp":"...","openai":true}
```

## 💬 Example Request

```bash
curl -X POST http://localhost:3000/api/v1/chat \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello!",
    "model": "gpt-3.5-turbo"
  }'
```

## 🎨 Supported Models

**OpenAI**: `gpt-4-turbo`, `gpt-4`, `gpt-3.5-turbo`
**Anthropic**: `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`
**Google**: `gemini-1.5-pro`, `gemini-1.5-flash`, `gemini-1.0-pro`

## 🤝 Need Help?

1. **Setup issues**: Check `SETUP.md` troubleshooting section
2. **API questions**: See `README_CHAT.md` examples
3. **Testing problems**: Review `TESTING.md` troubleshooting
4. **Architecture questions**: Read `IMPLEMENTATION_SUMMARY.md`

## 🚀 Next Steps

After getting the basic setup working:

- [ ] Test all three providers
- [ ] Build a simple frontend
- [ ] Try different models
- [ ] Add conversation management
- [ ] Explore parallel multi-model (see IMPLEMENTATION_SUMMARY.md)

## 📝 License

MIT

---

**Made with ❤️ using official Ruby SDKs for OpenAI and Anthropic**