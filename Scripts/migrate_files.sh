#!/bin/bash
# Migration script to move files into new modular framework structure

# Core
mv Modules/Features/Shared/Models/CoreHealthDataModel.swift Frameworks/HealthAI2030Core/Sources/ 2>/dev/null
mv Modules/Features/Shared/Managers/HealthDataManager.swift Frameworks/HealthAI2030Core/Sources/ 2>/dev/null
mv Apps/MainApp/ViewModels/Dashboard/HealthDashboardViewModel.swift Frameworks/HealthAI2030Core/Sources/ 2>/dev/null

# Security
mv Apps/MainApp/Services/PrivacySecurityManager.swift Frameworks/SecurityComplianceKit/Sources/ 2>/dev/null

# Sleep
mv Modules/Features/SleepTracking/SleepTracking/Managers/SleepAnalysisManager.swift Frameworks/SleepIntelligenceKit/Sources/ 2>/dev/null

# Dashboard View
mv Apps/MainApp/Views/Dashboard/HealthDashboardView.swift App/HealthAI2030App/ 2>/dev/null

# Documentation
mv *.md Docs/ 2>/dev/null
mv docs/* Docs/ 2>/dev/null
mv Documentation/* Docs/ 2>/dev/null

# Scripts
mv Apps/MainApp/Scripts/* Scripts/ 2>/dev/null
