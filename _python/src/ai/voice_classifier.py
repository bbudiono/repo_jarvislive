"""
* Purpose: Advanced voice command classification and intent recognition system
* Issues & Complexity Summary: NLP-based classification with confidence scoring and fallback logic
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: High (NLP, intent classification)
  - Dependencies: spaCy, scikit-learn, custom classification models
  - State Management Complexity: Medium (context tracking)
  - Novelty/Uncertainty Factor: Medium (complex NLP processing)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 87%
* Overall Result Score: 86%
* Key Variances/Learnings: Complex intent classification with context management
* Last Updated: 2025-06-26
"""

import re
import asyncio
import logging
from typing import Dict, List, Optional, Tuple, Any, Union
from dataclasses import dataclass, field
from enum import Enum
import json
import time
from datetime import datetime, timedelta
import hashlib

import spacy
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# Custom imports
from ..api.models import AIProvider


# Configure logging
logger = logging.getLogger(__name__)


class CommandCategory(str, Enum):
    """Voice command categories"""

    GENERAL_CONVERSATION = "general_conversation"
    DOCUMENT_GENERATION = "document_generation"
    EMAIL_MANAGEMENT = "email_management"
    CALENDAR_SCHEDULING = "calendar_scheduling"
    WEB_SEARCH = "web_search"
    SYSTEM_CONTROL = "system_control"
    FILE_MANAGEMENT = "file_management"
    TASK_MANAGEMENT = "task_management"
    WEATHER_INFO = "weather_info"
    NEWS_BRIEFING = "news_briefing"
    CALCULATIONS = "calculations"
    TRANSLATIONS = "translations"
    REMINDERS = "reminders"
    UNKNOWN = "unknown"


class IntentConfidence(str, Enum):
    """Intent confidence levels"""

    HIGH = "high"  # >0.8
    MEDIUM = "medium"  # 0.5-0.8
    LOW = "low"  # 0.3-0.5
    VERY_LOW = "very_low"  # <0.3


@dataclass
class ClassificationResult:
    """Voice command classification result"""

    category: CommandCategory
    intent: str
    confidence: float
    parameters: Dict[str, Any] = field(default_factory=dict)
    context_used: bool = False
    preprocessing_time: float = 0.0
    classification_time: float = 0.0
    suggestions: List[str] = field(default_factory=list)
    raw_text: str = ""
    normalized_text: str = ""

    @property
    def confidence_level(self) -> IntentConfidence:
        """Get confidence level based on score"""
        if self.confidence > 0.8:
            return IntentConfidence.HIGH
        elif self.confidence > 0.5:
            return IntentConfidence.MEDIUM
        elif self.confidence > 0.3:
            return IntentConfidence.LOW
        else:
            return IntentConfidence.VERY_LOW

    @property
    def requires_confirmation(self) -> bool:
        """Check if classification requires user confirmation"""
        return self.confidence < 0.7 or self.category == CommandCategory.UNKNOWN


@dataclass
class ConversationContext:
    """Context management for ongoing conversations"""

    user_id: str
    session_id: str
    conversation_history: List[Dict[str, Any]] = field(default_factory=list)
    current_topic: Optional[str] = None
    last_command_category: Optional[CommandCategory] = None
    active_parameters: Dict[str, Any] = field(default_factory=dict)
    context_timestamp: datetime = field(default_factory=datetime.now)
    preferences: Dict[str, Any] = field(default_factory=dict)

    def add_interaction(
        self, user_input: str, bot_response: str, category: CommandCategory
    ):
        """Add interaction to conversation history"""
        self.conversation_history.append(
            {
                "timestamp": datetime.now(),
                "user_input": user_input,
                "bot_response": bot_response,
                "category": category.value,
                "parameters": dict(self.active_parameters),
            }
        )

        # Keep only last 20 interactions for performance
        if len(self.conversation_history) > 20:
            self.conversation_history = self.conversation_history[-20:]

    def get_recent_context(self, max_items: int = 5) -> List[Dict[str, Any]]:
        """Get recent conversation context"""
        return (
            self.conversation_history[-max_items:] if self.conversation_history else []
        )

    def is_context_expired(self, timeout_minutes: int = 30) -> bool:
        """Check if context has expired"""
        return datetime.now() - self.context_timestamp > timedelta(
            minutes=timeout_minutes
        )


class VoiceClassifier:
    """Advanced voice command classifier with NLP and context management"""

    def __init__(self, model_path: str = "en_core_web_sm"):
        self.nlp = None
        self.model_path = model_path
        self.vectorizer = TfidfVectorizer(stop_words="english", max_features=1000)
        self.command_patterns = self._initialize_command_patterns()
        self.context_cache: Dict[str, ConversationContext] = {}
        self.classification_cache: Dict[str, ClassificationResult] = {}
        self.cache_ttl = 3600  # 1 hour

        # Performance metrics
        self.total_classifications = 0
        self.cache_hits = 0
        self.classification_times = []

        logger.info("VoiceClassifier initialized")

    async def initialize(self):
        """Initialize spaCy model and other resources"""
        try:
            self.nlp = spacy.load(self.model_path)
            logger.info(f"Loaded spaCy model: {self.model_path}")
        except OSError:
            logger.warning(
                f"spaCy model {self.model_path} not found, using basic English model"
            )
            try:
                self.nlp = spacy.load("en_core_web_sm")
            except OSError:
                logger.error(
                    "No spaCy model available. Please install: python -m spacy download en_core_web_sm"
                )
                raise

        # Train vectorizer with command examples
        await self._train_vectorizer()

    def _initialize_command_patterns(
        self,
    ) -> Dict[CommandCategory, List[Dict[str, Any]]]:
        """Initialize command patterns for classification"""
        return {
            CommandCategory.DOCUMENT_GENERATION: [
                {
                    "patterns": [
                        r"\b(create|generate|make|write)\s+(document|doc|pdf|report|letter|memo)\b",
                        r"\bdocument\s+(about|for|on)\b",
                        r"\bwrite\s+me\s+a\b",
                        r"\bcreate\s+a\s+(pdf|word|doc)\b",
                    ],
                    "examples": [
                        "create a document about artificial intelligence",
                        "generate a PDF report on sales data",
                        "write me a letter to the customer",
                        "make a document for the meeting",
                    ],
                    "parameters": ["content_topic", "format", "template", "audience"],
                }
            ],
            CommandCategory.EMAIL_MANAGEMENT: [
                {
                    "patterns": [
                        r"\b(send|compose|write)\s+(email|mail|message)\b",
                        r"\bemail\s+(to|about)\b",
                        r"\bsend\s+.*\s+to\s+[\w@.]+\b",
                        r"\bcompose\s+a\s+(message|mail)\b",
                    ],
                    "examples": [
                        "send an email to john@example.com",
                        "compose a message about the project",
                        "write an email to the team",
                        "send mail to support",
                    ],
                    "parameters": [
                        "recipient",
                        "subject",
                        "content",
                        "priority",
                        "attachments",
                    ],
                }
            ],
            CommandCategory.CALENDAR_SCHEDULING: [
                {
                    "patterns": [
                        r"\b(schedule|book|create|add)\s+(meeting|appointment|event)\b",
                        r"\bmeet\s+with\b",
                        r"\b(calendar|schedule)\s+(for|on)\b",
                        r"\bset\s+up\s+a\s+(meeting|call)\b",
                    ],
                    "examples": [
                        "schedule a meeting with the team",
                        "book an appointment for tomorrow",
                        "create an event for the conference",
                        "meet with Sarah at 3 PM",
                    ],
                    "parameters": [
                        "date_time",
                        "duration",
                        "attendees",
                        "location",
                        "agenda",
                    ],
                }
            ],
            CommandCategory.WEB_SEARCH: [
                {
                    "patterns": [
                        r"\b(search|find|look up|google)\s+(for|about)?\b",
                        r"\bwhat\s+is\b",
                        r"\bhow\s+to\b",
                        r"\btell\s+me\s+about\b",
                    ],
                    "examples": [
                        "search for Python tutorials",
                        "what is machine learning",
                        "find information about climate change",
                        "look up the weather forecast",
                    ],
                    "parameters": ["query", "search_type", "num_results"],
                }
            ],
            CommandCategory.SYSTEM_CONTROL: [
                {
                    "patterns": [
                        r"\b(open|close|launch|start|stop|quit)\s+(app|application|program)\b",
                        r"\b(increase|decrease|set)\s+(volume|brightness)\b",
                        r"\b(turn\s+(on|off)|enable|disable)\b",
                        r"\bsystem\s+(restart|shutdown)\b",
                    ],
                    "examples": [
                        "open the calculator app",
                        "increase the volume",
                        "turn off bluetooth",
                        "close Safari",
                    ],
                    "parameters": ["action", "target", "value"],
                }
            ],
            CommandCategory.CALCULATIONS: [
                {
                    "patterns": [
                        r"\b(calculate|compute|what\s+is)\s+[\d\+\-\*\/\s]+\b",
                        r"\b\d+\s*[\+\-\*\/]\s*\d+\b",
                        r"\bmath\s+(problem|calculation)\b",
                        r"\bconvert\s+\d+\b",
                    ],
                    "examples": [
                        "calculate 15 plus 27",
                        "what is 100 divided by 4",
                        "compute the square root of 64",
                        "convert 100 USD to EUR",
                    ],
                    "parameters": ["expression", "operation", "units"],
                }
            ],
            CommandCategory.REMINDERS: [
                {
                    "patterns": [
                        r"\b(remind|alert)\s+me\b",
                        r"\bset\s+(reminder|alarm)\b",
                        r"\bdont?\s+forget\b",
                        r"\bremember\s+to\b",
                    ],
                    "examples": [
                        "remind me to call mom",
                        "set a reminder for the meeting",
                        "don't forget to buy groceries",
                        "alert me in 30 minutes",
                    ],
                    "parameters": ["task", "time", "frequency", "priority"],
                }
            ],
            CommandCategory.GENERAL_CONVERSATION: [
                {
                    "patterns": [
                        r"\b(hello|hi|hey|good\s+(morning|afternoon|evening))\b",
                        r"\bhow\s+are\s+you\b",
                        r"\bwhat\s+can\s+you\s+do\b",
                        r"\btell\s+me\s+a\s+(joke|story)\b",
                    ],
                    "examples": [
                        "hello there",
                        "how are you doing",
                        "what can you help me with",
                        "tell me a joke",
                    ],
                    "parameters": ["greeting_type", "conversation_topic"],
                }
            ],
        }

    async def _train_vectorizer(self):
        """Train the TF-IDF vectorizer with command examples"""
        all_examples = []
        for category, patterns in self.command_patterns.items():
            for pattern_group in patterns:
                all_examples.extend(pattern_group["examples"])

        if all_examples:
            self.vectorizer.fit(all_examples)
            logger.info(f"Trained vectorizer with {len(all_examples)} examples")

    def preprocess_text(self, text: str) -> str:
        """Preprocess and normalize input text"""
        start_time = time.time()

        # Basic cleaning
        text = text.lower().strip()

        # Remove filler words and hesitations
        filler_words = [
            "um",
            "uh",
            "ah",
            "like",
            "you know",
            "well",
            "so",
            "actually",
            "basically",
            "totally",
            "literally",
            "right",
            "okay",
            "alright",
        ]
        for filler in filler_words:
            text = re.sub(r"\b" + filler + r"\b", "", text)

        # Normalize contractions
        contractions = {
            "won't": "will not",
            "can't": "cannot",
            "n't": " not",
            "'re": " are",
            "'ve": " have",
            "'ll": " will",
            "'d": " would",
            "'m": " am",
            "it's": "it is",
            "that's": "that is",
        }
        for contraction, expansion in contractions.items():
            text = text.replace(contraction, expansion)

        # Remove extra whitespace
        text = re.sub(r"\s+", " ", text).strip()

        preprocessing_time = time.time() - start_time
        logger.debug(f"Text preprocessing took {preprocessing_time:.4f}s")

        return text

    def extract_parameters(
        self, text: str, category: CommandCategory
    ) -> Dict[str, Any]:
        """Extract parameters from text based on command category"""
        parameters = {}

        if category == CommandCategory.EMAIL_MANAGEMENT:
            # Extract email addresses
            email_pattern = r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"
            emails = re.findall(email_pattern, text)
            if emails:
                parameters["recipient"] = emails[0]

            # Extract subject hints
            subject_patterns = [
                r"about\s+(.+?)(?:\s+to|\s+for|$)",
                r"regarding\s+(.+?)(?:\s+to|\s+for|$)",
                r"subject\s+(.+?)(?:\s+to|\s+for|$)",
            ]
            for pattern in subject_patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    parameters["subject"] = match.group(1).strip()
                    break

        elif category == CommandCategory.DOCUMENT_GENERATION:
            # Extract document format
            format_pattern = r"\b(pdf|doc|docx|txt|markdown)\b"
            format_match = re.search(format_pattern, text, re.IGNORECASE)
            if format_match:
                parameters["format"] = format_match.group(1).lower()

            # Extract topic
            topic_patterns = [
                r"about\s+(.+?)(?:\s+in|\s+for|$)",
                r"on\s+(.+?)(?:\s+in|\s+for|$)",
                r"document\s+(.+?)(?:\s+in|\s+for|$)",
            ]
            for pattern in topic_patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    parameters["content_topic"] = match.group(1).strip()
                    break

        elif category == CommandCategory.CALENDAR_SCHEDULING:
            # Extract date/time information
            time_patterns = [
                r"\b(tomorrow|today|next\s+week|next\s+month)\b",
                r"\b(\d{1,2}:\d{2})\s*(am|pm)?\b",
                r"\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
                r"\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}\b",
            ]
            for pattern in time_patterns:
                matches = re.findall(pattern, text, re.IGNORECASE)
                if matches:
                    parameters["date_time"] = matches
                    break

            # Extract attendees
            with_pattern = r"with\s+(.+?)(?:\s+at|\s+on|\s+for|$)"
            with_match = re.search(with_pattern, text, re.IGNORECASE)
            if with_match:
                parameters["attendees"] = with_match.group(1).strip()

        elif category == CommandCategory.WEB_SEARCH:
            # Extract search query
            search_patterns = [
                r"search\s+for\s+(.+?)$",
                r"find\s+(.+?)$",
                r"look\s+up\s+(.+?)$",
                r"what\s+is\s+(.+?)$",
                r"tell\s+me\s+about\s+(.+?)$",
            ]
            for pattern in search_patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    parameters["query"] = match.group(1).strip()
                    break

        elif category == CommandCategory.CALCULATIONS:
            # Extract mathematical expressions
            math_pattern = r"[\d\+\-\*\/\(\)\.\s]+"
            math_matches = re.findall(math_pattern, text)
            if math_matches:
                parameters["expression"] = " ".join(math_matches).strip()

        return parameters

    def calculate_similarity_confidence(
        self, text: str, category: CommandCategory
    ) -> float:
        """Calculate confidence score using similarity matching"""
        if category not in self.command_patterns:
            return 0.0

        # Get examples for this category
        examples = []
        for pattern_group in self.command_patterns[category]:
            examples.extend(pattern_group["examples"])

        if not examples:
            return 0.0

        try:
            # Calculate TF-IDF similarity
            all_texts = examples + [text]
            tfidf_matrix = self.vectorizer.transform(all_texts)

            # Calculate cosine similarity between input and examples
            similarities = cosine_similarity(tfidf_matrix[-1:], tfidf_matrix[:-1])
            max_similarity = np.max(similarities)

            return float(max_similarity)
        except Exception as e:
            logger.warning(f"Similarity calculation failed: {e}")
            return 0.0

    def calculate_pattern_confidence(
        self, text: str, category: CommandCategory
    ) -> float:
        """Calculate confidence score using regex pattern matching"""
        if category not in self.command_patterns:
            return 0.0

        max_confidence = 0.0
        for pattern_group in self.command_patterns[category]:
            for pattern in pattern_group["patterns"]:
                try:
                    if re.search(pattern, text, re.IGNORECASE):
                        # Pattern matches get higher confidence
                        max_confidence = max(max_confidence, 0.8)
                except re.error:
                    logger.warning(f"Invalid regex pattern: {pattern}")
                    continue

        return max_confidence

    async def classify_command(
        self,
        text: str,
        user_id: str = "default",
        session_id: str = "default",
        use_context: bool = True,
    ) -> ClassificationResult:
        """Classify voice command with confidence scoring"""
        start_time = time.time()

        # Check cache first
        cache_key = f"{hashlib.md5(text.encode()).hexdigest()}_{user_id}_{session_id}"
        if cache_key in self.classification_cache:
            cached_result = self.classification_cache[cache_key]
            if time.time() - cached_result.classification_time < self.cache_ttl:
                self.cache_hits += 1
                logger.debug(f"Cache hit for classification: {text[:50]}...")
                return cached_result

        # Preprocess text
        preprocessing_start = time.time()
        normalized_text = self.preprocess_text(text)
        preprocessing_time = time.time() - preprocessing_start

        # Get or create conversation context
        context_key = f"{user_id}_{session_id}"
        context = self.context_cache.get(context_key)
        if not context:
            context = ConversationContext(user_id=user_id, session_id=session_id)
            self.context_cache[context_key] = context

        # Classification logic
        classification_start = time.time()
        best_category = CommandCategory.UNKNOWN
        best_confidence = 0.0
        best_parameters = {}

        # Try each category
        for category in CommandCategory:
            if category == CommandCategory.UNKNOWN:
                continue

            # Calculate pattern-based confidence
            pattern_confidence = self.calculate_pattern_confidence(
                normalized_text, category
            )

            # Calculate similarity-based confidence
            similarity_confidence = self.calculate_similarity_confidence(
                normalized_text, category
            )

            # Combine confidences (weighted average)
            combined_confidence = (pattern_confidence * 0.6) + (
                similarity_confidence * 0.4
            )

            # Context boost
            if use_context and context.last_command_category == category:
                combined_confidence += 0.1  # Boost for context continuity

            # Update best match
            if combined_confidence > best_confidence:
                best_confidence = combined_confidence
                best_category = category
                best_parameters = self.extract_parameters(normalized_text, category)

        classification_time = time.time() - classification_start
        total_time = time.time() - start_time

        # Create result
        result = ClassificationResult(
            category=best_category,
            intent=f"{best_category.value}_intent",
            confidence=best_confidence,
            parameters=best_parameters,
            context_used=use_context,
            preprocessing_time=preprocessing_time,
            classification_time=classification_time,
            raw_text=text,
            normalized_text=normalized_text,
        )

        # Add suggestions for low confidence
        if result.confidence < 0.5:
            result.suggestions = self._generate_suggestions(normalized_text)

        # Update context
        context.last_command_category = best_category
        context.active_parameters.update(best_parameters)
        context.context_timestamp = datetime.now()

        # Cache result
        self.classification_cache[cache_key] = result

        # Update metrics
        self.total_classifications += 1
        self.classification_times.append(total_time)

        logger.info(
            f"Classified '{text[:50]}...' as {best_category.value} "
            f"(confidence: {best_confidence:.3f}, time: {total_time:.3f}s)"
        )

        return result

    def _generate_suggestions(self, text: str) -> List[str]:
        """Generate command suggestions for unclear input"""
        suggestions = []

        # Basic keyword-based suggestions
        keywords = text.split()

        if any(word in ["create", "make", "generate", "write"] for word in keywords):
            suggestions.append("Try: 'Create a document about [topic]'")
            suggestions.append("Try: 'Generate a PDF report on [subject]'")

        if any(word in ["send", "email", "mail"] for word in keywords):
            suggestions.append("Try: 'Send an email to [recipient] about [subject]'")
            suggestions.append("Try: 'Compose a message to the team'")

        if any(word in ["search", "find", "look"] for word in keywords):
            suggestions.append("Try: 'Search for information about [topic]'")
            suggestions.append("Try: 'Find details on [subject]'")

        if any(word in ["schedule", "meeting", "appointment"] for word in keywords):
            suggestions.append("Try: 'Schedule a meeting with [person] tomorrow'")
            suggestions.append("Try: 'Book an appointment for [date/time]'")

        # Fallback generic suggestions
        if not suggestions:
            suggestions = [
                "Try being more specific about what you want to do",
                "Use action words like 'create', 'send', 'search', or 'schedule'",
                "Include details like recipients, topics, or dates",
            ]

        return suggestions[:3]  # Limit to 3 suggestions

    def get_context(
        self, user_id: str, session_id: str
    ) -> Optional[ConversationContext]:
        """Get conversation context for user/session"""
        context_key = f"{user_id}_{session_id}"
        return self.context_cache.get(context_key)

    def update_context(
        self,
        user_id: str,
        session_id: str,
        user_input: str,
        bot_response: str,
        category: CommandCategory,
    ):
        """Update conversation context"""
        context_key = f"{user_id}_{session_id}"
        if context_key in self.context_cache:
            context = self.context_cache[context_key]
            context.add_interaction(user_input, bot_response, category)

    def clear_context(self, user_id: str, session_id: str):
        """Clear conversation context"""
        context_key = f"{user_id}_{session_id}"
        if context_key in self.context_cache:
            del self.context_cache[context_key]

    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get classifier performance metrics"""
        avg_time = (
            np.mean(self.classification_times) if self.classification_times else 0
        )
        cache_hit_rate = (
            (self.cache_hits / self.total_classifications)
            if self.total_classifications > 0
            else 0
        )

        return {
            "total_classifications": self.total_classifications,
            "cache_hits": self.cache_hits,
            "cache_hit_rate": cache_hit_rate,
            "average_classification_time": avg_time,
            "active_contexts": len(self.context_cache),
            "cached_results": len(self.classification_cache),
        }

    def cleanup_expired_contexts(self, timeout_minutes: int = 30):
        """Clean up expired conversation contexts"""
        expired_keys = []
        for key, context in self.context_cache.items():
            if context.is_context_expired(timeout_minutes):
                expired_keys.append(key)

        for key in expired_keys:
            del self.context_cache[key]

        if expired_keys:
            logger.info(f"Cleaned up {len(expired_keys)} expired contexts")


# Global classifier instance
voice_classifier = VoiceClassifier()
