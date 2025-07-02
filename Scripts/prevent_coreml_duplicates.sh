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
