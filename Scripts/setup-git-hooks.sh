#!/bin/bash

# Git Hooks Setup Script for HealthAI 2030

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
DOCC_HOOK_SCRIPT="$PROJECT_ROOT/Scripts/pre-commit-docc-check.sh"

# Ensure .git/hooks directory exists
mkdir -p "$HOOKS_DIR"

# Create pre-commit hook
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# Make the DocC check script executable
chmod +x "$DOCC_HOOK_SCRIPT"

# Create or update pre-commit hook
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash

# Run DocC comment validation
"$(dirname "$0")/../../Scripts/pre-commit-docc-check.sh"
exit $?
EOF

# Make pre-commit hook executable
chmod +x "$PRE_COMMIT_HOOK"

# Verify hook installation
if [ -x "$PRE_COMMIT_HOOK" ]; then
    echo -e "${GREEN}✅ DocC comment validation pre-commit hook installed successfully!${NC}"
    echo -e "${YELLOW}ℹ️  This hook will check documentation comments for public APIs before each commit.${NC}"
    echo -e "${YELLOW}ℹ️  See docs/DOCUMENTATION_GUIDELINES.md for documentation comment guidelines.${NC}"
else
    echo -e "${RED}❌ Failed to install pre-commit hook.${NC}"
    exit 1
fi

# Optional: Suggest running the setup script in project README or CONTRIBUTING guide
echo -e "\n${YELLOW}Tip: Add this script to your project setup instructions or README.${NC}"
echo -e "Developers can run ${GREEN}./Scripts/setup-git-hooks.sh${NC} to install Git hooks."

exit 0 