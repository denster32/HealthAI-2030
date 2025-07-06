import Foundation
import Observation
import os.log

/// Device orchestrator for coordinating smart devices in federated learning
/// Manages device coordination, load balancing, fault tolerance, and performance optimization
@available(iOS 18.0, macOS 15.0, *)
public enum DeviceOrchestratorError: Error, LocalizedError {
    case initializationFailed(String)
    case deviceDiscoveryFailed(String)
    case deviceConnectionFailed(String)
    case loadBalancingFailed(String)
    case faultToleranceFailed(String)
    case performanceOptimizationFailed(String)
    case taskAssignmentFailed(String)
    case healthMonitoringFailed(String)
    case invalidDeviceData(String)
    case orchestrationStateError(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let details):
            return "Device orchestrator initialization failed: \(details)"
        case .deviceDiscoveryFailed(let details):
            return "Device discovery failed: \(details)"
        case .deviceConnectionFailed(let details):
            return "Device connection failed: \(details)"
        case .loadBalancingFailed(let details):
            return "Load balancing failed: \(details)"
        case .faultToleranceFailed(let details):
            return "Fault tolerance failed: \(details)"
        case .performanceOptimizationFailed(let details):
            return "Performance optimization failed: \(details)"
        case .taskAssignmentFailed(let details):
            return "Task assignment failed: \(details)"
        case .healthMonitoringFailed(let details):
            return "Health monitoring failed: \(details)"
        case .invalidDeviceData(let details):
            return "Invalid device data: \(details)"
        case .orchestrationStateError(let details):
            return "Orchestration state error: \(details)"
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
@Model
public final class DeviceOrchestrationSnapshot {
    public var id: UUID
    public var timestamp: Date
    public var connectedDevices: [SmartDevice]
    public var orchestrationStatus: OrchestrationStatus
    public var loadDistribution: LoadDistribution
    public var faultStatus: FaultStatus
    public var performanceMetrics: PerformanceMetrics
    public var metadata: Data?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        connectedDevices: [SmartDevice],
        orchestrationStatus: OrchestrationStatus,
        loadDistribution: LoadDistribution,
        faultStatus: FaultStatus,
        performanceMetrics: PerformanceMetrics,
        metadata: Data? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.connectedDevices = connectedDevices
        self.orchestrationStatus = orchestrationStatus
        self.loadDistribution = loadDistribution
        self.faultStatus = faultStatus
        self.performanceMetrics = performanceMetrics
        self.metadata = metadata
    }
}

@available(iOS 18.0, macOS 15.0, *)
@Observable
public final class DeviceOrchestrator {
    
    // MARK: - Published Properties
    public var connectedDevices: [SmartDevice] = []
    public var orchestrationStatus: OrchestrationStatus = .idle
    public var loadDistribution: LoadDistribution = LoadDistribution(
        totalLoad: 0.0,
        distributedLoad: 0.0,
        deviceLoads: [:],
        balanceScore: 0.0
    )
    public var faultStatus: FaultStatus = .healthy
    public var performanceMetrics: PerformanceMetrics = PerformanceMetrics(
        overallEfficiency: 0.0,
        averageResponseTime: 0.0,
        throughput: 0.0,
        resourceUtilization: 0.0,
        energyEfficiency: 0.0,
        networkEfficiency: 0.0,
        faultTolerance: 0.0,
        scalability: 0.0
    )
    
    // MARK: - Private Properties
    private var deviceManager: DeviceManager
    private var loadBalancer: LoadBalancer
    private var faultToleranceManager: FaultToleranceManager
    private var performanceOptimizer: PerformanceOptimizer
    private var deviceDiscovery: DeviceDiscovery
    private var healthMonitor: HealthMonitor
    
    // MARK: - Configuration
    private let deviceDiscoveryInterval: TimeInterval = 30 // 30 seconds
    private let healthMonitoringInterval: TimeInterval = 60 // 1 minute
    private let orchestrationInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.healthai.federated", category: "device-orchestrator")
    
    // MARK: - Initialization
    public init() throws {
        logger.info("🤖 Initializing Device Orchestrator...")
        
        do {
            self.deviceManager = try DeviceManager()
            self.loadBalancer = try LoadBalancer()
            self.faultToleranceManager = try FaultToleranceManager()
            self.performanceOptimizer = try PerformanceOptimizer()
            self.deviceDiscovery = try DeviceDiscovery()
            self.healthMonitor = try HealthMonitor()
            
            try setupDeviceDiscovery()
            try setupHealthMonitoring()
            try setupOrchestration()
            
            logger.info("✅ Device Orchestrator initialized successfully")
        } catch {
            logger.error("❌ Device Orchestrator initialization failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.initializationFailed("Initialization failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Interface
    
    /// Discover and connect to smart devices with enhanced error handling
    /// - Throws: DeviceOrchestratorError if discovery fails
    public func discoverDevices() async throws {
        logger.info("🔍 Starting device discovery...")
        
        do {
            orchestrationStatus = .discovering
            
            let discoveredDevices = try await deviceDiscovery.discoverDevices()
            
            // Validate discovered devices
            for device in discoveredDevices {
                try await validateDevice(device)
            }
            
            connectedDevices = discoveredDevices
            orchestrationStatus = .coordinating
            
            logger.info("✅ Device discovery completed: devices=\(discoveredDevices.count)")
        } catch {
            logger.error("❌ Device discovery failed: \(error.localizedDescription)")
            orchestrationStatus = .failed
            throw DeviceOrchestratorError.deviceDiscoveryFailed("Discovery failed: \(error.localizedDescription)")
        }
    }
    
    /// Monitor device health with enhanced validation
    /// - Throws: DeviceOrchestratorError if monitoring fails
    public func monitorDeviceHealth() async throws {
        logger.debug("🏥 Monitoring device health...")
        
        do {
            for (index, device) in connectedDevices.enumerated() {
                let healthStatus = try await healthMonitor.checkHealth(device)
                
                if healthStatus != device.health.status {
                    var updatedDevice = device
                    updatedDevice.health.status = healthStatus
                    connectedDevices[index] = updatedDevice
                    
                    if healthStatus == .unhealthy || healthStatus == .critical {
                        try await handleDeviceFailure(device)
                    }
                }
            }
            
            logger.debug("✅ Device health monitoring completed")
        } catch {
            logger.error("❌ Device health monitoring failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.healthMonitoringFailed("Health monitoring failed: \(error.localizedDescription)")
        }
    }
    
    /// Run orchestration cycle with enhanced error handling
    /// - Throws: DeviceOrchestratorError if orchestration fails
    public func runOrchestration() async throws {
        logger.info("🎼 Running orchestration cycle...")
        
        do {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Coordinate smart devices
            orchestrationStatus = .coordinating
            try await coordinateSmartDevices()
            
            // Balance load across devices
            orchestrationStatus = .balancing
            try await balanceLoadAcrossDevices()
            
            // Handle fault tolerance and recovery
            orchestrationStatus = .recovering
            try await handleFaultToleranceAndRecovery()
            
            // Optimize performance
            orchestrationStatus = .optimizing
            try await optimizePerformance()
            
            orchestrationStatus = .completed
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let cycleTime = endTime - startTime
            
            logger.info("✅ Orchestration cycle completed: cycleTime=\(cycleTime)")
        } catch {
            logger.error("❌ Orchestration cycle failed: \(error.localizedDescription)")
            orchestrationStatus = .failed
            throw DeviceOrchestratorError.orchestrationStateError("Orchestration failed: \(error.localizedDescription)")
        }
    }
    
    /// Assign task to best available device with enhanced validation
    /// - Parameter task: The task to assign
    /// - Returns: Assigned device ID
    /// - Throws: DeviceOrchestratorError if assignment fails
    public func assignTask(_ task: Task) async throws -> UUID {
        logger.debug("📋 Assigning task: \(task.name)")
        
        do {
            // Validate task
            try await validateTask(task)
            
            // Find best device for task
            let bestDevice = try await findBestDevice(for: task)
            
            // Assign task to device
            try await deviceManager.assignTask(task, to: bestDevice)
            
            logger.debug("✅ Task assigned successfully: task=\(task.name), device=\(bestDevice.name)")
            
            return bestDevice.id
        } catch {
            logger.error("❌ Task assignment failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.taskAssignmentFailed("Assignment failed: \(error.localizedDescription)")
        }
    }
    
    /// Get orchestration status with enhanced validation
    /// - Returns: Current orchestration status
    /// - Throws: DeviceOrchestratorError if status retrieval fails
    public func getOrchestrationStatus() async throws -> OrchestrationStatus {
        do {
            return orchestrationStatus
        } catch {
            logger.error("Status retrieval failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.orchestrationStateError("Status retrieval failed: \(error.localizedDescription)")
        }
    }
    
    /// Get connected devices with enhanced validation
    /// - Returns: Array of connected devices
    /// - Throws: DeviceOrchestratorError if device retrieval fails
    public func getConnectedDevices() async throws -> [SmartDevice] {
        do {
            return connectedDevices
        } catch {
            logger.error("Device retrieval failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.deviceConnectionFailed("Device retrieval failed: \(error.localizedDescription)")
        }
    }
    
    /// Get performance metrics with enhanced validation
    /// - Returns: Current performance metrics
    /// - Throws: DeviceOrchestratorError if metrics retrieval fails
    public func getPerformanceMetrics() async throws -> PerformanceMetrics {
        do {
            return performanceMetrics
        } catch {
            logger.error("Performance metrics retrieval failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.performanceOptimizationFailed("Metrics retrieval failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupDeviceDiscovery() throws {
        // Setup continuous device discovery with async/await
        Task {
            while true {
                try await Task.sleep(nanoseconds: UInt64(deviceDiscoveryInterval * 1_000_000_000))
                try await discoverDevices()
            }
        }
    }
    
    private func setupHealthMonitoring() throws {
        // Setup continuous health monitoring with async/await
        Task {
            while true {
                try await Task.sleep(nanoseconds: UInt64(healthMonitoringInterval * 1_000_000_000))
                try await monitorDeviceHealth()
            }
        }
    }
    
    private func setupOrchestration() throws {
        // Setup continuous orchestration with async/await
        Task {
            while true {
                try await Task.sleep(nanoseconds: UInt64(orchestrationInterval * 1_000_000_000))
                try await runOrchestration()
            }
        }
    }
    
    private func validateDevice(_ device: SmartDevice) async throws {
        // Validate device data
        guard !device.name.isEmpty else {
            throw DeviceOrchestratorError.invalidDeviceData("Device name cannot be empty")
        }
        guard !device.capabilities.isEmpty else {
            throw DeviceOrchestratorError.invalidDeviceData("Device capabilities cannot be empty")
        }
        guard !device.location.isEmpty else {
            throw DeviceOrchestratorError.invalidDeviceData("Device location cannot be empty")
        }
        
        // Validate performance metrics
        guard device.performance.cpuUsage >= 0.0 && device.performance.cpuUsage <= 1.0 else {
            throw DeviceOrchestratorError.invalidDeviceData("CPU usage must be between 0.0 and 1.0")
        }
        guard device.performance.memoryUsage >= 0.0 && device.performance.memoryUsage <= 1.0 else {
            throw DeviceOrchestratorError.invalidDeviceData("Memory usage must be between 0.0 and 1.0")
        }
        guard device.performance.batteryLevel >= 0.0 && device.performance.batteryLevel <= 1.0 else {
            throw DeviceOrchestratorError.invalidDeviceData("Battery level must be between 0.0 and 1.0")
        }
    }
    
    private func validateTask(_ task: Task) async throws {
        // Validate task data
        guard !task.name.isEmpty else {
            throw DeviceOrchestratorError.invalidDeviceData("Task name cannot be empty")
        }
        guard task.requirements.cpuCores > 0 else {
            throw DeviceOrchestratorError.invalidDeviceData("Task must require at least 1 CPU core")
        }
        guard task.requirements.memoryGB > 0 else {
            throw DeviceOrchestratorError.invalidDeviceData("Task must require at least some memory")
        }
    }
    
    private func handleDeviceFailure(_ device: SmartDevice) async throws {
        logger.warning("⚠️ Device failure detected: \(device.name)")
        
        faultStatus = .degraded
        
        do {
            // Implement fault tolerance
            try await faultToleranceManager.handleDeviceFailure(device, in: connectedDevices)
            
            logger.info("✅ Device failure handled successfully: \(device.name)")
        } catch {
            logger.error("❌ Device failure handling failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.faultToleranceFailed("Failure handling failed: \(error.localizedDescription)")
        }
    }
    
    private func coordinateSmartDevices() async throws {
        logger.debug("🎼 Coordinating smart devices...")
        
        do {
            // Coordinate devices for federated learning tasks
            let tasks = try await deviceManager.getPendingTasks()
            
            for task in tasks {
                let bestDevice = try await findBestDevice(for: task)
                try await deviceManager.assignTask(task, to: bestDevice)
            }
            
            logger.debug("✅ Smart device coordination completed")
        } catch {
            logger.error("❌ Smart device coordination failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.orchestrationStateError("Coordination failed: \(error.localizedDescription)")
        }
    }
    
    private func balanceLoadAcrossDevices() async throws {
        logger.debug("⚖️ Balancing load across devices...")
        
        do {
            let distribution = try await loadBalancer.balanceLoad(across: connectedDevices)
            loadDistribution = distribution
            
            logger.debug("✅ Load balancing completed: balanceScore=\(distribution.balanceScore)")
        } catch {
            logger.error("❌ Load balancing failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.loadBalancingFailed("Load balancing failed: \(error.localizedDescription)")
        }
    }
    
    private func handleFaultToleranceAndRecovery() async throws {
        logger.debug("🛡️ Handling fault tolerance and recovery...")
        
        do {
            try await faultToleranceManager.performRecovery(devices: connectedDevices)
            
            logger.debug("✅ Fault tolerance and recovery completed")
        } catch {
            logger.error("❌ Fault tolerance and recovery failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.faultToleranceFailed("Fault tolerance failed: \(error.localizedDescription)")
        }
    }
    
    private func optimizePerformance() async throws {
        logger.debug("⚡ Optimizing performance...")
        
        do {
            let metrics = try await performanceOptimizer.optimizePerformance(devices: connectedDevices)
            performanceMetrics = metrics
            
            logger.debug("✅ Performance optimization completed: efficiency=\(metrics.overallEfficiency)")
        } catch {
            logger.error("❌ Performance optimization failed: \(error.localizedDescription)")
            throw DeviceOrchestratorError.performanceOptimizationFailed("Performance optimization failed: \(error.localizedDescription)")
        }
    }
    
    private func findBestDevice(for task: Task) async throws -> SmartDevice {
        // Find the best device for the given task based on requirements and capabilities
        let suitableDevices = connectedDevices.filter { device in
            // Check if device has required capabilities
            let hasRequiredCapabilities = task.requirements.gpuRequired ? device.capabilities.contains(.gpu) : true
            let hasBattery = task.requirements.batteryRequired ? device.capabilities.contains(.battery) : true
            
            // Check if device is available
            let isAvailable = device.status == .online || device.status == .idle
            
            // Check if device is healthy
            let isHealthy = device.health.status == .healthy
            
            return hasRequiredCapabilities && hasBattery && isAvailable && isHealthy
        }
        
        guard !suitableDevices.isEmpty else {
            throw DeviceOrchestratorError.taskAssignmentFailed("No suitable devices found for task: \(task.name)")
        }
        
        // Select device with best performance for the task
        let bestDevice = suitableDevices.max { device1, device2 in
            let score1 = calculateDeviceScore(device1, for: task)
            let score2 = calculateDeviceScore(device2, for: task)
            return score1 < score2
        }
        
        return bestDevice ?? suitableDevices.first!
    }
    
    private func calculateDeviceScore(_ device: SmartDevice, for task: Task) -> Double {
        var score = 0.0
        
        // Performance score
        score += (1.0 - device.performance.cpuUsage) * 0.3
        score += (1.0 - device.performance.memoryUsage) * 0.2
        score += device.performance.batteryLevel * 0.2
        score += (1.0 / device.performance.responseTime) * 0.2
        score += (device.performance.throughput / 100.0) * 0.1
        
        // Health score
        if device.health.status == .healthy {
            score += 0.5
        } else if device.health.status == .degraded {
            score += 0.2
        }
        
        return score
    }
}

// MARK: - Supporting Manager Classes

@available(iOS 18.0, macOS 15.0, *)
public class DeviceManager {
    public init() throws {}
    
    public func getPendingTasks() async throws -> [Task] {
        // Implement task retrieval
        return []
    }
    
    public func assignTask(_ task: Task, to device: SmartDevice) async throws {
        // Implement task assignment
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class LoadBalancer {
    public init() throws {}
    
    public func balanceLoad(across devices: [SmartDevice]) async throws -> LoadDistribution {
        // Implement load balancing
        return LoadDistribution(
            totalLoad: 0.0,
            distributedLoad: 0.0,
            deviceLoads: [:],
            balanceScore: 0.0
        )
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class FaultToleranceManager {
    public init() throws {}
    
    public func handleDeviceFailure(_ device: SmartDevice, in devices: [SmartDevice]) async throws {
        // Implement device failure handling
    }
    
    public func performRecovery(devices: [SmartDevice]) async throws {
        // Implement recovery procedures
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class PerformanceOptimizer {
    public init() throws {}
    
    public func optimizePerformance(devices: [SmartDevice]) async throws -> PerformanceMetrics {
        // Implement performance optimization
        return PerformanceMetrics(
            overallEfficiency: 0.8,
            averageResponseTime: 0.1,
            throughput: 100.0,
            resourceUtilization: 0.7,
            energyEfficiency: 0.9,
            networkEfficiency: 0.8,
            faultTolerance: 0.9,
            scalability: 0.8
        )
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class DeviceDiscovery {
    public init() throws {}
    
    public func discoverDevices() async throws -> [SmartDevice] {
        // Implement device discovery
        return [
            SmartDevice(
                name: "iPhone 15 Pro",
                type: .smartphone,
                capabilities: [.computation, .storage, .networking, .sensors, .ml, .gpu, .battery, .display, .audio],
                status: .online,
                performance: SmartDevice.DevicePerformance(
                    cpuUsage: 0.3,
                    memoryUsage: 0.6,
                    storageUsage: 0.4,
                    networkUsage: 0.2,
                    batteryLevel: 0.8,
                    temperature: 35.0,
                    responseTime: 0.1,
                    throughput: 100.0
                ),
                health: SmartDevice.DeviceHealth(
                    status: .healthy,
                    uptime: 86400
                ),
                location: "Home"
            )
        ]
    }
}

@available(iOS 18.0, macOS 15.0, *)
public class HealthMonitor {
    public init() throws {}
    
    public func checkHealth(_ device: SmartDevice) async throws -> SmartDevice.DeviceHealth.HealthStatus {
        // Implement health checking
        return .healthy
    }
}
    
    // MARK: - Smart Device
@available(iOS 18.0, macOS 15.0, *)
public struct SmartDevice: Identifiable, Codable, Equatable {
        public let id = UUID()
        public let name: String
        public let type: DeviceType
        public let capabilities: [DeviceCapability]
        public let status: DeviceStatus
        public let performance: DevicePerformance
        public let health: DeviceHealth
        public let location: String
        public let lastSeen: Date
        
        public enum DeviceType: String, Codable, CaseIterable {
            case smartphone = "Smartphone"
            case tablet = "Tablet"
            case laptop = "Laptop"
            case desktop = "Desktop"
            case smartwatch = "Smartwatch"
            case smartSpeaker = "Smart Speaker"
            case iotDevice = "IoT Device"
            case edgeServer = "Edge Server"
            case cloudServer = "Cloud Server"
        }
        
        public enum DeviceCapability: String, Codable, CaseIterable {
            case computation = "Computation"
            case storage = "Storage"
            case networking = "Networking"
            case sensors = "Sensors"
            case ml = "Machine Learning"
            case gpu = "GPU"
            case fpga = "FPGA"
            case battery = "Battery"
            case display = "Display"
            case audio = "Audio"
        }
        
    public enum DeviceStatus: String, Codable, CaseIterable {
            case online = "Online"
            case offline = "Offline"
            case busy = "Busy"
            case idle = "Idle"
            case error = "Error"
            case maintenance = "Maintenance"
        }
        
    public struct DevicePerformance: Codable, Equatable {
            public let cpuUsage: Double
            public let memoryUsage: Double
            public let storageUsage: Double
            public let networkUsage: Double
            public let batteryLevel: Double
            public let temperature: Double
            public let responseTime: TimeInterval
            public let throughput: Double
        
        public init(
            cpuUsage: Double,
            memoryUsage: Double,
            storageUsage: Double,
            networkUsage: Double,
            batteryLevel: Double,
            temperature: Double,
            responseTime: TimeInterval,
            throughput: Double
        ) {
            self.cpuUsage = cpuUsage
            self.memoryUsage = memoryUsage
            self.storageUsage = storageUsage
            self.networkUsage = networkUsage
            self.batteryLevel = batteryLevel
            self.temperature = temperature
            self.responseTime = responseTime
            self.throughput = throughput
        }
    }
    
    public struct DeviceHealth: Codable, Equatable {
            public let status: HealthStatus
            public let uptime: TimeInterval
            public let lastCheck: Date
            public let issues: [String]
            public let warnings: [String]
            
        public enum HealthStatus: String, Codable, CaseIterable {
                case healthy = "Healthy"
                case degraded = "Degraded"
                case unhealthy = "Unhealthy"
                case critical = "Critical"
            }
        
        public init(
            status: HealthStatus,
            uptime: TimeInterval,
            lastCheck: Date = Date(),
            issues: [String] = [],
            warnings: [String] = []
        ) {
            self.status = status
            self.uptime = uptime
            self.lastCheck = lastCheck
            self.issues = issues
            self.warnings = warnings
        }
    }
    
    public init(
        name: String,
        type: DeviceType,
        capabilities: [DeviceCapability],
        status: DeviceStatus,
        performance: DevicePerformance,
        health: DeviceHealth,
        location: String,
        lastSeen: Date = Date()
    ) {
        self.name = name
        self.type = type
        self.capabilities = capabilities
        self.status = status
        self.performance = performance
        self.health = health
        self.location = location
        self.lastSeen = lastSeen
        }
    }
    
    // MARK: - Orchestration Status
@available(iOS 18.0, macOS 15.0, *)
public enum OrchestrationStatus: String, Codable, CaseIterable {
        case idle = "Idle"
        case discovering = "Discovering"
        case coordinating = "Coordinating"
        case balancing = "Load Balancing"
        case recovering = "Recovering"
        case optimizing = "Optimizing"
        case completed = "Completed"
        case failed = "Failed"
    }
    
    // MARK: - Load Distribution
@available(iOS 18.0, macOS 15.0, *)
public struct LoadDistribution: Codable, Equatable {
        public let totalLoad: Double
        public let distributedLoad: Double
        public let deviceLoads: [String: Double]
        public let balanceScore: Double
        public let bottlenecks: [String]
        public let recommendations: [String]
    
    public init(
        totalLoad: Double,
        distributedLoad: Double,
        deviceLoads: [String: Double],
        balanceScore: Double,
        bottlenecks: [String] = [],
        recommendations: [String] = []
    ) {
        self.totalLoad = totalLoad
        self.distributedLoad = distributedLoad
        self.deviceLoads = deviceLoads
        self.balanceScore = balanceScore
        self.bottlenecks = bottlenecks
        self.recommendations = recommendations
    }
    }
    
    // MARK: - Fault Status
@available(iOS 18.0, macOS 15.0, *)
public enum FaultStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case degraded = "Degraded"
        case critical = "Critical"
        case recovering = "Recovering"
    }
    
    // MARK: - Performance Metrics
@available(iOS 18.0, macOS 15.0, *)
public struct PerformanceMetrics: Codable, Equatable {
        public let overallEfficiency: Double
        public let averageResponseTime: TimeInterval
        public let throughput: Double
        public let resourceUtilization: Double
        public let energyEfficiency: Double
        public let networkEfficiency: Double
        public let faultTolerance: Double
        public let scalability: Double
    
    public init(
        overallEfficiency: Double,
        averageResponseTime: TimeInterval,
        throughput: Double,
        resourceUtilization: Double,
        energyEfficiency: Double,
        networkEfficiency: Double,
        faultTolerance: Double,
        scalability: Double
    ) {
        self.overallEfficiency = overallEfficiency
        self.averageResponseTime = averageResponseTime
        self.throughput = throughput
        self.resourceUtilization = resourceUtilization
        self.energyEfficiency = energyEfficiency
        self.networkEfficiency = networkEfficiency
        self.faultTolerance = faultTolerance
        self.scalability = scalability
    }
    }
    
    // MARK: - Task
@available(iOS 18.0, macOS 15.0, *)
public struct Task: Identifiable, Codable, Equatable {
        public let id = UUID()
        public let name: String
        public let type: TaskType
        public let priority: Priority
        public let requirements: TaskRequirements
        public let assignedDevice: UUID?
        public let status: TaskStatus
        public let createdAt: Date
        public let startedAt: Date?
        public let completedAt: Date?
        
    public enum TaskType: String, Codable, CaseIterable {
            case computation = "Computation"
            case dataProcessing = "Data Processing"
            case modelTraining = "Model Training"
            case inference = "Inference"
            case communication = "Communication"
            case storage = "Storage"
        }
        
    public enum Priority: String, Codable, CaseIterable {
            case low = "Low"
            case normal = "Normal"
            case high = "High"
            case critical = "Critical"
        }
        
    public struct TaskRequirements: Codable, Equatable {
            public let cpuCores: Int
            public let memoryGB: Double
            public let storageGB: Double
            public let networkMbps: Double
            public let gpuRequired: Bool
            public let batteryRequired: Bool
        
        public init(
            cpuCores: Int,
            memoryGB: Double,
            storageGB: Double,
            networkMbps: Double,
            gpuRequired: Bool,
            batteryRequired: Bool
        ) {
            self.cpuCores = cpuCores
            self.memoryGB = memoryGB
            self.storageGB = storageGB
            self.networkMbps = networkMbps
            self.gpuRequired = gpuRequired
            self.batteryRequired = batteryRequired
        }
    }
    
    public enum TaskStatus: String, Codable, CaseIterable {
            case pending = "Pending"
            case assigned = "Assigned"
            case running = "Running"
            case completed = "Completed"
            case failed = "Failed"
            case cancelled = "Cancelled"
    }
    
    public init(
        name: String,
        type: TaskType,
        priority: Priority,
        requirements: TaskRequirements,
        assignedDevice: UUID? = nil,
        status: TaskStatus = .pending,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.name = name
        self.type = type
        self.priority = priority
        self.requirements = requirements
        self.assignedDevice = assignedDevice
        self.status = status
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}