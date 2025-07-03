#!/bin/sh
brew install swiftlint swiftformat || true
chmod +x .git/hooks/pre-commit
