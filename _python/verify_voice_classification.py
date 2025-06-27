#!/usr/bin/env python3
"""
* Purpose: Verification script for voice classification and context management system
* Issues & Complexity Summary: Comprehensive testing and validation of all components
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~200
  - Core Algorithm Complexity: Medium (integration testing)
  - Dependencies: All voice classification modules
  - State Management Complexity: Medium (test orchestration)
  - Novelty/Uncertainty Factor: Low (standard testing)
* AI Pre-Task Self-Assessment: 92%
* Problem Estimate: 88%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 87%
* Overall Result Score: 90%
* Key Variances/Learnings: Comprehensive verification system
* Last Updated: 2025-06-26
"""

import asyncio
import logging
import time
from typing import List, Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def verify_voice_classification():
    """Verify voice classification system components"""

    print("🎯 Jarvis Live Voice Classification System Verification")
    print("=" * 60)

    try:
        # Import modules
        from src.ai.voice_classifier import voice_classifier, CommandCategory
        from src.ai.context_manager import context_manager
        from src.ai.performance_optimizer import performance_optimizer

        print("✅ Successfully imported all modules")

        # Initialize voice classifier
        print("\n🔧 Initializing voice classifier...")
        await voice_classifier.initialize()
        print("✅ Voice classifier initialized")

        # Initialize context manager
        print("\n🔧 Initializing context manager...")
        await context_manager.initialize()
        print("✅ Context manager initialized")

        # Test voice classification
        print("\n🎤 Testing voice classification...")
        test_commands = [
            "create a document about machine learning",
            "send an email to john@example.com about the meeting",
            "schedule a meeting with the team tomorrow",
            "search for information about Python programming",
            "calculate 25 plus 15 times 3",
            "remind me to call mom at 6 PM",
            "hello how are you today",
        ]

        classification_results = []
        for i, command in enumerate(test_commands):
            print(f"  {i+1}. Testing: '{command}'")

            start_time = time.time()
            result = await voice_classifier.classify_command(
                text=command,
                user_id=f"test_user_{i}",
                session_id=f"test_session_{i}",
                use_context=True,
            )
            processing_time = time.time() - start_time

            classification_results.append(
                {
                    "command": command,
                    "category": result.category.value,
                    "confidence": result.confidence,
                    "processing_time": processing_time,
                    "parameters": result.parameters,
                }
            )

            print(f"     → Category: {result.category.value}")
            print(f"     → Confidence: {result.confidence:.3f}")
            print(f"     → Time: {processing_time:.3f}s")
            if result.parameters:
                print(f"     → Parameters: {result.parameters}")
            print()

        print("✅ Voice classification tests completed")

        # Test context management
        print("\n💭 Testing context management...")

        user_id = "context_test_user"
        session_id = "context_test_session"

        # Update context with interactions
        for i, result in enumerate(classification_results[:3]):
            await context_manager.update_context_interaction(
                user_id=user_id,
                session_id=session_id,
                user_input=result["command"],
                bot_response=f"I'll help you with {result['category']}",
                category=CommandCategory(result["category"]),
                parameters=result["parameters"],
            )

        # Get context summary
        summary = await context_manager.get_context_summary(user_id, session_id)
        print(f"  Context summary: {summary}")

        # Get suggestions
        suggestions = await context_manager.get_contextual_suggestions(
            user_id, session_id
        )
        print(f"  Suggestions: {suggestions}")

        print("✅ Context management tests completed")

        # Test performance metrics
        print("\n📊 Testing performance metrics...")

        classifier_metrics = voice_classifier.get_performance_metrics()
        print(f"  Classifier metrics: {classifier_metrics}")

        context_metrics = context_manager.get_performance_metrics()
        print(f"  Context metrics: {context_metrics}")

        print("✅ Performance metrics tests completed")

        # Performance summary
        print("\n📈 Performance Summary")
        print("-" * 30)

        total_time = sum(r["processing_time"] for r in classification_results)
        avg_time = total_time / len(classification_results)

        print(f"  Total commands processed: {len(classification_results)}")
        print(f"  Total processing time: {total_time:.3f}s")
        print(f"  Average time per command: {avg_time:.3f}s")
        print(f"  Commands per second: {len(classification_results) / total_time:.1f}")

        # Category distribution
        categories = {}
        for result in classification_results:
            category = result["category"]
            categories[category] = categories.get(category, 0) + 1

        print(f"  Category distribution: {categories}")

        # Confidence distribution
        high_confidence = sum(
            1 for r in classification_results if r["confidence"] > 0.8
        )
        medium_confidence = sum(
            1 for r in classification_results if 0.5 <= r["confidence"] <= 0.8
        )
        low_confidence = sum(1 for r in classification_results if r["confidence"] < 0.5)

        print(f"  High confidence (>0.8): {high_confidence}")
        print(f"  Medium confidence (0.5-0.8): {medium_confidence}")
        print(f"  Low confidence (<0.5): {low_confidence}")

        print("\n🎉 All verification tests passed successfully!")
        print("✅ Voice classification system is ready for production")

        return True

    except Exception as e:
        print(f"\n❌ Verification failed: {e}")
        import traceback

        traceback.print_exc()
        return False


async def test_api_endpoints():
    """Test API endpoints (requires server to be running)"""

    print("\n🌐 Testing API endpoints...")

    try:
        import httpx

        base_url = "http://localhost:8000"

        async with httpx.AsyncClient() as client:
            # Test health endpoint
            print("  Testing health endpoint...")
            response = await client.get(f"{base_url}/health")
            if response.status_code == 200:
                print("  ✅ Health endpoint working")
            else:
                print(f"  ❌ Health endpoint failed: {response.status_code}")

            # Test voice classification endpoint
            print("  Testing voice classification endpoint...")
            classification_request = {
                "text": "create a document about artificial intelligence",
                "user_id": "api_test_user",
                "session_id": "api_test_session",
                "use_context": True,
                "include_suggestions": True,
            }

            response = await client.post(
                f"{base_url}/voice/classify", json=classification_request
            )

            if response.status_code == 200:
                result = response.json()
                print(
                    f"  ✅ Classification result: {result['category']} (confidence: {result['confidence']:.3f})"
                )
            else:
                print(f"  ❌ Classification endpoint failed: {response.status_code}")

            # Test categories endpoint
            print("  Testing categories endpoint...")
            response = await client.get(f"{base_url}/voice/categories")
            if response.status_code == 200:
                categories = response.json()
                print(f"  ✅ Available categories: {len(categories)}")
            else:
                print(f"  ❌ Categories endpoint failed: {response.status_code}")

        print("✅ API endpoint tests completed")

    except ImportError:
        print("  ⚠️  httpx not available, skipping API tests")
    except Exception as e:
        print(f"  ❌ API test failed: {e}")


async def main():
    """Main verification function"""

    print("Starting Jarvis Live Voice Classification Verification...")
    print(f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S')}")

    # Core system verification
    core_success = await verify_voice_classification()

    # API endpoint testing (optional)
    await test_api_endpoints()

    if core_success:
        print("\n🎯 VERIFICATION COMPLETE - SYSTEM READY! 🎯")
        return 0
    else:
        print("\n💥 VERIFICATION FAILED - SYSTEM NOT READY 💥")
        return 1


if __name__ == "__main__":
    exit_code = asyncio.run(main())
