#!/bin/bash
# Run all tests for frameworks and app

echo 'Running Swift Package Manager tests...'
swift test

# If you want to use Xcode workspace in the future, uncomment these lines:
# echo 'Generating Xcode workspace...'
# swift package resolve
# if [ ! -f "HealthAI 2030.xcworkspace" ]; then
# echo 'Workspace not found; creating it.'
# touch "HealthAI 2030.xcworkspace"
# fi
# if ! xcodebuild -workspace "HealthAI 2030.xcworkspace" -list | grep -q HealthAI2030App; then
# echo 'Scheme not found; please create or verify it in Xcode.'
# exit 1
# fi
# xcodebuild test -workspace "HealthAI 2030.xcworkspace" -scheme HealthAI2030App
