import Foundation
import Accelerate
import simd

/// Optimized vector operations for SleepIntelligenceEngine with SIMD and Accelerate framework
public final class OptimizedVectorOperations {
    
    public static let shared = OptimizedVectorOperations()
    
    private init() {}
    
    // MARK: - Optimized Vector Operations
    
    /// High-performance cosine similarity using SIMD
    public func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count, !vector1.isEmpty else { return 0.0 }
        
        let count = vector1.count
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        // Use Accelerate framework for vectorized operations
        vDSP_dotpr(vector1, 1, vector2, 1, &dotProduct, vDSP_Length(count))
        vDSP_svesq(vector1, 1, &norm1, vDSP_Length(count))
        vDSP_svesq(vector2, 1, &norm2, vDSP_Length(count))
        
        norm1 = sqrt(norm1)
        norm2 = sqrt(norm2)
        
        guard norm1 > 0 && norm2 > 0 else { return 0.0 }
        
        return dotProduct / (norm1 * norm2)
    }
    
    /// Batch cosine similarity computation
    public func batchCosineSimilarity(query: [Float], vectors: [[Float]]) -> [Float] {
        return vectors.map { cosineSimilarity(query, $0) }
    }
    
    /// Optimized euclidean distance using SIMD
    public func euclideanDistance(_ vector1: [Float], _ vector2: [Float]) -> Float {
        guard vector1.count == vector2.count, !vector1.isEmpty else { return Float.infinity }
        
        let count = vector1.count
        var diff = [Float](repeating: 0.0, count: count)
        var distance: Float = 0.0
        
        // Compute difference vector
        vDSP_vsub(vector2, 1, vector1, 1, &diff, 1, vDSP_Length(count))
        
        // Compute squared euclidean distance
        vDSP_svesq(diff, 1, &distance, vDSP_Length(count))
        
        return sqrt(distance)
    }
    
    /// Fast vector normalization using Accelerate
    public func normalizeVector(_ vector: [Float]) -> [Float] {
        guard !vector.isEmpty else { return vector }
        
        var normalized = vector
        var norm: Float = 0.0
        
        // Compute L2 norm
        vDSP_svesq(vector, 1, &norm, vDSP_Length(vector.count))
        norm = sqrt(norm)
        
        guard norm > 0 else { return vector }
        
        // Normalize
        vDSP_vsdiv(vector, 1, &norm, &normalized, 1, vDSP_Length(vector.count))
        
        return normalized
    }
    
    /// Optimized batch normalization
    public func batchNormalize(_ vectors: [[Float]]) -> [[Float]] {
        return vectors.map { normalizeVector($0) }
    }
    
    /// Fast top-k similar vectors using partial sorting
    public func findTopKSimilar(
        query: [Float],
        vectors: [(id: String, vector: [Float])],
        k: Int,
        threshold: Float = 0.0
    ) -> [(id: String, similarity: Float)] {
        
        guard k > 0 && !vectors.isEmpty else { return [] }
        
        // Compute all similarities
        let similarities = vectors.map { vectorData in
            let similarity = cosineSimilarity(query, vectorData.vector)
            return (id: vectorData.id, similarity: similarity)
        }
        
        // Filter by threshold and get top-k
        return similarities
            .filter { $0.similarity >= threshold }
            .sorted { $0.similarity > $1.similarity }
            .prefix(k)
            .map { (id: $0.id, similarity: $0.similarity) }
    }
    
    /// Optimized vector addition using SIMD
    public func addVectors(_ vector1: [Float], _ vector2: [Float]) -> [Float] {
        guard vector1.count == vector2.count else { return vector1 }
        
        var result = [Float](repeating: 0.0, count: vector1.count)
        vDSP_vadd(vector1, 1, vector2, 1, &result, 1, vDSP_Length(vector1.count))
        
        return result
    }
    
    /// Optimized weighted vector combination
    public func weightedCombination(vectors: [(vector: [Float], weight: Float)]) -> [Float] {
        guard let firstVector = vectors.first?.vector else { return [] }
        
        var result = [Float](repeating: 0.0, count: firstVector.count)
        
        for (vector, weight) in vectors {
            guard vector.count == firstVector.count else { continue }
            
            var weightedVector = [Float](repeating: 0.0, count: vector.count)
            vDSP_vsmul(vector, 1, &weight, &weightedVector, 1, vDSP_Length(vector.count))
            vDSP_vadd(result, 1, weightedVector, 1, &result, 1, vDSP_Length(vector.count))
        }
        
        return result
    }
    
    /// Fast vector quantization for reduced memory usage
    public func quantizeVector(_ vector: [Float], levels: Int = 256) -> [UInt8] {
        guard !vector.isEmpty && levels > 1 else { return [] }
        
        // Find min and max values
        var minVal: Float = 0.0
        var maxVal: Float = 0.0
        vDSP_minv(vector, 1, &minVal, vDSP_Length(vector.count))
        vDSP_maxv(vector, 1, &maxVal, vDSP_Length(vector.count))
        
        let range = maxVal - minVal
        guard range > 0 else { return Array(repeating: 0, count: vector.count) }
        
        let scale = Float(levels - 1) / range
        
        return vector.map { value in
            let normalized = (value - minVal) * scale
            return UInt8(max(0, min(Float(levels - 1), normalized)))
        }
    }
    
    /// Dequantize vector back to Float
    public func dequantizeVector(_ quantized: [UInt8], minVal: Float, maxVal: Float) -> [Float] {
        guard !quantized.isEmpty && maxVal > minVal else { return [] }
        
        let range = maxVal - minVal
        let scale = range / Float(255) // Assuming UInt8 quantization
        
        return quantized.map { value in
            minVal + Float(value) * scale
        }
    }
    
    /// Optimized PCA dimensionality reduction
    public func reduceDimensions(
        vectors: [[Float]],
        targetDimensions: Int
    ) -> (reducedVectors: [[Float]], projectionMatrix: [[Float]]) {
        
        guard !vectors.isEmpty,
              let firstVector = vectors.first,
              targetDimensions > 0,
              targetDimensions < firstVector.count else {
            return (vectors, [])
        }
        
        let originalDimensions = firstVector.count
        let numVectors = vectors.count
        
        // Compute mean vector
        var meanVector = [Float](repeating: 0.0, count: originalDimensions)
        for vector in vectors {
            vDSP_vadd(meanVector, 1, vector, 1, &meanVector, 1, vDSP_Length(originalDimensions))
        }
        var scale = Float(numVectors)
        vDSP_vsdiv(meanVector, 1, &scale, &meanVector, 1, vDSP_Length(originalDimensions))
        
        // Center the data
        let centeredVectors = vectors.map { vector in
            var centered = [Float](repeating: 0.0, count: originalDimensions)
            vDSP_vsub(meanVector, 1, vector, 1, &centered, 1, vDSP_Length(originalDimensions))
            return centered
        }
        
        // For simplicity, use random projection as approximation to PCA
        // In production, this would use proper SVD
        let projectionMatrix = generateRandomProjectionMatrix(
            from: originalDimensions,
            to: targetDimensions
        )
        
        let reducedVectors = centeredVectors.map { vector in
            projectVector(vector, with: projectionMatrix)
        }
        
        return (reducedVectors, projectionMatrix)
    }
    
    /// Generate random projection matrix for dimensionality reduction
    private func generateRandomProjectionMatrix(from: Int, to: Int) -> [[Float]] {
        let scale = sqrt(1.0 / Float(from))
        
        return (0..<to).map { _ in
            (0..<from).map { _ in
                Float.random(in: -1...1) * scale
            }
        }
    }
    
    /// Project vector using projection matrix
    private func projectVector(_ vector: [Float], with matrix: [[Float]]) -> [Float] {
        return matrix.map { row in
            var result: Float = 0.0
            vDSP_dotpr(vector, 1, row, 1, &result, vDSP_Length(vector.count))
            return result
        }
    }
    
    /// Optimized clustering using k-means with SIMD
    public func performKMeansClustering(
        vectors: [[Float]],
        k: Int,
        maxIterations: Int = 100,
        tolerance: Float = 1e-6
    ) -> (centroids: [[Float]], assignments: [Int]) {
        
        guard !vectors.isEmpty,
              let firstVector = vectors.first,
              k > 0,
              k <= vectors.count else {
            return ([], [])
        }
        
        let dimensions = firstVector.count
        var centroids = initializeRandomCentroids(count: k, dimensions: dimensions, from: vectors)
        var assignments = Array(repeating: 0, count: vectors.count)
        var converged = false
        
        for iteration in 0..<maxIterations {
            guard !converged else { break }
            
            // Assignment step
            let newAssignments = vectors.enumerated().map { index, vector in
                var bestCluster = 0
                var bestDistance = Float.infinity
                
                for (clusterIndex, centroid) in centroids.enumerated() {
                    let distance = euclideanDistance(vector, centroid)
                    if distance < bestDistance {
                        bestDistance = distance
                        bestCluster = clusterIndex
                    }
                }
                
                return bestCluster
            }
            
            // Check for convergence
            let changedAssignments = zip(assignments, newAssignments).reduce(0) { count, pair in
                count + (pair.0 != pair.1 ? 1 : 0)
            }
            
            if Float(changedAssignments) / Float(vectors.count) < tolerance {
                converged = true
            }
            
            assignments = newAssignments
            
            // Update step
            for clusterIndex in 0..<k {
                let clusterVectors = vectors.enumerated().compactMap { index, vector in
                    assignments[index] == clusterIndex ? vector : nil
                }
                
                if !clusterVectors.isEmpty {
                    centroids[clusterIndex] = computeCentroid(of: clusterVectors)
                }
            }
        }
        
        return (centroids, assignments)
    }
    
    /// Compute centroid of vectors using vectorized operations
    private func computeCentroid(of vectors: [[Float]]) -> [Float] {
        guard !vectors.isEmpty,
              let firstVector = vectors.first else { return [] }
        
        var centroid = [Float](repeating: 0.0, count: firstVector.count)
        
        for vector in vectors {
            vDSP_vadd(centroid, 1, vector, 1, &centroid, 1, vDSP_Length(firstVector.count))
        }
        
        var count = Float(vectors.count)
        vDSP_vsdiv(centroid, 1, &count, &centroid, 1, vDSP_Length(firstVector.count))
        
        return centroid
    }
    
    /// Initialize random centroids
    private func initializeRandomCentroids(count: Int, dimensions: Int, from vectors: [[Float]]) -> [[Float]] {
        // Use k-means++ initialization for better convergence
        guard !vectors.isEmpty else {
            return (0..<count).map { _ in
                (0..<dimensions).map { _ in Float.random(in: -1...1) }
            }
        }
        
        var centroids: [[Float]] = []
        
        // Choose first centroid randomly
        centroids.append(vectors.randomElement()!)
        
        // Choose remaining centroids with probability proportional to squared distance
        for _ in 1..<count {
            let distances = vectors.map { vector in
                centroids.map { centroid in
                    let dist = euclideanDistance(vector, centroid)
                    return dist * dist
                }.min() ?? Float.infinity
            }
            
            let totalDistance = distances.reduce(0, +)
            let threshold = Float.random(in: 0...totalDistance)
            
            var cumulative: Float = 0
            for (index, distance) in distances.enumerated() {
                cumulative += distance
                if cumulative >= threshold {
                    centroids.append(vectors[index])
                    break
                }
            }
        }
        
        return centroids
    }
}

// MARK: - SIMD Extensions for Better Performance

extension simd_float4 {
    /// Fast dot product using SIMD
    public func dot(_ other: simd_float4) -> Float {
        return simd_dot(self, other)
    }
    
    /// Fast cosine similarity using SIMD
    public func cosineSimilarity(with other: simd_float4) -> Float {
        let dotProduct = simd_dot(self, other)
        let magnitudes = simd_length(self) * simd_length(other)
        return magnitudes > 0 ? dotProduct / magnitudes : 0
    }
}

extension Array where Element == Float {
    /// Convert to SIMD vectors for batch processing
    public func toSIMDVectors() -> [simd_float4] {
        var result: [simd_float4] = []
        
        for i in stride(from: 0, to: count, by: 4) {
            let endIndex = min(i + 4, count)
            let slice = Array(self[i..<endIndex])
            
            // Pad with zeros if needed
            let paddedSlice = slice + Array(repeating: 0.0, count: 4 - slice.count)
            result.append(simd_float4(paddedSlice[0], paddedSlice[1], paddedSlice[2], paddedSlice[3]))
        }
        
        return result
    }
}

// MARK: - Cache-Optimized Vector Storage

public final class VectorCache {
    private var cache: [String: [Float]] = [:]
    private var lruOrder: [String] = []
    private let maxSize: Int
    private let lock = NSLock()
    
    public init(maxSize: Int = 1000) {
        self.maxSize = maxSize
    }
    
    public func get(_ key: String) -> [Float]? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let vector = cache[key] else { return nil }
        
        // Update LRU order
        if let index = lruOrder.firstIndex(of: key) {
            lruOrder.remove(at: index)
        }
        lruOrder.append(key)
        
        return vector
    }
    
    public func set(_ key: String, vector: [Float]) {
        lock.lock()
        defer { lock.unlock() }
        
        // Remove if already exists
        if cache[key] != nil {
            if let index = lruOrder.firstIndex(of: key) {
                lruOrder.remove(at: index)
            }
        }
        
        // Add new vector
        cache[key] = vector
        lruOrder.append(key)
        
        // Evict if necessary
        while cache.count > maxSize {
            let oldestKey = lruOrder.removeFirst()
            cache.removeValue(forKey: oldestKey)
        }
    }
    
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        
        cache.removeAll()
        lruOrder.removeAll()
    }
}

// MARK: - Performance Benchmarking

public struct VectorPerformanceMetrics {
    public var operationsPerSecond: Double = 0
    public var averageLatency: TimeInterval = 0
    public var memoryUsage: UInt64 = 0
    public var cacheHitRate: Double = 0
    
    public mutating func update(operationTime: TimeInterval) {
        operationsPerSecond = 1.0 / operationTime
        averageLatency = (averageLatency + operationTime) / 2
    }
}