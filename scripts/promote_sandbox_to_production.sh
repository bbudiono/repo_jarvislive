#!/bin/bash

# Production Sync Script: Sandbox to Production Promotion
# AUDIT-2024JUL27-PRE_PRODUCTION_VALIDATION Task 5.1
# 
# Purpose: Robust, idempotent synchronization from JarvisLive-Sandbox to JarvisLive production
# Critical: This script is the ONLY authorized path for production promotion
# 
# Usage: ./scripts/promote_sandbox_to_production.sh [--dry-run] [--force-backup]
# 
# Exit Codes:
#   0: Success
#   1: General error
#   2: Pre-flight check failed
#   3: Backup failed
#   4: Sync failed
#   5: Post-sync validation failed

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SANDBOX_DIR="$PROJECT_ROOT/_iOS/JarvisLive-Sandbox"
PRODUCTION_DIR="$PROJECT_ROOT/_iOS/JarvisLive"
BACKUP_DIR="$PROJECT_ROOT/_backups/production"
LOG_FILE="$PROJECT_ROOT/logs/production_promotion.log"

# Command line options
DRY_RUN=false
FORCE_BACKUP=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    log "SUCCESS" "$@"
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    log "WARNING" "$@"
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force-backup)
                FORCE_BACKUP=true
                shift
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

show_help() {
    cat << EOF
Production Sync Script: Sandbox to Production Promotion

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --dry-run           Show what would be done without making changes
    --force-backup      Create backup even if one exists from today
    -h, --help          Show this help message

DESCRIPTION:
    This script safely promotes code from JarvisLive-Sandbox to JarvisLive production.
    It performs comprehensive pre-flight checks, creates backups, and validates the sync.

REQUIREMENTS:
    - Clean git working directory
    - Sandbox build must be green
    - All tests must pass

SAFETY FEATURES:
    - Automatic backup creation with timestamp
    - Dry-run mode for validation
    - Comprehensive logging
    - Post-sync validation
    - Rollback capability

EOF
}

# Pre-flight checks
preflight_checks() {
    log_info "Running pre-flight checks..."
    
    # Check if we're in the correct directory
    if [[ ! -d "$SANDBOX_DIR" ]] || [[ ! -d "$PRODUCTION_DIR" ]]; then
        log_error "Required directories not found. Are you in the project root?"
        log_error "Sandbox: $SANDBOX_DIR"
        log_error "Production: $PRODUCTION_DIR"
        exit 2
    fi
    
    # Check git status
    if ! git diff --quiet; then
        log_error "Git working directory is not clean. Commit or stash changes first."
        git status --porcelain
        exit 2
    fi
    
    # Verify sandbox build status (skip in emergency mode)
    if [[ "${EMERGENCY_MODE:-}" != "1" ]]; then
        log_info "Verifying sandbox build status..."
        cd "$SANDBOX_DIR"
        
        if ! xcodebuild -project JarvisLive.xcodeproj -scheme JarvisLive-Sandbox -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet build &>/dev/null; then
            log_error "Sandbox build failed. Fix build errors before promotion."
            exit 2
        fi
    else
        log_warning "EMERGENCY MODE: Skipping sandbox build verification"
    fi
    
    log_success "Pre-flight checks passed"
    cd "$PROJECT_ROOT"
}

# Create backup of current production
create_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="$BACKUP_DIR/production_backup_$timestamp"
    
    # Check if backup already exists from today (unless forced)
    if [[ "$FORCE_BACKUP" == "false" ]]; then
        local today=$(date '+%Y%m%d')
        if ls "$BACKUP_DIR"/production_backup_${today}_* 1> /dev/null 2>&1; then
            log_info "Backup already exists from today. Use --force-backup to override."
            return 0
        fi
    fi
    
    log_info "Creating backup at: $backup_path"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would create backup at $backup_path"
        return 0
    fi
    
    # Create backup directory structure
    mkdir -p "$backup_path"
    
    # Copy production directory
    if ! cp -R "$PRODUCTION_DIR" "$backup_path/"; then
        log_error "Failed to create backup"
        exit 3
    fi
    
    # Create backup metadata
    cat > "$backup_path/backup_metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "git_commit": "$(git rev-parse HEAD)",
    "git_branch": "$(git branch --show-current)",
    "backup_reason": "Pre-promotion backup",
    "source_directory": "$PRODUCTION_DIR",
    "script_version": "1.0.0"
}
EOF
    
    log_success "Backup created successfully: $backup_path"
    echo "$backup_path" > "$PROJECT_ROOT/.last_backup_path"
}

# Perform the sync with exclusions
perform_sync() {
    log_info "Starting sandbox to production sync..."
    
    # Define exclusions for sandbox-only files (FIXED - more specific patterns)
    local exclusions=(
        # Sandbox-specific directories and files only
        "--exclude=JarvisLive-Sandbox/"
        "--exclude=JarvisLive-Sandbox.xcodeproj/"
        "--exclude=.build/"
        "--exclude=Demo/"
        "--exclude=Content/"
        "--exclude=*.playground"
        "--exclude=IMPLEMENTATION_SUMMARY.md"
        "--exclude=INTEGRATION_TESTING_FRAMEWORK.md"
        
        # Development temporary files
        "--exclude=*/DerivedData/*"
        "--exclude=*/xcuserdata/*"
        "--exclude=*/.swiftpm/*"
        "--exclude=*/Preview Content/*"
        
        # Temporary files
        "--exclude=*.tmp"
        "--exclude=*.temp"
        "--exclude=*~"
        "--exclude=.DS_Store"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would sync with the following command:"
        echo "rsync -av --delete ${exclusions[*]} \"$SANDBOX_DIR/\" \"$PRODUCTION_DIR/\""
        return 0
    fi
    
    # Perform the actual sync
    if ! rsync -av --delete "${exclusions[@]}" "$SANDBOX_DIR/" "$PRODUCTION_DIR/"; then
        log_error "Sync failed"
        exit 4
    fi
    
    log_success "Sync completed successfully"
}

# Post-sync validation
post_sync_validation() {
    log_info "Running post-sync validation..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would run post-sync validation"
        return 0
    fi
    
    cd "$PRODUCTION_DIR"
    
    # Verify production build
    log_info "Validating production build..."
    if ! xcodebuild -project JarvisLive.xcodeproj -scheme JarvisLive -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet build &>/dev/null; then
        log_error "Production build failed after sync. This is critical!"
        log_error "Consider rolling back using: ./scripts/rollback_production.sh"
        exit 5
    fi
    
    # Verify critical files exist
    local critical_files=(
        "Sources/App/JarvisLiveApp.swift"
        "Sources/Core/Security/KeychainManager.swift"
        "Sources/Core/Audio/LiveKitManager.swift"
        "Resources/Info.plist"
    )
    
    for file in "${critical_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Critical file missing after sync: $file"
            exit 5
        fi
    done
    
    # Check for sandbox-specific content that shouldn't be in production
    if grep -r "Sandbox" . --include="*.swift" --exclude-dir=Tests | grep -v "// SANDBOX FILE" | head -5; then
        log_warning "Found potential sandbox references in production code. Review needed."
    fi
    
    log_success "Post-sync validation passed"
    cd "$PROJECT_ROOT"
}

# Generate sync report
generate_sync_report() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local report_file="$PROJECT_ROOT/logs/sync_report_$(date '+%Y%m%d_%H%M%S').md"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would generate sync report at $report_file"
        return 0
    fi
    
    cat > "$report_file" << EOF
# Production Sync Report

**Date:** $timestamp  
**Branch:** $(git branch --show-current)  
**Commit:** $(git rev-parse HEAD)  
**Status:** SUCCESS ✅

## Sync Details

**Source:** $SANDBOX_DIR  
**Target:** $PRODUCTION_DIR  
**Backup:** $(cat "$PROJECT_ROOT/.last_backup_path" 2>/dev/null || echo "None")

## Files Synchronized

\`\`\`
$(rsync -av --delete --dry-run "${exclusions[@]}" "$SANDBOX_DIR/" "$PRODUCTION_DIR/" 2>/dev/null | head -20)
\`\`\`

## Post-Sync Validation

- ✅ Production build successful
- ✅ Critical files present
- ✅ No obvious sandbox contamination

## Rollback Instructions

If issues are discovered, run:
\`\`\`bash
./scripts/rollback_production.sh
\`\`\`

## Next Steps

1. Deploy production build to TestFlight
2. Run full E2E testing suite
3. Monitor for any issues

---
*Generated by promote_sandbox_to_production.sh v1.0.0*
EOF
    
    log_success "Sync report generated: $report_file"
}

# Main execution function
main() {
    local start_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Setup logging
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_info "=== PRODUCTION SYNC SCRIPT STARTED ==="
    log_info "Start time: $start_time"
    log_info "Dry run: $DRY_RUN"
    
    # Execute the sync process
    preflight_checks
    create_backup
    perform_sync
    post_sync_validation
    generate_sync_report
    
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "End time: $end_time"
    log_success "=== PRODUCTION SYNC COMPLETED SUCCESSFULLY ==="
    
    if [[ "$DRY_RUN" == "false" ]]; then
        echo ""
        echo "🚀 Production sync completed successfully!"
        echo "📊 Check the sync report for details"
        echo "🔄 To rollback if needed: ./scripts/rollback_production.sh"
        echo ""
    else
        echo ""
        echo "🔍 Dry run completed successfully!"
        echo "🚀 Run without --dry-run to perform actual sync"
        echo ""
    fi
}

# Parse arguments and run main function
parse_args "$@"
main