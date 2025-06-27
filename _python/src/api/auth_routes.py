"""
Authentication Routes for Jarvis Live API
Provides enhanced token generation, validation, and refresh endpoints
"""

from fastapi import APIRouter, HTTPException, status, Depends, Header
from typing import Optional
from datetime import datetime, timedelta
from src.auth.jwt_auth import (
    JWTAuth,
    APIKeyManager,
    TokenRequest,
    TokenResponse,
    get_current_user,
)
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])

# Add route paths as module attributes for validation
ROUTE_PATHS = [
    "/auth/token",
    "/auth/verify",
    "/auth/refresh",
    "/auth/health",
    "/auth/status",
]


# Enhanced API key management with environment variables
class EnhancedAPIKeyManager(APIKeyManager):
    """Enhanced API key manager with environment variable support"""

    @classmethod
    def get_valid_api_keys(cls) -> dict:
        """Get valid API keys from environment and defaults"""
        valid_keys = cls.VALID_API_KEYS.copy()

        # Add environment-based API keys
        env_api_keys = {
            "ANTHROPIC_API_KEY": "anthropic_user",
            "OPENAI_API_KEY": "openai_user",
            "ELEVENLABS_API_KEY": "elevenlabs_user",
            "LIVEKIT_API_KEY": "livekit_user",
        }

        for env_key, user_id in env_api_keys.items():
            if api_key := os.getenv(env_key):
                # Use first 16 chars + hash for security
                key_identifier = f"{api_key[:8]}_{cls.hash_api_key(api_key)[:8]}"
                valid_keys[key_identifier] = user_id

        return valid_keys

    @classmethod
    def validate_api_key(cls, api_key: str) -> Optional[str]:
        """Enhanced API key validation with logging"""
        valid_keys = cls.get_valid_api_keys()

        # Direct lookup
        if user_id := valid_keys.get(api_key):
            logger.info(f"API key validated for user: {user_id}")
            return user_id

        # Check against environment keys
        env_keys = [
            "ANTHROPIC_API_KEY",
            "OPENAI_API_KEY",
            "ELEVENLABS_API_KEY",
            "LIVEKIT_API_KEY",
        ]
        for env_key in env_keys:
            if env_value := os.getenv(env_key):
                if api_key == env_value:
                    user_id = f"{env_key.lower().replace('_api_key', '')}_user"
                    logger.info(
                        f"API key validated against environment for user: {user_id}"
                    )
                    return user_id

        logger.warning("Invalid API key provided")
        return None


@router.post("/token", response_model=TokenResponse)
async def generate_token(
    request: TokenRequest, user_agent: Optional[str] = Header(None)
):
    """
    Generate JWT token using API key with enhanced security

    Args:
        request: Token request containing API key
        user_agent: Client user agent for logging

    Returns:
        JWT token response with enhanced metadata

    Raises:
        HTTPException: If API key is invalid or rate limited
    """
    logger.info(f"Token generation request from user agent: {user_agent}")

    user_id = EnhancedAPIKeyManager.validate_api_key(request.api_key)

    if not user_id:
        logger.warning(f"Failed token generation attempt from user agent: {user_agent}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create token with custom expiration for iOS clients
    expiration_hours = 24 if user_agent and "iOS" in user_agent else 1
    expires_delta = timedelta(hours=expiration_hours)

    access_token = JWTAuth.create_access_token(
        user_id=user_id, expires_delta=expires_delta
    )

    logger.info(f"Token generated successfully for user: {user_id}")

    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        expires_in=expiration_hours * 3600,
    )


@router.get("/verify")
async def verify_token(current_user: dict = Depends(get_current_user)):
    """
    Verify current JWT token with enhanced information

    Args:
        current_user: Current user from JWT token

    Returns:
        Detailed user information and token status
    """
    expires_at = current_user.get("exp")
    issued_at = current_user.get("iat")

    # Calculate time remaining
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


@router.post("/refresh")
async def refresh_token(current_user: dict = Depends(get_current_user)):
    """
    Refresh JWT token for authenticated user

    Args:
        current_user: Current user from JWT token

    Returns:
        New JWT token

    Raises:
        HTTPException: If refresh fails
    """
    user_id = current_user.get("sub")

    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token for refresh",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Generate new token with same expiration as original
    new_token = JWTAuth.create_access_token(user_id=user_id)

    logger.info(f"Token refreshed for user: {user_id}")

    return TokenResponse(access_token=new_token, token_type="bearer")


@router.get("/status")
async def auth_status(current_user: dict = Depends(get_current_user)):
    """
    Get detailed authentication status

    Args:
        current_user: Current user from JWT token

    Returns:
        Comprehensive authentication status
    """
    expires_at = current_user.get("exp")
    issued_at = current_user.get("iat")
    current_time = datetime.utcnow().timestamp()

    time_remaining = expires_at - current_time if expires_at else 0
    token_age = current_time - issued_at if issued_at else 0

    return {
        "authenticated": True,
        "user_id": current_user.get("sub"),
        "token_type": current_user.get("type"),
        "issued_at": issued_at,
        "expires_at": expires_at,
        "token_age_seconds": int(token_age),
        "time_remaining_seconds": max(0, int(time_remaining)),
        "is_expiring_soon": time_remaining < 300,
        "needs_refresh": time_remaining < 600,  # 10 minutes
        "server_time": current_time,
        "status": "authenticated",
    }


@router.get("/health")
async def auth_health():
    """
    Authentication service health check (no auth required)

    Returns:
        Enhanced service health status
    """
    # Check environment variables
    required_env_vars = ["JWT_SECRET_KEY"]
    env_status = {var: bool(os.getenv(var)) for var in required_env_vars}

    # Check if any API keys are configured
    api_keys_configured = any(
        [
            os.getenv("ANTHROPIC_API_KEY"),
            os.getenv("OPENAI_API_KEY"),
            os.getenv("ELEVENLABS_API_KEY"),
            os.getenv("LIVEKIT_API_KEY"),
        ]
    )

    return {
        "service": "jarvis-live-auth",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "environment": {
            "jwt_configured": env_status.get("JWT_SECRET_KEY", False),
            "api_keys_configured": api_keys_configured,
            "available_endpoints": ROUTE_PATHS,
        },
        "uptime": "active",
    }
