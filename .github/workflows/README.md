# CI/CD Pipeline Documentation

## Overview

This directory contains the GitHub Actions workflows for the Jarvis Live project. The CI/CD pipeline ensures code quality, runs tests, and validates builds before allowing merges to the main branch.

## Workflow Files

### `ci.yml` - Main CI/CD Pipeline

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop` branches

**Jobs:**

#### 1. Python Backend Quality Gate
- **Platform:** Ubuntu Latest
- **Python Version:** 3.10
- **Steps:**
  - Install dependencies from `requirements.txt` and `requirements-dev.txt`
  - Run Black formatter check
  - Run isort import sorting check
  - Run Flake8 linting
  - Run MyPy type checking
  - Run unit tests with pytest
  - Upload test results as artifacts

#### 2. iOS Quality Gate
- **Platform:** macOS Latest
- **Xcode Version:** 15.0
- **Steps:**
  - Install SwiftLint
  - Run SwiftLint on both Sandbox and Production projects
  - Build projects using Swift Package Manager
  - Run Xcode unit tests
  - Upload test results as artifacts

#### 3. Integration Tests
- **Platform:** Ubuntu Latest
- **Dependencies:** Redis service
- **Steps:**
  - Start Python backend server
  - Run integration tests
  - Validate API endpoints health

#### 4. Security Scanning
- **Platform:** Ubuntu Latest
- **Steps:**
  - Run Bandit security scan on Python code
  - Upload security scan results

#### 5. Quality Gate Summary
- **Dependencies:** All previous jobs
- **Steps:**
  - Aggregate results from all quality gates
  - Post PR comments with results summary
  - Fail the build if any critical checks fail

## Quality Standards

### Python Code Quality
- **Formatter:** Black (line length: 88 characters)
- **Import Sorting:** isort
- **Linting:** Flake8 with complexity limits
- **Type Checking:** MyPy with strict mode
- **Test Coverage:** Tracked but not enforced in CI (for performance)

### iOS Code Quality
- **Linter:** SwiftLint with custom configuration
- **Build Validation:** Both Sandbox and Production must compile
- **Testing:** XCTest unit and integration tests
- **Performance:** Build time optimization

### Security Requirements
- **Python:** Bandit security scanning
- **Secrets:** No hardcoded credentials allowed
- **Dependencies:** Regular security updates

## Test Organization

### Python Tests
- **Location:** `_python/tests/`
- **Types:**
  - Unit tests: `test_*.py`
  - Integration tests: `test_api_*.py`
  - Performance tests: `tests/performance/`
- **Runner:** `run_minimal_ci_tests.py` for CI compatibility

### iOS Tests
- **Location:** `_iOS/JarvisLive-Sandbox/Tests/`
- **Types:**
  - Unit tests: Business logic validation
  - UI tests: User interface automation
  - Integration tests: Cross-component validation
- **Simulator:** iPhone 15 Pro (latest iOS)

## Performance Testing

### Load Testing
- **Tool:** Locust
- **Configuration:** 50 concurrent users, 2-minute duration
- **Metrics:** Response time, throughput, error rate
- **Runner:** `tests/performance/run_performance_tests.py`

### Benchmarking
- **Tool:** pytest-benchmark
- **Focus:** Individual function performance
- **Reporting:** JSON results with statistical analysis

## Artifact Management

### Test Results
- **Python:** Test reports and coverage data
- **iOS:** Xcode test result bundles
- **Security:** Bandit scan reports
- **Performance:** Load test HTML reports

### Retention
- **Duration:** 30 days for test artifacts
- **Access:** Available for download from GitHub Actions UI

## Failure Handling

### Build Failures
1. **Immediate notification** via GitHub status checks
2. **Detailed logs** available in Actions tab
3. **Artifact collection** for debugging
4. **PR blocking** until issues resolved

### Quality Gate Failures
- **Formatting:** Black/SwiftLint violations block merge
- **Testing:** Test failures prevent deployment
- **Security:** Security vulnerabilities require review
- **Performance:** Significant regressions trigger alerts

## Local Testing

### Quick Validation
```bash
# Python
cd _python && python run_minimal_ci_tests.py

# Full CI pipeline validation
./scripts/validate_ci_setup.sh
```

### Performance Testing
```bash
cd _python && python tests/performance/run_performance_tests.py --ci
```

## Configuration Files

### Python
- `pyproject.toml`: Tool configurations
- `requirements-dev.txt`: Development dependencies
- `.flake8`: Linting rules (if needed)

### iOS
- `.swiftlint.yml`: SwiftLint configuration
- `Package.swift`: Swift Package Manager setup

## Environment Variables

### Required in CI
- **GITHUB_TOKEN**: Automatically provided by GitHub Actions
- **Secrets**: Stored in GitHub repository settings

### Optional
- **PERFORMANCE_THRESHOLD**: Custom performance limits
- **NOTIFICATION_WEBHOOK**: Slack/Teams integration

## Monitoring and Alerts

### Success Metrics
- **Build Duration:** Target < 10 minutes
- **Success Rate:** Target > 95%
- **Test Coverage:** Tracked and reported

### Failure Alerts
- **Slack Integration:** Configurable webhook
- **Email Notifications:** GitHub native
- **Dashboard:** GitHub Actions insights

## Maintenance

### Regular Tasks
- **Dependencies:** Weekly security updates
- **Performance:** Monthly baseline reviews
- **Configuration:** Quarterly optimization

### Troubleshooting
1. Check GitHub Actions logs
2. Review artifact contents
3. Run local validation scripts
4. Escalate to development team if needed

---

**Last Updated:** 2025-06-26  
**Maintained By:** Development Team  
**Documentation Version:** 1.0.0