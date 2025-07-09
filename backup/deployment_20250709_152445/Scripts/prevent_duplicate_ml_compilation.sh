#!/bin/bash

# Prevent Duplicate Core ML Model Compilation Script
# This script helps prevent the "Multiple commands produce" error for .stringsdata files

echo "🔧 Preventing duplicate Core ML model compilation..."

# Get the project directory
PROJECT_DIR="${SRCROOT}"
DERIVED_DATA_DIR="${BUILT_PRODUCTS_DIR%/*}"

echo "Project Directory: $PROJECT_DIR"
echo "Derived Data Directory: $DERIVED_DATA_DIR"

# Find and remove any existing .stringsdata files for our models
find "$DERIVED_DATA_DIR" -name "*SleepStagePredictor.stringsdata*" -delete 2>/dev/null || true
find "$DERIVED_DATA_DIR" -name "*SleepStagePredictor.mlmodelc*" -exec rm -rf {} \; 2>/dev/null || true

# Ensure the Core ML model is properly copied to the bundle
if [ -f "$PROJECT_DIR/HealthAI 2030/ML/SleepStagePredictor.mlmodel" ]; then
    echo "✅ SleepStagePredictor.mlmodel found"
    
    # Copy to bundle if not already there
    if [ ! -f "$BUILT_PRODUCTS_DIR/SleepStagePredictor.mlmodel" ]; then
        cp "$PROJECT_DIR/HealthAI 2030/ML/SleepStagePredictor.mlmodel" "$BUILT_PRODUCTS_DIR/"
        echo "📋 Copied SleepStagePredictor.mlmodel to bundle"
    fi
else
    echo "❌ SleepStagePredictor.mlmodel not found"
fi

# Clean up any duplicate compilation artifacts
find "$DERIVED_DATA_DIR" -name "*.mlmodelc" -type d -exec rm -rf {} \; 2>/dev/null || true

echo "✅ Core ML compilation prevention completed" 