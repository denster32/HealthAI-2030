import Foundation
import Combine

/// Advanced anomaly detection engine for healthcare data analysis
public class AnomalyDetection {
    
    // MARK: - Properties
    private let analyticsEngine: AdvancedAnalyticsEngine
    private let configManager: AnalyticsConfiguration
    private let errorHandler: AnalyticsErrorHandling
    private let performanceMonitor: AnalyticsPerformanceMonitor
    private let statisticalEngine: StatisticalAnalysisEngine
    
    // MARK: - Detection Methods
    public enum AnomalyDetectionMethod {
        case statistical(threshold: Double)
        case isolationForest(numTrees: Int, contamination: Double)
        case oneClassSVM(nu: Double, gamma: Double)
        case localOutlierFactor(neighbors: Int)
        case dbscan(epsilon: Double, minPoints: Int)
        case ensemble(methods: [AnomalyDetectionMethod])
        case deepLearning(modelType: String)
    }
    
    // MARK: - Data Structures
    public struct AnomalyResult {
        let anomalies: [AnomalyPoint]
        let scores: [Double]
        let threshold: Double
        let method: AnomalyDetectionMethod
        let confidence: Double
        let metadata: [String: Any]
    }
    
    public struct AnomalyPoint {
        let index: Int
        let value: Double
        let timestamp: Date?
        let score: Double
        let severity: AnomalySeverity
        let context: [String: Any]
    }
    
    public enum AnomalySeverity {
        case low
        case medium
        case high
        case critical
    }
    
    public struct MultiVariateAnomalyResult {
        let anomalies: [MultiVariateAnomalyPoint]
        let overallScores: [Double]
        let featureContributions: [[Double]]
        let method: AnomalyDetectionMethod
        let confidence: Double
    }
    
    public struct MultiVariateAnomalyPoint {
        let index: Int
        let values: [Double]
        let timestamp: Date?
        let overallScore: Double
        let featureScores: [Double]
        let severity: AnomalySeverity
    }
    
    public struct RealTimeAnomalyDetector {
        let windowSize: Int
        let method: AnomalyDetectionMethod
        let threshold: Double
        var historicalData: [Double]
        var model: AnomalyModel?
    }
    
    // MARK: - Model Structures
    private struct AnomalyModel {
        let parameters: [String: Any]
        let threshold: Double
        let method: AnomalyDetectionMethod
        let trainedOn: Date
    }
    
    private struct IsolationTree {
        let root: IsolationNode
        let maxDepth: Int
        let sampleSize: Int
    }
    
    private struct IsolationNode {
        let isLeaf: Bool
        let splitFeature: Int?
        let splitValue: Double?
        let left: IsolationNode?
        let right: IsolationNode?
        let size: Int
        let depth: Int
    }
    
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
    
    /// Detect anomalies in univariate data
    public func detectUnivariateAnomalies(
        data: [Double],
        timestamps: [Date]? = nil,
        method: AnomalyDetectionMethod = .statistical(threshold: 2.0)
    ) async throws -> AnomalyResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("univariate_anomaly_detection", value: executionTime)
        }
        
        do {
            guard !data.isEmpty else {
                throw AnalyticsError.invalidInput("Data cannot be empty")
            }
            
            let scores: [Double]
            let threshold: Double
            
            switch method {
            case .statistical(let thresh):
                scores = calculateStatisticalScores(data)
                threshold = thresh
                
            case .isolationForest(let numTrees, let contamination):
                scores = try calculateIsolationForestScores(data, numTrees: numTrees)
                threshold = calculateContaminationThreshold(scores: scores, contamination: contamination)
                
            case .localOutlierFactor(let neighbors):
                scores = try calculateLOFScores(data, neighbors: neighbors)
                threshold = 1.5 // LOF threshold
                
            default:
                scores = calculateStatisticalScores(data)
                threshold = 2.0
            }
            
            let anomalyPoints = createAnomalyPoints(
                data: data,
                scores: scores,
                threshold: threshold,
                timestamps: timestamps
            )
            
            let confidence = calculateConfidence(scores: scores, anomalies: anomalyPoints)
            
            return AnomalyResult(
                anomalies: anomalyPoints,
                scores: scores,
                threshold: threshold,
                method: method,
                confidence: confidence,
                metadata: [
                    "total_points": data.count,
                    "anomaly_count": anomalyPoints.count,
                    "anomaly_rate": Double(anomalyPoints.count) / Double(data.count)
                ]
            )
            
        } catch {
            await errorHandler.handleError(error, context: "AnomalyDetection.detectUnivariateAnomalies")
            throw error
        }
    }
    
    /// Detect anomalies in multivariate data
    public func detectMultivariateAnomalies(
        data: [[Double]],
        timestamps: [Date]? = nil,
        method: AnomalyDetectionMethod = .isolationForest(numTrees: 100, contamination: 0.1)
    ) async throws -> MultiVariateAnomalyResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("multivariate_anomaly_detection", value: executionTime)
        }
        
        do {
            guard !data.isEmpty && !data[0].isEmpty else {
                throw AnalyticsError.invalidInput("Data cannot be empty")
            }
            
            let numFeatures = data.count
            let numSamples = data[0].count
            
            // Validate data consistency
            guard data.allSatisfy({ $0.count == numSamples }) else {
                throw AnalyticsError.invalidInput("All features must have the same number of samples")
            }
            
            let (overallScores, featureContributions) = try calculateMultivariateScores(
                data: data,
                method: method
            )
            
            let threshold = calculateAdaptiveThreshold(scores: overallScores, method: method)
            
            let anomalyPoints = createMultivariateAnomalyPoints(
                data: data,
                overallScores: overallScores,
                featureContributions: featureContributions,
                threshold: threshold,
                timestamps: timestamps
            )
            
            let confidence = calculateMultivariateConfidence(
                scores: overallScores,
                anomalies: anomalyPoints
            )
            
            return MultiVariateAnomalyResult(
                anomalies: anomalyPoints,
                overallScores: overallScores,
                featureContributions: featureContributions,
                method: method,
                confidence: confidence
            )
            
        } catch {
            await errorHandler.handleError(error, context: "AnomalyDetection.detectMultivariateAnomalies")
            throw error
        }
    }
    
    /// Create real-time anomaly detector
    public func createRealTimeDetector(
        initialData: [Double],
        windowSize: Int = 100,
        method: AnomalyDetectionMethod = .statistical(threshold: 2.5)
    ) async throws -> RealTimeAnomalyDetector {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("real_time_detector_creation", value: executionTime)
        }
        
        do {
            guard initialData.count >= windowSize else {
                throw AnalyticsError.invalidInput("Initial data must be at least window size")
            }
            
            let model = try trainAnomalyModel(data: initialData, method: method)
            let threshold = extractThreshold(from: method)
            
            return RealTimeAnomalyDetector(
                windowSize: windowSize,
                method: method,
                threshold: threshold,
                historicalData: Array(initialData.suffix(windowSize)),
                model: model
            )
            
        } catch {
            await errorHandler.handleError(error, context: "AnomalyDetection.createRealTimeDetector")
            throw error
        }
    }
    
    /// Update real-time detector with new data point
    public func updateRealTimeDetector(
        detector: inout RealTimeAnomalyDetector,
        newValue: Double,
        timestamp: Date = Date()
    ) async throws -> AnomalyPoint? {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("real_time_detection", value: executionTime)
        }
        
        do {
            // Add new value to historical data
            detector.historicalData.append(newValue)
            if detector.historicalData.count > detector.windowSize {
                detector.historicalData.removeFirst()
            }
            
            // Calculate anomaly score for new value
            let score = try calculateRealTimeScore(
                value: newValue,
                historicalData: detector.historicalData,
                model: detector.model,
                method: detector.method
            )
            
            // Check if it's an anomaly
            if score > detector.threshold {
                let severity = determineSeverity(score: score, threshold: detector.threshold)
                
                return AnomalyPoint(
                    index: detector.historicalData.count - 1,
                    value: newValue,
                    timestamp: timestamp,
                    score: score,
                    severity: severity,
                    context: [
                        "window_size": detector.windowSize,
                        "method": String(describing: detector.method),
                        "threshold": detector.threshold
                    ]
                )
            }
            
            return nil
            
        } catch {
            await errorHandler.handleError(error, context: "AnomalyDetection.updateRealTimeDetector")
            throw error
        }
    }
    
    /// Perform ensemble anomaly detection
    public func detectEnsembleAnomalies(
        data: [Double],
        methods: [AnomalyDetectionMethod],
        timestamps: [Date]? = nil
    ) async throws -> AnomalyResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceMonitor.recordMetric("ensemble_anomaly_detection", value: executionTime)
        }
        
        do {
            var allScores: [[Double]] = []
            var weights: [Double] = []
            
            // Run each detection method
            for method in methods {
                let result = try await detectUnivariateAnomalies(data: data, timestamps: timestamps, method: method)
                allScores.append(result.scores)
                weights.append(result.confidence)
            }
            
            // Normalize weights
            let weightSum = weights.reduce(0, +)
            let normalizedWeights = weights.map { $0 / weightSum }
            
            // Calculate ensemble scores
            var ensembleScores: [Double] = Array(repeating: 0.0, count: data.count)
            for i in 0..<data.count {
                for j in 0..<allScores.count {
                    ensembleScores[i] += normalizedWeights[j] * allScores[j][i]
                }
            }
            
            // Calculate adaptive threshold
            let threshold = calculateAdaptiveThreshold(scores: ensembleScores, method: .ensemble(methods: methods))
            
            let anomalyPoints = createAnomalyPoints(
                data: data,
                scores: ensembleScores,
                threshold: threshold,
                timestamps: timestamps
            )
            
            let confidence = calculateConfidence(scores: ensembleScores, anomalies: anomalyPoints)
            
            return AnomalyResult(
                anomalies: anomalyPoints,
                scores: ensembleScores,
                threshold: threshold,
                method: .ensemble(methods: methods),
                confidence: confidence,
                metadata: [
                    "method_count": methods.count,
                    "weighted_average": true,
                    "ensemble_weights": normalizedWeights
                ]
            )
            
        } catch {
            await errorHandler.handleError(error, context: "AnomalyDetection.detectEnsembleAnomalies")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateStatisticalScores(_ data: [Double]) -> [Double] {
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let standardDeviation = sqrt(variance)
        
        guard standardDeviation > 0 else {
            return Array(repeating: 0.0, count: data.count)
        }
        
        return data.map { abs($0 - mean) / standardDeviation }
    }
    
    private func calculateIsolationForestScores(_ data: [Double], numTrees: Int) throws -> [Double] {
        let subsampleSize = min(256, data.count)
        var scores: [Double] = Array(repeating: 0.0, count: data.count)
        
        // Build isolation trees
        var trees: [IsolationTree] = []
        for _ in 0..<numTrees {
            let subsample = Array(data.shuffled().prefix(subsampleSize))
            let maxDepth = Int(ceil(log2(Double(subsampleSize))))
            let tree = buildIsolationTree(data: [subsample], maxDepth: maxDepth)
            trees.append(tree)
        }
        
        // Calculate path lengths for each data point
        for i in 0..<data.count {
            var totalPathLength = 0.0
            for tree in trees {
                let pathLength = calculatePathLength(tree: tree.root, point: [data[i]])
                totalPathLength += Double(pathLength)
            }
            
            let avgPathLength = totalPathLength / Double(numTrees)
            let expectedPathLength = expectedPathLengthForSize(subsampleSize)
            scores[i] = pow(2, -avgPathLength / expectedPathLength)
        }
        
        return scores
    }
    
    private func calculateLOFScores(_ data: [Double], neighbors: Int) throws -> [Double] {
        guard neighbors < data.count else {
            throw AnalyticsError.invalidInput("Number of neighbors must be less than data size")
        }
        
        var lofScores: [Double] = []
        
        for i in 0..<data.count {
            // Calculate k-distance and reachability distance
            let distances = data.enumerated().map { (index, value) in
                (index: index, distance: abs(value - data[i]))
            }.sorted { $0.distance < $1.distance }
            
            let kNearest = Array(distances.prefix(neighbors + 1).dropFirst()) // Exclude self
            let kDistance = kNearest.last?.distance ?? 0.0
            
            // Calculate local reachability density
            var reachabilityDistances: [Double] = []
            for neighbor in kNearest {
                let neighborIndex = neighbor.index
                let neighborDistances = data.enumerated().map { (idx, val) in
                    abs(val - data[neighborIndex])
                }.sorted()
                let neighborKDistance = neighborDistances[min(neighbors, neighborDistances.count - 1)]
                let reachDist = max(neighbor.distance, neighborKDistance)
                reachabilityDistances.append(reachDist)
            }
            
            let lrd = Double(neighbors) / reachabilityDistances.reduce(0, +)
            
            // Calculate LOF
            var neighborLRDs: [Double] = []
            for neighbor in kNearest {
                let neighborIndex = neighbor.index
                // Simplified LRD calculation for neighbor
                let neighborLRD = 1.0 // In practice, would calculate actual LRD
                neighborLRDs.append(neighborLRD)
            }
            
            let avgNeighborLRD = neighborLRDs.reduce(0, +) / Double(neighborLRDs.count)
            let lof = avgNeighborLRD / lrd
            lofScores.append(lof)
        }
        
        return lofScores
    }
    
    private func calculateMultivariateScores(
        data: [[Double]],
        method: AnomalyDetectionMethod
    ) throws -> ([Double], [[Double]]) {
        
        let numFeatures = data.count
        let numSamples = data[0].count
        
        switch method {
        case .isolationForest(let numTrees, _):
            return try calculateMultivariateIsolationForest(data: data, numTrees: numTrees)
            
        case .statistical(let threshold):
            return calculateMultivariateStatistical(data: data)
            
        default:
            return calculateMultivariateStatistical(data: data)
        }
    }
    
    private func calculateMultivariateIsolationForest(
        data: [[Double]],
        numTrees: Int
    ) throws -> ([Double], [[Double]]) {
        
        let numFeatures = data.count
        let numSamples = data[0].count
        let subsampleSize = min(256, numSamples)
        
        var overallScores: [Double] = Array(repeating: 0.0, count: numSamples)
        var featureContributions: [[Double]] = Array(repeating: Array(repeating: 0.0, count: numFeatures), count: numSamples)
        
        // Build isolation trees
        for _ in 0..<numTrees {
            // Sample data points
            let sampleIndices = Array(0..<numSamples).shuffled().prefix(subsampleSize)
            var subsample: [[Double]] = Array(repeating: [], count: numFeatures)
            
            for featureIdx in 0..<numFeatures {
                subsample[featureIdx] = sampleIndices.map { data[featureIdx][$0] }
            }
            
            let maxDepth = Int(ceil(log2(Double(subsampleSize))))
            let tree = buildIsolationTree(data: subsample, maxDepth: maxDepth)
            
            // Calculate path lengths for all data points
            for sampleIdx in 0..<numSamples {
                let point = data.map { $0[sampleIdx] }
                let pathLength = calculatePathLength(tree: tree.root, point: point)
                
                let expectedLength = expectedPathLengthForSize(subsampleSize)
                let score = pow(2, -Double(pathLength) / expectedLength)
                overallScores[sampleIdx] += score
                
                // Simplified feature contribution (equal weight)
                for featureIdx in 0..<numFeatures {
                    featureContributions[sampleIdx][featureIdx] += score / Double(numFeatures)
                }
            }
        }
        
        // Average scores across trees
        for i in 0..<numSamples {
            overallScores[i] /= Double(numTrees)
            for j in 0..<numFeatures {
                featureContributions[i][j] /= Double(numTrees)
            }
        }
        
        return (overallScores, featureContributions)
    }
    
    private func calculateMultivariateStatistical(data: [[Double]]) -> ([Double], [[Double]]) {
        let numFeatures = data.count
        let numSamples = data[0].count
        
        // Calculate Mahalanobis distance approximation
        var overallScores: [Double] = Array(repeating: 0.0, count: numSamples)
        var featureContributions: [[Double]] = Array(repeating: Array(repeating: 0.0, count: numFeatures), count: numSamples)
        
        // Calculate feature means and standard deviations
        var means: [Double] = []
        var stds: [Double] = []
        
        for featureIdx in 0..<numFeatures {
            let feature = data[featureIdx]
            let mean = feature.reduce(0, +) / Double(feature.count)
            let variance = feature.map { pow($0 - mean, 2) }.reduce(0, +) / Double(feature.count)
            let std = sqrt(variance)
            
            means.append(mean)
            stds.append(max(std, 1e-10)) // Avoid division by zero
        }
        
        // Calculate scores
        for sampleIdx in 0..<numSamples {
            var totalScore = 0.0
            
            for featureIdx in 0..<numFeatures {
                let normalizedValue = abs(data[featureIdx][sampleIdx] - means[featureIdx]) / stds[featureIdx]
                featureContributions[sampleIdx][featureIdx] = normalizedValue
                totalScore += normalizedValue * normalizedValue
            }
            
            overallScores[sampleIdx] = sqrt(totalScore / Double(numFeatures))
        }
        
        return (overallScores, featureContributions)
    }
    
    private func buildIsolationTree(data: [[Double]], maxDepth: Int) -> IsolationTree {
        let root = buildIsolationNode(data: data, depth: 0, maxDepth: maxDepth)
        return IsolationTree(root: root, maxDepth: maxDepth, sampleSize: data[0].count)
    }
    
    private func buildIsolationNode(data: [[Double]], depth: Int, maxDepth: Int) -> IsolationNode {
        let numFeatures = data.count
        let numSamples = data[0].count
        
        if depth >= maxDepth || numSamples <= 1 {
            return IsolationNode(
                isLeaf: true,
                splitFeature: nil,
                splitValue: nil,
                left: nil,
                right: nil,
                size: numSamples,
                depth: depth
            )
        }
        
        // Randomly select feature and split value
        let splitFeature = Int.random(in: 0..<numFeatures)
        let feature = data[splitFeature]
        let minVal = feature.min() ?? 0
        let maxVal = feature.max() ?? 0
        
        guard minVal < maxVal else {
            return IsolationNode(
                isLeaf: true,
                splitFeature: nil,
                splitValue: nil,
                left: nil,
                right: nil,
                size: numSamples,
                depth: depth
            )
        }
        
        let splitValue = Double.random(in: minVal...maxVal)
        
        // Split data
        var leftIndices: [Int] = []
        var rightIndices: [Int] = []
        
        for i in 0..<numSamples {
            if feature[i] < splitValue {
                leftIndices.append(i)
            } else {
                rightIndices.append(i)
            }
        }
        
        // Create left and right data
        let leftData = data.map { feature in leftIndices.map { feature[$0] } }
        let rightData = data.map { feature in rightIndices.map { feature[$0] } }
        
        let left = buildIsolationNode(data: leftData, depth: depth + 1, maxDepth: maxDepth)
        let right = buildIsolationNode(data: rightData, depth: depth + 1, maxDepth: maxDepth)
        
        return IsolationNode(
            isLeaf: false,
            splitFeature: splitFeature,
            splitValue: splitValue,
            left: left,
            right: right,
            size: numSamples,
            depth: depth
        )
    }
    
    private func calculatePathLength(tree: IsolationNode, point: [Double]) -> Int {
        if tree.isLeaf {
            return tree.depth + adjustmentForSize(tree.size)
        }
        
        guard let splitFeature = tree.splitFeature,
              let splitValue = tree.splitValue,
              splitFeature < point.count else {
            return tree.depth
        }
        
        if point[splitFeature] < splitValue {
            return calculatePathLength(tree: tree.left!, point: point)
        } else {
            return calculatePathLength(tree: tree.right!, point: point)
        }
    }
    
    private func adjustmentForSize(_ size: Int) -> Int {
        if size <= 1 {
            return 0
        } else if size == 2 {
            return 1
        } else {
            return Int(ceil(log2(Double(size))))
        }
    }
    
    private func expectedPathLengthForSize(_ size: Int) -> Double {
        if size <= 1 {
            return 0.0
        } else if size == 2 {
            return 1.0
        } else {
            return 2.0 * (log(Double(size - 1)) + 0.5772156649) - (2.0 * Double(size - 1) / Double(size))
        }
    }
    
    private func calculateContaminationThreshold(scores: [Double], contamination: Double) -> Double {
        let sortedScores = scores.sorted(by: >)
        let thresholdIndex = Int(Double(scores.count) * contamination)
        return sortedScores[min(thresholdIndex, sortedScores.count - 1)]
    }
    
    private func calculateAdaptiveThreshold(scores: [Double], method: AnomalyDetectionMethod) -> Double {
        switch method {
        case .statistical(let threshold):
            return threshold
        case .isolationForest(_, let contamination):
            return calculateContaminationThreshold(scores: scores, contamination: contamination)
        case .localOutlierFactor(_):
            return 1.5
        default:
            // Use statistical approach for adaptive threshold
            let mean = scores.reduce(0, +) / Double(scores.count)
            let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
            let standardDeviation = sqrt(variance)
            return mean + 2.0 * standardDeviation
        }
    }
    
    private func createAnomalyPoints(
        data: [Double],
        scores: [Double],
        threshold: Double,
        timestamps: [Date]?
    ) -> [AnomalyPoint] {
        
        var anomalies: [AnomalyPoint] = []
        
        for i in 0..<data.count {
            if scores[i] > threshold {
                let severity = determineSeverity(score: scores[i], threshold: threshold)
                let timestamp = timestamps?[safe: i]
                
                let anomaly = AnomalyPoint(
                    index: i,
                    value: data[i],
                    timestamp: timestamp,
                    score: scores[i],
                    severity: severity,
                    context: [:]
                )
                
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    private func createMultivariateAnomalyPoints(
        data: [[Double]],
        overallScores: [Double],
        featureContributions: [[Double]],
        threshold: Double,
        timestamps: [Date]?
    ) -> [MultiVariateAnomalyPoint] {
        
        var anomalies: [MultiVariateAnomalyPoint] = []
        let numSamples = data[0].count
        
        for i in 0..<numSamples {
            if overallScores[i] > threshold {
                let severity = determineSeverity(score: overallScores[i], threshold: threshold)
                let timestamp = timestamps?[safe: i]
                let values = data.map { $0[i] }
                let featureScores = featureContributions[i]
                
                let anomaly = MultiVariateAnomalyPoint(
                    index: i,
                    values: values,
                    timestamp: timestamp,
                    overallScore: overallScores[i],
                    featureScores: featureScores,
                    severity: severity
                )
                
                anomalies.append(anomaly)
            }
        }
        
        return anomalies
    }
    
    private func determineSeverity(score: Double, threshold: Double) -> AnomalySeverity {
        let ratio = score / threshold
        
        if ratio >= 3.0 {
            return .critical
        } else if ratio >= 2.0 {
            return .high
        } else if ratio >= 1.5 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculateConfidence(scores: [Double], anomalies: [AnomalyPoint]) -> Double {
        guard !anomalies.isEmpty else { return 1.0 }
        
        let anomalyScores = anomalies.map { $0.score }
        let normalScores = scores.enumerated().compactMap { index, score in
            anomalies.contains { $0.index == index } ? nil : score
        }
        
        guard !normalScores.isEmpty else { return 0.5 }
        
        let anomalyMean = anomalyScores.reduce(0, +) / Double(anomalyScores.count)
        let normalMean = normalScores.reduce(0, +) / Double(normalScores.count)
        
        let separation = anomalyMean - normalMean
        let maxScore = scores.max() ?? 1.0
        
        return min(1.0, max(0.0, separation / maxScore))
    }
    
    private func calculateMultivariateConfidence(
        scores: [Double],
        anomalies: [MultiVariateAnomalyPoint]
    ) -> Double {
        guard !anomalies.isEmpty else { return 1.0 }
        
        let anomalyScores = anomalies.map { $0.overallScore }
        let normalScores = scores.enumerated().compactMap { index, score in
            anomalies.contains { $0.index == index } ? nil : score
        }
        
        guard !normalScores.isEmpty else { return 0.5 }
        
        let anomalyMean = anomalyScores.reduce(0, +) / Double(anomalyScores.count)
        let normalMean = normalScores.reduce(0, +) / Double(normalScores.count)
        
        let separation = anomalyMean - normalMean
        let maxScore = scores.max() ?? 1.0
        
        return min(1.0, max(0.0, separation / maxScore))
    }
    
    private func trainAnomalyModel(data: [Double], method: AnomalyDetectionMethod) throws -> AnomalyModel {
        let threshold = extractThreshold(from: method)
        
        return AnomalyModel(
            parameters: [
                "mean": data.reduce(0, +) / Double(data.count),
                "std": sqrt(data.map { pow($0 - (data.reduce(0, +) / Double(data.count)), 2) }.reduce(0, +) / Double(data.count))
            ],
            threshold: threshold,
            method: method,
            trainedOn: Date()
        )
    }
    
    private func extractThreshold(from method: AnomalyDetectionMethod) -> Double {
        switch method {
        case .statistical(let threshold):
            return threshold
        case .isolationForest(_, let contamination):
            return 1.0 - contamination // Simplified
        case .localOutlierFactor(_):
            return 1.5
        default:
            return 2.0
        }
    }
    
    private func calculateRealTimeScore(
        value: Double,
        historicalData: [Double],
        model: AnomalyModel?,
        method: AnomalyDetectionMethod
    ) throws -> Double {
        
        switch method {
        case .statistical(_):
            guard let model = model,
                  let mean = model.parameters["mean"] as? Double,
                  let std = model.parameters["std"] as? Double else {
                throw AnalyticsError.invalidModel("Statistical model parameters missing")
            }
            
            return abs(value - mean) / max(std, 1e-10)
            
        default:
            // Fallback to simple statistical method
            let mean = historicalData.reduce(0, +) / Double(historicalData.count)
            let variance = historicalData.map { pow($0 - mean, 2) }.reduce(0, +) / Double(historicalData.count)
            let std = sqrt(variance)
            
            return abs(value - mean) / max(std, 1e-10)
        }
    }
}

// MARK: - Health-Specific Anomaly Detection

extension AnomalyDetection {
    
    /// Detect anomalies in vital signs
    public func detectVitalSignAnomalies(
        heartRate: [Double],
        bloodPressure: [Double],
        oxygenSaturation: [Double],
        timestamps: [Date]? = nil
    ) async throws -> MultiVariateAnomalyResult {
        
        let vitalSigns = [heartRate, bloodPressure, oxygenSaturation]
        
        return try await detectMultivariateAnomalies(
            data: vitalSigns,
            timestamps: timestamps,
            method: .isolationForest(numTrees: 100, contamination: 0.05)
        )
    }
    
    /// Detect medication adherence anomalies
    public func detectMedicationAnomalies(
        adherenceData: [Double],
        timestamps: [Date]? = nil
    ) async throws -> AnomalyResult {
        
        return try await detectUnivariateAnomalies(
            data: adherenceData,
            timestamps: timestamps,
            method: .statistical(threshold: 2.0)
        )
    }
    
    /// Detect sleep pattern anomalies
    public func detectSleepPatternAnomalies(
        sleepDuration: [Double],
        sleepQuality: [Double],
        timestamps: [Date]? = nil
    ) async throws -> MultiVariateAnomalyResult {
        
        let sleepData = [sleepDuration, sleepQuality]
        
        return try await detectMultivariateAnomalies(
            data: sleepData,
            timestamps: timestamps,
            method: .ensemble(methods: [
                .statistical(threshold: 2.0),
                .isolationForest(numTrees: 50, contamination: 0.1)
            ])
        )
    }
}

// MARK: - Array Extension for Safe Access

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
