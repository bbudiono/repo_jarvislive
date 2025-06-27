"""
Test-focused FastAPI application with authentication but no heavy dependencies
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from src.auth.jwt_auth import get_current_user, JWTAuth
from src.api.auth_routes import router as auth_router
from pydantic import BaseModel
from typing import Dict, List, Optional
import time

# Create FastAPI app
app = FastAPI(
    title="Jarvis Live API (Test)",
    description="Test version of Jarvis Live API with authentication",
    version="1.0.0-test",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include authentication routes
app.include_router(auth_router)


# Models for testing
class VoiceClassificationRequest(BaseModel):
    text: str
    session_id: str
    context: Optional[Dict] = {}


class VoiceClassificationResponse(BaseModel):
    category: str
    intent: str
    confidence: float
    parameters: Dict
    suggestions: List[str]
    processing_time: float


class DocumentRequest(BaseModel):
    content: str
    format: str
    template: Optional[str] = "standard"


class EmailRequest(BaseModel):
    to: List[str]
    subject: str
    body: str
    attachments: Optional[List] = []


class SearchRequest(BaseModel):
    query: str
    max_results: Optional[int] = 10


class AIRequest(BaseModel):
    provider: str
    prompt: str
    context: Optional[Dict] = {}


# Test routes with authentication
@app.get("/health")
async def health_check():
    """Health check endpoint - no auth required"""
    return {
        "status": "healthy",
        "version": "1.0.0-test",
        "mcp_servers": {
            "document": {
                "status": "simulated",
                "capabilities": ["generate_pdf", "generate_docx"],
            },
            "email": {
                "status": "simulated",
                "capabilities": ["send_email", "compose_email"],
            },
            "search": {
                "status": "simulated",
                "capabilities": ["web_search", "fact_check"],
            },
            "ai_providers": {
                "status": "simulated",
                "capabilities": ["claude_chat", "gpt_chat"],
            },
            "voice": {
                "status": "simulated",
                "capabilities": ["speech_to_text", "text_to_speech"],
            },
        },
        "redis_status": "simulated",
        "websocket_connections": 0,
    }


@app.post("/voice/classify", response_model=VoiceClassificationResponse)
async def classify_voice_command(
    request: VoiceClassificationRequest, current_user: dict = Depends(get_current_user)
):
    """Classify voice command with authentication"""
    # Simulate classification
    return VoiceClassificationResponse(
        category="document_generation",
        intent="create_pdf",
        confidence=0.95,
        parameters={"content": "test content", "format": "pdf"},
        suggestions=["Consider adding formatting"],
        processing_time=0.045,
    )


@app.get("/voice/categories")
async def get_voice_categories(current_user: dict = Depends(get_current_user)):
    """Get voice command categories"""
    return {
        "categories": [
            {
                "name": "document_generation",
                "description": "Generate documents",
                "examples": ["Create a PDF", "Generate report"],
            },
            {
                "name": "email_management",
                "description": "Email operations",
                "examples": ["Send email", "Compose message"],
            },
        ]
    }


@app.get("/voice/metrics")
async def get_voice_metrics(current_user: dict = Depends(get_current_user)):
    """Get voice processing metrics"""
    return {
        "total_classifications": 1250,
        "average_confidence": 0.87,
        "average_processing_time": 0.042,
        "categories_distribution": {
            "document_generation": 450,
            "email_management": 380,
            "search": 420,
        },
    }


@app.post("/document/generate")
async def generate_document(
    request: DocumentRequest, current_user: dict = Depends(get_current_user)
):
    """Generate document with authentication"""
    return {
        "document_id": "doc_123456",
        "download_url": "https://example.com/documents/doc_123456.pdf",
        "format": request.format,
        "size_bytes": 245760,
        "generation_time": 2.34,
    }


@app.post("/email/send")
async def send_email(
    request: EmailRequest, current_user: dict = Depends(get_current_user)
):
    """Send email with authentication"""
    return {"message_id": "msg_789012", "status": "sent", "delivery_time": 1.23}


@app.post("/search/web")
async def search_web(
    request: SearchRequest, current_user: dict = Depends(get_current_user)
):
    """Search web with authentication"""
    return {
        "results": [
            {
                "title": "AI Development Guide",
                "url": "https://example.com/ai-guide",
                "snippet": "Comprehensive guide to AI development...",
                "relevance_score": 0.95,
            }
        ],
        "total_found": 1250,
        "search_time": 0.67,
    }


@app.post("/ai/process")
async def process_ai_request(
    request: AIRequest, current_user: dict = Depends(get_current_user)
):
    """Process AI request with authentication"""
    return {
        "response": "This is the AI-generated response to your query.",
        "provider_used": request.provider,
        "tokens_used": 150,
        "processing_time": 1.45,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main_test_simple:app", host="0.0.0.0", port=8000, reload=True)
