"""
JWT Authentication Module for Jarvis Live API
Implements Bearer Token authentication for API security
"""

import os
import jwt
from datetime import datetime, timedelta
from typing import Optional
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import secrets
import hashlib

# JWT Configuration
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", secrets.token_urlsafe(32))
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_HOURS = 24

# Initialize HTTP Bearer scheme
security = HTTPBearer()


class JWTAuth:
    """JWT Authentication manager for API endpoints"""

    @staticmethod
    def create_access_token(
        user_id: str, expires_delta: Optional[timedelta] = None
    ) -> str:
        """
        Create a JWT access token for a user

        Args:
            user_id: Unique identifier for the user
            expires_delta: Custom expiration time (defaults to 24 hours)

        Returns:
            JWT token string
        """
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(hours=JWT_EXPIRATION_HOURS)

        to_encode = {
            "sub": user_id,
            "exp": expire,
            "iat": datetime.utcnow(),
            "type": "access",
        }

        encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
        return encoded_jwt

    @staticmethod
    def verify_token(token: str) -> dict:
        """
        Verify and decode JWT token

        Args:
            token: JWT token string

        Returns:
            Decoded token payload

        Raises:
            HTTPException: If token is invalid or expired
        """
        try:
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
            user_id: str = payload.get("sub")

            if user_id is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication credentials",
                    headers={"WWW-Authenticate": "Bearer"},
                )

            return payload

        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except (jwt.PyJWTError, jwt.DecodeError):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )


# Dependency for protected endpoints
async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    FastAPI dependency to extract and verify current user from JWT token

    Args:
        credentials: HTTP Authorization credentials

    Returns:
        User payload from verified token

    Raises:
        HTTPException: If authentication fails
    """
    token = credentials.credentials
    return JWTAuth.verify_token(token)


# Simple API key management for token generation
class APIKeyManager:
    """Manages API keys for token generation"""

    # In production, this would be stored securely (database, env vars, etc.)
    VALID_API_KEYS = {"demo_key_123": "demo_user", "test_key_456": "test_user"}

    @classmethod
    def validate_api_key(cls, api_key: str) -> Optional[str]:
        """
        Validate API key and return associated user ID

        Args:
            api_key: API key to validate

        Returns:
            User ID if valid, None otherwise
        """
        return cls.VALID_API_KEYS.get(api_key)

    @classmethod
    def hash_api_key(cls, api_key: str) -> str:
        """
        Hash API key for secure storage

        Args:
            api_key: Plain text API key

        Returns:
            Hashed API key
        """
        return hashlib.sha256(api_key.encode()).hexdigest()


# Token generation endpoint model
from pydantic import BaseModel


class TokenRequest(BaseModel):
    """Request model for token generation"""

    api_key: str


class TokenResponse(BaseModel):
    """Response model for token generation"""

    access_token: str
    token_type: str = "bearer"
    expires_in: int = JWT_EXPIRATION_HOURS * 3600  # seconds
