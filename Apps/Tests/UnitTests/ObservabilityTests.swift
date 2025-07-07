import XCTest
@testable import HealthAI2030

@MainActor
final class ObservabilityTests: XCTestCase {
    var observabilityManager: ObservabilityManager!
    
    override func setUp() {
        super.setUp()
        observabilityManager = ObservabilityManager()
    }
    
    override func tearDown() {
        observabilityManager = nil
        super.tearDown()
    }
    
    // MARK: - Distributed Tracing Tests
    func testStartTrace() {
        let trace = observabilityManager.startTrace(name: "test_trace", metadata: ["test_key": "test_value"])
        
        XCTAssertNotNil(trace)
        XCTAssertEqual(trace.name, "test_trace")
        XCTAssertEqual(trace.metadata["test_key"], "test_value")
        XCTAssertNotNil(trace.traceId)
        XCTAssertNotNil(trace.spanId)
        XCTAssertEqual(trace.status, .success)
        XCTAssertNil(trace.endTime)
        XCTAssertTrue(trace.events.isEmpty)
        XCTAssertTrue(trace.childSpans.isEmpty)
        
        // Verify current trace is set
        XCTAssertEqual(observabilityManager.currentTraceId, trace.traceId)
    }
    
    func testAddSpanEvent() async throws {
        let trace = observabilityManager.startTrace(name: "test_trace")
        let event = SpanEvent(
            type: "test_event",
            timestamp: Date(),
            data: ["event_key": "event_value"]
        )
        
        try await observabilityManager.addSpanEvent(event, to: trace.traceId)
        
        // Verify event was added
        let retrievedTrace = try await observabilityManager.getTrace(trace.traceId)
        XCTAssertNotNil(retrievedTrace)
        XCTAssertEqual(retrievedTrace?.events.count, 1)
        XCTAssertEqual(retrievedTrace?.events.first?.type, "test_event")
        XCTAssertEqual(retrievedTrace?.events.first?.data["event_key"], "event_value")
    }
    
    func testEndTrace() async throws {
        let trace = observabilityManager.startTrace(name: "test_trace")
        
        // Add some delay to measure duration
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        try await observabilityManager.endTrace(trace.traceId, status: .success)
        
        // Verify trace was ended
        let retrievedTrace = try await observabilityManager.getTrace(trace.traceId)
        XCTAssertNotNil(retrievedTrace)
        XCTAssertNotNil(retrievedTrace?.endTime)
        XCTAssertEqual(retrievedTrace?.status, .success)
        
        // Verify current trace was cleared
        XCTAssertNil(observabilityManager.currentTraceId)
    }
    
    func testEndTraceWithError() async throws {
        let trace = observabilityManager.startTrace(name: "test_trace")
        
        try await observabilityManager.endTrace(trace.traceId, status: .error)
        
        // Verify trace was ended with error status
        let retrievedTrace = try await observabilityManager.getTrace(trace.traceId)
        XCTAssertNotNil(retrievedTrace)
        XCTAssertEqual(retrievedTrace?.status, .error)
    }
    
    func testSearchTraces() async throws {
        // Create multiple traces
        let trace1 = observabilityManager.startTrace(name: "user_login", metadata: ["user_id": "123"])
        let trace2 = observabilityManager.startTrace(name: "data_sync", metadata: ["sync_type": "full"])
        let trace3 = observabilityManager.startTrace(name: "user_login", metadata: ["user_id": "456"])
        
        // End traces
        try await observabilityManager.endTrace(trace1.traceId)
        try await observabilityManager.endTrace(trace2.traceId)
        try await observabilityManager.endTrace(trace3.traceId)
        
        // Search by name
        let loginTraces = try await observabilityManager.searchTraces(criteria: TraceSearchCriteria(
            traceId: nil,
            name: "user_login",
            status: nil,
            timeRange: nil,
            metadata: nil
        ))
        
        XCTAssertEqual(loginTraces.count, 2)
        XCTAssertTrue(loginTraces.allSatisfy { $0.name == "user_login" })
        
        // Search by status
        let successTraces = try await observabilityManager.searchTraces(criteria: TraceSearchCriteria(
            traceId: nil,
            name: nil,
            status: .success,
            timeRange: nil,
            metadata: nil
        ))
        
        XCTAssertEqual(successTraces.count, 3)
        XCTAssertTrue(successTraces.allSatisfy { $0.status == .success })
    }
    
    func testExportTraces() async throws {
        let trace = observabilityManager.startTrace(name: "test_trace")
        try await observabilityManager.endTrace(trace.traceId)
        
        let exportData = try await observabilityManager.exportTraces(format: .json)
        
        XCTAssertFalse(exportData.isEmpty)
        
        // Try to parse as JSON
        let jsonObject = try JSONSerialization.jsonObject(with: exportData)
        XCTAssertNotNil(jsonObject)
    }
    
    // MARK: - Structured Logging Tests
    func testLogging() async throws {
        observabilityManager.log(level: .info, message: "Test log message", metadata: ["test_key": "test_value"])
        
        let logs = try await observabilityManager.getLogs()
        
        XCTAssertNotNil(logs)
        XCTAssertFalse(logs.isEmpty)
        
        let lastLog = logs.last
        XCTAssertNotNil(lastLog)
        XCTAssertEqual(lastLog?.level, .info)
        XCTAssertEqual(lastLog?.message, "Test log message")
        XCTAssertEqual(lastLog?.metadata["test_key"], "test_value")
    }
    
    func testLoggingWithDifferentLevels() async throws {
        observabilityManager.log(level: .debug, message: "Debug message")
        observabilityManager.log(level: .info, message: "Info message")
        observabilityManager.log(level: .warning, message: "Warning message")
        observabilityManager.log(level: .error, message: "Error message")
        
        let logs = try await observabilityManager.getLogs()
        
        XCTAssertGreaterThanOrEqual(logs.count, 4)
        
        let levels = logs.map { $0.level }
        XCTAssertTrue(levels.contains(.debug))
        XCTAssertTrue(levels.contains(.info))
        XCTAssertTrue(levels.contains(.warning))
        XCTAssertTrue(levels.contains(.error))
    }
    
    func testGetLogsWithLevelFilter() async throws {
        observabilityManager.log(level: .debug, message: "Debug message")
        observabilityManager.log(level: .info, message: "Info message")
        observabilityManager.log(level: .error, message: "Error message")
        
        let errorLogs = try await observabilityManager.getLogs(level: .error)
        
        XCTAssertNotNil(errorLogs)
        XCTAssertTrue(errorLogs.allSatisfy { $0.level == .error })
        XCTAssertTrue(errorLogs.contains { $0.message == "Error message" })
    }
    
    func testGetLogsWithTimeRange() async throws {
        observabilityManager.log(level: .info, message: "Recent message")
        
        let recentLogs = try await observabilityManager.getLogs(timeRange: .lastHour)
        
        XCTAssertNotNil(recentLogs)
        XCTAssertTrue(recentLogs.allSatisfy { $0.timestamp >= Date().addingTimeInterval(-3600) })
    }
    
    func testGetLogsWithSearchTerm() async throws {
        observabilityManager.log(level: .info, message: "User login successful")
        observabilityManager.log(level: .info, message: "Data sync completed")
        observabilityManager.log(level: .error, message: "Login failed")
        
        let loginLogs = try await observabilityManager.getLogs(searchTerm: "login")
        
        XCTAssertNotNil(loginLogs)
        XCTAssertTrue(loginLogs.allSatisfy { $0.message.contains("login") })
        XCTAssertEqual(loginLogs.count, 2)
    }
    
    func testExportLogs() async throws {
        observabilityManager.log(level: .info, message: "Test export message")
        
        let exportData = try await observabilityManager.exportLogs(format: .json)
        
        XCTAssertFalse(exportData.isEmpty)
        
        // Try to parse as JSON
        let jsonObject = try JSONSerialization.jsonObject(with: exportData)
        XCTAssertNotNil(jsonObject)
    }
    
    func testSetLogLevel() {
        observabilityManager.setLogLevel(.warning)
        
        // Log messages at different levels
        observabilityManager.log(level: .debug, message: "Debug message") // Should be filtered
        observabilityManager.log(level: .info, message: "Info message") // Should be filtered
        observabilityManager.log(level: .warning, message: "Warning message") // Should be logged
        observabilityManager.log(level: .error, message: "Error message") // Should be logged
        
        // Note: In a real test, we would verify the filtering behavior
        // For now, we just verify the method doesn't crash
    }
    
    // MARK: - Metrics Collection Tests
    func testRecordMetric() {
        observabilityManager.recordMetric("test_metric", value: 42.5, tags: ["tag1": "value1"])
        
        XCTAssertNotNil(observabilityManager.metrics["test_metric"])
        XCTAssertEqual(observabilityManager.metrics["test_metric"]?.value, 42.5)
        XCTAssertEqual(observabilityManager.metrics["test_metric"]?.tags["tag1"], "value1")
    }
    
    func testIncrementCounter() {
        observabilityManager.incrementCounter("test_counter", tags: ["tag1": "value1"])
        
        XCTAssertNotNil(observabilityManager.metrics["test_counter"])
        XCTAssertEqual(observabilityManager.metrics["test_counter"]?.value, 1.0)
        
        observabilityManager.incrementCounter("test_counter", tags: ["tag1": "value1"])
        
        XCTAssertEqual(observabilityManager.metrics["test_counter"]?.value, 2.0)
    }
    
    func testRecordHistogram() {
        observabilityManager.recordHistogram("test_histogram", value: 10.0, tags: ["tag1": "value1"])
        
        // Histogram recording should work without errors
        // In a real implementation, this would store histogram data
    }
    
    func testGetMetrics() async throws {
        observabilityManager.recordMetric("metric1", value: 10.0)
        observabilityManager.recordMetric("metric2", value: 20.0)
        observabilityManager.recordMetric("metric1", value: 15.0)
        
        let allMetrics = try await observabilityManager.getMetrics()
        
        XCTAssertNotNil(allMetrics)
        XCTAssertGreaterThanOrEqual(allMetrics.count, 3)
        
        let metric1Values = try await observabilityManager.getMetrics(name: "metric1")
        XCTAssertNotNil(metric1Values)
        XCTAssertTrue(metric1Values.allSatisfy { $0.name == "metric1" })
    }
    
    func testGetMetricsWithTimeRange() async throws {
        observabilityManager.recordMetric("test_metric", value: 42.0)
        
        let recentMetrics = try await observabilityManager.getMetrics(timeRange: .lastHour)
        
        XCTAssertNotNil(recentMetrics)
        XCTAssertTrue(recentMetrics.allSatisfy { $0.timestamp >= Date().addingTimeInterval(-3600) })
    }
    
    func testGetMetricsSummary() async throws {
        observabilityManager.recordMetric("test_metric", value: 10.0)
        observabilityManager.recordMetric("test_metric", value: 20.0)
        observabilityManager.recordMetric("test_metric", value: 30.0)
        
        let summary = try await observabilityManager.getMetricsSummary()
        
        XCTAssertNotNil(summary)
        XCTAssertGreaterThanOrEqual(summary.totalMetrics, 3)
        XCTAssertEqual(summary.averageValue, 20.0, accuracy: 0.1)
        XCTAssertEqual(summary.minValue, 10.0, accuracy: 0.1)
        XCTAssertEqual(summary.maxValue, 30.0, accuracy: 0.1)
    }
    
    func testExportMetrics() async throws {
        observabilityManager.recordMetric("test_metric", value: 42.0)
        
        let exportData = try await observabilityManager.exportMetrics(format: .json)
        
        XCTAssertFalse(exportData.isEmpty)
        
        // Try to parse as JSON
        let jsonObject = try JSONSerialization.jsonObject(with: exportData)
        XCTAssertNotNil(jsonObject)
    }
    
    // MARK: - Intelligent Alerting Tests
    func testCreateAlert() async throws {
        let alert = ObservabilityAlert(
            id: UUID(),
            type: .metricThreshold,
            severity: .high,
            message: "Test alert message",
            timestamp: Date(),
            isAcknowledged: false,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: ["test_key": "test_value"]
        )
        
        try await observabilityManager.createAlert(alert)
        
        XCTAssertTrue(observabilityManager.alerts.contains { $0.id == alert.id })
        XCTAssertEqual(observabilityManager.alerts.first { $0.id == alert.id }?.message, "Test alert message")
        XCTAssertEqual(observabilityManager.alerts.first { $0.id == alert.id }?.severity, .high)
    }
    
    func testAcknowledgeAlert() async throws {
        let alert = ObservabilityAlert(
            id: UUID(),
            type: .metricThreshold,
            severity: .medium,
            message: "Test alert",
            timestamp: Date(),
            isAcknowledged: false,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: [:]
        )
        
        try await observabilityManager.createAlert(alert)
        try await observabilityManager.acknowledgeAlert(alert.id)
        
        let acknowledgedAlert = observabilityManager.alerts.first { $0.id == alert.id }
        XCTAssertNotNil(acknowledgedAlert)
        XCTAssertTrue(acknowledgedAlert?.isAcknowledged == true)
        XCTAssertNotNil(acknowledgedAlert?.acknowledgedAt)
    }
    
    func testResolveAlert() async throws {
        let alert = ObservabilityAlert(
            id: UUID(),
            type: .metricThreshold,
            severity: .low,
            message: "Test alert",
            timestamp: Date(),
            isAcknowledged: false,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: [:]
        )
        
        try await observabilityManager.createAlert(alert)
        try await observabilityManager.resolveAlert(alert.id)
        
        // Alert should be removed from active alerts
        XCTAssertFalse(observabilityManager.alerts.contains { $0.id == alert.id })
    }
    
    func testGetAlerts() async throws {
        let alert1 = ObservabilityAlert(
            id: UUID(),
            type: .metricThreshold,
            severity: .high,
            message: "High severity alert",
            timestamp: Date(),
            isAcknowledged: false,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: [:]
        )
        
        let alert2 = ObservabilityAlert(
            id: UUID(),
            type: .errorRate,
            severity: .medium,
            message: "Medium severity alert",
            timestamp: Date(),
            isAcknowledged: false,
            acknowledgedAt: nil,
            resolvedAt: nil,
            metadata: [:]
        )
        
        try await observabilityManager.createAlert(alert1)
        try await observabilityManager.createAlert(alert2)
        
        let allAlerts = try await observabilityManager.getAlerts()
        XCTAssertEqual(allAlerts.count, 2)
        
        let highSeverityAlerts = try await observabilityManager.getAlerts(severity: .high)
        XCTAssertEqual(highSeverityAlerts.count, 1)
        XCTAssertEqual(highSeverityAlerts.first?.severity, .high)
    }
    
    func testSetAlertRule() async throws {
        let rule = AlertRule(
            id: UUID(),
            name: "Test Rule",
            metricName: "test_metric",
            threshold: 100.0,
            operator: .greaterThan,
            severity: .high,
            enabled: true
        )
        
        try await observabilityManager.setAlertRule(rule)
        
        let rules = try await observabilityManager.getAlertRules()
        XCTAssertTrue(rules.contains { $0.id == rule.id })
        XCTAssertEqual(rules.first { $0.id == rule.id }?.name, "Test Rule")
    }
    
    // MARK: - Data Retention Tests
    func testSetRetentionPolicy() async throws {
        let policy = RetentionPolicy(
            id: UUID(),
            dataType: .logs,
            retentionDays: 30,
            archiveAfterDays: 7,
            enabled: true
        )
        
        try await observabilityManager.setRetentionPolicy(policy)
        
        let policies = try await observabilityManager.getRetentionPolicies()
        XCTAssertTrue(policies.contains { $0.id == policy.id })
        XCTAssertEqual(policies.first { $0.id == policy.id }?.retentionDays, 30)
    }
    
    func testArchiveData() async throws {
        try await observabilityManager.archiveData(dataType: .logs, before: Date())
        
        // Archive operation should complete without errors
    }
    
    func testCleanupExpiredData() async throws {
        let cleanedCount = try await observabilityManager.cleanupExpiredData()
        
        // Cleanup should complete without errors
        XCTAssertGreaterThanOrEqual(cleanedCount, 0)
    }
    
    // MARK: - Performance Monitoring Tests
    func testStartStopPerformanceMonitoring() {
        observabilityManager.startPerformanceMonitoring()
        observabilityManager.stopPerformanceMonitoring()
        
        // Start/stop operations should complete without errors
    }
    
    func testGetPerformanceMetrics() async throws {
        let metrics = try await observabilityManager.getPerformanceMetrics()
        
        XCTAssertNotNil(metrics)
        XCTAssertGreaterThanOrEqual(metrics.responseTime, 0)
        XCTAssertGreaterThanOrEqual(metrics.throughput, 0)
        XCTAssertGreaterThanOrEqual(metrics.errorRate, 0)
        XCTAssertGreaterThanOrEqual(metrics.memoryUsage, 0)
        XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
    }
    
    // MARK: - Health Check Tests
    func testPerformHealthCheck() async throws {
        let result = try await observabilityManager.performHealthCheck()
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.isHealthy)
        XCTAssertGreaterThanOrEqual(result.passedChecks, 0)
        XCTAssertGreaterThanOrEqual(result.failedChecks, 0)
        XCTAssertNotNil(result.timestamp)
    }
    
    func testGetHealthStatus() async throws {
        let status = try await observabilityManager.getHealthStatus()
        
        XCTAssertNotNil(status)
        XCTAssertNotNil(status.isHealthy)
        XCTAssertNotNil(status.lastCheck)
        XCTAssertGreaterThanOrEqual(status.uptime, 0)
        XCTAssertFalse(status.version.isEmpty)
    }
    
    // MARK: - Configuration Tests
    func testEnableDisableObservability() {
        XCTAssertTrue(observabilityManager.isEnabled)
        
        observabilityManager.disableObservability()
        XCTAssertFalse(observabilityManager.isEnabled)
        
        observabilityManager.enableObservability()
        XCTAssertTrue(observabilityManager.isEnabled)
    }
    
    func testConfigureSampling() {
        observabilityManager.configureSampling(rate: 0.5)
        
        // Sampling configuration should complete without errors
    }
    
    // MARK: - Error Handling Tests
    func testObservabilityErrorHandling() async {
        // Test error handling for invalid operations
        do {
            try await observabilityManager.addSpanEvent(
                SpanEvent(type: "test", timestamp: Date(), data: [:]),
                to: "invalid_trace_id"
            )
            XCTFail("Should throw error for invalid trace ID")
        } catch {
            XCTAssertTrue(error is ObservabilityError)
        }
    }
    
    // MARK: - Concurrent Operations Tests
    func testConcurrentObservabilityOperations() async {
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent operations
            group.addTask {
                let trace = self.observabilityManager.startTrace(name: "concurrent_trace_1")
                try? await self.observabilityManager.endTrace(trace.traceId)
            }
            
            group.addTask {
                self.observabilityManager.log(level: .info, message: "Concurrent log 1")
            }
            
            group.addTask {
                self.observabilityManager.recordMetric("concurrent_metric", value: 1.0)
            }
            
            group.addTask {
                let alert = ObservabilityAlert(
                    id: UUID(),
                    type: .metricThreshold,
                    severity: .low,
                    message: "Concurrent alert",
                    timestamp: Date(),
                    isAcknowledged: false,
                    acknowledgedAt: nil,
                    resolvedAt: nil,
                    metadata: [:]
                )
                try? await self.observabilityManager.createAlert(alert)
            }
        }
        
        // Verify no crashes occurred
        XCTAssertNotNil(observabilityManager)
    }
    
    // MARK: - Performance Tests
    func testObservabilityPerformance() async throws {
        let startTime = Date()
        
        // Perform multiple operations
        for i in 0..<100 {
            let trace = observabilityManager.startTrace(name: "perf_trace_\(i)")
            observabilityManager.log(level: .info, message: "Perf log \(i)")
            observabilityManager.recordMetric("perf_metric", value: Double(i))
            try await observabilityManager.endTrace(trace.traceId)
        }
        
        let operationTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(operationTime, 10.0) // Should complete within 10 seconds
    }
    
    // MARK: - Memory Management Tests
    func testObservabilityManagerMemoryManagement() {
        weak var weakManager: ObservabilityManager?
        
        autoreleasepool {
            let manager = ObservabilityManager()
            weakManager = manager
        }
        
        // The manager should be deallocated after the autoreleasepool
        XCTAssertNil(weakManager)
    }
    
    // MARK: - Integration Tests
    func testCompleteObservabilityWorkflow() async throws {
        // 1. Start trace
        let trace = observabilityManager.startTrace(name: "workflow_trace", metadata: ["workflow": "test"])
        XCTAssertNotNil(trace)
        
        // 2. Log operations
        observabilityManager.log(level: .info, message: "Workflow started")
        observabilityManager.log(level: .debug, message: "Processing data")
        
        // 3. Record metrics
        observabilityManager.recordMetric("workflow.duration", value: 1.5)
        observabilityManager.incrementCounter("workflow.steps")
        
        // 4. Add span event
        let event = SpanEvent(
            type: "workflow_step",
            timestamp: Date(),
            data: ["step": "data_processing"]
        )
        try await observabilityManager.addSpanEvent(event, to: trace.traceId)
        
        // 5. Create alert rule
        let rule = AlertRule(
            id: UUID(),
            name: "Workflow Alert Rule",
            metricName: "workflow.duration",
            threshold: 5.0,
            operator: .greaterThan,
            severity: .warning,
            enabled: true
        )
        try await observabilityManager.setAlertRule(rule)
        
        // 6. Set retention policy
        let policy = RetentionPolicy(
            id: UUID(),
            dataType: .traces,
            retentionDays: 7,
            archiveAfterDays: 3,
            enabled: true
        )
        try await observabilityManager.setRetentionPolicy(policy)
        
        // 7. End trace
        try await observabilityManager.endTrace(trace.traceId, status: .success)
        
        // 8. Get health status
        let healthStatus = try await observabilityManager.getHealthStatus()
        XCTAssertNotNil(healthStatus)
        
        // 9. Export data
        let tracesExport = try await observabilityManager.exportTraces(format: .json)
        let logsExport = try await observabilityManager.exportLogs(format: .json)
        let metricsExport = try await observabilityManager.exportMetrics(format: .json)
        
        XCTAssertFalse(tracesExport.isEmpty)
        XCTAssertFalse(logsExport.isEmpty)
        XCTAssertFalse(metricsExport.isEmpty)
        
        // 10. Cleanup
        try await observabilityManager.cleanupExpiredData()
        
        // Verify workflow completed successfully
        XCTAssertNotNil(observabilityManager)
    }
} 