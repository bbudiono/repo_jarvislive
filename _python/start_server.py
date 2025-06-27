#!/usr/bin/env python3
"""
Simple startup script for Jarvis Live FastAPI backend
This script starts the server and performs basic health checks
"""

import asyncio
import os
import sys
import time
import httpx
import uvicorn
from pathlib import Path

# Add src directory to Python path
sys.path.insert(0, str(Path(__file__).parent / "src"))


async def health_check():
    """Perform health check on the running server"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("http://localhost:8000/health", timeout=10.0)

            if response.status_code == 200:
                health_data = response.json()
                print("✅ Server health check passed")
                print(f"   Status: {health_data.get('status')}")
                print(f"   Version: {health_data.get('version')}")
                print(
                    f"   WebSocket connections: {health_data.get('websocket_connections', 0)}"
                )
                print(f"   Redis status: {health_data.get('redis_status', 'unknown')}")

                mcp_servers = health_data.get("mcp_servers", {})
                if mcp_servers:
                    print("   MCP Servers:")
                    for server_name, status in mcp_servers.items():
                        status_emoji = (
                            "✅" if status.get("status") == "running" else "❌"
                        )
                        print(
                            f"     {status_emoji} {server_name}: {status.get('status', 'unknown')}"
                        )
                else:
                    print("   ⚠️  No MCP servers initialized")

                return True
            else:
                print(f"❌ Health check failed with status: {response.status_code}")
                return False

    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
        return False


async def test_basic_endpoints():
    """Test basic API endpoints"""
    print("\n🧪 Testing basic endpoints...")

    try:
        async with httpx.AsyncClient() as client:
            # Test health endpoint
            response = await client.get("http://localhost:8000/health")
            if response.status_code == 200:
                print("✅ /health endpoint working")
            else:
                print(f"❌ /health endpoint failed: {response.status_code}")

            # Test MCP status endpoint
            try:
                response = await client.get("http://localhost:8000/mcp/status")
                if response.status_code == 200:
                    print("✅ /mcp/status endpoint working")
                    mcp_data = response.json()
                    print(f"   Found {len(mcp_data)} MCP servers")
                else:
                    print(f"❌ /mcp/status endpoint failed: {response.status_code}")
            except Exception as e:
                print(f"⚠️  /mcp/status endpoint not available: {str(e)}")

    except Exception as e:
        print(f"❌ Endpoint testing failed: {str(e)}")


def check_environment():
    """Check environment setup"""
    print("🔍 Checking environment setup...")

    required_vars = ["ANTHROPIC_API_KEY", "OPENAI_API_KEY", "ELEVENLABS_API_KEY"]

    optional_vars = [
        "GOOGLE_AI_API_KEY",
        "BING_SEARCH_API_KEY",
        "SMTP_USERNAME",
        "SMTP_PASSWORD",
        "REDIS_URL",
    ]

    # Check required variables
    missing_required = []
    for var in required_vars:
        if not os.getenv(var):
            missing_required.append(var)
        else:
            print(f"✅ {var} configured")

    if missing_required:
        print(
            f"⚠️  Missing required environment variables: {', '.join(missing_required)}"
        )
        print("   Some functionality will be limited")

    # Check optional variables
    configured_optional = []
    for var in optional_vars:
        if os.getenv(var):
            configured_optional.append(var)

    if configured_optional:
        print(f"✅ Optional variables configured: {', '.join(configured_optional)}")

    print()


def main():
    """Main startup function"""
    print("🚀 Starting Jarvis Live FastAPI Backend...")
    print("=" * 50)

    # Check environment
    check_environment()

    # Check if running in development mode
    dev_mode = (
        "--dev" in sys.argv or os.getenv("JARVIS_DEV_MODE", "false").lower() == "true"
    )

    if dev_mode:
        print("🔧 Running in development mode with auto-reload")

        # Start server with auto-reload
        uvicorn.run(
            "src.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info",
            access_log=True,
        )
    else:
        print("🏭 Running in production mode")

        # Start server without auto-reload
        uvicorn.run(
            "src.main:app",
            host="0.0.0.0",
            port=8000,
            reload=False,
            log_level="info",
            workers=1,
        )


async def startup_verification():
    """Verify server startup"""
    print("\n⏳ Waiting for server to start...")

    # Wait a moment for server to initialize
    await asyncio.sleep(3)

    # Perform health check
    success = await health_check()

    if success:
        await test_basic_endpoints()
        print("\n🎉 Jarvis Live backend is ready!")
        print("📖 API Documentation: http://localhost:8000/docs")
        print("🔍 Health Check: http://localhost:8000/health")
        print("🔗 WebSocket Endpoint: ws://localhost:8000/ws/{client_id}")
    else:
        print("\n❌ Server startup verification failed")
        return False

    return True


if __name__ == "__main__":
    if "--verify" in sys.argv:
        # Just run verification
        asyncio.run(startup_verification())
    else:
        # Start the server
        main()
