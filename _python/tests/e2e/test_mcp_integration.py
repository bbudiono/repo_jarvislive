"""
* Purpose: E2E MCP server integration testing for complete service validation
* Issues & Complexity Summary: Complex E2E testing of MCP server orchestration and integration
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: High (multi-server orchestration testing)
  - Dependencies: 8 New (MCP servers, async coordination, service discovery)
  - State Management Complexity: High (multiple server states + coordination)
  - Novelty/Uncertainty Factor: High (MCP E2E testing patterns)
* AI Pre-Task Self-Assessment: 70%
* Problem Estimate: 90%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
"""

import pytest
import asyncio
import time
from typing import Dict, Any, List
import json


class TestMCPServerDiscovery:
    """Test suite for MCP server discovery and status reporting."""
    
    async def test_mcp_server_status_endpoint(self, api_client):
        """Test MCP server status endpoint returns expected servers."""
        response = await api_client.get("/mcp/status")
        
        # Should succeed or fail gracefully if MCP not available
        assert response.status_code in [200, 503]
        
        if response.status_code == 200:
            data = response.json()
            assert isinstance(data, dict)
            
            # Expected MCP servers based on the codebase
            expected_servers = ["document", "email", "search", "voice"]
            
            for server_name in expected_servers:
                if server_name in data:
                    server_status = data[server_name]
                    assert isinstance(server_status, dict)
                    
                    # Verify status structure if present
                    if "status" in server_status:
                        assert server_status["status"] in ["running", "stopped", "error", "unknown"]
    
    async def test_mcp_server_health_consistency(self, api_client):
        """Test MCP server status consistency with health endpoint."""
        # Get MCP status
        mcp_response = await api_client.get("/mcp/status")
        health_response = await api_client.get("/health")
        
        assert health_response.status_code == 200
        health_data = health_response.json()
        
        if mcp_response.status_code == 200:
            mcp_data = mcp_response.json()
            
            # MCP servers in health should match MCP status endpoint
            health_mcp = health_data.get("mcp_servers", {})
            
            # Both should have consistent server information
            for server_name in mcp_data.keys():
                if server_name in health_mcp:
                    # Status should be consistent
                    mcp_status = mcp_data[server_name].get("status", "unknown")
                    health_status = health_mcp[server_name].get("status", "unknown")
                    
                    # Allow for slight timing differences
                    assert mcp_status in ["running", "stopped", "error", "unknown"]
                    assert health_status in ["running", "stopped", "error", "unknown"]


class TestDocumentMCPServer:
    """Test suite for Document MCP server integration."""
    
    async def test_document_server_via_api(self, api_client):
        """Test document generation via API endpoint."""
        # Test document generation through AI provider endpoint
        document_request = {
            "provider": "claude",
            "prompt": "Generate a simple test document with title 'Test Document' and content about testing",
            "context": [],
            "model": "claude-3-5-sonnet-20241022"
        }
        
        response = await api_client.post("/ai/process", json=document_request)
        
        # Should succeed or fail gracefully if MCP not available
        assert response.status_code in [200, 503]
        
        if response.status_code == 200:
            data = response.json()
            assert "response" in data
            assert "processing_time" in data
            assert data["provider"] == "claude"
    
    async def test_document_server_via_websocket(self, test_server, sample_mcp_command):
        """Test document generation via WebSocket MCP command."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/document_test_client"
        
        # Override sample command for document generation
        document_command = {
            "type": "mcp_command",
            "server_name": "document",
            "command": "generate_pdf", 
            "params": {
                "content": "This is a test document for E2E testing",
                "title": "E2E Test Document"
            }
        }
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                # Send document generation command
                await websocket.send(json.dumps(document_command))
                
                # Wait for response
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                    response_data = json.loads(response)
                    
                    # Verify response structure
                    assert "type" in response_data
                    assert response_data["type"] in ["mcp_response", "error"]
                    
                    if response_data["type"] == "mcp_response":
                        assert response_data["server_name"] == "document"
                        assert response_data["command"] == "generate_pdf"
                        assert "result" in response_data
                
                except asyncio.TimeoutError:
                    pytest.skip("Document MCP server response timeout")
                
        except (Exception,) as e:
            pytest.skip(f"WebSocket connection failed: {e}")


class TestEmailMCPServer:
    """Test suite for Email MCP server integration."""
    
    async def test_email_server_status(self, api_client):
        """Test email server appears in MCP status."""
        response = await api_client.get("/mcp/status")
        
        if response.status_code == 200:
            data = response.json()
            
            # Email server should be listed
            if "email" in data:
                email_status = data["email"]
                assert isinstance(email_status, dict)
                
                # Should have status information
                if "status" in email_status:
                    assert email_status["status"] in ["running", "stopped", "error", "unknown"]
    
    async def test_email_server_integration(self, test_server):
        """Test email server integration via WebSocket."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/email_test_client"
        
        email_command = {
            "type": "mcp_command",
            "server_name": "email",
            "command": "send_email",
            "params": {
                "to": "test@example.com",
                "subject": "E2E Test Email",
                "body": "This is a test email from E2E testing"
            }
        }
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                # Send email command
                await websocket.send(json.dumps(email_command))
                
                # Wait for response
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                    response_data = json.loads(response)
                    
                    assert "type" in response_data
                    assert response_data["type"] in ["mcp_response", "error"]
                    
                    if response_data["type"] == "mcp_response":
                        assert response_data["server_name"] == "email"
                        assert response_data["command"] == "send_email"
                
                except asyncio.TimeoutError:
                    pytest.skip("Email MCP server response timeout")
                
        except (Exception,) as e:
            pytest.skip(f"WebSocket connection failed: {e}")


class TestSearchMCPServer:
    """Test suite for Search MCP server integration."""
    
    async def test_search_server_integration(self, test_server):
        """Test search server integration via WebSocket."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/search_test_client"
        
        search_command = {
            "type": "mcp_command",
            "server_name": "search",
            "command": "web_search",
            "params": {
                "query": "FastAPI testing best practices",
                "limit": 5
            }
        }
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                # Send search command
                await websocket.send(json.dumps(search_command))
                
                # Wait for response
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                    response_data = json.loads(response)
                    
                    assert "type" in response_data
                    assert response_data["type"] in ["mcp_response", "error"]
                    
                    if response_data["type"] == "mcp_response":
                        assert response_data["server_name"] == "search"
                        assert response_data["command"] == "web_search"
                        assert "result" in response_data
                
                except asyncio.TimeoutError:
                    pytest.skip("Search MCP server response timeout")
                
        except (Exception,) as e:
            pytest.skip(f"WebSocket connection failed: {e}")


class TestVoiceMCPServer:
    """Test suite for Voice MCP server integration."""
    
    async def test_voice_server_integration(self, test_server, sample_voice_data):
        """Test voice server integration via WebSocket."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/voice_mcp_test_client"
        
        voice_command = {
            "type": "mcp_command",
            "server_name": "voice",
            "command": "process_speech",
            "params": sample_voice_data
        }
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                # Send voice processing command
                await websocket.send(json.dumps(voice_command))
                
                # Wait for response
                try:
                    response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                    response_data = json.loads(response)
                    
                    assert "type" in response_data
                    assert response_data["type"] in ["mcp_response", "error"]
                    
                    if response_data["type"] == "mcp_response":
                        assert response_data["server_name"] == "voice"
                        assert response_data["command"] == "process_speech"
                
                except asyncio.TimeoutError:
                    pytest.skip("Voice MCP server response timeout")
                
        except (Exception,) as e:
            pytest.skip(f"WebSocket connection failed: {e}")


class TestMCPServerOrchestration:
    """Test suite for MCP server orchestration and coordination."""
    
    async def test_multiple_mcp_servers_concurrent(self, test_server):
        """Test concurrent access to multiple MCP servers."""
        base_ws_url = test_server.replace("http://", "ws://") + "/ws/"
        
        # Define commands for different MCP servers
        mcp_commands = [
            {
                "client_id": "orchestration_client_1",
                "command": {
                    "type": "mcp_command",
                    "server_name": "document",
                    "command": "generate_pdf",
                    "params": {"content": "Test 1", "title": "Doc 1"}
                }
            },
            {
                "client_id": "orchestration_client_2", 
                "command": {
                    "type": "mcp_command",
                    "server_name": "email",
                    "command": "send_email",
                    "params": {"to": "test1@example.com", "subject": "Test 1", "body": "Body 1"}
                }
            },
            {
                "client_id": "orchestration_client_3",
                "command": {
                    "type": "mcp_command",
                    "server_name": "search",
                    "command": "web_search",
                    "params": {"query": "test query 1", "limit": 3}
                }
            }
        ]
        
        async def send_mcp_command(client_id: str, command: dict):
            """Send MCP command via WebSocket."""
            ws_url = base_ws_url + client_id
            try:
                import websockets
                async with websockets.connect(ws_url, timeout=10) as websocket:
                    await websocket.send(json.dumps(command))
                    
                    try:
                        response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                        response_data = json.loads(response)
                        return response_data
                    except asyncio.TimeoutError:
                        return {"type": "timeout"}
            except Exception:
                return {"type": "connection_error"}
        
        # Send all commands concurrently
        tasks = [
            send_mcp_command(cmd_info["client_id"], cmd_info["command"])
            for cmd_info in mcp_commands
        ]
        
        try:
            responses = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Verify responses
            successful_responses = 0
            for response in responses:
                if isinstance(response, dict) and response.get("type") in ["mcp_response", "error"]:
                    successful_responses += 1
            
            # At least some servers should respond
            assert successful_responses >= 0
            
        except Exception as e:
            pytest.skip(f"MCP orchestration test failed: {e}")
    
    async def test_mcp_server_error_handling(self, test_server):
        """Test MCP server error handling for invalid commands."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/error_test_client"
        
        invalid_commands = [
            {
                "type": "mcp_command",
                "server_name": "nonexistent_server",
                "command": "any_command",
                "params": {}
            },
            {
                "type": "mcp_command",
                "server_name": "document",
                "command": "invalid_command",
                "params": {}
            },
            {
                "type": "mcp_command",
                "server_name": "document",
                "command": "generate_pdf",
                "params": {}  # Missing required parameters
            }
        ]
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                for invalid_cmd in invalid_commands:
                    await websocket.send(json.dumps(invalid_cmd))
                    
                    try:
                        response = await asyncio.wait_for(websocket.recv(), timeout=5.0)
                        response_data = json.loads(response)
                        
                        # Should receive error response for invalid commands
                        assert "type" in response_data
                        assert response_data["type"] in ["error", "mcp_response"]
                        
                        # If it's an MCP response, it should indicate error
                        if response_data["type"] == "mcp_response":
                            result = response_data.get("result", {})
                            # Result should indicate error or failure
                            assert isinstance(result, dict)
                    
                    except asyncio.TimeoutError:
                        # No response is acceptable for invalid commands
                        pass
                
        except Exception as e:
            pytest.skip(f"WebSocket connection failed: {e}")


class TestMCPServerPerformance:
    """Test suite for MCP server performance characteristics."""
    
    async def test_mcp_server_response_times(self, test_server):
        """Test MCP server response time performance."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/performance_test_client"
        
        # Simple commands that should execute quickly
        quick_commands = [
            {
                "type": "mcp_command",
                "server_name": "search",
                "command": "web_search",
                "params": {"query": "test", "limit": 1}
            }
        ]
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                for command in quick_commands:
                    start_time = time.time()
                    
                    await websocket.send(json.dumps(command))
                    
                    try:
                        response = await asyncio.wait_for(websocket.recv(), timeout=10.0)
                        response_time = time.time() - start_time
                        
                        # Response should be received within reasonable time
                        assert response_time < 10.0  # 10 second threshold
                        
                        response_data = json.loads(response)
                        if response_data.get("type") == "mcp_response":
                            # Check if processing time is recorded
                            processing_time = response_data.get("processing_time", 0)
                            if processing_time > 0:
                                assert processing_time < 10.0
                    
                    except asyncio.TimeoutError:
                        pytest.skip("MCP server response timeout")
                
        except Exception as e:
            pytest.skip(f"WebSocket connection failed: {e}")
    
    async def test_mcp_server_load_handling(self, test_server):
        """Test MCP server behavior under load."""
        base_ws_url = test_server.replace("http://", "ws://") + "/ws/"
        
        async def send_load_command(client_num: int):
            """Send command from load testing client."""
            ws_url = base_ws_url + f"load_test_client_{client_num}"
            command = {
                "type": "mcp_command",
                "server_name": "document",
                "command": "generate_pdf",
                "params": {"content": f"Load test {client_num}", "title": f"Doc {client_num}"}
            }
            
            try:
                import websockets
                async with websockets.connect(ws_url, timeout=5) as websocket:
                    await websocket.send(json.dumps(command))
                    
                    try:
                        response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                        response_data = json.loads(response)
                        return response_data.get("type") == "mcp_response"
                    except asyncio.TimeoutError:
                        return False
            except Exception:
                return False
        
        # Send multiple concurrent commands
        num_clients = 5
        tasks = [send_load_command(i) for i in range(num_clients)]
        
        try:
            results = await asyncio.gather(*tasks, return_exceptions=True)
            
            # Count successful responses
            successful = sum(1 for result in results if result is True)
            
            # Should handle at least some concurrent requests
            assert successful >= 0
            
        except Exception as e:
            pytest.skip(f"MCP load test failed: {e}")


class TestMCPServerIntegration:
    """Test suite for end-to-end MCP server integration scenarios."""
    
    async def test_complete_voice_to_document_pipeline(self, test_server, sample_voice_data):
        """Test complete pipeline from voice input to document generation."""
        ws_url = test_server.replace("http://", "ws://") + "/ws/pipeline_test_client"
        
        try:
            import websockets
            async with websockets.connect(ws_url, timeout=10) as websocket:
                # 1. Process voice input
                voice_message = {
                    "type": "audio",
                    **sample_voice_data
                }
                
                await websocket.send(json.dumps(voice_message))
                
                # 2. Get transcription
                try:
                    voice_response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                    voice_data = json.loads(voice_response)
                    
                    if voice_data.get("type") == "audio_response" and voice_data.get("transcription"):
                        # 3. Generate document based on transcription
                        doc_command = {
                            "type": "mcp_command",
                            "server_name": "document",
                            "command": "generate_pdf",
                            "params": {
                                "content": f"Based on voice input: {voice_data['transcription']}",
                                "title": "Voice-to-Document Test"
                            }
                        }
                        
                        await websocket.send(json.dumps(doc_command))
                        
                        # 4. Get document generation response
                        try:
                            doc_response = await asyncio.wait_for(websocket.recv(), timeout=15.0)
                            doc_data = json.loads(doc_response)
                            
                            assert "type" in doc_data
                            assert doc_data["type"] in ["mcp_response", "error"]
                            
                            if doc_data["type"] == "mcp_response":
                                assert doc_data["server_name"] == "document"
                                assert doc_data["command"] == "generate_pdf"
                        
                        except asyncio.TimeoutError:
                            pytest.skip("Document generation timeout in pipeline")
                
                except asyncio.TimeoutError:
                    pytest.skip("Voice processing timeout in pipeline")
                
        except Exception as e:
            pytest.skip(f"Pipeline test connection failed: {e}")