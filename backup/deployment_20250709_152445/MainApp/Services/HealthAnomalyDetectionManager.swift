import Foundation
import HealthKit
import CoreML
import Combine
import CoreLocation

/// Real-time health anomaly detection and alert system
@MainActor
class HealthAnomalyDetectionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentAlerts: [HealthAlert] = []
    @Published var healthTrends: [HealthTrend] = []
    @Published var anomalyHistory: [HealthAnomaly] = []
    @Published var emergencyContacts: [EmergencyContact] = []
    @Published var detectionSettings = AnomalyDetectionSettings()
    @Published var isMonitoring = false
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var anomalyDetectionModel: MLModel?
    private var locationManager = CLLocationManager()
    
    // MARK: - Health Data Properties
    private var heartRateData: [HeartRateData] = []
    private var bloodPressureData: [BloodPressureData] = []
    private var oxygenSaturationData: [OxygenSaturationData] = []
    private var respiratoryRateData: [RespiratoryRateData] = []
    private var temperatureData: [TemperatureData] = []
    private var sleepData: [SleepData] = []
    private var activityData: [ActivityData] = []
    
    // MARK: - Anomaly Thresholds
    private let heartRateThresholds = HeartRateThresholds(
        bradycardia: 50,
        tachycardia: 100,
        criticalHigh: 120,
        criticalLow: 40
    )
    
    private let bloodPressureThresholds = BloodPressureThresholds(
        systolicHigh: 140,
        diastolicHigh: 90,
        systolicCritical: 180,
        diastolicCritical: 110
    )
    
    private let oxygenSaturationThresholds = OxygenSaturationThresholds(
        normal: 95,
        warning: 92,
        critical: 90
    )
    
    private let respiratoryRateThresholds = RespiratoryRateThresholds(
        normalMin: 12,
        normalMax: 20,
        warningMin: 10,
        warningMax: 25,
        criticalMin: 8,
        criticalMax: 30
    )
    
    private let temperatureThresholds = TemperatureThresholds(
        fever: 100.4,
        highFever: 103.0,
        hypothermia: 95.0
    )
    
    // MARK: - Initialization
    init() {
        setupHealthKit()
        setupLocationManager()
        loadAnomalyDetectionModel()
        loadEmergencyContacts()
        setupMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Setup Methods
    private func setupHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Request authorization for health data types
        let healthTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthTypes) { [weak self] success, error in
            if success {
                print("HealthKit authorization granted")
                self?.startHealthDataCollection()
            } else {
                print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func loadAnomalyDetectionModel() {
        // Load ML model for anomaly detection
        // This would be a trained model for detecting health anomalies
        print("Loading anomaly detection model...")
    }
    
    private func loadEmergencyContacts() {
        // Load emergency contacts from UserDefaults or Health app
        let contacts = UserDefaults.standard.array(forKey: "emergencyContacts") as? [[String: Any]] ?? []
        
        emergencyContacts = contacts.compactMap { contactData in
            guard let name = contactData["name"] as? String,
                  let phone = contactData["phone"] as? String else {
                return nil
            }
            
            return EmergencyContact(
                name: name,
                phone: phone,
                relationship: contactData["relationship"] as? String ?? "Unknown",
                isPrimary: contactData["isPrimary"] as? Bool ?? false
            )
        }
    }
    
    private func setupMonitoring() {
        // Start monitoring timer
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performAnomalyDetection()
        }
    }
    
    // MARK: - Health Data Collection
    private func startHealthDataCollection() {
        // Start observing health data changes
        observeHeartRate()
        observeBloodPressure()
        observeOxygenSaturation()
        observeRespiratoryRate()
        observeTemperature()
        observeSleepData()
        observeActivityData()
    }
    
    private func observeHeartRate() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processHeartRateData(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func observeBloodPressure() {
        guard let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic) else { return }
        
        let systolicQuery = HKAnchoredObjectQuery(
            type: systolicType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processBloodPressureData(samples, type: .systolic)
        }
        
        let diastolicQuery = HKAnchoredObjectQuery(
            type: diastolicType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processBloodPressureData(samples, type: .diastolic)
        }
        
        healthStore.execute(systolicQuery)
        healthStore.execute(diastolicQuery)
    }
    
    private func observeOxygenSaturation() {
        guard let oxygenType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: oxygenType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processOxygenSaturationData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processOxygenSaturationData(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func observeRespiratoryRate() {
        guard let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: respiratoryType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processRespiratoryRateData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processRespiratoryRateData(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func observeTemperature() {
        guard let temperatureType = HKQuantityType.quantityType(forIdentifier: .bodyTemperature) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: temperatureType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTemperatureData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processTemperatureData(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func observeSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: sleepType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSleepData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processSleepData(samples)
        }
        
        healthStore.execute(query)
    }
    
    private func observeActivityData() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: stepType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processActivityData(samples)
        }
        
        query.updateHandler = { [weak self] query, samples, deletedObjects, anchor, error in
            self?.processActivityData(samples)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Data Processing
    private func processHeartRateData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let data = HeartRateData(
                value: heartRate,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            heartRateData.append(data)
            
            // Keep only last 24 hours of data
            let dayAgo = Date().addingTimeInterval(-86400)
            heartRateData = heartRateData.filter { $0.timestamp > dayAgo }
            
            // Check for anomalies
            checkHeartRateAnomaly(data)
        }
    }
    
    private func processBloodPressureData(_ samples: [HKSample]?, type: BloodPressureType) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let value = sample.quantity.doubleValue(for: HKUnit.millimeterOfMercury())
            let data = BloodPressureData(
                systolic: type == .systolic ? value : nil,
                diastolic: type == .diastolic ? value : nil,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            bloodPressureData.append(data)
            
            // Keep only last 24 hours of data
            let dayAgo = Date().addingTimeInterval(-86400)
            bloodPressureData = bloodPressureData.filter { $0.timestamp > dayAgo }
            
            // Check for anomalies
            checkBloodPressureAnomaly(data)
        }
    }
    
    private func processOxygenSaturationData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let oxygenLevel = sample.quantity.doubleValue(for: HKUnit.percent())
            let data = OxygenSaturationData(
                value: oxygenLevel,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            oxygenSaturationData.append(data)
            
            // Keep only last 24 hours of data
            let dayAgo = Date().addingTimeInterval(-86400)
            oxygenSaturationData = oxygenSaturationData.filter { $0.timestamp > dayAgo }
            
            // Check for anomalies
            checkOxygenSaturationAnomaly(data)
        }
    }
    
    private func processRespiratoryRateData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let respiratoryRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            let data = RespiratoryRateData(
                value: respiratoryRate,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            respiratoryRateData.append(data)
            
            // Keep only last 24 hours of data
            let dayAgo = Date().addingTimeInterval(-86400)
            respiratoryRateData = respiratoryRateData.filter { $0.timestamp > dayAgo }
            
            // Check for anomalies
            checkRespiratoryRateAnomaly(data)
        }
    }
    
    private func processTemperatureData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let temperature = sample.quantity.doubleValue(for: HKUnit.degreeFahrenheit())
            let data = TemperatureData(
                value: temperature,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            temperatureData.append(data)
            
            // Keep only last 24 hours of data
            let dayAgo = Date().addingTimeInterval(-86400)
            temperatureData = temperatureData.filter { $0.timestamp > dayAgo }
            
            // Check for anomalies
            checkTemperatureAnomaly(data)
        }
    }
    
    private func processSleepData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKCategorySample] else { return }
        
        for sample in samples {
            let sleepStage = SleepStage(rawValue: sample.value) ?? .unknown
            let data = SleepData(
                stage: sleepStage,
                startTime: sample.startDate,
                endTime: sample.endDate,
                source: sample.sourceRevision.source.name
            )
            
            sleepData.append(data)
            
            // Keep only last 7 days of data
            let weekAgo = Date().addingTimeInterval(-604800)
            sleepData = sleepData.filter { $0.startTime > weekAgo }
            
            // Check for anomalies
            checkSleepAnomaly(data)
        }
    }
    
    private func processActivityData(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample] else { return }
        
        for sample in samples {
            let stepCount = sample.quantity.doubleValue(for: HKUnit.count())
            let data = ActivityData(
                stepCount: stepCount,
                timestamp: sample.startDate,
                source: sample.sourceRevision.source.name
            )
            
            activityData.append(data)
            
            // Keep only last 7 days of data
            let weekAgo = Date().addingTimeInterval(-604800)
            activityData = activityData.filter { $0.timestamp > weekAgo }
            
            // Check for anomalies
            checkActivityAnomaly(data)
        }
    }
    
    // MARK: - Anomaly Detection
    private func performAnomalyDetection() {
        // Perform comprehensive anomaly detection
        analyzeHealthTrends()
        detectPatternAnomalies()
        predictHealthRisks()
        updateHealthTrends()
    }
    
    private func checkHeartRateAnomaly(_ data: HeartRateData) {
        var severity: AlertSeverity = .info
        var message = ""
        
        if data.value >= heartRateThresholds.criticalHigh {
            severity = .critical
            message = "Critical: Heart rate \(Int(data.value)) BPM (Normal: 60-100)"
        } else if data.value <= heartRateThresholds.criticalLow {
            severity = .critical
            message = "Critical: Heart rate \(Int(data.value)) BPM (Normal: 60-100)"
        } else if data.value >= heartRateThresholds.tachycardia {
            severity = .warning
            message = "Warning: Elevated heart rate \(Int(data.value)) BPM"
        } else if data.value <= heartRateThresholds.bradycardia {
            severity = .warning
            message = "Warning: Low heart rate \(Int(data.value)) BPM"
        }
        
        if severity != .info {
            let alert = HealthAlert(
                type: .heartRate,
                severity: severity,
                message: message,
                timestamp: data.timestamp,
                value: data.value,
                threshold: heartRateThresholds.tachycardia
            )
            
            addAlert(alert)
        }
    }
    
    private func checkBloodPressureAnomaly(_ data: BloodPressureData) {
        guard let systolic = data.systolic, let diastolic = data.diastolic else { return }
        
        var severity: AlertSeverity = .info
        var message = ""
        
        if systolic >= bloodPressureThresholds.systolicCritical || diastolic >= bloodPressureThresholds.diastolicCritical {
            severity = .critical
            message = "Critical: Blood pressure \(Int(systolic))/\(Int(diastolic)) mmHg"
        } else if systolic >= bloodPressureThresholds.systolicHigh || diastolic >= bloodPressureThresholds.diastolicHigh {
            severity = .warning
            message = "Warning: Elevated blood pressure \(Int(systolic))/\(Int(diastolic)) mmHg"
        }
        
        if severity != .info {
            let alert = HealthAlert(
                type: .bloodPressure,
                severity: severity,
                message: message,
                timestamp: data.timestamp,
                value: systolic,
                threshold: bloodPressureThresholds.systolicHigh
            )
            
            addAlert(alert)
        }
    }
    
    private func checkOxygenSaturationAnomaly(_ data: OxygenSaturationData) {
        var severity: AlertSeverity = .info
        var message = ""
        
        if data.value <= oxygenSaturationThresholds.critical {
            severity = .critical
            message = "Critical: Oxygen saturation \(Int(data.value))% (Normal: 95-100%)"
        } else if data.value <= oxygenSaturationThresholds.warning {
            severity = .warning
            message = "Warning: Low oxygen saturation \(Int(data.value))%"
        }
        
        if severity != .info {
            let alert = HealthAlert(
                type: .oxygenSaturation,
                severity: severity,
                message: message,
                timestamp: data.timestamp,
                value: data.value,
                threshold: oxygenSaturationThresholds.normal
            )
            
            addAlert(alert)
        }
    }
    
    private func checkRespiratoryRateAnomaly(_ data: RespiratoryRateData) {
        var severity: AlertSeverity = .info
        var message = ""
        
        if data.value <= respiratoryRateThresholds.criticalMin || data.value >= respiratoryRateThresholds.criticalMax {
            severity = .critical
            message = "Critical: Respiratory rate \(Int(data.value)) breaths/min (Normal: 12-20)"
        } else if data.value <= respiratoryRateThresholds.warningMin || data.value >= respiratoryRateThresholds.warningMax {
            severity = .warning
            message = "Warning: Abnormal respiratory rate \(Int(data.value)) breaths/min"
        }
        
        if severity != .info {
            let alert = HealthAlert(
                type: .respiratoryRate,
                severity: severity,
                message: message,
                timestamp: data.timestamp,
                value: data.value,
                threshold: respiratoryRateThresholds.normalMax
            )
            
            addAlert(alert)
        }
    }
    
    private func checkTemperatureAnomaly(_ data: TemperatureData) {
        var severity: AlertSeverity = .info
        var message = ""
        
        if data.value >= temperatureThresholds.highFever {
            severity = .critical
            message = "Critical: High fever \(String(format: "%.1f", data.value))°F"
        } else if data.value <= temperatureThresholds.hypothermia {
            severity = .critical
            message = "Critical: Hypothermia \(String(format: "%.1f", data.value))°F"
        } else if data.value >= temperatureThresholds.fever {
            severity = .warning
            message = "Warning: Fever \(String(format: "%.1f", data.value))°F"
        }
        
        if severity != .info {
            let alert = HealthAlert(
                type: .temperature,
                severity: severity,
                message: message,
                timestamp: data.timestamp,
                value: data.value,
                threshold: temperatureThresholds.fever
            )
            
            addAlert(alert)
        }
    }
    
    private func checkSleepAnomaly(_ data: SleepData) {
        // Check for sleep pattern anomalies
        let sleepDuration = data.endTime.timeIntervalSince(data.startTime)
        
        if sleepDuration < 4 * 3600 { // Less than 4 hours
            let alert = HealthAlert(
                type: .sleep,
                severity: .warning,
                message: "Warning: Short sleep duration \(String(format: "%.1f", sleepDuration / 3600)) hours",
                timestamp: data.startTime,
                value: sleepDuration / 3600,
                threshold: 7.0
            )
            
            addAlert(alert)
        }
    }
    
    private func checkActivityAnomaly(_ data: ActivityData) {
        // Check for sudden drops in activity
        let recentActivity = activityData.filter { 
            $0.timestamp > Date().addingTimeInterval(-86400) 
        }
        
        if recentActivity.count > 10 {
            let averageSteps = recentActivity.map { $0.stepCount }.reduce(0, +) / Double(recentActivity.count)
            
            if data.stepCount < averageSteps * 0.3 { // 70% drop in activity
                let alert = HealthAlert(
                    type: .activity,
                    severity: .warning,
                    message: "Warning: Significant drop in activity detected",
                    timestamp: data.timestamp,
                    value: data.stepCount,
                    threshold: averageSteps
                )
                
                addAlert(alert)
            }
        }
    }
    
    // MARK: - Trend Analysis
    private func analyzeHealthTrends() {
        // Analyze trends in health data
        analyzeHeartRateTrends()
        analyzeBloodPressureTrends()
        analyzeSleepTrends()
        analyzeActivityTrends()
    }
    
    private func analyzeHeartRateTrends() {
        guard heartRateData.count > 10 else { return }
        
        let recentData = heartRateData.suffix(10)
        let values = recentData.map { $0.value }
        
        // Calculate trend
        let trend = calculateTrend(values: values)
        
        if abs(trend) > 5 { // Significant trend
            let healthTrend = HealthTrend(
                type: .heartRate,
                trend: trend > 0 ? .increasing : .decreasing,
                magnitude: abs(trend),
                confidence: 0.8,
                timestamp: Date()
            )
            
            healthTrends.append(healthTrend)
        }
    }
    
    private func analyzeBloodPressureTrends() {
        guard bloodPressureData.count > 5 else { return }
        
        let recentData = bloodPressureData.suffix(5)
        let systolicValues = recentData.compactMap { $0.systolic }
        
        if systolicValues.count > 3 {
            let trend = calculateTrend(values: systolicValues)
            
            if abs(trend) > 10 { // Significant trend
                let healthTrend = HealthTrend(
                    type: .bloodPressure,
                    trend: trend > 0 ? .increasing : .decreasing,
                    magnitude: abs(trend),
                    confidence: 0.7,
                    timestamp: Date()
                )
                
                healthTrends.append(healthTrend)
            }
        }
    }
    
    private func analyzeSleepTrends() {
        guard sleepData.count > 7 else { return }
        
        let recentSleep = sleepData.suffix(7)
        let durations = recentSleep.map { 
            $0.endTime.timeIntervalSince($0.startTime) / 3600 
        }
        
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        
        if averageDuration < 6.0 {
            let healthTrend = HealthTrend(
                type: .sleep,
                trend: .decreasing,
                magnitude: 6.0 - averageDuration,
                confidence: 0.9,
                timestamp: Date()
            )
            
            healthTrends.append(healthTrend)
        }
    }
    
    private func analyzeActivityTrends() {
        guard activityData.count > 7 else { return }
        
        let recentActivity = activityData.suffix(7)
        let dailySteps = groupActivityByDay(recentActivity)
        
        if dailySteps.count > 3 {
            let values = dailySteps.map { $0.value }
            let trend = calculateTrend(values: values)
            
            if abs(trend) > 1000 { // Significant trend
                let healthTrend = HealthTrend(
                    type: .activity,
                    trend: trend > 0 ? .increasing : .decreasing,
                    magnitude: abs(trend),
                    confidence: 0.8,
                    timestamp: Date()
                )
                
                healthTrends.append(healthTrend)
            }
        }
    }
    
    private func calculateTrend(values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let n = Double(values.count)
        let sumX = n * (n - 1) / 2
        let sumY = values.reduce(0, +)
        let sumXY = values.enumerated().map { Double($0.offset) * $0.element }.reduce(0, +)
        let sumX2 = values.enumerated().map { Double($0.offset) * Double($0.offset) }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        return slope
    }
    
    private func groupActivityByDay(_ activity: [ActivityData]) -> [DailyActivity] {
        let calendar = Calendar.current
        var dailyActivity: [Date: Double] = [:]
        
        for data in activity {
            let day = calendar.startOfDay(for: data.timestamp)
            dailyActivity[day, default: 0] += data.stepCount
        }
        
        return dailyActivity.map { DailyActivity(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    // MARK: - Pattern Detection
    private func detectPatternAnomalies() {
        // Detect unusual patterns in health data
        detectIrregularHeartRate()
        detectSleepDisruption()
        detectActivityPatterns()
    }
    
    private func detectIrregularHeartRate() {
        guard heartRateData.count > 20 else { return }
        
        let recentData = heartRateData.suffix(20)
        let values = recentData.map { $0.value }
        
        // Calculate variability
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        
        if standardDeviation > 15 { // High variability
            let anomaly = HealthAnomaly(
                type: .heartRateVariability,
                severity: .warning,
                description: "High heart rate variability detected",
                timestamp: Date(),
                data: values
            )
            
            anomalyHistory.append(anomaly)
        }
    }
    
    private func detectSleepDisruption() {
        guard sleepData.count > 7 else { return }
        
        let recentSleep = sleepData.suffix(7)
        let disruptions = recentSleep.filter { 
            $0.endTime.timeIntervalSince($0.startTime) < 6 * 3600 
        }
        
        if disruptions.count > 3 { // Multiple sleep disruptions
            let anomaly = HealthAnomaly(
                type: .sleepDisruption,
                severity: .warning,
                description: "Multiple sleep disruptions detected",
                timestamp: Date(),
                data: disruptions.map { $0.endTime.timeIntervalSince($0.startTime) / 3600 }
            )
            
            anomalyHistory.append(anomaly)
        }
    }
    
    private func detectActivityPatterns() {
        guard activityData.count > 14 else { return }
        
        let recentActivity = activityData.suffix(14)
        let dailySteps = groupActivityByDay(recentActivity)
        
        if dailySteps.count > 7 {
            let averageSteps = dailySteps.map { $0.value }.reduce(0, +) / Double(dailySteps.count)
            
            if averageSteps < 5000 { // Low activity
                let anomaly = HealthAnomaly(
                    type: .lowActivity,
                    severity: .warning,
                    description: "Consistently low activity levels",
                    timestamp: Date(),
                    data: dailySteps.map { $0.value }
                )
                
                anomalyHistory.append(anomaly)
            }
        }
    }
    
    // MARK: - Risk Prediction
    private func predictHealthRisks() {
        // Predict potential health risks based on current data
        predictCardiovascularRisk()
        predictRespiratoryRisk()
        predictSleepRisk()
    }
    
    private func predictCardiovascularRisk() {
        var riskFactors = 0
        
        // Check heart rate
        if let latestHeartRate = heartRateData.last {
            if latestHeartRate.value > heartRateThresholds.tachycardia {
                riskFactors += 2
            } else if latestHeartRate.value < heartRateThresholds.bradycardia {
                riskFactors += 1
            }
        }
        
        // Check blood pressure
        if let latestBP = bloodPressureData.last {
            if let systolic = latestBP.systolic, systolic > bloodPressureThresholds.systolicHigh {
                riskFactors += 2
            }
            if let diastolic = latestBP.diastolic, diastolic > bloodPressureThresholds.diastolicHigh {
                riskFactors += 2
            }
        }
        
        if riskFactors >= 3 {
            let alert = HealthAlert(
                type: .cardiovascularRisk,
                severity: .warning,
                message: "Elevated cardiovascular risk detected",
                timestamp: Date(),
                value: Double(riskFactors),
                threshold: 3.0
            )
            
            addAlert(alert)
        }
    }
    
    private func predictRespiratoryRisk() {
        var riskFactors = 0
        
        // Check oxygen saturation
        if let latestO2 = oxygenSaturationData.last {
            if latestO2.value < oxygenSaturationThresholds.warning {
                riskFactors += 2
            }
        }
        
        // Check respiratory rate
        if let latestRR = respiratoryRateData.last {
            if latestRR.value < respiratoryRateThresholds.warningMin || 
               latestRR.value > respiratoryRateThresholds.warningMax {
                riskFactors += 1
            }
        }
        
        if riskFactors >= 2 {
            let alert = HealthAlert(
                type: .respiratoryRisk,
                severity: .warning,
                message: "Elevated respiratory risk detected",
                timestamp: Date(),
                value: Double(riskFactors),
                threshold: 2.0
            )
            
            addAlert(alert)
        }
    }
    
    private func predictSleepRisk() {
        guard let latestSleep = sleepData.last else { return }
        
        let sleepDuration = latestSleep.endTime.timeIntervalSince(latestSleep.startTime) / 3600
        
        if sleepDuration < 5 {
            let alert = HealthAlert(
                type: .sleepRisk,
                severity: .warning,
                message: "Insufficient sleep detected",
                timestamp: Date(),
                value: sleepDuration,
                threshold: 7.0
            )
            
            addAlert(alert)
        }
    }
    
    // MARK: - Alert Management
    private func addAlert(_ alert: HealthAlert) {
        currentAlerts.append(alert)
        
        // Keep only recent alerts
        let dayAgo = Date().addingTimeInterval(-86400)
        currentAlerts = currentAlerts.filter { $0.timestamp > dayAgo }
        
        // Handle critical alerts
        if alert.severity == .critical {
            handleCriticalAlert(alert)
        }
        
        // Update anomaly history
        let anomaly = HealthAnomaly(
            type: alert.type,
            severity: alert.severity,
            description: alert.message,
            timestamp: alert.timestamp,
            data: [alert.value]
        )
        
        anomalyHistory.append(anomaly)
    }
    
    private func handleCriticalAlert(_ alert: HealthAlert) {
        // Send emergency notification
        sendEmergencyNotification(alert)
        
        // Contact emergency services if needed
        if alert.type == .heartRate || alert.type == .bloodPressure {
            contactEmergencyServices(alert)
        }
        
        // Notify emergency contacts
        notifyEmergencyContacts(alert)
    }
    
    private func sendEmergencyNotification(_ alert: HealthAlert) {
        // Send local notification
        let content = UNMutableNotificationContent()
        content.title = "Health Alert"
        content.body = alert.message
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func contactEmergencyServices(_ alert: HealthAlert) {
        // This would integrate with emergency services
        // For now, just log the action
        print("Emergency services contacted for: \(alert.message)")
    }
    
    private func notifyEmergencyContacts(_ alert: HealthAlert) {
        for contact in emergencyContacts where contact.isPrimary {
            // Send SMS or call emergency contact
            print("Notifying emergency contact: \(contact.name)")
        }
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        isMonitoring = true
        setupMonitoring()
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func addEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.append(contact)
        saveEmergencyContacts()
    }
    
    func removeEmergencyContact(_ contact: EmergencyContact) {
        emergencyContacts.removeAll { $0.id == contact.id }
        saveEmergencyContacts()
    }
    
    func updateDetectionSettings(_ settings: AnomalyDetectionSettings) {
        detectionSettings = settings
        saveDetectionSettings()
    }
    
    func clearAlerts() {
        currentAlerts.removeAll()
    }
    
    func exportHealthReport() -> HealthReport {
        return HealthReport(
            timestamp: Date(),
            alerts: currentAlerts,
            trends: healthTrends,
            anomalies: anomalyHistory,
            emergencyContacts: emergencyContacts
        )
    }
    
    // MARK: - Private Helper Methods
    private func saveEmergencyContacts() {
        let contactsData = emergencyContacts.map { contact in
            [
                "name": contact.name,
                "phone": contact.phone,
                "relationship": contact.relationship,
                "isPrimary": contact.isPrimary
            ]
        }
        
        UserDefaults.standard.set(contactsData, forKey: "emergencyContacts")
    }
    
    private func saveDetectionSettings() {
        // Save detection settings to UserDefaults
        UserDefaults.standard.set(detectionSettings.enabled, forKey: "anomalyDetectionEnabled")
        UserDefaults.standard.set(detectionSettings.sensitivity, forKey: "anomalyDetectionSensitivity")
    }
    
    private func updateHealthTrends() {
        // Keep only recent trends
        let weekAgo = Date().addingTimeInterval(-604800)
        healthTrends = healthTrends.filter { $0.timestamp > weekAgo }
    }
}

// MARK: - Data Models
struct HeartRateData {
    let value: Double
    let timestamp: Date
    let source: String
}

struct BloodPressureData {
    let systolic: Double?
    let diastolic: Double?
    let timestamp: Date
    let source: String
}

struct OxygenSaturationData {
    let value: Double
    let timestamp: Date
    let source: String
}

struct RespiratoryRateData {
    let value: Double
    let timestamp: Date
    let source: String
}

struct TemperatureData {
    let value: Double
    let timestamp: Date
    let source: String
}

struct SleepData {
    let stage: SleepStage
    let startTime: Date
    let endTime: Date
    let source: String
}

struct ActivityData {
    let stepCount: Double
    let timestamp: Date
    let source: String
}

struct DailyActivity {
    let date: Date
    let value: Double
}

enum SleepStage: Int {
    case unknown = 0
    case inBed = 1
    case asleep = 2
    case awake = 3
}

enum BloodPressureType {
    case systolic
    case diastolic
}

struct HeartRateThresholds {
    let bradycardia: Double
    let tachycardia: Double
    let criticalHigh: Double
    let criticalLow: Double
}

struct BloodPressureThresholds {
    let systolicHigh: Double
    let diastolicHigh: Double
    let systolicCritical: Double
    let diastolicCritical: Double
}

struct OxygenSaturationThresholds {
    let normal: Double
    let warning: Double
    let critical: Double
}

struct RespiratoryRateThresholds {
    let normalMin: Double
    let normalMax: Double
    let warningMin: Double
    let warningMax: Double
    let criticalMin: Double
    let criticalMax: Double
}

struct TemperatureThresholds {
    let fever: Double
    let highFever: Double
    let hypothermia: Double
}

struct HealthAlert {
    let id = UUID()
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
    let value: Double
    let threshold: Double
}

enum AlertType {
    case heartRate
    case bloodPressure
    case oxygenSaturation
    case respiratoryRate
    case temperature
    case sleep
    case activity
    case cardiovascularRisk
    case respiratoryRisk
    case sleepRisk
}

enum AlertSeverity {
    case info
    case warning
    case critical
}

struct HealthTrend {
    let id = UUID()
    let type: TrendType
    let trend: TrendDirection
    let magnitude: Double
    let confidence: Double
    let timestamp: Date
}

enum TrendType {
    case heartRate
    case bloodPressure
    case sleep
    case activity
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

struct HealthAnomaly {
    let id = UUID()
    let type: AnomalyType
    let severity: AlertSeverity
    let description: String
    let timestamp: Date
    let data: [Double]
}

enum AnomalyType {
    case heartRateVariability
    case sleepDisruption
    case lowActivity
}

struct EmergencyContact {
    let id = UUID()
    let name: String
    let phone: String
    let relationship: String
    let isPrimary: Bool
}

struct AnomalyDetectionSettings {
    var enabled: Bool = true
    var sensitivity: Double = 0.7
    var monitoringInterval: TimeInterval = 30.0
    var alertNotifications: Bool = true
    var emergencyContacts: Bool = true
}

struct HealthReport {
    let timestamp: Date
    let alerts: [HealthAlert]
    let trends: [HealthTrend]
    let anomalies: [HealthAnomaly]
    let emergencyContacts: [EmergencyContact]
}

// MARK: - Location Manager Delegate
extension HealthAnomalyDetectionManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates for emergency services
        if let location = locations.last {
            print("Current location: \(location.coordinate)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }
} 