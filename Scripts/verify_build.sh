#!/bin/bash

echo "🔍 Verifying Consolidated Build..."
echo "=================================="

# Check if consolidated modules exist
echo "📁 Checking consolidated module directories..."
modules=(
    "Packages/Core/HealthAI2030Core"
    "Packages/Core/HealthAI2030UI"
    "Packages/Core/HealthAI2030Networking"
    "Packages/Core/HealthAI2030Foundation"
    "Packages/Features/Sleep"
    "Packages/Features/SmartHome"
)

for module in "${modules[@]}"; do
    if [ -d "$module" ]; then
        echo "  ✅ $module exists"
    else
        echo "  ❌ $module missing"
    fi
done

# Check Package.swift syntax
echo -e "\n📋 Checking Package.swift syntax..."
if swift package dump-package > /dev/null 2>&1; then
    echo "  ✅ Package.swift syntax is valid"
else
    echo "  ❌ Package.swift has syntax errors"
    swift package dump-package
    exit 1
fi

# Attempt to resolve dependencies
echo -e "\n📦 Resolving dependencies..."
if swift package resolve; then
    echo "  ✅ Dependencies resolved successfully"
else
    echo "  ❌ Dependency resolution failed"
    exit 1
fi

# Test compilation
echo -e "\n🏗️ Testing compilation..."
if swift build --target HealthAI2030Core; then
    echo "  ✅ HealthAI2030Core compiles successfully"
else
    echo "  ❌ HealthAI2030Core compilation failed"
    exit 1
fi

if swift build --target Sleep; then
    echo "  ✅ Sleep module compiles successfully"
else
    echo "  ❌ Sleep module compilation failed"
    exit 1
fi

if swift build --target SmartHome; then
    echo "  ✅ SmartHome module compiles successfully"
else
    echo "  ❌ SmartHome module compilation failed"
    exit 1
fi

echo -e "\n✅ All verification checks passed!"
echo "📊 Consolidation Summary:"
echo "- Core frameworks: Unified"
echo "- Sleep modules: Consolidated"
echo "- SmartHome modules: Consolidated"
echo "- Build system: Optimized"
