# Jarvis Live FastAPI Backend - API Endpoints

## Overview

The Jarvis Live Python backend provides a comprehensive FastAPI-based REST API and WebSocket interface for iOS client integration. The backend orchestrates multiple MCP (Meta-Cognitive Primitive) servers to provide AI, voice processing, document generation, email, and search capabilities.

## Base URL
- **Development:** `http://localhost:8000`
- **Production:** `https://your-domain.com`

## Core Endpoints

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "mcp_servers": {
    "document": {"status": "running", "capabilities": ["generate_pdf", "generate_docx"]},
    "email": {"status": "running", "capabilities": ["send_email", "compose_email"]},
    "search": {"status": "running", "capabilities": ["web_search", "fact_check"]},
    "ai_providers": {"status": "running", "capabilities": ["claude_chat", "gpt_chat"]},
    "voice": {"status": "running", "capabilities": ["speech_to_text", "text_to_speech"]}
  },
  "redis_status": "connected",
  "websocket_connections": 3
}
```

### MCP Server Status
```http
GET /mcp/status
```

**Response:**
```json
{
  "document": {
    "name": "document",
    "status": "running",
    "capabilities": ["generate_pdf", "generate_docx", "generate_markdown"],
    "last_ping": 1640995200.0
  },
  "email": {
    "name": "email", 
    "status": "running",
    "capabilities": ["send_email", "compose_email", "validate_email"],
    "last_ping": 1640995200.0
  }
}
```

## AI Provider Endpoints

### Process AI Request
```http
POST /ai/process
```

**Request Body:**
```json
{
  "provider": "claude",
  "prompt": "What is the capital of Australia?",
  "context": [
    {"role": "user", "content": "Previous message"},
    {"role": "assistant", "content": "Previous response"}
  ],
  "model": "claude-3-5-sonnet-20241022",
  "temperature": 0.7,
  "max_tokens": 1000,
  "stream": false
}
```

**Response:**
```json
{
  "provider": "claude",
  "response": "The capital of Australia is Canberra.",
  "model_used": "claude-3-5-sonnet-20241022",
  "usage": {
    "input_tokens": 15,
    "output_tokens": 12,
    "total_tokens": 27
  },
  "processing_time": 1.2
}
```

## Voice Processing Endpoints

### Process Voice Input
```http
POST /voice/process
```

**Request Body:**
```json
{
  "audio_data": "base64_encoded_audio_data",
  "format": "wav",
  "sample_rate": 44100,
  "channels": 1,
  "ai_provider": "claude",
  "voice_id": "default"
}
```

**Response:**
```json
{
  "transcription": "Hello, what is the weather today?",
  "ai_response": "I'd be happy to help with weather information, but I don't have access to real-time weather data.",
  "audio_response": "base64_encoded_audio_response",
  "processing_time": 2.5,
  "transcription_confidence": 0.95,
  "voice_synthesis_time": 1.2
}
```

## Document Generation Endpoints

### Generate Document
```http
POST /documents/generate
```

**Request Body:**
```json
{
  "content": "This is the document content that will be converted to the specified format.",
  "format": "pdf",
  "template": "business_letter",
  "title": "Sample Document",
  "author": "Jarvis Live",
  "options": {
    "filename": "sample_document.pdf"
  }
}
```

**Response:**
```json
{
  "document_data": "base64_encoded_document_data",
  "format": "pdf",
  "file_size": 12485,
  "filename": "sample_document.pdf",
  "processing_time": 0.8,
  "template_used": "business_letter"
}
```

## Email Endpoints

### Send Email
```http
POST /email/send
```

**Request Body:**
```json
{
  "to": "recipient@example.com",
  "subject": "Test Email from Jarvis Live",
  "body": "This is a test email sent through the Jarvis Live backend.",
  "cc": ["cc@example.com"],
  "bcc": ["bcc@example.com"],
  "attachments": [
    {
      "filename": "document.pdf",
      "data": "base64_encoded_file_data",
      "content_type": "application/pdf"
    }
  ],
  "template": "professional",
  "priority": "normal"
}
```

**Response:**
```json
{
  "message_id": "uuid-message-id",
  "status": "sent",
  "sent_at": "2024-01-01 12:00:00 UTC",
  "processing_time": 1.5,
  "recipients": 3
}
```

### Compose Email
```http
POST /email/compose
```

**Request Body:**
```json
{
  "prompt": "Write a professional email asking for a meeting next week",
  "recipient_context": {
    "name": "John Doe",
    "company": "Acme Corp"
  },
  "template": "professional",
  "tone": "professional"
}
```

**Response:**
```json
{
  "subject": "Meeting Request for Next Week",
  "body": "Dear John Doe,\n\nI hope this email finds you well...",
  "tone": "professional",
  "template_used": "professional",
  "word_count": 85,
  "estimated_read_time": 1
}
```

## Search Endpoints

### Web Search
```http
POST /search/web
```

**Request Body:**
```json
{
  "query": "latest developments in AI technology",
  "num_results": 10,
  "search_type": "general",
  "safe_search": true,
  "language": "en"
}
```

**Response:**
```json
{
  "query": "latest developments in AI technology",
  "results": [
    {
      "title": "AI Technology Breakthrough 2024",
      "url": "https://example.com/ai-news",
      "snippet": "Recent developments in artificial intelligence...",
      "source": "bing",
      "relevance_score": 0.95
    }
  ],
  "total_results": 10,
  "processing_time": 1.8,
  "search_engines": ["bing", "duckduckgo"]
}
```

### Fact Check
```http
POST /search/fact-check
```

**Request Body:**
```json
{
  "statement": "The Earth is the third planet from the Sun",
  "sources": ["wikipedia", "britannica"]
}
```

**Response:**
```json
{
  "statement": "The Earth is the third planet from the Sun",
  "fact_check_sources": [
    {
      "title": "Earth - Wikipedia",
      "url": "https://en.wikipedia.org/wiki/Earth",
      "snippet": "Earth is the third planet from the Sun...",
      "source": "wikipedia"
    }
  ],
  "credibility_indicators": [],
  "confidence_level": "high",
  "recommendation": "Statement verified by authoritative sources"
}
```

## WebSocket Endpoints

### Real-time Communication
```
WebSocket: ws://localhost:8000/ws/{client_id}
```

**Connection:**
- Replace `{client_id}` with a unique identifier for the iOS client
- The server will send a welcome message upon connection

**Message Types:**

#### Audio Processing
```json
{
  "type": "audio",
  "audio_data": "base64_encoded_audio_chunk",
  "format": "wav",
  "sample_rate": 44100,
  "sequence": 1,
  "is_final": false
}
```

#### AI Request
```json
{
  "type": "ai_request",
  "provider": "claude",
  "prompt": "Hello, how are you?",
  "context": [],
  "model": "claude-3-5-sonnet-20241022"
}
```

#### MCP Command
```json
{
  "type": "mcp_command",
  "server_name": "document",
  "command": "generate_document",
  "params": {
    "content": "Sample content",
    "format": "pdf"
  }
}
```

**Server Responses:**

#### Audio Response
```json
{
  "type": "audio_response",
  "transcription": "Hello, how are you?",
  "ai_response": "I'm doing well, thank you for asking!",
  "audio_response": "base64_encoded_audio",
  "processing_time": 2.1
}
```

#### AI Response
```json
{
  "type": "ai_response",
  "provider": "claude",
  "response": "I'm doing well, thank you for asking!",
  "model_used": "claude-3-5-sonnet-20241022",
  "usage": {"total_tokens": 25},
  "processing_time": 1.2
}
```

## Error Handling

All endpoints return standardized error responses:

```json
{
  "error": "ValidationError",
  "message": "Invalid request format",
  "code": 400,
  "details": {
    "field": "audio_data",
    "issue": "Base64 decoding failed"
  },
  "timestamp": 1640995200.0
}
```

### Common HTTP Status Codes
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid API key)
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error
- `503` - Service Unavailable (MCP server down)

## Rate Limiting

- **AI Requests:** 100 requests per minute per client
- **Voice Processing:** 50 requests per minute per client
- **Document Generation:** 20 requests per minute per client
- **Email Sending:** 10 requests per minute per client
- **Web Search:** 30 requests per minute per client

## Authentication

Currently, the API uses environment-based API key configuration. Future versions will implement:
- JWT token-based authentication
- API key management per client
- Rate limiting per authenticated user

## Development Usage

### Start Minimal Server (for testing)
```bash
cd _python
python3 -m uvicorn src.main_minimal:app --host 0.0.0.0 --port 8000 --reload
```

### Start Full Server (requires dependencies)
```bash
cd _python
pip install -r requirements.txt
python3 start_server.py --dev
```

### API Documentation
- **Interactive Docs:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **OpenAPI Schema:** http://localhost:8000/openapi.json

## iOS Integration

The FastAPI backend is designed for seamless iOS integration:

1. **RESTful API** for standard request/response operations
2. **WebSocket** for real-time voice processing
3. **Base64 encoding** for audio/document data
4. **JSON responses** compatible with Swift Codable
5. **CORS enabled** for cross-origin requests during development

### iOS Example Usage

```swift
// Health check
let response = try await URLSession.shared.data(from: URL(string: "http://localhost:8000/health")!)

// WebSocket connection
let webSocket = URLSessionWebSocketTask(session: URLSession.shared, url: URL(string: "ws://localhost:8000/ws/ios-client-1")!)
await webSocket.send(.string("{\"type\":\"ping\"}"))
```

This backend provides a robust foundation for the Jarvis Live iOS voice AI assistant with comprehensive MCP server integration.