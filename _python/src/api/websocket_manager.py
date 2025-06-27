"""
* Purpose: WebSocket connection manager for real-time communication with iOS clients
* Issues & Complexity Summary: Complex connection lifecycle management with message routing
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~150
  - Core Algorithm Complexity: Medium (connection pooling + message routing)
  - Dependencies: FastAPI WebSocket + Redis
  - State Management Complexity: High (multiple client sessions)
  - Novelty/Uncertainty Factor: Medium
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 90%
* Initial Code Complexity Estimate: 88%
* Final Code Complexity: 89%
* Overall Result Score: 89%
* Key Variances/Learnings: Efficient WebSocket session management for iOS clients
* Last Updated: 2025-06-26
"""

import asyncio
import json
import logging
import time
from typing import Dict, List, Optional, Any
from fastapi import WebSocket, WebSocketDisconnect
import redis.asyncio as redis

logger = logging.getLogger(__name__)


class WebSocketConnection:
    """Represents a single WebSocket connection"""

    def __init__(self, websocket: WebSocket, client_id: str):
        self.websocket = websocket
        self.client_id = client_id
        self.connected_at = time.time()
        self.last_activity = time.time()
        self.message_count = 0
        self.is_active = True
        self.metadata: Dict[str, Any] = {}

    async def send_message(self, message: Dict[str, Any]):
        """Send message to client"""
        try:
            await self.websocket.send_json(message)
            self.last_activity = time.time()
            self.message_count += 1

        except Exception as e:
            logger.error(f"Failed to send message to {self.client_id}: {str(e)}")
            self.is_active = False
            raise

    async def receive_message(self) -> Dict[str, Any]:
        """Receive message from client"""
        try:
            message = await self.websocket.receive_json()
            self.last_activity = time.time()
            return message

        except Exception as e:
            logger.error(f"Failed to receive message from {self.client_id}: {str(e)}")
            self.is_active = False
            raise

    def get_connection_stats(self) -> Dict[str, Any]:
        """Get connection statistics"""
        return {
            "client_id": self.client_id,
            "connected_at": self.connected_at,
            "last_activity": self.last_activity,
            "message_count": self.message_count,
            "uptime": time.time() - self.connected_at,
            "is_active": self.is_active,
            "metadata": self.metadata,
        }


class WebSocketManager:
    """
    Manages WebSocket connections for Jarvis Live iOS clients
    Handles connection lifecycle, message routing, and session management
    """

    def __init__(self, redis_client: Optional[redis.Redis] = None):
        self.active_connections: Dict[str, WebSocketConnection] = {}
        self.redis_client = redis_client
        self.connection_groups: Dict[str, List[str]] = {}  # For grouping connections
        self.message_handlers: Dict[str, callable] = {}
        self.cleanup_task: Optional[asyncio.Task] = None

        # Initialize cleanup task as None - will be started when needed
        self.cleanup_task = None

    def start_cleanup_task(self):
        """Start the cleanup task"""
        if self.cleanup_task is None:
            self.cleanup_task = asyncio.create_task(
                self._cleanup_inactive_connections()
            )

    async def connect(self, websocket: WebSocket, client_id: str) -> bool:
        """Accept new WebSocket connection"""
        try:
            await websocket.accept()

            # Create connection object
            connection = WebSocketConnection(websocket, client_id)

            # Store connection
            self.active_connections[client_id] = connection

            # Store in Redis if available
            if self.redis_client:
                await self._store_connection_in_redis(client_id, connection)

            logger.info(f"WebSocket connection established for client: {client_id}")

            # Send welcome message
            await self.send_personal_message(
                {
                    "type": "connection_established",
                    "client_id": client_id,
                    "server_time": time.time(),
                    "message": "Connected to Jarvis Live backend",
                },
                client_id,
            )

            return True

        except Exception as e:
            logger.error(
                f"Failed to establish WebSocket connection for {client_id}: {str(e)}"
            )
            return False

    def disconnect(self, client_id: str):
        """Disconnect client and cleanup"""
        if client_id in self.active_connections:
            connection = self.active_connections[client_id]
            connection.is_active = False
            del self.active_connections[client_id]

            # Remove from Redis if available
            if self.redis_client:
                asyncio.create_task(self._remove_connection_from_redis(client_id))

            # Remove from any groups
            for group_name, members in self.connection_groups.items():
                if client_id in members:
                    members.remove(client_id)

            logger.info(f"WebSocket connection closed for client: {client_id}")

    async def send_personal_message(
        self, message: Dict[str, Any], client_id: str
    ) -> bool:
        """Send message to specific client"""
        if client_id not in self.active_connections:
            logger.warning(
                f"Attempted to send message to non-existent client: {client_id}"
            )
            return False

        try:
            connection = self.active_connections[client_id]

            # Add timestamp to message
            message["timestamp"] = time.time()
            message["client_id"] = client_id

            await connection.send_message(message)
            return True

        except Exception as e:
            logger.error(f"Failed to send personal message to {client_id}: {str(e)}")
            self.disconnect(client_id)
            return False

    async def broadcast_message(
        self, message: Dict[str, Any], exclude_clients: List[str] = None
    ) -> int:
        """Broadcast message to all connected clients"""
        exclude_clients = exclude_clients or []
        sent_count = 0

        message["timestamp"] = time.time()
        message["type"] = message.get("type", "broadcast")

        # Send to all active connections
        for client_id in list(self.active_connections.keys()):
            if client_id not in exclude_clients:
                if await self.send_personal_message(message, client_id):
                    sent_count += 1

        logger.info(f"Broadcast message sent to {sent_count} clients")
        return sent_count

    async def send_to_group(self, group_name: str, message: Dict[str, Any]) -> int:
        """Send message to all clients in a specific group"""
        if group_name not in self.connection_groups:
            logger.warning(
                f"Attempted to send message to non-existent group: {group_name}"
            )
            return 0

        sent_count = 0
        client_ids = self.connection_groups[group_name].copy()

        for client_id in client_ids:
            if await self.send_personal_message(message, client_id):
                sent_count += 1

        logger.info(
            f"Group message sent to {sent_count} clients in group: {group_name}"
        )
        return sent_count

    def add_to_group(self, client_id: str, group_name: str):
        """Add client to a group"""
        if client_id not in self.active_connections:
            logger.warning(
                f"Attempted to add non-existent client to group: {client_id}"
            )
            return False

        if group_name not in self.connection_groups:
            self.connection_groups[group_name] = []

        if client_id not in self.connection_groups[group_name]:
            self.connection_groups[group_name].append(client_id)
            logger.info(f"Added client {client_id} to group {group_name}")

        return True

    def remove_from_group(self, client_id: str, group_name: str):
        """Remove client from a group"""
        if group_name in self.connection_groups:
            if client_id in self.connection_groups[group_name]:
                self.connection_groups[group_name].remove(client_id)
                logger.info(f"Removed client {client_id} from group {group_name}")

    def get_connection_count(self) -> int:
        """Get number of active connections"""
        return len(self.active_connections)

    def get_connection_stats(self) -> Dict[str, Any]:
        """Get comprehensive connection statistics"""
        stats = {
            "total_connections": len(self.active_connections),
            "groups": {
                name: len(members) for name, members in self.connection_groups.items()
            },
            "connections": {},
        }

        for client_id, connection in self.active_connections.items():
            stats["connections"][client_id] = connection.get_connection_stats()

        return stats

    def get_client_connection(self, client_id: str) -> Optional[WebSocketConnection]:
        """Get specific client connection"""
        return self.active_connections.get(client_id)

    def is_client_connected(self, client_id: str) -> bool:
        """Check if client is connected"""
        return (
            client_id in self.active_connections
            and self.active_connections[client_id].is_active
        )

    async def ping_client(self, client_id: str) -> bool:
        """Ping specific client to check connection"""
        if not self.is_client_connected(client_id):
            return False

        try:
            await self.send_personal_message(
                {"type": "ping", "timestamp": time.time()}, client_id
            )
            return True

        except Exception as e:
            logger.error(f"Failed to ping client {client_id}: {str(e)}")
            return False

    async def ping_all_clients(self) -> Dict[str, bool]:
        """Ping all clients and return results"""
        results = {}

        for client_id in list(self.active_connections.keys()):
            results[client_id] = await self.ping_client(client_id)

        return results

    async def _cleanup_inactive_connections(self):
        """Background task to cleanup inactive connections"""
        while True:
            try:
                await asyncio.sleep(60)  # Check every minute

                current_time = time.time()
                inactive_threshold = 300  # 5 minutes

                inactive_clients = []

                for client_id, connection in self.active_connections.items():
                    if (current_time - connection.last_activity) > inactive_threshold:
                        inactive_clients.append(client_id)

                for client_id in inactive_clients:
                    logger.info(f"Cleaning up inactive connection: {client_id}")
                    self.disconnect(client_id)

                if inactive_clients:
                    logger.info(
                        f"Cleaned up {len(inactive_clients)} inactive connections"
                    )

            except Exception as e:
                logger.error(f"Error in connection cleanup: {str(e)}")

    async def _store_connection_in_redis(
        self, client_id: str, connection: WebSocketConnection
    ):
        """Store connection info in Redis"""
        try:
            connection_data = {
                "client_id": client_id,
                "connected_at": connection.connected_at,
                "server_instance": "main",  # Could be server ID for load balancing
                "metadata": connection.metadata,
            }

            await self.redis_client.hset(
                f"ws_connections:{client_id}", mapping=connection_data
            )

            # Set expiration
            await self.redis_client.expire(f"ws_connections:{client_id}", 3600)

        except Exception as e:
            logger.error(f"Failed to store connection in Redis: {str(e)}")

    async def _remove_connection_from_redis(self, client_id: str):
        """Remove connection info from Redis"""
        try:
            await self.redis_client.delete(f"ws_connections:{client_id}")

        except Exception as e:
            logger.error(f"Failed to remove connection from Redis: {str(e)}")

    async def shutdown(self):
        """Shutdown WebSocket manager"""
        logger.info("Shutting down WebSocket manager...")

        # Cancel cleanup task
        if self.cleanup_task:
            self.cleanup_task.cancel()

        # Disconnect all clients
        for client_id in list(self.active_connections.keys()):
            try:
                await self.send_personal_message(
                    {"type": "server_shutdown", "message": "Server is shutting down"},
                    client_id,
                )
            except:
                pass

            self.disconnect(client_id)

        logger.info("WebSocket manager shutdown complete")
