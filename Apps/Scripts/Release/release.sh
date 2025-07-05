#!/bin/zsh
# Release script for HealthAI 2030
set -e

echo "==> Running tests..."
swift test --enable-code-coverage

echo "==> Building for release..."
swift build -c release

echo "==> Tagging version..."
VERSION=$(grep '^// Version' Package.swift | awk '{print $3}')
git tag v$VERSION

echo "==> Pushing tags..."
git push origin v$VERSION

echo "==> Release complete."
