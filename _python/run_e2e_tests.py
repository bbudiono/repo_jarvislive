#!/usr/bin/env python3
"""
* Purpose: E2E test runner for CI/CD pipeline integration
* Issues & Complexity Summary: Automated E2E test execution with proper environment setup
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~200
  - Core Algorithm Complexity: Medium (test orchestration + environment management)
  - Dependencies: 6 New (subprocess, pytest, signal handling)
  - State Management Complexity: Medium (test environment isolation)
  - Novelty/Uncertainty Factor: Low (standard test runner patterns)
* AI Pre-Task Self-Assessment: 90%
* Problem Estimate: 70%
* Initial Code Complexity Estimate: 75%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
"""

import os
import sys
import subprocess
import time
import signal
import asyncio
from pathlib import Path
from typing import List, Optional, Tuple

class E2ETestRunner:
    """Comprehensive E2E test runner for Jarvis Live backend."""
    
    def __init__(self, verbose: bool = True):
        self.verbose = verbose
        self.test_results = {}
        self.test_server_process: Optional[subprocess.Popen] = None
        
        # Test configuration
        self.test_timeout = 300  # 5 minutes total timeout
        self.server_startup_timeout = 30  # 30 seconds for server startup
        
        # Environment setup
        self.setup_test_environment()
    
    def setup_test_environment(self):
        """Setup test environment variables."""
        # Test-specific environment variables
        test_env = {
            "TESTING": "true",
            "LOG_LEVEL": "WARNING",
            "REDIS_URL": "redis://localhost:6379/1",  # Test database
            "TEST_MODE": "e2e",
            "DISABLE_AUTH": "true",  # Simplify E2E testing
            "MCP_SERVER_TIMEOUT": "10",  # Shorter timeouts for testing
        }
        
        for key, value in test_env.items():
            os.environ[key] = value
        
        if self.verbose:
            print("✅ Test environment configured")
    
    def log(self, message: str, level: str = "INFO"):
        """Log message with timestamp."""
        if self.verbose:
            timestamp = time.strftime("%H:%M:%S")
            print(f"[{timestamp}] {level}: {message}")
    
    def run_command(self, command: List[str], description: str, timeout: int = 60) -> bool:
        """Run a command with timeout and return success status."""
        self.log(f"Running: {description}")
        self.log(f"Command: {' '.join(command)}")
        
        try:
            result = subprocess.run(
                command,
                timeout=timeout,
                capture_output=True,
                text=True
            )
            
            success = result.returncode == 0
            
            if success:
                self.log(f"✅ {description} completed successfully")
                if result.stdout and self.verbose:
                    print(f"Output: {result.stdout[:500]}")  # Truncate long output
            else:
                self.log(f"❌ {description} failed (exit code: {result.returncode})", "ERROR")
                if result.stderr:
                    print(f"Error: {result.stderr[:500]}")
                if result.stdout:
                    print(f"Output: {result.stdout[:500]}")
            
            return success
        
        except subprocess.TimeoutExpired:
            self.log(f"⏰ {description} timed out after {timeout} seconds", "ERROR")
            return False
        except Exception as e:
            self.log(f"💥 {description} failed with exception: {e}", "ERROR")
            return False
    
    def check_dependencies(self) -> bool:
        """Check that required dependencies are available."""
        self.log("Checking E2E test dependencies...")
        
        # Check Python dependencies
        required_packages = [
            "pytest",
            "pytest-asyncio", 
            "httpx",
            "websockets",
            "fastapi",
            "uvicorn"
        ]
        
        missing_packages = []
        for package in required_packages:
            try:
                __import__(package.replace("-", "_"))
            except ImportError:
                missing_packages.append(package)
        
        if missing_packages:
            self.log(f"❌ Missing required packages: {', '.join(missing_packages)}", "ERROR")
            self.log("Install with: pip install -r requirements.txt", "ERROR")
            return False
        
        # Check Redis availability (optional)
        try:
            result = subprocess.run(
                ["redis-cli", "ping"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.log("✅ Redis is available")
            else:
                self.log("⚠️ Redis not available - some tests may be skipped", "WARN")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.log("⚠️ Redis not available - some tests may be skipped", "WARN")
        
        self.log("✅ Dependencies check completed")
        return True
    
    def run_test_category(self, category: str, test_files: List[str] = None) -> bool:
        """Run a specific category of E2E tests."""
        self.log(f"Running {category} tests...")
        
        if test_files:
            test_paths = [f"tests/e2e/{test_file}" for test_file in test_files]
        else:
            test_paths = ["tests/e2e/"]
        
        # Pytest command with E2E-specific configuration
        pytest_cmd = [
            "python", "-m", "pytest",
            *test_paths,
            "-v",  # Verbose output
            "--tb=short",  # Short traceback format
            "--disable-warnings",  # Reduce noise
            "--timeout=60",  # Per-test timeout
            "-x",  # Stop on first failure for faster feedback
            "--durations=10",  # Show 10 slowest tests
        ]
        
        # Add markers for specific test categories
        if category == "fast":
            pytest_cmd.extend(["-m", "not slow"])
        elif category == "integration":
            pytest_cmd.extend(["-k", "integration"])
        
        success = self.run_command(
            pytest_cmd,
            f"{category} E2E tests",
            timeout=self.test_timeout
        )
        
        self.test_results[category] = success
        return success
    
    def run_health_check(self) -> bool:
        """Run a quick health check to verify test environment."""
        self.log("Running E2E health check...")
        
        health_check_cmd = [
            "python", "-m", "pytest",
            "tests/e2e/test_api_endpoints.py::TestHealthEndpoint::test_health_endpoint_basic_response",
            "-v",
            "--tb=short",
            "--disable-warnings",
            "--timeout=30"
        ]
        
        return self.run_command(
            health_check_cmd,
            "E2E health check",
            timeout=60
        )
    
    def run_api_tests(self) -> bool:
        """Run API endpoint E2E tests."""
        return self.run_test_category(
            "API",
            ["test_api_endpoints.py"]
        )
    
    def run_websocket_tests(self) -> bool:
        """Run WebSocket communication E2E tests."""
        return self.run_test_category(
            "WebSocket",
            ["test_websocket_communication.py"]
        )
    
    def run_mcp_integration_tests(self) -> bool:
        """Run MCP integration E2E tests."""
        return self.run_test_category(
            "MCP",
            ["test_mcp_integration.py"]
        )
    
    def run_all_tests(self) -> bool:
        """Run all E2E tests."""
        self.log("🚀 Starting comprehensive E2E test suite...")
        
        # Test sequence with increasing complexity
        test_sequence = [
            ("Health Check", self.run_health_check),
            ("API Tests", self.run_api_tests),
            ("WebSocket Tests", self.run_websocket_tests),
            ("MCP Integration Tests", self.run_mcp_integration_tests),
        ]
        
        all_passed = True
        
        for test_name, test_func in test_sequence:
            self.log(f"\n{'='*60}")
            self.log(f"Running: {test_name}")
            self.log(f"{'='*60}")
            
            success = test_func()
            
            if not success:
                self.log(f"❌ {test_name} failed", "ERROR")
                all_passed = False
                
                # For CI environments, continue with remaining tests
                # to get complete picture
                if os.getenv("CI") != "true":
                    self.log("Stopping test execution due to failure", "ERROR")
                    break
            else:
                self.log(f"✅ {test_name} passed")
        
        return all_passed
    
    def generate_report(self) -> str:
        """Generate test execution report."""
        report_lines = [
            "\n" + "="*80,
            "E2E TEST EXECUTION REPORT",
            "="*80,
        ]
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results.values() if result)
        
        report_lines.extend([
            f"Total Test Categories: {total_tests}",
            f"Passed: {passed_tests}",
            f"Failed: {total_tests - passed_tests}",
            f"Success Rate: {(passed_tests/total_tests*100):.1f}%" if total_tests > 0 else "Success Rate: 0%",
            "",
            "Test Results by Category:",
        ])
        
        for category, result in self.test_results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            report_lines.append(f"  {category}: {status}")
        
        report_lines.extend([
            "",
            "="*80,
        ])
        
        return "\n".join(report_lines)
    
    def cleanup(self):
        """Cleanup test environment."""
        self.log("Cleaning up test environment...")
        
        # Clean up any test data or processes
        # In a real implementation, you might:
        # - Clear test database
        # - Stop test servers
        # - Clean temporary files
        
        self.log("✅ Cleanup completed")


def main():
    """Main entry point for E2E test runner."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Jarvis Live E2E Test Runner")
    parser.add_argument(
        "--category",
        choices=["all", "health", "api", "websocket", "mcp"],
        default="all",
        help="Test category to run"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=True,
        help="Enable verbose output"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=300,
        help="Overall test timeout in seconds"
    )
    
    args = parser.parse_args()
    
    # Create test runner
    runner = E2ETestRunner(verbose=args.verbose)
    runner.test_timeout = args.timeout
    
    try:
        # Check dependencies
        if not runner.check_dependencies():
            sys.exit(1)
        
        # Run tests based on category
        if args.category == "all":
            success = runner.run_all_tests()
        elif args.category == "health":
            success = runner.run_health_check()
        elif args.category == "api":
            success = runner.run_api_tests()
        elif args.category == "websocket":
            success = runner.run_websocket_tests()
        elif args.category == "mcp":
            success = runner.run_mcp_integration_tests()
        
        # Generate and display report
        report = runner.generate_report()
        print(report)
        
        # Exit with appropriate code
        sys.exit(0 if success else 1)
    
    except KeyboardInterrupt:
        runner.log("Test execution interrupted by user", "WARN")
        sys.exit(130)
    except Exception as e:
        runner.log(f"Test execution failed with exception: {e}", "ERROR")
        sys.exit(1)
    finally:
        runner.cleanup()


if __name__ == "__main__":
    main()