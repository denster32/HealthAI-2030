import Foundation
import Combine
import CoreML
import HealthKit

class ECGInsightManager: ObservableObject {
    static let shared = ECGInsightManager()
    
    // MARK: - Published Properties
    @Published var currentInsights: [ECGInsight] = []
    @Published var isAnalysisActive: Bool = false
    @Published var lastAnalysisTime: Date?
    @Published var analysisStatus: AnalysisStatus = .idle
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var analysisTimer: Timer?
    
    // MARK: - ECG Analysis Components
    private let beatMorphologyAnalyzer = BeatMorphologyAnalyzer()
    private let hrtTurbulenceCalculator = HRTurbulenceCalculator()
    private let qtDynamicAnalyzer = QTDynamicAnalyzer()
    private let stSegmentAnalyzer = STSegmentAnalyzer()
    private let afForecastModel = AFForecastModel()
    private let afFeatureExtractor = AFFeatureExtractor()
    
    // MARK: - Data Processing
    private let ecgDataProcessor = ECGDataProcessor()
    
    private init() {
        setupECGMonitoring()
        startPeriodicAnalysis()
    }
    
    deinit {
        cancellables.removeAll()
        analysisTimer?.invalidate()
        print("ECGInsightManager deinitialized, Combine cancellables cleared and timer invalidated.")
    }
    
    // MARK: - Public Interface
    
    /// Start continuous ECG monitoring and analysis
    func startECGMonitoring() {
        isAnalysisActive = true
        analysisStatus = .active
        print("ECG Insight Manager: Started continuous monitoring")
        
        // Request HealthKit permissions for ECG data
        requestECGPermissions()
    }
    
    /// Stop ECG monitoring
    func stopECGMonitoring() {
        isAnalysisActive = false
        analysisStatus = .idle
        analysisTimer?.invalidate()
        print("ECG Insight Manager: Stopped monitoring")
    }
    
    /// Trigger immediate ECG analysis
    func triggerImmediateAnalysis() {
        guard isAnalysisActive else {
            print("ECG Insight Manager: Analysis not active")
            return
        }
        
        analysisStatus = .analyzing
        performECGAnalysis()
    }
    
    /// Get latest insights
    func getLatestInsights() -> [ECGInsight] {
        return currentInsights
    }
    
    /// Get insight by type
    func getInsight(for type: ECGInsightType) -> ECGInsight? {
        return currentInsights.first { $0.type == type }
    }
    
    /// Check if any critical insights are present
    func hasCriticalInsights() -> Bool {
        return currentInsights.contains { $0.severity == .critical }
    }
    
    // MARK: - Private Methods
    
    private func setupECGMonitoring() {
        // Set up HealthKit ECG data observation
        HealthDataManager.shared.$currentECGData
            .compactMap { $0 }
            .sink { [weak self] ecgData in
                self?.processECGData(ecgData)
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicAnalysis() {
        // Perform analysis every 5 minutes during active monitoring
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self, self.isAnalysisActive else { return }
            self.performECGAnalysis()
        }
    }
    
    private func requestECGPermissions() {
        // Request ECG permissions from HealthKit
        HealthDataManager.shared.requestECGPermissions { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("ECG Insight Manager: ECG permissions granted")
                } else {
                    print("ECG Insight Manager: ECG permissions denied")
                    self?.analysisStatus = .permissionDenied
                }
            }
        }
    }
    
    private func processECGData(_ ecgData: ECGData) {
        guard isAnalysisActive else { return }
        
        // Process raw ECG data
        let processedData = ecgDataProcessor.processECGData(ecgData)
        
        // Store processed data for analysis
        storeProcessedECGData(processedData)
        
        // Trigger analysis if we have sufficient data
        if shouldTriggerAnalysis() {
            performECGAnalysis()
        }
    }
    
    private func performECGAnalysis() {
        guard isAnalysisActive else { return }
        
        analysisStatus = .analyzing
        print("ECG Insight Manager: Starting ECG analysis...")
        
        // Get recent ECG data for analysis
        let recentECGData = getRecentECGData()
        
        // Perform parallel analysis on different aspects
        let analysisGroup = DispatchGroup()
        var newInsights: [ECGInsight] = []
        
        // Beat Morphology Analysis
        analysisGroup.enter()
        beatMorphologyAnalyzer.analyzeBeatMorphology(ecgData: recentECGData) { [weak self] result in
            defer { analysisGroup.leave() }
            
            switch result {
            case .success(let insight):
                newInsights.append(insight)
            case .failure(let error):
                print("ECG Insight Manager: Beat morphology analysis failed: \(error)")
            }
        }
        
        // HR Turbulence Analysis
        analysisGroup.enter()
        hrtTurbulenceCalculator.calculateHRTurbulence(ecgData: recentECGData) { [weak self] result in
            defer { analysisGroup.leave() }
            
            switch result {
            case .success(let insight):
                newInsights.append(insight)
            case .failure(let error):
                print("ECG Insight Manager: HR turbulence analysis failed: \(error)")
            }
        }
        
        // QT Dynamic Analysis
        analysisGroup.enter()
        qtDynamicAnalyzer.analyzeQTDynamics(ecgData: recentECGData) { [weak self] result in
            defer { analysisGroup.leave() }
            
            switch result {
            case .success(let insight):
                newInsights.append(insight)
            case .failure(let error):
                print("ECG Insight Manager: QT dynamic analysis failed: \(error)")
            }
        }
        
        // ST Segment Analysis
        analysisGroup.enter()
        stSegmentAnalyzer.analyzeSTSegments(ecgData: recentECGData) { [weak self] result in
            defer { analysisGroup.leave() }
            
            switch result {
            case .success(let insight):
                newInsights.append(insight)
            case .failure(let error):
                print("ECG Insight Manager: ST segment analysis failed: \(error)")
            }
        }
        
        // AF Forecast Analysis
        analysisGroup.enter()
        performAFForecastAnalysis(ecgData: recentECGData) { [weak self] result in
            defer { analysisGroup.leave() }
            
            switch result {
            case .success(let insight):
                newInsights.append(insight)
            case .failure(let error):
                print("ECG Insight Manager: AF forecast analysis failed: \(error)")
            }
        }
        
        // Update insights when all analysis is complete
        analysisGroup.notify(queue: .main) { [weak self] in
            self?.updateInsights(newInsights)
            self?.analysisStatus = .completed
            self?.lastAnalysisTime = Date()
            print("ECG Insight Manager: Analysis completed with \(newInsights.count) insights")
        }
    }
    
    private func performAFForecastAnalysis(ecgData: ProcessedECGData, completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        // Extract AF-specific features
        afFeatureExtractor.extractAFFeatures(ecgData: ecgData) { [weak self] result in
            switch result {
            case .success(let features):
                // Run AF forecast model
                self?.afForecastModel.predictAFRisk(features: features) { result in
                    switch result {
                    case .success(let prediction):
                        let insight = ECGInsight(
                            type: .atrialFibrillationForecast,
                            severity: prediction.riskLevel,
                            confidence: prediction.confidence,
                            description: "AF conversion risk: \(prediction.riskDescription)",
                            timestamp: Date(),
                            data: prediction
                        )
                        completion(.success(insight))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateInsights(_ newInsights: [ECGInsight]) {
        // Merge new insights with existing ones, replacing by type
        var updatedInsights = currentInsights.filter { existingInsight in
            !newInsights.contains { $0.type == existingInsight.type }
        }
        updatedInsights.append(contentsOf: newInsights)
        
        // Sort by severity and timestamp
        updatedInsights.sort { first, second in
            if first.severity.rawValue != second.severity.rawValue {
                return first.severity.rawValue > second.severity.rawValue
            }
            return first.timestamp > second.timestamp
        }
        
        currentInsights = updatedInsights
        
        // Check for critical insights that need immediate attention
        let criticalInsights = newInsights.filter { $0.severity == .critical }
        if !criticalInsights.isEmpty {
            handleCriticalInsights(criticalInsights)
        }
    }
    
    private func handleCriticalInsights(_ insights: [ECGInsight]) {
        print("ECG Insight Manager: Critical insights detected: \(insights.count)")
        
        // Trigger emergency alert system
        for insight in insights {
            switch insight.type {
            case .stSegmentShift:
                // Immediate action for ST segment changes
                triggerEmergencyAlert(for: insight)
            case .beatMorphology:
                // High ischemic risk
                triggerUrgentAlert(for: insight)
            default:
                // Other critical insights
                triggerUrgentAlert(for: insight)
            }
        }
    }
    
    private func triggerEmergencyAlert(for insight: ECGInsight) {
        // Trigger immediate ECG capture and EMS suggestion
        EmergencyAlertManager.shared.triggerEmergencyAlert(
            type: .ecgCritical,
            description: insight.description,
            severity: insight.severity
        )
    }
    
    private func triggerUrgentAlert(for insight: ECGInsight) {
        // Trigger urgent but non-emergency alert
        EmergencyAlertManager.shared.triggerUrgentAlert(
            type: .ecgUrgent,
            description: insight.description,
            severity: insight.severity
        )
    }
    
    private func shouldTriggerAnalysis() -> Bool {
        // Trigger analysis if we have sufficient ECG data
        // For M2, this is simplified - in production, this would be more sophisticated
        return getRecentECGData().duration >= 30 // At least 30 seconds of data
    }
    
    private func getRecentECGData() -> ProcessedECGData {
        // Get recent ECG data for analysis
        // This would typically come from a data store or cache
        return ProcessedECGData(
            samples: [], // Placeholder
            duration: 60,
            timestamp: Date(),
            quality: .good
        )
    }
    
    private func storeProcessedECGData(_ data: ProcessedECGData) {
        // Store processed ECG data for analysis
        // In a real implementation, this would be stored in a database or cache
        print("ECG Insight Manager: Stored processed ECG data")
    }
}

// MARK: - Supporting Types

enum AnalysisStatus {
    case idle
    case active
    case analyzing
    case completed
    case error
    case permissionDenied
}

enum ECGInsightType: String, CaseIterable {
    case beatMorphology = "Beat Morphology"
    case hrTurbulence = "HR Turbulence"
    case qtDynamics = "QT Dynamics"
    case stSegmentShift = "ST Segment Shift"
    case atrialFibrillationForecast = "AF Forecast"
}

enum InsightSeverity: Int, CaseIterable {
    case normal = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case critical = 4
    
    var description: String {
        switch self {
        case .normal: return "Normal"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        case .critical: return "Critical"
        }
    }
}

struct ECGInsight: Identifiable, Codable {
    let id = UUID()
    let type: ECGInsightType
    let severity: InsightSeverity
    let confidence: Double
    let description: String
    let timestamp: Date
    let data: AnyCodable // Generic data storage for insight-specific information
}

// MARK: - Placeholder Types (to be implemented)

struct ECGData {
    let samples: [Double]
    let timestamp: Date
    let duration: TimeInterval
}

struct ProcessedECGData {
    let samples: [Double]
    let duration: TimeInterval
    let timestamp: Date
    let quality: DataQuality
}

enum DataQuality {
    case poor
    case fair
    case good
    case excellent
}

// Generic codable wrapper for storing any data type
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        // Simplified implementation for M2
        self.value = ""
    }
    
    func encode(to encoder: Encoder) throws {
        // Simplified implementation for M2
    }
}