#!/bin/zsh
# Validate release readiness for HealthAI 2030
set -euo pipefail
IFS=$'\n\t'

trap 'echo "ERROR: Release validation failed" >&2' ERR

echo "==> Ensuring working tree is clean..."
if ! git diff-index --quiet HEAD --; then
  echo "ERROR: Uncommitted changes detected. Commit or stash before releasing."
  exit 1
fi

echo "==> Checking test coverage..."
COVERAGE=$(swift test --enable-code-coverage 2>&1 | grep 'lines covered' | awk '{print $1}')
echo "Coverage: $COVERAGE%"
if [[ $COVERAGE -lt 90 ]]; then
  echo "ERROR: Test coverage below 90%. Release blocked."
  exit 1
fi

echo "==> Checking for unresolved TODOs..."
if grep -r 'TODO' . --include='*.swift'; then
  echo "ERROR: Unresolved TODOs found. Release blocked."
  exit 1
fi

echo "==> All checks passed. Ready for release."
