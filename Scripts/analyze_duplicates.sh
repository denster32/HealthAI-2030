#!/bin/bash

# HealthAI-2030 Duplicate Analysis Script
# Identifies duplicate files and redundant implementations

echo "🔍 Analyzing HealthAI-2030 for duplicate implementations..."
echo "================================================"

# Function to find duplicate Swift files by name
find_duplicates() {
    echo -e "\n📁 Finding duplicate Swift files..."
    find . -name "*.swift" -type f | grep -v ".build" | grep -v "build/" | \
        sed 's|.*/||' | sort | uniq -c | sort -rn | \
        awk '$1 > 1 {print $1 " duplicates: " $2}'
}

# Function to analyze sleep modules
analyze_sleep() {
    echo -e "\n😴 Analyzing Sleep Module Distribution..."
    echo "Sleep files by directory:"
    find . -name "*.swift" -type f | grep -i sleep | grep -v ".build" | \
        sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
}

# Function to analyze framework duplicates
analyze_frameworks() {
    echo -e "\n📦 Analyzing Framework Duplicates..."
    for framework in "HealthAI2030Core" "HealthAI2030UI" "HealthAI2030Networking" "HealthAI2030Foundation"; do
        echo -e "\n$framework locations:"
        find . -type d -name "$framework" | grep -v ".build"
    done
}

# Function to analyze SmartHome modules
analyze_smarthome() {
    echo -e "\n🏠 Analyzing SmartHome Module Distribution..."
    echo "SmartHome files:"
    find . -name "*.swift" -type f | grep -i smarthome | grep -v ".build" | sort
}

# Function to count lines of code
count_loc() {
    echo -e "\n📊 Lines of Code Analysis..."
    echo "Sleep-related code:"
    find . -name "*.swift" -type f | grep -i sleep | grep -v ".build" | xargs wc -l | tail -1
    
    echo -e "\nSmartHome-related code:"
    find . -name "*.swift" -type f | grep -i smarthome | grep -v ".build" | xargs wc -l | tail -1
}

# Function to check for identical files
check_identical() {
    echo -e "\n🔄 Checking for identical files..."
    echo "Calculating MD5 hashes for potential duplicates..."
    
    # Create temp directory for hashes
    mkdir -p /tmp/healthai_hashes
    
    # Generate hashes for all Swift files
    find . -name "*.swift" -type f | grep -v ".build" | while read file; do
        md5sum "$file" >> /tmp/healthai_hashes/all_hashes.txt
    done
    
    # Find files with same hash
    echo "Files with identical content:"
    sort /tmp/healthai_hashes/all_hashes.txt | uniq -w32 -d
    
    # Cleanup
    rm -rf /tmp/healthai_hashes
}

# Execute all analyses
find_duplicates
analyze_sleep
analyze_frameworks
analyze_smarthome
count_loc
check_identical

echo -e "\n✅ Analysis complete!"
echo "================================================"