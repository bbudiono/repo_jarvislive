#!/usr/bin/env python3
"""
* Purpose: Simplified CI test runner for GitHub Actions compatibility
* Issues & Complexity Summary: Lightweight test orchestration for CI/CD pipelines
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~100
  - Core Algorithm Complexity: Low (Simple test orchestration)
  - Dependencies: 2 New (subprocess, sys)
  - State Management Complexity: Low (Basic process management)
  - Novelty/Uncertainty Factor: Low (Standard CI patterns)
* AI Pre-Task Self-Assessment: 95%
* Problem Estimate: 90%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 82%
* Overall Result Score: 94%
* Key Variances/Learnings: CI compatibility requires minimal dependencies
* Last Updated: 2025-06-26
"""

import subprocess
import sys
import os
from pathlib import Path


def run_command(cmd, description, critical=True):
    """Run a command and handle the result"""
    print(f"🔄 {description}...")

    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, check=True
        )
        print(f"✅ {description} - PASSED")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} - FAILED")
        print(f"Exit code: {e.returncode}")
        if e.stdout:
            print(f"STDOUT:\n{e.stdout}")
        if e.stderr:
            print(f"STDERR:\n{e.stderr}")

        if critical:
            return False
        else:
            print(f"⚠️ Non-critical failure, continuing...")
            return True


def main():
    """Main CI test execution"""
    print("🚀 Starting CI Test Suite for Jarvis Live")
    print("=" * 60)

    # Change to python directory
    os.chdir(Path(__file__).parent)

    # Track overall success
    all_passed = True

    # Test 1: Code formatting check
    if not run_command("black --check --diff .", "Black code formatting check"):
        all_passed = False

    # Test 2: Import sorting check
    if not run_command("isort --check-only --diff .", "Import sorting check"):
        all_passed = False

    # Test 3: Linting
    if not run_command("flake8 src/ --max-line-length=88", "Flake8 linting"):
        all_passed = False

    # Test 4: Type checking
    if not run_command("mypy src/ --ignore-missing-imports", "MyPy type checking"):
        all_passed = False

    # Test 5: Unit tests
    if not run_command(
        "python -m pytest tests/ -v --tb=short --disable-warnings", "Unit tests"
    ):
        all_passed = False

    # Test 6: Basic smoke test
    if not run_command(
        "python -c 'from src.main import app; print(\"✅ Main app imports successfully\")'",
        "Import smoke test",
    ):
        all_passed = False

    # Summary
    print("\n" + "=" * 60)
    if all_passed:
        print("✅ ALL CI TESTS PASSED")
        print("Build is ready for deployment")
        sys.exit(0)
    else:
        print("❌ CI TESTS FAILED")
        print("Please fix the failing tests before merging")
        sys.exit(1)


if __name__ == "__main__":
    main()
