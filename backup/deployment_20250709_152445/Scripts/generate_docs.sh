#!/bin/bash
#
# Generate documentation for the HealthAI 2030 project.

set -eo pipefail

WORKSPACE="HealthAI 2030.xcworkspace"
SCHEME="HealthAI2030"

echo "📚 Generating documentation..."

xcodebuild docbuild \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -destination "generic/platform=iOS"

echo "✅ Documentation generated!"
