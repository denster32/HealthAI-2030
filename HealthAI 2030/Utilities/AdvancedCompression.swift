import Foundation
import Compression
import os.log
import Combine

/// Advanced memory compression system for SomnaSync Pro
@MainActor
class AdvancedCompression: ObservableObject {
    static let shared = AdvancedCompression()
    
    // MARK: - Published Properties
    @Published var isCompressing = false
    @Published var compressionProgress: Double = 0.0
    @Published var compressionRatio: Double = 0.0
    @Published var totalCompressedSize: Int64 = 0
    @Published var totalOriginalSize: Int64 = 0
    
    // MARK: - Private Properties
    private let compressionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.somnasync.compression"
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
    private var compressionCache: [String: CompressedData] = [:]
    
    // MARK: - Configuration
    private let maxCompressedCacheSize = 50 * 1024 * 1024 // 50MB
    private let compressionThreshold = 1024 // 1KB minimum size for compression
    
    private init() {
        setupCompressionManager()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupCompressionManager() {
        Logger.success("Advanced compression manager initialized", log: Logger.performance)
    }
    
    // MARK: - Compression Operations
    
    func compressData(_ data: Data, algorithm: CompressionAlgorithmType = .lz4) async -> CompressedData? {
        guard data.count >= compressionThreshold else {
            return CompressedData(
                id: UUID(),
                originalData: data,
                compressedData: data,
                algorithm: algorithm,
                compressionRatio: 1.0,
                timestamp: Date()
            )
        }
        
        return await compressionQueue.asyncResult {
            return try await self.performCompression(data: data, algorithm: algorithm)
        }
    }
    
    private func performCompression(data: Data, algorithm: CompressionAlgorithmType) async throws -> CompressedData? {
        do {
            let compressedData = try await compressWithAlgorithm(data, algorithm: algorithm)
            let compressionRatio = Double(compressedData.count) / Double(data.count)
            
            let result = CompressedData(
                id: UUID(),
                originalData: data,
                compressedData: compressedData,
                algorithm: algorithm,
                compressionRatio: compressionRatio,
                timestamp: Date()
            )
            
            // Update statistics
            await updateCompressionStatistics(originalSize: data.count, compressedSize: compressedData.count)
            
            // Cache result
            await cacheCompressedData(result)
            
            Logger.info("Compressed data: \(data.count) -> \(compressedData.count) bytes (ratio: \(compressionRatio))", log: Logger.performance)
            
            return result
            
        } catch {
            Logger.error("Compression failed: \(error.localizedDescription)", log: Logger.performance)
            return nil
        }
    }
    
    private func compressWithAlgorithm(_ data: Data, algorithm: CompressionAlgorithmType) async throws -> Data {
        switch algorithm {
        case .lz4:
            return try await compressLZ4(data)
        case .lzma:
            return try await compressLZMA(data)
        case .zlib:
            return try await compressZLib(data)
        case .lzfse:
            return try await compressLZFSE(data)
        }
    }
    
    // MARK: - Algorithm-Specific Compression
    
    private func compressLZ4(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize + (sourceSize / 16) + 64
        
        var compressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            compressedData.withUnsafeMutableBytes { destPtr in
                compression_encode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZ4
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.compressionFailed
        }
        
        compressedData.count = result
        return compressedData
    }
    
    private func compressLZMA(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize + (sourceSize / 16) + 64
        
        var compressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            compressedData.withUnsafeMutableBytes { destPtr in
                compression_encode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZMA
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.compressionFailed
        }
        
        compressedData.count = result
        return compressedData
    }
    
    private func compressZLib(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize + (sourceSize / 16) + 64
        
        var compressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            compressedData.withUnsafeMutableBytes { destPtr in
                compression_encode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.compressionFailed
        }
        
        compressedData.count = result
        return compressedData
    }
    
    private func compressLZFSE(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize + (sourceSize / 16) + 64
        
        var compressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            compressedData.withUnsafeMutableBytes { destPtr in
                compression_encode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.compressionFailed
        }
        
        compressedData.count = result
        return compressedData
    }
    
    // MARK: - Decompression Operations
    
    func decompressData(_ compressedData: CompressedData) async -> Data? {
        do {
            let decompressedData = try await decompressWithAlgorithm(
                compressedData.compressedData,
                algorithm: compressedData.algorithm
            )
            
            Logger.info("Decompressed data: \(compressedData.compressedData.count) -> \(decompressedData.count) bytes", log: Logger.performance)
            
            return decompressedData
            
        } catch {
            Logger.error("Decompression failed: \(error.localizedDescription)", log: Logger.performance)
            return nil
        }
    }
    
    private func decompressWithAlgorithm(_ data: Data, algorithm: CompressionAlgorithmType) async throws -> Data {
        switch algorithm {
        case .lz4:
            return try await decompressLZ4(data)
        case .lzma:
            return try await decompressLZMA(data)
        case .zlib:
            return try await decompressZLib(data)
        case .lzfse:
            return try await decompressLZFSE(data)
        }
    }
    
    // MARK: - Algorithm-Specific Decompression
    
    private func decompressLZ4(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize * 4 // Estimate decompressed size
        
        var decompressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            decompressedData.withUnsafeMutableBytes { destPtr in
                compression_decode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZ4
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.decompressionFailed
        }
        
        decompressedData.count = result
        return decompressedData
    }
    
    private func decompressLZMA(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize * 4 // Estimate decompressed size
        
        var decompressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            decompressedData.withUnsafeMutableBytes { destPtr in
                compression_decode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZMA
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.decompressionFailed
        }
        
        decompressedData.count = result
        return decompressedData
    }
    
    private func decompressZLib(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize * 4 // Estimate decompressed size
        
        var decompressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            decompressedData.withUnsafeMutableBytes { destPtr in
                compression_decode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.decompressionFailed
        }
        
        decompressedData.count = result
        return decompressedData
    }
    
    private func decompressLZFSE(_ data: Data) async throws -> Data {
        let sourceSize = data.count
        let destinationSize = sourceSize * 4 // Estimate decompressed size
        
        var decompressedData = Data(count: destinationSize)
        
        let result = data.withUnsafeBytes { sourcePtr in
            decompressedData.withUnsafeMutableBytes { destPtr in
                compression_decode_buffer(
                    destPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    destinationSize,
                    sourcePtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    sourceSize,
                    nil,
                    COMPRESSION_LZFSE
                )
            }
        }
        
        guard result > 0 else {
            throw CompressionError.decompressionFailed
        }
        
        decompressedData.count = result
        return decompressedData
    }
    
    // MARK: - Intelligent Compression
    
    func compressIntelligently(_ data: Data) async -> CompressedData? {
        // Try different algorithms and choose the best one
        var bestResult: CompressedData?
        var bestRatio = 1.0
        
        let algorithms: [CompressionAlgorithmType] = [.lz4, .lzfse, .zlib, .lzma]
        
        for algorithm in algorithms {
            if let result = await compressData(data, algorithm: algorithm) {
                if result.compressionRatio < bestRatio {
                    bestRatio = result.compressionRatio
                    bestResult = result
                }
            }
        }
        
        return bestResult
    }
    
    func compressBatch(_ dataArray: [Data]) async -> [CompressedData] {
        var results: [CompressedData] = []
        
        await MainActor.run {
            isCompressing = true
            compressionProgress = 0.0
        }
        
        let totalCount = dataArray.count
        
        for (index, data) in dataArray.enumerated() {
            if let compressed = await compressData(data) {
                results.append(compressed)
            }
            
            await MainActor.run {
                compressionProgress = Double(index + 1) / Double(totalCount)
            }
        }
        
        await MainActor.run {
            isCompressing = false
            compressionProgress = 1.0
        }
        
        return results
    }
    
    // MARK: - Cache Management
    
    private func cacheCompressedData(_ data: CompressedData) async {
        let key = data.id.uuidString
        compressionCache[key] = data
        
        // Check cache size and evict if necessary
        await manageCacheSize()
    }
    
    private func manageCacheSize() async {
        let totalSize = compressionCache.values.reduce(0) { $0 + $1.compressedData.count }
        
        if totalSize > maxCompressedCacheSize {
            // Remove oldest entries
            let sortedEntries = compressionCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = sortedEntries.prefix(sortedEntries.count / 4) // Remove 25%
            
            for entry in entriesToRemove {
                compressionCache.removeValue(forKey: entry.key)
            }
            
            Logger.info("Evicted \(entriesToRemove.count) entries from compression cache", log: Logger.performance)
        }
    }
    
    func getCachedCompressedData(_ id: UUID) -> CompressedData? {
        return compressionCache[id.uuidString]
    }
    
    func clearCompressionCache() {
        compressionCache.removeAll()
        Logger.info("Compression cache cleared", log: Logger.performance)
    }
    
    // MARK: - Statistics
    
    private func updateCompressionStatistics(originalSize: Int, compressedSize: Int) async {
        await MainActor.run {
            totalOriginalSize += Int64(originalSize)
            totalCompressedSize += Int64(compressedSize)
            compressionRatio = totalCompressedSize > 0 ? Double(totalCompressedSize) / Double(totalOriginalSize) : 1.0
        }
    }
    
    func getCompressionStatistics() -> CompressionStatistics {
        return CompressionStatistics(
            totalOriginalSize: totalOriginalSize,
            totalCompressedSize: totalCompressedSize,
            compressionRatio: compressionRatio,
            cacheSize: compressionCache.count
        )
    }
}

// MARK: - Supporting Types

struct CompressedData {
    let id: UUID
    let originalData: Data
    let compressedData: Data
    let algorithm: CompressionAlgorithmType
    let compressionRatio: Double
    let timestamp: Date
}

struct CompressionStatistics {
    let totalOriginalSize: Int64
    let totalCompressedSize: Int64
    let compressionRatio: Double
    let cacheSize: Int
}

enum CompressionAlgorithmType {
    case lz4, lzma, zlib, lzfse
}

enum CompressionError: Error {
    case compressionFailed
    case decompressionFailed
    case invalidData
    case unsupportedAlgorithm
}

// MARK: - Extensions

extension OperationQueue {
    func asyncResult<T>(_ block: @escaping () async throws -> T) async -> T? {
        return await withCheckedContinuation { continuation in
            self.addOperation {
                Task {
                    do {
                        let result = try await block()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
} 