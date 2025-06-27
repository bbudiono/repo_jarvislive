"""
* Purpose: Pydantic models for API request/response validation
* Issues & Complexity Summary: Comprehensive data validation for all API endpoints
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~200
  - Core Algorithm Complexity: Low (data validation)
  - Dependencies: Pydantic validation
  - State Management Complexity: Low
  - Novelty/Uncertainty Factor: Low
* AI Pre-Task Self-Assessment: 95%
* Problem Estimate: 90%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 88%
* Overall Result Score: 92%
* Key Variances/Learnings: Comprehensive validation models for voice/AI integration
* Last Updated: 2025-06-26
"""

from typing import Dict, List, Optional, Any, Union
from pydantic import BaseModel, Field, validator
from enum import Enum


class AIProvider(str, Enum):
    """Supported AI providers"""

    CLAUDE = "claude"
    GPT4 = "gpt4"
    GEMINI = "gemini"


class AudioFormat(str, Enum):
    """Supported audio formats"""

    WAV = "wav"
    MP3 = "mp3"
    FLAC = "flac"
    AAC = "aac"


class DocumentFormat(str, Enum):
    """Supported document formats"""

    PDF = "pdf"
    DOCX = "docx"
    MARKDOWN = "markdown"
    TXT = "txt"


class HealthResponse(BaseModel):
    """Health check response model"""

    status: str
    version: str
    mcp_servers: Dict[str, Any] = {}
    redis_status: str = "unknown"
    websocket_connections: int = 0
    timestamp: Optional[float] = None


class AIProviderRequest(BaseModel):
    """Request model for AI provider processing"""

    provider: AIProvider
    prompt: str = Field(..., min_length=1, max_length=10000)
    context: List[Dict[str, Any]] = Field(default_factory=list)
    model: Optional[str] = None
    temperature: Optional[float] = Field(default=0.7, ge=0.0, le=2.0)
    max_tokens: Optional[int] = Field(default=1000, ge=1, le=4000)
    stream: bool = False

    @validator("context")
    def validate_context(cls, v):
        if len(v) > 50:  # Limit context history
            raise ValueError("Context history too long")
        return v


class AIProviderResponse(BaseModel):
    """Response model for AI provider processing"""

    provider: AIProvider
    response: str
    model_used: str
    usage: Dict[str, Any] = Field(default_factory=dict)
    processing_time: float
    tokens_used: Optional[int] = None
    cost_estimate: Optional[float] = None


class VoiceProcessingRequest(BaseModel):
    """Request model for voice processing"""

    audio_data: str = Field(..., description="Base64 encoded audio data")
    format: AudioFormat = AudioFormat.WAV
    sample_rate: int = Field(default=44100, ge=8000, le=48000)
    channels: int = Field(default=1, ge=1, le=2)
    ai_provider: AIProvider = AIProvider.CLAUDE
    voice_id: Optional[str] = Field(default="21m00Tcm4TlvDq8ikWAM")

    @validator("audio_data")
    def validate_audio_data(cls, v):
        if not v:
            raise ValueError("Audio data cannot be empty")
        # Basic base64 validation
        try:
            import base64

            base64.b64decode(v)
        except Exception:
            raise ValueError("Invalid base64 audio data")
        return v


class VoiceProcessingResponse(BaseModel):
    """Response model for voice processing"""

    transcription: str
    ai_response: str
    audio_response: Optional[str] = Field(description="Base64 encoded audio response")
    processing_time: float
    transcription_confidence: Optional[float] = None
    voice_synthesis_time: Optional[float] = None


class DocumentGenerationRequest(BaseModel):
    """Request model for document generation"""

    content: str = Field(..., min_length=1)
    format: DocumentFormat = DocumentFormat.PDF
    template: Optional[str] = None
    title: Optional[str] = None
    author: Optional[str] = None
    options: Dict[str, Any] = Field(default_factory=dict)


class DocumentGenerationResponse(BaseModel):
    """Response model for document generation"""

    document_data: str = Field(description="Base64 encoded document")
    format: DocumentFormat
    file_size: int
    processing_time: float
    filename: str


class EmailRequest(BaseModel):
    """Request model for email sending"""

    to: str = Field(..., pattern=r"^[^@]+@[^@]+\.[^@]+$")
    subject: str = Field(..., min_length=1, max_length=500)
    body: str = Field(..., min_length=1)
    cc: List[str] = Field(default_factory=list)
    bcc: List[str] = Field(default_factory=list)
    attachments: List[Dict[str, Any]] = Field(default_factory=list)
    priority: str = Field(default="normal", pattern=r"^(low|normal|high)$")

    @validator("cc", "bcc")
    def validate_email_lists(cls, v):
        for email in v:
            if not email or "@" not in email:
                raise ValueError(f"Invalid email address: {email}")
        return v


class EmailResponse(BaseModel):
    """Response model for email sending"""

    message_id: str
    status: str
    sent_at: str
    processing_time: float


class SearchRequest(BaseModel):
    """Request model for web search"""

    query: str = Field(..., min_length=1, max_length=500)
    num_results: int = Field(default=10, ge=1, le=50)
    search_type: str = Field(default="general")
    safe_search: bool = True
    language: str = Field(default="en")


class SearchResult(BaseModel):
    """Individual search result model"""

    title: str
    url: str
    snippet: str
    source: str
    relevance_score: Optional[float] = None


class SearchResponse(BaseModel):
    """Response model for web search"""

    query: str
    results: List[SearchResult]
    total_results: int
    processing_time: float
    search_engine: str


class MCPServerStatus(BaseModel):
    """MCP server status model"""

    name: str
    status: str
    last_ping: Optional[float] = None
    error_message: Optional[str] = None
    capabilities: List[str] = Field(default_factory=list)
    uptime: Optional[float] = None
    memory_usage: Optional[float] = None


class MCPCommandRequest(BaseModel):
    """Request model for MCP command execution"""

    server_name: str
    command: str
    params: Dict[str, Any] = Field(default_factory=dict)
    timeout: Optional[float] = Field(default=30.0, ge=1.0, le=300.0)


class MCPCommandResponse(BaseModel):
    """Response model for MCP command execution"""

    server_name: str
    command: str
    result: Dict[str, Any]
    processing_time: float
    status: str


class WebSocketMessage(BaseModel):
    """Base WebSocket message model"""

    type: str
    client_id: str
    timestamp: Optional[float] = None
    data: Dict[str, Any] = Field(default_factory=dict)


class AudioStreamMessage(WebSocketMessage):
    """WebSocket message for audio streaming"""

    type: str = "audio"
    audio_data: str = Field(description="Base64 encoded audio chunk")
    sequence: int = Field(default=0)
    is_final: bool = Field(default=False)
    format: AudioFormat = AudioFormat.WAV
    sample_rate: int = Field(default=44100)


class AIStreamMessage(WebSocketMessage):
    """WebSocket message for AI streaming"""

    type: str = "ai_stream"
    provider: AIProvider
    content: str
    is_complete: bool = Field(default=False)
    usage: Dict[str, Any] = Field(default_factory=dict)


class ErrorResponse(BaseModel):
    """Standard error response model"""

    error: str
    message: str
    code: int
    details: Optional[Dict[str, Any]] = None
    timestamp: Optional[float] = None


class BatchRequest(BaseModel):
    """Request model for batch processing"""

    requests: List[Dict[str, Any]] = Field(..., min_items=1, max_items=100)
    batch_id: Optional[str] = None
    priority: str = Field(default="normal")


class BatchResponse(BaseModel):
    """Response model for batch processing"""

    batch_id: str
    results: List[Dict[str, Any]]
    successful: int
    failed: int
    processing_time: float
    errors: List[Dict[str, Any]] = Field(default_factory=list)


class ServerMetrics(BaseModel):
    """Server performance metrics model"""

    cpu_usage: float
    memory_usage: float
    disk_usage: float
    network_io: Dict[str, float]
    active_connections: int
    requests_per_minute: float
    error_rate: float
    uptime: float


class ConfigurationRequest(BaseModel):
    """Request model for server configuration"""

    component: str
    settings: Dict[str, Any]
    environment: str = Field(default="production")


class ConfigurationResponse(BaseModel):
    """Response model for server configuration"""

    component: str
    settings: Dict[str, Any]
    applied: bool
    restart_required: bool
    errors: List[str] = Field(default_factory=list)
