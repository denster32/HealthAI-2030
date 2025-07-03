import Foundation
import CoreML
import Accelerate

class BeatMorphologyAnalyzer {
    
    // MARK: - Constants
    private let qrsWindowSize = 120 // samples (120ms at 512Hz)
    private let vaeLatentDimension = 16
    private let outlierThreshold = 2.0 // Standard deviations for outlier detection
    private let clusterCount = 5 // Number of QRS morphology clusters
    
    // MARK: - Private Properties
    private var qrsClusters: [QRSCluster] = []
    private var vaeModel: MLModel? // Placeholder for VAE model
    private var morphologyDatabase: [QRSMorphology] = []
    
    // MARK: - Public Interface
    
    /// Analyze beat morphology and detect ischemic risk
    func analyzeBeatMorphology(ecgData: ProcessedECGData, completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        print("Beat Morphology Analyzer: Starting analysis...")
        
        // Extract QRS complexes
        let qrsComplexes = extractQRSComplexes(from: ecgData)
        
        // Extract morphology features
        let morphologies = extractMorphologyFeatures(from: qrsComplexes)
        
        // Perform VAE clustering
        performVAEClustering(morphologies: morphologies) { [weak self] result in
            switch result {
            case .success(let clusters):
                self?.qrsClusters = clusters
                
                // Detect outliers and assess ischemic risk
                let ischemicRisk = self?.assessIschemicRisk(morphologies: morphologies, clusters: clusters) ?? 0.0
                
                // Create insight
                let insight = ECGInsight(
                    type: .beatMorphology,
                    severity: self?.severityForRisk(ischemicRisk) ?? .normal,
                    confidence: self?.calculateConfidence(morphologies: morphologies) ?? 0.0,
                    description: self?.generateDescription(ischemicRisk: ischemicRisk, clusters: clusters) ?? "",
                    timestamp: Date(),
                    data: BeatMorphologyData(
                        ischemicRisk: ischemicRisk,
                        clusterCount: clusters.count,
                        outlierCount: self?.countOutliers(morphologies: morphologies, clusters: clusters) ?? 0,
                        averageMorphologyScore: self?.calculateAverageMorphologyScore(morphologies: morphologies) ?? 0.0
                    )
                )
                
                completion(.success(insight))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get current morphology clusters
    func getCurrentClusters() -> [QRSCluster] {
        return qrsClusters
    }
    
    /// Update morphology database with new data
    func updateMorphologyDatabase(_ newMorphologies: [QRSMorphology]) {
        morphologyDatabase.append(contentsOf: newMorphologies)
        
        // Keep database size manageable
        if morphologyDatabase.count > 10000 {
            morphologyDatabase.removeFirst(morphologyDatabase.count - 10000)
        }
        
        print("Beat Morphology Analyzer: Updated database with \(newMorphologies.count) new morphologies")
    }
    
    // MARK: - Private Methods
    
    private func extractQRSComplexes(from ecgData: ProcessedECGData) -> [QRSComplex] {
        let processor = ECGDataProcessor()
        return processor.extractQRSComplexes(ecgData)
    }
    
    private func extractMorphologyFeatures(from qrsComplexes: [QRSComplex]) -> [QRSMorphology] {
        var morphologies: [QRSMorphology] = []
        
        for qrsComplex in qrsComplexes {
            let morphology = extractMorphologyFeatures(from: qrsComplex)
            morphologies.append(morphology)
        }
        
        print("Beat Morphology Analyzer: Extracted \(morphologies.count) morphology features")
        return morphologies
    }
    
    private func extractMorphologyFeatures(from qrsComplex: QRSComplex) -> QRSMorphology {
        // Extract comprehensive morphology features
        let amplitude = qrsComplex.rPoint - min(qrsComplex.qPoint, qrsComplex.sPoint)
        let width = qrsComplex.width
        let qrRatio = abs(qrsComplex.qPoint) / (abs(qrsComplex.rPoint) + 1e-10)
        let rsRatio = abs(qrsComplex.sPoint) / (abs(qrsComplex.rPoint) + 1e-10)
        
        // Calculate additional features
        let area = calculateQRSArea(qrsComplex)
        let slope = calculateQRSSlope(qrsComplex)
        let symmetry = calculateQRSSymmetry(qrsComplex)
        
        return QRSMorphology(
            amplitude: amplitude,
            width: width,
            qrRatio: qrRatio,
            rsRatio: rsRatio,
            area: area,
            slope: slope,
            symmetry: symmetry,
            timestamp: qrsComplex.rPeakTime,
            index: qrsComplex.index
        )
    }
    
    private func calculateQRSArea(_ qrsComplex: QRSComplex) -> Double {
        // Simplified area calculation
        // In production, this would integrate the actual QRS waveform
        let baseWidth = qrsComplex.width
        let height = qrsComplex.rPoint - min(qrsComplex.qPoint, qrsComplex.sPoint)
        return baseWidth * height * 0.5 // Triangular approximation
    }
    
    private func calculateQRSSlope(_ qrsComplex: QRSComplex) -> Double {
        // Calculate QRS upslope
        let riseTime = qrsComplex.rPeakTime - qrsComplex.qPeakTime
        let amplitude = qrsComplex.rPoint - qrsComplex.qPoint
        return amplitude / (riseTime + 1e-10)
    }
    
    private func calculateQRSSymmetry(_ qrsComplex: QRSComplex) -> Double {
        // Calculate QRS symmetry (0 = asymmetric, 1 = symmetric)
        let leftHalf = abs(qrsComplex.rPoint - qrsComplex.qPoint)
        let rightHalf = abs(qrsComplex.rPoint - qrsComplex.sPoint)
        let total = leftHalf + rightHalf
        
        guard total > 0 else { return 0.0 }
        
        return 1.0 - abs(leftHalf - rightHalf) / total
    }
    
    private func performVAEClustering(morphologies: [QRSMorphology], completion: @escaping (Result<[QRSCluster], Error>) -> Void) {
        // For M2, we'll use a simplified clustering approach
        // In production, this would use a trained VAE model
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(.failure(BeatMorphologyError.initializationFailed))
                return
            }
            
            // Convert morphologies to feature vectors
            let featureVectors = morphologies.map { self.morphologyToFeatureVector($0) }
            
            // Perform k-means clustering
            let clusters = self.performKMeansClustering(featureVectors: featureVectors, k: self.clusterCount)
            
            // Convert to QRSCluster objects
            let qrsClusters = self.convertToQRSClusters(clusters: clusters, morphologies: morphologies)
            
            DispatchQueue.main.async {
                completion(.success(qrsClusters))
            }
        }
    }
    
    private func morphologyToFeatureVector(_ morphology: QRSMorphology) -> [Double] {
        // Convert morphology to normalized feature vector
        return [
            morphology.amplitude,
            morphology.width,
            morphology.qrRatio,
            morphology.rsRatio,
            morphology.area,
            morphology.slope,
            morphology.symmetry
        ]
    }
    
    private func performKMeansClustering(featureVectors: [[Double]], k: Int) -> [Cluster] {
        // Simplified k-means implementation
        // In production, this would use optimized clustering algorithms
        
        guard !featureVectors.isEmpty else { return [] }
        
        let featureCount = featureVectors[0].count
        var centroids = (0..<k).map { _ in
            (0..<featureCount).map { _ in Double.random(in: 0...1) }
        }
        
        var clusters: [Cluster] = Array(repeating: Cluster(centroid: [], points: []), count: k)
        
        // Simple k-means iteration
        for _ in 0..<10 { // Max 10 iterations
            // Assign points to nearest centroid
            for (index, vector) in featureVectors.enumerated() {
                let nearestCentroid = findNearestCentroid(vector: vector, centroids: centroids)
                clusters[nearestCentroid].points.append(index)
            }
            
            // Update centroids
            for i in 0..<k {
                if !clusters[i].points.isEmpty {
                    let clusterVectors = clusters[i].points.map { featureVectors[$0] }
                    centroids[i] = calculateCentroid(vectors: clusterVectors)
                    clusters[i].centroid = centroids[i]
                }
            }
            
            // Clear points for next iteration
            for i in 0..<k {
                clusters[i].points.removeAll()
            }
        }
        
        return clusters
    }
    
    private func findNearestCentroid(vector: [Double], centroids: [[Double]]) -> Int {
        var minDistance = Double.infinity
        var nearestIndex = 0
        
        for (index, centroid) in centroids.enumerated() {
            let distance = euclideanDistance(vector1: vector, vector2: centroid)
            if distance < minDistance {
                minDistance = distance
                nearestIndex = index
            }
        }
        
        return nearestIndex
    }
    
    private func euclideanDistance(vector1: [Double], vector2: [Double]) -> Double {
        guard vector1.count == vector2.count else { return Double.infinity }
        
        let squaredDifferences = zip(vector1, vector2).map { pow($0 - $1, 2) }
        return sqrt(squaredDifferences.reduce(0, +))
    }
    
    private func calculateCentroid(vectors: [[Double]]) -> [Double] {
        guard !vectors.isEmpty else { return [] }
        
        let featureCount = vectors[0].count
        var centroid = [Double](repeating: 0.0, count: featureCount)
        
        for vector in vectors {
            for i in 0..<featureCount {
                centroid[i] += vector[i]
            }
        }
        
        return centroid.map { $0 / Double(vectors.count) }
    }
    
    private func convertToQRSClusters(clusters: [Cluster], morphologies: [QRSMorphology]) -> [QRSCluster] {
        return clusters.enumerated().map { index, cluster in
            let clusterMorphologies = cluster.points.map { morphologies[$0] }
            let centroidMorphology = calculateCentroidMorphology(morphologies: clusterMorphologies)
            
            return QRSCluster(
                id: index,
                centroid: centroidMorphology,
                morphologies: clusterMorphologies,
                size: clusterMorphologies.count,
                variance: calculateClusterVariance(morphologies: clusterMorphologies, centroid: centroidMorphology)
            )
        }
    }
    
    private func calculateCentroidMorphology(morphologies: [QRSMorphology]) -> QRSMorphology {
        guard !morphologies.isEmpty else {
            return QRSMorphology(
                amplitude: 0, width: 0, qrRatio: 0, rsRatio: 0,
                area: 0, slope: 0, symmetry: 0, timestamp: 0, index: 0
            )
        }
        
        let avgAmplitude = morphologies.map { $0.amplitude }.reduce(0, +) / Double(morphologies.count)
        let avgWidth = morphologies.map { $0.width }.reduce(0, +) / Double(morphologies.count)
        let avgQrRatio = morphologies.map { $0.qrRatio }.reduce(0, +) / Double(morphologies.count)
        let avgRsRatio = morphologies.map { $0.rsRatio }.reduce(0, +) / Double(morphologies.count)
        let avgArea = morphologies.map { $0.area }.reduce(0, +) / Double(morphologies.count)
        let avgSlope = morphologies.map { $0.slope }.reduce(0, +) / Double(morphologies.count)
        let avgSymmetry = morphologies.map { $0.symmetry }.reduce(0, +) / Double(morphologies.count)
        
        return QRSMorphology(
            amplitude: avgAmplitude,
            width: avgWidth,
            qrRatio: avgQrRatio,
            rsRatio: avgRsRatio,
            area: avgArea,
            slope: avgSlope,
            symmetry: avgSymmetry,
            timestamp: morphologies.first?.timestamp ?? 0,
            index: morphologies.first?.index ?? 0
        )
    }
    
    private func calculateClusterVariance(morphologies: [QRSMorphology], centroid: QRSMorphology) -> Double {
        guard !morphologies.isEmpty else { return 0.0 }
        
        let distances = morphologies.map { morphology in
            euclideanDistance(
                vector1: morphologyToFeatureVector(morphology),
                vector2: morphologyToFeatureVector(centroid)
            )
        }
        
        let meanDistance = distances.reduce(0, +) / Double(distances.count)
        let variance = distances.map { pow($0 - meanDistance, 2) }.reduce(0, +) / Double(distances.count)
        
        return variance
    }
    
    private func assessIschemicRisk(morphologies: [QRSMorphology], clusters: [QRSCluster]) -> Double {
        // Calculate ischemic risk based on outlier detection and morphology changes
        
        let outlierCount = countOutliers(morphologies: morphologies, clusters: clusters)
        let totalBeats = morphologies.count
        
        guard totalBeats > 0 else { return 0.0 }
        
        let outlierRatio = Double(outlierCount) / Double(totalBeats)
        let averageMorphologyScore = calculateAverageMorphologyScore(morphologies: morphologies)
        
        // Combine factors for risk assessment
        let riskScore = outlierRatio * 0.6 + (1.0 - averageMorphologyScore) * 0.4
        
        return min(riskScore, 1.0) // Normalize to 0-1
    }
    
    private func countOutliers(morphologies: [QRSMorphology], clusters: [QRSCluster]) -> Int {
        var outlierCount = 0
        
        for morphology in morphologies {
            let nearestCluster = findNearestCluster(morphology: morphology, clusters: clusters)
            let distance = euclideanDistance(
                vector1: morphologyToFeatureVector(morphology),
                vector2: morphologyToFeatureVector(nearestCluster.centroid)
            )
            
            // Consider outlier if distance is more than 2 standard deviations
            if distance > outlierThreshold * sqrt(nearestCluster.variance) {
                outlierCount += 1
            }
        }
        
        return outlierCount
    }
    
    private func findNearestCluster(morphology: QRSMorphology, clusters: [QRSCluster]) -> QRSCluster {
        let morphologyVector = morphologyToFeatureVector(morphology)
        
        var nearestCluster = clusters[0]
        var minDistance = Double.infinity
        
        for cluster in clusters {
            let distance = euclideanDistance(
                vector1: morphologyVector,
                vector2: morphologyToFeatureVector(cluster.centroid)
            )
            
            if distance < minDistance {
                minDistance = distance
                nearestCluster = cluster
            }
        }
        
        return nearestCluster
    }
    
    private func calculateAverageMorphologyScore(morphologies: [QRSMorphology]) -> Double {
        guard !morphologies.isEmpty else { return 0.0 }
        
        let scores = morphologies.map { morphology in
            // Calculate morphology score based on normal ranges
            let amplitudeScore = normalizeScore(morphology.amplitude, min: 0.5, max: 2.0)
            let widthScore = normalizeScore(morphology.width, min: 0.06, max: 0.12)
            let symmetryScore = morphology.symmetry
            
            return (amplitudeScore + widthScore + symmetryScore) / 3.0
        }
        
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private func normalizeScore(_ value: Double, min: Double, max: Double) -> Double {
        if value < min { return 0.0 }
        if value > max { return 0.0 }
        return 1.0 - abs(value - (min + max) / 2.0) / ((max - min) / 2.0)
    }
    
    private func severityForRisk(_ risk: Double) -> InsightSeverity {
        switch risk {
        case 0.0..<0.2:
            return .normal
        case 0.2..<0.4:
            return .mild
        case 0.4..<0.6:
            return .moderate
        case 0.6..<0.8:
            return .severe
        default:
            return .critical
        }
    }
    
    private func calculateConfidence(morphologies: [QRSMorphology]) -> Double {
        // Calculate confidence based on data quality and consistency
        guard !morphologies.isEmpty else { return 0.0 }
        
        let consistency = calculateMorphologyConsistency(morphologies: morphologies)
        let quality = Double(morphologies.count) / 100.0 // More data = higher confidence
        
        return min(consistency * quality, 1.0)
    }
    
    private func calculateMorphologyConsistency(morphologies: [QRSMorphology]) -> Double {
        // Calculate consistency of morphology features
        let amplitudes = morphologies.map { $0.amplitude }
        let widths = morphologies.map { $0.width }
        
        let amplitudeCV = coefficientOfVariation(amplitudes)
        let widthCV = coefficientOfVariation(widths)
        
        // Lower CV = higher consistency
        return 1.0 - (amplitudeCV + widthCV) / 2.0
    }
    
    private func coefficientOfVariation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(variance)
        
        return stdDev / (mean + 1e-10)
    }
    
    private func generateDescription(ischemicRisk: Double, clusters: [QRSCluster]) -> String {
        let riskPercentage = Int(ischemicRisk * 100)
        let clusterCount = clusters.count
        let outlierCount = clusters.reduce(0) { $0 + $1.morphologies.count }
        
        if ischemicRisk < 0.2 {
            return "Normal QRS morphology with \(clusterCount) distinct patterns detected."
        } else if ischemicRisk < 0.4 {
            return "Mild QRS morphology changes detected. \(riskPercentage)% ischemic risk."
        } else if ischemicRisk < 0.6 {
            return "Moderate QRS morphology abnormalities. \(riskPercentage)% ischemic risk with \(outlierCount) outlier beats."
        } else if ischemicRisk < 0.8 {
            return "Significant QRS morphology changes. \(riskPercentage)% ischemic risk with multiple outlier patterns."
        } else {
            return "Critical QRS morphology abnormalities. \(riskPercentage)% ischemic risk requiring immediate attention."
        }
    }
}

// MARK: - Supporting Types

struct QRSMorphology {
    let amplitude: Double
    let width: TimeInterval
    let qrRatio: Double
    let rsRatio: Double
    let area: Double
    let slope: Double
    let symmetry: Double
    let timestamp: TimeInterval
    let index: Int
}

struct QRSCluster {
    let id: Int
    let centroid: QRSMorphology
    let morphologies: [QRSMorphology]
    let size: Int
    let variance: Double
}

struct Cluster {
    var centroid: [Double]
    var points: [Int]
}

struct BeatMorphologyData: Codable {
    let ischemicRisk: Double
    let clusterCount: Int
    let outlierCount: Int
    let averageMorphologyScore: Double
}

enum BeatMorphologyError: Error {
    case initializationFailed
    case insufficientData
    case clusteringFailed
    case modelError
}