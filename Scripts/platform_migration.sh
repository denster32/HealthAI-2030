#!/bin/zsh
# Additional migration for platform-specific files and cleanup
set -e

# Move macOS and tvOS app entry points to App/
if [ -f "HealthAI 2030 macOS/HealthAI2030MacApp.swift" ]; then
  mv "HealthAI 2030 macOS/HealthAI2030MacApp.swift" App/
fi
if [ -f "HealthAI 2030 tvOS/HealthAI2030TVApp.swift" ]; then
  mv "HealthAI 2030 tvOS/HealthAI2030TVApp.swift" App/
fi

# Move any remaining platform-specific files to Features or Shared as appropriate
# Example: Move all .swift files from macOS and tvOS folders to App/ or Features/ as needed
for f in HealthAI\ 2030\ macOS/*.swift; do
  [ -e "$f" ] && mv "$f" App/
  done
for f in HealthAI\ 2030\ tvOS/*.swift; do
  [ -e "$f" ] && mv "$f" App/
  done

# Remove now-empty macOS and tvOS folders
rmdir "HealthAI 2030 macOS" 2>/dev/null || true
rmdir "HealthAI 2030 tvOS" 2>/dev/null || true

# Final message
echo "Platform-specific migration and cleanup complete."
