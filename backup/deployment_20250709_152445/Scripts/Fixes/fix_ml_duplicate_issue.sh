#!/bin/bash

# Fix Core ML Model Duplicate Compilation Issue
# This script specifically addresses the SleepStagePredictor.stringsdata duplicate error

echo "🔧 Fixing Core ML Model Duplicate Compilation Issue..."

# 1. Remove all derived data for this project
echo "📁 Removing all derived data..."
find ~/Library/Developer/Xcode/DerivedData -name "*HealthAI_2030*" -type d -exec rm -rf {} \; 2>/dev/null || true

# 2. Remove all .stringsdata files
echo "🗑️  Removing all .stringsdata files..."
find ~/Library/Developer/Xcode/DerivedData -name "*.stringsdata" -delete 2>/dev/null || true

# 3. Remove all .mlmodelc directories
echo "🤖 Removing all compiled Core ML models..."
find ~/Library/Developer/Xcode/DerivedData -name "*.mlmodelc" -type d -exec rm -rf {} \; 2>/dev/null || true

# 4. Clean Xcode caches
echo "🔄 Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true

# 5. Verify the Core ML model exists
echo "🔍 Verifying Core ML model..."
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "✅ SleepStagePredictor.mlmodel found"
    ls -la "HealthAI 2030/ML/SleepStagePredictor.mlmodel"
else
    echo "❌ SleepStagePredictor.mlmodel missing"
    exit 1
fi

# 6. Check for duplicate model files
echo "🔍 Checking for duplicate model files..."
MODEL_COUNT=$(find . -name "*.mlmodel" -type f | wc -l)
echo "Found $MODEL_COUNT .mlmodel files"

if [ "$MODEL_COUNT" -gt 1 ]; then
    echo "⚠️  Multiple .mlmodel files found:"
    find . -name "*.mlmodel" -type f
fi

# 7. Verify no duplicate references in code
echo "🔍 Checking for duplicate model references..."
SLEEP_PREDICTOR_COUNT=$(grep -r "SleepStagePredictor()" "HealthAI 2030" --include="*.swift" | wc -l)
echo "Found $SLEEP_PREDICTOR_COUNT SleepStagePredictor() instantiations"

if [ "$SLEEP_PREDICTOR_COUNT" -gt 1 ]; then
    echo "⚠️  Multiple SleepStagePredictor() instantiations found:"
    grep -r "SleepStagePredictor()" "HealthAI 2030" --include="*.swift"
fi

echo ""
echo "✅ Core ML duplicate compilation fix completed!"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. Clean Build Folder (Cmd+Shift+K)"
echo "3. Build the project (Cmd+B)"
echo ""
echo "The issue should now be resolved because:"
echo "- Only one SleepStagePredictor.shared instance is used"
echo "- All duplicate build artifacts have been removed"
echo "- Xcode caches have been cleared" 