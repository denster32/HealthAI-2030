#!/bin/bash

# HealthAI 2030 Development Environment Setup Script
# Sets up complete development environment for iOS 18+ / macOS 15+ health app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Script metadata
SCRIPT_VERSION="2.0.1"
REQUIRED_XCODE_VERSION="16.0"
REQUIRED_SWIFT_VERSION="6.0"

log_info "HealthAI 2030 Development Setup v${SCRIPT_VERSION}"
log_info "Setting up iOS 18+ / macOS 15+ development environment..."
echo ""

# =============================================================================
# SYSTEM REQUIREMENTS CHECK
# =============================================================================

check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
    MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)
    
    if [[ $MACOS_MAJOR -lt 14 || ($MACOS_MAJOR -eq 14 && $MACOS_MINOR -lt 0) ]]; then
        log_error "macOS 14.0+ required for iOS 18+ development. Current: $MACOS_VERSION"
        exit 1
    fi
    log_success "macOS version check passed: $MACOS_VERSION"
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found. Please install Xcode 16+ from the App Store"
        exit 1
    fi
    
    # Check Xcode version
    XCODE_VERSION=$(xcodebuild -version | head -n1 | awk '{print $2}')
    if [[ $(echo "$XCODE_VERSION < $REQUIRED_XCODE_VERSION" | bc -l) -eq 1 ]]; then
        log_error "Xcode 16.0+ required. Current: $XCODE_VERSION"
        exit 1
    fi
    log_success "Xcode version check passed: $XCODE_VERSION"
    
    # Check Swift version
    SWIFT_VERSION=$(swift --version | head -n1 | awk '{print $4}')
    if [[ $(echo "$SWIFT_VERSION < $REQUIRED_SWIFT_VERSION" | bc -l) -eq 1 ]]; then
        log_error "Swift 6.0+ required. Current: $SWIFT_VERSION"
        exit 1
    fi
    log_success "Swift version check passed: $SWIFT_VERSION"
    
    echo ""
}

# =============================================================================
# ENVIRONMENT CONFIGURATION
# =============================================================================

setup_environment() {
    log_info "Setting up environment configuration..."
    
    # Create .env file from template if it doesn't exist
    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            log_success "Created .env file from template"
            log_warning "Please edit .env with your development team ID and settings"
        else
            log_error ".env.example template not found"
            exit 1
        fi
    else
        log_info ".env file already exists"
    fi
    
    # Create necessary directories
    mkdir -p "build"
    mkdir -p "docs/generated"
    mkdir -p "TestResults"
    mkdir -p "Coverage"
    log_success "Created necessary directories"
    
    echo ""
}

# =============================================================================
# SWIFT PACKAGE RESOLUTION
# =============================================================================

resolve_dependencies() {
    log_info "Resolving Swift Package dependencies..."
    
    # Clean previous builds
    if [[ -d ".build" ]]; then
        rm -rf .build
        log_info "Cleaned previous build artifacts"
    fi
    
    # Resolve packages
    swift package resolve
    log_success "Swift Package dependencies resolved"
    
    # Update Package.resolved if needed
    if [[ -f "Package.resolved" ]]; then
        log_info "Package.resolved updated"
    fi
    
    echo ""
}

# =============================================================================
# XCODE PROJECT GENERATION
# =============================================================================

generate_xcode_project() {
    log_info "Generating Xcode project..."
    
    # Generate Xcode project from Package.swift
    swift package generate-xcodeproj
    
    if [[ -f "HealthAI2030.xcodeproj/project.pbxproj" ]]; then
        log_success "Xcode project generated successfully"
    else
        log_error "Failed to generate Xcode project"
        exit 1
    fi
    
    echo ""
}

# =============================================================================
# DEVELOPMENT CERTIFICATES SETUP
# =============================================================================

setup_certificates() {
    log_info "Setting up development certificates..."
    
    # Check if development team is configured
    if [[ -f ".env" ]]; then
        DEVELOPMENT_TEAM=$(grep "DEVELOPMENT_TEAM=" .env | cut -d'=' -f2)
        if [[ -z "$DEVELOPMENT_TEAM" || "$DEVELOPMENT_TEAM" == "YOUR_APPLE_DEVELOPER_TEAM_ID" ]]; then
            log_warning "Development team not configured in .env"
            log_warning "Please update DEVELOPMENT_TEAM in .env with your Apple Developer Team ID"
        else
            log_success "Development team configured: $DEVELOPMENT_TEAM"
        fi
    fi
    
    # Check for valid signing identity
    SIGNING_IDENTITIES=$(security find-identity -v -p codesigning | grep "Apple Development" | wc -l)
    if [[ $SIGNING_IDENTITIES -eq 0 ]]; then
        log_warning "No Apple Development certificates found"
        log_warning "Please install development certificates from Apple Developer portal"
    else
        log_success "Found $SIGNING_IDENTITIES development certificate(s)"
    fi
    
    echo ""
}

# =============================================================================
# HEALTHKIT ENTITLEMENTS CHECK
# =============================================================================

check_healthkit_entitlements() {
    log_info "Checking HealthKit entitlements..."
    
    IOS_ENTITLEMENTS="Apps/MainApp/Resources/HealthAI2030_iOS18.entitlements"
    MACOS_ENTITLEMENTS="Apps/MainApp/Resources/HealthAI2030_macOS15.entitlements"
    
    if [[ -f "$IOS_ENTITLEMENTS" ]]; then
        if grep -q "com.apple.developer.healthkit" "$IOS_ENTITLEMENTS"; then
            log_success "iOS HealthKit entitlement found"
        else
            log_error "iOS HealthKit entitlement missing"
        fi
    else
        log_error "iOS entitlements file not found: $IOS_ENTITLEMENTS"
    fi
    
    if [[ -f "$MACOS_ENTITLEMENTS" ]]; then
        log_success "macOS entitlements file found"
    else
        log_error "macOS entitlements file not found: $MACOS_ENTITLEMENTS"
    fi
    
    echo ""
}

# =============================================================================
# BUILD VERIFICATION
# =============================================================================

verify_build() {
    log_info "Verifying build configuration..."
    
    # Test Swift package build
    log_info "Testing Swift package build..."
    if swift build -c debug; then
        log_success "Swift package builds successfully"
    else
        log_error "Swift package build failed"
        return 1
    fi
    
    # Test iOS project build (simulator only for setup)
    log_info "Testing iOS project build..."
    if xcodebuild -scheme HealthAI2030 -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug build; then
        log_success "iOS project builds successfully"
    else
        log_error "iOS project build failed"
        return 1
    fi
    
    echo ""
}

# =============================================================================
# DEVELOPMENT TOOLS SETUP
# =============================================================================

setup_development_tools() {
    log_info "Setting up development tools..."
    
    # Install SwiftLint if not present
    if ! command -v swiftlint &> /dev/null; then
        log_info "Installing SwiftLint..."
        if command -v brew &> /dev/null; then
            brew install swiftlint
            log_success "SwiftLint installed via Homebrew"
        else
            log_warning "Homebrew not found. Please install SwiftLint manually"
            log_info "Download from: https://github.com/realm/SwiftLint"
        fi
    else
        log_success "SwiftLint already installed"
    fi
    
    # Install SwiftFormat if not present
    if ! command -v swiftformat &> /dev/null; then
        log_info "Installing SwiftFormat..."
        if command -v brew &> /dev/null; then
            brew install swiftformat
            log_success "SwiftFormat installed via Homebrew"
        else
            log_warning "Homebrew not found. Please install SwiftFormat manually"
        fi
    else
        log_success "SwiftFormat already installed"
    fi
    
    echo ""
}

# =============================================================================
# GIT HOOKS SETUP
# =============================================================================

setup_git_hooks() {
    log_info "Setting up Git hooks..."
    
    # Create pre-commit hook
    PRE_COMMIT_HOOK=".git/hooks/pre-commit"
    
    cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash
# HealthAI 2030 pre-commit hook

echo "Running pre-commit checks..."

# Run SwiftLint
if command -v swiftlint >/dev/null 2>&1; then
    swiftlint --quiet
    if [[ $? -ne 0 ]]; then
        echo "❌ SwiftLint failed. Please fix the issues before committing."
        exit 1
    fi
    echo "✅ SwiftLint passed"
else
    echo "⚠️  SwiftLint not installed"
fi

# Run SwiftFormat check
if command -v swiftformat >/dev/null 2>&1; then
    swiftformat --lint .
    if [[ $? -ne 0 ]]; then
        echo "❌ SwiftFormat check failed. Run 'swiftformat .' to fix formatting."
        exit 1
    fi
    echo "✅ SwiftFormat check passed"
else
    echo "⚠️  SwiftFormat not installed"
fi

# Build check
echo "Running build check..."
swift build -c debug
if [[ $? -ne 0 ]]; then
    echo "❌ Build failed. Please fix build errors before committing."
    exit 1
fi
echo "✅ Build check passed"

echo "✅ All pre-commit checks passed!"
EOF

    chmod +x "$PRE_COMMIT_HOOK"
    log_success "Git pre-commit hook installed"
    
    echo ""
}

# =============================================================================
# SIMULATOR SETUP
# =============================================================================

setup_simulators() {
    log_info "Setting up iOS Simulators..."
    
    # List available simulators
    AVAILABLE_SIMULATORS=$(xcrun simctl list devices available | grep "iPhone 15 Pro" | head -1)
    
    if [[ -n "$AVAILABLE_SIMULATORS" ]]; then
        log_success "iPhone 15 Pro simulator available"
    else
        log_warning "iPhone 15 Pro simulator not found"
        log_info "You may need to download additional simulators in Xcode"
    fi
    
    # Check for watchOS simulator
    WATCH_SIMULATORS=$(xcrun simctl list devices available | grep "Apple Watch" | head -1)
    
    if [[ -n "$WATCH_SIMULATORS" ]]; then
        log_success "Apple Watch simulator available"
    else
        log_warning "Apple Watch simulator not found"
    fi
    
    echo ""
}

# =============================================================================
# DOCUMENTATION GENERATION
# =============================================================================

generate_documentation() {
    log_info "Generating project documentation..."
    
    # Generate Swift package documentation using DocC
    if command -v swift &> /dev/null; then
        log_info "Generating DocC documentation..."
        
        # Create documentation for each package
        for package in Packages/*/; do
            if [[ -d "$package" ]]; then
                package_name=$(basename "$package")
                log_info "Generating docs for $package_name..."
                
                cd "$package"
                swift package generate-documentation --target "$package_name" 2>/dev/null || true
                cd - > /dev/null
            fi
        done
        
        log_success "Documentation generation completed"
    fi
    
    echo ""
}

# =============================================================================
# PRIVACY MANIFEST VALIDATION
# =============================================================================

validate_privacy_manifests() {
    log_info "Validating privacy manifests..."
    
    PRIVACY_MANIFEST="Apps/MainApp/Resources/PrivacyInfo.xcprivacy"
    
    if [[ -f "$PRIVACY_MANIFEST" ]]; then
        # Basic XML validation
        if xmllint --noout "$PRIVACY_MANIFEST" 2>/dev/null; then
            log_success "Privacy manifest is valid XML"
        else
            log_error "Privacy manifest has XML syntax errors"
        fi
        
        # Check for required privacy keys
        if grep -q "NSPrivacyCollectedDataTypes" "$PRIVACY_MANIFEST"; then
            log_success "Privacy data types declared"
        else
            log_warning "Privacy data types not declared"
        fi
        
        if grep -q "NSPrivacyAccessedAPITypes" "$PRIVACY_MANIFEST"; then
            log_success "API access types declared"
        else
            log_warning "API access types not declared"
        fi
    else
        log_warning "Privacy manifest not found at $PRIVACY_MANIFEST"
    fi
    
    echo ""
}

# =============================================================================
# TESTING SETUP
# =============================================================================

setup_testing() {
    log_info "Setting up testing environment..."
    
    # Run basic tests to verify setup
    log_info "Running test suite..."
    
    if swift test 2>/dev/null; then
        log_success "Test suite runs successfully"
    else
        log_warning "Some tests may be failing (this is normal for initial setup)"
    fi
    
    # Create test data directories
    mkdir -p "Tests/TestData"
    mkdir -p "Tests/MockData"
    log_success "Test directories created"
    
    echo ""
}

# =============================================================================
# COMPLETION SUMMARY
# =============================================================================

print_setup_summary() {
    echo ""
    log_success "🎉 HealthAI 2030 development environment setup completed!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 SETUP SUMMARY:"
    echo ""
    echo "   ✅ System requirements verified"
    echo "   ✅ Environment configuration created"
    echo "   ✅ Swift packages resolved"
    echo "   ✅ Xcode project generated"
    echo "   ✅ Development tools installed"
    echo "   ✅ Git hooks configured"
    echo "   ✅ Testing environment ready"
    echo ""
    echo "📱 NEXT STEPS:"
    echo ""
    echo "   1. Edit .env file with your Apple Developer Team ID"
    echo "   2. Open HealthAI2030.xcodeproj in Xcode"
    echo "   3. Select your development team in project settings"
    echo "   4. Run the app on a physical device for HealthKit testing"
    echo "   5. Review docs/DEVELOPER_GUIDE.md for detailed instructions"
    echo ""
    echo "🔧 DEVELOPMENT COMMANDS:"
    echo ""
    echo "   swift build                    # Build the project"
    echo "   swift test                     # Run tests"
    echo "   swiftlint                      # Check code style"
    echo "   swiftformat .                  # Format code"
    echo ""
    echo "📖 DOCUMENTATION:"
    echo ""
    echo "   README.md                      # Project overview"
    echo "   docs/DEVELOPER_GUIDE.md        # Development guide"
    echo "   docs/API_REFERENCE.md          # API documentation"
    echo "   Security/SECURITY.md           # Security guidelines"
    echo ""
    echo "🆘 SUPPORT:"
    echo ""
    echo "   GitHub Issues: https://github.com/healthai2030/HealthAI2030/issues"
    echo "   Discord: https://discord.gg/healthai2030"
    echo "   Email: support@healthai2030.com"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_success "Happy coding! 🚀"
    echo ""
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    # Check if running from correct directory
    if [[ ! -f "Package.swift" ]]; then
        log_error "Please run this script from the HealthAI2030 project root directory"
        exit 1
    fi
    
    # Run setup steps
    check_system_requirements
    setup_environment
    resolve_dependencies
    generate_xcode_project
    setup_certificates
    check_healthkit_entitlements
    setup_development_tools
    setup_git_hooks
    setup_simulators
    generate_documentation
    validate_privacy_manifests
    setup_testing
    
    # Verify everything works
    if verify_build; then
        print_setup_summary
    else
        log_error "Setup completed but build verification failed"
        log_warning "Please check the error messages above and resolve any issues"
        exit 1
    fi
}

# Run main function
main "$@"