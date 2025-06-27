#!/bin/bash

# Release Preparation Script
# AUDIT-2024JUL28-RELEASE_CANDIDATE_VALIDATION Task 6.2
# 
# Purpose: Automate version management and release preparation across the entire project
# Usage: ./scripts/prepare_release.sh <version> [--changelog-entry "description"]
# 
# This script:
# 1. Updates version numbers in iOS project files
# 2. Updates version in Python pyproject.toml
# 3. Creates/updates CHANGELOG.md entry
# 4. Validates all changes
#
# Exit Codes:
#   0: Success
#   1: General error
#   2: Invalid version format
#   3: File update failed
#   4: Validation failed

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IOS_PROJECT_FILE="$PROJECT_ROOT/_iOS/JarvisLive/JarvisLive.xcodeproj/project.pbxproj"
IOS_SANDBOX_PROJECT_FILE="$PROJECT_ROOT/_iOS/JarvisLive-Sandbox/JarvisLive.xcodeproj/project.pbxproj"
PYTHON_PROJECT_FILE="$PROJECT_ROOT/_python/pyproject.toml"
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Command line options
VERSION=""
CHANGELOG_ENTRY=""

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Show help
show_help() {
    cat << EOF
Release Preparation Script - Jarvis Live

USAGE:
    $0 <version> [OPTIONS]

ARGUMENTS:
    version                 Version number in semantic format (e.g., 1.0.1, 2.1.0)

OPTIONS:
    --changelog-entry TEXT  Custom changelog entry description
    -h, --help             Show this help message

EXAMPLES:
    $0 1.0.1
    $0 1.1.0 --changelog-entry "Added new voice synthesis features"
    $0 2.0.0 --changelog-entry "Major release with breaking changes"

DESCRIPTION:
    This script automates the release preparation process by:
    
    1. Validating the version number format
    2. Updating iOS project version and build numbers
    3. Updating Python project version in pyproject.toml
    4. Creating a new CHANGELOG.md entry
    5. Validating all changes

REQUIREMENTS:
    - Clean git working directory
    - Valid semantic version number
    - Write access to project files

EOF
}

# Parse command line arguments
parse_args() {
    if [[ $# -eq 0 ]]; then
        log_error "Version number is required"
        show_help
        exit 1
    fi
    
    VERSION="$1"
    shift
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --changelog-entry)
                CHANGELOG_ENTRY="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Validate version format
validate_version() {
    local version="$1"
    
    # Check semantic version format (major.minor.patch)
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid version format: $version"
        log_error "Version must be in semantic format (e.g., 1.0.1, 2.1.0)"
        exit 2
    fi
    
    log_success "Version format validated: $version"
}

# Pre-flight checks
preflight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check git status
    if ! git diff --quiet; then
        log_error "Git working directory is not clean. Commit or stash changes first."
        git status --porcelain
        exit 2
    fi
    
    # Check required files exist
    local required_files=("$IOS_PROJECT_FILE" "$PYTHON_PROJECT_FILE" "$CHANGELOG_FILE")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file not found: $file"
            exit 2
        fi
    done
    
    log_success "Pre-flight checks passed"
}

# Update iOS project version
update_ios_version() {
    local version="$1"
    local build_number=$(date '+%Y%m%d%H%M')
    
    log_info "Updating iOS project version to $version (build $build_number)..."
    
    # Update production project
    if [[ -f "$IOS_PROJECT_FILE" ]]; then
        # Update MARKETING_VERSION (version)
        sed -i.bak "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $version/g" "$IOS_PROJECT_FILE"
        
        # Update CURRENT_PROJECT_VERSION (build number)
        sed -i.bak "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $build_number/g" "$IOS_PROJECT_FILE"
        
        # Remove backup file
        rm -f "$IOS_PROJECT_FILE.bak"
        
        log_success "Updated iOS production project: $version ($build_number)"
    else
        log_warning "iOS production project file not found: $IOS_PROJECT_FILE"
    fi
    
    # Update sandbox project (if it exists)
    if [[ -f "$IOS_SANDBOX_PROJECT_FILE" ]]; then
        # Update MARKETING_VERSION (version)
        sed -i.bak "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = $version/g" "$IOS_SANDBOX_PROJECT_FILE"
        
        # Update CURRENT_PROJECT_VERSION (build number)
        sed -i.bak "s/CURRENT_PROJECT_VERSION = [^;]*/CURRENT_PROJECT_VERSION = $build_number/g" "$IOS_SANDBOX_PROJECT_FILE"
        
        # Remove backup file
        rm -f "$IOS_SANDBOX_PROJECT_FILE.bak"
        
        log_success "Updated iOS sandbox project: $version ($build_number)"
    else
        log_info "iOS sandbox project file not found (optional): $IOS_SANDBOX_PROJECT_FILE"
    fi
}

# Update Python project version
update_python_version() {
    local version="$1"
    
    log_info "Updating Python project version to $version..."
    
    if [[ -f "$PYTHON_PROJECT_FILE" ]]; then
        # Update version in pyproject.toml
        sed -i.bak "s/^version = .*/version = \"$version\"/" "$PYTHON_PROJECT_FILE"
        
        # Remove backup file
        rm -f "$PYTHON_PROJECT_FILE.bak"
        
        log_success "Updated Python project version: $version"
    else
        log_error "Python project file not found: $PYTHON_PROJECT_FILE"
        exit 3
    fi
}

# Update changelog
update_changelog() {
    local version="$1"
    local entry="$2"
    local date=$(date '+%Y-%m-%d')
    
    log_info "Updating CHANGELOG.md for version $version..."
    
    # Create temporary changelog entry
    local temp_entry=$(mktemp)
    
    # If custom entry provided, use it; otherwise create a template
    if [[ -n "$entry" ]]; then
        cat > "$temp_entry" << EOF

## [$version] - $date

### Changed
- $entry

EOF
    else
        cat > "$temp_entry" << EOF

## [$version] - $date

### Added
- New features and enhancements

### Changed
- Updates and improvements

### Fixed
- Bug fixes and stability improvements

EOF
    fi
    
    # Insert the new entry after the [Unreleased] section
    if grep -q "## \[Unreleased\]" "$CHANGELOG_FILE"; then
        # Find line number of [Unreleased] section
        local unreleased_line=$(grep -n "## \[Unreleased\]" "$CHANGELOG_FILE" | cut -d: -f1)
        local next_section_line=$(tail -n +$((unreleased_line + 1)) "$CHANGELOG_FILE" | grep -n "^## " | head -1 | cut -d: -f1)
        
        if [[ -n "$next_section_line" ]]; then
            # Insert before next section
            local insert_line=$((unreleased_line + next_section_line))
            head -n $((insert_line - 1)) "$CHANGELOG_FILE" > "$CHANGELOG_FILE.tmp"
            cat "$temp_entry" >> "$CHANGELOG_FILE.tmp"
            tail -n +$insert_line "$CHANGELOG_FILE" >> "$CHANGELOG_FILE.tmp"
        else
            # Insert at end of file
            head -n "$unreleased_line" "$CHANGELOG_FILE" > "$CHANGELOG_FILE.tmp"
            cat "$temp_entry" >> "$CHANGELOG_FILE.tmp"
            tail -n +$((unreleased_line + 1)) "$CHANGELOG_FILE" >> "$CHANGELOG_FILE.tmp"
        fi
        
        mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
    else
        # No [Unreleased] section, add entry at the top
        cat "$temp_entry" "$CHANGELOG_FILE" > "$CHANGELOG_FILE.tmp"
        mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
    fi
    
    # Clean up
    rm -f "$temp_entry"
    
    log_success "Updated CHANGELOG.md with version $version"
}

# Validate changes
validate_changes() {
    local version="$1"
    
    log_info "Validating version changes..."
    
    local validation_errors=0
    
    # Validate iOS project version
    if [[ -f "$IOS_PROJECT_FILE" ]]; then
        if grep -q "MARKETING_VERSION = $version" "$IOS_PROJECT_FILE"; then
            log_success "iOS production version updated correctly"
        else
            log_error "iOS production version not updated correctly"
            validation_errors=$((validation_errors + 1))
        fi
    fi
    
    # Validate Python project version
    if grep -q "version = \"$version\"" "$PYTHON_PROJECT_FILE"; then
        log_success "Python version updated correctly"
    else
        log_error "Python version not updated correctly"
        validation_errors=$((validation_errors + 1))
    fi
    
    # Validate changelog entry
    if grep -q "## \[$version\]" "$CHANGELOG_FILE"; then
        log_success "Changelog entry created correctly"
    else
        log_error "Changelog entry not created correctly"
        validation_errors=$((validation_errors + 1))
    fi
    
    if [[ $validation_errors -gt 0 ]]; then
        log_error "Validation failed with $validation_errors errors"
        exit 4
    fi
    
    log_success "All validations passed"
}

# Generate release summary
generate_release_summary() {
    local version="$1"
    
    cat << EOF

🚀 RELEASE PREPARATION COMPLETE: v$version

✅ iOS project version updated
✅ Python project version updated  
✅ CHANGELOG.md entry created
✅ All validations passed

NEXT STEPS:
1. Review the changes:
   git diff

2. Commit the changes:
   git add .
   git commit -m "chore: prepare release v$version"

3. Create and push release tag:
   git tag -a v$version -m "Release v$version"
   git push origin v$version

4. Merge to main branch to trigger production validation:
   git checkout main
   git merge feature/audit-release-engineering-20240728
   git push origin main

The production validation pipeline will automatically verify the release candidate.

EOF
}

# Main execution function
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    log_info "=== RELEASE PREPARATION SCRIPT STARTED ==="
    log_info "Start time: $start_time"
    log_info "Version: $VERSION"
    
    # Execute the release preparation process
    validate_version "$VERSION"
    preflight_checks
    update_ios_version "$VERSION"
    update_python_version "$VERSION"
    update_changelog "$VERSION" "$CHANGELOG_ENTRY"
    validate_changes "$VERSION"
    
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "End time: $end_time"
    log_success "=== RELEASE PREPARATION COMPLETED SUCCESSFULLY ==="
    
    generate_release_summary "$VERSION"
}

# Parse arguments and run main function
parse_args "$@"
main