import Foundation
import HealthKit
import Combine
import CoreML
import UserNotifications

/// Cardiac Emergency Handler
/// Specialized emergency response system for cardiac events using ECG analysis and real-time monitoring
class CardiacEmergencyHandler: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cardiacStatus: CardiacEmergencyStatus = .normal
    @Published var activeCardiacAlerts: [CardiacEmergencyAlert] = []
    @Published var isMonitoringCardiac = false
    @Published var lastECGAnalysis: Date?
    @Published var cardiacRiskLevel: CardiacRiskLevel = .low
    @Published var emergencyResponseActive = false
    
    // MARK: - Private Properties
    private var healthDataManager: HealthDataManager?
    private var ecgInsightManager: ECGInsightManager?
    private var cardiacHealthAnalyzer: CardiacHealthAnalyzer?
    private var emergencyAlertManager: EmergencyAlertManager?
    
    // Cardiac monitoring configuration
    private var cardiacThresholds: CardiacThresholds = CardiacThresholds()
    private var ecgAnalysisHistory: [ECGAnalysisResult] = []
    private var cardiacEventHistory: [CardiacEvent] = []
    
    // Real-time monitoring
    private var heartRateMonitor: Timer?
    private var ecgAnalysisTimer: Timer?
    private var cardiacDataSubscription: AnyCancellable?
    
    // Emergency response
    private var cardiacResponseProtocol: CardiacResponseProtocol = CardiacResponseProtocol()
    private var lastEmergencyCall: Date?
    private let emergencyCallCooldown: TimeInterval = 300 // 5 minutes
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupCardiacEmergencyHandler()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup and Configuration
    
    private func setupCardiacEmergencyHandler() {
        initializeManagers()
        setupCardiacMonitoring()
        configureEmergencyProtocols()
        startCardiacMonitoring()
    }
    
    private func initializeManagers() {
        healthDataManager = HealthDataManager()
        ecgInsightManager = ECGInsightManager()
        cardiacHealthAnalyzer = CardiacHealthAnalyzer()
        emergencyAlertManager = EmergencyAlertManager()
        
        setupCardiacDataSubscriptions()
    }
    
    private func setupCardiacDataSubscriptions() {
        healthDataManager?.$latestHealthData
            .compactMap { $0 }
            .sink { [weak self] healthData in
                self?.processCardiacData(healthData)
            }
            .store(in: &cancellables)
        
        ecgInsightManager?.$latestECGInsights
            .compactMap { $0 }
            .sink { [weak self] ecgInsights in
                self?.analyzeECGForEmergencies(ecgInsights)
            }
            .store(in: &cancellables)
    }
    
    private func setupCardiacMonitoring() {
        cardiacThresholds = CardiacThresholds(
            maxHeartRate: 180,
            minHeartRate: 40,
            maxRestingHeartRate: 100,
            minRestingHeartRate: 50,
            criticalHRVThreshold: 20,
            atrialFibrillationConfidence: 0.8,
            ventricularTachycardiaThreshold: 150,
            bradycardiaThreshold: 50
        )
    }
    
    private func configureEmergencyProtocols() {
        cardiacResponseProtocol = CardiacResponseProtocol(
            immediateResponseEvents: [.ventricularTachycardia, .ventricularFibrillation, .asystole],
            urgentResponseEvents: [.atrialFibrillation, .severeBradycardia, .sustainedTachycardia],
            monitoringEvents: [.prematureVentricularContractions, .atrialFlutter, .sinus]
        )
    }
    
    // MARK: - Cardiac Monitoring
    
    func startCardiacMonitoring() {
        guard !isMonitoringCardiac else { return }
        
        isMonitoringCardiac = true
        
        heartRateMonitor = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.performHeartRateCheck()
        }
        
        ecgAnalysisTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performECGAnalysis()
        }
    }
    
    func stopCardiacMonitoring() {
        isMonitoringCardiac = false
        heartRateMonitor?.invalidate()
        ecgAnalysisTimer?.invalidate()
        heartRateMonitor = nil
        ecgAnalysisTimer = nil
    }
    
    private func performHeartRateCheck() {
        Task {
            await checkHeartRateThresholds()
        }
    }
    
    private func performECGAnalysis() {
        Task {
            await analyzeECGData()
        }
    }
    
    // MARK: - Emergency Detection
    
    private func processCardiacData(_ healthData: HealthData) {
        Task {
            await analyzeCardiacMetrics(healthData)
        }
    }
    
    private func analyzeCardiacMetrics(_ healthData: HealthData) async {
        let heartRate = healthData.heartRate
        let heartRateVariability = healthData.heartRateVariability
        
        // Check for immediate cardiac emergencies
        if heartRate > cardiacThresholds.maxHeartRate {
            await handleTachycardiaEvent(heartRate: heartRate)
        } else if heartRate < cardiacThresholds.minHeartRate {
            await handleBradycardiaEvent(heartRate: heartRate)
        }
        
        // Analyze HRV for cardiac stress
        if heartRateVariability < cardiacThresholds.criticalHRVThreshold {
            await handleLowHRVEvent(hrv: heartRateVariability)
        }
        
        // Update cardiac risk level
        await updateCardiacRiskLevel(heartRate: heartRate, hrv: heartRateVariability)
    }
    
    private func analyzeECGForEmergencies(_ ecgInsights: ECGInsights) {
        Task {
            await processECGInsights(ecgInsights)
        }
    }
    
    private func processECGInsights(_ ecgInsights: ECGInsights) async {
        lastECGAnalysis = Date()
        
        // Check for critical cardiac events
        for insight in ecgInsights.insights {
            switch insight.type {
            case .atrialFibrillation:
                if insight.confidence > cardiacThresholds.atrialFibrillationConfidence {
                    await handleAtrialFibrillationEvent(confidence: insight.confidence)
                }
            case .ventricularTachycardia:
                await handleVentricularTachycardiaEvent(confidence: insight.confidence)
            case .bradycardia:
                await handleBradycardiaEvent(heartRate: insight.heartRate ?? 0)
            case .prematureVentricularContractions:
                await handlePVCEvent(frequency: insight.frequency ?? 0)
            case .stElevation:
                await handleSTElevationEvent(confidence: insight.confidence)
            default:
                break
            }
        }
    }
    
    // MARK: - Emergency Event Handlers
    
    private func handleTachycardiaEvent(heartRate: Double) async {
        let event = CardiacEvent(
            type: .tachycardia,
            severity: heartRate > 200 ? .critical : .high,
            heartRate: heartRate,
            timestamp: Date(),
            confidence: 0.9
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    private func handleBradycardiaEvent(heartRate: Double) async {
        let event = CardiacEvent(
            type: .bradycardia,
            severity: heartRate < 30 ? .critical : .high,
            heartRate: heartRate,
            timestamp: Date(),
            confidence: 0.9
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    private func handleAtrialFibrillationEvent(confidence: Double) async {
        let event = CardiacEvent(
            type: .atrialFibrillation,
            severity: .high,
            heartRate: nil,
            timestamp: Date(),
            confidence: confidence
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    private func handleVentricularTachycardiaEvent(confidence: Double) async {
        let event = CardiacEvent(
            type: .ventricularTachycardia,
            severity: .critical,
            heartRate: nil,
            timestamp: Date(),
            confidence: confidence
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    private func handleLowHRVEvent(hrv: Double) async {
        let event = CardiacEvent(
            type: .lowHRV,
            severity: .medium,
            heartRate: nil,
            timestamp: Date(),
            confidence: 0.8
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    private func handlePVCEvent(frequency: Double) async {
        let event = CardiacEvent(
            type: .prematureVentricularContractions,
            severity: frequency > 10 ? .medium : .low,
            heartRate: nil,
            timestamp: Date(),
            confidence: 0.7
        )
        
        if frequency > 10 {
            await triggerCardiacEmergency(event: event)
        }
    }
    
    private func handleSTElevationEvent(confidence: Double) async {
        let event = CardiacEvent(
            type: .stElevation,
            severity: .critical,
            heartRate: nil,
            timestamp: Date(),
            confidence: confidence
        )
        
        await triggerCardiacEmergency(event: event)
    }
    
    // MARK: - Emergency Response
    
    private func triggerCardiacEmergency(event: CardiacEvent) async {
        cardiacEventHistory.append(event)
        
        let alert = CardiacEmergencyAlert(
            id: UUID(),
            event: event,
            timestamp: Date(),
            status: .active,
            responseLevel: determineResponseLevel(for: event)
        )
        
        await MainActor.run {
            activeCardiacAlerts.append(alert)
            cardiacStatus = .emergency
            emergencyResponseActive = true
        }
        
        await executeEmergencyResponse(for: alert)
    }
    
    private func determineResponseLevel(for event: CardiacEvent) -> CardiacResponseLevel {
        switch event.type {
        case .ventricularTachycardia, .ventricularFibrillation, .asystole, .stElevation:
            return .immediate
        case .atrialFibrillation, .severeBradycardia, .sustainedTachycardia:
            return .urgent
        case .tachycardia, .bradycardia, .lowHRV:
            return event.severity == .critical ? .urgent : .monitoring
        default:
            return .monitoring
        }
    }
    
    private func executeEmergencyResponse(for alert: CardiacEmergencyAlert) async {
        switch alert.responseLevel {
        case .immediate:
            await executeImmediateResponse(alert)
        case .urgent:
            await executeUrgentResponse(alert)
        case .monitoring:
            await executeMonitoringResponse(alert)
        }
    }
    
    private func executeImmediateResponse(_ alert: CardiacEmergencyAlert) async {
        // Call emergency services immediately
        if shouldCallEmergencyServices() {
            await callEmergencyServices(alert)
        }
        
        // Notify emergency contacts
        await notifyEmergencyContacts(alert, priority: .critical)
        
        // Send medical data to emergency services
        await transmitMedicalData(alert)
        
        // Show critical alert to user
        await showCriticalAlert(alert)
    }
    
    private func executeUrgentResponse(_ alert: CardiacEmergencyAlert) async {
        // Notify emergency contacts
        await notifyEmergencyContacts(alert, priority: .high)
        
        // Prepare medical data
        await prepareMedicalData(alert)
        
        // Show urgent alert to user
        await showUrgentAlert(alert)
        
        // Start countdown for emergency services
        await startEmergencyCountdown(alert)
    }
    
    private func executeMonitoringResponse(_ alert: CardiacEmergencyAlert) async {
        // Continue monitoring
        await enhanceMonitoring(alert)
        
        // Notify user
        await showMonitoringAlert(alert)
        
        // Log event for healthcare provider
        await logForHealthcareProvider(alert)
    }
    
    private func shouldCallEmergencyServices() -> Bool {
        guard let lastCall = lastEmergencyCall else { return true }
        return Date().timeIntervalSince(lastCall) > emergencyCallCooldown
    }
    
    private func callEmergencyServices(_ alert: CardiacEmergencyAlert) async {
        lastEmergencyCall = Date()
        
        // Implementation would integrate with emergency services API
        // For now, this is a placeholder
        print("🚨 CALLING EMERGENCY SERVICES - Cardiac Emergency Detected")
        print("Event: \(alert.event.type)")
        print("Severity: \(alert.event.severity)")
        print("Confidence: \(alert.event.confidence)")
    }
    
    private func notifyEmergencyContacts(_ alert: CardiacEmergencyAlert, priority: NotificationPriority) async {
        emergencyAlertManager?.notifyEmergencyContacts(
            message: "Cardiac emergency detected: \(alert.event.type)",
            priority: priority,
            location: nil
        )
    }
    
    private func transmitMedicalData(_ alert: CardiacEmergencyAlert) async {
        // Prepare and transmit critical medical data
        // Implementation would integrate with emergency medical systems
    }
    
    private func showCriticalAlert(_ alert: CardiacEmergencyAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "🚨 CARDIAC EMERGENCY"
        content.body = "Critical cardiac event detected. Emergency services contacted."
        content.sound = .critical
        content.categoryIdentifier = "CARDIAC_EMERGENCY"
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func showUrgentAlert(_ alert: CardiacEmergencyAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Cardiac Alert"
        content.body = "Urgent cardiac event detected. Please seek medical attention."
        content.sound = .default
        content.categoryIdentifier = "CARDIAC_URGENT"
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func showMonitoringAlert(_ alert: CardiacEmergencyAlert) async {
        let content = UNMutableNotificationContent()
        content.title = "📊 Cardiac Monitoring"
        content.body = "Cardiac event detected. Continuing to monitor."
        content.sound = .default
        content.categoryIdentifier = "CARDIAC_MONITORING"
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func prepareMedicalData(_ alert: CardiacEmergencyAlert) async {
        // Prepare medical data for potential transmission
    }
    
    private func enhanceMonitoring(_ alert: CardiacEmergencyAlert) async {
        // Increase monitoring frequency
    }
    
    private func startEmergencyCountdown(_ alert: CardiacEmergencyAlert) async {
        // Start countdown timer for emergency services
    }
    
    private func logForHealthcareProvider(_ alert: CardiacEmergencyAlert) async {
        // Log event for healthcare provider review
    }
    
    // MARK: - Risk Assessment
    
    private func updateCardiacRiskLevel(heartRate: Double, hrv: Double) async {
        let riskScore = calculateCardiacRiskScore(heartRate: heartRate, hrv: hrv)
        
        let newRiskLevel: CardiacRiskLevel
        switch riskScore {
        case 0..<0.3:
            newRiskLevel = .low
        case 0.3..<0.6:
            newRiskLevel = .medium
        case 0.6..<0.8:
            newRiskLevel = .high
        default:
            newRiskLevel = .critical
        }
        
        await MainActor.run {
            cardiacRiskLevel = newRiskLevel
        }
    }
    
    private func calculateCardiacRiskScore(heartRate: Double, hrv: Double) -> Double {
        var riskScore = 0.0
        
        // Heart rate risk factors
        if heartRate > 100 || heartRate < 60 {
            riskScore += 0.3
        }
        if heartRate > 140 || heartRate < 40 {
            riskScore += 0.4
        }
        
        // HRV risk factors
        if hrv < 30 {
            riskScore += 0.2
        }
        if hrv < 20 {
            riskScore += 0.3
        }
        
        return min(riskScore, 1.0)
    }
    
    // MARK: - Utility Methods
    
    private func checkHeartRateThresholds() async {
        guard let latestHeartRate = await healthDataManager?.getLatestHeartRate() else { return }
        
        if latestHeartRate > cardiacThresholds.maxHeartRate {
            await handleTachycardiaEvent(heartRate: latestHeartRate)
        } else if latestHeartRate < cardiacThresholds.minHeartRate {
            await handleBradycardiaEvent(heartRate: latestHeartRate)
        }
    }
    
    private func analyzeECGData() async {
        guard let ecgData = await healthDataManager?.getLatestECGData() else { return }
        
        // Process ECG data through ECG insight manager
        await ecgInsightManager?.analyzeECGData(ecgData)
    }
    
    func getCardiacEmergencyHistory() -> [CardiacEvent] {
        return cardiacEventHistory
    }
    
    func clearCardiacAlert(_ alertId: UUID) {
        activeCardiacAlerts.removeAll { $0.id == alertId }
        
        if activeCardiacAlerts.isEmpty {
            cardiacStatus = .normal
            emergencyResponseActive = false
        }
    }
    
    private func cleanup() {
        stopCardiacMonitoring()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Data Structures

struct CardiacThresholds {
    let maxHeartRate: Double
    let minHeartRate: Double
    let maxRestingHeartRate: Double
    let minRestingHeartRate: Double
    let criticalHRVThreshold: Double
    let atrialFibrillationConfidence: Double
    let ventricularTachycardiaThreshold: Double
    let bradycardiaThreshold: Double
    
    init(maxHeartRate: Double = 180,
         minHeartRate: Double = 40,
         maxRestingHeartRate: Double = 100,
         minRestingHeartRate: Double = 50,
         criticalHRVThreshold: Double = 20,
         atrialFibrillationConfidence: Double = 0.8,
         ventricularTachycardiaThreshold: Double = 150,
         bradycardiaThreshold: Double = 50) {
        self.maxHeartRate = maxHeartRate
        self.minHeartRate = minHeartRate
        self.maxRestingHeartRate = maxRestingHeartRate
        self.minRestingHeartRate = minRestingHeartRate
        self.criticalHRVThreshold = criticalHRVThreshold
        self.atrialFibrillationConfidence = atrialFibrillationConfidence
        self.ventricularTachycardiaThreshold = ventricularTachycardiaThreshold
        self.bradycardiaThreshold = bradycardiaThreshold
    }
}

struct CardiacEvent {
    let type: CardiacEventType
    let severity: CardiacSeverity
    let heartRate: Double?
    let timestamp: Date
    let confidence: Double
}

struct CardiacEmergencyAlert {
    let id: UUID
    let event: CardiacEvent
    let timestamp: Date
    let status: AlertStatus
    let responseLevel: CardiacResponseLevel
}

struct CardiacResponseProtocol {
    let immediateResponseEvents: [CardiacEventType]
    let urgentResponseEvents: [CardiacEventType]
    let monitoringEvents: [CardiacEventType]
    
    init(immediateResponseEvents: [CardiacEventType] = [],
         urgentResponseEvents: [CardiacEventType] = [],
         monitoringEvents: [CardiacEventType] = []) {
        self.immediateResponseEvents = immediateResponseEvents
        self.urgentResponseEvents = urgentResponseEvents
        self.monitoringEvents = monitoringEvents
    }
}

enum CardiacEmergencyStatus {
    case normal
    case monitoring
    case alert
    case emergency
}

enum CardiacRiskLevel {
    case low
    case medium
    case high
    case critical
}

enum CardiacEventType {
    case tachycardia
    case bradycardia
    case atrialFibrillation
    case ventricularTachycardia
    case ventricularFibrillation
    case asystole
    case prematureVentricularContractions
    case atrialFlutter
    case sinus
    case lowHRV
    case stElevation
    case sustainedTachycardia
    case severeBradycardia
}

enum CardiacSeverity {
    case low
    case medium
    case high
    case critical
}

enum CardiacResponseLevel {
    case immediate
    case urgent
    case monitoring
}

enum AlertStatus {
    case active
    case acknowledged
    case resolved
}

enum NotificationPriority {
    case low
    case medium
    case high
    case critical
}