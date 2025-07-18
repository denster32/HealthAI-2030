#!/bin/bash

# Documentation Cleanup Script for HealthAI-2030
# Removes obsolete completion reports, agent artifacts, and legacy files

echo "🧹 Starting Documentation Cleanup..."
echo "===================================="

# Create backup directory for removed files
BACKUP_DIR="Documentation/Archive/Removed_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 Created backup directory: $BACKUP_DIR"

# Function to safely remove files with backup
safe_remove() {
    local file=$1
    local reason=$2
    
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "$BACKUP_DIR/$(basename "$file")"
        # Remove original
        rm "$file"
        echo "  🗑️  Removed: $file ($reason)"
        return 0
    else
        echo "  ⚠️  Not found: $file"
        return 1
    fi
}

echo -e "\n📋 Phase 1: Removing Completion Reports..."
removed_count=0

# Remove completion reports from docs/
completion_reports=(
    "docs/FINAL_COMPREHENSIVE_COMPLETION_REPORT.md"
    "docs/FINAL_COMPREHENSIVE_COMPLETION_REPORT_V2.md"
    "docs/ADVANCED_BIOMETRIC_FUSION_COMPLETION_REPORT.md"
    "docs/ADVANCED_CLINICAL_DECISION_SUPPORT_COMPLETION_REPORT.md"
    "docs/ADVANCED_HEALTH_ANALYTICS_COMPLETION_REPORT.md"
    "docs/ADVANCED_HEALTH_DATA_INTEGRATION_COMPLETION_REPORT.md"
    "docs/ADVANCED_HEALTH_DATA_PRIVACY_COMPLETION_REPORT.md"
    "docs/ADVANCED_HEALTH_DEVICE_INTEGRATION_COMPLETION_REPORT.md"
    "docs/ADVANCED_HEALTH_RESEARCH_COMPLETION_REPORT.md"
    "docs/ADVANCED_MENTAL_HEALTH_COMPLETION_REPORT.md"
    "docs/ADVANCED_SLEEP_INTELLIGENCE_COMPLETION_REPORT.md"
    "docs/REAL_TIME_COACHING_COMPLETION_REPORT.md"
    "docs/FEATURE_IMPLEMENTATION_REPORT.md"
)

for file in "${completion_reports[@]}"; do
    if safe_remove "$file" "completion report"; then
        ((removed_count++))
    fi
done

echo -e "\n📋 Phase 2: Removing Agent Task Files..."

# Remove agent task files
agent_files=(
    "docs/AGENT_TASK_MANIFEST.md"
    "Tests/AGENT_4_COMPLETION_REPORT.md"
    "Tests/AGENT_4_FINAL_MISSION_COMPLETE.md"
)

for file in "${agent_files[@]}"; do
    if safe_remove "$file" "agent artifact"; then
        ((removed_count++))
    fi
done

echo -e "\n📋 Phase 3: Removing Final/Validation Files..."

# Remove final validation files from Tests/
final_files=(
    "Tests/FINAL_EXECUTION_VALIDATION.md"
    "Tests/FINAL_HANDOVER_SUMMARY.md"
    "Tests/FINAL_TESTING_SUMMARY.md"
    "Tests/FINAL_VALIDATION_CHECKLIST.md"
    "Tests/FINAL_VALIDATION_REPORT.md"
    "Tests/COMPREHENSIVE_IMPROVEMENT_PLAN.md"
    "Tests/COMPREHENSIVE_IMPROVEMENT_SUMMARY.md"
    "Tests/COMPREHENSIVE_TEST_STATUS_REPORT.md"
    "Tests/IMMEDIATE_ACTION_PLAN.md"
)

for file in "${final_files[@]}"; do
    if safe_remove "$file" "final validation artifact"; then
        ((removed_count++))
    fi
done

echo -e "\n📋 Phase 4: Removing Legacy Development Files..."

# Remove other legacy files
legacy_files=(
    "docs/DEPLOYMENT_READY_SUMMARY.md"
    "docs/PlatformSpecificImplementationReport.md"
    "docs/Task_Completion_Checklist.md"
    "docs/DOCUMENTATION_IMPROVEMENTS_LOG.md"
)

for file in "${legacy_files[@]}"; do
    if safe_remove "$file" "legacy development file"; then
        ((removed_count++))
    fi
done

echo -e "\n📋 Phase 5: Removing Redundant Files..."

# Remove files that are duplicates or redundant
redundant_files=(
    "docs/TECH_DEBT_ASSESSMENT.md"
    "Tests/BugTriageSystem.md"
    "Tests/TEST_METRICS_DASHBOARD.md"
    "Tests/TestCoverageAnalysisReport.md"
)

for file in "${redundant_files[@]}"; do
    if safe_remove "$file" "redundant content"; then
        ((removed_count++))
    fi
done

# Summary
echo -e "\n📊 Cleanup Summary:"
echo "Files removed: $removed_count"
echo "Backup location: $BACKUP_DIR"
echo "$(ls -la "$BACKUP_DIR" | wc -l | tr -d ' ') files backed up"

echo -e "\n✅ Documentation cleanup complete!"
echo "📍 Backup directory: $BACKUP_DIR"
echo -e "\n⚠️  Next steps:"
echo "1. Review backup directory if you need to recover any files"
echo "2. Proceed with documentation reorganization"
echo "3. Create new consolidated structure"