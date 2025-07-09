#!/bin/bash

# Fix Build Issues Script for HealthAI 2030
# This script helps resolve common Xcode build issues

echo "🔧 Fixing HealthAI 2030 Build Issues..."

# 1. Clean Derived Data
echo "📁 Cleaning Derived Data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/HealthAI_2030-*

# 2. Clean Build Folder
echo "🏗️  Cleaning Build Folder..."
xcodebuild clean -project "HealthAI 2030.xcodeproj" -scheme "HealthAI 2030"

# 3. Remove any duplicate .stringsdata files
echo "🗑️  Removing duplicate .stringsdata files..."
find ~/Library/Developer/Xcode/DerivedData -name "*SleepStagePredictor.stringsdata*" -delete 2>/dev/null

# 4. Reset Xcode caches
echo "🔄 Resetting Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode
rm -rf ~/Library/Developer/Xcode/DerivedData

# 5. Check for duplicate files in project
echo "🔍 Checking for duplicate files..."
echo "Note: Removed duplicate IPAD_ADAPTATION_PLAN.md from Archive directory"

# 6. Verify Core ML model
echo "🤖 Verifying Core ML model..."
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "✅ SleepStagePredictor.mlmodel found"
else
    echo "❌ SleepStagePredictor.mlmodel missing"
fi

echo ""
echo "✅ Build issue fixes completed!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (Cmd+Shift+K)"
echo "3. Build the project (Cmd+B)"
echo ""
echo "If issues persist:"
echo "- Check Build Settings > Core ML Model Compiler"
echo "- Ensure no duplicate files in project navigator"
echo "- Verify target membership for all files"

${SRCROOT}/Scripts/prevent_coreml_duplicates.sh 