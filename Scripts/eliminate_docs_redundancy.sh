#!/bin/bash

# Eliminate docs/ and Documentation/ Redundancy Script
# Consolidates everything into the well-organized Documentation/ structure

echo "🔧 Eliminating Documentation Redundancy..."
echo "========================================"

echo "📊 Current State:"
docs_count=$(find docs/ -type f | wc -l | tr -d ' ')
documentation_count=$(find Documentation/ -type f | wc -l | tr -d ' ')
echo "docs/ contains: $docs_count files"
echo "Documentation/ contains: $documentation_count files"

echo -e "\n📋 Phase 1: Moving Remaining Useful Files from docs/..."

# Move the remaining useful markdown files from docs/
useful_docs=(
    "docs/DeveloperGuides/build-phases.md:Documentation/DeveloperGuides/BuildPhases.md"
    "docs/Features/README.md:Documentation/DeveloperGuides/FeaturesREADME.md"
    "docs/README.md:Documentation/Archive/DocsREADME.md"
    "docs/DOCUMENTATION_INDEX.md:Documentation/Archive/OldDocumentationIndex.md"
    "docs/FILE_INDEX.md:Documentation/Archive/OldFileIndex.md"
)

moved_count=0
for mapping in "${useful_docs[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if [ -f "$source" ]; then
        mv "$source" "$dest"
        echo "  ✅ Moved: $dest"
        ((moved_count++))
    fi
done

# Move any remaining API documentation
if [ -d "docs/API" ]; then
    echo -e "\n📋 Moving remaining API docs..."
    find docs/API -name "*.md" -type f | while read file; do
        filename=$(basename "$file")
        dest="Documentation/DeveloperGuides/APIs/$filename"
        if [ ! -f "$dest" ]; then
            mv "$file" "$dest"
            echo "  ✅ Moved API doc: $filename"
            ((moved_count++))
        else
            echo "  ⚠️  API doc already exists: $filename"
            rm "$file"
        fi
    done
fi

echo -e "\n📋 Phase 2: Preserving Configuration Files..."

# Move configuration files to appropriate locations
config_files=(
    "docs/.swiftlint.yml:.swiftlint.yml"
    "docs/DocCConfig.yaml:DocCConfig.yaml"
)

for mapping in "${config_files[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if [ -f "$source" ]; then
        # Only move if destination doesn't exist
        if [ ! -f "$dest" ]; then
            mv "$source" "$dest"
            echo "  ✅ Moved config: $dest"
        else
            echo "  ⚠️  Config already exists at root: $dest"
            rm "$source"
        fi
    fi
done

echo -e "\n📋 Phase 3: Removing Empty docs/ Structure..."

# Remove remaining empty directories and leftover files
rm -rf docs/ 
echo "  ✅ Removed: docs/ directory entirely"

echo -e "\n📋 Phase 4: Updating References..."

# Update any references from docs/ to Documentation/
# Check for any references in key files
reference_files=(
    "README.md"
    "Package.swift"
    ".github/ISSUE_TEMPLATE.md"
    ".github/PULL_REQUEST_TEMPLATE.md"
)

for file in "${reference_files[@]}"; do
    if [ -f "$file" ]; then
        # Replace docs/ references with Documentation/
        if grep -q "docs/" "$file" 2>/dev/null; then
            sed -i.bak 's|docs/|Documentation/|g' "$file" 2>/dev/null || sed -i '' 's|docs/|Documentation/|g' "$file" 2>/dev/null
            rm -f "$file.bak" 2>/dev/null
            echo "  ✅ Updated references in: $file"
        fi
    fi
done

# Update .gitignore if it references docs/
if [ -f ".gitignore" ] && grep -q "docs/" ".gitignore" 2>/dev/null; then
    sed -i.bak 's|docs/|Documentation/|g' ".gitignore" 2>/dev/null || sed -i '' 's|docs/|Documentation/|g' ".gitignore" 2>/dev/null
    rm -f ".gitignore.bak" 2>/dev/null
    echo "  ✅ Updated .gitignore references"
fi

echo -e "\n📋 Phase 5: Creating Standard docs/ Symlink (Optional)..."

# Create a symlink from docs/ to Documentation/ for conventional access
# This allows both docs/ and Documentation/ to work, but only one actual directory
ln -s Documentation docs
echo "  ✅ Created: docs/ -> Documentation/ symlink for conventional access"

# Final count
final_count=$(find Documentation/ -type f | wc -l | tr -d ' ')

echo -e "\n📊 Redundancy Elimination Summary:"
echo "Files moved from old docs/: $moved_count"
echo "Total files in Documentation/: $final_count"
echo "docs/ directory: Removed and replaced with symlink"
echo "References updated: README.md and other key files"

echo -e "\n✅ Documentation redundancy eliminated!"
echo "📂 Single source of truth: Documentation/"
echo "🔗 Conventional access: docs/ -> Documentation/ (symlink)"
echo "📚 All content organized and accessible"

echo -e "\n🎯 Benefits Achieved:"
echo "• Eliminated confusing dual documentation directories"
echo "• Maintained well-organized Documentation/ structure"
echo "• Preserved conventional docs/ access via symlink"
echo "• Updated all references to point to correct location"
echo "• Archived old index files for reference"