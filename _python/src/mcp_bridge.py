"""
* Purpose: MCP protocol bridge for coordinating multiple MCP servers
* Issues & Complexity Summary: Complex multi-server coordination with fallback mechanisms
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~500
  - Core Algorithm Complexity: High (multi-server orchestration)
  - Dependencies: Multiple MCP servers + Redis
  - State Management Complexity: High (server states + session management)
  - Novelty/Uncertainty Factor: High (MCP protocol implementation)
* AI Pre-Task Self-Assessment: 80%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 88%
* Final Code Complexity: 91%
* Overall Result Score: 87%
* Key Variances/Learnings: Complex async coordination between multiple MCP servers
* Last Updated: 2025-06-26
"""

import asyncio
import json
import logging
import time
from typing import Dict, List, Optional, Any, Union
import base64

import redis.asyncio as redis
from pydantic import BaseModel

from mcp.document_server import DocumentMCPServer
from mcp.email_server import EmailMCPServer
from mcp.search_server import SearchMCPServer
from mcp.ai_providers import AIProviderMCP
from mcp.voice_server import VoiceMCPServer

logger = logging.getLogger(__name__)


class MCPServerStatus(BaseModel):
    """Model for MCP server status"""

    name: str
    status: str  # "running", "stopped", "error"
    last_ping: Optional[float] = None
    error_message: Optional[str] = None
    capabilities: List[str] = []


class MCPBridge:
    """
    Bridge class for coordinating multiple MCP servers and providing
    unified interface for Jarvis Live iOS application
    """

    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.redis_client = redis_client
        self.servers: Dict[str, Any] = {}
        self.server_status: Dict[str, MCPServerStatus] = {}
        self.initialization_complete = False

        # Server configurations
        self.server_configs = {
            "document": {
                "class": DocumentMCPServer,
                "capabilities": [
                    "generate_pdf",
                    "generate_docx",
                    "generate_markdown",
                    "extract_text",
                ],
            },
            "email": {
                "class": EmailMCPServer,
                "capabilities": [
                    "send_email",
                    "read_inbox",
                    "compose_email",
                    "manage_contacts",
                ],
            },
            "search": {
                "class": SearchMCPServer,
                "capabilities": [
                    "web_search",
                    "knowledge_query",
                    "fact_check",
                    "research",
                ],
            },
            "ai_providers": {
                "class": AIProviderMCP,
                "capabilities": [
                    "claude_chat",
                    "gpt_chat",
                    "gemini_chat",
                    "model_selection",
                ],
            },
            "voice": {
                "class": VoiceMCPServer,
                "capabilities": [
                    "speech_to_text",
                    "text_to_speech",
                    "voice_synthesis",
                    "audio_processing",
                ],
            },
        }

    async def initialize(self):
        """Initialize all MCP servers"""
        logger.info("Initializing MCP Bridge...")

        try:
            # Initialize each server
            for server_name, config in self.server_configs.items():
                logger.info(f"Initializing {server_name} MCP server...")

                server_class = config["class"]
                server_instance = server_class(redis_client=self.redis_client)

                # Initialize the server
                await server_instance.initialize()

                # Store server instance
                self.servers[server_name] = server_instance

                # Initialize status
                self.server_status[server_name] = MCPServerStatus(
                    name=server_name,
                    status="initialized",
                    capabilities=config["capabilities"],
                )

                logger.info(f"{server_name} MCP server initialized successfully")

            self.initialization_complete = True
            logger.info("MCP Bridge initialization complete")

        except Exception as e:
            logger.error(f"MCP Bridge initialization failed: {str(e)}")
            raise

    async def start_all_servers(self):
        """Start all MCP servers"""
        if not self.initialization_complete:
            raise RuntimeError("MCP Bridge not initialized")

        logger.info("Starting all MCP servers...")

        for server_name, server in self.servers.items():
            try:
                await server.start()
                self.server_status[server_name].status = "running"
                self.server_status[server_name].last_ping = time.time()
                logger.info(f"{server_name} MCP server started")

            except Exception as e:
                logger.error(f"Failed to start {server_name} MCP server: {str(e)}")
                self.server_status[server_name].status = "error"
                self.server_status[server_name].error_message = str(e)

    async def shutdown(self):
        """Shutdown all MCP servers"""
        logger.info("Shutting down MCP Bridge...")

        for server_name, server in self.servers.items():
            try:
                await server.shutdown()
                self.server_status[server_name].status = "stopped"
                logger.info(f"{server_name} MCP server shut down")

            except Exception as e:
                logger.error(f"Error shutting down {server_name}: {str(e)}")

        logger.info("MCP Bridge shutdown complete")

    async def get_server_status(self, server_name: str) -> Optional[MCPServerStatus]:
        """Get status of a specific MCP server"""
        if server_name not in self.server_status:
            return None

        # Ping the server to get current status
        try:
            if server_name in self.servers:
                await self.servers[server_name].ping()
                self.server_status[server_name].last_ping = time.time()

        except Exception as e:
            self.server_status[server_name].status = "error"
            self.server_status[server_name].error_message = str(e)

        return self.server_status[server_name]

    async def get_all_server_status(self) -> Dict[str, MCPServerStatus]:
        """Get status of all MCP servers"""
        status_dict = {}

        for server_name in self.servers.keys():
            status = await self.get_server_status(server_name)
            if status:
                status_dict[server_name] = status

        return status_dict

    async def route_ai_request(
        self,
        provider: str,
        prompt: str,
        context: List[Dict] = None,
        model: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Route AI request to appropriate provider through AI MCP server"""
        if "ai_providers" not in self.servers:
            raise RuntimeError("AI providers MCP server not available")

        start_time = time.time()

        try:
            ai_server = self.servers["ai_providers"]

            result = await ai_server.process_request(
                provider=provider, prompt=prompt, context=context or [], model=model
            )

            processing_time = time.time() - start_time
            result["processing_time"] = processing_time

            return result

        except Exception as e:
            logger.error(f"AI request routing failed: {str(e)}")
            raise

    async def process_voice_input(
        self,
        audio_data: Union[str, bytes],
        format: str = "wav",
        sample_rate: int = 44100,
    ) -> Dict[str, Any]:
        """Process voice input through voice MCP server"""
        if "voice" not in self.servers:
            raise RuntimeError("Voice MCP server not available")

        start_time = time.time()

        try:
            voice_server = self.servers["voice"]

            # Convert base64 audio data if needed
            if isinstance(audio_data, str):
                audio_data = base64.b64decode(audio_data)

            # Process speech-to-text
            transcription_result = await voice_server.speech_to_text(
                audio_data=audio_data, format=format, sample_rate=sample_rate
            )

            transcription = transcription_result.get("text", "")

            if not transcription:
                return {
                    "transcription": "",
                    "ai_response": "",
                    "audio_response": None,
                    "processing_time": time.time() - start_time,
                }

            # Route transcription to AI provider (default to Claude)
            ai_result = await self.route_ai_request(
                provider="claude", prompt=transcription, context=[]
            )

            ai_response = ai_result.get("content", "")

            # Convert AI response to speech
            if ai_response:
                tts_result = await voice_server.text_to_speech(
                    text=ai_response,
                    voice_id="21m00Tcm4TlvDq8ikWAM",  # ElevenLabs default
                    format="mp3",
                )

                audio_response = tts_result.get("audio_data")
            else:
                audio_response = None

            processing_time = time.time() - start_time

            return {
                "transcription": transcription,
                "ai_response": ai_response,
                "audio_response": audio_response,
                "processing_time": processing_time,
            }

        except Exception as e:
            logger.error(f"Voice processing failed: {str(e)}")
            raise

    async def generate_document(
        self,
        content: str,
        format: str = "pdf",
        template: Optional[str] = None,
        options: Dict[str, Any] = None,
    ) -> Dict[str, Any]:
        """Generate document through document MCP server"""
        if "document" not in self.servers:
            raise RuntimeError("Document MCP server not available")

        try:
            document_server = self.servers["document"]

            result = await document_server.generate_document(
                content=content, format=format, template=template, options=options or {}
            )

            return result

        except Exception as e:
            logger.error(f"Document generation failed: {str(e)}")
            raise

    async def send_email(
        self,
        to: str,
        subject: str,
        body: str,
        attachments: List[Dict] = None,
        cc: List[str] = None,
        bcc: List[str] = None,
    ) -> Dict[str, Any]:
        """Send email through email MCP server"""
        if "email" not in self.servers:
            raise RuntimeError("Email MCP server not available")

        try:
            email_server = self.servers["email"]

            result = await email_server.send_email(
                to=to,
                subject=subject,
                body=body,
                attachments=attachments or [],
                cc=cc or [],
                bcc=bcc or [],
            )

            return result

        except Exception as e:
            logger.error(f"Email sending failed: {str(e)}")
            raise

    async def search_web(
        self, query: str, num_results: int = 10, search_type: str = "general"
    ) -> Dict[str, Any]:
        """Perform web search through search MCP server"""
        if "search" not in self.servers:
            raise RuntimeError("Search MCP server not available")

        try:
            search_server = self.servers["search"]

            result = await search_server.web_search(
                query=query, num_results=num_results, search_type=search_type
            )

            return result

        except Exception as e:
            logger.error(f"Web search failed: {str(e)}")
            raise

    async def execute_command(
        self, server_name: str, command: str, params: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Execute arbitrary command on specific MCP server"""
        if server_name not in self.servers:
            raise RuntimeError(f"MCP server '{server_name}' not available")

        try:
            server = self.servers[server_name]

            # Check if server has the command
            if not hasattr(server, command):
                raise AttributeError(
                    f"Server '{server_name}' does not support command '{command}'"
                )

            # Execute the command
            method = getattr(server, command)
            result = await method(**params)

            return result

        except Exception as e:
            logger.error(f"Command execution failed: {str(e)}")
            raise

    async def health_check(self) -> Dict[str, Any]:
        """Perform health check on all MCP servers"""
        health_status = {
            "bridge_status": "healthy" if self.initialization_complete else "unhealthy",
            "servers": {},
        }

        for server_name in self.servers.keys():
            try:
                status = await self.get_server_status(server_name)
                health_status["servers"][server_name] = {
                    "status": status.status if status else "unknown",
                    "last_ping": status.last_ping if status else None,
                    "capabilities": status.capabilities if status else [],
                }

            except Exception as e:
                health_status["servers"][server_name] = {
                    "status": "error",
                    "error": str(e),
                    "capabilities": [],
                }

        return health_status

    async def get_server_capabilities(self, server_name: str) -> List[str]:
        """Get capabilities of a specific MCP server"""
        if server_name in self.server_configs:
            return self.server_configs[server_name]["capabilities"]
        return []

    async def get_all_capabilities(self) -> Dict[str, List[str]]:
        """Get capabilities of all MCP servers"""
        capabilities = {}

        for server_name, config in self.server_configs.items():
            capabilities[server_name] = config["capabilities"]

        return capabilities
