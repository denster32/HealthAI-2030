import Foundation
import SwiftUI

/// Comprehensive Usage Examples for Advanced Performance Monitor
/// Demonstrates all features and capabilities of the HealthAI 2030 Performance Monitoring System
public struct PerformanceMonitorExamples {
    
    // MARK: - Basic Usage Examples
    
    /// Basic monitoring example - start monitoring and collect metrics
    public static func demonstrateBasicMonitoring() async {
        print("🚀 Performance Monitor Basic Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 2.0)
            print("✅ Monitoring started successfully")
            
            // Monitor for 10 seconds
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                print("📊 Update \(i):")
                print("   CPU Usage: \(String(format: "%.1f", monitor.currentMetrics.cpu.usage))%")
                print("   Memory Usage: \(String(format: "%.1f", Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100))%")
                print("   Network Latency: \(String(format: "%.1f", monitor.currentMetrics.network.latency))ms")
                print("   Battery Level: \(String(format: "%.1f", monitor.currentMetrics.battery.batteryLevel * 100))%")
                
                // Check for anomalies
                if !monitor.anomalyAlerts.isEmpty {
                    print("⚠️  Anomalies detected: \(monitor.anomalyAlerts.count)")
                    for alert in monitor.anomalyAlerts.prefix(3) {
                        print("   - \(alert.severity.rawValue): \(alert.metric) = \(String(format: "%.1f", alert.value))")
                    }
                }
                
                // Check for recommendations
                if !monitor.optimizationRecommendations.isEmpty {
                    print("💡 Recommendations: \(monitor.optimizationRecommendations.count)")
                    for recommendation in monitor.optimizationRecommendations.prefix(2) {
                        print("   - \(recommendation.priority.rawValue): \(recommendation.title)")
                    }
                }
                
                print("---")
            }
            
            // Stop monitoring
            monitor.stopMonitoring()
            print("✅ Performance monitoring stopped")
            
        } catch {
            print("❌ Monitoring failed: \(error.localizedDescription)")
        }
    }
    
    static func demonstrateAnomalyDetection() async {
        print("\n🔍 Performance Monitor Anomaly Detection Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Monitoring started - watching for anomalies...")
            
            // Monitor for anomalies
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                let criticalAlerts = monitor.anomalyAlerts.filter { $0.severity == .critical }
                let highAlerts = monitor.anomalyAlerts.filter { $0.severity == .high }
                let mediumAlerts = monitor.anomalyAlerts.filter { $0.severity == .medium }
                
                if !criticalAlerts.isEmpty || !highAlerts.isEmpty {
                    print("🚨 Performance Issues Detected (Update \(i)):")
                    
                    for alert in criticalAlerts {
                        print("   🔴 CRITICAL: \(alert.metric) = \(String(format: "%.1f", alert.value)) (threshold: \(String(format: "%.1f", alert.threshold)))")
                        print("      Description: \(alert.description)")
                        print("      Recommendation: \(alert.recommendation)")
                    }
                    
                    for alert in highAlerts {
                        print("   🟠 HIGH: \(alert.metric) = \(String(format: "%.1f", alert.value)) (threshold: \(String(format: "%.1f", alert.threshold)))")
                        print("      Description: \(alert.description)")
                    }
                    
                    for alert in mediumAlerts.prefix(2) {
                        print("   🟡 MEDIUM: \(alert.metric) = \(String(format: "%.1f", alert.value))")
                    }
                }
            }
            
            monitor.stopMonitoring()
            print("✅ Anomaly detection demo completed")
            
        } catch {
            print("❌ Anomaly detection failed: \(error.localizedDescription)")
        }
    }
    
    static func demonstrateTrendAnalysis() async {
        print("\n📈 Performance Monitor Trend Analysis Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Monitoring started - analyzing trends...")
            
            // Collect data for trend analysis
            for i in 1...15 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                if i % 5 == 0 {
                    print("📊 Trend Analysis Update \(i/5):")
                    
                    for trend in monitor.performanceTrends {
                        print("   📈 \(trend.metric):")
                        print("      Trend: \(trend.trend.rawValue)")
                        print("      Confidence: \(String(format: "%.1f", trend.confidence))%")
                        
                        if !trend.forecast.isEmpty {
                            let nextForecast = trend.forecast.first ?? 0
                            print("      Next Forecast: \(String(format: "%.1f", nextForecast))")
                        }
                        
                        // Show recent values
                        let recentValues = Array(trend.values.suffix(5))
                        if !recentValues.isEmpty {
                            let avg = recentValues.reduce(0, +) / Double(recentValues.count)
                            print("      Recent Average: \(String(format: "%.1f", avg))")
                        }
                    }
                    print("---")
                }
            }
            
            monitor.stopMonitoring()
            print("✅ Trend analysis demo completed")
            
        } catch {
            print("❌ Trend analysis failed: \(error.localizedDescription)")
        }
    }
    
    static func demonstrateOptimizationRecommendations() async {
        print("\n⚡ Performance Monitor Optimization Recommendations Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Monitoring started - generating recommendations...")
            
            // Monitor for recommendations
            for i in 1...8 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                if i % 4 == 0 {
                    print("💡 Optimization Recommendations Update \(i/4):")
                    
                    let criticalRecs = monitor.optimizationRecommendations.filter { $0.priority == .critical }
                    let highRecs = monitor.optimizationRecommendations.filter { $0.priority == .high }
                    let mediumRecs = monitor.optimizationRecommendations.filter { $0.priority == .medium }
                    
                    if !criticalRecs.isEmpty {
                        print("   🔴 CRITICAL Recommendations:")
                        for rec in criticalRecs.prefix(2) {
                            print("      • \(rec.title)")
                            print("        Impact: \(rec.impact)")
                            print("        Effort: \(rec.effort)")
                            print("        Estimated Savings: \(String(format: "%.1f", rec.estimatedSavings))%")
                        }
                    }
                    
                    if !highRecs.isEmpty {
                        print("   🟠 HIGH Priority Recommendations:")
                        for rec in highRecs.prefix(2) {
                            print("      • \(rec.title)")
                            print("        Impact: \(rec.impact)")
                            print("        Effort: \(rec.effort)")
                        }
                    }
                    
                    if !mediumRecs.isEmpty {
                        print("   🟡 MEDIUM Priority Recommendations:")
                        for rec in mediumRecs.prefix(1) {
                            print("      • \(rec.title)")
                        }
                    }
                    
                    print("---")
                }
            }
            
            monitor.stopMonitoring()
            print("✅ Optimization recommendations demo completed")
            
        } catch {
            print("❌ Optimization recommendations failed: \(error.localizedDescription)")
        }
    }
    
    static func demonstrateDashboardUsage() async {
        print("\n📊 Performance Monitor Dashboard Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 2.0)
            print("✅ Monitoring started - building dashboard...")
            
            // Wait for dashboard data
            try await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
            
            let dashboard = monitor.getPerformanceDashboard()
            
            print("🎯 Performance Dashboard:")
            print("   Overall Health: \(dashboard.systemOverview.overallHealth.rawValue)")
            print("   CPU Health: \(dashboard.systemOverview.cpuHealth.rawValue)")
            print("   Memory Health: \(dashboard.systemOverview.memoryHealth.rawValue)")
            print("   Network Health: \(dashboard.systemOverview.networkHealth.rawValue)")
            print("   Battery Health: \(dashboard.systemOverview.batteryHealth.rawValue)")
            print("   Last Updated: \(dashboard.systemOverview.lastUpdated)")
            
            print("\n📈 Metric Charts:")
            for chart in dashboard.metricCharts {
                print("   • \(chart.title): \(String(format: "%.1f", chart.currentValue)) (\(chart.trend.rawValue))")
            }
            
            print("\n⚠️  Active Alerts: \(dashboard.anomalyAlerts.count)")
            for alert in dashboard.anomalyAlerts.prefix(3) {
                print("   • \(alert.severity.rawValue) - \(alert.metric): \(String(format: "%.1f", alert.value))")
            }
            
            print("\n💡 Recommendations: \(dashboard.optimizationRecommendations.count)")
            for rec in dashboard.optimizationRecommendations.prefix(3) {
                print("   • \(rec.priority.rawValue) - \(rec.title)")
            }
            
            print("\n📋 Performance Summary:")
            print("   Overall Score: \(String(format: "%.1f", dashboard.performanceSummary.overallScore))")
            print("   Top Issues: \(dashboard.performanceSummary.topIssues.count)")
            for issue in dashboard.performanceSummary.topIssues.prefix(3) {
                print("     - \(issue)")
            }
            print("   Quick Recommendations: \(dashboard.performanceSummary.recommendations.count)")
            for rec in dashboard.performanceSummary.recommendations.prefix(2) {
                print("     - \(rec)")
            }
            
            monitor.stopMonitoring()
            print("\n✅ Dashboard demo completed")
            
        } catch {
            print("❌ Dashboard demo failed: \(error.localizedDescription)")
        }
    }
    
    static func demonstrateRealWorldScenario() async {
        print("\n🌍 Performance Monitor Real-World Scenario Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Monitoring started - simulating real-world scenario...")
            
            // Phase 1: Normal operation
            print("📱 Phase 1: Normal Operation (5 seconds)")
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            // Phase 2: Simulate high CPU load
            print("🔥 Phase 2: High CPU Load (5 seconds)")
            let cpuTasks = (0..<5).map { _ in
                Task {
                    for _ in 0..<1000000 {
                        _ = sqrt(Double.random(in: 1...1000))
                    }
                }
            }
            
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            // Phase 3: Simulate memory pressure
            print("💾 Phase 3: Memory Pressure (5 seconds)")
            var memoryBlocks: [Data] = []
            for i in 0..<20 {
                memoryBlocks.append(Data(count: 1024 * 1024)) // 1MB blocks
                try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
            }
            
            // Phase 4: Recovery
            print("🔄 Phase 4: Recovery (5 seconds)")
            memoryBlocks.removeAll()
            try await Task.sleep(nanoseconds: 5_000_000_000)
            
            // Final analysis
            print("📊 Final Analysis:")
            let dashboard = monitor.getPerformanceDashboard()
            print("   Final Health: \(dashboard.systemOverview.overallHealth.rawValue)")
            print("   Total Anomalies Detected: \(monitor.anomalyAlerts.count)")
            print("   Total Recommendations Generated: \(monitor.optimizationRecommendations.count)")
            print("   Performance Trends Analyzed: \(monitor.performanceTrends.count)")
            
            // Show critical findings
            let criticalAlerts = monitor.anomalyAlerts.filter { $0.severity == .critical }
            if !criticalAlerts.isEmpty {
                print("\n🚨 Critical Issues Found:")
                for alert in criticalAlerts {
                    print("   • \(alert.metric): \(alert.description)")
                }
            }
            
            let criticalRecs = monitor.optimizationRecommendations.filter { $0.priority == .critical }
            if !criticalRecs.isEmpty {
                print("\n⚡ Critical Recommendations:")
                for rec in criticalRecs {
                    print("   • \(rec.title)")
                    print("     \(rec.description)")
                }
            }
            
            monitor.stopMonitoring()
            print("\n✅ Real-world scenario demo completed")
            
        } catch {
            print("❌ Real-world scenario failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Advanced Usage Examples
    
    /// Comprehensive system monitoring with all metrics
    public static func demonstrateComprehensiveMonitoring() async {
        print("\n🔬 Comprehensive Performance Monitor Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 2.0)
            print("✅ Comprehensive monitoring started...")
            
            for i in 1...5 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                print("📊 Comprehensive Update \(i):")
                
                // CPU Metrics
                print("   🔥 CPU:")
                print("      Usage: \(String(format: "%.1f", monitor.currentMetrics.cpu.usage))%")
                print("      Temperature: \(String(format: "%.1f", monitor.currentMetrics.cpu.temperature))°C")
                print("      Efficiency: \(String(format: "%.1f", monitor.currentMetrics.cpu.efficiency))%")
                
                // Memory Metrics
                print("   💾 Memory:")
                let memUsage = Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100
                print("      Usage: \(String(format: "%.1f", memUsage))%")
                print("      Pressure: \(monitor.currentMetrics.memory.pressure.rawValue)")
                print("      Swap: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.memory.swapUsage), countStyle: .memory))")
                
                // Network Metrics
                print("   🌐 Network:")
                print("      Latency: \(String(format: "%.1f", monitor.currentMetrics.network.latency))ms")
                print("      Throughput: \(String(format: "%.1f", monitor.currentMetrics.network.throughput)) Mbps")
                print("      Connections: \(monitor.currentMetrics.network.connectionCount)")
                
                // Disk Metrics
                print("   💿 Disk:")
                let diskUsage = Double(monitor.currentMetrics.disk.usedSpace) / Double(monitor.currentMetrics.disk.totalSpace) * 100
                print("      Usage: \(String(format: "%.1f", diskUsage))%")
                print("      Read Speed: \(String(format: "%.1f", monitor.currentMetrics.disk.readSpeed)) MB/s")
                print("      Write Speed: \(String(format: "%.1f", monitor.currentMetrics.disk.writeSpeed)) MB/s")
                
                // Application Metrics
                print("   📱 Application:")
                print("      Launch Time: \(String(format: "%.2f", monitor.currentMetrics.application.launchTime))s")
                print("      Response Time: \(String(format: "%.3f", monitor.currentMetrics.application.responseTime))s")
                print("      Frame Rate: \(String(format: "%.1f", monitor.currentMetrics.application.frameRate)) fps")
                
                // UI Metrics
                print("   🎨 UI:")
                print("      Render Time: \(String(format: "%.2f", monitor.currentMetrics.ui.renderTime))ms")
                print("      Touch Latency: \(String(format: "%.1f", monitor.currentMetrics.ui.touchLatency))ms")
                print("      Hierarchy Depth: \(monitor.currentMetrics.ui.viewHierarchyDepth)")
                
                // Battery Metrics
                print("   🔋 Battery:")
                print("      Level: \(String(format: "%.1f", monitor.currentMetrics.battery.batteryLevel * 100))%")
                print("      State: \(monitor.currentMetrics.battery.batteryState)")
                print("      Power: \(String(format: "%.1f", monitor.currentMetrics.battery.powerConsumption))W")
                
                // ML Metrics
                print("   🤖 Machine Learning:")
                print("      Inference Time: \(String(format: "%.3f", monitor.currentMetrics.ml.inferenceTime))s")
                print("      Model Size: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.ml.modelSize), countStyle: .memory))")
                print("      Neural Engine: \(String(format: "%.1f", monitor.currentMetrics.ml.neuralEngineUsage))%")
                
                // Database Metrics
                print("   🗄️ Database:")
                print("      Query Time: \(String(format: "%.3f", monitor.currentMetrics.database.queryTime))s")
                print("      Cache Hit Rate: \(String(format: "%.1f", monitor.currentMetrics.database.cacheHitRate))%")
                print("      Storage: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.database.storageSize), countStyle: .memory))")
                
                // Security Metrics
                print("   🔒 Security:")
                print("      Encryption Overhead: \(String(format: "%.1f", monitor.currentMetrics.security.encryptionOverhead))%")
                print("      Auth Time: \(String(format: "%.3f", monitor.currentMetrics.security.authenticationTime))s")
                print("      Secure Connections: \(monitor.currentMetrics.security.secureConnections)")
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ Comprehensive monitoring completed")
            
        } catch {
            print("❌ Comprehensive monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Memory pressure simulation and monitoring
    public static func demonstrateMemoryPressureMonitoring() async {
        print("\n💾 Memory Pressure Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 0.5)
            print("✅ Memory pressure monitoring started...")
            
            var memoryBlocks: [Data] = []
            
            // Gradually increase memory usage
            for i in 1...20 {
                // Allocate 5MB blocks
                let blockSize = 5 * 1024 * 1024
                memoryBlocks.append(Data(count: blockSize))
                
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                let memUsage = Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100
                
                print("📊 Memory Block \(i):")
                print("   Allocated: \(ByteCountFormatter.string(fromByteCount: Int64(memoryBlocks.count * blockSize), countStyle: .memory))")
                print("   Total Usage: \(String(format: "%.1f", memUsage))%")
                print("   Pressure: \(monitor.currentMetrics.memory.pressure.rawValue)")
                
                // Check for memory alerts
                let memoryAlerts = monitor.anomalyAlerts.filter { $0.category == .memory }
                if !memoryAlerts.isEmpty {
                    print("   ⚠️  Memory Alerts:")
                    for alert in memoryAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for memory recommendations
                let memoryRecs = monitor.optimizationRecommendations.filter { $0.category == .memory }
                if !memoryRecs.isEmpty {
                    print("   💡 Memory Recommendations:")
                    for rec in memoryRecs.prefix(1) {
                        print("      - \(rec.title)")
                    }
                }
                
                // Break if critical memory pressure
                if monitor.currentMetrics.memory.pressure == .critical {
                    print("   🚨 Critical memory pressure reached!")
                    break
                }
            }
            
            // Release memory gradually
            print("\n🔄 Releasing memory...")
            while !memoryBlocks.isEmpty {
                memoryBlocks.removeLast()
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                
                let memUsage = Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100
                print("   Released block - Usage: \(String(format: "%.1f", memUsage))%")
            }
            
            monitor.stopMonitoring()
            print("✅ Memory pressure monitoring completed")
            
        } catch {
            print("❌ Memory pressure monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Network performance monitoring
    public static func demonstrateNetworkPerformanceMonitoring() async {
        print("\n🌐 Network Performance Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Network performance monitoring started...")
            
            // Simulate network activity
            for i in 1...10 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                print("📊 Network Update \(i):")
                print("   Latency: \(String(format: "%.1f", monitor.currentMetrics.network.latency))ms")
                print("   Throughput: \(String(format: "%.1f", monitor.currentMetrics.network.throughput)) Mbps")
                print("   Bytes Received: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.network.bytesReceived), countStyle: .memory))")
                print("   Bytes Sent: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.network.bytesSent), countStyle: .memory))")
                print("   Active Connections: \(monitor.currentMetrics.network.connectionCount)")
                print("   Error Rate: \(String(format: "%.2f", monitor.currentMetrics.network.errorRate))%")
                
                // Check for network alerts
                let networkAlerts = monitor.anomalyAlerts.filter { $0.category == .network }
                if !networkAlerts.isEmpty {
                    print("   ⚠️  Network Alerts:")
                    for alert in networkAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for network optimization recommendations
                let networkRecs = monitor.optimizationRecommendations.filter { $0.category == .network }
                if !networkRecs.isEmpty {
                    print("   💡 Network Recommendations:")
                    for rec in networkRecs.prefix(1) {
                        print("      - \(rec.title) (Savings: \(String(format: "%.1f", rec.estimatedSavings))%)")
                    }
                }
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ Network performance monitoring completed")
            
        } catch {
            print("❌ Network performance monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Battery and power monitoring
    public static func demonstrateBatteryMonitoring() async {
        print("\n🔋 Battery and Power Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 2.0)
            print("✅ Battery monitoring started...")
            
            for i in 1...8 {
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                print("📊 Battery Update \(i):")
                print("   Level: \(String(format: "%.1f", monitor.currentMetrics.battery.batteryLevel * 100))%")
                print("   State: \(monitor.currentMetrics.battery.batteryState)")
                print("   Power Consumption: \(String(format: "%.1f", monitor.currentMetrics.battery.powerConsumption))W")
                print("   Thermal State: \(monitor.currentMetrics.battery.thermalState)")
                print("   Charging Rate: \(String(format: "%.1f", monitor.currentMetrics.battery.chargingRate))W")
                print("   Battery Health: \(String(format: "%.1f", monitor.currentMetrics.battery.batteryHealth))%")
                
                // Check for battery alerts
                let batteryAlerts = monitor.anomalyAlerts.filter { $0.category == .battery }
                if !batteryAlerts.isEmpty {
                    print("   ⚠️  Battery Alerts:")
                    for alert in batteryAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for battery optimization recommendations
                let batteryRecs = monitor.optimizationRecommendations.filter { $0.category == .battery }
                if !batteryRecs.isEmpty {
                    print("   💡 Battery Recommendations:")
                    for rec in batteryRecs.prefix(1) {
                        print("      - \(rec.title) (Savings: \(String(format: "%.1f", rec.estimatedSavings))%)")
                    }
                }
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ Battery monitoring completed")
            
        } catch {
            print("❌ Battery monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Machine Learning performance monitoring
    public static func demonstrateMLPerformanceMonitoring() async {
        print("\n🤖 Machine Learning Performance Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.5)
            print("✅ ML performance monitoring started...")
            
            for i in 1...6 {
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                
                print("📊 ML Update \(i):")
                print("   Model Load Time: \(String(format: "%.3f", monitor.currentMetrics.ml.modelLoadTime))s")
                print("   Inference Time: \(String(format: "%.3f", monitor.currentMetrics.ml.inferenceTime))s")
                print("   Memory Usage: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.ml.memoryUsage), countStyle: .memory))")
                print("   Model Accuracy: \(String(format: "%.1f", monitor.currentMetrics.ml.accuracy))%")
                print("   Model Size: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.ml.modelSize), countStyle: .memory))")
                print("   Neural Engine Usage: \(String(format: "%.1f", monitor.currentMetrics.ml.neuralEngineUsage))%")
                
                // Check for ML alerts
                let mlAlerts = monitor.anomalyAlerts.filter { $0.category == .ml }
                if !mlAlerts.isEmpty {
                    print("   ⚠️  ML Alerts:")
                    for alert in mlAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for ML optimization recommendations
                let mlRecs = monitor.optimizationRecommendations.filter { $0.category == .ml }
                if !mlRecs.isEmpty {
                    print("   💡 ML Recommendations:")
                    for rec in mlRecs.prefix(1) {
                        print("      - \(rec.title) (Savings: \(String(format: "%.1f", rec.estimatedSavings))%)")
                    }
                }
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ ML performance monitoring completed")
            
        } catch {
            print("❌ ML performance monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Database performance monitoring
    public static func demonstrateDatabasePerformanceMonitoring() async {
        print("\n🗄️ Database Performance Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Database performance monitoring started...")
            
            for i in 1...8 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                print("📊 Database Update \(i):")
                print("   Query Time: \(String(format: "%.3f", monitor.currentMetrics.database.queryTime))s")
                print("   Connection Pool: \(monitor.currentMetrics.database.connectionPool)")
                print("   Cache Hit Rate: \(String(format: "%.1f", monitor.currentMetrics.database.cacheHitRate))%")
                print("   Transaction Rate: \(String(format: "%.1f", monitor.currentMetrics.database.transactionRate))/s")
                print("   Storage Size: \(ByteCountFormatter.string(fromByteCount: Int64(monitor.currentMetrics.database.storageSize), countStyle: .memory))")
                print("   Index Efficiency: \(String(format: "%.1f", monitor.currentMetrics.database.indexEfficiency))%")
                
                // Check for database alerts
                let databaseAlerts = monitor.anomalyAlerts.filter { $0.category == .database }
                if !databaseAlerts.isEmpty {
                    print("   ⚠️  Database Alerts:")
                    for alert in databaseAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for database optimization recommendations
                let databaseRecs = monitor.optimizationRecommendations.filter { $0.category == .database }
                if !databaseRecs.isEmpty {
                    print("   💡 Database Recommendations:")
                    for rec in databaseRecs.prefix(1) {
                        print("      - \(rec.title) (Savings: \(String(format: "%.1f", rec.estimatedSavings))%)")
                    }
                }
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ Database performance monitoring completed")
            
        } catch {
            print("❌ Database performance monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Security performance monitoring
    public static func demonstrateSecurityPerformanceMonitoring() async {
        print("\n🔒 Security Performance Monitoring Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Security performance monitoring started...")
            
            for i in 1...6 {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                print("📊 Security Update \(i):")
                print("   Encryption Overhead: \(String(format: "%.1f", monitor.currentMetrics.security.encryptionOverhead))%")
                print("   Authentication Time: \(String(format: "%.3f", monitor.currentMetrics.security.authenticationTime))s")
                print("   Threat Detection: \(monitor.currentMetrics.security.threatDetection)")
                print("   Data Integrity: \(monitor.currentMetrics.security.dataIntegrity ? "✅" : "❌")")
                print("   Secure Connections: \(monitor.currentMetrics.security.secureConnections)")
                print("   Access Control Latency: \(String(format: "%.3f", monitor.currentMetrics.security.accessControlLatency))s")
                
                // Check for security alerts
                let securityAlerts = monitor.anomalyAlerts.filter { $0.category == .security }
                if !securityAlerts.isEmpty {
                    print("   ⚠️  Security Alerts:")
                    for alert in securityAlerts.suffix(2) {
                        print("      - \(alert.severity.rawValue): \(alert.description)")
                    }
                }
                
                // Check for security optimization recommendations
                let securityRecs = monitor.optimizationRecommendations.filter { $0.category == .security }
                if !securityRecs.isEmpty {
                    print("   💡 Security Recommendations:")
                    for rec in securityRecs.prefix(1) {
                        print("      - \(rec.title)")
                    }
                }
                
                print("---")
            }
            
            monitor.stopMonitoring()
            print("✅ Security performance monitoring completed")
            
        } catch {
            print("❌ Security performance monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Complete performance audit
    public static func demonstrateCompletePerformanceAudit() async {
        print("\n🔍 Complete Performance Audit Demo")
        
        let monitor = AdvancedPerformanceMonitor()
        
        do {
            try monitor.startMonitoring(interval: 1.0)
            print("✅ Complete performance audit started...")
            
            // Run audit for 20 seconds
            try await Task.sleep(nanoseconds: 20_000_000_000)
            
            let dashboard = monitor.getPerformanceDashboard()
            
            print("📊 PERFORMANCE AUDIT REPORT")
            print("=" * 50)
            
            // System Overview
            print("\n🎯 SYSTEM OVERVIEW:")
            print("   Overall Health: \(dashboard.systemOverview.overallHealth.rawValue)")
            print("   CPU Health: \(dashboard.systemOverview.cpuHealth.rawValue)")
            print("   Memory Health: \(dashboard.systemOverview.memoryHealth.rawValue)")
            print("   Network Health: \(dashboard.systemOverview.networkHealth.rawValue)")
            print("   Battery Health: \(dashboard.systemOverview.batteryHealth.rawValue)")
            
            // Performance Summary
            print("\n📋 PERFORMANCE SUMMARY:")
            print("   Overall Score: \(String(format: "%.1f", dashboard.performanceSummary.overallScore))/100")
            print("   Grade: \(getPerformanceGrade(dashboard.performanceSummary.overallScore))")
            
            // Top Issues
            print("\n🚨 TOP ISSUES:")
            if dashboard.performanceSummary.topIssues.isEmpty {
                print("   ✅ No critical issues found")
            } else {
                for (index, issue) in dashboard.performanceSummary.topIssues.enumerated() {
                    print("   \(index + 1). \(issue)")
                }
            }
            
            // Anomaly Analysis
            print("\n⚠️  ANOMALY ANALYSIS:")
            let criticalCount = dashboard.anomalyAlerts.filter { $0.severity == .critical }.count
            let highCount = dashboard.anomalyAlerts.filter { $0.severity == .high }.count
            let mediumCount = dashboard.anomalyAlerts.filter { $0.severity == .medium }.count
            let lowCount = dashboard.anomalyAlerts.filter { $0.severity == .low }.count
            
            print("   Critical: \(criticalCount)")
            print("   High: \(highCount)")
            print("   Medium: \(mediumCount)")
            print("   Low: \(lowCount)")
            print("   Total: \(dashboard.anomalyAlerts.count)")
            
            // Recommendations by Priority
            print("\n💡 OPTIMIZATION RECOMMENDATIONS:")
            let criticalRecs = dashboard.optimizationRecommendations.filter { $0.priority == .critical }
            let highRecs = dashboard.optimizationRecommendations.filter { $0.priority == .high }
            let mediumRecs = dashboard.optimizationRecommendations.filter { $0.priority == .medium }
            let lowRecs = dashboard.optimizationRecommendations.filter { $0.priority == .low }
            
            if !criticalRecs.isEmpty {
                print("   🔴 CRITICAL:")
                for rec in criticalRecs {
                    print("      • \(rec.title)")
                    print("        Impact: \(rec.impact) | Effort: \(rec.effort) | Savings: \(String(format: "%.1f", rec.estimatedSavings))%")
                }
            }
            
            if !highRecs.isEmpty {
                print("   🟠 HIGH:")
                for rec in highRecs.prefix(3) {
                    print("      • \(rec.title)")
                    print("        Impact: \(rec.impact) | Effort: \(rec.effort) | Savings: \(String(format: "%.1f", rec.estimatedSavings))%")
                }
            }
            
            if !mediumRecs.isEmpty {
                print("   🟡 MEDIUM:")
                for rec in mediumRecs.prefix(2) {
                    print("      • \(rec.title)")
                }
            }
            
            if !lowRecs.isEmpty {
                print("   🔵 LOW:")
                for rec in lowRecs.prefix(2) {
                    print("      • \(rec.title)")
                }
            }
            
            // Trend Analysis
            print("\n📈 TREND ANALYSIS:")
            for trend in dashboard.performanceTrends.prefix(5) {
                print("   \(trend.metric): \(trend.trend.rawValue) (Confidence: \(String(format: "%.1f", trend.confidence))%)")
            }
            
            // Metric Details
            print("\n📊 DETAILED METRICS:")
            for chart in dashboard.metricCharts {
                print("   \(chart.title): \(String(format: "%.1f", chart.currentValue))\(chart.unit) (\(chart.trend.rawValue))")
            }
            
            print("\n" + "=" * 50)
            print("✅ PERFORMANCE AUDIT COMPLETED")
            print("   Report Generated: \(Date())")
            print("   Total Monitoring Time: 20 seconds")
            print("   Data Points Collected: \(dashboard.metricCharts.map { $0.values.count }.reduce(0, +))")
            
            monitor.stopMonitoring()
            
        } catch {
            print("❌ Performance audit failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Methods
    
    private static func getPerformanceGrade(_ score: Double) -> String {
        switch score {
        case 90...100: return "A+ (Excellent)"
        case 80..<90: return "A (Very Good)"
        case 70..<80: return "B+ (Good)"
        case 60..<70: return "B (Fair)"
        case 50..<60: return "C (Poor)"
        default: return "F (Critical)"
        }
    }
    
    // MARK: - Integration Examples
    
    /// Example of integrating with SwiftUI
    public struct PerformanceMonitoringView: View {
        @StateObject private var monitor = AdvancedPerformanceMonitor()
        @State private var isMonitoring = false
        
        public var body: some View {
            VStack(spacing: 20) {
                // System Health Overview
                HStack {
                    VStack(alignment: .leading) {
                        Text("System Health")
                            .font(.headline)
                        Text(monitor.systemHealth.rawValue)
                            .font(.title2)
                            .foregroundColor(healthColor(monitor.systemHealth))
                    }
                    Spacer()
                    Button(isMonitoring ? "Stop" : "Start") {
                        toggleMonitoring()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Current Metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    MetricCard(
                        title: "CPU",
                        value: "\(String(format: "%.1f", monitor.currentMetrics.cpu.usage))%",
                        color: metricColor(monitor.currentMetrics.cpu.usage, threshold: 80)
                    )
                    
                    MetricCard(
                        title: "Memory",
                        value: "\(String(format: "%.1f", Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100))%",
                        color: metricColor(Double(monitor.currentMetrics.memory.usedMemory) / Double(monitor.currentMetrics.memory.totalMemory) * 100, threshold: 80)
                    )
                    
                    MetricCard(
                        title: "Network",
                        value: "\(String(format: "%.0f", monitor.currentMetrics.network.latency))ms",
                        color: metricColor(monitor.currentMetrics.network.latency, threshold: 200, lowerIsBetter: true)
                    )
                    
                    MetricCard(
                        title: "Battery",
                        value: "\(String(format: "%.0f", monitor.currentMetrics.battery.batteryLevel * 100))%",
                        color: metricColor(Double(monitor.currentMetrics.battery.batteryLevel) * 100, threshold: 20, lowerIsBetter: true)
                    )
                }
                
                // Anomaly Alerts
                if !monitor.anomalyAlerts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Active Alerts")
                            .font(.headline)
                        
                        ForEach(monitor.anomalyAlerts.prefix(3)) { alert in
                            HStack {
                                Circle()
                                    .fill(Color(alert.severity.color))
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading) {
                                    Text(alert.description)
                                        .font(.caption)
                                    Text(alert.recommendation)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Optimization Recommendations
                if !monitor.optimizationRecommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recommendations")
                            .font(.headline)
                        
                        ForEach(monitor.optimizationRecommendations.prefix(3)) { rec in
                            HStack {
                                Circle()
                                    .fill(Color(rec.priority.color))
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading) {
                                    Text(rec.title)
                                        .font(.caption)
                                    Text("Impact: \(rec.impact) | Savings: \(String(format: "%.1f", rec.estimatedSavings))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Performance Monitor")
        }
        
        private func toggleMonitoring() {
            if isMonitoring {
                monitor.stopMonitoring()
            } else {
                do {
                    try monitor.startMonitoring(interval: 1.0)
                } catch {
                    print("Failed to start monitoring: \(error)")
                }
            }
            isMonitoring.toggle()
        }
        
        private func healthColor(_ health: SystemHealth) -> Color {
            switch health {
            case .excellent: return .green
            case .good: return .green
            case .fair: return .yellow
            case .poor: return .orange
            case .critical: return .red
            }
        }
        
        private func metricColor(_ value: Double, threshold: Double, lowerIsBetter: Bool = false) -> Color {
            if lowerIsBetter {
                return value > threshold ? .red : .green
            } else {
                return value > threshold ? .red : .green
            }
        }
    }
    
    struct MetricCard: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Demo Runner
    
    /// Run all demo examples
    public static func runAllDemos() async {
        print("🚀 Running All Performance Monitor Demos")
        print("=" * 60)
        
        // Basic examples
        await demonstrateBasicMonitoring()
        await demonstrateAnomalyDetection()
        await demonstrateTrendAnalysis()
        await demonstrateOptimizationRecommendations()
        await demonstrateDashboardUsage()
        await demonstrateRealWorldScenario()
        
        // Advanced examples
        await demonstrateComprehensiveMonitoring()
        await demonstrateMemoryPressureMonitoring()
        await demonstrateNetworkPerformanceMonitoring()
        await demonstrateBatteryMonitoring()
        await demonstrateMLPerformanceMonitoring()
        await demonstrateDatabasePerformanceMonitoring()
        await demonstrateSecurityPerformanceMonitoring()
        
        // Complete audit
        await demonstrateCompletePerformanceAudit()
        
        print("\n🎉 All Performance Monitor Demos Completed!")
        print("=" * 60)
    }
}

// MARK: - String Extension for Repeated Characters
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}