# Voice Classification API Documentation

## Overview

The Voice Classification API provides advanced voice command classification and context management capabilities for the Jarvis Live iOS Voice AI Assistant. This system uses NLP-based intent recognition, confidence scoring, parameter extraction, and intelligent context management to enhance voice interaction quality.

## Base URL

```
http://localhost:8000
```

## Authentication

Currently, no authentication is required for development. Production deployment should implement proper authentication mechanisms.

## API Endpoints

### Voice Classification

#### Classify Voice Command

**POST** `/voice/classify`

Classify a voice command text into predefined categories with confidence scoring and parameter extraction.

**Request Body:**
```json
{
  "text": "create a document about machine learning",
  "user_id": "user123",
  "session_id": "session456",
  "use_context": true,
  "include_suggestions": true
}
```

**Response:**
```json
{
  "category": "document_generation",
  "intent": "document_generation_intent",
  "confidence": 0.85,
  "confidence_level": "high",
  "parameters": {
    "content_topic": "machine learning",
    "format": "pdf"
  },
  "context_used": true,
  "preprocessing_time": 0.002,
  "classification_time": 0.015,
  "suggestions": [],
  "requires_confirmation": false,
  "raw_text": "create a document about machine learning",
  "normalized_text": "create document about machine learning"
}
```

#### Get Available Categories

**GET** `/voice/categories`

Get list of available voice command categories.

**Response:**
```json
[
  "document_generation",
  "email_management",
  "calendar_scheduling",
  "web_search",
  "system_control",
  "calculations",
  "reminders",
  "general_conversation"
]
```

#### Get Category Patterns

**GET** `/voice/patterns/{category}`

Get example patterns and parameters for a specific category.

**Response:**
```json
{
  "category": "document_generation",
  "patterns": [
    {
      "patterns": [
        "\\b(create|generate|make|write)\\s+(document|doc|pdf|report|letter|memo)\\b"
      ],
      "examples": [
        "create a document about artificial intelligence",
        "generate a PDF report on sales data"
      ],
      "parameters": ["content_topic", "format", "template", "audience"]
    }
  ],
  "description": "Patterns and examples for document_generation commands"
}
```

#### Get Classifier Metrics

**GET** `/voice/metrics`

Get voice classifier performance metrics.

**Response:**
```json
{
  "classifier_metrics": {
    "total_classifications": 1542,
    "cache_hits": 342,
    "cache_hit_rate": 0.22,
    "average_classification_time": 0.018,
    "active_contexts": 15,
    "cached_results": 89
  },
  "timestamp": "2025-06-26T10:30:00Z",
  "status": "active"
}
```

#### Cleanup Classifier

**POST** `/voice/cleanup?timeout_minutes=30`

Clean up expired contexts and cache entries.

**Response:**
```json
{
  "status": "success",
  "message": "Cleaned up contexts older than 30 minutes",
  "timestamp": "2025-06-26T10:30:00Z"
}
```

### Context Management

#### Get Context Summary

**GET** `/context/{user_id}/{session_id}/summary`

Get conversation context summary for a specific user and session.

**Response:**
```json
{
  "user_id": "user123",
  "session_id": "session456",
  "total_interactions": 15,
  "categories_used": ["document_generation", "email_management"],
  "current_topic": "machine learning project",
  "recent_topics": ["AI research", "project planning"],
  "last_activity": "2025-06-26T10:25:00Z",
  "active_parameters": {
    "content_topic": "machine learning",
    "format": "pdf"
  },
  "session_duration": 25.5,
  "preferences": {}
}
```

#### Get Contextual Suggestions

**GET** `/context/{user_id}/{session_id}/suggestions`

Get contextual suggestions based on conversation history.

**Response:**
```json
{
  "suggestions": [
    "Generate another document on a different topic",
    "Create a PDF version of your document",
    "Send the document via email"
  ],
  "user_id": "user123",
  "session_id": "session456",
  "context_available": true
}
```

#### Update Context Interaction

**POST** `/context/{user_id}/{session_id}/interaction`

Update context with a new interaction.

**Request Body:**
```json
{
  "user_input": "create a document about AI",
  "bot_response": "I'll help you create a document about AI",
  "category": "document_generation",
  "parameters": {
    "content_topic": "AI"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Context updated successfully",
  "user_id": "user123",
  "session_id": "session456",
  "timestamp": "2025-06-26T10:30:00Z"
}
```

#### Get User Sessions

**GET** `/context/{user_id}/sessions`

Get all active sessions for a user.

**Response:**
```json
{
  "user_id": "user123",
  "sessions": ["session456", "session789"],
  "total_sessions": 2,
  "timestamp": "2025-06-26T10:30:00Z"
}
```

#### Clear Context

**DELETE** `/context/{user_id}/{session_id}`

Clear specific context for user/session.

**Response:**
```json
{
  "status": "success",
  "message": "Context cleared successfully",
  "user_id": "user123",
  "session_id": "session456",
  "timestamp": "2025-06-26T10:30:00Z"
}
```

#### Clear All User Contexts

**DELETE** `/context/{user_id}`

Clear all contexts for a user.

**Response:**
```json
{
  "status": "success",
  "message": "All user contexts cleared successfully",
  "user_id": "user123",
  "timestamp": "2025-06-26T10:30:00Z"
}
```

#### Get Context Metrics

**GET** `/context/metrics`

Get context manager performance metrics.

**Response:**
```json
{
  "context_metrics": {
    "cache_hits": 145,
    "cache_misses": 23,
    "cache_hit_rate": 0.86,
    "redis_operations": 168,
    "local_cache_size": 42,
    "redis_connected": true
  },
  "timestamp": "2025-06-26T10:30:00Z",
  "status": "active"
}
```

### Enhanced Audio Processing

#### Process Voice with Classification

**POST** `/audio/process`

Process voice audio with automatic command classification.

**Request Body:**
```json
{
  "audio_data": "base64_encoded_audio_data",
  "format": "wav",
  "sample_rate": 44100,
  "channels": 1,
  "ai_provider": "claude",
  "voice_id": "21m00Tcm4TlvDq8ikWAM"
}
```

**Response:**
```json
{
  "transcription": "create a document about machine learning",
  "ai_response": "I'll help you create a document about machine learning",
  "audio_response": "base64_encoded_audio_response",
  "processing_time": 2.15,
  "transcription_confidence": 0.95,
  "voice_synthesis_time": 0.8
}
```

## Command Categories

### Document Generation
- **Intent**: Create, generate, or write documents
- **Examples**: 
  - "create a PDF document about AI"
  - "generate a report on sales data"
  - "write a letter to the customer"
- **Parameters**: content_topic, format, template, audience

### Email Management
- **Intent**: Send, compose, or manage emails
- **Examples**:
  - "send an email to john@example.com"
  - "compose a message about the project"
  - "write an email to the team"
- **Parameters**: recipient, subject, content, priority, attachments

### Calendar Scheduling
- **Intent**: Schedule meetings, appointments, or events
- **Examples**:
  - "schedule a meeting with the team"
  - "book an appointment for tomorrow"
  - "create an event for the conference"
- **Parameters**: date_time, duration, attendees, location, agenda

### Web Search
- **Intent**: Search for information online
- **Examples**:
  - "search for Python tutorials"
  - "what is machine learning"
  - "find information about climate change"
- **Parameters**: query, search_type, num_results

### System Control
- **Intent**: Control system functions or applications
- **Examples**:
  - "open the calculator app"
  - "increase the volume"
  - "turn off bluetooth"
- **Parameters**: action, target, value

### Calculations
- **Intent**: Perform mathematical calculations
- **Examples**:
  - "calculate 15 plus 27"
  - "what is 100 divided by 4"
  - "convert 100 USD to EUR"
- **Parameters**: expression, operation, units

### Reminders
- **Intent**: Set reminders or alerts
- **Examples**:
  - "remind me to call mom"
  - "set a reminder for the meeting"
  - "don't forget to buy groceries"
- **Parameters**: task, time, frequency, priority

### General Conversation
- **Intent**: General conversational interactions
- **Examples**:
  - "hello there"
  - "how are you doing"
  - "what can you help me with"
- **Parameters**: greeting_type, conversation_topic

## Confidence Levels

- **HIGH** (>0.8): High confidence classification, no confirmation needed
- **MEDIUM** (0.5-0.8): Medium confidence, may suggest alternatives
- **LOW** (0.3-0.5): Low confidence, confirmation recommended
- **VERY_LOW** (<0.3): Very low confidence, requires clarification

## Error Handling

All endpoints return standard HTTP status codes:

- **200**: Success
- **400**: Bad Request (invalid parameters)
- **404**: Not Found (resource doesn't exist)
- **500**: Internal Server Error

Error responses follow this format:
```json
{
  "error": "ValidationError",
  "message": "Missing required field: user_input",
  "code": 400,
  "details": {},
  "timestamp": "2025-06-26T10:30:00Z"
}
```

## Performance Considerations

### Caching
- Classification results are cached for 1 hour
- Context data is cached in Redis with 24-hour TTL
- Local cache maintains 100 most recent contexts

### Rate Limiting
- No rate limiting implemented in development
- Production should implement appropriate rate limiting

### Batch Processing
- Support for batch classification requests
- Automatic queue management for high-load scenarios
- Priority handling (high, normal, low)

## Integration Examples

### iOS Swift Integration

```swift
// Classification request
struct ClassificationRequest: Codable {
    let text: String
    let userId: String
    let sessionId: String
    let useContext: Bool
    let includeSuggestions: Bool
}

// Usage
let request = ClassificationRequest(
    text: voiceInput,
    userId: currentUserId,
    sessionId: currentSessionId,
    useContext: true,
    includeSuggestions: true
)

let response = try await apiClient.classify(request)
```

### Python Client Integration

```python
import httpx

async def classify_voice_command(text: str, user_id: str, session_id: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8000/voice/classify",
            json={
                "text": text,
                "user_id": user_id,
                "session_id": session_id,
                "use_context": True,
                "include_suggestions": True
            }
        )
        return response.json()
```

## Testing

### Development Testing
```bash
# Start the server
cd _python
uvicorn src.main:app --reload --port 8000

# Test classification endpoint
curl -X POST "http://localhost:8000/voice/classify" \
  -H "Content-Type: application/json" \
  -d '{"text": "create a document about AI", "user_id": "test", "session_id": "test"}'

# Run test suite
pytest tests/test_voice_classifier.py -v
```

### Load Testing
```bash
# Install dependencies
pip install locust

# Run load tests
locust -f tests/load_test.py --host=http://localhost:8000
```

## Monitoring and Metrics

### Health Check
```bash
curl http://localhost:8000/health
```

### Performance Metrics
```bash
curl http://localhost:8000/voice/metrics
curl http://localhost:8000/context/metrics
```

## Future Enhancements

1. **Machine Learning Improvements**
   - Custom model training on user data
   - Continuous learning from user feedback
   - Multi-language support

2. **Advanced Context Management**
   - Cross-session context persistence
   - User preference learning
   - Conversation topic modeling

3. **Performance Optimizations**
   - GPU acceleration for classification
   - Distributed caching strategies
   - Real-time model updates

4. **Integration Features**
   - Webhook support for real-time notifications
   - GraphQL API support
   - Advanced analytics and reporting

---

*This documentation covers the Voice Classification API v1.0.0. For questions or issues, please refer to the project documentation or contact the development team.*