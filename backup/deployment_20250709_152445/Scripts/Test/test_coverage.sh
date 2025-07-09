#!/bin/sh
xcodebuild test -scheme "HealthAI 2030" -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES
