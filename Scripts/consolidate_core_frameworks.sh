#!/bin/bash

# Core Frameworks Consolidation Script for HealthAI-2030
# Consolidates duplicate core frameworks into single locations

echo "🏗️ Starting Core Frameworks Consolidation..."
echo "==========================================="

# Create consolidated core framework directories
CORE_BASE="Packages/Core"
echo "📁 Creating consolidated core framework structure at: $CORE_BASE"

mkdir -p "$CORE_BASE/HealthAI2030Core/Sources/HealthAI2030Core"
mkdir -p "$CORE_BASE/HealthAI2030Core/Tests/HealthAI2030CoreTests"
mkdir -p "$CORE_BASE/HealthAI2030UI/Sources/HealthAI2030UI"
mkdir -p "$CORE_BASE/HealthAI2030UI/Tests/HealthAI2030UITests"
mkdir -p "$CORE_BASE/HealthAI2030Networking/Sources/HealthAI2030Networking"
mkdir -p "$CORE_BASE/HealthAI2030Networking/Tests/HealthAI2030NetworkingTests"
mkdir -p "$CORE_BASE/HealthAI2030Foundation/Sources/HealthAI2030Foundation"
mkdir -p "$CORE_BASE/HealthAI2030Foundation/Tests/HealthAI2030FoundationTests"

# Function to create Package.swift for a core module
create_core_package() {
    local module_name=$1
    local package_path="$CORE_BASE/$module_name/Package.swift"
    
    cat > "$package_path" << EOF
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "$module_name",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
        .watchOS(.v11),
        .tvOS(.v18),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "$module_name",
            targets: ["$module_name"]
        )
    ],
    dependencies: [
        // Core dependencies will be added here
    ],
    targets: [
        .target(
            name: "$module_name",
            dependencies: [],
            path: "Sources/$module_name"
        ),
        .testTarget(
            name: "${module_name}Tests",
            dependencies: ["$module_name"],
            path: "Tests/${module_name}Tests"
        )
    ]
)
EOF
    echo "✅ Created Package.swift for $module_name"
}

# Function to consolidate files from multiple locations
consolidate_framework() {
    local framework=$1
    local dest_dir="$CORE_BASE/$framework/Sources/$framework"
    
    echo -e "\n📦 Consolidating $framework..."
    
    # List of potential source locations
    local sources=(
        "Sources/Features/$framework/Sources/$framework"
        "Frameworks/$framework/Sources/$framework"
        "Packages/$framework/Sources/$framework"
        "Apps/Packages/$framework/Sources/$framework"
        "Modules/Core/$framework/Sources/$framework"
    )
    
    local file_count=0
    
    for source in "${sources[@]}"; do
        if [ -d "$source" ]; then
            echo "  📋 Processing $source..."
            
            # Copy all Swift files
            find "$source" -name "*.swift" -type f | while read file; do
                filename=$(basename "$file")
                dest_file="$dest_dir/$filename"
                
                if [ ! -f "$dest_file" ]; then
                    cp "$file" "$dest_file"
                    ((file_count++))
                    echo "    ✓ Copied: $filename"
                else
                    # Compare files and keep the larger one (likely more complete)
                    size1=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
                    size2=$(stat -f%z "$dest_file" 2>/dev/null || stat -c%s "$dest_file" 2>/dev/null)
                    
                    if [ "$size1" -gt "$size2" ]; then
                        cp "$file" "$dest_file"
                        echo "    ⚠️  Replaced with larger version: $filename"
                    fi
                fi
            done
        fi
    done
    
    echo "  📊 Consolidated files in $framework"
}

# Create Package.swift for each core framework
create_core_package "HealthAI2030Core"
create_core_package "HealthAI2030UI"
create_core_package "HealthAI2030Networking"
create_core_package "HealthAI2030Foundation"

# Consolidate each framework
consolidate_framework "HealthAI2030Core"
consolidate_framework "HealthAI2030UI"
consolidate_framework "HealthAI2030Networking"
consolidate_framework "HealthAI2030Foundation"

# Special handling for HealthAI2030Core - remove sleep-related files
echo -e "\n🧹 Removing sleep-related files from HealthAI2030Core..."
find "$CORE_BASE/HealthAI2030Core/Sources/HealthAI2030Core" -name "*Sleep*.swift" -type f -exec rm {} \; -print | while read file; do
    echo "  ✓ Removed: $(basename $file)"
done

# Create main entry files if they don't exist
for framework in "HealthAI2030Core" "HealthAI2030UI" "HealthAI2030Networking" "HealthAI2030Foundation"; do
    main_file="$CORE_BASE/$framework/Sources/$framework/$framework.swift"
    if [ ! -f "$main_file" ]; then
        cat > "$main_file" << EOF
//
//  $framework.swift
//  HealthAI-2030
//
//  Main entry point for $framework
//

import Foundation

public struct $framework {
    public init() {}
    
    public static let version = "1.0.0"
    public static let moduleName = "$framework"
}
EOF
        echo "✅ Created main entry file for $framework"
    fi
done

# Create README for core frameworks
cat > "$CORE_BASE/README.md" << 'EOF'
# Core Frameworks

This directory contains the consolidated core frameworks for HealthAI-2030.

## Structure

- **HealthAI2030Core**: Core functionality and business logic
- **HealthAI2030UI**: Shared UI components and views
- **HealthAI2030Networking**: Network layer and API clients
- **HealthAI2030Foundation**: Foundation utilities and extensions

## Migration Notes

These frameworks have been consolidated from multiple locations:
- Sources/Features/
- Frameworks/
- Packages/
- Apps/Packages/
- Modules/Core/

All duplicate implementations have been merged, keeping the most complete versions.

## Dependencies

The dependency hierarchy is:
```
HealthAI2030Foundation (no dependencies)
    ↓
HealthAI2030Core (depends on Foundation)
    ↓
HealthAI2030Networking (depends on Core, Foundation)
    ↓
HealthAI2030UI (depends on all above)
```
EOF

# Summary
echo -e "\n📊 Consolidation Summary:"
for framework in "HealthAI2030Core" "HealthAI2030UI" "HealthAI2030Networking" "HealthAI2030Foundation"; do
    count=$(find "$CORE_BASE/$framework/Sources/$framework" -name "*.swift" | wc -l | tr -d ' ')
    size=$(du -sh "$CORE_BASE/$framework" | cut -f1)
    echo "$framework: $count files, $size"
done

echo -e "\n✅ Core frameworks consolidation complete!"
echo "📍 Location: $CORE_BASE"
echo -e "\n⚠️  Next steps:"
echo "1. Update Package.swift to reference consolidated frameworks"
echo "2. Remove old framework locations"
echo "3. Update all import paths"
echo "4. Fix dependency declarations"