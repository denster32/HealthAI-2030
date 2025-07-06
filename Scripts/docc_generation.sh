#!/bin/bash

# DocC Generation and Validation Script for HealthAI 2030
# Ensures comprehensive documentation generation and quality

set -e  # Exit immediately if a command exits with a non-zero status

# Logging functions
log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[0;33m[WARNING]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
    exit 1
}

# Configuration
DOCC_OUTPUT_DIR="./DocCDocumentation"
PACKAGES_DIR="Packages"
MINIMUM_COVERAGE_THRESHOLD=80  # Minimum documentation coverage percentage

# Validate DocC is available
validate_docc_availability() {
    if ! command -v swift &> /dev/null; then
        log_error "Swift not found. Please install Swift development tools."
    fi

    log_info "DocC generation environment validated."
}

# Generate documentation for a specific package
generate_package_documentation() {
    local package_path="$1"
    local package_name=$(basename "$package_path")

    log_info "Generating documentation for package: $package_name"

    # Attempt to generate documentation
    swift package generate-documentation \
        --target "$package_name" \
        --output-path "$DOCC_OUTPUT_DIR/$package_name" \
        --disable-indexing \
        2>&1 | tee "$DOCC_OUTPUT_DIR/$package_name/docc_log.txt"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "Documentation generation failed for $package_name"
    fi
}

# Validate documentation coverage
validate_documentation_coverage() {
    log_info "Validating documentation coverage..."

    local total_files=$(find "$PACKAGES_DIR" -name "*.swift" | wc -l)
    local documented_files=$(find "$DOCC_OUTPUT_DIR" -name "*.md" | wc -l)
    
    local coverage_percentage=$((documented_files * 100 / total_files))

    log_info "Total Swift files: $total_files"
    log_info "Documented files: $documented_files"
    log_info "Documentation coverage: $coverage_percentage%"

    if [ "$coverage_percentage" -lt "$MINIMUM_COVERAGE_THRESHOLD" ]; then
        log_error "Documentation coverage is below ${MINIMUM_COVERAGE_THRESHOLD}%"
    else
        log_success "Documentation coverage meets minimum requirements"
    fi
}

# Check for missing documentation comments
check_missing_documentation_comments() {
    log_info "Checking for missing documentation comments..."

    local missing_comments=$(find "$PACKAGES_DIR" -name "*.swift" -exec grep -L "///" {} \; | wc -l)

    if [ "$missing_comments" -gt 0 ]; then
        log_warning "$missing_comments files are missing documentation comments"
        find "$PACKAGES_DIR" -name "*.swift" -exec grep -L "///" {} \;
    else
        log_success "All Swift files have documentation comments"
    fi
}

# Main execution
main() {
    # Create output directory
    mkdir -p "$DOCC_OUTPUT_DIR"

    validate_docc_availability

    # Generate documentation for each package
    for package in "$PACKAGES_DIR"/*/; do
        if [ -d "$package" ]; then
            generate_package_documentation "$package"
        fi
    done

    validate_documentation_coverage
    check_missing_documentation_comments

    log_success "DocC documentation generation and validation completed successfully!"
}

# Run the script
main 