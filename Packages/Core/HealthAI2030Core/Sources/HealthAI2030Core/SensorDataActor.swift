import Foundation
import HealthKit
import CoreMotion
import CoreLocation

/// High-performance sensor data collection and processing actor
@globalActor
public actor SensorDataActor {
    public static let shared = SensorDataActor()
    
    private let healthStore = HKHealthStore()
    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let pedometer = CMPedometer()
    private let altimeter = CMAltimeter()
    
    private var isCollecting = false
    private var dataBuffer: [SensorReading] = []
    private let bufferLimit = 1000
    private var lastProcessingTime = Date()
    private let processingInterval: TimeInterval = 60 // Process every minute
    
    // Sensor configuration
    private let accelerometerUpdateInterval: TimeInterval = 0.1
    private let gyroscopeUpdateInterval: TimeInterval = 0.1
    private let heartRateQueryInterval: TimeInterval = 30
    
    private init() {
        setupSensors()
    }
    
    // MARK: - Public Interface
    
    /// Start collecting sensor data
    public func startCollection() {
        guard !isCollecting else { return }
        isCollecting = true
        
        startHealthKitCollection()
        startMotionCollection()
        startLocationCollection()
        startContinuousProcessing()
    }
    
    /// Stop collecting sensor data
    public func stopCollection() {
        isCollecting = false
        
        stopHealthKitCollection()
        stopMotionCollection()
        stopLocationCollection()
    }
    
    /// Get recent sensor readings
    public func getRecentReadings(for sensorType: SensorType, within timeInterval: TimeInterval = 3600) -> [SensorReading] {
        let cutoffDate = Date().addingTimeInterval(-timeInterval)
        return dataBuffer.filter { $0.sensorType == sensorType && $0.timestamp >= cutoffDate }
    }
    
    /// Get aggregated sensor data for analysis
    public func getAggregatedData(for sensorType: SensorType, timeWindow: TimeInterval = 3600) -> SensorAggregation? {
        let readings = getRecentReadings(for: sensorType, within: timeWindow)
        guard !readings.isEmpty else { return nil }
        
        return SensorAggregation(
            sensorType: sensorType,
            readings: readings,
            timeWindow: timeWindow
        )
    }
    
    /// Convert sensor readings to health metrics
    public func convertToHealthMetrics() -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        
        // Process heart rate data
        let heartRateReadings = getRecentReadings(for: .heartRate, within: 3600)
        if let latestHeartRate = heartRateReadings.last {
            let metric = HealthMetric(
                type: .heartRate,
                value: latestHeartRate.value,
                timestamp: latestHeartRate.timestamp,
                source: "HealthKit",
                deviceId: latestHeartRate.deviceId,
                accuracy: latestHeartRate.accuracy
            )
            metrics.append(metric)
        }
        
        // Process step count data
        let stepReadings = getRecentReadings(for: .stepCount, within: 3600)
        if let totalSteps = calculateStepCountForPeriod(stepReadings) {
            let metric = HealthMetric(
                type: .stepCount,
                value: totalSteps,
                timestamp: Date(),
                source: "CoreMotion",
                accuracy: 0.9
            )
            metrics.append(metric)
        }
        
        // Process activity level
        let activityLevel = calculateActivityLevel()
        if activityLevel > 0 {
            let metric = HealthMetric(
                type: .exerciseMinutes,
                value: activityLevel,
                timestamp: Date(),
                source: "SensorFusion",
                accuracy: 0.8
            )
            metrics.append(metric)
        }
        
        return metrics
    }
    
    /// Get real-time sensor status
    public func getSensorStatus() -> [SensorStatus] {
        return [
            SensorStatus(type: .heartRate, isActive: isHealthKitAvailable(), lastReading: getLastReading(for: .heartRate)),
            SensorStatus(type: .accelerometer, isActive: motionManager.isAccelerometerActive, lastReading: getLastReading(for: .accelerometer)),
            SensorStatus(type: .gyroscope, isActive: motionManager.isGyroActive, lastReading: getLastReading(for: .gyroscope)),
            SensorStatus(type: .stepCount, isActive: CMPedometer.isStepCountingAvailable(), lastReading: getLastReading(for: .stepCount)),
            SensorStatus(type: .location, isActive: CLLocationManager.locationServicesEnabled(), lastReading: getLastReading(for: .location))
        ]
    }
    
    // MARK: - Private Implementation
    
    private func setupSensors() {
        // Configure motion manager
        motionManager.accelerometerUpdateInterval = accelerometerUpdateInterval
        motionManager.gyroUpdateInterval = gyroscopeUpdateInterval
        
        // Configure location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
    }
    
    // MARK: - HealthKit Integration
    
    private func startHealthKitCollection() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        requestHealthKitPermissions { [weak self] success in
            if success {
                Task { await self?.startHealthKitQueries() }
            }
        }
    }
    
    private func requestHealthKitPermissions(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            completion(success && error == nil)
        }
    }
    
    private func startHealthKitQueries() {
        // Start heart rate monitoring
        startHeartRateQuery()
        
        // Start step count monitoring
        startStepCountQuery()
        
        // Start blood pressure monitoring
        startBloodPressureQuery()
        
        // Start other vital signs monitoring
        startVitalSignsQueries()
    }
    
    private func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task { await self?.fetchLatestHeartRate() }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let reading = SensorReading(
                sensorType: .heartRate,
                value: heartRate,
                timestamp: sample.endDate,
                deviceId: sample.device?.name,
                accuracy: 0.95
            )
            
            Task { await self?.addReading(reading) }
        }
        
        healthStore.execute(query)
    }
    
    private func startStepCountQuery() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task { await self?.fetchLatestStepCount() }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestStepCount() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else { return }
            
            let steps = sum.doubleValue(for: HKUnit.count())
            let reading = SensorReading(
                sensorType: .stepCount,
                value: steps,
                timestamp: now,
                deviceId: "iPhone",
                accuracy: 0.9
            )
            
            Task { await self?.addReading(reading) }
        }
        
        healthStore.execute(query)
    }
    
    private func startBloodPressureQuery() {
        guard let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        let query = HKObserverQuery(sampleType: systolicType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task { await self?.fetchLatestBloodPressure() }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBloodPressure() {
        // Implementation for blood pressure fetching
        // This would require correlation of systolic and diastolic readings
    }
    
    private func startVitalSignsQueries() {
        // Start monitoring for oxygen saturation, body temperature, etc.
        startOxygenSaturationQuery()
        startBodyTemperatureQuery()
    }
    
    private func startOxygenSaturationQuery() {
        guard let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let query = HKObserverQuery(sampleType: oxygenType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task { await self?.fetchLatestOxygenSaturation() }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestOxygenSaturation() {
        guard let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: oxygenType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            let oxygenSaturation = sample.quantity.doubleValue(for: HKUnit.percent()) * 100
            let reading = SensorReading(
                sensorType: .bloodOxygen,
                value: oxygenSaturation,
                timestamp: sample.endDate,
                deviceId: sample.device?.name,
                accuracy: 0.93
            )
            
            Task { await self?.addReading(reading) }
        }
        
        healthStore.execute(query)
    }
    
    private func startBodyTemperatureQuery() {
        guard let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let query = HKObserverQuery(sampleType: temperatureType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task { await self?.fetchLatestBodyTemperature() }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBodyTemperature() {
        guard let temperatureType = HKObjectType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: temperatureType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            
            let temperature = sample.quantity.doubleValue(for: HKUnit.degreeFahrenheit())
            let reading = SensorReading(
                sensorType: .bodyTemperature,
                value: temperature,
                timestamp: sample.endDate,
                deviceId: sample.device?.name,
                accuracy: 0.85
            )
            
            Task { await self?.addReading(reading) }
        }
        
        healthStore.execute(query)
    }
    
    private func stopHealthKitCollection() {
        healthStore.stop()
    }
    
    // MARK: - Motion Sensors
    
    private func startMotionCollection() {
        startAccelerometerCollection()
        startGyroscopeCollection()
        startPedometerCollection()
        startAltimeterCollection()
    }
    
    private func startAccelerometerCollection() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let magnitude = sqrt(data.acceleration.x * data.acceleration.x +
                                data.acceleration.y * data.acceleration.y +
                                data.acceleration.z * data.acceleration.z)
            
            let reading = SensorReading(
                sensorType: .accelerometer,
                value: magnitude,
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.95,
                metadata: [
                    "x": String(data.acceleration.x),
                    "y": String(data.acceleration.y),
                    "z": String(data.acceleration.z)
                ]
            )
            
            Task { await self?.addReading(reading) }
        }
    }
    
    private func startGyroscopeCollection() {
        guard motionManager.isGyroAvailable else { return }
        
        motionManager.startGyroUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let magnitude = sqrt(data.rotationRate.x * data.rotationRate.x +
                                data.rotationRate.y * data.rotationRate.y +
                                data.rotationRate.z * data.rotationRate.z)
            
            let reading = SensorReading(
                sensorType: .gyroscope,
                value: magnitude,
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.95,
                metadata: [
                    "x": String(data.rotationRate.x),
                    "y": String(data.rotationRate.y),
                    "z": String(data.rotationRate.z)
                ]
            )
            
            Task { await self?.addReading(reading) }
        }
    }
    
    private func startPedometerCollection() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let reading = SensorReading(
                sensorType: .stepCount,
                value: Double(data.numberOfSteps.intValue),
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.9
            )
            
            Task { await self?.addReading(reading) }
        }
    }
    
    private func startAltimeterCollection() {
        guard CMAltimeter.isRelativeAltitudeAvailable() else { return }
        
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let reading = SensorReading(
                sensorType: .altitude,
                value: Double(truncating: data.relativeAltitude),
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.8
            )
            
            Task { await self?.addReading(reading) }
        }
    }
    
    private func stopMotionCollection() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        pedometer.stopUpdates()
        altimeter.stopRelativeAltitudeUpdates()
    }
    
    // MARK: - Location Services
    
    private func startLocationCollection() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func stopLocationCollection() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Data Processing
    
    private func addReading(_ reading: SensorReading) {
        dataBuffer.append(reading)
        
        // Maintain buffer limit
        if dataBuffer.count > bufferLimit {
            dataBuffer.removeFirst(dataBuffer.count - bufferLimit)
        }
        
        // Process data if enough time has passed
        if Date().timeIntervalSince(lastProcessingTime) >= processingInterval {
            processBufferedData()
            lastProcessingTime = Date()
        }
    }
    
    private func processBufferedData() {
        // Group readings by sensor type and perform analysis
        let groupedReadings = Dictionary(grouping: dataBuffer) { $0.sensorType }
        
        for (sensorType, readings) in groupedReadings {
            processReadings(readings, for: sensorType)
        }
    }
    
    private func processReadings(_ readings: [SensorReading], for sensorType: SensorType) {
        // Perform sensor-specific processing
        switch sensorType {
        case .accelerometer:
            processAccelerometerData(readings)
        case .heartRate:
            processHeartRateData(readings)
        case .stepCount:
            processStepCountData(readings)
        default:
            break
        }
    }
    
    private func processAccelerometerData(_ readings: [SensorReading]) {
        // Detect activity patterns from accelerometer data
        let recentReadings = readings.suffix(100) // Last 100 readings
        let averageMagnitude = recentReadings.map(\.value).reduce(0, +) / Double(recentReadings.count)
        
        // Simple activity detection
        if averageMagnitude > 1.2 {
            // High activity detected
            let activityReading = SensorReading(
                sensorType: .activityLevel,
                value: min(averageMagnitude * 10, 100), // Scale to 0-100
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.8
            )
            dataBuffer.append(activityReading)
        }
    }
    
    private func processHeartRateData(_ readings: [SensorReading]) {
        // Analyze heart rate variability and trends
        guard readings.count >= 2 else { return }
        
        let recentValues = readings.suffix(10).map(\.value)
        let variance = calculateVariance(recentValues)
        
        // Store HRV as a derived metric
        let hrvReading = SensorReading(
            sensorType: .heartRateVariability,
            value: variance,
            timestamp: Date(),
            deviceId: "iPhone",
            accuracy: 0.85
        )
        dataBuffer.append(hrvReading)
    }
    
    private func processStepCountData(_ readings: [SensorReading]) {
        // Calculate walking pace and activity level
        guard readings.count >= 2 else { return }
        
        let recent = readings.suffix(2)
        let stepDifference = recent.last!.value - recent.first!.value
        let timeDifference = recent.last!.timestamp.timeIntervalSince(recent.first!.timestamp)
        
        if timeDifference > 0 {
            let stepsPerMinute = stepDifference / (timeDifference / 60)
            
            let paceReading = SensorReading(
                sensorType: .walkingPace,
                value: stepsPerMinute,
                timestamp: Date(),
                deviceId: "iPhone",
                accuracy: 0.8
            )
            dataBuffer.append(paceReading)
        }
    }
    
    private func startContinuousProcessing() {
        Timer.scheduledTimer(withTimeInterval: processingInterval, repeats: true) { [weak self] _ in
            Task { await self?.processBufferedData() }
        }
    }
    
    // MARK: - Utility Methods
    
    private func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    private func getLastReading(for sensorType: SensorType) -> Date? {
        return dataBuffer.last { $0.sensorType == sensorType }?.timestamp
    }
    
    private func calculateStepCountForPeriod(_ readings: [SensorReading]) -> Double? {
        guard !readings.isEmpty else { return nil }
        return readings.map(\.value).reduce(0, +)
    }
    
    private func calculateActivityLevel() -> Double {
        let activityReadings = getRecentReadings(for: .activityLevel, within: 3600)
        guard !activityReadings.isEmpty else { return 0 }
        
        return activityReadings.map(\.value).reduce(0, +) / Double(activityReadings.count)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { ($0 - mean) * ($0 - mean) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
}

// MARK: - Supporting Types

/// Raw sensor reading data
public struct SensorReading: Codable, Identifiable {
    public let id = UUID()
    public let sensorType: SensorType
    public let value: Double
    public let timestamp: Date
    public let deviceId: String?
    public let accuracy: Double
    public let metadata: [String: String]
    
    public init(
        sensorType: SensorType,
        value: Double,
        timestamp: Date,
        deviceId: String? = nil,
        accuracy: Double = 1.0,
        metadata: [String: String] = [:]
    ) {
        self.sensorType = sensorType
        self.value = value
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.accuracy = accuracy
        self.metadata = metadata
    }
}

/// Types of sensors available
public enum SensorType: String, CaseIterable, Codable {
    case heartRate = "heart_rate"
    case accelerometer = "accelerometer"
    case gyroscope = "gyroscope"
    case stepCount = "step_count"
    case location = "location"
    case altitude = "altitude"
    case bloodOxygen = "blood_oxygen"
    case bodyTemperature = "body_temperature"
    case activityLevel = "activity_level"
    case heartRateVariability = "heart_rate_variability"
    case walkingPace = "walking_pace"
    
    public var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .accelerometer: return "Accelerometer"
        case .gyroscope: return "Gyroscope"
        case .stepCount: return "Step Count"
        case .location: return "Location"
        case .altitude: return "Altitude"
        case .bloodOxygen: return "Blood Oxygen"
        case .bodyTemperature: return "Body Temperature"
        case .activityLevel: return "Activity Level"
        case .heartRateVariability: return "Heart Rate Variability"
        case .walkingPace: return "Walking Pace"
        }
    }
}

/// Aggregated sensor data for analysis
public struct SensorAggregation: Codable {
    public let sensorType: SensorType
    public let averageValue: Double
    public let minimumValue: Double
    public let maximumValue: Double
    public let standardDeviation: Double
    public let sampleCount: Int
    public let timeWindow: TimeInterval
    public let timestamp: Date
    
    public init(sensorType: SensorType, readings: [SensorReading], timeWindow: TimeInterval) {
        self.sensorType = sensorType
        self.timeWindow = timeWindow
        self.timestamp = Date()
        self.sampleCount = readings.count
        
        let values = readings.map(\.value)
        self.averageValue = values.reduce(0, +) / Double(values.count)
        self.minimumValue = values.min() ?? 0
        self.maximumValue = values.max() ?? 0
        
        let variance = values.map { ($0 - averageValue) * ($0 - averageValue) }.reduce(0, +) / Double(values.count)
        self.standardDeviation = sqrt(variance)
    }
}

/// Status of a sensor
public struct SensorStatus: Codable {
    public let type: SensorType
    public let isActive: Bool
    public let lastReading: Date?
    public let health: SensorHealth
    
    public init(type: SensorType, isActive: Bool, lastReading: Date?) {
        self.type = type
        self.isActive = isActive
        self.lastReading = lastReading
        
        // Determine sensor health
        if !isActive {
            self.health = .offline
        } else if let lastReading = lastReading {
            let timeSinceLastReading = Date().timeIntervalSince(lastReading)
            if timeSinceLastReading < 300 { // 5 minutes
                self.health = .healthy
            } else if timeSinceLastReading < 3600 { // 1 hour
                self.health = .degraded
            } else {
                self.health = .stale
            }
        } else {
            self.health = .unknown
        }
    }
}

/// Health status of a sensor
public enum SensorHealth: String, Codable, CaseIterable {
    case healthy = "healthy"
    case degraded = "degraded"
    case stale = "stale"
    case offline = "offline"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .healthy: return "Healthy"
        case .degraded: return "Degraded"
        case .stale: return "Stale Data"
        case .offline: return "Offline"
        case .unknown: return "Unknown"
        }
    }
    
    public var color: String {
        switch self {
        case .healthy: return "green"
        case .degraded: return "yellow"
        case .stale: return "orange"
        case .offline: return "red"
        case .unknown: return "gray"
        }
    }
}