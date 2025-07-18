#!/bin/bash

# Sleep Module Consolidation Script for HealthAI-2030
# This script consolidates all sleep implementations into a single module

echo "🌙 Starting Sleep Module Consolidation..."
echo "========================================"

# Create consolidated sleep module directory
CONSOLIDATED_PATH="Packages/Features/Sleep"
echo "📁 Creating consolidated sleep module at: $CONSOLIDATED_PATH"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep/Models"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep/Analytics"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep/ML"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep/Managers"
mkdir -p "$CONSOLIDATED_PATH/Sources/Sleep/Views"
mkdir -p "$CONSOLIDATED_PATH/Tests/SleepTests"

# Create Package.swift for the consolidated module
cat > "$CONSOLIDATED_PATH/Package.swift" << 'EOF'
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Sleep",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18)
    ],
    products: [
        .library(
            name: "Sleep",
            targets: ["Sleep"]
        )
    ],
    dependencies: [
        .package(path: "../../Core/HealthAI2030Core"),
        .package(path: "../../Core/HealthAI2030UI"),
        .package(path: "../HealthMetrics")
    ],
    targets: [
        .target(
            name: "Sleep",
            dependencies: [
                "HealthAI2030Core",
                "HealthAI2030UI",
                "HealthMetrics"
            ],
            path: "Sources/Sleep"
        ),
        .testTarget(
            name: "SleepTests",
            dependencies: ["Sleep"],
            path: "Tests/SleepTests"
        )
    ]
)
EOF

echo "✅ Created Package.swift for consolidated Sleep module"

# Function to copy unique files
copy_unique_files() {
    local source_dir=$1
    local dest_subdir=$2
    
    echo "📋 Processing $source_dir..."
    
    if [ -d "$source_dir" ]; then
        find "$source_dir" -name "*.swift" -type f | while read file; do
            filename=$(basename "$file")
            dest_dir="$CONSOLIDATED_PATH/Sources/Sleep/$dest_subdir"
            dest_file="$dest_dir/$filename"
            
            # If file doesn't exist in destination, copy it
            if [ ! -f "$dest_file" ]; then
                cp "$file" "$dest_file"
                echo "  ✓ Copied: $filename"
            else
                # If file exists, check if they're different
                if ! cmp -s "$file" "$dest_file"; then
                    echo "  ⚠️  Conflict: $filename (keeping newer version)"
                    # Keep the file with more recent modification time
                    if [ "$file" -nt "$dest_file" ]; then
                        cp "$file" "$dest_file"
                    fi
                fi
            fi
        done
    fi
}

# Consolidate from all sleep locations
echo -e "\n📦 Consolidating sleep implementations..."

# Models
copy_unique_files "Apps/MainApp/SleepTracking/Models" "Models"
copy_unique_files "Frameworks/SleepTracking/Sources/SleepTracking/Models" "Models"

# Analytics
copy_unique_files "Apps/MainApp/SleepTracking/Analytics" "Analytics"
copy_unique_files "Frameworks/SleepTracking/Sources/SleepTracking/Analytics" "Analytics"

# ML
copy_unique_files "Apps/MainApp/SleepTracking/ML" "ML"
copy_unique_files "Frameworks/SleepTracking/Sources/SleepTracking/ML" "ML"

# Managers
copy_unique_files "Apps/MainApp/SleepTracking/Managers" "Managers"
copy_unique_files "Frameworks/SleepTracking/Sources/SleepTracking/Managers" "Managers"

# Views
copy_unique_files "Apps/MainApp/SleepTracking/Views" "Views"
copy_unique_files "Frameworks/SleepTracking/Sources/SleepTracking/Views" "Views"

# Core sleep managers from HealthAI2030Core
echo -e "\n📋 Processing Core sleep managers..."
for file in Sources/Features/HealthAI2030Core/Sources/HealthAI2030Core/*Sleep*.swift; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        cp "$file" "$CONSOLIDATED_PATH/Sources/Sleep/Managers/$filename"
        echo "  ✓ Copied: $filename from Core"
    fi
done

# Advanced features from FeatureModules
echo -e "\n📋 Processing advanced sleep features..."
if [ -d "Packages/FeatureModules/SleepOptimization/Sources" ]; then
    cp -r Packages/FeatureModules/SleepOptimization/Sources/* "$CONSOLIDATED_PATH/Sources/Sleep/"
    echo "  ✓ Copied advanced sleep optimization features"
fi

# Create main Sleep.swift file
cat > "$CONSOLIDATED_PATH/Sources/Sleep/Sleep.swift" << 'EOF'
//
//  Sleep.swift
//  HealthAI-2030
//
//  Consolidated Sleep Module
//

import Foundation

/// The main entry point for the consolidated Sleep module
public struct Sleep {
    public init() {}
    
    public static let version = "1.0.0"
    public static let moduleName = "Sleep"
}
EOF

echo "✅ Created main Sleep.swift file"

# Create README for the module
cat > "$CONSOLIDATED_PATH/README.md" << 'EOF'
# Sleep Module

This is the consolidated Sleep module for HealthAI-2030, combining all sleep-related functionality into a single, well-organized package.

## Structure

- **Models/**: Data models for sleep tracking
- **Analytics/**: Sleep analysis and insights
- **ML/**: Machine learning models for sleep prediction
- **Managers/**: Core sleep management functionality
- **Views/**: UI components for sleep features

## Migration Notes

This module consolidates functionality from:
- Apps/MainApp/SleepTracking/
- Frameworks/SleepTracking/
- Packages/FeatureModules/SleepOptimization/
- Various sleep managers from Core

All duplicate code has been removed and the best implementations have been preserved.
EOF

echo "✅ Created README.md"

# Count consolidated files
echo -e "\n📊 Consolidation Summary:"
echo "Models: $(find $CONSOLIDATED_PATH/Sources/Sleep/Models -name "*.swift" | wc -l | tr -d ' ') files"
echo "Analytics: $(find $CONSOLIDATED_PATH/Sources/Sleep/Analytics -name "*.swift" | wc -l | tr -d ' ') files"
echo "ML: $(find $CONSOLIDATED_PATH/Sources/Sleep/ML -name "*.swift" | wc -l | tr -d ' ') files"
echo "Managers: $(find $CONSOLIDATED_PATH/Sources/Sleep/Managers -name "*.swift" | wc -l | tr -d ' ') files"
echo "Views: $(find $CONSOLIDATED_PATH/Sources/Sleep/Views -name "*.swift" | wc -l | tr -d ' ') files"

echo -e "\n✅ Sleep module consolidation complete!"
echo "📍 Location: $CONSOLIDATED_PATH"
echo -e "\n⚠️  Next steps:"
echo "1. Update Package.swift to reference the new consolidated module"
echo "2. Remove old sleep implementations"
echo "3. Update all import statements"
echo "4. Run tests to ensure functionality"