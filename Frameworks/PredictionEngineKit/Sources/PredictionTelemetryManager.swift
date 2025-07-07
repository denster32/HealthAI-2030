import Foundation
import os.log
import Combine

/// Advanced telemetry and logging manager for health prediction system
public class PredictionTelemetryManager {
    /// Singleton instance
    public static let shared = PredictionTelemetryManager()
    
    /// Logging subsystem
    private let logger = Logger(subsystem: "com.healthai.predictionengine", category: "telemetry")
    
    /// Telemetry event publisher
    private let telemetryPublisher = PassthroughSubject<TelemetryEvent, Never>()
    
    /// Telemetry storage
    private var telemetryStorage: TelemetryStorage
    
    /// Combine cancellables
    private var cancellables = Set<AnyCancellable>()
    
    /// Telemetry event structure
    public struct TelemetryEvent: Codable {
        public let id: UUID
        public let timestamp: Date
        public let eventType: EventType
        public let payload: Payload
        
        public enum EventType: String, Codable {
            case predictionStarted
            case predictionCompleted
            case predictionFailed
            case modelDriftDetected
            case performanceMetrics
        }
        
        public struct Payload: Codable {
            public let inputFeatures: [String: Double]?
            public let outputRiskLevel: String?
            public let errorDescription: String?
            public let performanceMetrics: PerformanceMetrics?
        }
        
        public struct PerformanceMetrics: Codable {
            public let processingTime: TimeInterval
            public let memoryUsage: Int64
            public let cpuUsage: Double
        }
    }
    
    /// Telemetry storage mechanism
    private class TelemetryStorage {
        private let storageQueue = DispatchQueue(label: "com.healthai.telemetryStorage", attributes: .concurrent)
        private var events: [TelemetryEvent] = []
        private let maxStoredEvents = 1000
        
        func store(event: TelemetryEvent) {
            storageQueue.async(flags: .barrier) {
                self.events.append(event)
                
                // Limit storage size
                if self.events.count > self.maxStoredEvents {
                    self.events.removeFirst(self.events.count - self.maxStoredEvents)
                }
            }
        }
        
        func retrieveEvents(since date: Date? = nil) -> [TelemetryEvent] {
            return storageQueue.sync {
                guard let date = date else { return events }
                return events.filter { $0.timestamp > date }
            }
        }
    }
    
    /// Private initializer
    private init() {
        telemetryStorage = TelemetryStorage()
        setupTelemetryPipeline()
    }
    
    /// Setup telemetry processing pipeline
    private func setupTelemetryPipeline() {
        telemetryPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [weak self] event in
                // Store event
                self?.telemetryStorage.store(event: event)
                
                // Log event
                self?.logTelemetryEvent(event)
                
                // Potential additional processing (e.g., remote logging, analytics)
                self?.processRemoteTelemetry(event)
            }
            .store(in: &cancellables)
    }
    
    /// Log telemetry event to system log with memory monitoring
    private func logTelemetryEvent(_ event: TelemetryEvent) {
        // Capture current memory usage
        let memoryUsage = reportMemoryUsage()
        
        switch event.eventType {
        case .predictionStarted:
            logger.info("""
            Prediction Started: \(event.id)
            Memory: \(memoryUsage.used)MB used, \(memoryUsage.available)MB available
            """)
            
        case .predictionCompleted:
            logger.info("""
            Prediction Completed: \(event.id)
            Risk Level: \(event.payload.outputRiskLevel ?? "Unknown")
            Memory: \(memoryUsage.used)MB used
            """)
            
        case .predictionFailed:
            logger.error("""
            Prediction Failed: \(event.id)
            Error: \(event.payload.errorDescription ?? "Unknown Error")
            Memory: \(memoryUsage.used)MB used
            """)
            
        case .modelDriftDetected:
            logger.critical("""
            Model Drift Detected: \(event.id)
            Memory: \(memoryUsage.used)MB used
            """)
            
        case .performanceMetrics:
            if let metrics = event.payload.performanceMetrics {
                logger.debug("""
                Performance Metrics:
                - Processing Time: \(metrics.processingTime)s
                - Memory Usage: \(metrics.memoryUsage) bytes
                - System Memory: \(memoryUsage.used)MB used
                """)
            }
        }
    }
    
    /// Report current memory usage
    private func reportMemoryUsage() -> (used: Int64, available: Int64) {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return (0, 0)
        }
        
        let usedBytes = Int64(taskInfo.resident_size)
        let usedMB = usedBytes / (1024 * 1024)
        
        // Get available memory
        let availableBytes = ProcessInfo.processInfo.physicalMemory
        let availableMB = Int64(availableBytes) / (1024 * 1024)
        
        return (usedMB, availableMB)
    }
    
    /// Process telemetry for potential remote logging or analytics
    private func processRemoteTelemetry(_ event: TelemetryEvent) {
        // Placeholder for remote telemetry processing
        // In a real-world scenario, this might send data to:
        // - Analytics service
        // - Monitoring platform
        // - Custom backend for ML model improvement
    }
    
    /// Public method to record a telemetry event
    public func recordEvent(
        type: TelemetryEvent.EventType,
        inputFeatures: [String: Double]? = nil,
        outputRiskLevel: String? = nil,
        errorDescription: String? = nil,
        performanceMetrics: TelemetryEvent.PerformanceMetrics? = nil
    ) {
        let event = TelemetryEvent(
            id: UUID(),
            timestamp: Date(),
            eventType: type,
            payload: TelemetryEvent.Payload(
                inputFeatures: inputFeatures,
                outputRiskLevel: outputRiskLevel,
                errorDescription: errorDescription,
                performanceMetrics: performanceMetrics
            )
        )
        
        telemetryPublisher.send(event)
    }
    
    /// Retrieve recent telemetry events
    public func getRecentEvents(since date: Date? = nil) -> [TelemetryEvent] {
        return telemetryStorage.retrieveEvents(since: date)
    }
    
    /// Generate a comprehensive telemetry report with analysis
    public func generateTelemetryReport(since date: Date? = nil) -> String {
        let events = getRecentEvents(since: date)
        
        var report = "HealthAI Prediction Telemetry Report\n"
        report += "Generated at: \(Date())\n"
        report += "Time Period: \(date?.description ?? "All Time")\n\n"
        
        // Aggregate statistics
        let completedPredictions = events.filter { $0.eventType == .predictionCompleted }
        let failedPredictions = events.filter { $0.eventType == .predictionFailed }
        let modelDriftEvents = events.filter { $0.eventType == .modelDriftDetected }
        let performanceEvents = events.filter { $0.eventType == .performanceMetrics }
        
        // Calculate success rate
        let totalPredictions = completedPredictions.count + failedPredictions.count
        let successRate = totalPredictions > 0 ?
            Double(completedPredictions.count) / Double(totalPredictions) * 100 : 0
        
        // Calculate average processing time
        let avgProcessingTime = performanceEvents.compactMap {
            $0.payload.performanceMetrics?.processingTime
        }.average()
        
        // Memory analysis
        let memoryUsage = performanceEvents.compactMap {
            $0.payload.performanceMetrics?.memoryUsage
        }
        let avgMemoryUsage = memoryUsage.average()
        let maxMemoryUsage = memoryUsage.max() ?? 0
        
        report += """
        Prediction Statistics:
        - Total Events: \(events.count)
        - Completed Predictions: \(completedPredictions.count)
        - Failed Predictions: \(failedPredictions.count)
        - Success Rate: \(String(format: "%.1f", successRate))%
        - Model Drift Events: \(modelDriftEvents.count)
        
        Performance Metrics:
        - Avg Processing Time: \(String(format: "%.3f", avgProcessingTime ?? 0))s
        - Avg Memory Usage: \(avgMemoryUsage?.formattedByteSize() ?? "N/A")
        - Peak Memory Usage: \(maxMemoryUsage.formattedByteSize())
        
        Potential Issues:
        \(analyzeForIssues(events: events))
        """
        
        return report
    }
    
    /// Analyze telemetry events for potential problems
    private func analyzeForIssues(events: [TelemetryEvent]) -> String {
        var issues: [String] = []
        
        // Check for increasing memory usage
        let memoryTrend = events.compactMap {
            $0.payload.performanceMetrics?.memoryUsage
        }.trendAnalysis()
        
        if memoryTrend.isIncreasing {
            issues.append("- Memory usage shows increasing trend (\(memoryTrend.rateString))")
        }
        
        // Check for frequent failures
        let recentFailures = events.filter {
            $0.eventType == .predictionFailed &&
            $0.timestamp > Date().addingTimeInterval(-3600) // Last hour
        }
        
        if recentFailures.count > 5 {
            issues.append("- High failure rate (\(recentFailures.count) failures in last hour)")
        }
        
        // Check for model drift
        if events.contains(where: { $0.eventType == .modelDriftDetected }) {
            issues.append("- Model drift detected (check recent predictions)")
        }
        
        return issues.isEmpty ? "No significant issues detected" : issues.joined(separator: "\n")
    }
} 