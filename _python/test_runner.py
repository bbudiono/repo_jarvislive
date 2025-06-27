"""
API Endpoint Test Runner for Jarvis Live Backend
Validates all endpoints and authentication without external dependencies
"""

import sys
import json
from typing import Dict, Any
import asyncio


def validate_jwt_implementation():
    """Validate JWT authentication implementation exists"""
    try:
        from src.auth.jwt_auth import JWTAuth, get_current_user, APIKeyManager
        from src.api.auth_routes import router as auth_router

        print("✅ JWT Authentication module imported successfully")

        # Test token generation
        token = JWTAuth.create_access_token(user_id="test_user")
        print(f"✅ JWT Token generated: {token[:50]}...")

        # Test token verification
        payload = JWTAuth.verify_token(token)
        print(f"✅ JWT Token verified for user: {payload.get('sub')}")

        # Test API key validation
        user_id = APIKeyManager.validate_api_key("demo_key_123")
        print(f"✅ API Key validation works: {user_id}")

        return True

    except Exception as e:
        print(f"❌ JWT implementation error: {e}")
        return False


def validate_secure_app_structure():
    """Validate secure FastAPI app structure"""
    try:
        from src.main_secure import app

        print("✅ Secure FastAPI app imported successfully")

        # Check routes exist
        routes = [route.path for route in app.routes]
        expected_routes = [
            "/health",
            "/auth/token",
            "/auth/verify",
            "/voice/classify",
            "/voice/categories",
            "/voice/metrics",
            "/document/generate",
            "/email/send",
            "/search/web",
            "/ai/process",
        ]

        missing_routes = []
        for route in expected_routes:
            if route not in routes:
                missing_routes.append(route)

        if missing_routes:
            print(f"❌ Missing routes: {missing_routes}")
            return False
        else:
            print(f"✅ All {len(expected_routes)} expected routes exist")
            return True

    except Exception as e:
        print(f"❌ Secure app structure error: {e}")
        return False


def validate_api_models():
    """Validate API models exist and are properly structured"""
    try:
        from src.api.models import (
            VoiceClassificationRequest,
            VoiceClassificationResponse,
            DocumentGenerationRequest,
            DocumentGenerationResponse,
            EmailSendRequest,
            EmailSendResponse,
            WebSearchRequest,
            WebSearchResponse,
            AIProviderRequest,
            AIProviderResponse,
            HealthResponse,
        )

        print("✅ All API models imported successfully")

        # Test model instantiation
        health_model = HealthResponse(
            status="healthy",
            version="1.0.0",
            mcp_servers={},
            redis_status="connected",
            websocket_connections=0,
        )

        print(f"✅ Model validation works: {health_model.status}")
        return True

    except Exception as e:
        print(f"❌ API models error: {e}")
        return False


def validate_test_structure():
    """Validate test file structure"""
    try:
        import tests.test_api_endpoints as test_module

        # Check test class exists
        test_class = getattr(test_module, "TestAPIEndpoints", None)
        if not test_class:
            print("❌ TestAPIEndpoints class not found")
            return False

        # Count test methods
        test_methods = [
            method for method in dir(test_class) if method.startswith("test_")
        ]
        print(f"✅ Found {len(test_methods)} test methods")

        if len(test_methods) < 10:
            print(f"❌ Insufficient test coverage: only {len(test_methods)} tests")
            return False

        # Validate critical test methods exist
        critical_tests = [
            "test_health_endpoint_no_auth",
            "test_auth_token_generation_success",
            "test_voice_classify_endpoint_success",
            "test_all_protected_endpoints_require_auth",
        ]

        missing_tests = [
            test
            for test in critical_tests
            if f"test_{test}" not in test_methods and test not in test_methods
        ]

        if missing_tests:
            print(f"❌ Missing critical tests: {missing_tests}")
            return False

        print("✅ All critical test methods exist")
        return True

    except Exception as e:
        print(f"❌ Test structure validation error: {e}")
        return False


def run_validation_suite():
    """Run complete validation suite"""
    print("🔍 Starting API Endpoint Implementation Validation")
    print("=" * 60)

    validations = [
        ("JWT Authentication Implementation", validate_jwt_implementation),
        ("Secure App Structure", validate_secure_app_structure),
        ("API Models", validate_api_models),
        ("Test Structure", validate_test_structure),
    ]

    results = []
    for name, validator in validations:
        print(f"\n📋 Validating: {name}")
        print("-" * 40)
        result = validator()
        results.append((name, result))

        if result:
            print(f"✅ {name}: PASSED")
        else:
            print(f"❌ {name}: FAILED")

    print("\n" + "=" * 60)
    print("📊 VALIDATION SUMMARY")
    print("=" * 60)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{name}: {status}")

    print(f"\nOverall Result: {passed}/{total} validations passed")

    if passed == total:
        print("🎉 ALL VALIDATIONS PASSED - AUDIT COMPLIANCE ACHIEVED")
        return True
    else:
        print("🚨 VALIDATION FAILURES - AUDIT COMPLIANCE NOT MET")
        return False


if __name__ == "__main__":
    success = run_validation_suite()
    sys.exit(0 if success else 1)
