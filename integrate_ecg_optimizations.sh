#!/bin/zsh

# Move optimized files to their final locations
mv ECGDataProcessor_Optimized.swift Apps/MainApp/ML/ECGDataProcessor.swift
mv ECGInsightManager_Optimized.swift Apps/MainApp/Managers/ECGInsightManager.swift

# Update references in dependent files
sed -i '' 's/ECGDataProcessor_Optimized/ECGDataProcessor/g' Apps/MainApp/Managers/ECGInsightManager.swift
sed -i '' 's/ECGInsightManager_Optimized/ECGInsightManager/g' Apps/MainApp/Views/PerformanceOptimizationDashboardView.swift

# Add performance tests to test target
mv ECGProcessorPerformanceTests.swift Apps/MainApp/Tests/ECGProcessorPerformanceTests.swift

echo "ECG optimizations integrated successfully"
echo "Remember to:"
echo "1. Add ECGProcessorPerformanceTests to test target in Xcode"
echo "2. Run tests to validate performance metrics"