#!/bin/bash

# HealthAI 2030 Advanced Scaffolding Validation Script
# This script validates the complete advanced modular development structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/validation_log.txt"
ERROR_LOG="$PROJECT_ROOT/validation_errors.txt"

# Initialize logs
echo "HealthAI 2030 Advanced Scaffolding Validation" > "$LOG_FILE"
echo "Started at: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

echo "HealthAI 2030 Advanced Scaffolding Validation"
echo "=============================================="
echo "Project Root: $PROJECT_ROOT"
echo "Log File: $LOG_FILE"
echo "Error Log: $ERROR_LOG"
echo ""

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            echo "[$timestamp] [INFO] $message" >> "$LOG_FILE"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            echo "[$timestamp] [SUCCESS] $message" >> "$LOG_FILE"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            echo "[$timestamp] [WARNING] $message" >> "$LOG_FILE"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            echo "[$timestamp] [ERROR] $message" >> "$LOG_FILE"
            echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG"
            ;;
    esac
}

# Function to check if directory exists
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        log_message "SUCCESS" "✓ $description directory exists: $dir"
        return 0
    else
        log_message "ERROR" "✗ $description directory missing: $dir"
        return 1
    fi
}

# Function to check if file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        log_message "SUCCESS" "✓ $description file exists: $file"
        return 0
    else
        log_message "ERROR" "✗ $description file missing: $file"
        return 1
    fi
}

# Function to validate Swift file syntax
validate_swift_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        if swift -frontend -parse "$file" > /dev/null 2>&1; then
            log_message "SUCCESS" "✓ $description Swift syntax valid: $file"
            return 0
        else
            log_message "ERROR" "✗ $description Swift syntax invalid: $file"
            return 1
        fi
    else
        log_message "ERROR" "✗ $description Swift file missing: $file"
        return 1
    fi
}

# Function to count files in directory
count_files() {
    local dir="$1"
    local pattern="$2"
    local count=$(find "$dir" -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')
    echo "$count"
}

# Initialize error counter
ERROR_COUNT=0

log_message "INFO" "Starting comprehensive validation..."

# =============================================================================
# 1. VALIDATE ADVANCED MODULAR STRUCTURE
# =============================================================================

log_message "INFO" "Validating Advanced Modular Structure..."

# Core modules
check_directory "$PROJECT_ROOT/Modules/Advanced/Core/Protocols" "Core Protocols" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Core/Interfaces" "Core Interfaces" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Core/Abstractions" "Core Abstractions" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Core/Contracts" "Core Contracts" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Core/Extensions" "Core Extensions" || ((ERROR_COUNT++))

# Feature modules
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/HealthAI" "HealthAI Features" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/Analytics" "Analytics Features" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/Prediction" "Prediction Features" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/Integration" "Integration Features" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/UI" "UI Features" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Features/Performance" "Performance Features" || ((ERROR_COUNT++))

# Integration modules
check_directory "$PROJECT_ROOT/Modules/Advanced/Integration/APIs" "API Integration" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Integration/SDKs" "SDK Integration" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Integration/ThirdParty" "Third Party Integration" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Integration/Platforms" "Platform Integration" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Integration/Microservices" "Microservices Integration" || ((ERROR_COUNT++))

# Testing modules
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/Unit" "Unit Testing" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/Integration" "Integration Testing" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/Performance" "Performance Testing" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/UI" "UI Testing" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/Contract" "Contract Testing" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Testing/Property" "Property Testing" || ((ERROR_COUNT++))

# Documentation modules
check_directory "$PROJECT_ROOT/Modules/Advanced/Documentation/Architecture" "Architecture Documentation" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Documentation/API" "API Documentation" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Documentation/UserGuides" "User Guides" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Documentation/DeveloperGuides" "Developer Guides" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/Documentation/Deployment" "Deployment Documentation" || ((ERROR_COUNT++))

# CI/CD modules
check_directory "$PROJECT_ROOT/Modules/Advanced/CI-CD/Pipelines" "CI/CD Pipelines" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/CI-CD/Automation" "Automation" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/CI-CD/Deployment" "Deployment" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/CI-CD/Monitoring" "Monitoring" || ((ERROR_COUNT++))
check_directory "$PROJECT_ROOT/Modules/Advanced/CI-CD/Quality" "Quality Assurance" || ((ERROR_COUNT++))

# =============================================================================
# 2. VALIDATE CORE PROTOCOLS AND INTERFACES
# =============================================================================

log_message "INFO" "Validating Core Protocols and Interfaces..."

# Core protocol files
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Core/Protocols/HealthAIProtocols.swift" "HealthAI Protocols" || ((ERROR_COUNT++))
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Core/Interfaces/HealthAIInterfaces.swift" "HealthAI Interfaces" || ((ERROR_COUNT++))
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Core/Abstractions/HealthAIAbstractions.swift" "HealthAI Abstractions" || ((ERROR_COUNT++))
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Core/Contracts/HealthAIContracts.swift" "HealthAI Contracts" || ((ERROR_COUNT++))
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Core/Extensions/HealthAIExtensions.swift" "HealthAI Extensions" || ((ERROR_COUNT++))

# =============================================================================
# 3. VALIDATE FEATURE IMPLEMENTATIONS
# =============================================================================

log_message "INFO" "Validating Feature Implementations..."

# HealthAI Core
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Features/HealthAI/HealthAICore.swift" "HealthAI Core" || ((ERROR_COUNT++))

# Analytics Engine
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Features/Analytics/AnalyticsEngine.swift" "Analytics Engine" || ((ERROR_COUNT++))

# Prediction Engine
validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Features/Prediction/PredictionEngine.swift" "Prediction Engine" || ((ERROR_COUNT++))

# =============================================================================
# 4. VALIDATE CI/CD PIPELINES
# =============================================================================

log_message "INFO" "Validating CI/CD Pipelines..."

check_file "$PROJECT_ROOT/Modules/Advanced/CI-CD/Pipelines/GitHubActions.yml" "GitHub Actions Pipeline" || ((ERROR_COUNT++))

# =============================================================================
# 5. VALIDATE DOCUMENTATION
# =============================================================================

log_message "INFO" "Validating Documentation..."

check_file "$PROJECT_ROOT/Modules/Advanced/Documentation/Architecture/SystemArchitecture.md" "System Architecture Documentation" || ((ERROR_COUNT++))
check_file "$PROJECT_ROOT/Modules/Advanced/Documentation/API/APIDocumentation.md" "API Documentation" || ((ERROR_COUNT++))

# =============================================================================
# 6. VALIDATE TESTING INFRASTRUCTURE
# =============================================================================

log_message "INFO" "Validating Testing Infrastructure..."

validate_swift_file "$PROJECT_ROOT/Modules/Advanced/Testing/Unit/HealthAIUnitTests.swift" "HealthAI Unit Tests" || ((ERROR_COUNT++))

# =============================================================================
# 7. VALIDATE PACKAGE STRUCTURE
# =============================================================================

log_message "INFO" "Validating Package Structure..."

check_file "$PROJECT_ROOT/Package.swift" "Package.swift" || ((ERROR_COUNT++))
check_file "$PROJECT_ROOT/README.md" "README.md" || ((ERROR_COUNT++))

# =============================================================================
# 8. VALIDATE BUILD CONFIGURATION
# =============================================================================

log_message "INFO" "Validating Build Configuration..."

check_directory "$PROJECT_ROOT/Configuration" "Build Configuration" || ((ERROR_COUNT++))
check_file "$PROJECT_ROOT/Configuration/BuildSettings-iOS18.xcconfig" "iOS 18 Build Settings" || ((ERROR_COUNT++))
check_file "$PROJECT_ROOT/Configuration/BuildSettings-macOS15.xcconfig" "macOS 15 Build Settings" || ((ERROR_COUNT++))

# =============================================================================
# 9. VALIDATE SCRIPT INFRASTRUCTURE
# =============================================================================

log_message "INFO" "Validating Script Infrastructure..."

check_directory "$PROJECT_ROOT/Scripts" "Scripts Directory" || ((ERROR_COUNT++))
check_file "$PROJECT_ROOT/Scripts/validate_advanced_scaffolding.sh" "Validation Script" || ((ERROR_COUNT++))

# =============================================================================
# 10. COUNT FILES AND VALIDATE COMPLETENESS
# =============================================================================

log_message "INFO" "Counting files and validating completeness..."

# Count Swift files
SWIFT_FILES=$(count_files "$PROJECT_ROOT" "*.swift")
log_message "INFO" "Total Swift files found: $SWIFT_FILES"

# Count test files
TEST_FILES=$(count_files "$PROJECT_ROOT" "*Tests.swift")
log_message "INFO" "Total test files found: $TEST_FILES"

# Count documentation files
DOC_FILES=$(count_files "$PROJECT_ROOT" "*.md")
log_message "INFO" "Total documentation files found: $DOC_FILES"

# Count configuration files
CONFIG_FILES=$(count_files "$PROJECT_ROOT" "*.yml" && count_files "$PROJECT_ROOT" "*.yaml")
log_message "INFO" "Total configuration files found: $CONFIG_FILES"

# =============================================================================
# 11. VALIDATE SWIFT PACKAGE MANAGER
# =============================================================================

log_message "INFO" "Validating Swift Package Manager..."

cd "$PROJECT_ROOT"

# Check if package resolves
if swift package resolve > /dev/null 2>&1; then
    log_message "SUCCESS" "✓ Swift package resolves successfully"
else
    log_message "ERROR" "✗ Swift package resolution failed"
    ((ERROR_COUNT++))
fi

# Check if package builds
if swift build > /dev/null 2>&1; then
    log_message "SUCCESS" "✓ Swift package builds successfully"
else
    log_message "ERROR" "✗ Swift package build failed"
    ((ERROR_COUNT++))
fi

# =============================================================================
# 12. VALIDATE CODE QUALITY
# =============================================================================

log_message "INFO" "Validating Code Quality..."

# Check if SwiftLint is available
if command -v swiftlint > /dev/null 2>&1; then
    if swiftlint lint --quiet > /dev/null 2>&1; then
        log_message "SUCCESS" "✓ SwiftLint validation passed"
    else
        log_message "WARNING" "⚠ SwiftLint found code style issues"
    fi
else
    log_message "WARNING" "⚠ SwiftLint not available, skipping code quality check"
fi

# =============================================================================
# 13. VALIDATE SECURITY
# =============================================================================

log_message "INFO" "Validating Security..."

# Check for sensitive files
SENSITIVE_FILES=(
    ".env"
    "*.p12"
    "*.pem"
    "*.key"
    "secrets.json"
)

for pattern in "${SENSITIVE_FILES[@]}"; do
    if find "$PROJECT_ROOT" -name "$pattern" -not -path "*/\.*" | grep -q .; then
        log_message "WARNING" "⚠ Found potentially sensitive files matching pattern: $pattern"
    fi
done

# Check .gitignore for sensitive patterns
if grep -q "\.env" "$PROJECT_ROOT/.gitignore" 2>/dev/null; then
    log_message "SUCCESS" "✓ .env files are properly ignored"
else
    log_message "WARNING" "⚠ .env files not found in .gitignore"
fi

# =============================================================================
# 14. GENERATE VALIDATION SUMMARY
# =============================================================================

log_message "INFO" "Generating validation summary..."

echo "" >> "$LOG_FILE"
echo "Validation Summary" >> "$LOG_FILE"
echo "=================" >> "$LOG_FILE"
echo "Total Errors: $ERROR_COUNT" >> "$LOG_FILE"
echo "Swift Files: $SWIFT_FILES" >> "$LOG_FILE"
echo "Test Files: $TEST_FILES" >> "$LOG_FILE"
echo "Documentation Files: $DOC_FILES" >> "$LOG_FILE"
echo "Configuration Files: $CONFIG_FILES" >> "$LOG_FILE"
echo "Validation completed at: $(date)" >> "$LOG_FILE"

# =============================================================================
# 15. FINAL RESULTS
# =============================================================================

echo ""
echo "=============================================="
echo "VALIDATION COMPLETE"
echo "=============================================="

if [ $ERROR_COUNT -eq 0 ]; then
    log_message "SUCCESS" "🎉 All validations passed! Advanced scaffolding is complete and ready for development."
    echo ""
    echo "Next steps:"
    echo "1. Review the validation log: $LOG_FILE"
    echo "2. Start implementing specific features"
    echo "3. Run tests: swift test"
    echo "4. Build the project: swift build"
    echo ""
    exit 0
else
    log_message "ERROR" "❌ Validation failed with $ERROR_COUNT errors."
    echo ""
    echo "Please review the following files:"
    echo "- Validation log: $LOG_FILE"
    echo "- Error log: $ERROR_LOG"
    echo ""
    echo "Fix the errors and run the validation script again."
    echo ""
    exit 1
fi 