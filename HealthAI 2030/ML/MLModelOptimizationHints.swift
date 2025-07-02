//
//  MLModelOptimizationHints.swift
//  HealthAI 2030
//
//  iOS 26 ML Optimization Framework

import Foundation
import CoreML

@available(iOS 17.0, *)
@available(macOS 14.0, *)
enum MLModelOptimizationHints: String {
    case reduceMemoryFootprint = "reduceMemoryFootprint"
    case optimizeForBattery = "optimizeForBattery"
    case maximizePerformance = "maximizePerformance"
    case balancedOptimization = "balancedOptimization"
    case neuralEnginePreferred = "neuralEnginePreferred"
    case cpuOptimized = "cpuOptimized"
    case gpuAccelerated = "gpuAccelerated"
    
    var configuration: MLModelConfiguration {
        let config = MLModelConfiguration()
        
        switch self {
        case .reduceMemoryFootprint:
            config.allowLowPrecisionAccumulationOnGPU = true
            config.computeUnits = .cpuAndNeuralEngine
            
        case .optimizeForBattery:
            config.computeUnits = .cpuOnly
            config.allowLowPrecisionAccumulationOnGPU = true
            
        case .maximizePerformance:
            config.computeUnits = .all
            config.allowLowPrecisionAccumulationOnGPU = false
            
        case .balancedOptimization:
            config.computeUnits = .cpuAndNeuralEngine
            config.allowLowPrecisionAccumulationOnGPU = true
            
        case .neuralEnginePreferred:
            config.computeUnits = .cpuAndNeuralEngine
            
        case .cpuOptimized:
            config.computeUnits = .cpuOnly
            
        case .gpuAccelerated:
            config.computeUnits = .cpuAndGPU
        }
        
        return config
    }
}

@available(iOS 17.0, *)
@available(macOS 14.0, *)
class MLOptimizationManager {
    static let shared = MLOptimizationManager()
    
    private init() {}
    
    func optimizeModelForDevice(_ modelURL: URL, hint: MLModelOptimizationHints) async throws -> MLModel {
        let config = hint.configuration
        
        // iOS 26+ specific optimizations
        if #available(iOS 17.0, *) {
            // Try to load compiled model first, then compile if needed
            // This prevents duplicate compilation issues
            if let compiledURL = try? MLModel.compileModel(at: modelURL) {
                return try MLModel(contentsOf: compiledURL, configuration: config)
            } else {
                // Fallback: load model directly
                return try MLModel(contentsOf: modelURL, configuration: config)
            }
        } else {
            // Fallback for older versions
            return try MLModel(contentsOf: modelURL, configuration: config)
        }
    }
    
    func recommendOptimization(for modelType: MLModelType, deviceCapabilities: DeviceCapabilities) -> MLModelOptimizationHints {
        switch (modelType, deviceCapabilities.neuralEngineSupport) {
        case (.sleepStage, true):
            return .neuralEnginePreferred
        case (.healthPrediction, true):
            return .balancedOptimization
        case (.realTimeProcessing, _):
            return .maximizePerformance
        case (_, false):
            return .cpuOptimized
        default:
            return .balancedOptimization
        }
    }
}

enum MLModelType {
    case sleepStage
    case healthPrediction
    case arrhythmiaDetection
    case realTimeProcessing
    case backgroundAnalysis
}

struct DeviceCapabilities {
    let neuralEngineSupport: Bool
    let gpuSupport: Bool
    let memoryConstraints: MemoryConstraint
    let batteryOptimizationRequired: Bool
    
    static var current: DeviceCapabilities {
        return DeviceCapabilities(
            neuralEngineSupport: true, // Assume modern device
            gpuSupport: true,
            memoryConstraints: .moderate,
            batteryOptimizationRequired: false
        )
    }
}

enum MemoryConstraint {
    case low
    case moderate
    case high
}