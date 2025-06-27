"""
* Purpose: Advanced context management system for voice conversations
* Issues & Complexity Summary: Session management, context persistence, and intelligent context updates
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: Medium (context tracking, session management)
  - Dependencies: Redis, async operations, custom context models
  - State Management Complexity: High (multi-user, multi-session context)
  - Novelty/Uncertainty Factor: Medium (complex context relationships)
* AI Pre-Task Self-Assessment: 88%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 87%
* Final Code Complexity: 89%
* Overall Result Score: 88%
* Key Variances/Learnings: Complex context management with Redis persistence
* Last Updated: 2025-06-26
"""

import asyncio
import json
import logging
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import redis.asyncio as redis
import pickle
import hashlib

from .voice_classifier import ConversationContext, CommandCategory


# Configure logging
logger = logging.getLogger(__name__)


@dataclass
class ContextUpdateEvent:
    """Event for context updates"""

    user_id: str
    session_id: str
    event_type: str  # "interaction", "parameter_update", "topic_change"
    data: Dict[str, Any]
    timestamp: datetime


class ContextManager:
    """Advanced context management with Redis persistence"""

    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_url = redis_url
        self.redis_client: Optional[redis.Redis] = None
        self.local_cache: Dict[str, ConversationContext] = {}
        self.context_ttl = 3600 * 24  # 24 hours
        self.cache_sync_interval = 300  # 5 minutes
        self.max_local_cache_size = 100

        # Performance tracking
        self.cache_hits = 0
        self.cache_misses = 0
        self.redis_operations = 0

        logger.info("ContextManager initialized")

    async def initialize(self):
        """Initialize Redis connection"""
        try:
            self.redis_client = redis.from_url(self.redis_url, decode_responses=False)
            await self.redis_client.ping()
            logger.info("Redis connection established")

            # Start background cache sync task
            asyncio.create_task(self._background_cache_sync())

        except Exception as e:
            logger.warning(f"Redis connection failed: {e}. Using local cache only.")
            self.redis_client = None

    def _get_context_key(self, user_id: str, session_id: str) -> str:
        """Generate context key for storage"""
        return f"context:{user_id}:{session_id}"

    def _get_user_sessions_key(self, user_id: str) -> str:
        """Generate user sessions key"""
        return f"user_sessions:{user_id}"

    async def get_context(
        self, user_id: str, session_id: str, create_if_missing: bool = True
    ) -> Optional[ConversationContext]:
        """Get conversation context with Redis fallback"""
        context_key = f"{user_id}_{session_id}"

        # Check local cache first
        if context_key in self.local_cache:
            self.cache_hits += 1
            context = self.local_cache[context_key]

            # Check if context is expired
            if not context.is_context_expired():
                return context
            else:
                # Remove expired context
                del self.local_cache[context_key]

        # Try Redis if available
        if self.redis_client:
            try:
                redis_key = self._get_context_key(user_id, session_id)
                data = await self.redis_client.get(redis_key)
                self.redis_operations += 1

                if data:
                    context = pickle.loads(data)
                    # Update local cache
                    self.local_cache[context_key] = context
                    self._manage_cache_size()
                    return context

            except Exception as e:
                logger.error(f"Redis get context failed: {e}")

        self.cache_misses += 1

        # Create new context if requested
        if create_if_missing:
            context = ConversationContext(user_id=user_id, session_id=session_id)
            await self.save_context(context)
            return context

        return None

    async def save_context(self, context: ConversationContext):
        """Save conversation context to both local cache and Redis"""
        context_key = f"{context.user_id}_{context.session_id}"

        # Update local cache
        self.local_cache[context_key] = context
        self._manage_cache_size()

        # Save to Redis if available
        if self.redis_client:
            try:
                redis_key = self._get_context_key(context.user_id, context.session_id)
                data = pickle.dumps(context)

                # Save with TTL
                await self.redis_client.setex(redis_key, self.context_ttl, data)

                # Track user sessions
                user_sessions_key = self._get_user_sessions_key(context.user_id)
                await self.redis_client.sadd(user_sessions_key, context.session_id)
                await self.redis_client.expire(user_sessions_key, self.context_ttl)

                self.redis_operations += 1

            except Exception as e:
                logger.error(f"Redis save context failed: {e}")

    async def update_context_interaction(
        self,
        user_id: str,
        session_id: str,
        user_input: str,
        bot_response: str,
        category: CommandCategory,
        parameters: Dict[str, Any] = None,
    ):
        """Update context with new interaction"""
        context = await self.get_context(user_id, session_id)
        if not context:
            return

        # Add interaction to history
        context.add_interaction(user_input, bot_response, category)

        # Update active parameters
        if parameters:
            context.active_parameters.update(parameters)

        # Update current topic if it's a significant change
        if category != CommandCategory.GENERAL_CONVERSATION:
            context.current_topic = self._extract_topic_from_interaction(
                user_input, category
            )

        # Update timestamp
        context.context_timestamp = datetime.now()

        # Save updated context
        await self.save_context(context)

        logger.debug(f"Updated context for {user_id}/{session_id}")

    def _extract_topic_from_interaction(
        self, user_input: str, category: CommandCategory
    ) -> Optional[str]:
        """Extract topic from user interaction"""
        # Simple topic extraction based on category
        if category == CommandCategory.DOCUMENT_GENERATION:
            # Look for "about X" or "on X"
            import re

            patterns = [
                r"about\s+(.+?)(?:\s+in|\s+for|$)",
                r"on\s+(.+?)(?:\s+in|\s+for|$)",
                r"regarding\s+(.+?)(?:\s+in|\s+for|$)",
            ]
            for pattern in patterns:
                match = re.search(pattern, user_input, re.IGNORECASE)
                if match:
                    return match.group(1).strip()

        elif category == CommandCategory.WEB_SEARCH:
            # Extract search topic
            search_patterns = [
                r"search\s+for\s+(.+?)$",
                r"find\s+(.+?)$",
                r"about\s+(.+?)$",
            ]
            for pattern in search_patterns:
                match = re.search(pattern, user_input, re.IGNORECASE)
                if match:
                    return match.group(1).strip()

        return None

    async def get_user_sessions(self, user_id: str) -> List[str]:
        """Get all active sessions for a user"""
        if self.redis_client:
            try:
                user_sessions_key = self._get_user_sessions_key(user_id)
                sessions = await self.redis_client.smembers(user_sessions_key)
                return [s.decode("utf-8") for s in sessions]
            except Exception as e:
                logger.error(f"Redis get user sessions failed: {e}")

        # Fallback to local cache
        sessions = []
        for key in self.local_cache.keys():
            if key.startswith(f"{user_id}_"):
                session_id = key.split("_", 1)[1]
                sessions.append(session_id)

        return sessions

    async def clear_context(self, user_id: str, session_id: str):
        """Clear specific context"""
        context_key = f"{user_id}_{session_id}"

        # Remove from local cache
        if context_key in self.local_cache:
            del self.local_cache[context_key]

        # Remove from Redis
        if self.redis_client:
            try:
                redis_key = self._get_context_key(user_id, session_id)
                await self.redis_client.delete(redis_key)

                # Remove from user sessions
                user_sessions_key = self._get_user_sessions_key(user_id)
                await self.redis_client.srem(user_sessions_key, session_id)

                self.redis_operations += 1

            except Exception as e:
                logger.error(f"Redis clear context failed: {e}")

        logger.info(f"Cleared context for {user_id}/{session_id}")

    async def clear_user_contexts(self, user_id: str):
        """Clear all contexts for a user"""
        sessions = await self.get_user_sessions(user_id)

        for session_id in sessions:
            await self.clear_context(user_id, session_id)

        logger.info(f"Cleared all contexts for user {user_id}")

    async def get_context_summary(
        self, user_id: str, session_id: str
    ) -> Dict[str, Any]:
        """Get summary of conversation context"""
        context = await self.get_context(user_id, session_id, create_if_missing=False)
        if not context:
            return {}

        # Calculate conversation statistics
        total_interactions = len(context.conversation_history)
        categories_used = set()
        recent_topics = []

        for interaction in context.conversation_history:
            categories_used.add(interaction.get("category", "unknown"))
            # Extract topics from recent interactions
            if len(recent_topics) < 3:
                topic = self._extract_topic_from_interaction(
                    interaction.get("user_input", ""),
                    CommandCategory(interaction.get("category", "unknown")),
                )
                if topic and topic not in recent_topics:
                    recent_topics.append(topic)

        return {
            "user_id": user_id,
            "session_id": session_id,
            "total_interactions": total_interactions,
            "categories_used": list(categories_used),
            "current_topic": context.current_topic,
            "recent_topics": recent_topics,
            "last_activity": context.context_timestamp.isoformat(),
            "active_parameters": context.active_parameters,
            "session_duration": (
                datetime.now() - context.context_timestamp
            ).total_seconds()
            / 60,  # minutes
            "preferences": context.preferences,
        }

    async def get_contextual_suggestions(
        self, user_id: str, session_id: str
    ) -> List[str]:
        """Get contextual suggestions based on conversation history"""
        context = await self.get_context(user_id, session_id, create_if_missing=False)
        if not context or not context.conversation_history:
            return [
                "Try asking me to create a document",
                "You can send emails through voice commands",
                "Ask me to search for information",
                "Schedule meetings with voice commands",
            ]

        suggestions = []
        recent_interactions = context.get_recent_context(3)

        # Analyze recent categories for suggestions
        recent_categories = [
            interaction.get("category", "") for interaction in recent_interactions
        ]

        if "document_generation" in recent_categories:
            suggestions.extend(
                [
                    "Generate another document on a different topic",
                    "Create a PDF version of your document",
                    "Send the document via email",
                ]
            )

        if "email_management" in recent_categories:
            suggestions.extend(
                [
                    "Schedule a follow-up meeting",
                    "Create a document to attach to your email",
                    "Search for more information on the topic",
                ]
            )

        if "web_search" in recent_categories:
            suggestions.extend(
                [
                    "Create a document with the search results",
                    "Send the information via email",
                    "Set a reminder about the topic",
                ]
            )

        if "calendar_scheduling" in recent_categories:
            suggestions.extend(
                [
                    "Send calendar invites to attendees",
                    "Create agenda documents for meetings",
                    "Set reminders for upcoming events",
                ]
            )

        # Add current topic-based suggestions
        if context.current_topic:
            suggestions.append(f"Search for more details about {context.current_topic}")
            suggestions.append(f"Create a document about {context.current_topic}")

        # Remove duplicates and limit
        unique_suggestions = list(dict.fromkeys(suggestions))
        return unique_suggestions[:5]

    def _manage_cache_size(self):
        """Manage local cache size to prevent memory issues"""
        if len(self.local_cache) > self.max_local_cache_size:
            # Remove oldest contexts (simple LRU)
            sorted_contexts = sorted(
                self.local_cache.items(), key=lambda x: x[1].context_timestamp
            )

            # Remove oldest 20% of contexts
            to_remove = len(sorted_contexts) // 5
            for i in range(to_remove):
                del self.local_cache[sorted_contexts[i][0]]

            logger.debug(f"Cleaned {to_remove} contexts from local cache")

    async def _background_cache_sync(self):
        """Background task to sync cache with Redis"""
        while True:
            try:
                await asyncio.sleep(self.cache_sync_interval)

                if self.redis_client:
                    # Sync contexts that have been updated recently
                    for context_key, context in list(self.local_cache.items()):
                        if (
                            datetime.now() - context.context_timestamp
                        ).seconds < 600:  # 10 minutes
                            await self.save_context(context)

                # Clean expired contexts
                await self.cleanup_expired_contexts()

            except Exception as e:
                logger.error(f"Background cache sync error: {e}")

    async def cleanup_expired_contexts(self):
        """Clean up expired contexts from both local cache and Redis"""
        expired_keys = []

        # Clean local cache
        for key, context in list(self.local_cache.items()):
            if context.is_context_expired():
                expired_keys.append(key)

        for key in expired_keys:
            del self.local_cache[key]

        if expired_keys:
            logger.info(
                f"Cleaned {len(expired_keys)} expired contexts from local cache"
            )

        # Redis cleanup is handled by TTL automatically

    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get context manager performance metrics"""
        cache_hit_rate = (
            self.cache_hits / (self.cache_hits + self.cache_misses)
            if (self.cache_hits + self.cache_misses) > 0
            else 0
        )

        return {
            "cache_hits": self.cache_hits,
            "cache_misses": self.cache_misses,
            "cache_hit_rate": cache_hit_rate,
            "redis_operations": self.redis_operations,
            "local_cache_size": len(self.local_cache),
            "redis_connected": self.redis_client is not None,
        }


# Global context manager instance
context_manager = ContextManager()
