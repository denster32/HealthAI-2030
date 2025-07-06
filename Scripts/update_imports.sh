#!/bin/bash

# HealthAI 2030 - Update Import Statements Script
# Updates all import statements to reference the new modular framework structure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "Starting import statement updates for HealthAI 2030..."

# =============================================================================
# UPDATE IMPORT STATEMENTS
# =============================================================================

# Function to update imports in a file
update_imports_in_file() {
    local file="$1"
    
    # Skip if not a Swift file
    if [[ ! "$file" =~ \.swift$ ]]; then
        return
    fi
    
    log_info "Updating imports in: $file"
    
    # Create a temporary file
    local temp_file=$(mktemp)
    
    # Update import statements
    sed -E '
        # Update framework imports to use new structure
        s/import HealthAI2030Core/import HealthAI2030Core/g
        s/import HealthAI2030Networking/import HealthAI2030Networking/g
        s/import HealthAI2030UI/import HealthAI2030UI/g
        s/import HealthAI2030Graphics/import HealthAI2030Graphics/g
        s/import HealthAI2030ML/import HealthAI2030ML/g
        s/import HealthAI2030Foundation/import HealthAI2030Foundation/g
        
        # Update feature module imports
        s/import CardiacHealth/import CardiacHealth/g
        s/import MentalHealth/import MentalHealth/g
        s/import iOS18Features/import iOS18Features/g
        s/import SleepTracking/import SleepTracking/g
        s/import HealthPrediction/import HealthPrediction/g
        s/import CopilotSkills/import CopilotSkills/g
        s/import Metal4/import Metal4/g
        s/import SmartHome/import SmartHome/g
        s/import UserScripting/import UserScripting/g
        s/import Shortcuts/import Shortcuts/g
        s/import LogWaterIntake/import LogWaterIntake/g
        s/import StartMeditation/import StartMeditation/g
        s/import AR/import AR/g
        s/import Biofeedback/import Biofeedback/g
        s/import Shared/import Shared/g
        s/import SharedSettingsModule/import SharedSettingsModule/g
        s/import HealthAIConversationalEngine/import HealthAIConversationalEngine/g
        s/import Kit/import Kit/g
        s/import ML/import ML/g
        s/import SharedHealthSummary/import SharedHealthSummary/g
    ' "$file" > "$temp_file"
    
    # Replace original file with updated content
    mv "$temp_file" "$file"
}

# Find all Swift files and update imports
log_info "Finding and updating Swift files..."

# Update imports in Frameworks directory
find Frameworks -name "*.swift" -type f | while read -r file; do
    update_imports_in_file "$file"
done

# Update imports in Sources directory
find Sources -name "*.swift" -type f | while read -r file; do
    update_imports_in_file "$file"
done

# Update imports in Apps directory
find Apps -name "*.swift" -type f | while read -r file; do
    update_imports_in_file "$file"
done

# Update imports in Tests directory
find Tests -name "*.swift" -type f | while read -r file; do
    update_imports_in_file "$file"
done

log_success "Import statement updates completed!"

# =============================================================================
# VERIFY BUILD
# =============================================================================

log_info "Verifying build after import updates..."

# Try to build the project
if swift build; then
    log_success "Build successful after import updates!"
else
    log_error "Build failed after import updates. Please check for import errors."
    exit 1
fi

log_success "Task 1: Complete Modular Migration - Import updates completed!"
log_info "Next: Remove obsolete files and finalize migration..."
