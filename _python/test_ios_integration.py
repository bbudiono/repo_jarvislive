#!/usr/bin/env python3
"""
Test script to validate iOS-Python integration for Jarvis Live Voice Classification
This script simulates the exact requests that the iOS VoiceClassificationManager would make
"""

import requests
import json
import time
from typing import Dict, Any

BASE_URL = "http://localhost:8000"
TEST_API_KEY = "test-api-key"


def test_authentication_flow():
    """Test the complete authentication flow"""
    print("🔐 Testing Authentication Flow...")

    # Step 1: Generate JWT token
    token_response = requests.post(
        f"{BASE_URL}/auth/token",
        json={"api_key": TEST_API_KEY},
        headers={"User-Agent": "iOS/JarvisLive-Sandbox/1.0"},
    )

    assert (
        token_response.status_code == 200
    ), f"Token generation failed: {token_response.text}"

    token_data = token_response.json()
    access_token = token_data["access_token"]

    print(f"   ✅ JWT Token generated successfully")
    print(f"   📄 Token type: {token_data['token_type']}")
    print(f"   ⏰ Expires in: {token_data['expires_in']} seconds")

    # Step 2: Verify JWT token
    verify_response = requests.get(
        f"{BASE_URL}/auth/verify", headers={"Authorization": f"Bearer {access_token}"}
    )

    assert (
        verify_response.status_code == 200
    ), f"Token verification failed: {verify_response.text}"

    verify_data = verify_response.json()
    print(f"   ✅ Token verified successfully")
    print(f"   👤 User ID: {verify_data['user_id']}")
    print(f"   ⏱️ Time remaining: {verify_data['time_remaining_seconds']} seconds")

    return access_token


def test_voice_classification(access_token: str):
    """Test voice classification with various commands"""
    print("\n🎤 Testing Voice Classification...")

    test_commands = [
        "create a document about machine learning",
        "send an email to john@example.com about the meeting",
        "schedule a team meeting for tomorrow at 2 PM",
        "search for information about artificial intelligence",
        "calculate 25 plus 37",
        "remind me to call mom at 5 PM",
        "open the calculator app",
        "hello, how are you today?",
    ]

    results = []

    for command in test_commands:
        print(f"\n   🗣️ Testing command: '{command}'")

        start_time = time.time()

        # Make classification request (exactly like iOS VoiceClassificationManager)
        classification_response = requests.post(
            f"{BASE_URL}/voice/classify",
            json={
                "text": command,
                "user_id": "test_user_ios",
                "session_id": "test_session_123",
                "use_context": True,
                "include_suggestions": True,
            },
            headers={"Authorization": f"Bearer {access_token}"},
        )

        request_time = time.time() - start_time

        assert (
            classification_response.status_code == 200
        ), f"Classification failed: {classification_response.text}"

        result = classification_response.json()
        results.append(result)

        print(f"      📂 Category: {result['category']}")
        print(f"      🎯 Intent: {result['intent']}")
        print(
            f"      📊 Confidence: {result['confidence']:.2f} ({result['confidence_level']})"
        )
        print(f"      ⚡ Processing Time: {request_time:.3f}s")
        print(f"      🔧 Parameters: {result['parameters']}")

        if result["suggestions"]:
            print(f"      💡 Suggestions: {result['suggestions']}")

        # Validate classification makes sense
        if "document" in command or "create" in command:
            assert (
                result["category"] == "document_generation"
            ), f"Expected document_generation, got {result['category']}"
        elif "email" in command or "send" in command:
            assert (
                result["category"] == "email_management"
            ), f"Expected email_management, got {result['category']}"
        elif "schedule" in command or "meeting" in command:
            assert (
                result["category"] == "calendar_scheduling"
            ), f"Expected calendar_scheduling, got {result['category']}"
        elif "search" in command:
            assert (
                result["category"] == "web_search"
            ), f"Expected web_search, got {result['category']}"
        elif "calculate" in command or "plus" in command:
            assert (
                result["category"] == "calculations"
            ), f"Expected calculations, got {result['category']}"
        elif "remind" in command:
            assert (
                result["category"] == "reminders"
            ), f"Expected reminders, got {result['category']}"
        elif "open" in command:
            assert (
                result["category"] == "system_control"
            ), f"Expected system_control, got {result['category']}"
        elif "hello" in command:
            assert (
                result["category"] == "general_conversation"
            ), f"Expected general_conversation, got {result['category']}"

        print(f"      ✅ Classification validation passed")

    return results


def test_context_endpoints(access_token: str):
    """Test context management endpoints"""
    print("\n🧠 Testing Context Management...")

    # Test context summary
    summary_response = requests.get(
        f"{BASE_URL}/context/test_user_ios/test_session_123/summary",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert (
        summary_response.status_code == 200
    ), f"Context summary failed: {summary_response.text}"

    summary_data = summary_response.json()
    print(f"   📊 Context Summary:")
    print(f"      👤 User: {summary_data['user_id']}")
    print(f"      🔗 Session: {summary_data['session_id']}")
    print(f"      📈 Total Interactions: {summary_data['total_interactions']}")
    print(f"      📂 Categories Used: {summary_data['categories_used']}")
    print(f"      💭 Current Topic: {summary_data['current_topic']}")

    # Test contextual suggestions
    suggestions_response = requests.get(
        f"{BASE_URL}/context/test_user_ios/test_session_123/suggestions",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert (
        suggestions_response.status_code == 200
    ), f"Contextual suggestions failed: {suggestions_response.text}"

    suggestions_data = suggestions_response.json()
    print(f"   💡 Contextual Suggestions:")
    for suggestion in suggestions_data["suggestions"]:
        print(f"      • {suggestion}")

    print(f"   ✅ Context management working correctly")


def test_performance_metrics(access_token: str):
    """Test performance and metrics endpoints"""
    print("\n📊 Testing Performance Metrics...")

    # Test voice categories
    categories_response = requests.get(
        f"{BASE_URL}/voice/categories",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert (
        categories_response.status_code == 200
    ), f"Categories failed: {categories_response.text}"

    categories_data = categories_response.json()
    print(f"   📂 Available Categories: {len(categories_data['categories'])}")

    # Test metrics
    metrics_response = requests.get(
        f"{BASE_URL}/voice/metrics", headers={"Authorization": f"Bearer {access_token}"}
    )

    assert (
        metrics_response.status_code == 200
    ), f"Metrics failed: {metrics_response.text}"

    metrics_data = metrics_response.json()
    print(f"   📈 Classification Metrics:")
    print(f"      🔢 Total Classifications: {metrics_data['total_classifications']}")
    print(f"      📊 Average Confidence: {metrics_data['average_confidence']:.2f}")
    print(
        f"      ⚡ Average Processing Time: {metrics_data['average_processing_time']:.3f}s"
    )
    print(f"      ✅ Success Rate: {metrics_data['success_rate']:.2%}")

    print(f"   ✅ Performance metrics working correctly")


def test_error_handling(access_token: str):
    """Test error handling scenarios"""
    print("\n❌ Testing Error Handling...")

    # Test invalid endpoint
    invalid_response = requests.get(
        f"{BASE_URL}/invalid/endpoint",
        headers={"Authorization": f"Bearer {access_token}"},
    )

    assert (
        invalid_response.status_code == 404
    ), f"Expected 404, got {invalid_response.status_code}"
    print(f"   ✅ 404 error handling works correctly")

    # Test invalid token
    invalid_token_response = requests.post(
        f"{BASE_URL}/voice/classify",
        json={
            "text": "test command",
            "user_id": "test_user",
            "session_id": "test_session",
        },
        headers={"Authorization": "Bearer invalid-token"},
    )

    assert (
        invalid_token_response.status_code == 401
    ), f"Expected 401, got {invalid_token_response.status_code}"
    print(f"   ✅ Invalid token handling works correctly")

    # Test missing authorization
    no_auth_response = requests.post(
        f"{BASE_URL}/voice/classify",
        json={
            "text": "test command",
            "user_id": "test_user",
            "session_id": "test_session",
        },
    )

    assert (
        no_auth_response.status_code == 403
    ), f"Expected 403, got {no_auth_response.status_code}"
    print(f"   ✅ Missing authorization handling works correctly")


def generate_integration_report(classification_results: list):
    """Generate integration test report"""
    print("\n📋 INTEGRATION TEST REPORT")
    print("=" * 50)

    total_tests = len(classification_results)
    high_confidence = sum(1 for r in classification_results if r["confidence"] >= 0.8)
    medium_confidence = sum(
        1 for r in classification_results if 0.6 <= r["confidence"] < 0.8
    )
    low_confidence = sum(1 for r in classification_results if r["confidence"] < 0.6)

    avg_confidence = sum(r["confidence"] for r in classification_results) / total_tests
    avg_processing_time = (
        sum(r["classification_time"] for r in classification_results) / total_tests
    )

    categories_tested = set(r["category"] for r in classification_results)

    print(f"📊 CLASSIFICATION PERFORMANCE:")
    print(f"   Total Commands Tested: {total_tests}")
    print(f"   Average Confidence: {avg_confidence:.3f}")
    print(f"   Average Processing Time: {avg_processing_time:.6f}s")
    print(f"   Categories Covered: {len(categories_tested)}/8")
    print()

    print(f"📈 CONFIDENCE DISTRIBUTION:")
    print(
        f"   High Confidence (≥0.8): {high_confidence}/{total_tests} ({high_confidence/total_tests:.1%})"
    )
    print(
        f"   Medium Confidence (0.6-0.8): {medium_confidence}/{total_tests} ({medium_confidence/total_tests:.1%})"
    )
    print(
        f"   Low Confidence (<0.6): {low_confidence}/{total_tests} ({low_confidence/total_tests:.1%})"
    )
    print()

    print(f"✅ INTEGRATION STATUS:")
    print(f"   🔐 Authentication Flow: WORKING")
    print(f"   🎤 Voice Classification: WORKING")
    print(f"   🧠 Context Management: WORKING")
    print(f"   📊 Performance Metrics: WORKING")
    print(f"   ❌ Error Handling: WORKING")
    print()

    print(f"🎯 READY FOR iOS INTEGRATION:")
    print(f"   ✅ Backend API fully functional")
    print(f"   ✅ JWT authentication working")
    print(f"   ✅ Voice classification accurate")
    print(f"   ✅ All endpoints responding correctly")
    print(f"   ✅ Error handling robust")
    print()

    print(f"📱 NEXT STEPS:")
    print(f"   1. Run iOS VoiceClassificationManager tests")
    print(f"   2. Validate LiveKit integration")
    print(f"   3. Test end-to-end voice pipeline")
    print(f"   4. Performance optimization")


def main():
    """Run complete iOS-Python integration test suite"""
    print("🚀 JARVIS LIVE iOS-PYTHON INTEGRATION TEST SUITE")
    print("=" * 60)
    print()

    try:
        # Test health endpoint first
        health_response = requests.get(f"{BASE_URL}/health")
        assert health_response.status_code == 200, "Backend not healthy"
        print("✅ Backend health check passed")

        # Run test suite
        access_token = test_authentication_flow()
        classification_results = test_voice_classification(access_token)
        test_context_endpoints(access_token)
        test_performance_metrics(access_token)
        test_error_handling(access_token)

        # Generate final report
        generate_integration_report(classification_results)

        print("\n🎉 ALL INTEGRATION TESTS PASSED!")
        print("✅ iOS VoiceClassificationManager ready for integration")

    except Exception as e:
        print(f"\n❌ INTEGRATION TEST FAILED: {e}")
        raise


if __name__ == "__main__":
    main()
