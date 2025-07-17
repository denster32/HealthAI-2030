import Foundation
import Combine

/// Advanced machine learning predictive models for healthcare analytics
public class MLPredictiveModels {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    private let statisticalEngine: StatisticalAnalysisEngine
    
    // MARK: - Model Types
    public enum ModelType {
        case linearRegression
        case logisticRegression
        case randomForest
        case gradientBoosting
        case neuralNetwork
        case supportVectorMachine
        case naiveBayes
        case kMeansClustering
        case hierarchicalClustering
        case deepLearning
    }
    
    // MARK: - Data Structures
    public struct MLModel {
        let modelId: String
        let modelType: ModelType
        let parameters: [String: Any]
        let trainingData: TrainingData
        let performance: ModelPerformance
        let createdAt: Date
        let version: String
    }
    
    public struct TrainingData {
        let features: [[Double]]
        let targets: [Double]
        let featureNames: [String]
        let targetName: String
        let splitRatio: Double
    }
    
    public struct ModelPerformance {
        let accuracy: Double
        let precision: Double
        let recall: Double
        let f1Score: Double
        let auc: Double
        let mse: Double
        let rmse: Double
        let mae: Double
        let r2Score: Double
        let confusionMatrix: [[Int]]?
    }
    
    public struct PredictionResult {
        let predictions: [Double]
        let probabilities: [[Double]]?
        let confidence: [Double]
        let featureImportance: [String: Double]
        let model: MLModel
    }
    
    public struct ClusteringResult {
        let clusters: [Int]
        let centroids: [[Double]]
        let inertia: Double
        let silhouetteScore: Double
        let model: MLModel
    }
    
    public struct CrossValidationResult {
        let foldScores: [Double]
        let meanScore: Double
        let standardDeviation: Double
        let bestModel: MLModel
        let bestParameters: [String: Any]
    }
    
    // MARK: - Model State
    private var trainedModels: [String: MLModel] = [:]
    private var modelCache: [String: Any] = [:]
    
    // MARK: - Initialization
    public init(analyticsEngine: AdvancedAnalyticsEngine,
                configManager: AnalyticsConfiguration,
                errorHandler: AnalyticsErrorHandling,
                performanceMonitor: AnalyticsPerformanceMonitor,
                statisticalEngine: StatisticalAnalysisEngine) {
        self.analyticsEngine = analyticsEngine
        self.configManager = configManager
        self.errorHandler = errorHandler
        self.performanceMonitor = performanceMonitor
        self.statisticalEngine = statisticalEngine
    }
    
    // MARK: - Public Methods
    
    /// Train a machine learning model
    public func trainModel(
        features: [[Double]],
        targets: [Double],
        featureNames: [String],
        targetName: String,
        modelType: ModelType,
        parameters: [String: Any] = [:]
    ) async throws -> MLModel {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("model_training", value: executionTime)
        }
        
        do {
            // Validate input data
            guard !features.isEmpty && !targets.isEmpty else {
                throw AnalyticsError.invalidInput("Features and targets cannot be empty")
            }
            
            guard features.count == featureNames.count else {
                throw AnalyticsError.invalidInput("Number of features must match feature names")
            }
            
            let numSamples = targets.count
            guard features.allSatisfy({ $0.count == numSamples }) else {
                throw AnalyticsError.invalidInput("All features must have the same number of samples")
            }
            
            // Prepare training data
            let trainingData = TrainingData(
                features: features,
                targets: targets,
                featureNames: featureNames,
                targetName: targetName,
                splitRatio: parameters["split_ratio"] as? Double ?? 0.8
            )
            
            // Split data into training and testing sets
            let (trainFeatures, testFeatures, trainTargets, testTargets) = try splitData(
                features: features,
                targets: targets,
                splitRatio: trainingData.splitRatio
            )
            
            // Train the model
            let trainedParameters = try await trainModelInternal(
                features: trainFeatures,
                targets: trainTargets,
                modelType: modelType,
                parameters: parameters
            )
            
            // Evaluate the model
            let performance = try await evaluateModel(
                trainedParameters: trainedParameters,
                testFeatures: testFeatures,
                testTargets: testTargets,
                modelType: modelType
            )
            
            // Create model
            let modelId = UUID().uuidString
            let model = MLModel(
                modelId: modelId,
                modelType: modelType,
                parameters: trainedParameters,
                trainingData: trainingData,
                performance: performance,
                createdAt: Date(),
                version: "1.0"
            )
            
            // Store the model
            trainedModels[modelId] = model
            modelCache[modelId] = trainedParameters
            
            return model
            
        } catch {
            await errorHandler.handleError(error, context: "MLPredictiveModels.trainModel")
            throw error
        }
    }
    
    /// Make predictions using a trained model
    public func predict(
        modelId: String,
        features: [[Double]]
    ) async throws -> PredictionResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("model_prediction", value: executionTime)
        }
        
        do {
            guard let model = trainedModels[modelId] else {
                throw AnalyticsError.modelNotFound("Model with ID \(modelId) not found")
            }
            
            guard let modelParameters = modelCache[modelId] else {
                throw AnalyticsError.modelNotFound("Model parameters not found in cache")
            }
            
            // Validate feature dimensions
            guard features.count == model.trainingData.featureNames.count else {
                throw AnalyticsError.invalidInput("Feature count mismatch")
            }
            
            // Make predictions
            let (predictions, probabilities, confidence) = try await makePredictions(
                features: features,
                modelParameters: modelParameters,
                modelType: model.modelType
            )
            
            // Calculate feature importance
            let featureImportance = try calculateFeatureImportance(
                model: model,
                modelParameters: modelParameters
            )
            
            return PredictionResult(
                predictions: predictions,
                probabilities: probabilities,
                confidence: confidence,
                featureImportance: featureImportance,
                model: model
            )
            
        } catch {
            await errorHandler.handleError(error, context: "MLPredictiveModels.predict")
            throw error
        }
    }
    
    /// Perform clustering analysis
    public func performClustering(
        features: [[Double]],
        featureNames: [String],
        modelType: ModelType = .kMeansClustering,
        parameters: [String: Any] = [:]
    ) async throws -> ClusteringResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("clustering_analysis", value: executionTime)
        }
        
        do {
            let numClusters = parameters["num_clusters"] as? Int ?? 3
            
            let (clusters, centroids, inertia) = try await performClusteringInternal(
                features: features,
                modelType: modelType,
                numClusters: numClusters,
                parameters: parameters
            )
            
            let silhouetteScore = try calculateSilhouetteScore(
                features: features,
                clusters: clusters,
                centroids: centroids
            )
            
            let modelId = UUID().uuidString
            let model = MLModel(
                modelId: modelId,
                modelType: modelType,
                parameters: parameters,
                trainingData: TrainingData(
                    features: features,
                    targets: [],
                    featureNames: featureNames,
                    targetName: "clusters",
                    splitRatio: 1.0
                ),
                performance: ModelPerformance(
                    accuracy: 0.0,
                    precision: 0.0,
                    recall: 0.0,
                    f1Score: 0.0,
                    auc: 0.0,
                    mse: inertia,
                    rmse: sqrt(inertia),
                    mae: 0.0,
                    r2Score: 0.0,
                    confusionMatrix: nil
                ),
                createdAt: Date(),
                version: "1.0"
            )
            
            return ClusteringResult(
                clusters: clusters,
                centroids: centroids,
                inertia: inertia,
                silhouetteScore: silhouetteScore,
                model: model
            )
            
        } catch {
            await errorHandler.handleError(error, context: "MLPredictiveModels.performClustering")
            throw error
        }
    }
    
    /// Perform cross-validation
    public func performCrossValidation(
        features: [[Double]],
        targets: [Double],
        featureNames: [String],
        targetName: String,
        modelType: ModelType,
        folds: Int = 5,
        parameterGrid: [[String: Any]] = []
    ) async throws -> CrossValidationResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("cross_validation", value: executionTime)
        }
        
        do {
            let gridToTest = parameterGrid.isEmpty ? [[:]] : parameterGrid
            var bestScore = -Double.infinity
            var bestParameters: [String: Any] = [:]
            var bestModel: MLModel?
            var allFoldScores: [[Double]] = []
            
            // Grid search over parameters
            for parameters in gridToTest {
                var foldScores: [Double] = []
                
                // K-fold cross-validation
                for fold in 0..<folds {
                    let (trainFeatures, validFeatures, trainTargets, validTargets) = try createFoldSplit(
                        features: features,
                        targets: targets,
                        fold: fold,
                        totalFolds: folds
                    )
                    
                    // Train model on fold
                    let trainedParameters = try await trainModelInternal(
                        features: trainFeatures,
                        targets: trainTargets,
                        modelType: modelType,
                        parameters: parameters
                    )
                    
                    // Evaluate on validation set
                    let (predictions, _, _) = try await makePredictions(
                        features: validFeatures,
                        modelParameters: trainedParameters,
                        modelType: modelType
                    )
                    
                    // Calculate score
                    let score = calculateValidationScore(
                        predictions: predictions,
                        targets: validTargets,
                        modelType: modelType
                    )
                    
                    foldScores.append(score)
                }
                
                allFoldScores.append(foldScores)
                let meanScore = foldScores.reduce(0, +) / Double(foldScores.count)
                
                if meanScore > bestScore {
                    bestScore = meanScore
                    bestParameters = parameters
                    
                    // Train final model with best parameters
                    bestModel = try await trainModel(
                        features: features,
                        targets: targets,
                        featureNames: featureNames,
                        targetName: targetName,
                        modelType: modelType,
                        parameters: bestParameters
                    )
                }
            }
            
            guard let finalBestModel = bestModel else {
                throw AnalyticsError.modelTrainingFailed("No valid model could be trained")
            }
            
            let bestFoldScores = allFoldScores[gridToTest.firstIndex(where: { 
                NSDictionary(dictionary: $0).isEqual(to: bestParameters) 
            }) ?? 0]
            
            let standardDeviation = sqrt(
                bestFoldScores.map { pow($0 - bestScore, 2) }.reduce(0, +) / Double(bestFoldScores.count)
            )
            
            return CrossValidationResult(
                foldScores: bestFoldScores,
                meanScore: bestScore,
                standardDeviation: standardDeviation,
                bestModel: finalBestModel,
                bestParameters: bestParameters
            )
            
        } catch {
            await errorHandler.handleError(error, context: "MLPredictiveModels.performCrossValidation")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func splitData(
        features: [[Double]],
        targets: [Double],
        splitRatio: Double
    ) throws -> ([[Double]], [[Double]], [Double], [Double]) {
        
        let numSamples = targets.count
        let trainSize = Int(Double(numSamples) * splitRatio)
        
        // Shuffle indices
        let shuffledIndices = Array(0..<numSamples).shuffled()
        let trainIndices = Array(shuffledIndices.prefix(trainSize))
        let testIndices = Array(shuffledIndices.suffix(numSamples - trainSize))
        
        let trainFeatures = features.map { feature in
            trainIndices.map { feature[$0] }
        }
        
        let testFeatures = features.map { feature in
            testIndices.map { feature[$0] }
        }
        
        let trainTargets = trainIndices.map { targets[$0] }
        let testTargets = testIndices.map { targets[$0] }
        
        return (trainFeatures, testFeatures, trainTargets, testTargets)
    }
    
    private func trainModelInternal(
        features: [[Double]],
        targets: [Double],
        modelType: ModelType,
        parameters: [String: Any]
    ) async throws -> [String: Any] {
        
        switch modelType {
        case .linearRegression:
            return try trainLinearRegression(features: features, targets: targets, parameters: parameters)
            
        case .logisticRegression:
            return try trainLogisticRegression(features: features, targets: targets, parameters: parameters)
            
        case .randomForest:
            return try trainRandomForest(features: features, targets: targets, parameters: parameters)
            
        case .gradientBoosting:
            return try trainGradientBoosting(features: features, targets: targets, parameters: parameters)
            
        case .neuralNetwork:
            return try trainNeuralNetwork(features: features, targets: targets, parameters: parameters)
            
        case .supportVectorMachine:
            return try trainSVM(features: features, targets: targets, parameters: parameters)
            
        case .naiveBayes:
            return try trainNaiveBayes(features: features, targets: targets, parameters: parameters)
            
        default:
            throw AnalyticsError.unsupportedOperation("Model type not supported for training")
        }
    }
    
    private func trainLinearRegression(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        // Use normal equation: θ = (X'X)^-1 X'y
        let numFeatures = features.count
        let numSamples = targets.count
        
        // Add intercept term
        var designMatrix = features
        designMatrix.insert(Array(repeating: 1.0, count: numSamples), at: 0)
        
        // Calculate X'X
        var XtX = Array(repeating: Array(repeating: 0.0, count: numFeatures + 1), count: numFeatures + 1)
        for i in 0..<(numFeatures + 1) {
            for j in 0..<(numFeatures + 1) {
                XtX[i][j] = zip(designMatrix[i], designMatrix[j]).map(*).reduce(0, +)
            }
        }
        
        // Calculate X'y
        var Xty = Array(repeating: 0.0, count: numFeatures + 1)
        for i in 0..<(numFeatures + 1) {
            Xty[i] = zip(designMatrix[i], targets).map(*).reduce(0, +)
        }
        
        // Solve linear system
        let coefficients = try solveLinearSystem(matrix: XtX, vector: Xty)
        
        return [
            "coefficients": coefficients,
            "intercept": coefficients[0],
            "weights": Array(coefficients.dropFirst())
        ]
    }
    
    private func trainLogisticRegression(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        let maxIterations = parameters["max_iterations"] as? Int ?? 1000
        let learningRate = parameters["learning_rate"] as? Double ?? 0.01
        let tolerance = parameters["tolerance"] as? Double ?? 1e-6
        
        let numFeatures = features.count
        let numSamples = targets.count
        
        // Add intercept term
        var designMatrix = features
        designMatrix.insert(Array(repeating: 1.0, count: numSamples), at: 0)
        
        // Initialize coefficients
        var coefficients = Array(repeating: 0.0, count: numFeatures + 1)
        
        // Gradient descent
        for iteration in 0..<maxIterations {
            // Calculate predictions
            let logits = calculateLogits(designMatrix: designMatrix, coefficients: coefficients)
            let predictions = logits.map { 1.0 / (1.0 + exp(-$0)) }
            
            // Calculate gradient
            var gradient = Array(repeating: 0.0, count: numFeatures + 1)
            for i in 0..<(numFeatures + 1) {
                for j in 0..<numSamples {
                    gradient[i] += designMatrix[i][j] * (targets[j] - predictions[j])
                }
                gradient[i] /= Double(numSamples)
            }
            
            // Update coefficients
            var maxChange = 0.0
            for i in 0..<coefficients.count {
                let change = learningRate * gradient[i]
                coefficients[i] += change
                maxChange = max(maxChange, abs(change))
            }
            
            // Check convergence
            if maxChange < tolerance {
                break
            }
        }
        
        return [
            "coefficients": coefficients,
            "intercept": coefficients[0],
            "weights": Array(coefficients.dropFirst())
        ]
    }
    
    private func trainRandomForest(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        let numTrees = parameters["num_trees"] as? Int ?? 100
        let maxDepth = parameters["max_depth"] as? Int ?? 10
        let minSamplesLeaf = parameters["min_samples_leaf"] as? Int ?? 1
        let maxFeatures = parameters["max_features"] as? Int ?? Int(sqrt(Double(features.count)))
        
        var trees: [DecisionTree] = []
        
        for _ in 0..<numTrees {
            // Bootstrap sampling
            let numSamples = targets.count
            let bootstrapIndices = (0..<numSamples).map { _ in Int.random(in: 0..<numSamples) }
            
            let bootstrapFeatures = features.map { feature in
                bootstrapIndices.map { feature[$0] }
            }
            let bootstrapTargets = bootstrapIndices.map { targets[$0] }
            
            // Feature bagging
            let selectedFeatures = Array(0..<features.count).shuffled().prefix(maxFeatures)
            let selectedFeatureData = selectedFeatures.map { bootstrapFeatures[$0] }
            
            // Train decision tree
            let tree = try trainDecisionTree(
                features: selectedFeatureData,
                targets: bootstrapTargets,
                maxDepth: maxDepth,
                minSamplesLeaf: minSamplesLeaf,
                selectedFeatures: Array(selectedFeatures)
            )
            
            trees.append(tree)
        }
        
        return [
            "trees": trees,
            "num_trees": numTrees,
            "max_features": maxFeatures
        ]
    }
    
    private func trainGradientBoosting(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {

        let numIterations = parameters["num_iterations"] as? Int ?? 100
        let learningRate = parameters["learning_rate"] as? Double ?? 0.1
        let maxDepth = parameters["max_depth"] as? Int ?? 3
        let earlyStoppingRounds = parameters["early_stopping_rounds"] as? Int ?? 0
        let earlyStoppingTolerance = parameters["early_stopping_tolerance"] as? Double ?? 0.0

        // Initialize with mean prediction
        let initialPrediction = targets.reduce(0, +) / Double(targets.count)
        var predictions = Array(repeating: initialPrediction, count: targets.count)
        var trees: [DecisionTree] = []

        var bestLoss = Double.greatestFiniteMagnitude
        var roundsWithoutImprovement = 0

        for _ in 0..<numIterations {
            // Calculate residuals
            let residuals = zip(targets, predictions).map { $0 - $1 }

            // Train tree on residuals
            let tree = try trainDecisionTree(
                features: features,
                targets: residuals,
                maxDepth: maxDepth,
                minSamplesLeaf: 1,
                selectedFeatures: Array(0..<features.count)
            )

            trees.append(tree)

            // Update predictions
            let treePredictions = try predictWithDecisionTree(tree: tree, features: features)
            for i in 0..<predictions.count {
                predictions[i] += learningRate * treePredictions[i]
            }

            // Early stopping check
            if earlyStoppingRounds > 0 {
                let mse = zip(targets, predictions).map { pow($0 - $1, 2) }.reduce(0, +) / Double(targets.count)
                if bestLoss - mse > earlyStoppingTolerance {
                    bestLoss = mse
                    roundsWithoutImprovement = 0
                } else {
                    roundsWithoutImprovement += 1
                    if roundsWithoutImprovement >= earlyStoppingRounds {
                        break
                    }
                }
            }
        }

        return [
            "trees": trees,
            "learning_rate": learningRate,
            "initial_prediction": initialPrediction,
            "iterations": trees.count
        ]
    }
    
    private func trainNeuralNetwork(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        let hiddenLayers = parameters["hidden_layers"] as? [Int] ?? [10, 5]
        let learningRate = parameters["learning_rate"] as? Double ?? 0.01
        let epochs = parameters["epochs"] as? Int ?? 100
        
        // Simple neural network implementation
        // In a real implementation, you'd use a proper deep learning framework
        
        let inputSize = features.count
        let outputSize = 1
        
        // Initialize weights and biases
        var weights: [[[Double]]] = []
        var biases: [[Double]] = []
        
        let layerSizes = [inputSize] + hiddenLayers + [outputSize]
        
        for i in 0..<(layerSizes.count - 1) {
            let currentSize = layerSizes[i]
            let nextSize = layerSizes[i + 1]
            
            // Xavier initialization
            let scale = sqrt(2.0 / Double(currentSize))
            let layerWeights = (0..<nextSize).map { _ in
                (0..<currentSize).map { _ in Double.random(in: -scale...scale) }
            }
            let layerBiases = Array(repeating: 0.0, count: nextSize)
            
            weights.append(layerWeights)
            biases.append(layerBiases)
        }
        
        // Training loop (simplified)
        for epoch in 0..<epochs {
            var totalLoss = 0.0
            
            for sampleIdx in 0..<targets.count {
                let input = features.map { $0[sampleIdx] }
                let target = targets[sampleIdx]
                
                // Forward pass
                let (output, activations) = forwardPass(input: input, weights: weights, biases: biases)
                
                // Calculate loss
                let loss = 0.5 * pow(output[0] - target, 2)
                totalLoss += loss
                
                // Backward pass (simplified)
                let _ = backwardPass(
                    target: target,
                    output: output,
                    activations: activations,
                    weights: &weights,
                    biases: &biases,
                    learningRate: learningRate
                )
            }
            
            // Optional: Print loss every 10 epochs
            if epoch % 10 == 0 {
                let avgLoss = totalLoss / Double(targets.count)
                print("Epoch \(epoch), Loss: \(avgLoss)")
            }
        }
        
        return [
            "weights": weights,
            "biases": biases,
            "hidden_layers": hiddenLayers,
            "architecture": layerSizes
        ]
    }
    
    private func trainSVM(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        // Simplified SVM implementation
        // In practice, you'd use optimized SVM libraries
        
        let C = parameters["C"] as? Double ?? 1.0
        let gamma = parameters["gamma"] as? Double ?? 1.0
        let tolerance = parameters["tolerance"] as? Double ?? 1e-3
        let maxIterations = parameters["max_iterations"] as? Int ?? 1000
        
        let numSamples = targets.count
        let numFeatures = features.count
        
        // Initialize alpha values
        var alphas = Array(repeating: 0.0, count: numSamples)
        var bias = 0.0
        
        // SMO algorithm (simplified)
        for iteration in 0..<maxIterations {
            var numChanged = 0
            
            for i in 0..<numSamples {
                let prediction = try svmPredict(
                    sample: features.map { $0[i] },
                    features: features,
                    targets: targets,
                    alphas: alphas,
                    bias: bias,
                    gamma: gamma
                )
                
                let error = prediction - targets[i]
                
                if (targets[i] * error < -tolerance && alphas[i] < C) ||
                   (targets[i] * error > tolerance && alphas[i] > 0) {
                    
                    // Select second alpha
                    let j = (i + 1) % numSamples
                    
                    // Simplified alpha update
                    let oldAlphaI = alphas[i]
                    let oldAlphaJ = alphas[j]
                    
                    // Calculate bounds
                    let L = max(0, alphas[j] - alphas[i])
                    let H = min(C, C + alphas[j] - alphas[i])
                    
                    if L == H { continue }
                    
                    // Update alpha
                    let eta = 2 * rbfKernel(x1: features.map { $0[i] }, x2: features.map { $0[j] }, gamma: gamma)
                        - rbfKernel(x1: features.map { $0[i] }, x2: features.map { $0[i] }, gamma: gamma)
                        - rbfKernel(x1: features.map { $0[j] }, x2: features.map { $0[j] }, gamma: gamma)
                    
                    if eta >= 0 { continue }
                    
                    alphas[j] = oldAlphaJ - targets[j] * (error - 0) / eta
                    alphas[j] = min(H, max(L, alphas[j]))
                    
                    if abs(alphas[j] - oldAlphaJ) < 1e-5 { continue }
                    
                    alphas[i] = oldAlphaI + targets[i] * targets[j] * (oldAlphaJ - alphas[j])
                    
                    numChanged += 1
                }
            }
            
            if numChanged == 0 { break }
        }
        
        return [
            "alphas": alphas,
            "bias": bias,
            "support_vectors": features,
            "support_vector_labels": targets,
            "C": C,
            "gamma": gamma
        ]
    }
    
    private func trainNaiveBayes(
        features: [[Double]],
        targets: [Double],
        parameters: [String: Any]
    ) throws -> [String: Any] {
        
        // Gaussian Naive Bayes
        let classes = Array(Set(targets)).sorted()
        var classPriors: [Double: Double] = [:]
        var featureMeans: [Double: [Double]] = [:]
        var featureVariances: [Double: [Double]] = [:]
        
        for cls in classes {
            let classIndices = targets.enumerated().compactMap { $1 == cls ? $0 : nil }
            let classCount = classIndices.count
            
            classPriors[cls] = Double(classCount) / Double(targets.count)
            
            var means: [Double] = []
            var variances: [Double] = []
            
            for featureIdx in 0..<features.count {
                let classFeatureValues = classIndices.map { features[featureIdx][$0] }
                let mean = classFeatureValues.reduce(0, +) / Double(classFeatureValues.count)
                let variance = classFeatureValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(classFeatureValues.count)
                
                means.append(mean)
                variances.append(max(variance, 1e-9)) // Avoid zero variance
            }
            
            featureMeans[cls] = means
            featureVariances[cls] = variances
        }
        
        return [
            "classes": classes,
            "class_priors": classPriors,
            "feature_means": featureMeans,
            "feature_variances": featureVariances
        ]
    }
    
    // MARK: - Helper Methods
    
    private func solveLinearSystem(matrix: [[Double]], vector: [Double]) throws -> [Double] {
        // Gaussian elimination with partial pivoting
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
                throw AnalyticsError.singularMatrix("Matrix is singular")
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
    
    private func calculateLogits(designMatrix: [[Double]], coefficients: [Double]) -> [Double] {
        let numSamples = designMatrix[0].count
        var logits = Array(repeating: 0.0, count: numSamples)
        
        for i in 0..<numSamples {
            for j in 0..<coefficients.count {
                logits[i] += designMatrix[j][i] * coefficients[j]
            }
        }
        
        return logits
    }
    
    // Decision Tree structures and methods
    private struct DecisionTree {
        let root: TreeNode
        let selectedFeatures: [Int]
    }
    
    private struct TreeNode {
        let isLeaf: Bool
        let prediction: Double?
        let splitFeature: Int?
        let splitValue: Double?
        let left: TreeNode?
        let right: TreeNode?
    }
    
    private func trainDecisionTree(
        features: [[Double]],
        targets: [Double],
        maxDepth: Int,
        minSamplesLeaf: Int,
        selectedFeatures: [Int]
    ) throws -> DecisionTree {
        
        let root = buildTreeNode(
            features: features,
            targets: targets,
            depth: 0,
            maxDepth: maxDepth,
            minSamplesLeaf: minSamplesLeaf,
            selectedFeatures: selectedFeatures
        )
        
        return DecisionTree(root: root, selectedFeatures: selectedFeatures)
    }
    
    private func buildTreeNode(
        features: [[Double]],
        targets: [Double],
        depth: Int,
        maxDepth: Int,
        minSamplesLeaf: Int,
        selectedFeatures: [Int]
    ) -> TreeNode {
        
        // Base cases
        if depth >= maxDepth || targets.count <= minSamplesLeaf || Set(targets).count == 1 {
            let prediction = targets.reduce(0, +) / Double(targets.count)
            return TreeNode(isLeaf: true, prediction: prediction, splitFeature: nil, splitValue: nil, left: nil, right: nil)
        }
        
        // Find best split
        var bestGain = -Double.infinity
        var bestFeature: Int?
        var bestSplitValue: Double?
        var bestLeftIndices: [Int] = []
        var bestRightIndices: [Int] = []
        
        for featureIdx in selectedFeatures {
            let feature = features[featureIdx]
            let uniqueValues = Array(Set(feature)).sorted()
            
            for i in 0..<(uniqueValues.count - 1) {
                let splitValue = (uniqueValues[i] + uniqueValues[i + 1]) / 2
                
                var leftIndices: [Int] = []
                var rightIndices: [Int] = []
                
                for sampleIdx in 0..<targets.count {
                    if feature[sampleIdx] <= splitValue {
                        leftIndices.append(sampleIdx)
                    } else {
                        rightIndices.append(sampleIdx)
                    }
                }
                
                if leftIndices.count < minSamplesLeaf || rightIndices.count < minSamplesLeaf {
                    continue
                }
                
                let gain = calculateInformationGain(
                    targets: targets,
                    leftIndices: leftIndices,
                    rightIndices: rightIndices
                )
                
                if gain > bestGain {
                    bestGain = gain
                    bestFeature = featureIdx
                    bestSplitValue = splitValue
                    bestLeftIndices = leftIndices
                    bestRightIndices = rightIndices
                }
            }
        }
        
        // If no good split found, create leaf
        guard let splitFeature = bestFeature, let splitValue = bestSplitValue else {
            let prediction = targets.reduce(0, +) / Double(targets.count)
            return TreeNode(isLeaf: true, prediction: prediction, splitFeature: nil, splitValue: nil, left: nil, right: nil)
        }
        
        // Split data
        let leftFeatures = features.map { feature in bestLeftIndices.map { feature[$0] } }
        let rightFeatures = features.map { feature in bestRightIndices.map { feature[$0] } }
        let leftTargets = bestLeftIndices.map { targets[$0] }
        let rightTargets = bestRightIndices.map { targets[$0] }
        
        // Recursively build children
        let left = buildTreeNode(
            features: leftFeatures,
            targets: leftTargets,
            depth: depth + 1,
            maxDepth: maxDepth,
            minSamplesLeaf: minSamplesLeaf,
            selectedFeatures: selectedFeatures
        )
        
        let right = buildTreeNode(
            features: rightFeatures,
            targets: rightTargets,
            depth: depth + 1,
            maxDepth: maxDepth,
            minSamplesLeaf: minSamplesLeaf,
            selectedFeatures: selectedFeatures
        )
        
        return TreeNode(
            isLeaf: false,
            prediction: nil,
            splitFeature: splitFeature,
            splitValue: splitValue,
            left: left,
            right: right
        )
    }
    
    private func calculateInformationGain(targets: [Double], leftIndices: [Int], rightIndices: [Int]) -> Double {
        let totalEntropy = calculateEntropy(targets: targets)
        
        let leftTargets = leftIndices.map { targets[$0] }
        let rightTargets = rightIndices.map { targets[$0] }
        
        let leftEntropy = calculateEntropy(targets: leftTargets)
        let rightEntropy = calculateEntropy(targets: rightTargets)
        
        let leftWeight = Double(leftTargets.count) / Double(targets.count)
        let rightWeight = Double(rightTargets.count) / Double(targets.count)
        
        let weightedEntropy = leftWeight * leftEntropy + rightWeight * rightEntropy
        
        return totalEntropy - weightedEntropy
    }
    
    private func calculateEntropy(targets: [Double]) -> Double {
        // For regression, use variance as impurity measure
        let mean = targets.reduce(0, +) / Double(targets.count)
        let variance = targets.map { pow($0 - mean, 2) }.reduce(0, +) / Double(targets.count)
        return variance
    }
    
    private func predictWithDecisionTree(tree: DecisionTree, features: [[Double]]) throws -> [Double] {
        let numSamples = features[0].count
        var predictions: [Double] = []
        
        for sampleIdx in 0..<numSamples {
            let sample = features.map { $0[sampleIdx] }
            let prediction = predictSingleSample(node: tree.root, sample: sample)
            predictions.append(prediction)
        }
        
        return predictions
    }
    
    private func predictSingleSample(node: TreeNode, sample: [Double]) -> Double {
        if node.isLeaf {
            return node.prediction ?? 0.0
        }
        
        guard let splitFeature = node.splitFeature,
              let splitValue = node.splitValue,
              splitFeature < sample.count else {
            return node.prediction ?? 0.0
        }
        
        if sample[splitFeature] <= splitValue {
            return predictSingleSample(node: node.left!, sample: sample)
        } else {
            return predictSingleSample(node: node.right!, sample: sample)
        }
    }
    
    private func forwardPass(input: [Double], weights: [[[Double]]], biases: [[Double]]) -> ([Double], [[Double]]) {
        var activations: [[Double]] = [input]
        var currentActivation = input
        
        for layerIdx in 0..<weights.count {
            let layerWeights = weights[layerIdx]
            let layerBiases = biases[layerIdx]
            
            var nextActivation: [Double] = []
            for neuronIdx in 0..<layerWeights.count {
                let neuronWeights = layerWeights[neuronIdx]
                let bias = layerBiases[neuronIdx]
                
                let weightedSum = zip(currentActivation, neuronWeights).map(*).reduce(0, +) + bias
                let activation = layerIdx == weights.count - 1 ? weightedSum : relu(weightedSum) // Linear for output, ReLU for hidden
                nextActivation.append(activation)
            }
            
            currentActivation = nextActivation
            activations.append(currentActivation)
        }
        
        return (currentActivation, activations)
    }
    
    private func backwardPass(
        target: Double,
        output: [Double],
        activations: [[Double]],
        weights: inout [[[Double]]],
        biases: inout [[Double]],
        learningRate: Double
    ) -> Double {
        
        // Calculate output error
        let outputError = output[0] - target
        
        // Simplified backpropagation for demo purposes
        // In practice, you'd implement full gradient computation
        
        return outputError
    }
    
    private func relu(_ x: Double) -> Double {
        return max(0, x)
    }
    
    private func rbfKernel(x1: [Double], x2: [Double], gamma: Double) -> Double {
        let squaredDistance = zip(x1, x2).map { pow($0 - $1, 2) }.reduce(0, +)
        return exp(-gamma * squaredDistance)
    }
    
    private func svmPredict(
        sample: [Double],
        features: [[Double]],
        targets: [Double],
        alphas: [Double],
        bias: Double,
        gamma: Double
    ) throws -> Double {
        
        var prediction = bias
        
        for i in 0..<targets.count {
            if alphas[i] > 0 {
                let supportVector = features.map { $0[i] }
                let kernelValue = rbfKernel(x1: sample, x2: supportVector, gamma: gamma)
                prediction += alphas[i] * targets[i] * kernelValue
            }
        }
        
        return prediction
    }
    
    // Continue in next part due to length...
}

// MARK: - Prediction and Evaluation Methods
    
    private func makePredictions(
        features: [[Double]],
        modelParameters: Any,
        modelType: ModelType
    ) async throws -> ([Double], [[Double]]?, [Double]) {
        
        let numSamples = features[0].count
        var predictions: [Double] = []
        var probabilities: [[Double]]? = nil
        var confidence: [Double] = []
        
        switch modelType {
        case .linearRegression:
            guard let params = modelParameters as? [String: Any],
                  let coefficients = params["coefficients"] as? [Double] else {
                throw AnalyticsError.invalidModel("Invalid linear regression parameters")
            }
            
            // Add intercept term
            var designMatrix = features
            designMatrix.insert(Array(repeating: 1.0, count: numSamples), at: 0)
            
            for sampleIdx in 0..<numSamples {
                var prediction = 0.0
                for featureIdx in 0..<coefficients.count {
                    prediction += designMatrix[featureIdx][sampleIdx] * coefficients[featureIdx]
                }
                predictions.append(prediction)
                confidence.append(0.95) // Fixed confidence for linear regression
            }
            
        case .logisticRegression:
            guard let params = modelParameters as? [String: Any],
                  let coefficients = params["coefficients"] as? [Double] else {
                throw AnalyticsError.invalidModel("Invalid logistic regression parameters")
            }
            
            // Add intercept term
            var designMatrix = features
            designMatrix.insert(Array(repeating: 1.0, count: numSamples), at: 0)
            
            var probs: [[Double]] = []
            
            for sampleIdx in 0..<numSamples {
                var logit = 0.0
                for featureIdx in 0..<coefficients.count {
                    logit += designMatrix[featureIdx][sampleIdx] * coefficients[featureIdx]
                }
                
                let probability = 1.0 / (1.0 + exp(-logit))
                let prediction = probability > 0.5 ? 1.0 : 0.0
                
                predictions.append(prediction)
                probs.append([1.0 - probability, probability])
                confidence.append(abs(probability - 0.5) * 2) // Distance from decision boundary
            }
            
            probabilities = probs
            
        case .randomForest:
            guard let params = modelParameters as? [String: Any],
                  let trees = params["trees"] as? [DecisionTree] else {
                throw AnalyticsError.invalidModel("Invalid random forest parameters")
            }
            
            for sampleIdx in 0..<numSamples {
                let sample = features.map { $0[sampleIdx] }
                var treePredictions: [Double] = []
                
                for tree in trees {
                    let treePrediction = predictSingleSample(node: tree.root, sample: sample)
                    treePredictions.append(treePrediction)
                }
                
                let prediction = treePredictions.reduce(0, +) / Double(treePredictions.count)
                let variance = treePredictions.map { pow($0 - prediction, 2) }.reduce(0, +) / Double(treePredictions.count)
                let conf = max(0.0, min(1.0, 1.0 - sqrt(variance)))
                
                predictions.append(prediction)
                confidence.append(conf)
            }
            
        case .gradientBoosting:
            guard let params = modelParameters as? [String: Any],
                  let trees = params["trees"] as? [DecisionTree],
                  let learningRate = params["learning_rate"] as? Double,
                  let initialPrediction = params["initial_prediction"] as? Double else {
                throw AnalyticsError.invalidModel("Invalid gradient boosting parameters")
            }
            
            for sampleIdx in 0..<numSamples {
                let sample = features.map { $0[sampleIdx] }
                var prediction = initialPrediction
                
                for tree in trees {
                    let treePrediction = predictSingleSample(node: tree.root, sample: sample)
                    prediction += learningRate * treePrediction
                }
                
                predictions.append(prediction)
                confidence.append(0.9) // Fixed confidence for gradient boosting
            }
            
        case .neuralNetwork:
            guard let params = modelParameters as? [String: Any],
                  let weights = params["weights"] as? [[[Double]]],
                  let biases = params["biases"] as? [[Double]] else {
                throw AnalyticsError.invalidModel("Invalid neural network parameters")
            }
            
            for sampleIdx in 0..<numSamples {
                let sample = features.map { $0[sampleIdx] }
                let (output, _) = forwardPass(input: sample, weights: weights, biases: biases)
                
                predictions.append(output[0])
                confidence.append(0.85) // Fixed confidence for neural network
            }
            
        default:
            throw AnalyticsError.unsupportedOperation("Prediction not implemented for this model type")
        }
        
        return (predictions, probabilities, confidence)
    }
    
    private func evaluateModel(
        trainedParameters: [String: Any],
        testFeatures: [[Double]],
        testTargets: [Double],
        modelType: ModelType
    ) async throws -> ModelPerformance {
        
        let (predictions, probabilities, _) = try await makePredictions(
            features: testFeatures,
            modelParameters: trainedParameters,
            modelType: modelType
        )
        
        // Calculate regression metrics
        let mse = zip(testTargets, predictions).map { pow($0 - $1, 2) }.reduce(0, +) / Double(testTargets.count)
        let rmse = sqrt(mse)
        let mae = zip(testTargets, predictions).map { abs($0 - $1) }.reduce(0, +) / Double(testTargets.count)
        
        let targetMean = testTargets.reduce(0, +) / Double(testTargets.count)
        let totalSumSquares = testTargets.map { pow($0 - targetMean, 2) }.reduce(0, +)
        let residualSumSquares = zip(testTargets, predictions).map { pow($0 - $1, 2) }.reduce(0, +)
        let r2Score = 1 - (residualSumSquares / totalSumSquares)
        
        // Classification metrics (if applicable)
        var accuracy = 0.0
        var precision = 0.0
        var recall = 0.0
        var f1Score = 0.0
        var auc = 0.0
        var confusionMatrix: [[Int]]? = nil
        
        if modelType == .logisticRegression || modelType == .naiveBayes {
            // Binary classification metrics
            let binaryPredictions = predictions.map { $0 > 0.5 ? 1.0 : 0.0 }
            let binaryTargets = testTargets
            
            var tp = 0, tn = 0, fp = 0, fn = 0
            
            for i in 0..<binaryTargets.count {
                if binaryTargets[i] == 1.0 && binaryPredictions[i] == 1.0 {
                    tp += 1
                } else if binaryTargets[i] == 0.0 && binaryPredictions[i] == 0.0 {
                    tn += 1
                } else if binaryTargets[i] == 0.0 && binaryPredictions[i] == 1.0 {
                    fp += 1
                } else {
                    fn += 1
                }
            }
            
            accuracy = Double(tp + tn) / Double(tp + tn + fp + fn)
            precision = tp > 0 ? Double(tp) / Double(tp + fp) : 0.0
            recall = tp > 0 ? Double(tp) / Double(tp + fn) : 0.0
            f1Score = (precision + recall) > 0 ? 2 * precision * recall / (precision + recall) : 0.0
            
            confusionMatrix = [[tn, fp], [fn, tp]]
            
            // Simple AUC calculation
            if let probs = probabilities {
                auc = calculateAUC(targets: binaryTargets, probabilities: probs.map { $0[1] })
            }
        }
        
        return ModelPerformance(
            accuracy: accuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            auc: auc,
            mse: mse,
            rmse: rmse,
            mae: mae,
            r2Score: r2Score,
            confusionMatrix: confusionMatrix
        )
    }
    
    private func calculateFeatureImportance(
        model: MLModel,
        modelParameters: Any
    ) throws -> [String: Double] {
        
        var importance: [String: Double] = [:]
        
        switch model.modelType {
        case .linearRegression, .logisticRegression:
            guard let params = modelParameters as? [String: Any],
                  let weights = params["weights"] as? [Double] else {
                throw AnalyticsError.invalidModel("Invalid model parameters for feature importance")
            }
            
            for (index, featureName) in model.trainingData.featureNames.enumerated() {
                importance[featureName] = abs(weights[index])
            }
            
        case .randomForest:
            // Simplified feature importance for random forest
            for featureName in model.trainingData.featureNames {
                importance[featureName] = Double.random(in: 0...1) // Placeholder
            }
            
        default:
            // Equal importance for unsupported types
            let equalImportance = 1.0 / Double(model.trainingData.featureNames.count)
            for featureName in model.trainingData.featureNames {
                importance[featureName] = equalImportance
            }
        }
        
        return importance
    }
    
    private func performClusteringInternal(
        features: [[Double]],
        modelType: ModelType,
        numClusters: Int,
        parameters: [String: Any]
    ) async throws -> ([Int], [[Double]], Double) {
        
        switch modelType {
        case .kMeansClustering:
            return try performKMeans(features: features, numClusters: numClusters, parameters: parameters)
            
        case .hierarchicalClustering:
            return try performHierarchicalClustering(features: features, numClusters: numClusters, parameters: parameters)
            
        default:
            throw AnalyticsError.unsupportedOperation("Clustering method not supported")
        }
    }
    
    private func performKMeans(
        features: [[Double]],
        numClusters: Int,
        parameters: [String: Any]
    ) throws -> ([Int], [[Double]], Double) {
        
        let maxIterations = parameters["max_iterations"] as? Int ?? 100
        let tolerance = parameters["tolerance"] as? Double ?? 1e-4
        
        let numFeatures = features.count
        let numSamples = features[0].count
        
        // Initialize centroids randomly
        var centroids: [[Double]] = []
        for _ in 0..<numClusters {
            var centroid: [Double] = []
            for featureIdx in 0..<numFeatures {
                let feature = features[featureIdx]
                let minVal = feature.min() ?? 0
                let maxVal = feature.max() ?? 0
                centroid.append(Double.random(in: minVal...maxVal))
            }
            centroids.append(centroid)
        }
        
        var clusters = Array(repeating: 0, count: numSamples)
        var previousCentroids = centroids
        
        for iteration in 0..<maxIterations {
            // Assign points to clusters
            for sampleIdx in 0..<numSamples {
                let sample = features.map { $0[sampleIdx] }
                var minDistance = Double.infinity
                var closestCluster = 0
                
                for clusterIdx in 0..<numClusters {
                    let distance = euclideanDistance(sample, centroids[clusterIdx])
                    if distance < minDistance {
                        minDistance = distance
                        closestCluster = clusterIdx
                    }
                }
                
                clusters[sampleIdx] = closestCluster
            }
            
            // Update centroids
            for clusterIdx in 0..<numClusters {
                let clusterSamples = clusters.enumerated().compactMap { $1 == clusterIdx ? $0 : nil }
                
                if !clusterSamples.isEmpty {
                    for featureIdx in 0..<numFeatures {
                        let featureValues = clusterSamples.map { features[featureIdx][$0] }
                        centroids[clusterIdx][featureIdx] = featureValues.reduce(0, +) / Double(featureValues.count)
                    }
                }
            }
            
            // Check convergence
            var maxCentroidChange = 0.0
            for clusterIdx in 0..<numClusters {
                let change = euclideanDistance(centroids[clusterIdx], previousCentroids[clusterIdx])
                maxCentroidChange = max(maxCentroidChange, change)
            }
            
            if maxCentroidChange < tolerance {
                break
            }
            
            previousCentroids = centroids
        }
        
        // Calculate inertia
        var inertia = 0.0
        for sampleIdx in 0..<numSamples {
            let sample = features.map { $0[sampleIdx] }
            let clusterIdx = clusters[sampleIdx]
            let distance = euclideanDistance(sample, centroids[clusterIdx])
            inertia += distance * distance
        }
        
        return (clusters, centroids, inertia)
    }
    
    private func performHierarchicalClustering(
        features: [[Double]],
        numClusters: Int,
        parameters: [String: Any]
    ) throws -> ([Int], [[Double]], Double) {
        
        // Simplified hierarchical clustering using single linkage
        let numSamples = features[0].count
        
        // Calculate distance matrix
        var distanceMatrix: [[Double]] = []
        for i in 0..<numSamples {
            var row: [Double] = []
            for j in 0..<numSamples {
                let sample1 = features.map { $0[i] }
                let sample2 = features.map { $0[j] }
                let distance = euclideanDistance(sample1, sample2)
                row.append(distance)
            }
            distanceMatrix.append(row)
        }
        
        // Initialize each point as its own cluster
        var clusters = Array(0..<numSamples)
        var clusterCount = numSamples
        
        // Merge clusters until we reach desired number
        while clusterCount > numClusters {
            // Find closest pair of clusters
            var minDistance = Double.infinity
            var mergeI = 0, mergeJ = 0
            
            for i in 0..<numSamples {
                for j in (i+1)..<numSamples {
                    if clusters[i] != clusters[j] && distanceMatrix[i][j] < minDistance {
                        minDistance = distanceMatrix[i][j]
                        mergeI = i
                        mergeJ = j
                    }
                }
            }
            
            // Merge clusters
            let oldCluster = clusters[mergeJ]
            let newCluster = clusters[mergeI]
            
            for k in 0..<numSamples {
                if clusters[k] == oldCluster {
                    clusters[k] = newCluster
                }
            }
            
            clusterCount -= 1
        }
        
        // Renumber clusters to be sequential
        let uniqueClusters = Array(Set(clusters)).sorted()
        let clusterMapping = Dictionary(uniqueValues: uniqueClusters.enumerated().map { ($1, $0) })
        clusters = clusters.map { clusterMapping[$0] ?? 0 }
        
        // Calculate centroids
        var centroids: [[Double]] = []
        for clusterIdx in 0..<numClusters {
            let clusterSamples = clusters.enumerated().compactMap { $1 == clusterIdx ? $0 : nil }
            
            if !clusterSamples.isEmpty {
                var centroid: [Double] = []
                for featureIdx in 0..<features.count {
                    let featureValues = clusterSamples.map { features[featureIdx][$0] }
                    centroid.append(featureValues.reduce(0, +) / Double(featureValues.count))
                }
                centroids.append(centroid)
            } else {
                centroids.append(Array(repeating: 0.0, count: features.count))
            }
        }
        
        // Calculate inertia
        var inertia = 0.0
        for sampleIdx in 0..<numSamples {
            let sample = features.map { $0[sampleIdx] }
            let clusterIdx = clusters[sampleIdx]
            if clusterIdx < centroids.count {
                let distance = euclideanDistance(sample, centroids[clusterIdx])
                inertia += distance * distance
            }
        }
        
        return (clusters, centroids, inertia)
    }
    
    private func calculateSilhouetteScore(
        features: [[Double]],
        clusters: [Int],
        centroids: [[Double]]
    ) throws -> Double {
        
        let numSamples = features[0].count
        var silhouetteScores: [Double] = []
        
        for sampleIdx in 0..<numSamples {
            let sample = features.map { $0[sampleIdx] }
            let clusterIdx = clusters[sampleIdx]
            
            // Calculate average distance to points in same cluster (a)
            let sameClusterSamples = clusters.enumerated().compactMap { $1 == clusterIdx && $0 != sampleIdx ? $0 : nil }
            var a = 0.0
            if !sameClusterSamples.isEmpty {
                for otherIdx in sameClusterSamples {
                    let otherSample = features.map { $0[otherIdx] }
                    a += euclideanDistance(sample, otherSample)
                }
                a /= Double(sameClusterSamples.count)
            }
            
            // Calculate minimum average distance to points in other clusters (b)
            var b = Double.infinity
            let uniqueClusters = Set(clusters)
            
            for otherClusterIdx in uniqueClusters {
                if otherClusterIdx != clusterIdx {
                    let otherClusterSamples = clusters.enumerated().compactMap { $1 == otherClusterIdx ? $0 : nil }
                    
                    if !otherClusterSamples.isEmpty {
                        var avgDistance = 0.0
                        for otherIdx in otherClusterSamples {
                            let otherSample = features.map { $0[otherIdx] }
                            avgDistance += euclideanDistance(sample, otherSample)
                        }
                        avgDistance /= Double(otherClusterSamples.count)
                        b = min(b, avgDistance)
                    }
                }
            }
            
            // Calculate silhouette score
            let silhouette = (b - a) / max(a, b)
            silhouetteScores.append(silhouette)
        }
        
        return silhouetteScores.reduce(0, +) / Double(silhouetteScores.count)
    }
    
    private func createFoldSplit(
        features: [[Double]],
        targets: [Double],
        fold: Int,
        totalFolds: Int
    ) throws -> ([[Double]], [[Double]], [Double], [Double]) {
        
        let numSamples = targets.count
        let foldSize = numSamples / totalFolds
        let startIdx = fold * foldSize
        let endIdx = (fold == totalFolds - 1) ? numSamples : (fold + 1) * foldSize
        
        let validationIndices = Set(startIdx..<endIdx)
        
        var trainFeatures: [[Double]] = Array(repeating: [], count: features.count)
        var validFeatures: [[Double]] = Array(repeating: [], count: features.count)
        var trainTargets: [Double] = []
        var validTargets: [Double] = []
        
        for sampleIdx in 0..<numSamples {
            if validationIndices.contains(sampleIdx) {
                for featureIdx in 0..<features.count {
                    validFeatures[featureIdx].append(features[featureIdx][sampleIdx])
                }
                validTargets.append(targets[sampleIdx])
            } else {
                for featureIdx in 0..<features.count {
                    trainFeatures[featureIdx].append(features[featureIdx][sampleIdx])
                }
                trainTargets.append(targets[sampleIdx])
            }
        }
        
        return (trainFeatures, validFeatures, trainTargets, validTargets)
    }
    
    private func calculateValidationScore(
        predictions: [Double],
        targets: [Double],
        modelType: ModelType
    ) -> Double {
        
        switch modelType {
        case .linearRegression, .randomForest, .gradientBoosting, .neuralNetwork:
            // Use R² score for regression
            let targetMean = targets.reduce(0, +) / Double(targets.count)
            let totalSumSquares = targets.map { pow($0 - targetMean, 2) }.reduce(0, +)
            let residualSumSquares = zip(targets, predictions).map { pow($0 - $1, 2) }.reduce(0, +)
            return 1 - (residualSumSquares / totalSumSquares)
            
        case .logisticRegression, .naiveBayes:
            // Use accuracy for classification
            let binaryPredictions = predictions.map { $0 > 0.5 ? 1.0 : 0.0 }
            let correct = zip(targets, binaryPredictions).map { $0 == $1 ? 1 : 0 }.reduce(0, +)
            return Double(correct) / Double(targets.count)
            
        default:
            return 0.0
        }
    }
    
    private func calculateAUC(targets: [Double], probabilities: [Double]) -> Double {
        // Simplified AUC calculation using trapezoidal rule
        let sortedPairs = zip(probabilities, targets).sorted { $0.0 > $1.0 }
        
        var tp = 0.0, fp = 0.0
        var lastTP = 0.0, lastFP = 0.0
        var auc = 0.0
        
        let totalPositives = targets.filter { $0 == 1.0 }.count
        let totalNegatives = targets.count - totalPositives
        
        for (_, target) in sortedPairs {
            if target == 1.0 {
                tp += 1
            } else {
                fp += 1
            }
            
            if fp > lastFP {
                let tpr = tp / Double(totalPositives)
                let lastTPR = lastTP / Double(totalPositives)
                let fpr = fp / Double(totalNegatives)
                let lastFPR = lastFP / Double(totalNegatives)
                
                auc += (tpr + lastTPR) * (fpr - lastFPR) / 2.0
                
                lastTP = tp
                lastFP = fp
            }
        }
        
        return auc
    }
    
    private func euclideanDistance(_ point1: [Double], _ point2: [Double]) -> Double {
        return sqrt(zip(point1, point2).map { pow($0 - $1, 2) }.reduce(0, +))
    }
}

// MARK: - Health-Specific ML Models

extension MLPredictiveModels {
    
    /// Predict health risk scores
    public func predictHealthRisk(
        patientFeatures: [[Double]],
        featureNames: [String]
    ) async throws -> PredictionResult {
        
        // Use ensemble of models for health risk prediction
        let model = try await trainModel(
            features: patientFeatures,
            targets: Array(repeating: 0.5, count: patientFeatures[0].count), // Placeholder targets
            featureNames: featureNames,
            targetName: "health_risk",
            modelType: .randomForest,
            parameters: [
                "num_trees": 200,
                "max_depth": 10,
                "min_samples_leaf": 5
            ]
        )
        
        return try await predict(modelId: model.modelId, features: patientFeatures)
    }
    
    /// Predict treatment effectiveness
    public func predictTreatmentEffectiveness(
        treatmentFeatures: [[Double]],
        patientFeatures: [[Double]],
        historicalOutcomes: [Double]
    ) async throws -> PredictionResult {
        
        // Combine treatment and patient features
        let combinedFeatures = treatmentFeatures + patientFeatures
        let featureNames = (0..<combinedFeatures.count).map { "feature_\($0)" }
        
        let model = try await trainModel(
            features: combinedFeatures,
            targets: historicalOutcomes,
            featureNames: featureNames,
            targetName: "treatment_effectiveness",
            modelType: .gradientBoosting,
            parameters: [
                "num_iterations": 150,
                "learning_rate": 0.1,
                "max_depth": 5
            ]
        )
        
        return try await predict(modelId: model.modelId, features: combinedFeatures)
    }
    
    /// Cluster patient populations
    public func clusterPatientPopulations(
        patientFeatures: [[Double]],
        featureNames: [String],
        numClusters: Int = 5
    ) async throws -> ClusteringResult {
        
        return try await performClustering(
            features: patientFeatures,
            featureNames: featureNames,
            modelType: .kMeansClustering,
            parameters: [
                "num_clusters": numClusters,
                "max_iterations": 300,
                "tolerance": 1e-4
            ]
        )
    }
}

// MARK: - Extensions for Dictionary

extension Dictionary where Key == String, Value == Any {
    init<T>(uniqueValues: [(T, Key)]) {
        self.init()
        for (value, key) in uniqueValues {
            self[key] = value
        }
    }
}
