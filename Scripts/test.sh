#!/bin/bash
#
# Run unit and UI tests for the HealthAI 2030 project.

set -eo pipefail

WORKSPACE="HealthAI 2030.xcworkspace"
SCHEME="HealthAI2030App"
PLATFORM="iOS Simulator,name=iPhone 15 Pro"

echo "🧪 Running tests for HealthAI 2030..."

xcodebuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "platform=$PLATFORM" \
  test

echo "✅ Tests passed!"
