// MLModelRegistry.swift
// Centralized registry for expanded Core ML models

import CoreML

public struct MLModelRegistry {
    public static let advancedSleepModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "AdvancedSleepModel", withExtension: "mlmodelc")!)
    public static let digitalTwinModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "DigitalTwinModel", withExtension: "mlmodelc")!)
    public static let personalizedForecastModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "PersonalizedForecastModel", withExtension: "mlmodelc")!)
    public static let arrhythmiaDetectionModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "ArrhythmiaDetectionModel", withExtension: "mlmodelc")!)
    public static let sleepStageTransformer = try? MLModel(contentsOf: Bundle.main.url(forResource: "SleepStageTransformer", withExtension: "mlmodelc")!)
    public static let moodPredictionModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "MoodPredictionModel", withExtension: "mlmodelc")!)
    public static let nutritionRecommendationModel = try? MLModel(contentsOf: Bundle.main.url(forResource: "NutritionRecommendationModel", withExtension: "mlmodelc")!)
    // Add more models as they are trained and bundled
}
