import Foundation
import Combine
import CoreML
import HealthKit

open class ECGInsightManager: ObservableObject { // Changed to 'open'
    public static let shared = ECGInsightManager()
    
    // MARK: - Published Properties
    @Published open var currentInsights: [ECGInsight] = [] // Changed to 'open'
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
    
    public init() { // Made init public for mocking
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
    
    private func updateInsights(_ insights: [ECGInsight]) {
        // Merge new insights, prioritize critical, remove duplicates by type
        var merged: [ECGInsight] = []
        for insight in insights {
            if let idx = merged.firstIndex(where: { $0.type == insight.type }) {
                // Prefer higher severity
                if insight.severity.rawValue > merged[idx].severity.rawValue {
                    merged[idx] = insight
                }
            } else {
                merged.append(insight)
            }
        }
        currentInsights = merged.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    private func performAFForecastAnalysis(ecgData: [ProcessedECGData], completion: @escaping (Result<ECGInsight, Error>) -> Void) {
        // Extract features and run AF forecast model
        let features = afFeatureExtractor.extractFeatures(from: ecgData)
        afForecastModel.predictAFRisk(features: features) { result in
            switch result {
            case .success(let risk):
                let insight = ECGInsight(type: .afForecast, severity: risk > 0.7 ? .critical : .warning, message: "AF risk: \(Int(risk * 100))%", timestamp: Date())
                completion(.success(insight))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func shouldTriggerAnalysis() -> Bool {
        // Trigger if enough new data or a critical event is detected
        return ecgDataProcessor.hasSufficientDataForAnalysis()
    }
    
    private func getRecentECGData() -> [ProcessedECGData] {
        return ecgDataProcessor.getRecentProcessedData()
    }
    
    private func storeProcessedECGData(_ data: ProcessedECGData) {
        // Store processed ECG data for rolling analysis window
        // (Implement a ring buffer or capped array for efficiency)
        // For now, just append to a static array in the processor
        ecgDataProcessor.appendProcessedData(data)
    }
}

// MARK: - Supporting Types (Stubs for Compilation)

enum AnalysisStatus: Int { case idle, active, analyzing, completed, permissionDenied }
struct ECGInsight: Identifiable { let id = UUID(); let type: ECGInsightType; let severity: InsightSeverity; let message: String; let timestamp: Date }
enum ECGInsightType { case beatMorphology, hrtTurbulence, qtDynamics, stSegment, afForecast }
// Removed duplicate declaration of InsightSeverity
struct ECGData {}
struct ProcessedECGData {}
class ECGDataProcessor {
    private var buffer: [ProcessedECGData] = []
    func processECGData(_ data: ECGData) -> ProcessedECGData { ProcessedECGData() }
    func appendProcessedData(_ data: ProcessedECGData) { buffer.append(data); if buffer.count > 1000 { buffer.removeFirst() } }
    func hasSufficientDataForAnalysis() -> Bool { buffer.count > 10 }
    func getRecentProcessedData() -> [ProcessedECGData] { Array(buffer.suffix(20)) }
}
class BeatMorphologyAnalyzer { func analyzeBeatMorphology(ecgData: [ProcessedECGData], completion: @escaping (Result<ECGInsight, Error>) -> Void) { completion(.success(ECGInsight(type: .beatMorphology, severity: .info, message: "Normal morphology", timestamp: Date()))) } }
class HRTurbulenceCalculator { func calculateHRTurbulence(ecgData: [ProcessedECGData], completion: @escaping (Result<ECGInsight, Error>) -> Void) { completion(.success(ECGInsight(type: .hrtTurbulence, severity: .info, message: "Normal HR Turbulence", timestamp: Date()))) } }
class QTDynamicAnalyzer { func analyzeQTDynamics(ecgData: [ProcessedECGData], completion: @escaping (Result<ECGInsight, Error>) -> Void) { completion(.success(ECGInsight(type: .qtDynamics, severity: .info, message: "Normal QT Dynamics", timestamp: Date()))) } }
class STSegmentAnalyzer { func analyzeSTSegments(ecgData: [ProcessedECGData], completion: @escaping (Result<ECGInsight, Error>) -> Void) { completion(.success(ECGInsight(type: .stSegment, severity: .info, message: "Normal ST Segment", timestamp: Date()))) } }
class AFForecastModel { func predictAFRisk(features: [Double], completion: @escaping (Result<Double, Error>) -> Void) { completion(.success(Double.random(in: 0...1))) } }
class AFFeatureExtractor { func extractFeatures(from: [ProcessedECGData]) -> [Double] { [Double.random(in: 0...1), Double.random(in: 0...1)] } }
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
class HealthDataManager: ObservableObject {
    static let shared = HealthDataManager()
    @Published var currentECGData: ECGData? = nil
    
    private var rawSensorData: [SensorData] = [] // To store raw sensor data
    private let maxRawSensorDataSize = 1000 // Limit to prevent memory leaks

    func requestECGPermissions(_ completion: @escaping (Bool) -> Void) {
        completion(true)
    }

    func addRawSensorData(_ data: SensorData) {
        rawSensorData.append(data)
        limitRawSensorData()
    }

    private func limitRawSensorData() {
        if rawSensorData.count > maxRawSensorDataSize {
            rawSensorData.removeFirst(rawSensorData.count - maxRawSensorDataSize)
        }
    }
}

struct SensorData {} // Placeholder for actual sensor data structure