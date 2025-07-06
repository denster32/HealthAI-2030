#!/bin/bash

# Fix Xcode Project Configuration for Core ML
# This script addresses the root cause of duplicate Core ML compilation

echo "🔧 Fixing Xcode project configuration for Core ML..."

# 1. First, let's restore the model
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel.disabled" ]; then
    echo "📋 Restoring SleepStagePredictor.mlmodel..."
    mv "HealthAI 2030/ML/SleepStagePredictor.mlmodel.disabled" "HealthAI 2030/ML/SleepStagePredictor.mlmodel"
fi

# 2. Create a build phase script to prevent duplicate compilation
echo "📝 Creating build phase prevention script..."
cat > "Scripts/prevent_coreml_duplicates.sh" << 'EOF'
#!/bin/bash

# Prevent Core ML Duplicate Compilation
# This script runs during build to prevent duplicate .stringsdata files

echo "🔧 Preventing Core ML duplicate compilation..."

# Get build environment variables
PROJECT_DIR="${SRCROOT}"
DERIVED_DATA_DIR="${BUILT_PRODUCTS_DIR%/*}"
BUILD_DIR="${BUILD_DIR}"

echo "Project: $PROJECT_DIR"
echo "Derived Data: $DERIVED_DATA_DIR"
echo "Build Dir: $BUILD_DIR"

# Remove any existing .stringsdata files for our models
find "$DERIVED_DATA_DIR" -name "*SleepStagePredictor.stringsdata*" -delete 2>/dev/null || true
find "$BUILD_DIR" -name "*SleepStagePredictor.stringsdata*" -delete 2>/dev/null || true

# Remove any existing .mlmodelc directories
find "$DERIVED_DATA_DIR" -name "*SleepStagePredictor.mlmodelc*" -exec rm -rf {} \; 2>/dev/null || true
find "$BUILD_DIR" -name "*SleepStagePredictor.mlmodelc*" -exec rm -rf {} \; 2>/dev/null || true

# Ensure only one copy of the model is processed
MODEL_COUNT=$(find "$PROJECT_DIR" -name "SleepStagePredictor.mlmodel" | wc -l)
if [ "$MODEL_COUNT" -gt 1 ]; then
    echo "⚠️  Multiple SleepStagePredictor.mlmodel files found, keeping only the first one"
    find "$PROJECT_DIR" -name "SleepStagePredictor.mlmodel" | tail -n +2 | xargs rm -f
fi

echo "✅ Core ML duplicate prevention completed"
EOF

chmod +x "Scripts/prevent_coreml_duplicates.sh"

# 3. Clean everything
echo "🧹 Cleaning build environment..."
find ~/Library/Developer/Xcode/DerivedData -name "*HealthAI_2030*" -type d -exec rm -rf {} \; 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "*.stringsdata" -delete 2>/dev/null || true
find ~/Library/Developer/Xcode/DerivedData -name "*.mlmodelc" -type d -exec rm -rf {} \; 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null || true

# 4. Verify setup
echo "🔍 Verifying setup..."
if [ -f "HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "✅ SleepStagePredictor.mlmodel exists"
    ls -la "HealthAI 2030/ML/SleepStagePredictor.mlmodel"
else
    echo "❌ SleepStagePredictor.mlmodel missing"
fi

if [ -f "Scripts/prevent_coreml_duplicates.sh" ]; then
    echo "✅ Prevention script created"
else
    echo "❌ Prevention script creation failed"
fi

echo ""
echo "✅ Xcode project configuration fix completed!"
echo ""
echo "IMPORTANT: You need to add a build phase script in Xcode:"
echo "1. Open Xcode"
echo "2. Select your target"
echo "3. Go to 'Build Phases'"
echo "4. Click '+' → 'New Run Script Phase'"
echo "5. Add this script: \${SRCROOT}/Scripts/prevent_coreml_duplicates.sh"
echo "6. Move this phase BEFORE the 'Compile Sources' phase"
echo ""
echo "Then:"
echo "1. Clean Build Folder (Cmd+Shift+K)"
echo "2. Build the project (Cmd+B)" 