#!/bin/bash

# HealthAI 2030 - Xcode Project Setup Script
# This script sets up the Xcode project structure and build configurations

set -e

echo "🚀 Setting up HealthAI 2030 Xcode Project..."

# Create build directory
mkdir -p build

# Create Xcode project structure
echo "📁 Creating Xcode project structure..."

# Create main Xcode project if it doesn't exist
if [ ! -d "HealthAI 2030.xcodeproj" ]; then
    echo "Creating main Xcode project..."
    # This would typically be done through Xcode GUI or xcodebuild
    echo "Note: Main Xcode project creation requires Xcode GUI or xcodebuild with proper setup"
fi

# Verify Swift Package dependencies
echo "📦 Verifying Swift Package dependencies..."
swift package resolve
swift package update

# Create build configuration files
echo "⚙️ Creating build configuration files..."

# iOS Build Settings
cat > Configuration/BuildSettings-iOS18.xcconfig << 'EOF'
// iOS 18.0+ Build Settings
SWIFT_VERSION = 6.0
IPHONEOS_DEPLOYMENT_TARGET = 18.0
TARGETED_DEVICE_FAMILY = 1,2,3,4
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
CODE_SIGN_STYLE = Automatic
PRODUCT_BUNDLE_IDENTIFIER = com.healthai2030.ios
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule
EOF

# macOS Build Settings
cat > Configuration/BuildSettings-macOS15.xcconfig << 'EOF'
// macOS 15.0+ Build Settings
SWIFT_VERSION = 6.0
MACOSX_DEPLOYMENT_TARGET = 15.0
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
CODE_SIGN_STYLE = Automatic
PRODUCT_BUNDLE_IDENTIFIER = com.healthai2030.mac
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule
EOF

# watchOS Build Settings
cat > Configuration/BuildSettings-watchOS11.xcconfig << 'EOF'
// watchOS 11.0+ Build Settings
SWIFT_VERSION = 6.0
WATCHOS_DEPLOYMENT_TARGET = 11.0
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
CODE_SIGN_STYLE = Automatic
PRODUCT_BUNDLE_IDENTIFIER = com.healthai2030.watch
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule
EOF

# tvOS Build Settings
cat > Configuration/BuildSettings-tvOS18.xcconfig << 'EOF'
// tvOS 18.0+ Build Settings
SWIFT_VERSION = 6.0
TVOS_DEPLOYMENT_TARGET = 18.0
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
CODE_SIGN_STYLE = Automatic
PRODUCT_BUNDLE_IDENTIFIER = com.healthai2030.tv
MARKETING_VERSION = 1.0
CURRENT_PROJECT_VERSION = 1
GCC_OPTIMIZATION_LEVEL = s
SWIFT_COMPILATION_MODE = wholemodule
EOF

# Create build scripts
echo "🔧 Creating build scripts..."

# iOS Build Script
cat > Scripts/build_ios.sh << 'EOF'
#!/bin/bash
echo "📱 Building iOS app..."
xcodebuild -scheme HealthAI2030iOS -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
EOF

# macOS Build Script
cat > Scripts/build_macos.sh << 'EOF'
#!/bin/bash
echo "🖥️ Building macOS app..."
xcodebuild -scheme HealthAI2030Mac -destination 'platform=macOS' build
EOF

# watchOS Build Script
cat > Scripts/build_watchos.sh << 'EOF'
#!/bin/bash
echo "⌚ Building watchOS app..."
xcodebuild -scheme HealthAI2030Watch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9' build
EOF

# tvOS Build Script
cat > Scripts/build_tvos.sh << 'EOF'
#!/bin/bash
echo "📺 Building tvOS app..."
xcodebuild -scheme HealthAI2030TV -destination 'platform=tvOS Simulator,name=Apple TV 4K (3rd generation)' build
EOF

# Archive Scripts
cat > Scripts/archive_ios.sh << 'EOF'
#!/bin/bash
echo "📦 Archiving iOS app..."
xcodebuild -scheme HealthAI2030iOS -destination generic/platform=iOS archive -archivePath build/HealthAI2030iOS.xcarchive
EOF

cat > Scripts/archive_macos.sh << 'EOF'
#!/bin/bash
echo "📦 Archiving macOS app..."
xcodebuild -scheme HealthAI2030Mac -destination generic/platform=macOS archive -archivePath build/HealthAI2030Mac.xcarchive
EOF

cat > Scripts/archive_watchos.sh << 'EOF'
#!/bin/bash
echo "📦 Archiving watchOS app..."
xcodebuild -scheme HealthAI2030Watch -destination generic/platform=watchOS archive -archivePath build/HealthAI2030Watch.xcarchive
EOF

cat > Scripts/archive_tvos.sh << 'EOF'
#!/bin/bash
echo "📦 Archiving tvOS app..."
xcodebuild -scheme HealthAI2030TV -destination generic/platform=tvOS archive -archivePath build/HealthAI2030TV.xcarchive
EOF

# Export Scripts
cat > Scripts/export_ios.sh << 'EOF'
#!/bin/bash
echo "📤 Exporting iOS app..."
xcodebuild -exportArchive -archivePath build/HealthAI2030iOS.xcarchive -exportPath ./build -exportOptionsPlist ExportOptions.plist
EOF

cat > Scripts/export_macos.sh << 'EOF'
#!/bin/bash
echo "📤 Exporting macOS app..."
xcodebuild -exportArchive -archivePath build/HealthAI2030Mac.xcarchive -exportPath ./build -exportOptionsPlist ExportOptionsMac.plist
EOF

cat > Scripts/export_watchos.sh << 'EOF'
#!/bin/bash
echo "📤 Exporting watchOS app..."
xcodebuild -exportArchive -archivePath build/HealthAI2030Watch.xcarchive -exportPath ./build -exportOptionsPlist ExportOptionsWatch.plist
EOF

cat > Scripts/export_tvos.sh << 'EOF'
#!/bin/bash
echo "📤 Exporting tvOS app..."
xcodebuild -exportArchive -archivePath build/HealthAI2030TV.xcarchive -exportPath ./build -exportOptionsPlist ExportOptionsTV.plist
EOF

# Make scripts executable
chmod +x Scripts/build_*.sh
chmod +x Scripts/archive_*.sh
chmod +x Scripts/export_*.sh

echo "✅ Xcode project setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Open 'HealthAI 2030.xcworkspace' in Xcode"
echo "2. Configure code signing with your Apple Developer account"
echo "3. Set your Team ID in ExportOptions*.plist files"
echo "4. Run build scripts to test compilation"
echo ""
echo "🔧 Available build scripts:"
echo "  - Scripts/build_ios.sh"
echo "  - Scripts/build_macos.sh"
echo "  - Scripts/build_watchos.sh"
echo "  - Scripts/build_tvos.sh"
echo ""
echo "📦 Available archive scripts:"
echo "  - Scripts/archive_ios.sh"
echo "  - Scripts/archive_macos.sh"
echo "  - Scripts/archive_watchos.sh"
echo "  - Scripts/archive_tvos.sh" 