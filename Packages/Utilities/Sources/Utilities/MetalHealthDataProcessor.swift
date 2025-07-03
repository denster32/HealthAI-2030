import Foundation
import Metal
import MetalPerformanceShaders
import simd
import os.log
import Combine
import HealthKit

/// Metal-accelerated health data processing for real-time analytics
@MainActor
class MetalHealthDataProcessor: ObservableObject {
    static let shared = MetalHealthDataProcessor()
    
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var processingEfficiency: Double = 0.0
    @Published var currentOperation = ""
    
    // Metal components
    private let metalDevice: MTLDevice?
    private let metalCommandQueue: MTLCommandQueue?
    private let metalLibrary: MTLLibrary?
    
    // Metal compute pipeline states
    private var heartRateAnalysisKernel: MTLComputePipelineState?
    private var hrvCalculationKernel: MTLComputePipelineState?
    private var sleepMetricsKernel: MTLComputePipelineState?
    private var correlationAnalysisKernel: MTLComputePipelineState?
    
    // Performance optimization
    private let advancedMetalOptimizer = AdvancedMetalOptimizer.shared
    private var processingMetrics = HealthProcessingMetrics()
    
    // Data buffers
    private var heartRateBuffer: MTLBuffer?
    private var hrvBuffer: MTLBuffer?
    private var activityBuffer: MTLBuffer?
    private var sleepBuffer: MTLBuffer?
    private var outputBuffer: MTLBuffer?
    
    private init() {
        self.metalDevice = MTLCreateSystemDefaultDevice()
        self.metalCommandQueue = metalDevice?.makeCommandQueue()
        self.metalLibrary = metalDevice?.makeDefaultLibrary()
        
        setupMetalComputeKernels()
        Logger.info("MetalHealthDataProcessor initialized with Metal support: \(metalDevice != nil)", log: Logger.performance)
    }
    
    // MARK: - Setup
    
    private func setupMetalComputeKernels() {
        guard let device = metalDevice, let library = metalLibrary else {
            Logger.warning("Metal device or library not available", log: Logger.performance)
            return
        }
        
        do {
            // Create compute pipeline states for health data processing
            if let heartRateFunction = library.makeFunction(name: "analyzeHeartRateVariability") {
                heartRateAnalysisKernel = try device.makeComputePipelineState(function: heartRateFunction)
            }
            
            if let hrvFunction = library.makeFunction(name: "calculateHRVMetrics") {
                hrvCalculationKernel = try device.makeComputePipelineState(function: hrvFunction)
            }
            
            if let sleepFunction = library.makeFunction(name: "processSleepMetrics") {
                sleepMetricsKernel = try device.makeComputePipelineState(function: sleepFunction)
            }
            
            if let correlationFunction = library.makeFunction(name: "calculateHealthCorrelations") {
                correlationAnalysisKernel = try device.makeComputePipelineState(function: correlationFunction)
            }
            
            Logger.success("Metal compute kernels initialized", log: Logger.performance)
        } catch {
            Logger.error("Failed to setup Metal compute kernels: \(error.localizedDescription)", log: Logger.performance)
        }
    }
    
    // MARK: - Public Processing Methods
    
    /// Process heart rate data with Metal acceleration
    func processHeartRateData(_ heartRateData: [Double]) async -> HeartRateAnalysis {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let kernel = heartRateAnalysisKernel else {
            return await fallbackHeartRateProcessing(heartRateData)
        }
        
        await MainActor.run {
            isProcessing = true
            currentOperation = "Processing heart rate data with Metal..."
            processingProgress = 0.1
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await metalProcessHeartRate(heartRateData, device: device, commandQueue: commandQueue, kernel: kernel)
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordProcessingMetrics(operation: "HeartRate", duration: processingTime, dataSize: heartRateData.count)
            
            await MainActor.run {
                isProcessing = false
                processingProgress = 1.0
                currentOperation = "Heart rate analysis completed"
            }
            
            return result
        } catch {
            Logger.error("Metal heart rate processing failed: \(error.localizedDescription)", log: Logger.performance)
            await MainActor.run {
                isProcessing = false
                currentOperation = "Using fallback processing"
            }
            return await fallbackHeartRateProcessing(heartRateData)
        }
    }
    
    /// Process HRV data with Metal acceleration
    func processHRVData(_ intervalData: [Double]) async -> HRVAnalysis {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let kernel = hrvCalculationKernel else {
            return await fallbackHRVProcessing(intervalData)
        }
        
        await MainActor.run {
            isProcessing = true
            currentOperation = "Calculating HRV metrics with Metal..."
            processingProgress = 0.2
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await metalProcessHRV(intervalData, device: device, commandQueue: commandQueue, kernel: kernel)
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordProcessingMetrics(operation: "HRV", duration: processingTime, dataSize: intervalData.count)
            
            await MainActor.run {
                isProcessing = false
                processingProgress = 1.0
                currentOperation = "HRV analysis completed"
            }
            
            return result
        } catch {
            Logger.error("Metal HRV processing failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackHRVProcessing(intervalData)
        }
    }
    
    /// Process sleep data with Metal acceleration
    func processSleepData(_ sleepData: [SleepDataPoint]) async -> SleepAnalysis {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let kernel = sleepMetricsKernel else {
            return await fallbackSleepProcessing(sleepData)
        }
        
        await MainActor.run {
            isProcessing = true
            currentOperation = "Analyzing sleep patterns with Metal..."
            processingProgress = 0.3
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await metalProcessSleep(sleepData, device: device, commandQueue: commandQueue, kernel: kernel)
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await recordProcessingMetrics(operation: "Sleep", duration: processingTime, dataSize: sleepData.count)
            
            await MainActor.run {
                isProcessing = false
                processingProgress = 1.0
                currentOperation = "Sleep analysis completed"
            }
            
            return result
        } catch {
            Logger.error("Metal sleep processing failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackSleepProcessing(sleepData)
        }
    }
    
    /// Calculate health data correlations with Metal acceleration
    func calculateHealthCorrelations(_ datasets: [String: [Double]]) async -> HealthCorrelationMatrix {
        guard let device = metalDevice, let commandQueue = metalCommandQueue, let kernel = correlationAnalysisKernel else {
            return await fallbackCorrelationCalculation(datasets)
        }
        
        await MainActor.run {
            isProcessing = true
            currentOperation = "Calculating health correlations with Metal..."
            processingProgress = 0.4
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let result = try await metalCalculateCorrelations(datasets, device: device, commandQueue: commandQueue, kernel: kernel)
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let totalDataPoints = datasets.values.reduce(0) { $0 + $1.count }
            await recordProcessingMetrics(operation: "Correlation", duration: processingTime, dataSize: totalDataPoints)
            
            await MainActor.run {
                isProcessing = false
                processingProgress = 1.0
                currentOperation = "Correlation analysis completed"
            }
            
            return result
        } catch {
            Logger.error("Metal correlation processing failed: \(error.localizedDescription)", log: Logger.performance)
            return await fallbackCorrelationCalculation(datasets)
        }
    }
    
    // MARK: - Metal Processing Implementation
    
    private func metalProcessHeartRate(_ data: [Double], device: MTLDevice, commandQueue: MTLCommandQueue, kernel: MTLComputePipelineState) async throws -> HeartRateAnalysis {
        let floatData = data.map { Float($0) }
        let count = floatData.count
        
        guard let inputBuffer = device.makeBuffer(bytes: floatData, length: count * MemoryLayout<Float>.size, options: .storageModeShared),
              let outputBuffer = device.makeBuffer(length: 8 * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw MetalProcessingError.bufferCreationFailed
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalProcessingError.commandBufferCreationFailed
        }
        
        computeEncoder.setComputePipelineState(kernel)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        var dataCount = UInt32(count)
        computeEncoder.setBytes(&dataCount, length: MemoryLayout<UInt32>.size, index: 2)
        
        let threadgroupSize = MTLSize(width: min(kernel.maxTotalThreadsPerThreadgroup, count), height: 1, depth: 1)
        let threadgroups = MTLSize(width: (count + threadgroupSize.width - 1) / threadgroupSize.width, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Extract results
        let resultPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: 8)
        
        return HeartRateAnalysis(
            averageHeartRate: Double(resultPointer[0]),
            maxHeartRate: Double(resultPointer[1]),
            minHeartRate: Double(resultPointer[2]),
            restingHeartRate: Double(resultPointer[3]),
            heartRateVariability: Double(resultPointer[4]),
            irregularRhythmCount: Int(resultPointer[5]),
            recoveryHeartRate: Double(resultPointer[6]),
            stressIndicator: Double(resultPointer[7])
        )
    }
    
    private func metalProcessHRV(_ data: [Double], device: MTLDevice, commandQueue: MTLCommandQueue, kernel: MTLComputePipelineState) async throws -> HRVAnalysis {
        let floatData = data.map { Float($0) }
        let count = floatData.count
        
        guard let inputBuffer = device.makeBuffer(bytes: floatData, length: count * MemoryLayout<Float>.size, options: .storageModeShared),
              let outputBuffer = device.makeBuffer(length: 6 * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw MetalProcessingError.bufferCreationFailed
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalProcessingError.commandBufferCreationFailed
        }
        
        computeEncoder.setComputePipelineState(kernel)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        var dataCount = UInt32(count)
        computeEncoder.setBytes(&dataCount, length: MemoryLayout<UInt32>.size, index: 2)
        
        let threadgroupSize = MTLSize(width: min(kernel.maxTotalThreadsPerThreadgroup, count), height: 1, depth: 1)
        let threadgroups = MTLSize(width: (count + threadgroupSize.width - 1) / threadgroupSize.width, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Extract results
        let resultPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: 6)
        
        return HRVAnalysis(
            rmssd: Double(resultPointer[0]),
            sdnn: Double(resultPointer[1]),
            pnn50: Double(resultPointer[2]),
            triangularIndex: Double(resultPointer[3]),
            stressScore: Double(resultPointer[4]),
            recoveryScore: Double(resultPointer[5])
        )
    }
    
    private func metalProcessSleep(_ data: [SleepDataPoint], device: MTLDevice, commandQueue: MTLCommandQueue, kernel: MTLComputePipelineState) async throws -> SleepAnalysis {
        // Convert sleep data to float arrays for Metal processing
        let heartRates = data.map { Float($0.heartRate) }
        let movements = data.map { Float($0.movement) }
        let timestamps = data.map { Float($0.timestamp.timeIntervalSince1970) }
        
        let count = data.count
        let totalFloats = count * 3 // HR, movement, timestamp
        
        var inputData: [Float] = []
        for i in 0..<count {
            inputData.append(heartRates[i])
            inputData.append(movements[i])
            inputData.append(timestamps[i])
        }
        
        guard let inputBuffer = device.makeBuffer(bytes: inputData, length: totalFloats * MemoryLayout<Float>.size, options: .storageModeShared),
              let outputBuffer = device.makeBuffer(length: 10 * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw MetalProcessingError.bufferCreationFailed
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalProcessingError.commandBufferCreationFailed
        }
        
        computeEncoder.setComputePipelineState(kernel)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        var dataCount = UInt32(count)
        computeEncoder.setBytes(&dataCount, length: MemoryLayout<UInt32>.size, index: 2)
        
        let threadgroupSize = MTLSize(width: min(kernel.maxTotalThreadsPerThreadgroup, count), height: 1, depth: 1)
        let threadgroups = MTLSize(width: (count + threadgroupSize.width - 1) / threadgroupSize.width, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Extract results
        let resultPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: 10)
        
        return SleepAnalysis(
            totalSleepTime: TimeInterval(resultPointer[0]),
            deepSleepTime: TimeInterval(resultPointer[1]),
            remSleepTime: TimeInterval(resultPointer[2]),
            lightSleepTime: TimeInterval(resultPointer[3]),
            awakeTime: TimeInterval(resultPointer[4]),
            sleepEfficiency: Double(resultPointer[5]),
            sleepQuality: Double(resultPointer[6]),
            restfulnessScore: Double(resultPointer[7]),
            sleepLatency: TimeInterval(resultPointer[8]),
            wakeCount: Int(resultPointer[9])
        )
    }
    
    private func metalCalculateCorrelations(_ datasets: [String: [Double]], device: MTLDevice, commandQueue: MTLCommandQueue, kernel: MTLComputePipelineState) async throws -> HealthCorrelationMatrix {
        // Prepare correlation matrix calculation with Metal
        let datasetKeys = Array(datasets.keys)
        let matrixSize = datasetKeys.count
        let totalElements = matrixSize * matrixSize
        
        // Create flattened input data
        var inputData: [Float] = []
        let maxDataLength = datasets.values.map { $0.count }.max() ?? 0
        
        for key in datasetKeys {
            let data = datasets[key] ?? []
            let paddedData = data + Array(repeating: 0.0, count: max(0, maxDataLength - data.count))
            inputData.append(contentsOf: paddedData.map { Float($0) })
        }
        
        guard let inputBuffer = device.makeBuffer(bytes: inputData, length: inputData.count * MemoryLayout<Float>.size, options: .storageModeShared),
              let outputBuffer = device.makeBuffer(length: totalElements * MemoryLayout<Float>.size, options: .storageModeShared) else {
            throw MetalProcessingError.bufferCreationFailed
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalProcessingError.commandBufferCreationFailed
        }
        
        computeEncoder.setComputePipelineState(kernel)
        computeEncoder.setBuffer(inputBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        var matrixSizeUInt = UInt32(matrixSize)
        var dataLengthUInt = UInt32(maxDataLength)
        computeEncoder.setBytes(&matrixSizeUInt, length: MemoryLayout<UInt32>.size, index: 2)
        computeEncoder.setBytes(&dataLengthUInt, length: MemoryLayout<UInt32>.size, index: 3)
        
        let threadgroupSize = MTLSize(width: min(kernel.maxTotalThreadsPerThreadgroup, matrixSize), height: 1, depth: 1)
        let threadgroups = MTLSize(width: (matrixSize + threadgroupSize.width - 1) / threadgroupSize.width, height: matrixSize, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Extract correlation matrix
        let resultPointer = outputBuffer.contents().bindMemory(to: Float.self, capacity: totalElements)
        var correlations: [String: [String: Double]] = [:]
        
        for i in 0..<matrixSize {
            correlations[datasetKeys[i]] = [:]
            for j in 0..<matrixSize {
                let index = i * matrixSize + j
                correlations[datasetKeys[i]]![datasetKeys[j]] = Double(resultPointer[index])
            }
        }
        
        return HealthCorrelationMatrix(
            correlations: correlations,
            significantCorrelations: findSignificantCorrelations(correlations),
            strongestCorrelation: findStrongestCorrelation(correlations),
            weakestCorrelation: findWeakestCorrelation(correlations)
        )
    }
    
    // MARK: - Fallback Processing
    
    private func fallbackHeartRateProcessing(_ data: [Double]) async -> HeartRateAnalysis {
        await MainActor.run { currentOperation = "Using CPU fallback for heart rate analysis" }
        
        let avg = data.reduce(0, +) / Double(data.count)
        let max = data.max() ?? 0
        let min = data.min() ?? 0
        let resting = data.prefix(10).reduce(0, +) / 10.0
        
        return HeartRateAnalysis(
            averageHeartRate: avg,
            maxHeartRate: max,
            minHeartRate: min,
            restingHeartRate: resting,
            heartRateVariability: calculateHRVFallback(data),
            irregularRhythmCount: 0,
            recoveryHeartRate: resting,
            stressIndicator: max(0, (avg - resting) / resting)
        )
    }
    
    private func fallbackHRVProcessing(_ data: [Double]) async -> HRVAnalysis {
        await MainActor.run { currentOperation = "Using CPU fallback for HRV analysis" }
        
        let diffs = zip(data.dropFirst(), data).map { $1 - $0 }
        let rmssd = sqrt(diffs.map { $0 * $0 }.reduce(0, +) / Double(diffs.count))
        let sdnn = sqrt(data.map { d in let avg = data.reduce(0, +) / Double(data.count); return (d - avg) * (d - avg) }.reduce(0, +) / Double(data.count))
        
        return HRVAnalysis(
            rmssd: rmssd,
            sdnn: sdnn,
            pnn50: Double(diffs.filter { abs($0) > 50 }.count) / Double(diffs.count) * 100,
            triangularIndex: sdnn / (1.0/128.0),
            stressScore: max(0, min(100, (60 - rmssd) / 60 * 100)),
            recoveryScore: max(0, min(100, rmssd / 60 * 100))
        )
    }
    
    private func fallbackSleepProcessing(_ data: [SleepDataPoint]) async -> SleepAnalysis {
        await MainActor.run { currentOperation = "Using CPU fallback for sleep analysis" }
        
        let totalDuration = data.last?.timestamp.timeIntervalSince(data.first?.timestamp ?? Date()) ?? 0
        let avgMovement = data.map { $0.movement }.reduce(0, +) / Double(data.count)
        
        return SleepAnalysis(
            totalSleepTime: totalDuration,
            deepSleepTime: totalDuration * 0.25,
            remSleepTime: totalDuration * 0.20,
            lightSleepTime: totalDuration * 0.50,
            awakeTime: totalDuration * 0.05,
            sleepEfficiency: max(0, min(1, 1.0 - avgMovement)),
            sleepQuality: max(0, min(1, 1.0 - avgMovement * 0.8)),
            restfulnessScore: max(0, min(1, 1.0 - avgMovement * 0.6)),
            sleepLatency: 15 * 60, // 15 minutes default
            wakeCount: Int(avgMovement * 10)
        )
    }
    
    private func fallbackCorrelationCalculation(_ datasets: [String: [Double]]) async -> HealthCorrelationMatrix {
        await MainActor.run { currentOperation = "Using CPU fallback for correlation analysis" }
        
        let keys = Array(datasets.keys)
        var correlations: [String: [String: Double]] = [:]
        
        for key1 in keys {
            correlations[key1] = [:]
            for key2 in keys {
                let correlation = calculatePearsonCorrelation(datasets[key1] ?? [], datasets[key2] ?? [])
                correlations[key1]![key2] = correlation
            }
        }
        
        return HealthCorrelationMatrix(
            correlations: correlations,
            significantCorrelations: findSignificantCorrelations(correlations),
            strongestCorrelation: findStrongestCorrelation(correlations),
            weakestCorrelation: findWeakestCorrelation(correlations)
        )
    }
    
    // MARK: - Utility Methods
    
    private func calculateHRVFallback(_ data: [Double]) -> Double {
        guard data.count > 1 else { return 0 }
        let diffs = zip(data.dropFirst(), data).map { $1 - $0 }
        return sqrt(diffs.map { $0 * $0 }.reduce(0, +) / Double(diffs.count))
    }
    
    private func calculatePearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator != 0 ? numerator / denominator : 0
    }
    
    private func findSignificantCorrelations(_ correlations: [String: [String: Double]]) -> [(String, String, Double)] {
        var significant: [(String, String, Double)] = []
        
        for (key1, inner) in correlations {
            for (key2, value) in inner {
                if key1 != key2 && abs(value) > 0.7 {
                    significant.append((key1, key2, value))
                }
            }
        }
        
        return significant.sorted { abs($0.2) > abs($1.2) }
    }
    
    private func findStrongestCorrelation(_ correlations: [String: [String: Double]]) -> (String, String, Double)? {
        var strongest: (String, String, Double)? = nil
        var maxCorrelation: Double = 0
        
        for (key1, inner) in correlations {
            for (key2, value) in inner {
                if key1 != key2 && abs(value) > maxCorrelation {
                    maxCorrelation = abs(value)
                    strongest = (key1, key2, value)
                }
            }
        }
        
        return strongest
    }
    
    private func findWeakestCorrelation(_ correlations: [String: [String: Double]]) -> (String, String, Double)? {
        var weakest: (String, String, Double)? = nil
        var minCorrelation: Double = 1.0
        
        for (key1, inner) in correlations {
            for (key2, value) in inner {
                if key1 != key2 && abs(value) < minCorrelation {
                    minCorrelation = abs(value)
                    weakest = (key1, key2, value)
                }
            }
        }
        
        return weakest
    }
    
    private func recordProcessingMetrics(operation: String, duration: TimeInterval, dataSize: Int) async {
        processingMetrics.recordOperation(operation: operation, duration: duration, dataSize: dataSize)
        
        await MainActor.run {
            processingEfficiency = min(1.0, max(0.0, 1.0 - (duration / 0.1)))
        }
        
        await advancedMetalOptimizer.recordModelInference(duration: duration)
        
        Logger.debug("Health data processing - \(operation): \(String(format: \"%.3f\", duration))s for \(dataSize) points", log: Logger.performance)
    }
    
    // MARK: - Public API
    
    func getProcessingMetrics() -> HealthProcessingMetrics {
        return processingMetrics
    }
    
    func isMetalAccelerationAvailable() -> Bool {
        return metalDevice != nil && metalCommandQueue != nil
    }
}

// MARK: - Data Models

struct HeartRateAnalysis {
    let averageHeartRate: Double
    let maxHeartRate: Double
    let minHeartRate: Double
    let restingHeartRate: Double
    let heartRateVariability: Double
    let irregularRhythmCount: Int
    let recoveryHeartRate: Double
    let stressIndicator: Double
}

struct HRVAnalysis {
    let rmssd: Double
    let sdnn: Double
    let pnn50: Double
    let triangularIndex: Double
    let stressScore: Double
    let recoveryScore: Double
}

struct SleepAnalysis {
    let totalSleepTime: TimeInterval
    let deepSleepTime: TimeInterval
    let remSleepTime: TimeInterval
    let lightSleepTime: TimeInterval
    let awakeTime: TimeInterval
    let sleepEfficiency: Double
    let sleepQuality: Double
    let restfulnessScore: Double
    let sleepLatency: TimeInterval
    let wakeCount: Int
}

struct SleepDataPoint {
    let timestamp: Date
    let heartRate: Double
    let movement: Double
    let stage: SleepStage
}

struct HealthCorrelationMatrix {
    let correlations: [String: [String: Double]]
    let significantCorrelations: [(String, String, Double)]
    let strongestCorrelation: (String, String, Double)?
    let weakestCorrelation: (String, String, Double)?
}

struct HealthProcessingMetrics {
    private var operationCounts: [String: Int] = [:]
    private var averageDurations: [String: TimeInterval] = [:]
    private var totalDataProcessed: [String: Int] = [:]
    
    mutating func recordOperation(operation: String, duration: TimeInterval, dataSize: Int) {
        operationCounts[operation, default: 0] += 1
        averageDurations[operation] = ((averageDurations[operation] ?? 0) * Double(operationCounts[operation]! - 1) + duration) / Double(operationCounts[operation]!)
        totalDataProcessed[operation, default: 0] += dataSize
    }
    
    func getAverageDuration(for operation: String) -> TimeInterval {
        return averageDurations[operation] ?? 0
    }
    
    func getTotalOperations(for operation: String) -> Int {
        return operationCounts[operation] ?? 0
    }
    
    func getTotalDataProcessed(for operation: String) -> Int {
        return totalDataProcessed[operation] ?? 0
    }
}

enum MetalProcessingError: Error {
    case bufferCreationFailed
    case commandBufferCreationFailed
    case kernelNotFound
    case deviceNotAvailable
}