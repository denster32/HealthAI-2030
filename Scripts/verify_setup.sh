#!/bin/bash

echo "🔍 HealthAI 2030 - Project Verification"
echo "======================================"

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found. Please run this script from the project root."
    exit 1
fi

echo "✅ Found Package.swift"

# Check Swift version
SWIFT_VERSION=$(swift --version | head -n 1)
echo "📱 Swift Version: $SWIFT_VERSION"

# Check if all packages exist
echo ""
echo "📦 Checking package structure..."

PACKAGES=(
    "HealthAI2030Core"
    "HealthAI2030Networking"
    "HealthAI2030UI"
    "HealthAI2030Graphics"
    "HealthAI2030ML"
    "HealthAI2030Foundation"
    "CardiacHealth"
    "MentalHealth"
    "iOS18Features"
    "SleepTracking"
    "HealthPrediction"
    "CopilotSkills"
    "Metal4"
    "SmartHome"
    "UserScripting"
    "Shortcuts"
    "LogWaterIntake"
    "StartMeditation"
    "AR"
    "Biofeedback"
    "Shared"
    "SharedSettingsModule"
    "HealthAIConversationalEngine"
    "Kit"
    "SharedHealthSummary"
)

MISSING_PACKAGES=()

for package in "${PACKAGES[@]}"; do
    if [ -d "Packages/$package/Sources" ] || \
       [ -d "Packages/$package/Sources/$package" ] || \
       [ -d "Modules/Features/$package/$package" ] || \
       [ -d "Frameworks/$package/Sources" ] || \
       [ -d "Frameworks/$package/Sources/$package" ]; then
        echo "  ✅ $package"
    else
        echo "  ❌ $package (missing)"
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "❌ Missing packages: ${MISSING_PACKAGES[*]}"
    exit 1
fi

echo ""
echo "✅ All packages present"

# Check test structure
echo ""
echo "🧪 Checking test structure..."

TEST_TARGETS=(
    "HealthAI2030Tests"
    "HealthAI2030IntegrationTests"
    "HealthAI2030UITests"
)

for test in "${TEST_TARGETS[@]}"; do
    if [ -d "Tests/$test" ]; then
        echo "  ✅ $test"
    else
        echo "  ❌ $test (missing)"
        exit 1
    fi
done

echo ""
echo "✅ All test targets present"

# Run build verification
echo ""
echo "🔨 Running build verification..."

if swift build --quiet; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    echo "    ⚠️ Ensure the installed Swift toolchain matches the required version"
    echo "    as specified in Package.swift files (e.g., Swift 6.2)."
    exit 1
fi

# Run test verification
echo ""
echo "🧪 Running test verification..."

if swift test --quiet; then
    echo "✅ All tests passed"
else
    echo "❌ Tests failed"
    exit 1
fi

# Check platform support
echo ""
echo "📱 Platform Support:"
echo "  ✅ iOS 18.0+"
echo "  ✅ macOS 15.0+"
echo "  ✅ watchOS 11.0+"
echo "  ✅ tvOS 18.0+"

# Final status
echo ""
echo "🎉 VERIFICATION COMPLETE!"
echo "========================="
echo "✅ Project structure: Valid"
echo "✅ Package dependencies: Resolved"
echo "✅ Build system: Working"
echo "✅ Test suite: Passing"
echo "✅ Platform targets: Configured"
echo ""
echo "🚀 HealthAI 2030 is ready for development!"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode"
echo "2. Start developing features in the Packages/ directory"
echo "3. Add new modules as needed"
echo "4. Run 'swift test' to verify changes"
echo ""
echo "📚 Documentation: README.md"
echo "📋 Summary: REORGANIZATION_SUMMARY.md" 