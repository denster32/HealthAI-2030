# Explainable AI (XAI) Implementation Plan

## 1. Feature Importance Visualization
- Extract feature weights or importances from models (e.g., linear coefficients, SHAP values).
- Create a SwiftUI `FeatureImportanceView` to display top N features and their relative importance (e.g., bar chart).
- Integrate `FeatureImportanceView` into `SleepReportView` and `PredictiveHealthDashboardView`.

## 2. Counterfactual (What-If) Scenarios
- Provide a UI slider or input for key features (e.g., bedtime, exercise minutes).
- Re-run the model locally with modified inputs to show predicted outcome changes.
- Display before/after predictions in a `WhatIfScenarioView`.

## 3. Integration Steps
1. Define `FeatureImportanceView.swift` and `WhatIfScenarioView.swift` components.
2. Bridge model inference calls to return both prediction and feature importance.
3. Test for performance and UI responsiveness.

*End of XAI Plan* 