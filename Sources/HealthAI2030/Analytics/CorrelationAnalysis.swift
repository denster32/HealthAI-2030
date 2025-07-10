import Foundation
import Accelerate

/// Advanced correlation analysis engine for multi-variable healthcare data
public class CorrelationAnalysis {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    
    // MARK: - Correlation Types
    public enum CorrelationType {
        case pearson
        case spearman
        case kendall
        case partial
        case canonical
    }
    
    // MARK: - Data Structures
    public struct CorrelationResult {
        let coefficient: Double
        let pValue: Double
        let confidenceInterval: (lower: Double, upper: Double)
        let sampleSize: Int
        let isSignificant: Bool
        let correlationType: CorrelationType
    }
    
    public struct MultiVariateCorrelation {
        let correlationMatrix: [[Double]]
        let variableNames: [String]
        let significanceMatrix: [[Bool]]
        let pValueMatrix: [[Double]]
    }
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                configManager: AnalyticsConfiguration,
                errorHandler: AnalyticsErrorHandling,
                performanceMonitor: AnalyticsPerformanceMonitor) {
        self.analyticsEngine = analyticsEngine
        self.configManager = configManager
        self.errorHandler = errorHandler
        self.performanceMonitor = performanceMonitor
    }
    
    // MARK: - Public Methods
    
    /// Calculate correlation between two variables
    public func calculateCorrelation(
        variable1: [Double],
        variable2: [Double],
        type: CorrelationType = .pearson
    ) async throws -> CorrelationResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("correlation_calculation", value: executionTime)
        }
        
        do {
            // Validate input data
            guard variable1.count == variable2.count else {
                throw AnalyticsError.invalidInput("Variables must have the same length")
            }
            
            guard variable1.count >= 3 else {
                throw AnalyticsError.insufficientData("Need at least 3 data points for correlation")
            }
            
            // Remove missing values
            let (cleanVar1, cleanVar2) = removeMissingValues(variable1, variable2)
            
            let coefficient: Double
            let pValue: Double
            
            switch type {
            case .pearson:
                coefficient = calculatePearsonCorrelation(cleanVar1, cleanVar2)
                pValue = calculatePearsonPValue(coefficient, sampleSize: cleanVar1.count)
                
            case .spearman:
                coefficient = calculateSpearmanCorrelation(cleanVar1, cleanVar2)
                pValue = calculateSpearmanPValue(coefficient, sampleSize: cleanVar1.count)
                
            case .kendall:
                coefficient = calculateKendallCorrelation(cleanVar1, cleanVar2)
                pValue = calculateKendallPValue(coefficient, sampleSize: cleanVar1.count)
                
            case .partial:
                // For partial correlation, would need additional control variables
                coefficient = calculatePearsonCorrelation(cleanVar1, cleanVar2)
                pValue = calculatePearsonPValue(coefficient, sampleSize: cleanVar1.count)
                
            case .canonical:
                // Canonical correlation for multivariate relationships
                coefficient = calculatePearsonCorrelation(cleanVar1, cleanVar2)
                pValue = calculatePearsonPValue(coefficient, sampleSize: cleanVar1.count)
            }
            
            let confidenceInterval = calculateConfidenceInterval(
                coefficient: coefficient,
                sampleSize: cleanVar1.count,
                confidenceLevel: 0.95
            )
            
            let isSignificant = pValue < configManager.significanceLevel
            
            return CorrelationResult(
                coefficient: coefficient,
                pValue: pValue,
                confidenceInterval: confidenceInterval,
                sampleSize: cleanVar1.count,
                isSignificant: isSignificant,
                correlationType: type
            )
            
        } catch {
            await errorHandler.handleError(error, context: "CorrelationAnalysis.calculateCorrelation")
            throw error
        }
    }
    
    /// Calculate correlation matrix for multiple variables
    public func calculateCorrelationMatrix(
        variables: [[Double]],
        variableNames: [String],
        type: CorrelationType = .pearson
    ) async throws -> MultiVariateCorrelation {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("correlation_matrix_calculation", value: executionTime)
        }
        
        do {
            guard variables.count == variableNames.count else {
                throw AnalyticsError.invalidInput("Number of variables must match number of names")
            }
            
            let numVariables = variables.count
            var correlationMatrix = Array(repeating: Array(repeating: 0.0, count: numVariables), count: numVariables)
            var significanceMatrix = Array(repeating: Array(repeating: false, count: numVariables), count: numVariables)
            var pValueMatrix = Array(repeating: Array(repeating: 1.0, count: numVariables), count: numVariables)
            
            for i in 0..<numVariables {
                for j in 0..<numVariables {
                    if i == j {
                        correlationMatrix[i][j] = 1.0
                        significanceMatrix[i][j] = true
                        pValueMatrix[i][j] = 0.0
                    } else if i < j {
                        let result = try await calculateCorrelation(
                            variable1: variables[i],
                            variable2: variables[j],
                            type: type
                        )
                        
                        correlationMatrix[i][j] = result.coefficient
                        correlationMatrix[j][i] = result.coefficient
                        significanceMatrix[i][j] = result.isSignificant
                        significanceMatrix[j][i] = result.isSignificant
                        pValueMatrix[i][j] = result.pValue
                        pValueMatrix[j][i] = result.pValue
                    }
                }
            }
            
            return MultiVariateCorrelation(
                correlationMatrix: correlationMatrix,
                variableNames: variableNames,
                significanceMatrix: significanceMatrix,
                pValueMatrix: pValueMatrix
            )
            
        } catch {
            await errorHandler.handleError(error, context: "CorrelationAnalysis.calculateCorrelationMatrix")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func removeMissingValues(_ var1: [Double], _ var2: [Double]) -> ([Double], [Double]) {
        var cleanVar1: [Double] = []
        var cleanVar2: [Double] = []
        
        for i in 0..<var1.count {
            if !var1[i].isNaN && !var1[i].isInfinite && !var2[i].isNaN && !var2[i].isInfinite {
                cleanVar1.append(var1[i])
                cleanVar2.append(var2[i])
            }
        }
        
        return (cleanVar1, cleanVar2)
    }
    
    private func calculatePearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumXSquared = x.map { $0 * $0 }.reduce(0, +)
        let sumYSquared = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumXSquared - sumX * sumX) * (n * sumYSquared - sumY * sumY))
        
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    private func calculateSpearmanCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let ranksX = calculateRanks(x)
        let ranksY = calculateRanks(y)
        return calculatePearsonCorrelation(ranksX, ranksY)
    }
    
    private func calculateKendallCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = x.count
        var concordant = 0
        var discordant = 0
        
        for i in 0..<n {
            for j in (i+1)..<n {
                let xDiff = x[i] - x[j]
                let yDiff = y[i] - y[j]
                
                if (xDiff > 0 && yDiff > 0) || (xDiff < 0 && yDiff < 0) {
                    concordant += 1
                } else if (xDiff > 0 && yDiff < 0) || (xDiff < 0 && yDiff > 0) {
                    discordant += 1
                }
            }
        }
        
        let totalPairs = n * (n - 1) / 2
        return Double(concordant - discordant) / Double(totalPairs)
    }
    
    private func calculateRanks(_ values: [Double]) -> [Double] {
        let sortedWithIndices = values.enumerated().sorted { $0.element < $1.element }
        var ranks = Array(repeating: 0.0, count: values.count)
        
        for (rank, (originalIndex, _)) in sortedWithIndices.enumerated() {
            ranks[originalIndex] = Double(rank + 1)
        }
        
        return ranks
    }
    
    private func calculatePearsonPValue(_ correlation: Double, sampleSize: Int) -> Double {
        let t = correlation * sqrt(Double(sampleSize - 2) / (1 - correlation * correlation))
        let df = sampleSize - 2
        
        // Simplified t-distribution p-value calculation
        // In a real implementation, you'd use a proper statistical library
        return 2 * (1 - cumulativeNormalDistribution(abs(t)))
    }
    
    private func calculateSpearmanPValue(_ correlation: Double, sampleSize: Int) -> Double {
        // Approximate p-value for Spearman correlation
        return calculatePearsonPValue(correlation, sampleSize: sampleSize)
    }
    
    private func calculateKendallPValue(_ correlation: Double, sampleSize: Int) -> Double {
        // Approximate p-value for Kendall correlation
        let variance = 2.0 * (2.0 * Double(sampleSize) + 5.0) / (9.0 * Double(sampleSize) * Double(sampleSize - 1))
        let z = correlation / sqrt(variance)
        return 2 * (1 - cumulativeNormalDistribution(abs(z)))
    }
    
    private func calculateConfidenceInterval(
        coefficient: Double,
        sampleSize: Int,
        confidenceLevel: Double
    ) -> (lower: Double, upper: Double) {
        
        let alpha = 1 - confidenceLevel
        let zValue = 1.96 // For 95% confidence interval
        
        // Fisher's z-transformation
        let fisherZ = 0.5 * log((1 + coefficient) / (1 - coefficient))
        let standardError = 1.0 / sqrt(Double(sampleSize - 3))
        
        let lowerZ = fisherZ - zValue * standardError
        let upperZ = fisherZ + zValue * standardError
        
        // Transform back
        let lower = (exp(2 * lowerZ) - 1) / (exp(2 * lowerZ) + 1)
        let upper = (exp(2 * upperZ) - 1) / (exp(2 * upperZ) + 1)
        
        return (lower: lower, upper: upper)
    }
    
    private func cumulativeNormalDistribution(_ x: Double) -> Double {
        // Simplified normal distribution CDF
        // In a real implementation, you'd use a proper statistical library
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
}

// MARK: - Health-Specific Correlation Analysis

extension CorrelationAnalysis {
    
    /// Analyze correlations between vital signs
    public func analyzeVitalSignsCorrelation(
        heartRate: [Double],
        bloodPressure: [Double],
        oxygenSaturation: [Double],
        temperature: [Double]
    ) async throws -> MultiVariateCorrelation {
        
        let variables = [heartRate, bloodPressure, oxygenSaturation, temperature]
        let variableNames = ["Heart Rate", "Blood Pressure", "Oxygen Saturation", "Temperature"]
        
        return try await calculateCorrelationMatrix(
            variables: variables,
            variableNames: variableNames,
            type: .pearson
        )
    }
    
    /// Analyze correlation between symptoms and treatments
    public func analyzeSymptomTreatmentCorrelation(
        symptomSeverity: [Double],
        medicationDosage: [Double],
        treatmentDuration: [Double]
    ) async throws -> CorrelationResult {
        
        // Calculate correlation between symptom improvement and treatment intensity
        let treatmentIntensity = zip(medicationDosage, treatmentDuration).map { $0 * $1 }
        
        return try await calculateCorrelation(
            variable1: symptomSeverity,
            variable2: treatmentIntensity,
            type: .spearman
        )
    }
    
    /// Analyze lifestyle factors correlation with health outcomes
    public func analyzeLifestyleHealthCorrelation(
        exerciseMinutes: [Double],
        sleepHours: [Double],
        stressLevel: [Double],
        healthScore: [Double]
    ) async throws -> MultiVariateCorrelation {
        
        let variables = [exerciseMinutes, sleepHours, stressLevel, healthScore]
        let variableNames = ["Exercise Minutes", "Sleep Hours", "Stress Level", "Health Score"]
        
        return try await calculateCorrelationMatrix(
            variables: variables,
            variableNames: variableNames,
            type: .pearson
        )
    }
}
