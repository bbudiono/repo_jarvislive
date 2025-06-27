"""
AI module for Jarvis Live voice classification and context management

This module provides:
- Advanced voice command classification with NLP
- Conversation context management
- Performance optimization and caching
- Intent recognition and parameter extraction
"""

from .voice_classifier import (
    VoiceClassifier,
    CommandCategory,
    ClassificationResult,
    ConversationContext,
    IntentConfidence,
    voice_classifier,
)

from .context_manager import ContextManager, ContextUpdateEvent, context_manager

from .performance_optimizer import (
    PerformanceOptimizer,
    PerformanceMetrics,
    BatchProcessingRequest,
    performance_optimizer,
)

__all__ = [
    "VoiceClassifier",
    "CommandCategory",
    "ClassificationResult",
    "ConversationContext",
    "IntentConfidence",
    "voice_classifier",
    "ContextManager",
    "ContextUpdateEvent",
    "context_manager",
    "PerformanceOptimizer",
    "PerformanceMetrics",
    "BatchProcessingRequest",
    "performance_optimizer",
]
