#!/bin/bash

# Advanced Build Validation Script
# Purpose: Comprehensive build quality validation
# Version: 1.0.0

set -euo pipefail

VALIDATION_RESULTS=()
EXIT_CODE=0

# Quality gate functions
validate_code_complexity() {
    echo "Validating code complexity..."
    
    # Swift code complexity check
    if command -v lizard &> /dev/null; then
        lizard _iOS/JarvisLive*/Sources/ --CCN 15 --length 100 --arguments 10 || {
            VALIDATION_RESULTS+=("❌ Code complexity validation failed")
            EXIT_CODE=1
        }
    else
        echo "Warning: lizard not installed, skipping complexity check"
    fi
    
    # Python code complexity check
    if [ -f "_python/requirements-dev.txt" ]; then
        pip install radon
        radon cc _python/src/ --min B || {
            VALIDATION_RESULTS+=("❌ Python code complexity validation failed")
            EXIT_CODE=1
        }
    fi
}

validate_security_standards() {
    echo "Validating security standards..."
    
    # Check for hardcoded secrets
    if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        if git log --all --full-history -- '*.swift' '*.py' | grep -i -E "(password|secret|key|token)" | grep -v -E "(KeychainManager|SecureStorage)"; then
            VALIDATION_RESULTS+=("❌ Potential hardcoded secrets detected")
            EXIT_CODE=1
        fi
    fi
    
    # Validate iOS security practices
    if grep -r "NSAllowsArbitraryLoads" _iOS/ 2>/dev/null; then
        VALIDATION_RESULTS+=("❌ Insecure network configuration detected")
        EXIT_CODE=1
    fi
}

validate_performance_standards() {
    echo "Validating performance standards..."
    
    # iOS build size check
    if [ -d "_iOS/JarvisLive-Sandbox" ]; then
        SANDBOX_SIZE=$(du -sh _iOS/JarvisLive-Sandbox | cut -f1)
        echo "Sandbox build size: $SANDBOX_SIZE"
        
        # Check if size is reasonable (under 100MB for source)
        SIZE_BYTES=$(du -s _iOS/JarvisLive-Sandbox | cut -f1)
        if [ "$SIZE_BYTES" -gt 102400 ]; then  # 100MB in KB
            VALIDATION_RESULTS+=("⚠️  Large build size detected: $SANDBOX_SIZE")
        fi
    fi
    
    # Python startup time check
    if [ -f "_python/src/main.py" ]; then
        STARTUP_TIME=$(cd _python && time python -c "import src.main" 2>&1 | grep real | cut -d'm' -f2 | cut -d's' -f1)
        echo "Python startup time: ${STARTUP_TIME}s"
    fi
}

validate_documentation_coverage() {
    echo "Validating documentation coverage..."
    
    # Check for missing documentation
    SWIFT_FILES_COUNT=$(find _iOS/JarvisLive*/Sources/ -name "*.swift" | wc -l)
    DOCUMENTED_SWIFT_FILES=$(find _iOS/JarvisLive*/Sources/ -name "*.swift" -exec grep -l "///" {} \; | wc -l)
    
    if [ "$SWIFT_FILES_COUNT" -gt 0 ]; then
        DOC_COVERAGE=$((DOCUMENTED_SWIFT_FILES * 100 / SWIFT_FILES_COUNT))
        echo "Swift documentation coverage: ${DOC_COVERAGE}%"
        
        if [ "$DOC_COVERAGE" -lt 70 ]; then
            VALIDATION_RESULTS+=("❌ Documentation coverage below 70%: ${DOC_COVERAGE}%")
            EXIT_CODE=1
        fi
    fi
}

# Run all validations
main() {
    echo "=== ADVANCED BUILD VALIDATION ==="
    echo "Timestamp: $(date)"
    echo
    
    validate_code_complexity
    validate_security_standards
    validate_performance_standards
    validate_documentation_coverage
    
    echo
    echo "=== VALIDATION RESULTS ==="
    
    if [ ${#VALIDATION_RESULTS[@]} -eq 0 ]; then
        echo "✅ All quality gates passed"
    else
        echo "Quality gate failures:"
        for result in "${VALIDATION_RESULTS[@]}"; do
            echo "$result"
        done
    fi
    
    echo
    echo "Build validation completed with exit code: $EXIT_CODE"
    exit $EXIT_CODE
}

main "$@"
