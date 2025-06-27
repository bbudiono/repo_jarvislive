"""
Simplified API Endpoint Test Suite that works without heavy dependencies
Tests all API endpoints with authentication and validates responses
"""

import pytest
import json
from fastapi.testclient import TestClient
from src.main_test_simple import app
from src.auth.jwt_auth import JWTAuth


class TestAPIEndpointsSimple:
    """Test suite for all API endpoints (simplified version)"""

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

        print(f"✅ Health endpoint test passed: {data['status']}")

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

        print(
            f"✅ Token generation test passed: {len(data['access_token'])} char token"
        )

    def test_auth_token_generation_invalid_key(self, client):
        """Test token generation with invalid API key"""
        request_data = {"api_key": "invalid_key_999"}

        response = client.post("/auth/token", json=request_data)

        assert response.status_code == 401
        data = response.json()
        assert "detail" in data
        assert data["detail"] == "Invalid API key"

        print("✅ Invalid token generation test passed: Correctly rejected")

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

        print(f"✅ Token verification test passed: User {data['user_id']}")

    def test_auth_verify_endpoint_no_token(self, client):
        """Test token verification without token"""
        response = client.get("/auth/verify")

        assert response.status_code == 403  # No credentials provided
        print("✅ No token verification test passed: Correctly rejected")

    def test_auth_verify_endpoint_invalid_token(self, client):
        """Test token verification with invalid token"""
        headers = {"Authorization": "Bearer invalid_token_123"}
        response = client.get("/auth/verify", headers=headers)

        assert response.status_code == 401
        print("✅ Invalid token verification test passed: Correctly rejected")

    def test_voice_classify_endpoint_success(self, client, auth_headers):
        """Test voice classification endpoint with valid request"""
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

        print(
            f"✅ Voice classification test passed: {data['category']} ({data['confidence']})"
        )

    def test_voice_classify_endpoint_no_auth(self, client):
        """Test voice classification endpoint without authentication"""
        request_data = {
            "text": "Create a PDF document",
            "session_id": "test_session",
            "context": {},
        }

        response = client.post("/voice/classify", json=request_data)

        assert response.status_code == 403  # No authentication
        print("✅ Voice classification no auth test passed: Correctly rejected")

    def test_voice_classify_endpoint_bad_request(self, client, auth_headers):
        """Test voice classification endpoint with invalid request data"""
        request_data = {"invalid_field": "invalid_value"}

        response = client.post(
            "/voice/classify", json=request_data, headers=auth_headers
        )

        assert response.status_code == 422  # Unprocessable Entity
        print("✅ Voice classification bad request test passed: Correctly rejected")

    def test_voice_categories_endpoint_success(self, client, auth_headers):
        """Test voice categories endpoint"""
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

        print(f"✅ Voice categories test passed: {len(data['categories'])} categories")

    def test_voice_metrics_endpoint_success(self, client, auth_headers):
        """Test voice metrics endpoint"""
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

        print(
            f"✅ Voice metrics test passed: {data['total_classifications']} classifications"
        )

    def test_document_generate_endpoint_success(self, client, auth_headers):
        """Test document generation endpoint"""
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

        print(f"✅ Document generation test passed: {data['document_id']}")

    def test_email_send_endpoint_success(self, client, auth_headers):
        """Test email sending endpoint"""
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

        print(f"✅ Email send test passed: {data['message_id']}")

    def test_search_web_endpoint_success(self, client, auth_headers):
        """Test web search endpoint"""
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

        print(f"✅ Web search test passed: {data['total_found']} results")

    def test_ai_process_endpoint_success(self, client, auth_headers):
        """Test AI processing endpoint"""
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

        print(f"✅ AI processing test passed: {data['provider_used']}")

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

        protected_count = 0
        for method, endpoint, *payload in protected_endpoints:
            if method == "GET":
                response = client.get(endpoint)
            else:
                response = client.post(endpoint, json=payload[0] if payload else {})

            assert response.status_code in [
                401,
                403,
            ], f"Endpoint {endpoint} should require authentication"
            protected_count += 1

        print(
            f"✅ All protected endpoints test passed: {protected_count} endpoints secured"
        )

    def test_performance_requirements(self, client, auth_headers):
        """Test that API responses meet performance requirements"""
        import time

        # Test voice classification performance
        start_time = time.time()
        request_data = {
            "text": "Create a PDF document about AI",
            "session_id": "test_session_123",
            "context": {},
        }
        response = client.post(
            "/voice/classify", json=request_data, headers=auth_headers
        )
        end_time = time.time()

        assert response.status_code == 200
        response_time = end_time - start_time
        assert (
            response_time < 1.0
        ), f"Voice classification took {response_time:.3f}s, should be <1s"

        print(
            f"✅ Performance test passed: Voice classification in {response_time:.3f}s"
        )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
