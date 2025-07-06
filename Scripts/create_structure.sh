#!/bin/bash
# Create all required directories for frameworks, app, docs, resources, and tests

mkdir -p App/HealthAI2030App
mkdir -p Frameworks/{HealthAI2030Core,SecurityComplianceKit,SleepIntelligenceKit,PredictionEngineKit,StressDetectionKit,CoachingKit,BiometricFusionKit,ClinicalIntegrationKit,DeviceEcosystemKit}/{Sources,Tests}
mkdir -p Resources/MLModels
mkdir -p Docs
mkdir -p Scripts
mkdir -p Tests
