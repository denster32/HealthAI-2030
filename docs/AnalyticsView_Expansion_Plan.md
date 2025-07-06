# Plan for Expanding AnalyticsView with Detailed Health Data Visualizations

## Goal
Expand the `AnalyticsView` to display detailed health data visualizations.

## Sub-goals
1.  **Design the overall layout of `AnalyticsView`:**
    *   It should be a scrollable view.
    *   Include sections for different categories of health data (e.g., Daily Summary, Trends, Sleep, Activity, etc.).
    *   Each section will contain relevant visualization components.
2.  **Create reusable visualization components:**
    *   **Line Charts:** For displaying trends over time (e.g., Heart Rate Trend, HRV Trend, Sleep Trend).
    *   **Bar Charts:** For comparing daily/weekly aggregates (e.g., Daily Steps, Weekly Active Energy).
    *   **Pie/Donut Charts:** For showing proportions (e.g., Sleep Stage Breakdown).
    *   **Summary Cards:** For key metrics and insights.
3.  **Integrate `HealthDataManager` and `HealthModels`:**
    *   The `AnalyticsView` and its sub-components will need to observe `HealthDataManager` to get the latest data.
    *   Utilize the existing data structures in `HealthModels` to populate the visualizations.
4.  **Populate `AnalyticsView` with data:**
    *   Display daily summaries (average heart rate, total steps, sleep duration).
    *   Show weekly trends for key metrics.
    *   Present detailed sleep analysis (sleep stages, efficiency).
    *   Include activity summaries (calories burned, exercise types).
    *   Potentially add sections for insights, correlations, and predictions if data is available or can be simulated.

## Detailed Plan

### Phase 1: Information Gathering & Initial Design (Architect Mode)
*   **Current Step:** Already gathered initial context from `MainTabView.swift`, `BiofeedbackMeditationView.swift`, `RecoveryRatingCard.swift`, `SleepArchitectureCard.swift`, `HealthDataManager.swift`, and `HealthModels.swift`.
*   **Next Step:** Propose a detailed UI/UX plan for `AnalyticsView`.

### Phase 2: Implementation (Code Mode)

1.  **Create `AnalyticsView.swift` (if not already a dedicated file, otherwise modify existing):**
    *   Modify the existing `AnalyticsView` struct in `MainTabView.swift` or move it to its own file for better organization.
    *   Add `@EnvironmentObject` properties for `HealthDataManager`, `PredictiveAnalyticsManager`, and potentially others if needed for insights/predictions.
    *   Structure the main `VStack` with `ScrollView` to accommodate multiple sections.

2.  **Develop Core Visualization Components:**
    *   **`HealthTrendLineChart.swift`:** A reusable SwiftUI view for line charts.
        *   Inputs: `data: [Double]`, `labels: [String]`, `title: String`, `unit: String`.
        *   Display historical data for metrics like heart rate, HRV, etc.
    *   **`SleepStageDonutChart.swift`:** A reusable SwiftUI view for a donut chart.
        *   Inputs: `sleepMetrics: SleepMetrics`.
        *   Visualize percentages of awake, light, deep, and REM sleep.
    *   **`DailyActivityBarChart.swift`:** A reusable SwiftUI view for a bar chart.
        *   Inputs: `data: [Double]`, `labels: [String]`, `title: String`, `unit: String`.
        *   Display daily steps, active energy, etc.
    *   **`HealthSummaryCard.swift`:** A generic card for displaying key metrics.
        *   Inputs: `title: String`, `value: String`, `icon: String`, `color: Color`.

3.  **Integrate Components into `AnalyticsView`:**
    *   **Daily Summary Section:**
        *   Use `HealthSummaryCard` to display `dailyMetrics.averageHeartRate`, `dailyMetrics.totalSteps`, `dailyMetrics.sleepDuration`, etc.
    *   **Weekly Trends Section:**
        *   Use `HealthTrendLineChart` for `weeklyTrends.heartRateTrend`, `weeklyTrends.hrvTrend`, `weeklyTrends.sleepTrend`.
    *   **Sleep Analysis Section:**
        *   Use `SleepStageDonutChart` for `sleepOptimizationManager.sleepMetrics`.
        *   Display `sleepOptimizationManager.sleepQuality`, `deepSleepPercentage`, `remSleepPercentage`.
    *   **Activity Overview Section:**
        *   Use `DailyActivityBarChart` for `healthDataManager.activeEnergyBurned` and `healthDataManager.stepCount` over a period.
    *   **Insights & Predictions Section (Optional for initial implementation, can be added later):**
        *   Display `predictiveAnalytics.dailyInsights` and `predictiveAnalytics.healthAlerts` in a more analytical format.

## Mermaid Diagram for AnalyticsView Structure

```mermaid
graph TD
    A[AnalyticsView] --> B(ScrollView)
    B --> C{VStack (Main Content)}
    C --> D[Daily Summary Section]
    C --> E[Weekly Trends Section]
    C --> F[Sleep Analysis Section]
    C --> G[Activity Overview Section]
    D --> D1(HealthSummaryCard: Heart Rate)
    D --> D2(HealthSummaryCard: Steps)
    D --> D3(HealthSummaryCard: Sleep Duration)
    E --> E1(HealthTrendLineChart: Heart Rate Trend)
    E --> E2(HealthTrendLineChart: HRV Trend)
    E --> E3(HealthTrendLineChart: Sleep Trend)
    F --> F1(SleepStageDonutChart)
    F --> F2(Text: Sleep Quality)
    F --> F3(Text: Deep Sleep Percentage)
    G --> G1(DailyActivityBarChart: Steps)
    G --> G2(DailyActivityBarChart: Active Energy)
```

## Mermaid Diagram for Data Flow

```mermaid
graph TD
    A[HealthDataManager] --> B[AnalyticsView]
    A --> C[HealthSummaryCard]
    A --> D[HealthTrendLineChart]
    A --> E[SleepStageDonutChart]
    A --> F[DailyActivityBarChart]
    B --> C
    B --> D
    B --> E
    B --> F
    G[HealthModels] --> A
    G --> E