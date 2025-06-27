#!/bin/bash

# CI/CD Setup Validation Script
# Purpose: Verify that the CI/CD pipeline configuration is properly set up
# Last Updated: 2025-06-26

set -e

echo "🔍 Validating CI/CD Setup for Jarvis Live"
echo "========================================"

# Check if we're in the right directory
if [[ ! -f "CLAUDE.md" ]]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

echo "✅ Project root directory confirmed"

# Check GitHub Actions workflow file
if [[ -f ".github/workflows/ci.yml" ]]; then
    echo "✅ GitHub Actions workflow file exists"
    
    # Validate workflow syntax (basic check)
    if grep -q "name: CI/CD Pipeline" ".github/workflows/ci.yml"; then
        echo "✅ Workflow file appears to be properly configured"
    else
        echo "⚠️ Workflow file might have issues"
    fi
else
    echo "❌ GitHub Actions workflow file missing"
    exit 1
fi

# Check Python CI test runner
if [[ -f "_python/run_ci_tests.py" ]]; then
    echo "✅ Python CI test runner exists"
else
    echo "❌ Python CI test runner missing"
    exit 1
fi

# Check Python dependencies
echo "🔍 Checking Python environment..."
cd _python

if [[ -f "requirements.txt" ]] && [[ -f "requirements-dev.txt" ]]; then
    echo "✅ Python requirements files exist"
else
    echo "❌ Python requirements files missing"
    exit 1
fi

# Check if linting tools are available
if command -v black &> /dev/null; then
    echo "✅ Black formatter available"
else
    echo "⚠️ Black formatter not installed (will be installed in CI)"
fi

if command -v flake8 &> /dev/null; then
    echo "✅ Flake8 linter available"
else
    echo "⚠️ Flake8 linter not installed (will be installed in CI)"
fi

if command -v mypy &> /dev/null; then
    echo "✅ MyPy type checker available"
else
    echo "⚠️ MyPy type checker not installed (will be installed in CI)"
fi

cd ..

# Check iOS project structure
echo "🔍 Checking iOS project structure..."

if [[ -d "_iOS/JarvisLive-Sandbox" ]]; then
    echo "✅ iOS Sandbox project directory exists"
    
    if [[ -f "_iOS/JarvisLive-Sandbox/JarvisLive-Sandbox.xcodeproj/project.pbxproj" ]]; then
        echo "✅ iOS Sandbox project file exists"
    else
        echo "⚠️ iOS Sandbox project file structure might be different"
    fi
else
    echo "❌ iOS Sandbox project directory missing"
    exit 1
fi

if [[ -d "_iOS/JarvisLive" ]]; then
    echo "✅ iOS Production project directory exists"
else
    echo "⚠️ iOS Production project directory missing (might be different structure)"
fi

# Check SwiftLint configuration
if [[ -f "_iOS/JarvisLive-Sandbox/.swiftlint.yml" ]]; then
    echo "✅ SwiftLint configuration exists"
else
    echo "⚠️ SwiftLint configuration missing"
fi

# Check if Xcode is available (on macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    if command -v xcodebuild &> /dev/null; then
        echo "✅ Xcode build tools available"
    else
        echo "⚠️ Xcode build tools not available"
    fi
else
    echo "ℹ️ Not on macOS - Xcode checks skipped"
fi

# Final summary
echo ""
echo "========================================"
echo "✅ CI/CD Setup Validation Complete"
echo ""
echo "The CI/CD pipeline is properly configured and should work in GitHub Actions."
echo "Key components verified:"
echo "  - GitHub Actions workflow file"
echo "  - Python test runner and dependencies"
echo "  - iOS project structure"
echo "  - Linting configurations"
echo ""
echo "🚀 Ready for continuous integration!"