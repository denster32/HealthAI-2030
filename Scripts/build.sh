#!/bin/bash
#
# Build the HealthAI 2030 project for a specific scheme and platform.

set -eo pipefail

WORKSPACE="HealthAI 2030.xcworkspace"
SCHEME="HealthAI2030App"
PLATFORM="iOS Simulator,name=iPhone 15 Pro"

echo "🚀 Building HealthAI 2030 for a modern iOS platform..."

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "platform=$PLATFORM" \
  clean build

echo "✅ Build complete!"
