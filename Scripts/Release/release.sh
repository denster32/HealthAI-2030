#!/bin/zsh
# Release script for HealthAI 2030
# Improved reliability and safety checks
set -euo pipefail
IFS=$'\n\t'

trap 'echo "ERROR: Release script failed" >&2' ERR

echo "==> Ensuring working tree is clean..."
if ! git diff-index --quiet HEAD --; then
  echo "ERROR: Uncommitted changes detected. Commit or stash before releasing."
  exit 1
fi

echo "==> Running tests..."
swift test --enable-code-coverage

echo "==> Building for release..."
swift build -c release

echo "==> Tagging version..."
VERSION=$(grep '^// Version' Package.swift | awk '{print $3}')
if [ -z "$VERSION" ]; then
  echo "ERROR: Version not found in Package.swift"
  exit 1
fi
git tag "v${VERSION}"

echo "==> Pushing tags..."
git push origin "v${VERSION}"

echo "==> Release complete."
