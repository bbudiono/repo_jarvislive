"""
* Purpose: Main FastAPI application for Jarvis Live MCP server integration
* Issues & Complexity Summary: Multi-service integration with real-time WebSocket support
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: High (real-time audio + MCP orchestration)
  - Dependencies: 15+ external services
  - State Management Complexity: High (WebSocket sessions + MCP connections)
  - Novelty/Uncertainty Factor: Medium (LiveKit + MCP integration)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 90%
* Initial Code Complexity Estimate: 88%
* Final Code Complexity: 92%
* Overall Result Score: 90%
* Key Variances/Learnings: Complex WebSocket session management with MCP bridge
* Last Updated: 2025-06-26
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

from .mcp_bridge import MCPBridge
from .api.routes import (
    audio_router,
    ai_router,
    mcp_router,
    voice_router,
    context_router,
)
from .api.websocket_manager import WebSocketManager
from .ai.voice_classifier import voice_classifier
from .ai.context_manager import context_manager
from .api.models import (
    HealthResponse,
    AIProviderRequest,
    AIProviderResponse,
    MCPServerStatus,
    VoiceProcessingRequest,
    VoiceProcessingResponse,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Global state management
websocket_manager = WebSocketManager()
mcp_bridge: Optional[MCPBridge] = None
redis_client: Optional[redis.Redis] = None


class JarvisLiveAPI:
    """Main application class for Jarvis Live FastAPI backend"""

    def __init__(self):
        self.app = FastAPI(
            title="Jarvis Live MCP Backend",
            description="FastAPI backend for Jarvis Live iOS voice AI assistant",
            version="1.0.0",
            lifespan=self.lifespan,
        )
        self.setup_middleware()
        self.setup_routes()

    @asynccontextmanager
    async def lifespan(self, app: FastAPI):
        """Application lifespan management"""
        # Startup
        logger.info("Starting Jarvis Live MCP Backend...")
        await self.startup()

        yield

        # Shutdown
        logger.info("Shutting down Jarvis Live MCP Backend...")
        await self.shutdown()

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
        """Setup API routes"""
        # Include API routers
        self.app.include_router(audio_router)
        self.app.include_router(ai_router)
        self.app.include_router(mcp_router)
        self.app.include_router(voice_router)
        self.app.include_router(context_router)

        # Health check endpoint
        @self.app.get("/health", response_model=HealthResponse)
        async def health_check():
            """Health check endpoint"""
            mcp_status = {}
            if mcp_bridge:
                mcp_status = await mcp_bridge.get_all_server_status()

            redis_status = "disconnected"
            if redis_client:
                try:
                    await redis_client.ping()
                    redis_status = "connected"
                except Exception:
                    redis_status = "error"

            return HealthResponse(
                status="healthy",
                version="1.0.0",
                mcp_servers=mcp_status,
                redis_status=redis_status,
                websocket_connections=websocket_manager.get_connection_count(),
            )

        # WebSocket endpoint for real-time communication
        @self.app.websocket("/ws/{client_id}")
        async def websocket_endpoint(websocket: WebSocket, client_id: str):
            """WebSocket endpoint for real-time voice processing"""
            await websocket_manager.connect(websocket, client_id)
            try:
                while True:
                    # Receive audio data or commands from iOS client
                    data = await websocket.receive_json()

                    # Process different message types
                    if data.get("type") == "audio":
                        # Handle audio processing
                        response = await self.process_audio_message(data, client_id)
                        await websocket_manager.send_personal_message(
                            response, client_id
                        )

                    elif data.get("type") == "ai_request":
                        # Handle AI provider requests
                        response = await self.process_ai_request(data, client_id)
                        await websocket_manager.send_personal_message(
                            response, client_id
                        )

                    elif data.get("type") == "mcp_command":
                        # Handle MCP server commands
                        response = await self.process_mcp_command(data, client_id)
                        await websocket_manager.send_personal_message(
                            response, client_id
                        )

            except WebSocketDisconnect:
                websocket_manager.disconnect(client_id)
                logger.info(f"Client {client_id} disconnected")

        # AI Provider endpoint
        @self.app.post("/ai/process", response_model=AIProviderResponse)
        async def process_ai_request(request: AIProviderRequest):
            """Process AI requests through appropriate provider"""
            if not mcp_bridge:
                raise HTTPException(
                    status_code=503, detail="MCP bridge not initialized"
                )

            try:
                # Route to appropriate AI provider MCP server
                result = await mcp_bridge.route_ai_request(
                    provider=request.provider,
                    prompt=request.prompt,
                    context=request.context,
                    model=request.model,
                )

                return AIProviderResponse(
                    provider=request.provider,
                    response=result.get("content", ""),
                    model_used=result.get("model", request.model),
                    usage=result.get("usage", {}),
                    processing_time=result.get("processing_time", 0.0),
                )

            except Exception as e:
                logger.error(f"AI processing error: {str(e)}")
                raise HTTPException(
                    status_code=500, detail=f"AI processing failed: {str(e)}"
                )

        # MCP Server status endpoint
        @self.app.get("/mcp/status", response_model=Dict[str, MCPServerStatus])
        async def get_mcp_status():
            """Get status of all MCP servers"""
            if not mcp_bridge:
                raise HTTPException(
                    status_code=503, detail="MCP bridge not initialized"
                )

            return await mcp_bridge.get_all_server_status()

        # Voice processing endpoint
        @self.app.post("/voice/process", response_model=VoiceProcessingResponse)
        async def process_voice(request: VoiceProcessingRequest):
            """Process voice input through speech-to-text and AI"""
            try:
                # Use MCP bridge to process audio
                result = await mcp_bridge.process_voice_input(
                    audio_data=request.audio_data,
                    format=request.format,
                    sample_rate=request.sample_rate,
                )

                return VoiceProcessingResponse(
                    transcription=result.get("transcription", ""),
                    ai_response=result.get("ai_response", ""),
                    audio_response=result.get("audio_response"),
                    processing_time=result.get("processing_time", 0.0),
                )

            except Exception as e:
                logger.error(f"Voice processing error: {str(e)}")
                raise HTTPException(
                    status_code=500, detail=f"Voice processing failed: {str(e)}"
                )

    async def startup(self):
        """Initialize services on startup"""
        global mcp_bridge, redis_client

        try:
            # Initialize Redis connection
            redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
            redis_client = redis.from_url(redis_url, decode_responses=True)
            await redis_client.ping()
            logger.info("Redis connection established")

            # Initialize voice classifier
            await voice_classifier.initialize()
            logger.info("Voice classifier initialized")

            # Initialize context manager
            await context_manager.initialize()
            logger.info("Context manager initialized")

            # Initialize MCP bridge
            mcp_bridge = MCPBridge(redis_client=redis_client)
            await mcp_bridge.initialize()
            logger.info("MCP bridge initialized")

            # Start MCP servers
            await mcp_bridge.start_all_servers()
            logger.info("All MCP servers started")

        except Exception as e:
            logger.error(f"Startup error: {str(e)}")
            raise

    async def shutdown(self):
        """Cleanup on shutdown"""
        global mcp_bridge, redis_client

        try:
            if mcp_bridge:
                await mcp_bridge.shutdown()
                logger.info("MCP bridge shut down")

            if redis_client:
                await redis_client.close()
                logger.info("Redis connection closed")

        except Exception as e:
            logger.error(f"Shutdown error: {str(e)}")

    async def process_audio_message(self, data: dict, client_id: str) -> dict:
        """Process audio message from WebSocket"""
        try:
            audio_data = data.get("audio_data")
            format = data.get("format", "wav")
            sample_rate = data.get("sample_rate", 44100)

            if not mcp_bridge:
                return {"type": "error", "message": "MCP bridge not available"}

            result = await mcp_bridge.process_voice_input(
                audio_data=audio_data, format=format, sample_rate=sample_rate
            )

            return {
                "type": "audio_response",
                "transcription": result.get("transcription", ""),
                "ai_response": result.get("ai_response", ""),
                "audio_response": result.get("audio_response"),
                "processing_time": result.get("processing_time", 0.0),
            }

        except Exception as e:
            logger.error(f"Audio processing error: {str(e)}")
            return {"type": "error", "message": f"Audio processing failed: {str(e)}"}

    async def process_ai_request(self, data: dict, client_id: str) -> dict:
        """Process AI request from WebSocket"""
        try:
            provider = data.get("provider", "claude")
            prompt = data.get("prompt", "")
            context = data.get("context", [])
            model = data.get("model")

            if not mcp_bridge:
                return {"type": "error", "message": "MCP bridge not available"}

            result = await mcp_bridge.route_ai_request(
                provider=provider, prompt=prompt, context=context, model=model
            )

            return {
                "type": "ai_response",
                "provider": provider,
                "response": result.get("content", ""),
                "model_used": result.get("model", model),
                "usage": result.get("usage", {}),
                "processing_time": result.get("processing_time", 0.0),
            }

        except Exception as e:
            logger.error(f"AI request processing error: {str(e)}")
            return {"type": "error", "message": f"AI request failed: {str(e)}"}

    async def process_mcp_command(self, data: dict, client_id: str) -> dict:
        """Process MCP command from WebSocket"""
        try:
            command = data.get("command")
            server_name = data.get("server_name")
            params = data.get("params", {})

            if not mcp_bridge:
                return {"type": "error", "message": "MCP bridge not available"}

            result = await mcp_bridge.execute_command(
                server_name=server_name, command=command, params=params
            )

            return {
                "type": "mcp_response",
                "server_name": server_name,
                "command": command,
                "result": result,
                "processing_time": result.get("processing_time", 0.0),
            }

        except Exception as e:
            logger.error(f"MCP command processing error: {str(e)}")
            return {"type": "error", "message": f"MCP command failed: {str(e)}"}


# Create the FastAPI application instance
jarvis_api = JarvisLiveAPI()
app = jarvis_api.app


if __name__ == "__main__":
    # Run the server
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
