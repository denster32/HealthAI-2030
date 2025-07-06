#!/bin/bash

# DocC Comment Pre-Commit Validation Script

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a Swift file has documentation comments
check_docc_comments() {
    local file="$1"
    local public_declarations=$(grep -E "^(public|open)\s+(class|struct|enum|protocol|func|var|let)" "$file")
    
    if [ -n "$public_declarations" ]; then
        # Check if public declarations have documentation comments
        local undocumented_declarations=$(echo "$public_declarations" | while read -r declaration; do
            # Get the line number of the declaration
            line_num=$(grep -n "$declaration" "$file" | cut -d: -f1)
            
            # Check if the line before the declaration starts with ///, indicating a DocC comment
            prev_line=$((line_num - 1))
            comment_line=$(sed -n "${prev_line}p" "$file")
            
            if [[ ! "$comment_line" =~ ^///  ]]; then
                echo "$declaration"
            fi
        done)
        
        if [ -n "$undocumented_declarations" ]; then
            echo -e "${RED}Error: The following public declarations are missing DocC comments:${NC}"
            echo "$undocumented_declarations"
            return 1
        fi
    fi
    
    return 0
}

# Main script
main() {
    local staged_swift_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')
    
    if [ -z "$staged_swift_files" ]; then
        echo -e "${GREEN}No Swift files staged. Skipping DocC comment check.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Checking DocC comments for staged Swift files...${NC}"
    
    local failed=0
    for file in $staged_swift_files; do
        if [ -f "$file" ]; then
            check_docc_comments "$file"
            if [ $? -ne 0 ]; then
                failed=1
            fi
        fi
    done
    
    if [ $failed -eq 1 ]; then
        echo -e "${RED}DocC comment validation failed. Please add documentation comments to public APIs.${NC}"
        echo -e "${YELLOW}Refer to docs/DOCUMENTATION_GUIDELINES.md for guidance.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}DocC comment validation passed successfully!${NC}"
    exit 0
}

# Run the main script
main 