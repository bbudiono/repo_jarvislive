#!/bin/bash

# Enterprise Build Validation Script - AUDIT Compliant
# Purpose: Comprehensive build quality validation with security integration
# Version: 2.0.0

set -euo pipefail

VALIDATION_RESULTS=()
SECURITY_ISSUES=()
PERFORMANCE_ISSUES=()
EXIT_CODE=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Advanced code complexity analysis
validate_code_complexity() {
    print_header "ADVANCED CODE COMPLEXITY ANALYSIS"
    
    # Swift code complexity with enhanced metrics
    if command -v lizard &> /dev/null; then
        echo "Analyzing Swift code complexity..."
        
        # Run lizard with strict thresholds for enterprise software
        lizard _iOS/JarvisLive*/Sources/ \
            --CCN 10 \
            --length 80 \
            --arguments 8 \
            --exclude "**/Tests/**" \
            --exclude "**/Mocks/**" \
            --xml > complexity_report.xml || {
            VALIDATION_RESULTS+=("❌ Swift code complexity exceeds enterprise standards")
            EXIT_CODE=1
        }
        
        # Extract complexity metrics
        COMPLEX_FUNCTIONS=$(grep -c 'ccn="[0-9][0-9]"' complexity_report.xml || echo "0")
        if [ "$COMPLEX_FUNCTIONS" -gt 5 ]; then
            VALIDATION_RESULTS+=("⚠️  $COMPLEX_FUNCTIONS functions exceed complexity threshold")
        fi
    else
        print_warning "lizard not installed, installing..."
        pip install lizard
        validate_code_complexity
        return
    fi
    
    # Python code complexity with maintainability index
    if [ -f "_python/requirements.txt" ]; then
        echo "Analyzing Python code complexity..."
        
        if ! command -v radon &> /dev/null; then
            pip install radon
        fi
        
        radon cc _python/src/ --min B --show-complexity || {
            VALIDATION_RESULTS+=("❌ Python code complexity validation failed")
            EXIT_CODE=1
        }
        
        # Maintainability index check
        radon mi _python/src/ --min B || {
            VALIDATION_RESULTS+=("⚠️  Python maintainability index below standards")
        }
        
        # Halstead complexity metrics
        radon hal _python/src/ || {
            print_warning "Halstead metrics calculation failed"
        }
    fi
    
    print_success "Code complexity analysis completed"
}

# Enhanced security validation with SAST integration
validate_security_standards() {
    print_header "ENTERPRISE SECURITY VALIDATION"
    
    # Secret scanning with multiple patterns
    echo "Performing comprehensive secret scanning..."
    
    SECRET_PATTERNS=(
        "api[_-]?key['\"][^'\"]*['\"]"
        "secret['\"][^'\"]*['\"]"
        "password['\"][^'\"]*['\"]"
        "token['\"][^'\"]*['\"]"
        "AKIA[0-9A-Z]{16}"  # AWS Access Key
        "sk_live_[0-9a-zA-Z]{24}"  # Stripe Live Key
        "pk_live_[0-9a-zA-Z]{24}"  # Stripe Public Key
    )
    
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -r -E "$pattern" _iOS/ _python/ --exclude-dir=Tests --exclude-dir=Mocks 2>/dev/null; then
            SECURITY_ISSUES+=("Potential secret pattern detected: $pattern")
            EXIT_CODE=1
        fi
    done
    
    # iOS security configuration validation
    echo "Validating iOS security configurations..."
    
    # Check for insecure network settings
    if grep -r "NSAllowsArbitraryLoads.*true" _iOS/ 2>/dev/null; then
        SECURITY_ISSUES+=("Insecure network configuration: Arbitrary loads enabled")
        EXIT_CODE=1
    fi
    
    # Check for debug logging in production code
    if grep -r "print(" _iOS/JarvisLive/Sources/ 2>/dev/null | grep -v "Tests"; then
        SECURITY_ISSUES+=("Debug print statements found in production code")
    fi
    
    # Python security validation
    if [ -f "_python/requirements.txt" ]; then
        echo "Checking Python dependencies for known vulnerabilities..."
        
        if command -v safety &> /dev/null; then
            safety check --json > security_report.json || {
                SECURITY_ISSUES+=("Python dependencies have known security vulnerabilities")
                EXIT_CODE=1
            }
        else
            print_warning "safety not installed, installing..."
            pip install safety
            validate_security_standards
            return
        fi
    fi
    
    # Certificate and keychain validation
    echo "Validating certificate configurations..."
    if [ -d "_iOS" ]; then
        # Check for proper certificate pinning implementation
        if ! grep -r "URLSessionDelegate" _iOS/JarvisLive*/Sources/ | grep -q "urlSession.*didReceive.*challenge"; then
            print_warning "Certificate pinning implementation not detected"
        fi
    fi
    
    print_success "Security validation completed"
}

# Enhanced performance validation with benchmarking
validate_performance_standards() {
    print_header "PERFORMANCE STANDARDS VALIDATION"
    
    # iOS build performance analysis
    if [ -d "_iOS/JarvisLive-Sandbox" ]; then
        echo "Analyzing iOS build performance..."
        
        # Measure build time
        BUILD_START=$(date +%s)
        xcodebuild build \
            -project _iOS/JarvisLive-Sandbox/JarvisLive-Sandbox.xcodeproj \
            -scheme JarvisLive-Sandbox \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
            -quiet > build_output.log 2>&1 || {
            PERFORMANCE_ISSUES+=("iOS build failed - check build_output.log")
            EXIT_CODE=1
        }
        BUILD_END=$(date +%s)
        BUILD_TIME=$((BUILD_END - BUILD_START))
        
        echo "Build time: ${BUILD_TIME}s"
        
        # Build time threshold (5 minutes for enterprise projects)
        if [ "$BUILD_TIME" -gt 300 ]; then
            PERFORMANCE_ISSUES+=("Build time exceeds 5 minutes: ${BUILD_TIME}s")
        fi
        
        # Build size analysis
        BUILD_SIZE=$(du -sh _iOS/JarvisLive-Sandbox | cut -f1)
        echo "Build size: $BUILD_SIZE"
        
        SIZE_BYTES=$(du -s _iOS/JarvisLive-Sandbox | cut -f1)
        if [ "$SIZE_BYTES" -gt 102400 ]; then  # 100MB in KB
            PERFORMANCE_ISSUES+=("Build size exceeds enterprise standards: $BUILD_SIZE")
        fi
        
        # Memory usage validation
        if command -v instruments &> /dev/null; then
            echo "Running memory analysis (if available)..."
            # This would require actual device/simulator for full analysis
        fi
    fi
    
    # Python performance benchmarks
    if [ -f "_python/tests/performance/test_benchmark_micro.py" ]; then
        echo "Running Python performance benchmarks..."
        
        cd _python
        if [ -f "requirements-dev.txt" ]; then
            pip install -r requirements-dev.txt
        fi
        
        python -m pytest tests/performance/ \
            --benchmark-only \
            --benchmark-json=../performance_results.json \
            --quiet || {
            PERFORMANCE_ISSUES+=("Python performance benchmarks failed")
        }
        cd ..
        
        # Analyze benchmark results
        if [ -f "performance_results.json" ]; then
            python3 << 'PYTHON'
import json
import sys

try:
    with open('performance_results.json', 'r') as f:
        results = json.load(f)
    
    # Check for performance regressions
    for benchmark in results.get('benchmarks', []):
        mean_time = benchmark['stats']['mean']
        if mean_time > 1.0:  # 1 second threshold
            print(f"⚠️  Slow benchmark detected: {benchmark['name']} - {mean_time:.3f}s")
except Exception as e:
    print(f"Error analyzing performance results: {e}")
PYTHON
        fi
    fi
    
    print_success "Performance validation completed"
}

# Comprehensive documentation and accessibility validation
validate_documentation_and_accessibility() {
    print_header "DOCUMENTATION & ACCESSIBILITY VALIDATION"
    
    # Swift documentation coverage
    echo "Analyzing Swift documentation coverage..."
    SWIFT_FILES_COUNT=$(find _iOS/JarvisLive*/Sources/ -name "*.swift" -not -path "*/Tests/*" | wc -l)
    DOCUMENTED_SWIFT_FILES=$(find _iOS/JarvisLive*/Sources/ -name "*.swift" -not -path "*/Tests/*" -exec grep -l "///" {} \; | wc -l)
    
    if [ "$SWIFT_FILES_COUNT" -gt 0 ]; then
        DOC_COVERAGE=$((DOCUMENTED_SWIFT_FILES * 100 / SWIFT_FILES_COUNT))
        echo "Swift documentation coverage: ${DOC_COVERAGE}%"
        
        if [ "$DOC_COVERAGE" -lt 80 ]; then
            VALIDATION_RESULTS+=("❌ Documentation coverage below enterprise standard (80%): ${DOC_COVERAGE}%")
            EXIT_CODE=1
        fi
    fi
    
    # Python documentation coverage
    if [ -d "_python/src" ]; then
        echo "Analyzing Python documentation coverage..."
        PYTHON_FILES_COUNT=$(find _python/src/ -name "*.py" | wc -l)
        DOCUMENTED_PYTHON_FILES=$(find _python/src/ -name "*.py" -exec grep -l '"""' {} \; | wc -l)
        
        if [ "$PYTHON_FILES_COUNT" -gt 0 ]; then
            PYTHON_DOC_COVERAGE=$((DOCUMENTED_PYTHON_FILES * 100 / PYTHON_FILES_COUNT))
            echo "Python documentation coverage: ${PYTHON_DOC_COVERAGE}%"
            
            if [ "$PYTHON_DOC_COVERAGE" -lt 75 ]; then
                VALIDATION_RESULTS+=("⚠️  Python documentation coverage below standard: ${PYTHON_DOC_COVERAGE}%")
            fi
        fi
    fi
    
    # Accessibility validation for iOS
    echo "Validating iOS accessibility implementation..."
    if [ -d "_iOS/JarvisLive*/Sources/" ]; then
        # Check for accessibility identifiers
        ACCESSIBILITY_COUNT=$(grep -r "accessibilityIdentifier" _iOS/JarvisLive*/Sources/ | wc -l)
        echo "Accessibility identifiers found: $ACCESSIBILITY_COUNT"
        
        # Check for VoiceOver support
        VOICEOVER_COUNT=$(grep -r "accessibilityLabel" _iOS/JarvisLive*/Sources/ | wc -l)
        echo "VoiceOver labels found: $VOICEOVER_COUNT"
        
        if [ "$ACCESSIBILITY_COUNT" -lt 10 ]; then
            VALIDATION_RESULTS+=("⚠️  Limited accessibility implementation detected")
        fi
    fi
    
    print_success "Documentation and accessibility validation completed"
}

# Test coverage and quality validation
validate_test_coverage() {
    print_header "TEST COVERAGE & QUALITY VALIDATION"
    
    # iOS test coverage (if available)
    if [ -d "_iOS/JarvisLive*/Tests/" ]; then
        echo "Analyzing iOS test coverage..."
        TEST_FILES_COUNT=$(find _iOS/JarvisLive*/Tests/ -name "*Tests.swift" | wc -l)
        SOURCE_FILES_COUNT=$(find _iOS/JarvisLive*/Sources/ -name "*.swift" -not -path "*/Tests/*" | wc -l)
        
        echo "Test files: $TEST_FILES_COUNT"
        echo "Source files: $SOURCE_FILES_COUNT"
        
        if [ "$SOURCE_FILES_COUNT" -gt 0 ]; then
            TEST_RATIO=$((TEST_FILES_COUNT * 100 / SOURCE_FILES_COUNT))
            echo "Test file ratio: ${TEST_RATIO}%"
        fi
    fi
    
    # Python test coverage
    if [ -f "_python/tests/test_api_endpoints.py" ]; then
        echo "Running Python test coverage analysis..."
        
        cd _python
        if command -v pytest-cov &> /dev/null || pip list | grep -q pytest-cov; then
            python -m pytest --cov=src --cov-report=json --cov-report=term || {
                VALIDATION_RESULTS+=("❌ Python test execution failed")
                EXIT_CODE=1
            }
            
            # Analyze coverage results
            if [ -f "coverage.json" ]; then
                python3 << 'PYTHON'
import json
try:
    with open('coverage.json', 'r') as f:
        coverage = json.load(f)
    
    total_coverage = coverage['totals']['percent_covered']
    print(f"Python test coverage: {total_coverage:.1f}%")
    
    if total_coverage < 80:
        print(f"❌ Test coverage below enterprise standard (80%): {total_coverage:.1f}%")
        exit(1)
except Exception as e:
    print(f"Error analyzing coverage: {e}")
PYTHON
            fi
        else
            print_warning "pytest-cov not installed, installing..."
            pip install pytest-cov
        fi
        cd ..
    fi
    
    print_success "Test coverage validation completed"
}

# Generate comprehensive validation report
generate_validation_report() {
    echo
    print_header "ENTERPRISE BUILD VALIDATION REPORT"
    echo "Generated: $(date)"
    echo "Validation Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    
    # Security issues summary
    if [ ${#SECURITY_ISSUES[@]} -gt 0 ]; then
        print_error "SECURITY ISSUES DETECTED:"
        for issue in "${SECURITY_ISSUES[@]}"; do
            echo "  - $issue"
        done
        echo
    fi
    
    # Performance issues summary
    if [ ${#PERFORMANCE_ISSUES[@]} -gt 0 ]; then
        print_warning "PERFORMANCE CONCERNS:"
        for issue in "${PERFORMANCE_ISSUES[@]}"; do
            echo "  - $issue"
        done
        echo
    fi
    
    # General validation results
    if [ ${#VALIDATION_RESULTS[@]} -gt 0 ]; then
        echo "VALIDATION RESULTS:"
        for result in "${VALIDATION_RESULTS[@]}"; do
            echo "  - $result"
        done
        echo
    fi
    
    # Final assessment
    if [ ${#SECURITY_ISSUES[@]} -eq 0 ] && [ ${#PERFORMANCE_ISSUES[@]} -eq 0 ] && [ ${#VALIDATION_RESULTS[@]} -eq 0 ]; then
        print_success "ALL ENTERPRISE QUALITY GATES PASSED ✅"
        echo "Build meets all enterprise standards for:"
        echo "  - Code complexity and maintainability"
        echo "  - Security standards and vulnerability scanning"
        echo "  - Performance benchmarks and optimization"
        echo "  - Documentation coverage and accessibility"
        echo "  - Test coverage and quality assurance"
    else
        print_error "ENTERPRISE QUALITY GATES FAILED ❌"
        echo "Issues must be resolved before production deployment"
    fi
    
    echo
    echo "=== ENTERPRISE STANDARDS SUMMARY ==="
    echo "- Code Complexity: CCN ≤ 10, Function Length ≤ 80 lines"
    echo "- Security: Zero known vulnerabilities, no hardcoded secrets"
    echo "- Performance: Build time ≤ 5 minutes, size ≤ 100MB"
    echo "- Documentation: ≥ 80% Swift, ≥ 75% Python coverage"
    echo "- Test Coverage: ≥ 80% overall coverage"
    echo "- Accessibility: Comprehensive VoiceOver and identifier support"
    
    # Create JSON report for CI integration
    cat > validation_report.json << JSON
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "overall_status": $([ $EXIT_CODE -eq 0 ] && echo "\"PASSED\"" || echo "\"FAILED\""),
    "security_issues": ${#SECURITY_ISSUES[@]},
    "performance_issues": ${#PERFORMANCE_ISSUES[@]},
    "validation_failures": ${#VALIDATION_RESULTS[@]},
    "exit_code": $EXIT_CODE
}
JSON
    
    echo
    echo "Enterprise validation completed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
}

# Main execution
main() {
    print_header "ENTERPRISE BUILD VALIDATION - AUDIT COMPLIANT"
    echo "Version: 2.0.0"
    echo "Started: $(date)"
    echo
    
    validate_code_complexity
    validate_security_standards
    validate_performance_standards
    validate_documentation_and_accessibility
    validate_test_coverage
    
    generate_validation_report
}

main "$@"
