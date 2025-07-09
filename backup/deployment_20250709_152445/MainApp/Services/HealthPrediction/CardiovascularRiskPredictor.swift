import Foundation
import CoreML
import HealthKit
import Combine

/// Comprehensive cardiovascular risk prediction engine using CoreML and clinical risk calculators
@MainActor
public class CardiovascularRiskPredictor: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var currentRiskScore: Double = 0.0
    @Published public var riskTrend: RiskTrend = .stable
    @Published public var riskFactors: [RiskFactor] = []
    @Published public var recommendations: [HealthRecommendation] = []
    @Published public var isCalculating: Bool = false
    
    // MARK: - Private Properties
    private var healthStore: HKHealthStore?
    private var riskModel: MLModel?
    private var cancellables = Set<AnyCancellable>()
    private let riskCalculator = ClinicalRiskCalculator()
    
    // MARK: - Risk Assessment Models
    public enum RiskModel: String, CaseIterable {
        case framingham = "Framingham"
        case ascvd = "ASCVD"
        case reynolds = "Reynolds"
        case qrisk = "QRISK"
    }
    
    public enum RiskTrend: String, CaseIterable {
        case improving = "Improving"
        case stable = "Stable"
        case worsening = "Worsening"
        case critical = "Critical"
    }
    
    public struct RiskFactor: Identifiable, Codable {
        public let id = UUID()
        public let name: String
        public let value: Double
        public let unit: String
        public let impact: Double // 0.0 to 1.0, how much this factor contributes to risk
        public let category: RiskCategory
        public let isModifiable: Bool
        
        public enum RiskCategory: String, CaseIterable, Codable {
            case age = "Age"
            case gender = "Gender"
            case bloodPressure = "Blood Pressure"
            case cholesterol = "Cholesterol"
            case diabetes = "Diabetes"
            case smoking = "Smoking"
            case familyHistory = "Family History"
            case lifestyle = "Lifestyle"
            case other = "Other"
        }
    }
    
    public struct HealthRecommendation: Identifiable, Codable {
        public let id = UUID()
        public let title: String
        public let description: String
        public let priority: Priority
        public let category: RecommendationCategory
        public let evidenceLevel: EvidenceLevel
        public let estimatedImpact: Double // 0.0 to 1.0, estimated impact on risk reduction
        
        public enum Priority: String, CaseIterable, Codable {
            case critical = "Critical"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
        }
        
        public enum RecommendationCategory: String, CaseIterable, Codable {
            case lifestyle = "Lifestyle"
            case medication = "Medication"
            case monitoring = "Monitoring"
            case screening = "Screening"
            case referral = "Referral"
        }
        
        public enum EvidenceLevel: String, CaseIterable, Codable {
            case a = "Level A"
            case b = "Level B"
            case c = "Level C"
        }
    }
    
    // MARK: - Initialization
    public init() {
        setupHealthKit()
        loadRiskModel()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Calculate cardiovascular risk using multiple models and clinical data
    public func calculateRisk() async throws -> Double {
        isCalculating = true
        defer { isCalculating = false }
        
        let healthData = try await fetchHealthData()
        let riskScores = try await calculateMultipleRiskScores(healthData: healthData)
        
        // Combine risk scores using weighted average
        let combinedScore = combineRiskScores(riskScores)
        
        // Update published properties
        await MainActor.run {
            self.currentRiskScore = combinedScore
            self.riskTrend = calculateRiskTrend(score: combinedScore)
            self.riskFactors = extractRiskFactors(healthData: healthData)
            self.recommendations = generateRecommendations(riskFactors: self.riskFactors, score: combinedScore)
        }
        
        return combinedScore
    }
    
    /// Get risk prediction for specific time period
    public func predictRiskTrend(months: Int = 12) async throws -> [Double] {
        let historicalData = try await fetchHistoricalHealthData(months: months)
        return try await predictFutureRisk(historicalData: historicalData, months: months)
    }
    
    /// Get detailed risk factor analysis
    public func analyzeRiskFactors() async throws -> [RiskFactor] {
        let healthData = try await fetchHealthData()
        return extractRiskFactors(healthData: healthData)
    }
    
    /// Generate personalized health recommendations
    public func generatePersonalizedRecommendations() async throws -> [HealthRecommendation] {
        let riskFactors = try await analyzeRiskFactors()
        let currentScore = await currentRiskScore
        return generateRecommendations(riskFactors: riskFactors, score: currentScore)
    }
    
    // MARK: - Private Methods
    
    private func setupHealthKit() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    private func loadRiskModel() {
        // Load CoreML model for risk prediction
        // In a real implementation, this would load a trained CoreML model
        // For now, we'll use clinical calculators
    }
    
    private func setupObservers() {
        // Observe health data changes and recalculate risk
        NotificationCenter.default.publisher(for: .healthDataDidUpdate)
            .sink { [weak self] _ in
                Task {
                    try? await self?.calculateRisk()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchHealthData() async throws -> HealthData {
        guard let healthStore = healthStore else {
            throw CardiovascularRiskError.healthKitNotAvailable
        }
        
        // Request authorization for required data types
        let dataTypes = Set([
            HKObjectType.quantityType(forIdentifier: .systolicBloodPressure)!,
            HKObjectType.quantityType(forIdentifier: .diastolicBloodPressure)!,
            HKObjectType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKObjectType.quantityType(forIdentifier: .height)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .bloodGlucose)!,
            HKObjectType.quantityType(forIdentifier: .totalCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .hdlCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .ldlCholesterol)!,
            HKObjectType.quantityType(forIdentifier: .triglycerides)!
        ])
        
        try await healthStore.requestAuthorization(toShare: nil, read: dataTypes)
        
        // Fetch latest health data
        return try await fetchLatestHealthData(healthStore: healthStore)
    }
    
    private func fetchLatestHealthData(healthStore: HKHealthStore) async throws -> HealthData {
        // Implementation to fetch latest health data from HealthKit
        // This would include blood pressure, cholesterol, BMI, etc.
        
        // For now, return mock data
        return HealthData(
            age: 45,
            gender: .male,
            systolicBP: 140,
            diastolicBP: 90,
            totalCholesterol: 220,
            hdlCholesterol: 45,
            ldlCholesterol: 150,
            triglycerides: 180,
            bmi: 28.5,
            isSmoker: false,
            hasDiabetes: false,
            familyHistory: true,
            restingHeartRate: 72,
            bloodGlucose: 95
        )
    }
    
    private func fetchHistoricalHealthData(months: Int) async throws -> [HealthData] {
        // Fetch historical health data for trend analysis
        // This would include data points over the specified time period
        
        // For now, return mock historical data
        return (0..<months).map { month in
            HealthData(
                age: 45,
                gender: .male,
                systolicBP: 140 + Int.random(in: -10...10),
                diastolicBP: 90 + Int.random(in: -5...5),
                totalCholesterol: 220 + Int.random(in: -20...20),
                hdlCholesterol: 45 + Int.random(in: -5...5),
                ldlCholesterol: 150 + Int.random(in: -15...15),
                triglycerides: 180 + Int.random(in: -30...30),
                bmi: 28.5 + Double.random(in: -2...2),
                isSmoker: false,
                hasDiabetes: false,
                familyHistory: true,
                restingHeartRate: 72 + Int.random(in: -5...5),
                bloodGlucose: 95 + Int.random(in: -10...10)
            )
        }
    }
    
    private func calculateMultipleRiskScores(healthData: HealthData) async throws -> [RiskModel: Double] {
        var riskScores: [RiskModel: Double] = [:]
        
        // Calculate Framingham Risk Score
        riskScores[.framingham] = try riskCalculator.calculateFraminghamRisk(healthData: healthData)
        
        // Calculate ASCVD Risk Score
        riskScores[.ascvd] = try riskCalculator.calculateASCVDRisk(healthData: healthData)
        
        // Calculate Reynolds Risk Score
        riskScores[.reynolds] = try riskCalculator.calculateReynoldsRisk(healthData: healthData)
        
        // Calculate QRISK Score
        riskScores[.qrisk] = try riskCalculator.calculateQRISKRisk(healthData: healthData)
        
        return riskScores
    }
    
    private func combineRiskScores(_ riskScores: [RiskModel: Double]) -> Double {
        // Weight the different risk scores based on clinical evidence
        let weights: [RiskModel: Double] = [
            .ascvd: 0.4,      // Most widely used in US
            .framingham: 0.3, // Traditional standard
            .qrisk: 0.2,      // UK standard, good for diverse populations
            .reynolds: 0.1    // Additional factor consideration
        ]
        
        let weightedSum = riskScores.reduce(0.0) { sum, entry in
            sum + (entry.value * weights[entry.key, default: 0.0])
        }
        
        return weightedSum
    }
    
    private func calculateRiskTrend(score: Double) -> RiskTrend {
        // Compare current score with historical trend
        // For now, use simple thresholds
        switch score {
        case 0..<0.05:
            return .improving
        case 0.05..<0.10:
            return .stable
        case 0.10..<0.20:
            return .worsening
        default:
            return .critical
        }
    }
    
    private func extractRiskFactors(healthData: HealthData) -> [RiskFactor] {
        var factors: [RiskFactor] = []
        
        // Age factor
        factors.append(RiskFactor(
            name: "Age",
            value: Double(healthData.age),
            unit: "years",
            impact: calculateAgeImpact(age: healthData.age),
            category: .age,
            isModifiable: false
        ))
        
        // Blood pressure factors
        factors.append(RiskFactor(
            name: "Systolic Blood Pressure",
            value: Double(healthData.systolicBP),
            unit: "mmHg",
            impact: calculateBPImpact(systolic: healthData.systolicBP, diastolic: healthData.diastolicBP),
            category: .bloodPressure,
            isModifiable: true
        ))
        
        // Cholesterol factors
        factors.append(RiskFactor(
            name: "Total Cholesterol",
            value: Double(healthData.totalCholesterol),
            unit: "mg/dL",
            impact: calculateCholesterolImpact(total: healthData.totalCholesterol, hdl: healthData.hdlCholesterol),
            category: .cholesterol,
            isModifiable: true
        ))
        
        // BMI factor
        factors.append(RiskFactor(
            name: "Body Mass Index",
            value: healthData.bmi,
            unit: "kg/m²",
            impact: calculateBMIImpact(bmi: healthData.bmi),
            category: .lifestyle,
            isModifiable: true
        ))
        
        // Family history
        if healthData.familyHistory {
            factors.append(RiskFactor(
                name: "Family History",
                value: 1.0,
                unit: "Yes/No",
                impact: 0.15,
                category: .familyHistory,
                isModifiable: false
            ))
        }
        
        return factors.sorted { $0.impact > $1.impact }
    }
    
    private func generateRecommendations(riskFactors: [RiskFactor], score: Double) -> [HealthRecommendation] {
        var recommendations: [HealthRecommendation] = []
        
        // High priority recommendations for high risk
        if score > 0.15 {
            recommendations.append(HealthRecommendation(
                title: "Consult Healthcare Provider",
                description: "Your cardiovascular risk is elevated. Schedule an appointment with your healthcare provider for a comprehensive evaluation.",
                priority: .critical,
                category: .referral,
                evidenceLevel: .a,
                estimatedImpact: 0.8
            ))
        }
        
        // Blood pressure recommendations
        if let bpFactor = riskFactors.first(where: { $0.category == .bloodPressure && $0.impact > 0.1 }) {
            recommendations.append(HealthRecommendation(
                title: "Blood Pressure Management",
                description: "Your blood pressure is contributing to cardiovascular risk. Consider lifestyle changes and medication if prescribed.",
                priority: .high,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.6
            ))
        }
        
        // Cholesterol recommendations
        if let cholesterolFactor = riskFactors.first(where: { $0.category == .cholesterol && $0.impact > 0.1 }) {
            recommendations.append(HealthRecommendation(
                title: "Cholesterol Management",
                description: "Your cholesterol levels are contributing to cardiovascular risk. Focus on heart-healthy diet and exercise.",
                priority: .high,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.5
            ))
        }
        
        // BMI recommendations
        if let bmiFactor = riskFactors.first(where: { $0.category == .lifestyle && $0.name == "Body Mass Index" && $0.value > 25 }) {
            recommendations.append(HealthRecommendation(
                title: "Weight Management",
                description: "Your BMI indicates overweight status. Consider weight loss through diet and exercise to reduce cardiovascular risk.",
                priority: .medium,
                category: .lifestyle,
                evidenceLevel: .a,
                estimatedImpact: 0.4
            ))
        }
        
        // General lifestyle recommendations
        recommendations.append(HealthRecommendation(
            title: "Regular Exercise",
            description: "Aim for at least 150 minutes of moderate-intensity exercise per week to improve cardiovascular health.",
            priority: .medium,
            category: .lifestyle,
            evidenceLevel: .a,
            estimatedImpact: 0.3
        ))
        
        recommendations.append(HealthRecommendation(
            title: "Heart-Healthy Diet",
            description: "Follow a diet rich in fruits, vegetables, whole grains, and lean proteins. Limit saturated fats and sodium.",
            priority: .medium,
            category: .lifestyle,
            evidenceLevel: .a,
            estimatedImpact: 0.3
        ))
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func predictFutureRisk(historicalData: [HealthData], months: Int) async throws -> [Double] {
        // Use time series analysis to predict future risk
        // This would involve machine learning models trained on historical data
        
        // For now, use simple linear extrapolation
        let currentRisk = await currentRiskScore
        let trend = await riskTrend
        
        let monthlyChange: Double
        switch trend {
        case .improving:
            monthlyChange = -0.005
        case .stable:
            monthlyChange = 0.0
        case .worsening:
            monthlyChange = 0.005
        case .critical:
            monthlyChange = 0.01
        }
        
        return (0..<months).map { month in
            max(0.0, min(1.0, currentRisk + (monthlyChange * Double(month))))
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateAgeImpact(age: Int) -> Double {
        // Age impact increases with age
        return min(1.0, Double(age - 30) / 50.0)
    }
    
    private func calculateBPImpact(systolic: Int, diastolic: Int) -> Double {
        // Higher blood pressure = higher impact
        let systolicImpact = max(0.0, Double(systolic - 120) / 80.0)
        let diastolicImpact = max(0.0, Double(diastolic - 80) / 40.0)
        return min(1.0, (systolicImpact + diastolicImpact) / 2.0)
    }
    
    private func calculateCholesterolImpact(total: Int, hdl: Int) -> Double {
        // Higher total cholesterol and lower HDL = higher impact
        let totalImpact = max(0.0, Double(total - 200) / 100.0)
        let hdlImpact = max(0.0, Double(60 - hdl) / 40.0)
        return min(1.0, (totalImpact + hdlImpact) / 2.0)
    }
    
    private func calculateBMIImpact(bmi: Double) -> Double {
        // BMI impact increases with higher BMI
        return min(1.0, max(0.0, (bmi - 18.5) / 20.0))
    }
}

// MARK: - Supporting Types

public struct HealthData: Codable {
    let age: Int
    let gender: Gender
    let systolicBP: Int
    let diastolicBP: Int
    let totalCholesterol: Int
    let hdlCholesterol: Int
    let ldlCholesterol: Int
    let triglycerides: Int
    let bmi: Double
    let isSmoker: Bool
    let hasDiabetes: Bool
    let familyHistory: Bool
    let restingHeartRate: Int
    let bloodGlucose: Int
    
    enum Gender: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
}

public enum CardiovascularRiskError: Error, LocalizedError {
    case healthKitNotAvailable
    case insufficientData
    case modelLoadFailed
    case calculationError
    
    public var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .insufficientData:
            return "Insufficient health data for risk calculation"
        case .modelLoadFailed:
            return "Failed to load risk prediction model"
        case .calculationError:
            return "Error during risk calculation"
        }
    }
}

// MARK: - Clinical Risk Calculator

private class ClinicalRiskCalculator {
    
    func calculateFraminghamRisk(healthData: HealthData) throws -> Double {
        // Implement Framingham Risk Score calculation
        // This is a simplified version - real implementation would be more complex
        
        var score = 0.0
        
        // Age factor
        score += Double(healthData.age - 30) * 0.01
        
        // Gender factor
        if healthData.gender == .male {
            score += 0.1
        }
        
        // Blood pressure factor
        if healthData.systolicBP >= 140 {
            score += 0.2
        }
        
        // Cholesterol factor
        if healthData.totalCholesterol >= 240 {
            score += 0.15
        }
        
        // Smoking factor
        if healthData.isSmoker {
            score += 0.25
        }
        
        // Diabetes factor
        if healthData.hasDiabetes {
            score += 0.3
        }
        
        return min(1.0, max(0.0, score))
    }
    
    func calculateASCVDRisk(healthData: HealthData) throws -> Double {
        // Implement ASCVD Risk Score calculation
        // This is a simplified version - real implementation would use the full ASCVD calculator
        
        var score = 0.0
        
        // Age factor (more weight for older age)
        score += Double(healthData.age - 40) * 0.015
        
        // Gender factor
        if healthData.gender == .male {
            score += 0.15
        }
        
        // Blood pressure factor
        if healthData.systolicBP >= 140 {
            score += 0.25
        }
        
        // Cholesterol factor
        if healthData.totalCholesterol >= 240 {
            score += 0.2
        }
        
        // HDL factor
        if healthData.hdlCholesterol < 40 {
            score += 0.15
        }
        
        // Smoking factor
        if healthData.isSmoker {
            score += 0.3
        }
        
        // Diabetes factor
        if healthData.hasDiabetes {
            score += 0.35
        }
        
        return min(1.0, max(0.0, score))
    }
    
    func calculateReynoldsRisk(healthData: HealthData) throws -> Double {
        // Implement Reynolds Risk Score calculation
        // This includes additional factors like hsCRP
        
        var score = 0.0
        
        // Base factors similar to Framingham
        score += Double(healthData.age - 30) * 0.008
        
        if healthData.gender == .male {
            score += 0.08
        }
        
        if healthData.systolicBP >= 140 {
            score += 0.18
        }
        
        if healthData.totalCholesterol >= 240 {
            score += 0.12
        }
        
        if healthData.isSmoker {
            score += 0.22
        }
        
        // Additional Reynolds factors (simplified)
        if healthData.familyHistory {
            score += 0.1
        }
        
        return min(1.0, max(0.0, score))
    }
    
    func calculateQRISKRisk(healthData: HealthData) throws -> Double {
        // Implement QRISK Score calculation
        // This is a UK-based risk calculator with additional factors
        
        var score = 0.0
        
        // Age factor
        score += Double(healthData.age - 30) * 0.012
        
        // Gender factor
        if healthData.gender == .male {
            score += 0.12
        }
        
        // Blood pressure factor
        if healthData.systolicBP >= 140 {
            score += 0.2
        }
        
        // Cholesterol factor
        if healthData.totalCholesterol >= 240 {
            score += 0.18
        }
        
        // BMI factor
        if healthData.bmi >= 30 {
            score += 0.15
        }
        
        // Smoking factor
        if healthData.isSmoker {
            score += 0.28
        }
        
        // Diabetes factor
        if healthData.hasDiabetes {
            score += 0.32
        }
        
        // Family history
        if healthData.familyHistory {
            score += 0.08
        }
        
        return min(1.0, max(0.0, score))
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let healthDataDidUpdate = Notification.Name("healthDataDidUpdate")
} 