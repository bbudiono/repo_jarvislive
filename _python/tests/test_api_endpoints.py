"""
Comprehensive API Endpoint Test Suite for Jarvis Live Backend
Tests all API endpoints with authentication and validates responses
"""

import pytest
import json
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import asyncio

# Import the secure FastAPI app
from src.main_secure import app
from src.auth.jwt_auth import JWTAuth


class TestAPIEndpoints:
    """Test suite for all API endpoints"""

    @pytest.fixture
    def client(self):
        """Create test client"""
        return TestClient(app)

    @pytest.fixture
    def auth_token(self):
        """Generate valid JWT token for testing"""
        return JWTAuth.create_access_token(user_id="test_user")

    @pytest.fixture
    def auth_headers(self, auth_token):
        """Create authorization headers"""
        return {"Authorization": f"Bearer {auth_token}"}

    def test_health_endpoint_no_auth(self, client):
        """Test health endpoint - no authentication required"""
        response = client.get("/health")

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "status" in data
        assert "version" in data
        assert "mcp_servers" in data
        assert "redis_status" in data
        assert "websocket_connections" in data

        # Validate data types
        assert isinstance(data["status"], str)
        assert isinstance(data["version"], str)
        assert isinstance(data["mcp_servers"], dict)
        assert isinstance(data["redis_status"], str)
        assert isinstance(data["websocket_connections"], int)

    def test_auth_token_generation_success(self, client):
        """Test token generation with valid API key"""
        request_data = {"api_key": "demo_key_123"}  # Valid key from APIKeyManager

        response = client.post("/auth/token", json=request_data)

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "access_token" in data
        assert "token_type" in data
        assert "expires_in" in data

        # Validate data types and values
        assert isinstance(data["access_token"], str)
        assert data["token_type"] == "bearer"
        assert isinstance(data["expires_in"], int)
        assert len(data["access_token"]) > 0

    def test_auth_token_generation_invalid_key(self, client):
        """Test token generation with invalid API key"""
        request_data = {"api_key": "invalid_key_999"}

        response = client.post("/auth/token", json=request_data)

        assert response.status_code == 401
        data = response.json()
        assert "detail" in data
        assert data["detail"] == "Invalid API key"

    def test_auth_verify_endpoint_success(self, client, auth_headers):
        """Test token verification with valid token"""
        response = client.get("/auth/verify", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "user_id" in data
        assert "token_type" in data
        assert "expires_at" in data
        assert "issued_at" in data
        assert "status" in data

        # Validate values
        assert data["user_id"] == "test_user"
        assert data["token_type"] == "access"
        assert data["status"] == "valid"

    def test_auth_verify_endpoint_no_token(self, client):
        """Test token verification without token"""
        response = client.get("/auth/verify")

        assert response.status_code == 403  # No credentials provided

    def test_auth_verify_endpoint_invalid_token(self, client):
        """Test token verification with invalid token"""
        headers = {"Authorization": "Bearer invalid_token_123"}
        response = client.get("/auth/verify", headers=headers)

        assert response.status_code == 401

    @patch("src.mcp.voice_server.VoiceProcessingServer.classify_command")
    def test_voice_classify_endpoint_success(self, mock_classify, client, auth_headers):
        """Test voice classification endpoint with valid request"""
        # Mock the voice classification response
        mock_classify.return_value = {
            "category": "document_generation",
            "intent": "create_pdf",
            "confidence": 0.95,
            "parameters": {"content": "test content", "format": "pdf"},
            "suggestions": ["Consider adding formatting"],
            "processing_time": 0.045,
        }

        request_data = {
            "text": "Create a PDF document about AI",
            "session_id": "test_session_123",
            "context": {"previous_commands": []},
        }

        response = client.post(
            "/voice/classify", json=request_data, headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "category" in data
        assert "intent" in data
        assert "confidence" in data
        assert "parameters" in data
        assert "suggestions" in data
        assert "processing_time" in data

        # Validate values
        assert data["category"] == "document_generation"
        assert data["intent"] == "create_pdf"
        assert data["confidence"] == 0.95
        assert isinstance(data["parameters"], dict)
        assert isinstance(data["suggestions"], list)
        assert isinstance(data["processing_time"], float)

    def test_voice_classify_endpoint_no_auth(self, client):
        """Test voice classification endpoint without authentication"""
        request_data = {
            "text": "Create a PDF document",
            "session_id": "test_session",
            "context": {},
        }

        response = client.post("/voice/classify", json=request_data)

        assert response.status_code == 403  # No authentication

    def test_voice_classify_endpoint_bad_request(self, client, auth_headers):
        """Test voice classification endpoint with invalid request data"""
        request_data = {"invalid_field": "invalid_value"}

        response = client.post(
            "/voice/classify", json=request_data, headers=auth_headers
        )

        assert response.status_code == 422  # Unprocessable Entity

    @patch("src.mcp.voice_server.VoiceProcessingServer.get_categories")
    def test_voice_categories_endpoint_success(
        self, mock_categories, client, auth_headers
    ):
        """Test voice categories endpoint"""
        mock_categories.return_value = [
            {
                "name": "document_generation",
                "description": "Generate documents",
                "examples": ["Create a PDF", "Generate report"],
            },
            {
                "name": "email_management",
                "description": "Email operations",
                "examples": ["Send email", "Compose message"],
            },
        ]

        response = client.get("/voice/categories", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        assert "categories" in data
        assert isinstance(data["categories"], list)
        assert len(data["categories"]) == 2

        # Validate category structure
        category = data["categories"][0]
        assert "name" in category
        assert "description" in category
        assert "examples" in category

    @patch("src.mcp.voice_server.VoiceProcessingServer.get_metrics")
    def test_voice_metrics_endpoint_success(self, mock_metrics, client, auth_headers):
        """Test voice metrics endpoint"""
        mock_metrics.return_value = {
            "total_classifications": 1250,
            "average_confidence": 0.87,
            "average_processing_time": 0.042,
            "categories_distribution": {
                "document_generation": 450,
                "email_management": 380,
                "search": 420,
            },
        }

        response = client.get("/voice/metrics", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        # Validate metrics structure
        assert "total_classifications" in data
        assert "average_confidence" in data
        assert "average_processing_time" in data
        assert "categories_distribution" in data

        # Validate data types
        assert isinstance(data["total_classifications"], int)
        assert isinstance(data["average_confidence"], float)
        assert isinstance(data["average_processing_time"], float)
        assert isinstance(data["categories_distribution"], dict)

    @patch("src.mcp.document_server.DocumentGenerationServer.generate_document")
    def test_document_generate_endpoint_success(
        self, mock_generate, client, auth_headers
    ):
        """Test document generation endpoint"""
        mock_generate.return_value = {
            "document_id": "doc_123456",
            "download_url": "https://example.com/documents/doc_123456.pdf",
            "format": "pdf",
            "size_bytes": 245760,
            "generation_time": 2.34,
        }

        request_data = {
            "content": "This is test document content about AI development.",
            "format": "pdf",
            "template": "standard",
        }

        response = client.post(
            "/document/generate", json=request_data, headers=auth_headers
        )

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "document_id" in data
        assert "download_url" in data
        assert "format" in data
        assert "size_bytes" in data
        assert "generation_time" in data

        # Validate values
        assert data["format"] == "pdf"
        assert isinstance(data["size_bytes"], int)
        assert isinstance(data["generation_time"], float)

    @patch("src.mcp.email_server.EmailServer.send_email")
    def test_email_send_endpoint_success(self, mock_send, client, auth_headers):
        """Test email sending endpoint"""
        mock_send.return_value = {
            "message_id": "msg_789012",
            "status": "sent",
            "delivery_time": 1.23,
        }

        request_data = {
            "to": ["test@example.com"],
            "subject": "Test Email",
            "body": "This is a test email body.",
            "attachments": [],
        }

        response = client.post("/email/send", json=request_data, headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "message_id" in data
        assert "status" in data
        assert "delivery_time" in data

        # Validate values
        assert data["status"] == "sent"
        assert isinstance(data["delivery_time"], float)

    @patch("src.mcp.search_server.SearchServer.search_web")
    def test_search_web_endpoint_success(self, mock_search, client, auth_headers):
        """Test web search endpoint"""
        mock_search.return_value = {
            "results": [
                {
                    "title": "AI Development Guide",
                    "url": "https://example.com/ai-guide",
                    "snippet": "Comprehensive guide to AI development...",
                    "relevance_score": 0.95,
                }
            ],
            "total_found": 1250,
            "search_time": 0.67,
        }

        request_data = {"query": "AI development best practices", "max_results": 10}

        response = client.post("/search/web", json=request_data, headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "results" in data
        assert "total_found" in data
        assert "search_time" in data

        # Validate values
        assert isinstance(data["results"], list)
        assert isinstance(data["total_found"], int)
        assert isinstance(data["search_time"], float)

    @patch("src.mcp.ai_providers.AIProvidersServer.process_request")
    def test_ai_process_endpoint_success(self, mock_process, client, auth_headers):
        """Test AI processing endpoint"""
        mock_process.return_value = {
            "response": "This is the AI-generated response to your query.",
            "provider_used": "claude",
            "tokens_used": 150,
            "processing_time": 1.45,
        }

        request_data = {
            "provider": "claude",
            "prompt": "Explain machine learning in simple terms",
            "context": {"conversation_history": []},
        }

        response = client.post("/ai/process", json=request_data, headers=auth_headers)

        assert response.status_code == 200
        data = response.json()

        # Validate response structure
        assert "response" in data
        assert "provider_used" in data
        assert "tokens_used" in data
        assert "processing_time" in data

        # Validate values
        assert isinstance(data["response"], str)
        assert data["provider_used"] == "claude"
        assert isinstance(data["tokens_used"], int)
        assert isinstance(data["processing_time"], float)

    def test_all_protected_endpoints_require_auth(self, client):
        """Test that all protected endpoints reject requests without authentication"""
        protected_endpoints = [
            ("GET", "/voice/categories"),
            ("GET", "/voice/metrics"),
            ("POST", "/voice/classify", {"text": "test", "session_id": "test"}),
            ("POST", "/document/generate", {"content": "test", "format": "pdf"}),
            (
                "POST",
                "/email/send",
                {"to": ["test@example.com"], "subject": "test", "body": "test"},
            ),
            ("POST", "/search/web", {"query": "test", "max_results": 5}),
            ("POST", "/ai/process", {"provider": "claude", "prompt": "test"}),
        ]

        for method, endpoint, *payload in protected_endpoints:
            if method == "GET":
                response = client.get(endpoint)
            else:
                response = client.post(endpoint, json=payload[0] if payload else {})

            assert response.status_code in [
                401,
                403,
            ], f"Endpoint {endpoint} should require authentication"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
