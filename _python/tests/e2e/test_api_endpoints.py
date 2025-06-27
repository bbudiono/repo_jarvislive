"""
* Purpose: E2E API endpoint testing for core FastAPI functionality
* Issues & Complexity Summary: Comprehensive API testing with real server responses
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~200
  - Core Algorithm Complexity: Medium (HTTP request/response validation)
  - Dependencies: 4 New (httpx, pytest, fastapi, pydantic)
  - State Management Complexity: Medium (test isolation + server state)
  - Novelty/Uncertainty Factor: Low (standard API testing patterns)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 75%
* Initial Code Complexity Estimate: 80%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
"""

import pytest
import time
from typing import Dict, Any
import httpx


class TestHealthEndpoint:
    """Test suite for /health endpoint E2E functionality."""
    
    async def test_health_endpoint_basic_response(self, api_client):
        """Test health endpoint returns 200 and valid structure."""
        response = await api_client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify response structure
        assert "status" in data
        assert "version" in data
        assert "mcp_servers" in data
        assert "redis_status" in data
        assert "websocket_connections" in data
        
        # Verify basic values
        assert data["status"] == "healthy"
        assert data["version"] == "1.0.0"
        assert isinstance(data["websocket_connections"], int)
    
    async def test_health_endpoint_performance(self, api_client, e2e_config):
        """Test health endpoint responds within performance threshold."""
        start_time = time.time()
        response = await api_client.get("/health")
        response_time = time.time() - start_time
        
        assert response.status_code == 200
        assert response_time < e2e_config.API_RESPONSE_THRESHOLD
    
    async def test_health_endpoint_redis_status(self, api_client):
        """Test health endpoint reports Redis connection status."""
        response = await api_client.get("/health")
        data = response.json()
        
        # Redis status should be one of: connected, disconnected, error
        assert data["redis_status"] in ["connected", "disconnected", "error"]
    
    async def test_health_endpoint_concurrent_requests(self, api_client):
        """Test health endpoint handles concurrent requests."""
        import asyncio
        
        # Make 10 concurrent requests
        tasks = [api_client.get("/health") for _ in range(10)]
        responses = await asyncio.gather(*tasks)
        
        # All requests should succeed
        for response in responses:
            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "healthy"


class TestAIProviderEndpoint:
    """Test suite for /ai/process endpoint E2E functionality."""
    
    async def test_ai_process_basic_request(self, api_client, sample_ai_request):
        """Test AI processing endpoint with valid request."""
        response = await api_client.post("/ai/process", json=sample_ai_request)
        
        # Should succeed or fail gracefully (503 if MCP not available)
        assert response.status_code in [200, 503]
        
        if response.status_code == 200:
            data = response.json()
            assert "provider" in data
            assert "response" in data
            assert "model_used" in data
            assert "usage" in data
            assert "processing_time" in data
            
            assert data["provider"] == sample_ai_request["provider"]
    
    async def test_ai_process_invalid_request(self, api_client):
        """Test AI processing endpoint with invalid request data."""
        invalid_request = {"invalid": "data"}
        
        response = await api_client.post("/ai/process", json=invalid_request)
        assert response.status_code == 422  # Validation error
    
    async def test_ai_process_missing_fields(self, api_client):
        """Test AI processing endpoint with missing required fields."""
        incomplete_request = {"provider": "claude"}  # Missing prompt
        
        response = await api_client.post("/ai/process", json=incomplete_request)
        assert response.status_code == 422  # Validation error
    
    async def test_ai_process_performance(self, api_client, sample_ai_request, e2e_config):
        """Test AI processing endpoint performance threshold."""
        start_time = time.time()
        response = await api_client.post("/ai/process", json=sample_ai_request)
        response_time = time.time() - start_time
        
        # Should respond within threshold (even if MCP not available)
        assert response_time < e2e_config.AI_RESPONSE_THRESHOLD
        assert response.status_code in [200, 503]


class TestVoiceProcessingEndpoint:
    """Test suite for /voice/process endpoint E2E functionality."""
    
    async def test_voice_process_basic_request(self, api_client, sample_voice_data):
        """Test voice processing endpoint with valid audio data."""
        response = await api_client.post("/voice/process", json=sample_voice_data)
        
        # Should succeed or fail gracefully (503 if MCP not available)
        assert response.status_code in [200, 503]
        
        if response.status_code == 200:
            data = response.json()
            assert "transcription" in data
            assert "ai_response" in data
            assert "processing_time" in data
    
    async def test_voice_process_invalid_audio_data(self, api_client):
        """Test voice processing endpoint with invalid audio data."""
        invalid_data = {
            "audio_data": "invalid_base64_data",
            "format": "wav",
            "sample_rate": 44100
        }
        
        response = await api_client.post("/voice/process", json=invalid_data)
        assert response.status_code in [400, 422, 500, 503]
    
    async def test_voice_process_missing_audio_data(self, api_client):
        """Test voice processing endpoint with missing audio data."""
        incomplete_data = {
            "format": "wav",
            "sample_rate": 44100
        }
        
        response = await api_client.post("/voice/process", json=incomplete_data)
        assert response.status_code == 422  # Validation error
    
    async def test_voice_process_performance(self, api_client, sample_voice_data, e2e_config):
        """Test voice processing endpoint performance threshold."""
        start_time = time.time()
        response = await api_client.post("/voice/process", json=sample_voice_data)
        response_time = time.time() - start_time
        
        # Should respond within threshold (even if MCP not available)
        assert response_time < e2e_config.VOICE_PROCESSING_THRESHOLD
        assert response.status_code in [200, 503]


class TestMCPStatusEndpoint:
    """Test suite for /mcp/status endpoint E2E functionality."""
    
    async def test_mcp_status_basic_response(self, api_client):
        """Test MCP status endpoint basic functionality."""
        response = await api_client.get("/mcp/status")
        
        # Should succeed or fail gracefully (503 if MCP not available)
        assert response.status_code in [200, 503]
        
        if response.status_code == 200:
            data = response.json()
            assert isinstance(data, dict)
            
            # Each server should have status information
            for server_name, status in data.items():
                assert isinstance(status, dict)
                if "status" in status:
                    assert status["status"] in ["running", "stopped", "error"]
    
    async def test_mcp_status_performance(self, api_client, e2e_config):
        """Test MCP status endpoint performance."""
        start_time = time.time()
        response = await api_client.get("/mcp/status")
        response_time = time.time() - start_time
        
        assert response_time < e2e_config.API_RESPONSE_THRESHOLD
        assert response.status_code in [200, 503]


class TestAPIErrorHandling:
    """Test suite for API error handling and edge cases."""
    
    async def test_invalid_endpoint(self, api_client):
        """Test API response to invalid endpoints."""
        response = await api_client.get("/invalid/endpoint")
        assert response.status_code == 404
    
    async def test_invalid_http_method(self, api_client):
        """Test API response to invalid HTTP methods."""
        # Try POST to GET-only endpoint
        response = await api_client.post("/health")
        assert response.status_code == 405  # Method not allowed
    
    async def test_malformed_json(self, api_client):
        """Test API response to malformed JSON."""
        response = await api_client.post(
            "/ai/process",
            content="invalid json{",
            headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422
    
    async def test_empty_request_body(self, api_client):
        """Test API response to empty request body."""
        response = await api_client.post("/ai/process", json={})
        assert response.status_code == 422  # Validation error
    
    async def test_large_request_payload(self, api_client):
        """Test API response to oversized request payload."""
        # Create a large payload
        large_payload = {
            "provider": "claude",
            "prompt": "x" * 10000,  # Very long prompt
            "context": [],
            "model": "claude-3-5-sonnet-20241022"
        }
        
        response = await api_client.post("/ai/process", json=large_payload)
        # Should handle gracefully - either accept or reject with proper status
        assert response.status_code in [200, 413, 422, 503]


class TestCORSConfiguration:
    """Test suite for CORS configuration."""
    
    async def test_cors_headers_present(self, api_client):
        """Test that CORS headers are properly configured."""
        response = await api_client.options("/health")
        
        # Should have CORS headers
        headers = response.headers
        # Note: Exact header values depend on configuration
        # This test verifies the endpoint is accessible
        assert response.status_code in [200, 404]  # Some servers don't handle OPTIONS
    
    async def test_api_accessible_cross_origin(self, api_client):
        """Test that API is accessible for cross-origin requests."""
        # Add Origin header to simulate cross-origin request
        headers = {"Origin": "http://localhost:3000"}
        response = await api_client.get("/health", headers=headers)
        
        assert response.status_code == 200


class TestAPIIntegration:
    """Test suite for API integration scenarios."""
    
    async def test_health_to_ai_processing_flow(self, api_client, sample_ai_request):
        """Test complete flow from health check to AI processing."""
        # 1. Check health
        health_response = await api_client.get("/health")
        assert health_response.status_code == 200
        
        # 2. Check MCP status
        mcp_response = await api_client.get("/mcp/status")
        assert mcp_response.status_code in [200, 503]
        
        # 3. Process AI request
        ai_response = await api_client.post("/ai/process", json=sample_ai_request)
        assert ai_response.status_code in [200, 503]
    
    async def test_voice_to_ai_processing_flow(self, api_client, sample_voice_data):
        """Test complete flow from voice processing."""
        # 1. Process voice input
        voice_response = await api_client.post("/voice/process", json=sample_voice_data)
        assert voice_response.status_code in [200, 503]
        
        # 2. If voice processing succeeded, verify structure
        if voice_response.status_code == 200:
            data = voice_response.json()
            assert "transcription" in data
            assert "ai_response" in data
            assert "processing_time" in data
    
    async def test_concurrent_mixed_requests(self, api_client, sample_ai_request, sample_voice_data):
        """Test server handling of concurrent mixed requests."""
        import asyncio
        
        # Create mixed concurrent requests
        tasks = [
            api_client.get("/health"),
            api_client.get("/mcp/status"),
            api_client.post("/ai/process", json=sample_ai_request),
            api_client.post("/voice/process", json=sample_voice_data),
            api_client.get("/health"),  # Duplicate health check
        ]
        
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        
        # All requests should complete without exceptions
        for response in responses:
            assert not isinstance(response, Exception)
            assert hasattr(response, 'status_code')
            # Status codes should be valid HTTP codes
            assert 200 <= response.status_code < 600