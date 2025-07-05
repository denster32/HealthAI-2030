#!/bin/bash
# Script to update imports in all moved Swift files to use new framework/module imports

find Frameworks -name "*.swift" -exec sed -i '' '1s;^;import HealthAI2030Core\n;' {} +
find Frameworks/SecurityComplianceKit/Sources -name "*.swift" -exec sed -i '' '1s;^;import SecurityComplianceKit\n;' {} +
find Frameworks/SleepIntelligenceKit/Sources -name "*.swift" -exec sed -i '' '1s;^;import SleepIntelligenceKit\n;' {} +
# Add more as you modularize
