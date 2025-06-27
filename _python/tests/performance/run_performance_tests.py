#!/usr/bin/env python3
"""
Performance Test Runner for Jarvis Live Backend
Executes comprehensive load testing with statistical analysis and requirement validation
"""

import subprocess
import sys
import time
import json
import os
import argparse
from pathlib import Path


def run_backend_server():
    """Start the FastAPI backend server for testing"""
    print("🚀 Starting FastAPI backend server...")
    try:
        # Start the server in background
        server_process = subprocess.Popen(
            [
                sys.executable,
                "-m",
                "uvicorn",
                "src.main:app",
                "--host",
                "0.0.0.0",
                "--port",
                "8000",
                "--reload",
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        # Wait for server to start
        time.sleep(5)

        # Check if server is responding
        import requests

        try:
            response = requests.get("http://localhost:8000/health", timeout=5)
            if response.status_code == 200:
                print("✅ Backend server is running and healthy")
                return server_process
        except requests.exceptions.RequestException:
            pass

        print("❌ Backend server failed to start properly")
        server_process.terminate()
        return None

    except Exception as e:
        print(f"❌ Failed to start backend server: {e}")
        return None


def run_locust_test(
    users=50, spawn_rate=5, duration="2m", host="http://localhost:8000"
):
    """Execute Locust load test with specified parameters"""
    print(f"🔥 Starting Locust load test with {users} users...")
    print(f"   Spawn rate: {spawn_rate} users/second")
    print(f"   Duration: {duration}")
    print(f"   Target host: {host}")

    cmd = [
        "locust",
        "-f",
        "tests/performance/test_load_performance.py",
        "--host",
        host,
        "--users",
        str(users),
        "--spawn-rate",
        str(spawn_rate),
        "--run-time",
        duration,
        "--headless",
        "--print-stats",
        "--html",
        f"performance_report_{int(time.time())}.html",
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ Locust test completed successfully")
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ Locust test failed: {e}")
        print(f"STDOUT: {e.stdout}")
        print(f"STDERR: {e.stderr}")
        return None


def run_pytest_benchmarks():
    """Run pytest-benchmark for micro-benchmarking individual functions"""
    print("🔬 Running pytest micro-benchmarks...")

    cmd = [
        "python",
        "-m",
        "pytest",
        "tests/performance/",
        "--benchmark-only",
        "--benchmark-sort=mean",
        "--benchmark-columns=min,max,mean,stddev,median,ops,rounds",
        "--benchmark-json=benchmark_results.json",
    ]

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ Pytest benchmarks completed successfully")
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ Pytest benchmarks failed: {e}")
        print(f"STDOUT: {e.stdout}")
        print(f"STDERR: {e.stderr}")
        return None


def analyze_results():
    """Analyze performance test results and provide summary"""
    print("📊 Analyzing performance test results...")

    # Look for latest results files
    json_files = list(Path(".").glob("performance_results_*.json"))
    html_files = list(Path(".").glob("performance_report_*.html"))
    benchmark_file = Path("benchmark_results.json")

    if json_files:
        latest_json = max(json_files, key=os.path.getctime)
        print(f"📈 Latest performance results: {latest_json}")

        try:
            with open(latest_json, "r") as f:
                results = json.load(f)

            print("\n" + "=" * 60)
            print("PERFORMANCE SUMMARY")
            print("=" * 60)
            print(f"Total Requests: {results.get('total_requests', 'N/A')}")
            print(f"Success Rate: {results.get('success_rate', 'N/A'):.2f}%")
            print(
                f"Average Response Time: {results.get('average_response_time_ms', 'N/A'):.2f}ms"
            )
            print(
                f"Median Response Time: {results.get('median_response_time_ms', 'N/A'):.2f}ms"
            )
            print(
                f"95th Percentile: {results.get('p95_response_time_ms', 'N/A'):.2f}ms"
            )
            print(
                f"99th Percentile: {results.get('p99_response_time_ms', 'N/A'):.2f}ms"
            )

            # Validate requirements
            avg_time = results.get("average_response_time_ms", float("inf"))
            success_rate = results.get("success_rate", 0)

            print("\n" + "=" * 60)
            print("REQUIREMENT VALIDATION")
            print("=" * 60)

            if avg_time < 20:
                print(f"✅ Average response time: {avg_time:.2f}ms (PASS)")
            else:
                print(
                    f"❌ Average response time: {avg_time:.2f}ms (FAIL - exceeds 20ms)"
                )

            if success_rate >= 99:
                print(f"✅ Success rate: {success_rate:.2f}% (PASS)")
            else:
                print(f"❌ Success rate: {success_rate:.2f}% (FAIL - below 99%)")

        except Exception as e:
            print(f"❌ Failed to analyze results: {e}")

    if html_files:
        latest_html = max(html_files, key=os.path.getctime)
        print(f"📊 HTML Report: {latest_html}")

    if benchmark_file.exists():
        print(f"🔬 Benchmark Results: {benchmark_file}")


def main():
    parser = argparse.ArgumentParser(description="Run comprehensive performance tests")
    parser.add_argument(
        "--users", type=int, default=50, help="Number of concurrent users"
    )
    parser.add_argument(
        "--spawn-rate", type=int, default=5, help="Users spawn rate per second"
    )
    parser.add_argument(
        "--duration", default="2m", help="Test duration (e.g., 2m, 30s)"
    )
    parser.add_argument(
        "--skip-server", action="store_true", help="Skip starting backend server"
    )
    parser.add_argument(
        "--skip-benchmarks", action="store_true", help="Skip pytest benchmarks"
    )
    parser.add_argument(
        "--ci", action="store_true", help="CI mode - exit with error code on failure"
    )
    parser.add_argument(
        "--host", default="http://localhost:8000", help="Target host URL"
    )

    args = parser.parse_args()

    print("🏃‍♂️ Starting comprehensive performance test suite...")
    print("=" * 60)

    server_process = None

    try:
        # Start backend server if needed
        if not args.skip_server:
            server_process = run_backend_server()
            if not server_process:
                print("❌ Cannot proceed without backend server")
                return 1

        # Run Locust load tests
        locust_result = run_locust_test(
            users=args.users,
            spawn_rate=args.spawn_rate,
            duration=args.duration,
            host=args.host,
        )

        if not locust_result:
            print("❌ Load test failed")
            return 1

        # Run pytest benchmarks
        if not args.skip_benchmarks:
            benchmark_result = run_pytest_benchmarks()
            if not benchmark_result:
                print("⚠️ Benchmarks failed, but continuing...")

        # Analyze results
        analyze_results()

        # CI mode validation
        if args.ci:
            json_files = list(Path(".").glob("performance_results_*.json"))
            if json_files:
                latest_json = max(json_files, key=os.path.getctime)
                try:
                    with open(latest_json, "r") as f:
                        results = json.load(f)

                    avg_time = results.get("average_response_time_ms", float("inf"))
                    success_rate = results.get("success_rate", 0)

                    # Validate CI requirements (relaxed for CI environment)
                    if (
                        avg_time >= 100 or success_rate < 95
                    ):  # Relaxed thresholds for CI
                        print(
                            "❌ Performance requirements not met for CI - failing build"
                        )
                        return 1
                    else:
                        print(
                            "✅ Performance requirements met for CI - build can proceed"
                        )
                except Exception as e:
                    print(f"❌ Failed to validate CI requirements: {e}")
                    return 1

        print("\n🎉 Performance test suite completed!")
        return 0

    except KeyboardInterrupt:
        print("\n⏹️ Performance tests interrupted by user")
        return 1

    finally:
        # Clean up server process
        if server_process:
            print("🛑 Stopping backend server...")
            server_process.terminate()
            server_process.wait()


if __name__ == "__main__":
    sys.exit(main())
