#!/bin/bash

# HealthAI 2030 - Auto Development Workflow
# This script can be configured to auto-execute common development tasks

set -e  # Exit on any error

# Configuration
AUTO_GIT_PULL=true
AUTO_BUILD_CHECK=true
AUTO_TEST_RUN=false  # Set to true for auto-testing
AUTO_LINT_CHECK=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    error "Not in HealthAI 2030 project root. Please run from project root."
    exit 1
fi

log "Starting HealthAI 2030 development workflow..."

# 1. Git operations
if [ "$AUTO_GIT_PULL" = true ]; then
    log "Checking for git updates..."
    if git fetch --dry-run >/dev/null 2>&1; then
        log "Pulling latest changes..."
        git pull
    else
        log "No updates available"
    fi
fi

# 2. Package resolution
log "Resolving Swift package dependencies..."
swift package resolve

# 3. Build check
if [ "$AUTO_BUILD_CHECK" = true ]; then
    log "Checking build..."
    if swift build; then
        log "Build successful"
    else
        error "Build failed"
        exit 1
    fi
fi

# 4. Lint check
if [ "$AUTO_LINT_CHECK" = true ]; then
    log "Running SwiftLint..."
    if command -v swiftlint >/dev/null 2>&1; then
        swiftlint
        log "Lint check completed"
    else
        warn "SwiftLint not found, skipping lint check"
    fi
fi

# 5. Test run
if [ "$AUTO_TEST_RUN" = true ]; then
    log "Running tests..."
    if swift test; then
        log "All tests passed"
    else
        error "Tests failed"
        exit 1
    fi
fi

log "Development workflow completed successfully!"

# Optional: Show project status
echo ""
log "Project Status:"
echo "  - Package.swift: $(swift package describe --type json | jq -r '.name')"
echo "  - Swift version: $(swift --version | head -n1)"
echo "  - Git branch: $(git branch --show-current)"
echo "  - Last commit: $(git log -1 --oneline)" 