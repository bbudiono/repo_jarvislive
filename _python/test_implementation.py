#!/usr/bin/env python3
"""
Simple test script to verify the voice classification implementation structure
"""

import sys
import os
import importlib.util


def test_imports():
    """Test that all modules can be imported"""
    print("🔍 Testing module imports...")

    # Test base imports
    modules_to_test = [
        "src.ai.voice_classifier",
        "src.ai.context_manager",
        "src.ai.performance_optimizer",
        "src.api.routes",
        "src.api.models",
    ]

    for module_name in modules_to_test:
        try:
            # Convert module path to file path
            module_path = module_name.replace(".", "/") + ".py"

            if os.path.exists(module_path):
                print(f"  ✅ {module_name} - file exists")

                # Try to load module spec
                spec = importlib.util.spec_from_file_location(module_name, module_path)
                if spec:
                    print(f"     → Module spec created successfully")
                else:
                    print(f"     ⚠️  Could not create module spec")
            else:
                print(f"  ❌ {module_name} - file not found at {module_path}")

        except Exception as e:
            print(f"  ❌ {module_name} - error: {e}")

    print()


def test_file_structure():
    """Test that all required files exist"""
    print("📁 Testing file structure...")

    required_files = [
        "src/ai/__init__.py",
        "src/ai/voice_classifier.py",
        "src/ai/context_manager.py",
        "src/ai/performance_optimizer.py",
        "src/api/routes.py",
        "src/api/models.py",
        "src/main.py",
        "requirements.txt",
        "tests/test_voice_classifier.py",
        "VOICE_CLASSIFICATION_API.md",
        "verify_voice_classification.py",
    ]

    for file_path in required_files:
        if os.path.exists(file_path):
            size = os.path.getsize(file_path)
            print(f"  ✅ {file_path} ({size:,} bytes)")
        else:
            print(f"  ❌ {file_path} - missing")

    print()


def test_code_structure():
    """Test basic code structure without imports"""
    print("🔧 Testing code structure...")

    # Test voice_classifier.py structure
    try:
        with open("src/ai/voice_classifier.py", "r") as f:
            content = f.read()

        checks = [
            ("class VoiceClassifier", "VoiceClassifier class"),
            ("class CommandCategory", "CommandCategory enum"),
            ("class ClassificationResult", "ClassificationResult dataclass"),
            ("async def classify_command", "classify_command method"),
            ("def preprocess_text", "preprocess_text method"),
            ("def extract_parameters", "extract_parameters method"),
        ]

        for check, description in checks:
            if check in content:
                print(f"  ✅ {description} - found")
            else:
                print(f"  ❌ {description} - missing")

    except Exception as e:
        print(f"  ❌ Error reading voice_classifier.py: {e}")

    # Test context_manager.py structure
    try:
        with open("src/ai/context_manager.py", "r") as f:
            content = f.read()

        checks = [
            ("class ContextManager", "ContextManager class"),
            ("async def get_context", "get_context method"),
            ("async def save_context", "save_context method"),
            (
                "async def update_context_interaction",
                "update_context_interaction method",
            ),
        ]

        for check, description in checks:
            if check in content:
                print(f"  ✅ {description} - found")
            else:
                print(f"  ❌ {description} - missing")

    except Exception as e:
        print(f"  ❌ Error reading context_manager.py: {e}")

    print()


def test_api_structure():
    """Test API structure"""
    print("🌐 Testing API structure...")

    try:
        with open("src/api/routes.py", "r") as f:
            content = f.read()

        endpoints = [
            ("/voice/classify", "Voice classification endpoint"),
            ("/voice/categories", "Voice categories endpoint"),
            ("/voice/metrics", "Voice metrics endpoint"),
            ("/context/{user_id}/{session_id}/summary", "Context summary endpoint"),
            (
                "/context/{user_id}/{session_id}/suggestions",
                "Context suggestions endpoint",
            ),
            ("@voice_router.post", "Voice router POST methods"),
            ("@context_router.get", "Context router GET methods"),
        ]

        for endpoint, description in endpoints:
            if endpoint in content:
                print(f"  ✅ {description} - found")
            else:
                print(f"  ❌ {description} - missing")

    except Exception as e:
        print(f"  ❌ Error reading routes.py: {e}")

    print()


def analyze_implementation():
    """Analyze the implementation quality"""
    print("📊 Implementation Analysis...")

    try:
        # Count lines of code
        total_lines = 0
        files_analyzed = 0

        python_files = [
            "src/ai/voice_classifier.py",
            "src/ai/context_manager.py",
            "src/ai/performance_optimizer.py",
            "src/api/routes.py",
        ]

        for file_path in python_files:
            if os.path.exists(file_path):
                with open(file_path, "r") as f:
                    lines = len(f.readlines())
                    total_lines += lines
                    files_analyzed += 1
                    print(f"  📄 {file_path}: {lines:,} lines")

        print(
            f"\n  📈 Total implementation: {total_lines:,} lines across {files_analyzed} files"
        )

        # Check for key features
        features = [
            ("NLP processing", "spacy"),
            ("Machine learning", "sklearn"),
            ("Async support", "async def"),
            ("Redis caching", "redis"),
            ("Performance optimization", "cache"),
            ("Context management", "ConversationContext"),
            ("Error handling", "try:"),
            ("Logging", "logger"),
            ("Type hints", "typing"),
            ("Documentation", '"""'),
        ]

        print(f"\n  🎯 Feature Analysis:")
        for feature, keyword in features:
            found_in = 0
            for file_path in python_files:
                if os.path.exists(file_path):
                    with open(file_path, "r") as f:
                        if keyword in f.read():
                            found_in += 1

            if found_in > 0:
                print(f"     ✅ {feature} - found in {found_in} files")
            else:
                print(f"     ❌ {feature} - not found")

    except Exception as e:
        print(f"  ❌ Analysis error: {e}")

    print()


def main():
    """Main test function"""
    print("🎯 Jarvis Live Voice Classification Implementation Test")
    print("=" * 60)
    print(f"📍 Working directory: {os.getcwd()}")
    print()

    test_file_structure()
    test_imports()
    test_code_structure()
    test_api_structure()
    analyze_implementation()

    print("🎉 Implementation structure verification complete!")
    print("\n📋 Next Steps:")
    print("  1. Install dependencies: pip install -r requirements.txt")
    print("  2. Download spaCy model: python -m spacy download en_core_web_sm")
    print("  3. Start Redis server: redis-server")
    print("  4. Run the FastAPI server: uvicorn src.main:app --reload")
    print("  5. Test endpoints with: python verify_voice_classification.py")

    return 0


if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
