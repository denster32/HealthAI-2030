#!/bin/bash

# Test Build Without Core ML Model
# This script temporarily removes the Core ML model to test if the build works

echo "🧪 Testing build without Core ML model..."

# 1. Ensure the model is disabled
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "⚠️  Model still exists, disabling..."
    mv "HealthAI 2030/ML/SleepStagePredictor.mlmodel" "HealthAI 2030/ML/SleepStagePredictor.mlmodel.disabled"
fi

# 2. Clean everything
echo "🧹 Cleaning build environment..."
find ~/Library/Developer/Xcode/DerivedData -name "*HealthAI_2030*" -type d -exec rm -rf {} \; 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true

# 3. Test build
echo "🏗️  Testing build without Core ML model..."
xcodebuild clean -project "HealthAI 2030.xcodeproj" -scheme "HealthAI 2030" 2>/dev/null || true

echo ""
echo "✅ Test completed!"
echo ""
echo "Now try building in Xcode:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (Cmd+Shift+K)"
echo "3. Build the project (Cmd+B)"
echo ""
echo "If the build succeeds without the model, the issue is with Core ML compilation."
echo "If it still fails, there's another underlying issue." 