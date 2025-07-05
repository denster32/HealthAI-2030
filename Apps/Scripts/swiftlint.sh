#!/bin/bash

# SwiftLint Build Phase Script for HealthAI 2030
# This script runs SwiftLint during the build process

# Check if SwiftLint is installed
if which swiftlint >/dev/null; then
    echo "Running SwiftLint..."
    swiftlint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    echo "You can install SwiftLint via Homebrew: brew install swiftlint"
fi