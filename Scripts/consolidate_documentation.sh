#!/bin/bash

# Documentation Consolidation Script for HealthAI-2030
# Moves existing files into the new optimized structure

echo "📦 Starting Documentation Consolidation..."
echo "=========================================="

# Function to move file with conflict resolution
move_with_consolidation() {
    local source=$1
    local dest=$2
    local category=$3
    
    if [ ! -f "$source" ]; then
        echo "  ⚠️  Source not found: $source"
        return 1
    fi
    
    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    if [ -f "$dest" ]; then
        echo "  ⚠️  Conflict: $dest already exists, comparing sizes..."
        # Keep the larger file (likely more comprehensive)
        size1=$(stat -f%z "$source" 2>/dev/null || stat -c%s "$source" 2>/dev/null)
        size2=$(stat -f%z "$dest" 2>/dev/null || stat -c%s "$dest" 2>/dev/null)
        
        if [ "$size1" -gt "$size2" ]; then
            mv "$source" "$dest"
            echo "  ✅ Replaced with larger version: $dest ($category)"
        else
            rm "$source"
            echo "  ✅ Kept existing (larger): $dest ($category)"
        fi
    else
        mv "$source" "$dest"
        echo "  ✅ Moved: $dest ($category)"
    fi
    
    return 0
}

moved_count=0

echo -e "\n📋 Phase 1: Moving User Guides..."

# Move user-focused guides
user_guides=(
    "docs/UserGuides/GettingStarted.md:Documentation/UserGuides/GettingStarted.md"
    "docs/onboarding.md:Documentation/UserGuides/Onboarding.md"
    "docs/UserOnboardingAndHelp.md:Documentation/UserGuides/UserOnboardingAndHelp.md"
    "docs/UserTrainingMaterials.md:Documentation/UserGuides/UserTrainingMaterials.md"
    "docs/feedback_support.md:Documentation/UserGuides/FeedbackSupport.md"
    "Documentation/FamilyHealthSharingGuide.md:Documentation/UserGuides/HealthFeatures/FamilyHealthSharing.md"
    "Documentation/MentalHealthWellnessGuide.md:Documentation/UserGuides/HealthFeatures/MentalWellness.md"
    "Documentation/NutritionDietOptimizationGuide.md:Documentation/UserGuides/HealthFeatures/NutritionOptimization.md"
    "Documentation/FitnessExerciseOptimizationGuide.md:Documentation/UserGuides/HealthFeatures/FitnessOptimization.md"
    "Documentation/HealthAnomalyDetectionGuide.md:Documentation/UserGuides/HealthFeatures/AnomalyDetection.md"
    "Documentation/HealthResearchClinicalIntegrationGuide.md:Documentation/UserGuides/HealthFeatures/ClinicalIntegration.md"
)

for mapping in "${user_guides[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "user guide"; then
        ((moved_count++))
    fi
done

echo -e "\n📋 Phase 2: Moving Developer Guides..."

# Move developer-focused guides
dev_guides=(
    "docs/DeveloperGuides/README.md:Documentation/DeveloperGuides/DeveloperREADME.md"
    "docs/DeveloperGuides/CONTRIBUTING.md:Documentation/DeveloperGuides/CONTRIBUTING.md"
    "docs/DeveloperGuides/architecture.md:Documentation/DeveloperGuides/Architecture/SystemArchitecture.md"
    "docs/architecture.md:Documentation/DeveloperGuides/Architecture/OverallArchitecture.md"
    "docs/core_data_architecture.md:Documentation/DeveloperGuides/Architecture/CoreDataArchitecture.md"
    "docs/DeveloperGuides/DigitalHealthTwin_Architecture.md:Documentation/DeveloperGuides/Architecture/DigitalHealthTwin.md"
    "docs/DeveloperGuides/System_Intelligence_API_Reference.md:Documentation/DeveloperGuides/APIs/SystemIntelligenceAPI.md"
    "docs/APIDocumentation.md:Documentation/DeveloperGuides/APIs/APIDocumentation.md"
    "docs/DeveloperGuides/SleepStageClassifier.md:Documentation/DeveloperGuides/APIs/SleepStageClassifier.md"
    "docs/DEVELOPER_GUIDE.md:Documentation/DeveloperGuides/DeveloperGuide.md"
    "docs/DeveloperDocumentationAPIReference.md:Documentation/DeveloperGuides/APIs/APIReference.md"
    "docs/DeveloperGuides/CROSS_DEVICE_SYNC_SETUP.md:Documentation/DeveloperGuides/Setup/CrossDeviceSyncSetup.md"
    "docs/DeveloperGuides/GITHUB_SETUP.md:Documentation/DeveloperGuides/Setup/GitHubSetup.md"
    "docs/DeveloperGuides/REAL_DEVICE_TESTING_GUIDE.md:Documentation/DeveloperGuides/Testing/RealDeviceTesting.md"
    "docs/DeveloperGuides/TESTFLIGHT_CHECKLIST.md:Documentation/DeveloperGuides/Testing/TestFlightChecklist.md"
    "docs/DeveloperGuides/Widget_Development_Guide.md:Documentation/DeveloperGuides/WidgetDevelopment.md"
    "docs/DeveloperGuides/adding-copilot-skill.md:Documentation/DeveloperGuides/CopilotSkillDevelopment.md"
    "docs/DeveloperGuides/iOS18_Enhancements_Guide.md:Documentation/DeveloperGuides/iOS18Enhancements.md"
    "docs/DeveloperGuides/TODO_RESOLUTIONS.md:Documentation/DeveloperGuides/TODOResolutions.md"
)

for mapping in "${dev_guides[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "developer guide"; then
        ((moved_count++))
    fi
done

echo -e "\n📋 Phase 3: Moving Administrative Documentation..."

# Move administrative/legal/compliance docs
admin_docs=(
    "Legal/PRIVACY_POLICY.md:Documentation/Administrative/Privacy/PRIVACY_POLICY.md"
    "Legal/TERMS_OF_SERVICE.md:Documentation/Administrative/Privacy/TERMS_OF_SERVICE.md"
    "Legal/LEGAL_IMPLEMENTATION_GUIDE.md:Documentation/Administrative/Privacy/LEGAL_IMPLEMENTATION_GUIDE.md"
    "SECURITY_AUDIT_REPORT.md:Documentation/Administrative/Security/SECURITY_AUDIT_REPORT.md"
    "SECURITY_IMPLEMENTATION_REPORT.md:Documentation/Administrative/Security/SECURITY_IMPLEMENTATION_REPORT.md"
    "SECURITY_TESTS_VALIDATION_REPORT.md:Documentation/Administrative/Security/SECURITY_TESTS_VALIDATION_REPORT.md"
    "docs/SECURITY.md:Documentation/Administrative/Security/SECURITY.md"
    "docs/ProjectOverview/SECURITY.md:Documentation/Administrative/Security/SecurityOverview.md"
    "CERTIFICATE_PINNING_SETUP.md:Documentation/Administrative/Security/CERTIFICATE_PINNING_SETUP.md"
    "Configuration/TEAM_ID_SETUP.md:Documentation/Administrative/Deployment/TEAM_ID_SETUP.md"
    "Configuration/TEAM_ID_SETUP_GUIDE.md:Documentation/Administrative/Deployment/TEAM_ID_SETUP_GUIDE.md"
    "docs/DEPLOYMENT_CHECKLIST.md:Documentation/Administrative/Deployment/DEPLOYMENT_CHECKLIST.md"
    "docs/app_store_submission.md:Documentation/Administrative/Deployment/AppStoreSubmission.md"
    "docs/devops.md:Documentation/Administrative/Deployment/DevOps.md"
    "Documentation/ENCRYPTION_COMPLIANCE_GUIDE.md:Documentation/Administrative/Compliance/ENCRYPTION_COMPLIANCE_GUIDE.md"
)

for mapping in "${admin_docs[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "administrative doc"; then
        ((moved_count++))
    fi
done

echo -e "\n📋 Phase 4: Moving Technical Documentation..."

# Move technical/advanced guides
tech_docs=(
    "Documentation/EnhancedAIHealthCoachGuide.md:Documentation/Technical/HealthDomains/AIHealthCoach.md"
    "Documentation/AdvancedSleepMitigationGuide.md:Documentation/Technical/HealthDomains/SleepOptimization.md"
    "Documentation/AdvancedSmartHomeGuide.md:Documentation/Technical/HealthDomains/SmartHomeHealth.md"
    "Documentation/AdvancedAnalyticsDashboardGuide.md:Documentation/Technical/Analytics/AnalyticsDashboard.md"
    "Documentation/PerformanceOptimizationGuide.md:Documentation/Technical/Performance/OptimizationGuide.md"
    "Documentation/PerformanceOptimizationSystem.md:Documentation/Technical/Performance/OptimizationSystem.md"
    "Documentation/RealTimeHealthMonitoringEngine.md:Documentation/Technical/Analytics/RealTimeMonitoring.md"
    "Documentation/PredictiveHealthModelingEngine.md:Documentation/Technical/Analytics/PredictiveModeling.md"
    "Documentation/RealTimeAnalyticsGuide.md:Documentation/Technical/Analytics/RealTimeAnalytics.md"
    "Documentation/CrossDeviceIntelligenceGuide.md:Documentation/Technical/Integration/CrossDeviceIntelligence.md"
    "Documentation/FederatedLearningGuide.md:Documentation/Technical/Integration/FederatedLearning.md"
    "Documentation/FederatedMarketplaceGuide.md:Documentation/Technical/Integration/FederatedMarketplace.md"
    "Documentation/FederatedUIGuide.md:Documentation/Technical/Integration/FederatedUI.md"
    "Documentation/PersonalizedAgentGuide.md:Documentation/Technical/Integration/PersonalizedAgent.md"
    "Documentation/PrivacyProtocolGuide.md:Documentation/Technical/Security/PrivacyProtocols.md"
    "Documentation/QuantumHealthSimulationGuide.md:Documentation/Technical/HealthDomains/QuantumHealthSimulation.md"
    "Documentation/CROSSDEVICESYNC_MIGRATION_GUIDE.md:Documentation/Technical/Integration/CrossDeviceSyncMigration.md"
    "Documentation/CROSSDEVICESYNC_REFACTORING_PLAN.md:Documentation/Technical/Integration/CrossDeviceSyncRefactoring.md"
    "docs/AdvancedHealthAnalyticsGuide.md:Documentation/Technical/Analytics/AdvancedHealthAnalytics.md"
    "docs/AdvancedMentalHealthGuide.md:Documentation/Technical/HealthDomains/AdvancedMentalHealth.md"
    "docs/AdvancedHealthDataIntegrationGuide.md:Documentation/Technical/Integration/HealthDataIntegration.md"
    "docs/AdvancedHealthResearchGuide.md:Documentation/Technical/HealthDomains/HealthResearch.md"
    "docs/AdvancedHealthDeviceIntegrationGuide.md:Documentation/Technical/Integration/HealthDeviceIntegration.md"
    "docs/AdvancedClinicalDecisionSupportGuide.md:Documentation/Technical/HealthDomains/ClinicalDecisionSupport.md"
    "docs/AdvancedBiometricFusionGuide.md:Documentation/Technical/HealthDomains/BiometricFusion.md"
    "docs/AdvancedHealthDataPrivacyGuide.md:Documentation/Technical/Security/HealthDataPrivacy.md"
    "docs/AdvancedSleepIntelligenceGuide.md:Documentation/Technical/HealthDomains/SleepIntelligence.md"
    "docs/AdvancedHealthPredictionGuide.md:Documentation/Technical/Analytics/HealthPrediction.md"
    "docs/RealTimeHealthCoachingGuide.md:Documentation/Technical/HealthDomains/RealTimeHealthCoaching.md"
)

for mapping in "${tech_docs[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "technical doc"; then
        ((moved_count++))
    fi
done

echo -e "\n📋 Phase 5: Moving Specialized Documentation..."

# Move specialized docs
specialized_docs=(
    "Documentation/LocalizationSystem.md:Documentation/Technical/Integration/LocalizationSystem.md"
    "Documentation/ComprehensiveTestingSystem.md:Documentation/DeveloperGuides/Testing/ComprehensiveTestingSystem.md"
    "Documentation/AdvancedSecurityPrivacySystem.md:Documentation/Technical/Security/AdvancedSecurityPrivacySystem.md"
    "docs/machine_learning_integration.md:Documentation/Technical/Integration/MachineLearningIntegration.md"
    "docs/networking_layer.md:Documentation/DeveloperGuides/Architecture/NetworkingLayer.md"
    "docs/real_time_data_sync.md:Documentation/Technical/Integration/RealTimeDataSync.md"
    "docs/multi_platform_support.md:Documentation/DeveloperGuides/Architecture/MultiPlatformSupport.md"
    "docs/accessibility_audit.md:Documentation/DeveloperGuides/Testing/AccessibilityAudit.md"
    "docs/notifications.md:Documentation/DeveloperGuides/NotificationSystem.md"
    "docs/health_goal_engine.md:Documentation/Technical/HealthDomains/HealthGoalEngine.md"
    "docs/health_insights_analytics.md:Documentation/Technical/Analytics/HealthInsightsAnalytics.md"
    "docs/Live_Activities_Setup.md:Documentation/DeveloperGuides/Setup/LiveActivitiesSetup.md"
    "docs/iOS18_Enhancement_Plan.md:Documentation/DeveloperGuides/iOS18EnhancementPlan.md"
)

for mapping in "${specialized_docs[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "specialized doc"; then
        ((moved_count++))
    fi
done

echo -e "\n📋 Phase 6: Consolidating Duplicate App Icon Guides..."

# Handle the duplicate APP_ICON_GENERATION_GUIDE.md files
if [ -f "APP_ICON_GENERATION_GUIDE.md" ] && [ -f "Documentation/APP_ICON_GENERATION_GUIDE.md" ]; then
    echo "  🔄 Consolidating duplicate APP_ICON_GENERATION_GUIDE.md files..."
    
    # Compare sizes and keep the larger one
    size1=$(stat -f%z "APP_ICON_GENERATION_GUIDE.md" 2>/dev/null || stat -c%s "APP_ICON_GENERATION_GUIDE.md" 2>/dev/null)
    size2=$(stat -f%z "Documentation/APP_ICON_GENERATION_GUIDE.md" 2>/dev/null || stat -c%s "Documentation/APP_ICON_GENERATION_GUIDE.md" 2>/dev/null)
    
    if [ "$size2" -gt "$size1" ]; then
        mv "Documentation/APP_ICON_GENERATION_GUIDE.md" "Documentation/DeveloperGuides/Setup/AppIconGeneration.md"
        rm "APP_ICON_GENERATION_GUIDE.md"
        echo "  ✅ Consolidated: Documentation version moved to DeveloperGuides/Setup/"
    else
        mv "APP_ICON_GENERATION_GUIDE.md" "Documentation/DeveloperGuides/Setup/AppIconGeneration.md"
        rm "Documentation/APP_ICON_GENERATION_GUIDE.md"
        echo "  ✅ Consolidated: Root version moved to DeveloperGuides/Setup/"
    fi
    ((moved_count++))
elif [ -f "APP_ICON_GENERATION_GUIDE.md" ]; then
    mv "APP_ICON_GENERATION_GUIDE.md" "Documentation/DeveloperGuides/Setup/AppIconGeneration.md"
    echo "  ✅ Moved: APP_ICON_GENERATION_GUIDE.md to DeveloperGuides/Setup/"
    ((moved_count++))
elif [ -f "Documentation/APP_ICON_GENERATION_GUIDE.md" ]; then
    mv "Documentation/APP_ICON_GENERATION_GUIDE.md" "Documentation/DeveloperGuides/Setup/AppIconGeneration.md"
    echo "  ✅ Moved: Documentation/APP_ICON_GENERATION_GUIDE.md to DeveloperGuides/Setup/"
    ((moved_count++))
fi

echo -e "\n📋 Phase 7: Moving Module-Specific Documentation..."

# Move module-specific READMEs and docs
module_docs=(
    "Sources/Features/Biofeedback/README.md:Documentation/Technical/HealthDomains/BiofeedbackREADME.md"
    "Sources/Features/CardiacHealth/Sources/CardiacHealth/README.md:Documentation/Technical/HealthDomains/CardiacHealthREADME.md"
    "Sources/Features/CardiacHealth/Sources/CardiacHealth/ECG/README.md:Documentation/Technical/HealthDomains/ECGProcessingREADME.md"
    "Sources/Features/HealthAI2030UI/README.md:Documentation/DeveloperGuides/HealthAI2030UIREADME.md"
)

for mapping in "${module_docs[@]}"; do
    source="${mapping%%:*}"
    dest="${mapping##*:}"
    if move_with_consolidation "$source" "$dest" "module doc"; then
        ((moved_count++))
    fi
done

# Count remaining documentation files
remaining_docs=$(find . -name "*.md" | grep -v ".build" | grep -v "Documentation/" | wc -l | tr -d ' ')
consolidated_docs=$(find Documentation/ -name "*.md" | wc -l | tr -d ' ')

echo -e "\n📊 Consolidation Summary:"
echo "Files moved/consolidated: $moved_count"
echo "Files in Documentation/: $consolidated_docs"
echo "Remaining scattered docs: $remaining_docs"

echo -e "\n✅ Documentation consolidation complete!"
echo "📂 New structure populated with consolidated content"
echo -e "\n⚠️  Next steps:"
echo "1. Review remaining scattered documentation files"
echo "2. Create comprehensive indexes"
echo "3. Validate all internal links"
echo "4. Apply final naming conventions"