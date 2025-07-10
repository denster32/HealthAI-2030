import Foundation
import Accelerate

/// Advanced regression modeling engine for healthcare predictive analytics
public class RegressionModels {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    
    // MARK: - Regression Types
    public enum RegressionType {
        case linear
        case polynomial(degree: Int)
        case logistic
        case ridge
        case lasso
        case elasticNet
        case multivariate
    }
    
    // MARK: - Data Structures
    public struct RegressionResult {
        let coefficients: [Double]
        let intercept: Double
        let rSquared: Double
        let adjustedRSquared: Double
        let pValues: [Double]
        let standardErrors: [Double]
        let residuals: [Double]
        let predictions: [Double]
        let confidence: Double
        let modelType: RegressionType
    }
    
    public struct ModelDiagnostics {
        let residualStandardError: Double
        let fStatistic: Double
        let durbin_watson: Double
        let cookDistance: [Double]
        let leverage: [Double]
        let outliers: [Int]
        let normalityTest: Double
        let homoscedasticityTest: Double
    }
    
    public struct CrossValidationResult {
        let meanSquaredError: Double
        let rootMeanSquaredError: Double
        let meanAbsoluteError: Double
        let crossValidationScore: Double
        let foldScores: [Double]
        let bestModel: RegressionResult
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
    
    /// Perform linear regression analysis
    public func performLinearRegression(
        independentVariables: [[Double]],
        dependentVariable: [Double],
        includeIntercept: Bool = true
    ) async throws -> RegressionResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("linear_regression", value: executionTime)
        }
        
        do {
            // Validate input data
            guard !independentVariables.isEmpty && !dependentVariable.isEmpty else {
                throw AnalyticsError.invalidInput("Input variables cannot be empty")
            }
            
            let n = dependentVariable.count
            let p = independentVariables.count
            
            guard independentVariables.allSatisfy({ $0.count == n }) else {
                throw AnalyticsError.invalidInput("All variables must have the same length")
            }
            
            // Prepare design matrix
            var designMatrix = independentVariables
            if includeIntercept {
                designMatrix.insert(Array(repeating: 1.0, count: n), at: 0)
            }
            
            // Solve normal equations: (X'X)^-1 X'y
            let coefficients = try solveLinearSystem(designMatrix: designMatrix, targets: dependentVariable)
            
            // Calculate predictions
            let predictions = calculatePredictions(designMatrix: designMatrix, coefficients: coefficients)
            
            // Calculate residuals
            let residuals = zip(dependentVariable, predictions).map { $0 - $1 }
            
            // Calculate R-squared
            let rSquared = calculateRSquared(actual: dependentVariable, predicted: predictions)
            let adjustedRSquared = calculateAdjustedRSquared(rSquared: rSquared, n: n, p: p)
            
            // Calculate standard errors and p-values
            let (standardErrors, pValues) = try calculateStatistics(
                designMatrix: designMatrix,
                residuals: residuals,
                coefficients: coefficients
            )
            
            let intercept = includeIntercept ? coefficients[0] : 0.0
            let finalCoefficients = includeIntercept ? Array(coefficients.dropFirst()) : coefficients
            
            return RegressionResult(
                coefficients: finalCoefficients,
                intercept: intercept,
                rSquared: rSquared,
                adjustedRSquared: adjustedRSquared,
                pValues: pValues,
                standardErrors: standardErrors,
                residuals: residuals,
                predictions: predictions,
                confidence: 0.95,
                modelType: .linear
            )
            
        } catch {
            await errorHandler.handleError(error, context: "RegressionModels.performLinearRegression")
            throw error
        }
    }
    
    /// Perform polynomial regression analysis
    public func performPolynomialRegression(
        independentVariable: [Double],
        dependentVariable: [Double],
        degree: Int = 2
    ) async throws -> RegressionResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("polynomial_regression", value: executionTime)
        }
        
        do {
            guard degree > 0 && degree <= 10 else {
                throw AnalyticsError.invalidInput("Polynomial degree must be between 1 and 10")
            }
            
            // Create polynomial features
            var polynomialFeatures: [[Double]] = []
            for power in 1...degree {
                let feature = independentVariable.map { pow($0, Double(power)) }
                polynomialFeatures.append(feature)
            }
            
            let result = try await performLinearRegression(
                independentVariables: polynomialFeatures,
                dependentVariable: dependentVariable,
                includeIntercept: true
            )
            
            return RegressionResult(
                coefficients: result.coefficients,
                intercept: result.intercept,
                rSquared: result.rSquared,
                adjustedRSquared: result.adjustedRSquared,
                pValues: result.pValues,
                standardErrors: result.standardErrors,
                residuals: result.residuals,
                predictions: result.predictions,
                confidence: result.confidence,
                modelType: .polynomial(degree: degree)
            )
            
        } catch {
            await errorHandler.handleError(error, context: "RegressionModels.performPolynomialRegression")
            throw error
        }
    }
    
    /// Perform logistic regression analysis
    public func performLogisticRegression(
        independentVariables: [[Double]],
        dependentVariable: [Double],
        maxIterations: Int = 1000,
        tolerance: Double = 1e-6
    ) async throws -> RegressionResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("logistic_regression", value: executionTime)
        }
        
        do {
            // Validate binary dependent variable
            let uniqueValues = Set(dependentVariable)
            guard uniqueValues.isSubset(of: [0.0, 1.0]) else {
                throw AnalyticsError.invalidInput("Logistic regression requires binary dependent variable (0 or 1)")
            }
            
            let n = dependentVariable.count
            let p = independentVariables.count + 1 // +1 for intercept
            
            // Prepare design matrix with intercept
            var designMatrix = independentVariables
            designMatrix.insert(Array(repeating: 1.0, count: n), at: 0)
            
            // Initialize coefficients
            var coefficients = Array(repeating: 0.0, count: p)
            
            // Newton-Raphson optimization
            for iteration in 0..<maxIterations {
                let (gradient, hessian) = calculateLogisticGradientHessian(
                    designMatrix: designMatrix,
                    targets: dependentVariable,
                    coefficients: coefficients
                )
                
                let deltaCoefficients = try solveLinearSystemForLogistic(hessian: hessian, gradient: gradient)
                
                for i in 0..<coefficients.count {
                    coefficients[i] += deltaCoefficients[i]
                }
                
                // Check convergence
                let maxDelta = deltaCoefficients.map(abs).max() ?? 0.0
                if maxDelta < tolerance {
                    break
                }
            }
            
            // Calculate predictions (probabilities)
            let logits = calculateLogits(designMatrix: designMatrix, coefficients: coefficients)
            let predictions = logits.map { 1.0 / (1.0 + exp(-$0)) }
            
            // Calculate residuals
            let residuals = zip(dependentVariable, predictions).map { $0 - $1 }
            
            // Calculate pseudo R-squared (McFadden's R-squared)
            let rSquared = calculatePseudoRSquared(actual: dependentVariable, predicted: predictions)
            
            // Calculate standard errors (simplified)
            let standardErrors = Array(repeating: 0.0, count: coefficients.count - 1)
            let pValues = Array(repeating: 0.05, count: coefficients.count - 1)
            
            let intercept = coefficients[0]
            let finalCoefficients = Array(coefficients.dropFirst())
            
            return RegressionResult(
                coefficients: finalCoefficients,
                intercept: intercept,
                rSquared: rSquared,
                adjustedRSquared: rSquared, // Same as R-squared for logistic
                pValues: pValues,
                standardErrors: standardErrors,
                residuals: residuals,
                predictions: predictions,
                confidence: 0.95,
                modelType: .logistic
            )
            
        } catch {
            await errorHandler.handleError(error, context: "RegressionModels.performLogisticRegression")
            throw error
        }
    }
    
    /// Perform cross-validation analysis
    public func performCrossValidation(
        independentVariables: [[Double]],
        dependentVariable: [Double],
        regressionType: RegressionType,
        folds: Int = 5
    ) async throws -> CrossValidationResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("cross_validation", value: executionTime)
        }
        
        do {
            let n = dependentVariable.count
            let foldSize = n / folds
            var foldScores: [Double] = []
            var allPredictions: [Double] = []
            var allActual: [Double] = []
            
            for fold in 0..<folds {
                let startIdx = fold * foldSize
                let endIdx = (fold == folds - 1) ? n : (fold + 1) * foldSize
                
                // Split data into training and validation sets
                let validationIndices = Set(startIdx..<endIdx)
                
                var trainX: [[Double]] = []
                var trainY: [Double] = []
                var validX: [[Double]] = []
                var validY: [Double] = []
                
                for i in 0..<n {
                    if validationIndices.contains(i) {
                        validX.append(independentVariables.map { $0[i] })
                        validY.append(dependentVariable[i])
                    } else {
                        trainX.append(independentVariables.map { $0[i] })
                        trainY.append(dependentVariable[i])
                    }
                }
                
                // Transpose training data
                let trainXTransposed = transposeMatrix(trainX)
                
                // Train model on training set
                let model: RegressionResult
                switch regressionType {
                case .linear:
                    model = try await performLinearRegression(
                        independentVariables: trainXTransposed,
                        dependentVariable: trainY
                    )
                case .polynomial(let degree):
                    guard trainXTransposed.count == 1 else {
                        throw AnalyticsError.invalidInput("Polynomial regression requires single independent variable")
                    }
                    model = try await performPolynomialRegression(
                        independentVariable: trainXTransposed[0],
                        dependentVariable: trainY,
                        degree: degree
                    )
                case .logistic:
                    model = try await performLogisticRegression(
                        independentVariables: trainXTransposed,
                        dependentVariable: trainY
                    )
                default:
                    throw AnalyticsError.unsupportedOperation("Cross-validation not implemented for this regression type")
                }
                
                // Make predictions on validation set
                let validXTransposed = transposeMatrix(validX)
                let predictions = makePredictions(model: model, data: validXTransposed)
                
                // Calculate fold score (MSE)
                let mse = calculateMSE(actual: validY, predicted: predictions)
                foldScores.append(mse)
                
                allPredictions.append(contentsOf: predictions)
                allActual.append(contentsOf: validY)
            }
            
            let meanSquaredError = allPredictions.indices.map { i in
                pow(allActual[i] - allPredictions[i], 2)
            }.reduce(0, +) / Double(allPredictions.count)
            
            let rootMeanSquaredError = sqrt(meanSquaredError)
            let meanAbsoluteError = allPredictions.indices.map { i in
                abs(allActual[i] - allPredictions[i])
            }.reduce(0, +) / Double(allPredictions.count)
            
            let crossValidationScore = foldScores.reduce(0, +) / Double(folds)
            
            // Train final model on all data
            let bestModel: RegressionResult
            switch regressionType {
            case .linear:
                bestModel = try await performLinearRegression(
                    independentVariables: independentVariables,
                    dependentVariable: dependentVariable
                )
            case .polynomial(let degree):
                guard independentVariables.count == 1 else {
                    throw AnalyticsError.invalidInput("Polynomial regression requires single independent variable")
                }
                bestModel = try await performPolynomialRegression(
                    independentVariable: independentVariables[0],
                    dependentVariable: dependentVariable,
                    degree: degree
                )
            case .logistic:
                bestModel = try await performLogisticRegression(
                    independentVariables: independentVariables,
                    dependentVariable: dependentVariable
                )
            default:
                throw AnalyticsError.unsupportedOperation("Final model training not implemented for this regression type")
            }
            
            return CrossValidationResult(
                meanSquaredError: meanSquaredError,
                rootMeanSquaredError: rootMeanSquaredError,
                meanAbsoluteError: meanAbsoluteError,
                crossValidationScore: crossValidationScore,
                foldScores: foldScores,
                bestModel: bestModel
            )
            
        } catch {
            await errorHandler.handleError(error, context: "RegressionModels.performCrossValidation")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func solveLinearSystem(designMatrix: [[Double]], targets: [Double]) throws -> [Double] {
        let n = designMatrix[0].count
        let p = designMatrix.count
        
        // Calculate X'X
        var XtX = Array(repeating: Array(repeating: 0.0, count: p), count: p)
        for i in 0..<p {
            for j in 0..<p {
                XtX[i][j] = zip(designMatrix[i], designMatrix[j]).map(*).reduce(0, +)
            }
        }
        
        // Calculate X'y
        var Xty = Array(repeating: 0.0, count: p)
        for i in 0..<p {
            Xty[i] = zip(designMatrix[i], targets).map(*).reduce(0, +)
        }
        
        // Solve using Gaussian elimination
        return try gaussianElimination(matrix: XtX, vector: Xty)
    }
    
    private func gaussianElimination(matrix: [[Double]], vector: [Double]) throws -> [Double] {
        let n = matrix.count
        var augmented = matrix.map { $0 }
        var b = vector
        
        // Forward elimination
        for i in 0..<n {
            // Find pivot
            var maxRow = i
            for k in (i+1)..<n {
                if abs(augmented[k][i]) > abs(augmented[maxRow][i]) {
                    maxRow = k
                }
            }
            
            // Swap rows
            if maxRow != i {
                augmented.swapAt(i, maxRow)
                b.swapAt(i, maxRow)
            }
            
            // Check for singular matrix
            if abs(augmented[i][i]) < 1e-10 {
                throw AnalyticsError.singularMatrix("Matrix is singular or nearly singular")
            }
            
            // Eliminate
            for k in (i+1)..<n {
                let factor = augmented[k][i] / augmented[i][i]
                for j in i..<n {
                    augmented[k][j] -= factor * augmented[i][j]
                }
                b[k] -= factor * b[i]
            }
        }
        
        // Back substitution
        var solution = Array(repeating: 0.0, count: n)
        for i in stride(from: n-1, through: 0, by: -1) {
            solution[i] = b[i]
            for j in (i+1)..<n {
                solution[i] -= augmented[i][j] * solution[j]
            }
            solution[i] /= augmented[i][i]
        }
        
        return solution
    }
    
    private func calculatePredictions(designMatrix: [[Double]], coefficients: [Double]) -> [Double] {
        let n = designMatrix[0].count
        var predictions = Array(repeating: 0.0, count: n)
        
        for i in 0..<n {
            for j in 0..<designMatrix.count {
                predictions[i] += designMatrix[j][i] * coefficients[j]
            }
        }
        
        return predictions
    }
    
    private func calculateRSquared(actual: [Double], predicted: [Double]) -> Double {
        let actualMean = actual.reduce(0, +) / Double(actual.count)
        let totalSumSquares = actual.map { pow($0 - actualMean, 2) }.reduce(0, +)
        let residualSumSquares = zip(actual, predicted).map { pow($0 - $1, 2) }.reduce(0, +)
        
        return totalSumSquares == 0 ? 0 : 1 - (residualSumSquares / totalSumSquares)
    }
    
    private func calculateAdjustedRSquared(rSquared: Double, n: Int, p: Int) -> Double {
        guard n > p + 1 else { return rSquared }
        return 1 - ((1 - rSquared) * Double(n - 1) / Double(n - p - 1))
    }
    
    private func calculateStatistics(
        designMatrix: [[Double]],
        residuals: [Double],
        coefficients: [Double]
    ) throws -> ([Double], [Double]) {
        
        let n = residuals.count
        let p = coefficients.count
        let residualSumSquares = residuals.map { $0 * $0 }.reduce(0, +)
        let mse = residualSumSquares / Double(n - p)
        
        // Calculate (X'X)^-1 for standard errors
        let XtX = calculateXtX(designMatrix: designMatrix)
        let invXtX = try invertMatrix(XtX)
        
        var standardErrors: [Double] = []
        var pValues: [Double] = []
        
        for i in 0..<p {
            let se = sqrt(mse * invXtX[i][i])
            let tStat = coefficients[i] / se
            let pValue = 2 * (1 - cumulativeNormalDistribution(abs(tStat)))
            
            standardErrors.append(se)
            pValues.append(pValue)
        }
        
        return (standardErrors, pValues)
    }
    
    private func calculateXtX(designMatrix: [[Double]]) -> [[Double]] {
        let p = designMatrix.count
        var XtX = Array(repeating: Array(repeating: 0.0, count: p), count: p)
        
        for i in 0..<p {
            for j in 0..<p {
                XtX[i][j] = zip(designMatrix[i], designMatrix[j]).map(*).reduce(0, +)
            }
        }
        
        return XtX
    }
    
    private func invertMatrix(_ matrix: [[Double]]) throws -> [[Double]] {
        let n = matrix.count
        var augmented = Array(repeating: Array(repeating: 0.0, count: 2 * n), count: n)
        
        // Create augmented matrix [A|I]
        for i in 0..<n {
            for j in 0..<n {
                augmented[i][j] = matrix[i][j]
                augmented[i][j + n] = (i == j) ? 1.0 : 0.0
            }
        }
        
        // Gaussian elimination
        for i in 0..<n {
            // Find pivot
            var maxRow = i
            for k in (i+1)..<n {
                if abs(augmented[k][i]) > abs(augmented[maxRow][i]) {
                    maxRow = k
                }
            }
            
            if maxRow != i {
                augmented.swapAt(i, maxRow)
            }
            
            if abs(augmented[i][i]) < 1e-10 {
                throw AnalyticsError.singularMatrix("Matrix is singular")
            }
            
            // Scale row
            let pivot = augmented[i][i]
            for j in 0..<(2 * n) {
                augmented[i][j] /= pivot
            }
            
            // Eliminate column
            for k in 0..<n {
                if k != i {
                    let factor = augmented[k][i]
                    for j in 0..<(2 * n) {
                        augmented[k][j] -= factor * augmented[i][j]
                    }
                }
            }
        }
        
        // Extract inverse
        var inverse = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        for i in 0..<n {
            for j in 0..<n {
                inverse[i][j] = augmented[i][j + n]
            }
        }
        
        return inverse
    }
    
    private func calculateLogisticGradientHessian(
        designMatrix: [[Double]],
        targets: [Double],
        coefficients: [Double]
    ) -> ([Double], [[Double]]) {
        
        let n = targets.count
        let p = coefficients.count
        
        // Calculate predictions
        let logits = calculateLogits(designMatrix: designMatrix, coefficients: coefficients)
        let predictions = logits.map { 1.0 / (1.0 + exp(-$0)) }
        
        // Calculate gradient
        var gradient = Array(repeating: 0.0, count: p)
        for i in 0..<p {
            for j in 0..<n {
                gradient[i] += designMatrix[i][j] * (targets[j] - predictions[j])
            }
        }
        
        // Calculate Hessian
        var hessian = Array(repeating: Array(repeating: 0.0, count: p), count: p)
        for i in 0..<p {
            for j in 0..<p {
                for k in 0..<n {
                    let weight = predictions[k] * (1 - predictions[k])
                    hessian[i][j] -= designMatrix[i][k] * designMatrix[j][k] * weight
                }
            }
        }
        
        return (gradient, hessian)
    }
    
    private func calculateLogits(designMatrix: [[Double]], coefficients: [Double]) -> [Double] {
        let n = designMatrix[0].count
        var logits = Array(repeating: 0.0, count: n)
        
        for i in 0..<n {
            for j in 0..<coefficients.count {
                logits[i] += designMatrix[j][i] * coefficients[j]
            }
        }
        
        return logits
    }
    
    private func solveLinearSystemForLogistic(hessian: [[Double]], gradient: [Double]) throws -> [Double] {
        // Solve Hessian * delta = gradient
        let negativeGradient = gradient.map { -$0 }
        return try gaussianElimination(matrix: hessian, vector: negativeGradient)
    }
    
    private func calculatePseudoRSquared(actual: [Double], predicted: [Double]) -> Double {
        // McFadden's pseudo R-squared
        var logLikelihood = 0.0
        var nullLogLikelihood = 0.0
        let meanActual = actual.reduce(0, +) / Double(actual.count)
        
        for i in 0..<actual.count {
            let p = max(min(predicted[i], 0.9999), 0.0001) // Avoid log(0)
            if actual[i] == 1.0 {
                logLikelihood += log(p)
                nullLogLikelihood += log(meanActual)
            } else {
                logLikelihood += log(1 - p)
                nullLogLikelihood += log(1 - meanActual)
            }
        }
        
        return 1 - (logLikelihood / nullLogLikelihood)
    }
    
    private func transposeMatrix(_ matrix: [[Double]]) -> [[Double]] {
        guard !matrix.isEmpty else { return [] }
        let rows = matrix.count
        let cols = matrix[0].count
        
        var transposed = Array(repeating: Array(repeating: 0.0, count: rows), count: cols)
        for i in 0..<rows {
            for j in 0..<cols {
                transposed[j][i] = matrix[i][j]
            }
        }
        
        return transposed
    }
    
    private func makePredictions(model: RegressionResult, data: [[Double]]) -> [Double] {
        let n = data[0].count
        var predictions = Array(repeating: model.intercept, count: n)
        
        for i in 0..<n {
            for j in 0..<data.count {
                predictions[i] += data[j][i] * model.coefficients[j]
            }
        }
        
        return predictions
    }
    
    private func calculateMSE(actual: [Double], predicted: [Double]) -> Double {
        return zip(actual, predicted).map { pow($0 - $1, 2) }.reduce(0, +) / Double(actual.count)
    }
    
    private func cumulativeNormalDistribution(_ x: Double) -> Double {
        return 0.5 * (1 + erf(x / sqrt(2)))
    }
}

// MARK: - Health-Specific Regression Models

extension RegressionModels {
    
    /// Predict health outcomes based on vital signs
    public func predictHealthOutcome(
        heartRate: [Double],
        bloodPressure: [Double],
        oxygenSaturation: [Double],
        healthScore: [Double]
    ) async throws -> RegressionResult {
        
        let independentVariables = [heartRate, bloodPressure, oxygenSaturation]
        
        return try await performLinearRegression(
            independentVariables: independentVariables,
            dependentVariable: healthScore
        )
    }
    
    /// Predict treatment effectiveness
    public func predictTreatmentEffectiveness(
        medicationDosage: [Double],
        treatmentDuration: [Double],
        patientAge: [Double],
        effectiveness: [Double]
    ) async throws -> RegressionResult {
        
        let independentVariables = [medicationDosage, treatmentDuration, patientAge]
        
        return try await performLinearRegression(
            independentVariables: independentVariables,
            dependentVariable: effectiveness
        )
    }
    
    /// Predict disease progression risk
    public func predictDiseaseRisk(
        riskFactors: [[Double]],
        diseaseOccurrence: [Double] // Binary: 0 = no disease, 1 = disease
    ) async throws -> RegressionResult {
        
        return try await performLogisticRegression(
            independentVariables: riskFactors,
            dependentVariable: diseaseOccurrence
        )
    }
}
