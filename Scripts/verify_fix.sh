#!/bin/bash

# Verify Core ML Fix
# This script verifies that all fixes are properly in place

echo "🔍 Verifying Core ML fix..."

# 1. Check model file
echo "📋 Checking Core ML model..."
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "✅ SleepStagePredictor.mlmodel exists"
    ls -la "HealthAI 2030/ML/SleepStagePredictor.mlmodel"
else
    echo "❌ SleepStagePredictor.mlmodel missing"
fi

# 2. Check prevention script
echo "📝 Checking prevention script..."
if [ -f "Scripts/prevent_coreml_duplicates.sh" ]; then
    echo "✅ Prevention script exists"
    ls -la "Scripts/prevent_coreml_duplicates.sh"
else
    echo "❌ Prevention script missing"
fi

# 3. Check shared instance usage
echo "🔗 Checking shared instance usage..."
SHARED_COUNT=$(grep -r "SleepStagePredictor.shared" "HealthAI 2030" --include="*.swift" | wc -l)
echo "Found $SHARED_COUNT SleepStagePredictor.shared references"

if [ "$SHARED_COUNT" -ge 2 ]; then
    echo "✅ Shared instance properly implemented"
else
    echo "⚠️  Shared instance may not be fully implemented"
fi

# 4. Check for duplicate instantiations
echo "🚫 Checking for duplicate instantiations..."
INSTANTIATION_COUNT=$(grep -r "SleepStagePredictor()" "HealthAI 2030" --include="*.swift" | grep -v "static let shared" | grep -v "//" | wc -l)
echo "Found $INSTANTIATION_COUNT non-shared instantiations"

if [ "$INSTANTIATION_COUNT" -eq 0 ]; then
    echo "✅ No duplicate instantiations found"
else
    echo "⚠️  Found $INSTANTIATION_COUNT duplicate instantiations"
    grep -r "SleepStagePredictor()" "HealthAI 2030" --include="*.swift" | grep -v "static let shared" | grep -v "//"
fi

# 5. Check for duplicate model files
echo "📁 Checking for duplicate model files..."
MODEL_COUNT=$(find . -name "*.mlmodel" -type f | wc -l)
echo "Found $MODEL_COUNT .mlmodel files"

if [ "$MODEL_COUNT" -eq 1 ]; then
    echo "✅ Only one .mlmodel file found"
else
    echo "⚠️  Multiple .mlmodel files found:"
    find . -name "*.mlmodel" -type f
fi

# 6. Check derived data
echo "🗂️  Checking derived data..."
DERIVED_COUNT=$(find ~/Library/Developer/Xcode/DerivedData -name "*HealthAI_2030*" 2>/dev/null | wc -l)
echo "Found $DERIVED_COUNT derived data entries"

if [ "$DERIVED_COUNT" -eq 0 ]; then
    echo "✅ No derived data found (clean state)"
else
    echo "⚠️  Derived data still exists"
fi

echo ""
echo "🎯 Fix Verification Summary:"
echo "=========================="

if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ] && \
   [ -f "Scripts/prevent_coreml_duplicates.sh" ] && \
   [ "$SHARED_COUNT" -ge 2 ] && \
   [ "$INSTANTIATION_COUNT" -eq 0 ] && \
   [ "$MODEL_COUNT" -eq 1 ]; then
    echo "✅ ALL FIXES ARE IN PLACE!"
    echo ""
    echo "The Core ML duplicate compilation issue should be resolved."
    echo ""
    echo "Next steps:"
    echo "1. Add the build phase script in Xcode (see instructions above)"
    echo "2. Clean Build Folder (Cmd+Shift+K)"
    echo "3. Build the project (Cmd+B)"
else
    echo "❌ SOME FIXES ARE MISSING!"
    echo ""
    echo "Please run the fix scripts again or check the issues above."
fi 