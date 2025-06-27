"""
Minimal FastAPI application for testing basic functionality
This version works without heavy dependencies like ML libraries
"""

import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from typing import Dict

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from api.models import HealthResponse
from api.websocket_manager import WebSocketManager

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global state
websocket_manager = WebSocketManager()


class MinimalJarvisAPI:
    """Minimal version of Jarvis Live FastAPI backend for testing"""

    def __init__(self):
        self.app = FastAPI(
            title="Jarvis Live MCP Backend (Minimal)",
            description="Minimal FastAPI backend for testing Jarvis Live infrastructure",
            version="1.0.0-minimal",
            lifespan=self.lifespan,
        )
        self.setup_middleware()
        self.setup_routes()

    @asynccontextmanager
    async def lifespan(self, app: FastAPI):
        """Application lifespan management"""
        # Startup
        logger.info("Starting Jarvis Live MCP Backend (Minimal)...")
        await self.startup()

        yield

        # Shutdown
        logger.info("Shutting down Jarvis Live MCP Backend (Minimal)...")
        await self.shutdown()

    def setup_middleware(self):
        """Configure CORS and other middleware"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    def setup_routes(self):
        """Setup API routes"""

        @self.app.get("/health", response_model=HealthResponse)
        async def health_check():
            """Health check endpoint"""
            return HealthResponse(
                status="healthy",
                version="1.0.0-minimal",
                mcp_servers={
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
                redis_status="simulated",
                websocket_connections=websocket_manager.get_connection_count(),
            )

        @self.app.get("/mcp/status")
        async def get_mcp_status():
            """Get status of all MCP servers (simulated)"""
            return {
                "document": {
                    "name": "document",
                    "status": "simulated",
                    "capabilities": [
                        "generate_pdf",
                        "generate_docx",
                        "generate_markdown",
                    ],
                    "last_ping": time.time(),
                },
                "email": {
                    "name": "email",
                    "status": "simulated",
                    "capabilities": ["send_email", "compose_email", "validate_email"],
                    "last_ping": time.time(),
                },
                "search": {
                    "name": "search",
                    "status": "simulated",
                    "capabilities": ["web_search", "knowledge_query", "fact_check"],
                    "last_ping": time.time(),
                },
                "ai_providers": {
                    "name": "ai_providers",
                    "status": "simulated",
                    "capabilities": ["claude_chat", "gpt_chat", "gemini_chat"],
                    "last_ping": time.time(),
                },
                "voice": {
                    "name": "voice",
                    "status": "simulated",
                    "capabilities": [
                        "speech_to_text",
                        "text_to_speech",
                        "voice_synthesis",
                    ],
                    "last_ping": time.time(),
                },
            }

        @self.app.websocket("/ws/{client_id}")
        async def websocket_endpoint(websocket: WebSocket, client_id: str):
            """WebSocket endpoint for real-time communication"""
            await websocket_manager.connect(websocket, client_id)
            try:
                while True:
                    data = await websocket.receive_json()

                    # Echo back with processed response
                    response = {
                        "type": "echo",
                        "original_message": data,
                        "server_response": "Message received by minimal server",
                        "timestamp": time.time(),
                    }

                    await websocket_manager.send_personal_message(response, client_id)

            except WebSocketDisconnect:
                websocket_manager.disconnect(client_id)
                logger.info(f"Client {client_id} disconnected")

        @self.app.post("/ai/process")
        async def process_ai_request(request: dict):
            """Simulate AI processing"""
            return {
                "provider": request.get("provider", "claude"),
                "response": f"Simulated AI response to: {request.get('prompt', '')}",
                "model_used": "simulated-model",
                "usage": {"total_tokens": 100},
                "processing_time": 0.5,
            }

        @self.app.post("/voice/process")
        async def process_voice(request: dict):
            """Simulate voice processing"""
            return {
                "transcription": "Simulated transcription of audio input",
                "ai_response": "Simulated AI response to transcribed text",
                "audio_response": "base64_encoded_audio_data_here",
                "processing_time": 1.2,
            }

        @self.app.get("/")
        async def root():
            """Root endpoint"""
            return {
                "message": "Jarvis Live MCP Backend (Minimal) is running",
                "version": "1.0.0-minimal",
                "docs_url": "/docs",
                "health_url": "/health",
            }

    async def startup(self):
        """Initialize services on startup"""
        try:
            logger.info("Minimal backend initialized - all services simulated")

        except Exception as e:
            logger.error(f"Startup error: {str(e)}")
            raise

    async def shutdown(self):
        """Cleanup on shutdown"""
        try:
            await websocket_manager.shutdown()
            logger.info("Minimal backend shutdown complete")

        except Exception as e:
            logger.error(f"Shutdown error: {str(e)}")


# Create the FastAPI application instance
jarvis_api = MinimalJarvisAPI()
app = jarvis_api.app


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main_minimal:app", host="0.0.0.0", port=8000, reload=True, log_level="info"
    )
