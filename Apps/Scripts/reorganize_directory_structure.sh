#!/bin/bash

# reorganize_directory_structure.sh
# Script to reorganize the HealthAI 2030 repository into a modern, future-proof structure
# Phase 2: Consolidate documentation from docs/, infra/docs/, and HealthAI2030DocC/

# Exit on error, but handle file not found gracefully
set -e

# Create new directory structure for documentation
echo "Creating documentation directory structure..."
mkdir -p Documentation/ProjectOverview Documentation/DeveloperGuides Documentation/API Documentation/Features Documentation/Infrastructure Documentation/UserGuides Documentation/Historical
mkdir -p Archives

# Function to move files if they exist
echo "Moving documentation files..."
move_if_exists() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ] || [ -d "$src" ]; then
        echo "Moving $src to $dest"
        mv "$src" "$dest" || echo "Failed to move $src, continuing..."
    else
        echo "Skipping $src (not found)"
    fi
}

# Move root-level documentation files (already done in Phase 1, included for completeness)
move_if_exists "Asset_Generation_Instructions.md" "Documentation/DeveloperGuides/Asset_Generation_Instructions.md"
move_if_exists "Asset_Resource_References.md" "Documentation/DeveloperGuides/Asset_Resource_References.md"
move_if_exists "CODE_OF_CONDUCT.md" "Documentation/ProjectOverview/CODE_OF_CONDUCT.md"
move_if_exists "GITHUB_SETUP.md" "Documentation/DeveloperGuides/GITHUB_SETUP.md"
move_if_exists "SECURITY.md" "Documentation/ProjectOverview/SECURITY.md"
move_if_exists "PROJECT_AUDIT_REPORT.md" "Documentation/Historical/PROJECT_AUDIT_REPORT.md"
move_if_exists "PROJECT_CLEANUP_REPORT.md" "Documentation/Historical/PROJECT_CLEANUP_REPORT.md"
move_if_exists "TODO_FIXME_ANALYSIS.md" "Documentation/Historical/TODO_FIXME_ANALYSIS.md"
move_if_exists "code_review_issues.md" "Documentation/Historical/code_review_issues.md"

# Move docs/ content
if [ -d "docs" ]; then
    echo "Processing docs/ directory..."
    for file in docs/*.md; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file")
            move_if_exists "$file" "Documentation/DeveloperGuides/$base_name"
        fi
    done
fi

# Move relevant archived docs, archive others
if [ -d "docs/Archive" ]; then
    echo "Processing docs/Archive directory..."
    move_if_exists "docs/Archive/iOS18_Enhancements_Guide.md" "Documentation/DeveloperGuides/iOS18_Enhancements_Guide.md"
    move_if_exists "docs/Archive/Widget_Development_Guide.md" "Documentation/DeveloperGuides/Widget_Development_Guide.md"
    move_if_exists "docs/Archive/System_Intelligence_API_Reference.md" "Documentation/DeveloperGuides/System_Intelligence_API_Reference.md"
    # Move remaining archived docs to Archives
    for file in docs/Archive/*.md; do
        if [ -f "$file" ] && ! [[ "$file" =~ (iOS18_Enhancements_Guide|Widget_Development_Guide|System_Intelligence_API_Reference) ]]; then
            base_name=$(basename "$file")
            move_if_exists "$file" "Archives/$base_name"
        fi
    done
fi

# Move infra/docs content
if [ -d "infra/docs" ]; then
    echo "Processing infra/docs directory..."
    for file in infra/docs/*.md; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file")
            move_if_exists "$file" "Documentation/Infrastructure/$base_name"
        fi
    done
fi

# Move HealthAI2030DocC content
if [ -d "HealthAI2030DocC" ]; then
    echo "Processing HealthAI2030DocC directory..."
    for file in HealthAI2030DocC/*.md HealthAI2030DocC/*.docc HealthAI2030DocC/*.yaml; do
        if [ -f "$file" ]; then
            base_name=$(basename "$file")
            move_if_exists "$file" "Documentation/API/$base_name"
        fi
    done
    if [ -d "HealthAI2030DocC/Tutorials" ]; then
        for file in HealthAI2030DocC/Tutorials/*.md; do
            if [ -f "$file" ]; then
                base_name=$(basename "$file")
                move_if_exists "$file" "Documentation/UserGuides/$base_name"
            fi
        done
    fi
fi

echo "Phase 2: Documentation reorganization complete. Please review changes. Subsequent phases will address scripts, tests, infrastructure, and deletions." 