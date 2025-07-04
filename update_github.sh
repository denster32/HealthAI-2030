#!/bin/bash

# Check if Git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Please install Git first."
    exit 1
fi

# Initialize Git repository if it doesn't exist
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
fi

# Create a new branch for iOS 18 optimization
echo "Creating a new branch for iOS 18 optimization..."
git checkout -b ios18-optimization 2>/dev/null || git checkout -b ios18-optimization

# Add all files to Git
echo "Adding all files to Git..."
git add .

# Commit the changes
echo "Committing iOS 18 optimization changes..."
git commit -m "Optimize entire codebase for iOS 18

- Update all platforms (iOS, watchOS, macOS, tvOS) to target iOS 18+ only
- Replace ObservableObject with @Observable macro
- Integrate SwiftData for persistence
- Add Swift concurrency with async/await patterns
- Implement Live Activities and Interactive Widgets
- Add MetricKit integration for performance monitoring
- Enhance background processing capabilities
- Remove backward compatibility with iOS 17"

echo "Changes committed successfully!"

# Instructions for pushing to GitHub
echo ""
echo "To push these changes to GitHub, run the following commands:"
echo "1. git remote add origin https://github.com/YOUR_USERNAME/HealthAI-2030.git"
echo "2. git push -u origin ios18-optimization"
