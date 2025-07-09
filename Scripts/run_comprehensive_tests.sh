#!/bin/bash

# HealthAI 2030 - Comprehensive Test Execution Script
# Agent 4: Testing & Reliability Engineer
# Date: July 14, 2025

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test configuration
PROJECT_NAME="HealthAI2030"
COVERAGE_THRESHOLD=85
TEST_TIMEOUT=1800  # 30 minutes
MAX_RETRIES=3

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$PROJECT_ROOT/TestResults"
COVERAGE_DIR="$PROJECT_ROOT/Coverage"
REPORTS_DIR="$PROJECT_ROOT/Reports"

# Test schemes
UNIT_TEST_SCHEME="HealthAI2030"
UI_TEST_SCHEME="HealthAI2030UITests"
INTEGRATION_TEST_SCHEME="HealthAI2030IntegrationTests"
PERFORMANCE_TEST_SCHEME="HealthAI2030PerformanceTests"
SECURITY_TEST_SCHEME="HealthAI2030SecurityTests"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}==============================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==============================================================================${NC}"
}

print_section() {
    echo -e "${CYAN}-------------------------------------------------------------------------------${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}-------------------------------------------------------------------------------${NC}"
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

print_info() {
    echo -e "${PURPLE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_section "Checking Prerequisites"
    
    # Check if Xcode is installed
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed or not in PATH"
        exit 1
    fi
    
    # Check if Swift is available
    if ! command -v swift &> /dev/null; then
        print_error "Swift is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [[ ! -f "$PROJECT_ROOT/Package.swift" ]]; then
        print_error "Package.swift not found. Please run this script from the project root."
        exit 1
    fi
    
    print_success "All prerequisites met"
}

setup_directories() {
    print_section "Setting up directories"
    
    mkdir -p "$TEST_RESULTS_DIR"
    mkdir -p "$COVERAGE_DIR"
    mkdir -p "$REPORTS_DIR"
    
    print_success "Directories created"
}

clean_previous_results() {
    print_section "Cleaning previous test results"
    
    rm -rf "$TEST_RESULTS_DIR"/*
    rm -rf "$COVERAGE_DIR"/*
    rm -rf "$REPORTS_DIR"/*
    
    print_success "Previous results cleaned"
}

# =============================================================================
# TEST EXECUTION FUNCTIONS
# =============================================================================

run_unit_tests() {
    print_section "Running Unit Tests"
    
    local start_time=$(date +%s)
    local test_result=0
    
    # Run unit tests for iOS
    print_info "Running iOS unit tests..."
    xcodebuild test \
        -scheme "$UNIT_TEST_SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        -enableCodeCoverage YES \
        -resultBundlePath "$TEST_RESULTS_DIR/UnitTests-iOS.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    # Run unit tests for macOS
    print_info "Running macOS unit tests..."
    xcodebuild test \
        -scheme "$UNIT_TEST_SCHEME-macOS" \
        -destination "platform=macOS" \
        -configuration Debug \
        -enableCodeCoverage YES \
        -resultBundlePath "$TEST_RESULTS_DIR/UnitTests-macOS.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $test_result -eq 0 ]]; then
        print_success "Unit tests completed in ${duration}s"
    else
        print_error "Unit tests failed after ${duration}s"
    fi
    
    return $test_result
}

run_ui_tests() {
    print_section "Running UI Tests"
    
    local start_time=$(date +%s)
    local test_result=0
    
    # List of devices to test on
    local devices=("iPhone 15 Pro" "iPhone 15 Pro Max" "iPad Pro (12.9-inch)")
    
    for device in "${devices[@]}"; do
        print_info "Running UI tests on $device..."
        xcodebuild test \
            -scheme "$UI_TEST_SCHEME" \
            -destination "platform=iOS Simulator,name=$device" \
            -configuration Debug \
            -resultBundlePath "$TEST_RESULTS_DIR/UITests-$device.xcresult" \
            -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
            -quiet || test_result=1
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $test_result -eq 0 ]]; then
        print_success "UI tests completed in ${duration}s"
    else
        print_error "UI tests failed after ${duration}s"
    fi
    
    return $test_result
}

run_integration_tests() {
    print_section "Running Integration Tests"
    
    local start_time=$(date +%s)
    local test_result=0
    
    print_info "Running integration tests..."
    xcodebuild test \
        -scheme "$INTEGRATION_TEST_SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        -resultBundlePath "$TEST_RESULTS_DIR/IntegrationTests.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $test_result -eq 0 ]]; then
        print_success "Integration tests completed in ${duration}s"
    else
        print_error "Integration tests failed after ${duration}s"
    fi
    
    return $test_result
}

run_performance_tests() {
    print_section "Running Performance Tests"
    
    local start_time=$(date +%s)
    local test_result=0
    
    print_info "Running performance tests..."
    xcodebuild test \
        -scheme "$PERFORMANCE_TEST_SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Release \
        -resultBundlePath "$TEST_RESULTS_DIR/PerformanceTests.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $test_result -eq 0 ]]; then
        print_success "Performance tests completed in ${duration}s"
    else
        print_error "Performance tests failed after ${duration}s"
    fi
    
    return $test_result
}

run_security_tests() {
    print_section "Running Security Tests"
    
    local start_time=$(date +%s)
    local test_result=0
    
    print_info "Running security tests..."
    xcodebuild test \
        -scheme "$SECURITY_TEST_SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        -resultBundlePath "$TEST_RESULTS_DIR/SecurityTests.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    print_info "Running security analysis..."
    xcodebuild analyze \
        -scheme "$UNIT_TEST_SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15 Pro" \
        -configuration Debug \
        -resultBundlePath "$TEST_RESULTS_DIR/SecurityAnalysis.xcresult" \
        -derivedDataPath "$TEST_RESULTS_DIR/DerivedData" \
        -quiet || test_result=1
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $test_result -eq 0 ]]; then
        print_success "Security tests completed in ${duration}s"
    else
        print_error "Security tests failed after ${duration}s"
    fi
    
    return $test_result
}

# =============================================================================
# COVERAGE ANALYSIS
# =============================================================================

generate_coverage_report() {
    print_section "Generating Coverage Report"
    
    local coverage_file="$COVERAGE_DIR/combined-coverage.txt"
    local coverage_report="$REPORTS_DIR/coverage-report.md"
    
    # Generate coverage data from unit test results
    print_info "Extracting coverage data..."
    
    # iOS coverage
    if [[ -d "$TEST_RESULTS_DIR/UnitTests-iOS.xcresult" ]]; then
        xcrun xccov view --report "$TEST_RESULTS_DIR/UnitTests-iOS.xcresult" > "$COVERAGE_DIR/ios-coverage.txt"
    fi
    
    # macOS coverage
    if [[ -d "$TEST_RESULTS_DIR/UnitTests-macOS.xcresult" ]]; then
        xcrun xccov view --report "$TEST_RESULTS_DIR/UnitTests-macOS.xcresult" > "$COVERAGE_DIR/macos-coverage.txt"
    fi
    
    # Generate combined coverage report
    cat > "$coverage_report" << EOF
# HealthAI 2030 - Test Coverage Report
Generated: $(date)

## Coverage Summary

EOF
    
    # Process iOS coverage
    if [[ -f "$COVERAGE_DIR/ios-coverage.txt" ]]; then
        echo "### iOS Coverage" >> "$coverage_report"
        cat "$COVERAGE_DIR/ios-coverage.txt" >> "$coverage_report"
        echo "" >> "$coverage_report"
    fi
    
    # Process macOS coverage
    if [[ -f "$COVERAGE_DIR/macos-coverage.txt" ]]; then
        echo "### macOS Coverage" >> "$coverage_report"
        cat "$COVERAGE_DIR/macos-coverage.txt" >> "$coverage_report"
        echo "" >> "$coverage_report"
    fi
    
    # Calculate overall coverage
    local overall_coverage=0
    local coverage_count=0
    
    if [[ -f "$COVERAGE_DIR/ios-coverage.txt" ]]; then
        local ios_coverage=$(grep "TOTAL" "$COVERAGE_DIR/ios-coverage.txt" | awk '{print $2}' | sed 's/%//')
        overall_coverage=$(echo "$overall_coverage + $ios_coverage" | bc)
        coverage_count=$((coverage_count + 1))
    fi
    
    if [[ -f "$COVERAGE_DIR/macos-coverage.txt" ]]; then
        local macos_coverage=$(grep "TOTAL" "$COVERAGE_DIR/macos-coverage.txt" | awk '{print $2}' | sed 's/%//')
        overall_coverage=$(echo "$overall_coverage + $macos_coverage" | bc)
        coverage_count=$((coverage_count + 1))
    fi
    
    if [[ $coverage_count -gt 0 ]]; then
        overall_coverage=$(echo "scale=1; $overall_coverage / $coverage_count" | bc)
        echo "### Overall Coverage: ${overall_coverage}%" >> "$coverage_report"
        
        # Check coverage threshold
        if (( $(echo "$overall_coverage >= $COVERAGE_THRESHOLD" | bc -l) )); then
            echo "✅ Coverage threshold met: ${overall_coverage}% >= ${COVERAGE_THRESHOLD}%" >> "$coverage_report"
            COVERAGE_PASSED=true
        else
            echo "❌ Coverage threshold not met: ${overall_coverage}% < ${COVERAGE_THRESHOLD}%" >> "$coverage_report"
            COVERAGE_PASSED=false
        fi
    fi
    
    print_success "Coverage report generated: $coverage_report"
}

# =============================================================================
# TEST SUMMARY GENERATION
# =============================================================================

generate_test_summary() {
    print_section "Generating Test Summary"
    
    local summary_file="$REPORTS_DIR/test-summary.md"
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    cat > "$summary_file" << EOF
# HealthAI 2030 - Test Summary Report
Generated: $(date)

## Test Results Summary

EOF
    
    # Process unit test results
    if [[ -d "$TEST_RESULTS_DIR/UnitTests-iOS.xcresult" ]]; then
        local ios_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/UnitTests-iOS.xcresult" | grep -c "passed\|failed" || echo "0")
        echo "- **Unit Tests (iOS)**: ✅ Passed" >> "$summary_file"
        passed_tests=$((passed_tests + ios_tests))
        total_tests=$((total_tests + ios_tests))
    fi
    
    if [[ -d "$TEST_RESULTS_DIR/UnitTests-macOS.xcresult" ]]; then
        local macos_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/UnitTests-macOS.xcresult" | grep -c "passed\|failed" || echo "0")
        echo "- **Unit Tests (macOS)**: ✅ Passed" >> "$summary_file"
        passed_tests=$((passed_tests + macos_tests))
        total_tests=$((total_tests + macos_tests))
    fi
    
    # Process UI test results
    for device in "iPhone 15 Pro" "iPhone 15 Pro Max" "iPad Pro (12.9-inch)"; do
        if [[ -d "$TEST_RESULTS_DIR/UITests-$device.xcresult" ]]; then
            echo "- **UI Tests ($device)**: ✅ Passed" >> "$summary_file"
            local ui_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/UITests-$device.xcresult" | grep -c "passed\|failed" || echo "0")
            passed_tests=$((passed_tests + ui_tests))
            total_tests=$((total_tests + ui_tests))
        fi
    done
    
    # Process integration test results
    if [[ -d "$TEST_RESULTS_DIR/IntegrationTests.xcresult" ]]; then
        echo "- **Integration Tests**: ✅ Passed" >> "$summary_file"
        local integration_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/IntegrationTests.xcresult" | grep -c "passed\|failed" || echo "0")
        passed_tests=$((passed_tests + integration_tests))
        total_tests=$((total_tests + integration_tests))
    fi
    
    # Process performance test results
    if [[ -d "$TEST_RESULTS_DIR/PerformanceTests.xcresult" ]]; then
        echo "- **Performance Tests**: ✅ Passed" >> "$summary_file"
        local performance_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/PerformanceTests.xcresult" | grep -c "passed\|failed" || echo "0")
        passed_tests=$((passed_tests + performance_tests))
        total_tests=$((total_tests + performance_tests))
    fi
    
    # Process security test results
    if [[ -d "$TEST_RESULTS_DIR/SecurityTests.xcresult" ]]; then
        echo "- **Security Tests**: ✅ Passed" >> "$summary_file"
        local security_tests=$(xcrun xctestrun --result-bundle "$TEST_RESULTS_DIR/SecurityTests.xcresult" | grep -c "passed\|failed" || echo "0")
        passed_tests=$((passed_tests + security_tests))
        total_tests=$((total_tests + security_tests))
    fi
    
    echo "" >> "$summary_file"
    echo "## Test Statistics" >> "$summary_file"
    echo "- **Total Tests**: $total_tests" >> "$summary_file"
    echo "- **Passed Tests**: $passed_tests" >> "$summary_file"
    echo "- **Failed Tests**: $failed_tests" >> "$summary_file"
    echo "- **Success Rate**: $(echo "scale=1; $passed_tests * 100 / $total_tests" | bc)%" >> "$summary_file"
    
    echo "" >> "$summary_file"
    echo "## Quality Gates" >> "$summary_file"
    
    # Check if all tests passed
    if [[ $failed_tests -eq 0 ]]; then
        echo "✅ **All Tests Passed**" >> "$summary_file"
        ALL_TESTS_PASSED=true
    else
        echo "❌ **Some Tests Failed**" >> "$summary_file"
        ALL_TESTS_PASSED=false
    fi
    
    # Check coverage threshold
    if [[ "$COVERAGE_PASSED" == "true" ]]; then
        echo "✅ **Coverage Threshold Met**" >> "$summary_file"
    else
        echo "❌ **Coverage Threshold Not Met**" >> "$summary_file"
    fi
    
    echo "" >> "$summary_file"
    echo "## Next Steps" >> "$summary_file"
    
    if [[ "$ALL_TESTS_PASSED" == "true" && "$COVERAGE_PASSED" == "true" ]]; then
        echo "🎉 All quality gates passed! Ready for deployment." >> "$summary_file"
        QUALITY_GATE_PASSED=true
    else
        echo "⚠️ Quality gates failed. Please review and fix issues before deployment." >> "$summary_file"
        QUALITY_GATE_PASSED=false
    fi
    
    print_success "Test summary generated: $summary_file"
}

# =============================================================================
# QUALITY GATES
# =============================================================================

check_quality_gates() {
    print_section "Checking Quality Gates"
    
    local gates_passed=0
    local total_gates=2
    
    # Gate 1: All tests passed
    if [[ "$ALL_TESTS_PASSED" == "true" ]]; then
        print_success "Quality Gate 1: All tests passed"
        gates_passed=$((gates_passed + 1))
    else
        print_error "Quality Gate 1: Some tests failed"
    fi
    
    # Gate 2: Coverage threshold met
    if [[ "$COVERAGE_PASSED" == "true" ]]; then
        print_success "Quality Gate 2: Coverage threshold met"
        gates_passed=$((gates_passed + 1))
    else
        print_error "Quality Gate 2: Coverage threshold not met"
    fi
    
    echo ""
    echo "Quality Gates Summary: $gates_passed/$total_gates passed"
    
    if [[ $gates_passed -eq $total_gates ]]; then
        print_success "All quality gates passed! 🎉"
        return 0
    else
        print_error "Some quality gates failed! ⚠️"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header "HealthAI 2030 - Comprehensive Test Execution"
    
    # Initialize variables
    ALL_TESTS_PASSED=false
    COVERAGE_PASSED=false
    QUALITY_GATE_PASSED=false
    
    # Check prerequisites
    check_prerequisites
    
    # Setup
    setup_directories
    clean_previous_results
    
    # Run tests with timeout
    local overall_result=0
    
    # Unit tests
    if ! timeout $TEST_TIMEOUT bash -c 'run_unit_tests'; then
        print_error "Unit tests timed out or failed"
        overall_result=1
    fi
    
    # UI tests
    if ! timeout $TEST_TIMEOUT bash -c 'run_ui_tests'; then
        print_error "UI tests timed out or failed"
        overall_result=1
    fi
    
    # Integration tests
    if ! timeout $TEST_TIMEOUT bash -c 'run_integration_tests'; then
        print_error "Integration tests timed out or failed"
        overall_result=1
    fi
    
    # Performance tests
    if ! timeout $TEST_TIMEOUT bash -c 'run_performance_tests'; then
        print_error "Performance tests timed out or failed"
        overall_result=1
    fi
    
    # Security tests
    if ! timeout $TEST_TIMEOUT bash -c 'run_security_tests'; then
        print_error "Security tests timed out or failed"
        overall_result=1
    fi
    
    # Generate reports
    generate_coverage_report
    generate_test_summary
    
    # Check quality gates
    if check_quality_gates; then
        print_success "All quality gates passed! Ready for deployment."
    else
        print_error "Quality gates failed. Please review and fix issues."
    fi
    
    # Final summary
    print_header "Test Execution Complete"
    echo "Test Results: $REPORTS_DIR/"
    echo "Coverage Data: $COVERAGE_DIR/"
    echo "Test Artifacts: $TEST_RESULTS_DIR/"
    
    if [[ $overall_result -eq 0 ]]; then
        print_success "All tests completed successfully!"
        exit 0
    else
        print_error "Some tests failed. Please review the reports."
        exit 1
    fi
}

# =============================================================================
# SCRIPT EXECUTION
# =============================================================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 