#!/usr/bin/env python3
"""
Minimal FastAPI server for Jarvis Live Voice Classification API
This version runs without complex MCP dependencies for immediate testing
"""

import os
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from fastapi import FastAPI, HTTPException, Depends, Header, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import jwt
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(
    title="Jarvis Live Voice Classification API",
    description="Minimal API for voice command classification and authentication",
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# JWT Configuration
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"

# Simple API key validation
VALID_API_KEYS = {
    "test-api-key": "test_user",
    "jarvis-development-key": "dev_user",
    "demo-key-123": "demo_user",
}


# Request/Response Models
class TokenRequest(BaseModel):
    api_key: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str
    expires_in: int


class ClassificationRequest(BaseModel):
    text: str
    user_id: str
    session_id: str
    use_context: bool = True
    include_suggestions: bool = True


class ClassificationResult(BaseModel):
    category: str
    intent: str
    confidence: float
    parameters: Dict[str, Any]
    suggestions: List[str]
    raw_text: str
    normalized_text: str
    confidence_level: str
    context_used: bool
    preprocessing_time: float
    classification_time: float
    requires_confirmation: bool


class ContextSummaryResponse(BaseModel):
    user_id: str
    session_id: str
    total_interactions: int
    categories_used: List[str]
    current_topic: Optional[str]
    recent_topics: List[str]
    last_activity: str
    active_parameters: Dict[str, str]
    session_duration: float
    preferences: Dict[str, str]


class ContextualSuggestionsResponse(BaseModel):
    suggestions: List[str]
    user_id: str
    session_id: str
    context_available: bool


# JWT Helper Functions
def create_access_token(user_id: str, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(hours=1)

    to_encode = {
        "sub": user_id,
        "exp": expire,
        "iat": datetime.utcnow(),
        "type": "access_token",
    }

    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt


def verify_token(token: str):
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token"""
    token = credentials.credentials
    return verify_token(token)


# Simple Voice Classification Logic
def classify_voice_command(
    text: str, user_id: str, session_id: str
) -> ClassificationResult:
    """Simple rule-based voice classification"""
    start_time = time.time()

    # Normalize text
    normalized_text = text.lower().strip()

    # Simple pattern matching for classification
    if any(
        word in normalized_text
        for word in ["create", "generate", "document", "pdf", "report", "write"]
    ):
        category = "document_generation"
        intent = "document_generation_intent"
        confidence = 0.85
        parameters = {"content_topic": "general", "format": "pdf"}

    elif any(word in normalized_text for word in ["email", "send", "mail", "message"]):
        category = "email_management"
        intent = "email_management_intent"
        confidence = 0.90
        parameters = {"action": "send", "recipient": "unknown"}

    elif any(
        word in normalized_text
        for word in ["schedule", "meeting", "calendar", "appointment"]
    ):
        category = "calendar_scheduling"
        intent = "calendar_scheduling_intent"
        confidence = 0.88
        parameters = {"event_type": "meeting", "time": "unknown"}

    elif any(word in normalized_text for word in ["search", "find", "look", "google"]):
        category = "web_search"
        intent = "web_search_intent"
        confidence = 0.92
        parameters = {"query": normalized_text}

    elif any(
        word in normalized_text
        for word in [
            "calculate",
            "math",
            "compute",
            "plus",
            "minus",
            "multiply",
            "divide",
        ]
    ):
        category = "calculations"
        intent = "calculations_intent"
        confidence = 0.95
        parameters = {"expression": normalized_text}

    elif any(
        word in normalized_text for word in ["remind", "reminder", "remember", "alert"]
    ):
        category = "reminders"
        intent = "reminders_intent"
        confidence = 0.87
        parameters = {"task": normalized_text, "time": "unknown"}

    elif any(
        word in normalized_text
        for word in ["open", "launch", "start", "app", "application"]
    ):
        category = "system_control"
        intent = "system_control_intent"
        confidence = 0.80
        parameters = {"action": "open", "target": "unknown"}

    else:
        category = "general_conversation"
        intent = "general_conversation_intent"
        confidence = 0.60
        parameters = {}

    # Calculate processing time
    processing_time = time.time() - start_time

    # Determine confidence level
    if confidence >= 0.8:
        confidence_level = "high"
    elif confidence >= 0.6:
        confidence_level = "medium"
    else:
        confidence_level = "low"

    # Generate suggestions for low confidence
    suggestions = []
    if confidence < 0.7:
        suggestions = [
            "Try being more specific about what you want to do",
            "Use action words like 'create', 'send', 'schedule'",
            "Provide more context about your request",
        ]

    return ClassificationResult(
        category=category,
        intent=intent,
        confidence=confidence,
        parameters=parameters,
        suggestions=suggestions,
        raw_text=text,
        normalized_text=normalized_text,
        confidence_level=confidence_level,
        context_used=True,  # Simulate context usage
        preprocessing_time=0.001,
        classification_time=processing_time,
        requires_confirmation=confidence < 0.7,
    )


# API Routes


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "Jarvis Live Voice Classification API",
        "status": "running",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "service": "jarvis-live-minimal",
    }


# Authentication Routes
@app.post("/auth/token", response_model=TokenResponse)
async def generate_token(
    request: TokenRequest, user_agent: Optional[str] = Header(None)
):
    """Generate JWT token using API key"""
    logger.info(f"Token generation request from user agent: {user_agent}")

    user_id = VALID_API_KEYS.get(request.api_key)

    if not user_id:
        logger.warning(f"Failed token generation attempt from user agent: {user_agent}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create token with extended expiration for iOS clients
    expiration_hours = 24 if user_agent and "iOS" in user_agent else 1
    expires_delta = timedelta(hours=expiration_hours)

    access_token = create_access_token(user_id=user_id, expires_delta=expires_delta)

    logger.info(f"Token generated successfully for user: {user_id}")

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=expiration_hours * 3600,
    )


@app.get("/auth/verify")
async def verify_token_endpoint(current_user: dict = Depends(get_current_user)):
    """Verify current JWT token"""
    expires_at = current_user.get("exp")
    issued_at = current_user.get("iat")

    current_time = datetime.utcnow().timestamp()
    time_remaining = expires_at - current_time if expires_at else 0

    return {
        "user_id": current_user.get("sub"),
        "token_type": current_user.get("type"),
        "expires_at": expires_at,
        "issued_at": issued_at,
        "time_remaining_seconds": max(0, int(time_remaining)),
        "is_expiring_soon": time_remaining < 300,  # 5 minutes
        "status": "valid",
    }


@app.get("/auth/health")
async def auth_health():
    """Authentication service health check"""
    return {
        "service": "jarvis-live-auth",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "environment": {
            "jwt_configured": bool(JWT_SECRET_KEY),
            "api_keys_configured": len(VALID_API_KEYS) > 0,
            "available_endpoints": ["/auth/token", "/auth/verify", "/auth/health"],
        },
    }


# Voice Classification Routes
@app.post("/voice/classify", response_model=ClassificationResult)
async def classify_voice_command_endpoint(
    request: ClassificationRequest, current_user: dict = Depends(get_current_user)
):
    """Classify voice command"""
    try:
        result = classify_voice_command(
            text=request.text, user_id=request.user_id, session_id=request.session_id
        )

        logger.info(
            f"Voice command classified: '{request.text}' -> {result.category} (confidence: {result.confidence})"
        )

        return result

    except Exception as e:
        logger.error(f"Voice classification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Classification failed: {str(e)}",
        )


@app.get("/voice/categories")
async def get_voice_categories(current_user: dict = Depends(get_current_user)):
    """Get available voice command categories"""
    categories = [
        {
            "name": "document_generation",
            "description": "Create documents, reports, and files",
            "examples": ["create a PDF", "generate a report", "write a document"],
        },
        {
            "name": "email_management",
            "description": "Send and manage emails",
            "examples": ["send email to john", "compose message", "mail the team"],
        },
        {
            "name": "calendar_scheduling",
            "description": "Schedule meetings and events",
            "examples": ["schedule meeting", "book appointment", "set up call"],
        },
        {
            "name": "web_search",
            "description": "Search for information online",
            "examples": [
                "search for Python tutorials",
                "find weather forecast",
                "google AI news",
            ],
        },
        {
            "name": "calculations",
            "description": "Perform mathematical calculations",
            "examples": [
                "calculate 15 plus 27",
                "what's 20% of 150",
                "compute the average",
            ],
        },
        {
            "name": "reminders",
            "description": "Set reminders and alerts",
            "examples": [
                "remind me to call mom",
                "set alarm for 7am",
                "alert me tomorrow",
            ],
        },
        {
            "name": "system_control",
            "description": "Control system and applications",
            "examples": ["open calculator", "launch browser", "start music app"],
        },
        {
            "name": "general_conversation",
            "description": "General conversation and queries",
            "examples": ["hello", "how are you", "what's the weather"],
        },
    ]

    return {"categories": categories}


@app.get(
    "/context/{user_id}/{session_id}/summary", response_model=ContextSummaryResponse
)
async def get_context_summary(
    user_id: str, session_id: str, current_user: dict = Depends(get_current_user)
):
    """Get context summary for user session"""
    # Simulate context data
    return ContextSummaryResponse(
        user_id=user_id,
        session_id=session_id,
        total_interactions=5,
        categories_used=["document_generation", "email_management"],
        current_topic="document creation",
        recent_topics=["emails", "documents", "scheduling"],
        last_activity=datetime.utcnow().isoformat() + "Z",
        active_parameters={"format": "pdf", "recipient": "team"},
        session_duration=300.0,  # 5 minutes
        preferences={"preferred_format": "pdf", "timezone": "UTC"},
    )


@app.get(
    "/context/{user_id}/{session_id}/suggestions",
    response_model=ContextualSuggestionsResponse,
)
async def get_contextual_suggestions(
    user_id: str, session_id: str, current_user: dict = Depends(get_current_user)
):
    """Get contextual suggestions for user session"""
    # Simulate contextual suggestions
    suggestions = [
        "Would you like me to send that document as an email?",
        "Shall I schedule a follow-up meeting to discuss the document?",
        "Do you want to create another document with similar content?",
    ]

    return ContextualSuggestionsResponse(
        suggestions=suggestions,
        user_id=user_id,
        session_id=session_id,
        context_available=True,
    )


# Basic metrics endpoint
@app.get("/voice/metrics")
async def get_voice_metrics(current_user: dict = Depends(get_current_user)):
    """Get voice classification metrics"""
    return {
        "total_classifications": 100,
        "average_confidence": 0.85,
        "category_distribution": {
            "document_generation": 25,
            "email_management": 20,
            "calendar_scheduling": 15,
            "web_search": 20,
            "calculations": 10,
            "reminders": 5,
            "system_control": 3,
            "general_conversation": 2,
        },
        "average_processing_time": 0.045,
        "success_rate": 0.94,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


if __name__ == "__main__":
    import uvicorn

    print("🚀 Starting Jarvis Live Minimal Voice Classification API...")
    print("📍 Available endpoints:")
    print("   - GET  /              - Root endpoint")
    print("   - GET  /health        - Health check")
    print("   - POST /auth/token    - Generate JWT token")
    print("   - GET  /auth/verify   - Verify JWT token")
    print("   - POST /voice/classify - Classify voice command")
    print("   - GET  /voice/categories - Get available categories")
    print("   - GET  /context/{user_id}/{session_id}/summary - Get context summary")
    print("   - GET  /context/{user_id}/{session_id}/suggestions - Get suggestions")
    print("   - GET  /voice/metrics - Get classification metrics")
    print()

    uvicorn.run(
        "main_minimal:app", host="0.0.0.0", port=8000, reload=True, log_level="info"
    )
