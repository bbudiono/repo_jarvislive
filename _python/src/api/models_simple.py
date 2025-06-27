"""
Simple API Models for Jarvis Live Backend
Core request/response models for validation
"""

from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional


# Authentication Models
class TokenRequest(BaseModel):
    """Request model for token generation"""

    api_key: str


class TokenResponse(BaseModel):
    """Response model for token generation"""

    access_token: str
    token_type: str = "bearer"
    expires_in: int = 86400  # 24 hours in seconds


# Voice Classification Models
class VoiceClassificationRequest(BaseModel):
    """Request for voice command classification"""

    text: str = Field(..., description="Voice command text to classify")
    session_id: str = Field(..., description="Session identifier")
    context: Optional[Dict[str, Any]] = Field(
        default={}, description="Conversation context"
    )


class VoiceClassificationResponse(BaseModel):
    """Response from voice command classification"""

    category: str = Field(..., description="Classified command category")
    intent: str = Field(..., description="Specific intent within category")
    confidence: float = Field(..., description="Classification confidence score")
    parameters: Dict[str, Any] = Field(default={}, description="Extracted parameters")
    suggestions: List[str] = Field(default=[], description="Follow-up suggestions")
    processing_time: float = Field(..., description="Processing time in seconds")


# Document Generation Models
class DocumentGenerationRequest(BaseModel):
    """Request for document generation"""

    content: str = Field(..., description="Document content")
    format: str = Field(default="pdf", description="Output format (pdf, docx, html)")
    template: Optional[str] = Field(default="standard", description="Template to use")


class DocumentGenerationResponse(BaseModel):
    """Response from document generation"""

    document_id: str = Field(..., description="Generated document ID")
    download_url: str = Field(..., description="URL to download document")
    format: str = Field(..., description="Document format")
    size_bytes: int = Field(..., description="Document size in bytes")
    generation_time: float = Field(..., description="Generation time in seconds")


# Email Models
class EmailSendRequest(BaseModel):
    """Request for sending email"""

    to: List[str] = Field(..., description="Recipient email addresses")
    subject: str = Field(..., description="Email subject")
    body: str = Field(..., description="Email body content")
    attachments: List[str] = Field(default=[], description="Attachment file paths")


class EmailSendResponse(BaseModel):
    """Response from email sending"""

    message_id: str = Field(..., description="Email message ID")
    status: str = Field(..., description="Delivery status")
    delivery_time: float = Field(..., description="Delivery time in seconds")


# Search Models
class WebSearchRequest(BaseModel):
    """Request for web search"""

    query: str = Field(..., description="Search query")
    max_results: int = Field(default=10, description="Maximum number of results")


class SearchResult(BaseModel):
    """Individual search result"""

    title: str = Field(..., description="Result title")
    url: str = Field(..., description="Result URL")
    snippet: str = Field(..., description="Result snippet")
    relevance_score: float = Field(..., description="Relevance score")


class WebSearchResponse(BaseModel):
    """Response from web search"""

    results: List[SearchResult] = Field(..., description="Search results")
    total_found: int = Field(..., description="Total results found")
    search_time: float = Field(..., description="Search time in seconds")


# AI Provider Models
class AIProviderRequest(BaseModel):
    """Request for AI processing"""

    provider: str = Field(..., description="AI provider to use")
    prompt: str = Field(..., description="Prompt text")
    context: Optional[Dict[str, Any]] = Field(
        default={}, description="Context information"
    )


class AIProviderResponse(BaseModel):
    """Response from AI processing"""

    response: str = Field(..., description="AI generated response")
    provider_used: str = Field(..., description="AI provider that was used")
    tokens_used: int = Field(..., description="Number of tokens consumed")
    processing_time: float = Field(..., description="Processing time in seconds")


# System Models
class HealthResponse(BaseModel):
    """Health check response"""

    status: str = Field(..., description="Overall system status")
    version: str = Field(..., description="API version")
    mcp_servers: Dict[str, str] = Field(..., description="MCP server statuses")
    redis_status: str = Field(..., description="Redis connection status")
    websocket_connections: int = Field(..., description="Active WebSocket connections")


# Categories Response
class VoiceCategoriesResponse(BaseModel):
    """Response with available voice categories"""

    categories: List[Dict[str, Any]] = Field(
        ..., description="Available command categories"
    )


# Metrics Response
class VoiceMetricsResponse(BaseModel):
    """Response with voice processing metrics"""

    total_classifications: int = Field(
        ..., description="Total classifications performed"
    )
    average_confidence: float = Field(..., description="Average confidence score")
    average_processing_time: float = Field(..., description="Average processing time")
    categories_distribution: Dict[str, int] = Field(
        ..., description="Category usage distribution"
    )
