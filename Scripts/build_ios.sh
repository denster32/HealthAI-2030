#!/bin/bash
echo "📱 Building iOS app..."
xcodebuild -scheme HealthAI2030iOS -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build 