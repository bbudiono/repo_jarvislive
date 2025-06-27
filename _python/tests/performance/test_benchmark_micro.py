"""
Micro-benchmark tests for individual function performance validation
Uses pytest-benchmark for statistical analysis of function execution times
"""

import pytest
import asyncio
from unittest.mock import Mock, patch
from src.voice.voice_classifier import VoiceClassifier
from src.auth.jwt_auth import JWTAuthManager
from src.api.voice_routes import classify_voice_command


class TestVoiceClassifierBenchmarks:
    """Benchmark individual voice classification operations"""

    @pytest.fixture
    def voice_classifier(self):
        """Create voice classifier instance for testing"""
        return VoiceClassifier()

    def test_benchmark_simple_classification(self, benchmark, voice_classifier):
        """Benchmark simple voice command classification"""
        test_text = "Create a PDF document about AI"

        result = benchmark(voice_classifier.classify_command, test_text)

        # Validate result structure
        assert "category" in result
        assert "confidence" in result
        assert result["confidence"] > 0.7

    def test_benchmark_complex_classification(self, benchmark, voice_classifier):
        """Benchmark complex voice command with context"""
        test_text = "Schedule a meeting with John and Sarah for next Tuesday at 2 PM to discuss the quarterly budget review and project timeline updates"
        context = {
            "previous_commands": ["calendar", "email"],
            "user_preferences": {"timezone": "UTC"},
            "session_context": {"active_project": "Q4_Planning"},
        }

        result = benchmark(
            voice_classifier.classify_command_with_context, test_text, context
        )

        assert "category" in result
        assert "parameters" in result

    def test_benchmark_batch_classification(self, benchmark, voice_classifier):
        """Benchmark batch processing of multiple commands"""
        test_commands = [
            "Create a document",
            "Send an email",
            "Schedule a meeting",
            "Search for information",
            "Hello Jarvis",
        ]

        result = benchmark(voice_classifier.classify_batch, test_commands)

        assert len(result) == 5
        assert all("category" in r for r in result)


class TestJWTAuthManagerBenchmarks:
    """Benchmark JWT authentication operations"""

    @pytest.fixture
    def jwt_manager(self):
        """Create JWT manager instance for testing"""
        return JWTAuthManager()

    def test_benchmark_token_creation(self, benchmark, jwt_manager):
        """Benchmark JWT token creation"""
        user_id = "test_user_123"

        token = benchmark(jwt_manager.create_access_token, user_id)

        assert isinstance(token, str)
        assert len(token) > 100  # JWT tokens are typically long

    def test_benchmark_token_validation(self, benchmark, jwt_manager):
        """Benchmark JWT token validation"""
        # Create a token first
        user_id = "test_user_123"
        token = jwt_manager.create_access_token(user_id)

        result = benchmark(jwt_manager.validate_token, token)

        assert result["user_id"] == user_id

    def test_benchmark_token_refresh(self, benchmark, jwt_manager):
        """Benchmark JWT token refresh operation"""
        user_id = "test_user_123"
        old_token = jwt_manager.create_access_token(user_id)

        new_token = benchmark(jwt_manager.refresh_token, old_token)

        assert isinstance(new_token, str)
        assert new_token != old_token


class TestAPIEndpointBenchmarks:
    """Benchmark actual API endpoint performance"""

    @pytest.mark.asyncio
    async def test_benchmark_voice_classify_endpoint(self, benchmark):
        """Benchmark the actual voice classification endpoint"""

        # Mock dependencies
        mock_request_data = {
            "text": "Create a PDF document about machine learning",
            "session_id": "benchmark_test",
            "context": {},
        }

        mock_current_user = {"user_id": "benchmark_user"}

        # Use benchmark.pedantic for async functions
        result = benchmark.pedantic(
            self._async_classify_wrapper,
            args=(mock_request_data, mock_current_user),
            rounds=10,
            iterations=1,
        )

        assert result["category"] == "document_generation"
        assert result["confidence"] > 0.8

    async def _async_classify_wrapper(self, request_data, current_user):
        """Wrapper for async voice classification endpoint"""
        with patch("src.api.voice_routes.get_current_user", return_value=current_user):
            # Mock the request object
            mock_request = Mock()
            mock_request.json.return_value = request_data

            # Call the actual endpoint function
            response = await classify_voice_command(mock_request, current_user)
            return response


class TestDataProcessingBenchmarks:
    """Benchmark data processing operations"""

    def test_benchmark_text_preprocessing(self, benchmark):
        """Benchmark text preprocessing operations"""
        test_text = "Hello! Can you please create a comprehensive PDF document about artificial intelligence, machine learning, and deep learning technologies for our upcoming presentation? Thanks!"

        from src.voice.text_processor import TextProcessor

        processor = TextProcessor()

        result = benchmark(processor.preprocess_text, test_text)

        assert len(result) > 0
        assert isinstance(result, str)

    def test_benchmark_context_analysis(self, benchmark):
        """Benchmark context analysis for voice commands"""
        context = {
            "previous_commands": ["document", "email", "calendar"] * 10,
            "user_preferences": {"format": "pdf", "language": "en"},
            "session_history": [
                {"command": f"test_{i}", "timestamp": i} for i in range(50)
            ],
            "active_projects": ["AI_Research", "ML_Implementation", "Data_Pipeline"],
        }

        from src.voice.context_analyzer import ContextAnalyzer

        analyzer = ContextAnalyzer()

        result = benchmark(analyzer.analyze_context, context)

        assert "relevance_score" in result
        assert "suggested_actions" in result

    def test_benchmark_response_generation(self, benchmark):
        """Benchmark response generation for voice commands"""
        classification_result = {
            "category": "document_generation",
            "intent": "create_pdf",
            "confidence": 0.95,
            "parameters": {
                "content": "AI technology overview",
                "format": "pdf",
                "template": "professional",
            },
        }

        from src.voice.response_generator import ResponseGenerator

        generator = ResponseGenerator()

        result = benchmark(generator.generate_response, classification_result)

        assert len(result) > 20  # Meaningful response length
        assert "document" in result.lower()


class TestConcurrencyBenchmarks:
    """Benchmark concurrent operations"""

    @pytest.mark.asyncio
    async def test_benchmark_concurrent_classifications(self, benchmark):
        """Benchmark concurrent voice classifications"""

        async def concurrent_classifications():
            from src.voice.voice_classifier import VoiceClassifier

            classifier = VoiceClassifier()

            tasks = []
            test_commands = [
                "Create a document about AI",
                "Send email to team",
                "Schedule meeting tomorrow",
                "Search for ML papers",
                "Hello assistant",
            ] * 10  # 50 concurrent classifications

            for command in test_commands:
                task = asyncio.create_task(
                    asyncio.to_thread(classifier.classify_command, command)
                )
                tasks.append(task)

            results = await asyncio.gather(*tasks)
            return results

        results = benchmark.pedantic(concurrent_classifications, rounds=3, iterations=1)

        assert len(results) == 50
        assert all("category" in result for result in results)


@pytest.fixture(scope="session", autouse=True)
def setup_benchmark_environment():
    """Setup environment for benchmarking"""
    import os

    os.environ["TESTING"] = "true"
    os.environ["JWT_SECRET_KEY"] = "benchmark_test_secret_key_12345"
    os.environ["JWT_ALGORITHM"] = "HS256"
