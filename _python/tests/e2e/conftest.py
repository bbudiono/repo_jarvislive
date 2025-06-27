"""
* Purpose: Pytest configuration for E2E tests with backend server management
* Issues & Complexity Summary: Complex test infrastructure with server lifecycle management
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~150
  - Core Algorithm Complexity: High (async server management + test isolation)
  - Dependencies: 8 New (pytest, playwright, uvicorn, asyncio)
  - State Management Complexity: High (server state + test state)
  - Novelty/Uncertainty Factor: Medium (E2E testing patterns)
* AI Pre-Task Self-Assessment: 80%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 82%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
"""

import asyncio
import os
import subprocess
import time
from typing import Generator, AsyncGenerator
import pytest
import httpx
import uvicorn
from multiprocessing import Process
from contextlib import asynccontextmanager

# Test server configuration
TEST_HOST = "127.0.0.1"
TEST_PORT = 8001  # Different from production port
TEST_BASE_URL = f"http://{TEST_HOST}:{TEST_PORT}"

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(scope="session")
async def test_server():
    """Start the FastAPI test server for E2E testing."""
    # Set test environment variables
    os.environ["TESTING"] = "true"
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"  # Use test database
    os.environ["LOG_LEVEL"] = "WARNING"  # Reduce log noise during testing
    
    # Start server in subprocess
    server_process = None
    try:
        # Import the app after setting environment variables
        from src.main import app
        
        # Configure uvicorn server
        config = uvicorn.Config(
            app=app,
            host=TEST_HOST,
            port=TEST_PORT,
            log_level="warning",
            access_log=False
        )
        
        # Start server in background process
        server_process = Process(target=_run_server, args=(config,))
        server_process.start()
        
        # Wait for server to start
        await _wait_for_server_start(TEST_BASE_URL, timeout=30)
        
        yield TEST_BASE_URL
        
    finally:
        # Cleanup: terminate server process
        if server_process and server_process.is_alive():
            server_process.terminate()
            server_process.join(timeout=5)
            if server_process.is_alive():
                server_process.kill()
                server_process.join()

def _run_server(config: uvicorn.Config):
    """Run uvicorn server in subprocess."""
    server = uvicorn.Server(config)
    asyncio.run(server.serve())

async def _wait_for_server_start(base_url: str, timeout: int = 30):
    """Wait for the test server to become responsive."""
    start_time = time.time()
    
    async with httpx.AsyncClient() as client:
        while time.time() - start_time < timeout:
            try:
                response = await client.get(f"{base_url}/health", timeout=2.0)
                if response.status_code == 200:
                    return
            except (httpx.RequestError, httpx.TimeoutException):
                pass
            
            await asyncio.sleep(0.5)
    
    raise RuntimeError(f"Test server failed to start within {timeout} seconds")

@pytest.fixture(scope="function")
async def api_client(test_server):
    """Create an HTTP client for API testing."""
    async with httpx.AsyncClient(base_url=test_server, timeout=30.0) as client:
        yield client

@pytest.fixture(scope="function")
async def authenticated_client(api_client):
    """Create an authenticated API client with valid JWT token."""
    # For now, return the regular client
    # In a real implementation, you would authenticate and add headers
    return api_client

@pytest.fixture(scope="function")
def sample_voice_data():
    """Provide sample voice/audio data for testing."""
    return {
        "audio_data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==",  # Sample base64
        "format": "wav",
        "sample_rate": 44100,
        "duration": 2.5
    }

@pytest.fixture(scope="function") 
def sample_ai_request():
    """Provide sample AI request data for testing."""
    return {
        "provider": "claude",
        "prompt": "What is the capital of France?",
        "context": [],
        "model": "claude-3-5-sonnet-20241022"
    }

@pytest.fixture(scope="function")
def sample_mcp_command():
    """Provide sample MCP command data for testing."""
    return {
        "server_name": "document",
        "command": "generate_pdf",
        "params": {
            "content": "Test document content",
            "title": "Test Document"
        }
    }

@pytest.fixture(autouse=True)
async def cleanup_test_data():
    """Cleanup test data before and after each test."""
    # Pre-test cleanup
    yield
    # Post-test cleanup
    # In a real implementation, you would clean up test data from Redis/database

class E2ETestConfig:
    """Configuration for E2E tests."""
    
    # Server configuration
    BASE_URL = TEST_BASE_URL
    TIMEOUT = 30.0
    
    # Test data configuration
    SAMPLE_VOICE_DURATION = 2.5
    SAMPLE_AUDIO_FORMAT = "wav"
    
    # WebSocket configuration
    WS_CONNECT_TIMEOUT = 10.0
    WS_MESSAGE_TIMEOUT = 5.0
    
    # Performance thresholds
    API_RESPONSE_THRESHOLD = 2.0  # seconds
    VOICE_PROCESSING_THRESHOLD = 5.0  # seconds
    AI_RESPONSE_THRESHOLD = 10.0  # seconds

# Make config available to tests
@pytest.fixture(scope="session")
def e2e_config():
    """Provide E2E test configuration."""
    return E2ETestConfig