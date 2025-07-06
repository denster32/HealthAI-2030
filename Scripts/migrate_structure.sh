#!/bin/zsh
# HealthAI 2030 Project File Migration Script
# This script will move files to the new modular structure.

set -e

# 1. App Entry Points
mkdir -p App
mv "HealthAI 2030 macOS/HealthAI2030MacApp.swift" App/ 2>/dev/null || true
mv "HealthAI 2030 tvOS/HealthAI2030TVApp.swift" App/ 2>/dev/null || true
mv "HealthAI 2030/Platforms/macOS/HealthAI2030MacApp.swift" App/ 2>/dev/null || true

# 2. Features
mkdir -p Features/SleepTracking/Models Features/SleepTracking/Views Features/SleepTracking/ViewModels Features/SleepTracking/Services
mkdir -p Features/HealthPrediction/Models Features/HealthPrediction/Views Features/HealthPrediction/ViewModels Features/HealthPrediction/Services
mkdir -p Features/UserScripting

mv "HealthAI 2030/Features/Sleep"/* Features/SleepTracking/ 2>/dev/null || true
mv "HealthAI 2030/Features/HealthPrediction"/* Features/HealthPrediction/ 2>/dev/null || true
mv "HealthAI 2030/UserScripting"/* Features/UserScripting/ 2>/dev/null || true
mv "HealthAI 2030/Views/Sleep"/* Features/SleepTracking/Views/ 2>/dev/null || true
mv "HealthAI 2030/Models/HealthDataModels.swift" Features/SleepTracking/Models/ 2>/dev/null || true
mv "HealthAI 2030/Views/AdvancedAnalyticsDashboardView.swift" Features/HealthPrediction/Views/ 2>/dev/null || true
mv "HealthAI 2030/Widgets/HeartRateWidget.swift" Features/HealthPrediction/Views/ 2>/dev/null || true

# 3. Shared
mkdir -p Shared/Components Shared/Extensions Shared/Utilities
mv "HealthAI 2030/UIComponents.swift" Shared/Components/ 2>/dev/null || true
mv "HealthAI 2030/Helpers/Security/E2EE.swift" Shared/Utilities/ 2>/dev/null || true
mv "HealthAI 2030/Utilities/AccessibilityHelper.swift" Shared/Utilities/ 2>/dev/null || true
# Move all .swift files from Extensions if any
if [ -d "HealthAI 2030/Extensions" ]; then
  mv HealthAI\ 2030/Extensions/*.swift Shared/Extensions/ 2>/dev/null || true
fi

# 4. Resources
mkdir -p Shared/Resources
mv "HealthAI 2030/Assets.xcassets" Shared/Resources/ 2>/dev/null || true
mv "HealthAI 2030/Resources"/* Shared/Resources/ 2>/dev/null || true

# 5. Tests
mkdir -p Tests/Features/SleepTracking Tests/Features/HealthPrediction Tests/Shared
mv "HealthAI 2030Tests"/* Tests/Features/ 2>/dev/null || true
mv "HealthAI 2030UITests"/* Tests/Features/ 2>/dev/null || true

# 6. Remove Redundant/Empty Folders
rmdir "HealthAI 2030/Helpers/Security" 2>/dev/null || true
rmdir "HealthAI 2030/Helpers" 2>/dev/null || true
rmdir "HealthAI 2030/UIComponents" 2>/dev/null || true
rmdir "HealthAI 2030/Extensions" 2>/dev/null || true
rmdir "HealthAI 2030/Utilities" 2>/dev/null || true
rmdir "HealthAI 2030/Views/Sleep" 2>/dev/null || true
rmdir "HealthAI 2030/Views" 2>/dev/null || true
rmdir "HealthAI 2030/Models" 2>/dev/null || true
rmdir "HealthAI 2030/Widgets" 2>/dev/null || true
rmdir "HealthAI 2030/Features/Sleep" 2>/dev/null || true
rmdir "HealthAI 2030/Features/HealthPrediction" 2>/dev/null || true
rmdir "HealthAI 2030/Features" 2>/dev/null || true
rmdir "HealthAI 2030/Resources" 2>/dev/null || true
rmdir "HealthAI 2030/Platforms/macOS" 2>/dev/null || true
rmdir "HealthAI 2030/Platforms/AppleTV" 2>/dev/null || true
rmdir "HealthAI 2030/Platforms/WatchKit Extension" 2>/dev/null || true
rmdir "HealthAI 2030/Platforms" 2>/dev/null || true

# Done
echo "Migration complete. Please update your Xcode project references."
