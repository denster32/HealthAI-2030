# ``HealthAI2030/PerformanceMonitorCoordinator``

Coordinates all performance monitoring services to provide comprehensive system analysis.

## Overview

This coordinator orchestrates the collection, analysis, and reporting of system performance metrics. It manages the lifecycle of monitoring operations and provides a unified interface for accessing performance data and recommendations.

## Architecture

The coordinator uses several specialized services:
- `MetricsCollector`: Gathers system metrics from various sources
- `AnomalyDetectionService`: Identifies performance anomalies
- `TrendAnalysisService`: Analyzes performance trends over time
- `RecommendationEngine`: Generates optimization recommendations

## Topics

### Essentials
- ``startMonitoring(interval:)``
- ``stopMonitoring()``
- ``currentMetrics``

### Analysis
- ``anomalyAlerts``
- ``performanceTrends``
- ``optimizationRecommendations``

### Services
- ``MetricsCollector``
- ``AnomalyDetectionService``
- ``TrendAnalysisService``
- ``RecommendationEngine``

## See Also

- ``SystemMetrics``
- ``AnomalyAlert``
- ``PerformanceTrend``
- ``OptimizationRecommendation`` 