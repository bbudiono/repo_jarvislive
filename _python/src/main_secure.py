"""
SECURE FastAPI Main Application for Jarvis Live MCP Backend
Implements JWT Bearer Token authentication on all endpoints
"""

import asyncio
import logging
import os
from contextlib import asynccontextmanager
from typing import Dict, List, Optional

import redis.asyncio as redis
import uvicorn
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from pydantic import BaseModel, Field

# Import authentication modules
from src.auth.jwt_auth import get_current_user, JWTAuth
from src.api.auth_routes import router as auth_router

# Import existing modules
from src.api.models import *
from src.api.websocket_manager import WebSocketManager
from src.mcp.voice_server import VoiceProcessingServer
from src.mcp.document_server import DocumentGenerationServer
from src.mcp.email_server import EmailServer
from src.mcp.search_server import SearchServer
from src.mcp.ai_providers import AIProvidersServer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global state management
websocket_manager = WebSocketManager()
redis_client: Optional[redis.Redis] = None

# MCP Servers
voice_server = VoiceProcessingServer()
document_server = DocumentGenerationServer()
email_server = EmailServer()
search_server = SearchServer()
ai_providers_server = AIProvidersServer()


class SecureJarvisLiveAPI:
    """Secure FastAPI application with JWT authentication"""

    def __init__(self):
        self.app = FastAPI(
            title="Jarvis Live MCP Backend (Secure)",
            description="Secure FastAPI backend with JWT authentication",
            version="1.0.0",
            lifespan=self.lifespan,
        )
        self.setup_middleware()
        self.setup_routes()

    @asynccontextmanager
    async def lifespan(self, app: FastAPI):
        """Application lifespan management"""
        # Startup
        logger.info("Starting Secure Jarvis Live MCP Backend...")
        await self.startup()

        yield

        # Shutdown
        logger.info("Shutting down Secure Jarvis Live MCP Backend...")
        await self.shutdown()

    async def startup(self):
        """Initialize services on startup"""
        global redis_client

        try:
            # Initialize Redis connection
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
            redis_client = redis.from_url(redis_url)
            await redis_client.ping()
            logger.info("Redis connection established")

            # Initialize MCP servers
            await voice_server.initialize()
            await document_server.initialize()
            await email_server.initialize()
            await search_server.initialize()
            await ai_providers_server.initialize()

            logger.info("All MCP servers initialized")

        except Exception as e:
            logger.error(f"Startup failed: {e}")
            raise

    async def shutdown(self):
        """Cleanup on shutdown"""
        if redis_client:
            await redis_client.close()
        logger.info("Services shut down")

    def setup_middleware(self):
        """Configure CORS and other middleware"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],  # Configure for production
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    def setup_routes(self):
        """Set up all API routes with authentication"""

        # Include authentication router (no auth required for token endpoints)
        self.app.include_router(auth_router)

        # Health check endpoint (no auth required)
        @self.app.get("/health", response_model=HealthResponse)
        async def health_check():
            """Health check endpoint - no authentication required"""
            redis_status = "connected" if redis_client else "disconnected"

            mcp_status = {
                "voice": "healthy",
                "document": "healthy",
                "email": "healthy",
                "search": "healthy",
                "ai_providers": "healthy",
            }

            return HealthResponse(
                status="healthy",
                version="1.0.0",
                mcp_servers=mcp_status,
                redis_status=redis_status,
                websocket_connections=websocket_manager.get_connection_count(),
            )

        # PROTECTED ENDPOINTS - Require JWT authentication

        @self.app.post("/voice/classify", response_model=VoiceClassificationResponse)
        async def classify_voice_command(
            request: VoiceClassificationRequest,
            current_user: dict = Depends(get_current_user),
        ):
            """Classify voice command - PROTECTED"""
            try:
                result = await voice_server.classify_command(
                    text=request.text,
                    user_id=current_user.get("sub"),
                    session_id=request.session_id,
                    context=request.context,
                )

                return VoiceClassificationResponse(
                    category=result["category"],
                    intent=result["intent"],
                    confidence=result["confidence"],
                    parameters=result["parameters"],
                    suggestions=result.get("suggestions", []),
                    processing_time=result["processing_time"],
                )

            except Exception as e:
                logger.error(f"Voice classification error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.get("/voice/categories", response_model=VoiceCategoriesResponse)
        async def get_voice_categories(current_user: dict = Depends(get_current_user)):
            """Get available voice command categories - PROTECTED"""
            categories = await voice_server.get_categories()
            return VoiceCategoriesResponse(categories=categories)

        @self.app.get("/voice/metrics", response_model=VoiceMetricsResponse)
        async def get_voice_metrics(current_user: dict = Depends(get_current_user)):
            """Get voice processing metrics - PROTECTED"""
            metrics = await voice_server.get_metrics()
            return VoiceMetricsResponse(**metrics)

        @self.app.post("/document/generate", response_model=DocumentGenerationResponse)
        async def generate_document(
            request: DocumentGenerationRequest,
            current_user: dict = Depends(get_current_user),
        ):
            """Generate document - PROTECTED"""
            try:
                result = await document_server.generate_document(
                    content=request.content,
                    format=request.format,
                    template=request.template,
                    user_id=current_user.get("sub"),
                )

                return DocumentGenerationResponse(
                    document_id=result["document_id"],
                    download_url=result["download_url"],
                    format=result["format"],
                    size_bytes=result["size_bytes"],
                    generation_time=result["generation_time"],
                )

            except Exception as e:
                logger.error(f"Document generation error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/email/send", response_model=EmailSendResponse)
        async def send_email(
            request: EmailSendRequest, current_user: dict = Depends(get_current_user)
        ):
            """Send email - PROTECTED"""
            try:
                result = await email_server.send_email(
                    to=request.to,
                    subject=request.subject,
                    body=request.body,
                    attachments=request.attachments,
                    user_id=current_user.get("sub"),
                )

                return EmailSendResponse(
                    message_id=result["message_id"],
                    status=result["status"],
                    delivery_time=result["delivery_time"],
                )

            except Exception as e:
                logger.error(f"Email send error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/search/web", response_model=WebSearchResponse)
        async def search_web(
            request: WebSearchRequest, current_user: dict = Depends(get_current_user)
        ):
            """Perform web search - PROTECTED"""
            try:
                results = await search_server.search_web(
                    query=request.query,
                    max_results=request.max_results,
                    user_id=current_user.get("sub"),
                )

                return WebSearchResponse(
                    results=results["results"],
                    total_found=results["total_found"],
                    search_time=results["search_time"],
                )

            except Exception as e:
                logger.error(f"Web search error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/ai/process", response_model=AIProviderResponse)
        async def process_ai_request(
            request: AIProviderRequest, current_user: dict = Depends(get_current_user)
        ):
            """Process AI request - PROTECTED"""
            try:
                result = await ai_providers_server.process_request(
                    provider=request.provider,
                    prompt=request.prompt,
                    context=request.context,
                    user_id=current_user.get("sub"),
                )

                return AIProviderResponse(
                    response=result["response"],
                    provider_used=result["provider_used"],
                    tokens_used=result["tokens_used"],
                    processing_time=result["processing_time"],
                )

            except Exception as e:
                logger.error(f"AI processing error: {e}")
                raise HTTPException(status_code=500, detail=str(e))


# Create secure application instance
secure_app = SecureJarvisLiveAPI()
app = secure_app.app

if __name__ == "__main__":
    uvicorn.run(
        "main_secure:app", host="0.0.0.0", port=8000, reload=True, log_level="info"
    )
