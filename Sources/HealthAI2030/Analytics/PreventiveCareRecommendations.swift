//
//  PreventiveCareRecommendations.swift
//  HealthAI 2030
//
//  Created by Agent 6 (Analytics) on 2025-01-31
//  Preventive care optimization system
//

import Foundation
import Combine
import HealthKit

/// Preventive care optimization and recommendation system
public class PreventiveCareRecommendations: ObservableObject {
    
    // MARK: - Properties
    
    @Published public var activeRecommendations: [PreventiveCareRecommendation] = []
    @Published public var preventionPlans: [PreventionPlan] = []
    @Published public var riskAssessments: [RiskAssessment] = []
    @Published public var isAnalyzing: Bool = false
    
    private let riskCalculator: RiskCalculator
    private let guidelinesEngine: ClinicalGuidelinesEngine
    private let evidenceEngine: EvidenceBasedEngine
    private let costEffectivenessAnalyzer: CostEffectivenessAnalyzer
    
    private var cancellables = Set<AnyCancellable>()
    
    // Prevention categories
    private let preventionCategories = [
        "screening", "vaccination", "lifestyle", "medication", "monitoring", "counseling"
    ]
    
    // MARK: - Initialization
    
    public init() {
        self.riskCalculator = RiskCalculator()
        self.guidelinesEngine = ClinicalGuidelinesEngine()
        self.evidenceEngine = EvidenceBasedEngine()
        self.costEffectivenessAnalyzer = CostEffectivenessAnalyzer()
        
        setupPreventiveCare()
    }
    
    // MARK: - Core Recommendation Methods
    
    /// Generate comprehensive preventive care recommendations
    public func generatePreventiveCareRecommendations(
        for patient: PatientProfile,
        preferences: PatientPreferences? = nil
    ) async throws -> [PreventiveCareRecommendation] {
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Assess patient risks
        let riskAssessment = try await assessPatientRisks(patient)
        
        // Get applicable guidelines
        let guidelines = try await guidelinesEngine.getApplicableGuidelines(for: patient)
        
        // Generate screening recommendations
        let screeningRecs = try await generateScreeningRecommendations(patient, riskAssessment, guidelines)
        
        // Generate vaccination recommendations
        let vaccinationRecs = try await generateVaccinationRecommendations(patient, guidelines)
        
        // Generate lifestyle recommendations
        let lifestyleRecs = try await generateLifestyleRecommendations(patient, riskAssessment)
        
        // Generate medication recommendations
        let medicationRecs = try await generateMedicationRecommendations(patient, riskAssessment)
        
        // Generate monitoring recommendations
        let monitoringRecs = try await generateMonitoringRecommendations(patient, riskAssessment)
        
        // Generate counseling recommendations
        let counselingRecs = try await generateCounselingRecommendations(patient, riskAssessment)
        
        // Combine all recommendations
        var allRecommendations = screeningRecs + vaccinationRecs + lifestyleRecs + 
                               medicationRecs + monitoringRecs + counselingRecs
        
        // Prioritize recommendations
        allRecommendations = prioritizeRecommendations(allRecommendations, patient: patient)
        
        // Apply patient preferences if provided
        if let preferences = preferences {
            allRecommendations = applyPatientPreferences(allRecommendations, preferences: preferences)
        }
        
        // Perform cost-effectiveness analysis
        allRecommendations = try await analyzeCostEffectiveness(allRecommendations, patient: patient)
        
        // Update active recommendations
        await MainActor.run {
            self.activeRecommendations = allRecommendations
            self.riskAssessments.append(riskAssessment)
        }
        
        return allRecommendations
    }
    
    /// Create personalized prevention plan
    public func createPreventionPlan(
        for patient: PatientProfile,
        timeFrame: TimeFrame = .oneYear
    ) async throws -> PreventionPlan {
        
        // Generate recommendations
        let recommendations = try await generatePreventiveCareRecommendations(for: patient)
        
        // Create timeline
        let timeline = createPreventionTimeline(recommendations, timeFrame: timeFrame)
        
        // Calculate cost projections
        let costProjections = calculateCostProjections(recommendations, timeFrame: timeFrame)
        
        // Estimate health outcomes
        let outcomeProjections = try await estimateHealthOutcomes(recommendations, patient: patient)
        
        // Generate follow-up schedule
        let followUpSchedule = createFollowUpSchedule(recommendations, timeFrame: timeFrame)
        
        let plan = PreventionPlan(
            id: UUID(),
            patient: patient,
            recommendations: recommendations,
            timeline: timeline,
            costProjections: costProjections,
            outcomeProjections: outcomeProjections,
            followUpSchedule: followUpSchedule,
            timeFrame: timeFrame,
            createdDate: Date()
        )
        
        await MainActor.run {
            self.preventionPlans.append(plan)
        }
        
        return plan
    }
    
    /// Update recommendations based on new data
    public func updateRecommendations(
        for patient: PatientProfile,
        newData: HealthData
    ) async throws -> [PreventiveCareRecommendation] {
        
        // Update risk assessment with new data
        let updatedRiskAssessment = try await updateRiskAssessment(patient, newData: newData)
        
        // Re-evaluate recommendations
        let updatedRecommendations = try await generatePreventiveCareRecommendations(for: patient)
        
        // Identify changes
        let changes = identifyRecommendationChanges(
            current: activeRecommendations,
            updated: updatedRecommendations
        )
        
        // Notify about significant changes
        if !changes.significant.isEmpty {
            await notifySignificantChanges(changes.significant, patient: patient)
        }
        
        return updatedRecommendations
    }
    
    // MARK: - Risk Assessment
    
    /// Assess comprehensive patient risks
    private func assessPatientRisks(_ patient: PatientProfile) async throws -> RiskAssessment {
        
        // Calculate cardiovascular risk
        let cvRisk = try await riskCalculator.calculateCardiovascularRisk(patient)
        
        // Calculate cancer risks
        let cancerRisks = try await riskCalculator.calculateCancerRisks(patient)
        
        // Calculate diabetes risk
        let diabetesRisk = try await riskCalculator.calculateDiabetesRisk(patient)
        
        // Calculate osteoporosis risk
        let osteoporosisRisk = try await riskCalculator.calculateOsteoporosisRisk(patient)
        
        // Calculate infectious disease risks
        let infectiousRisks = try await riskCalculator.calculateInfectiousRisks(patient)
        
        // Calculate overall health risks
        let overallRisk = calculateOverallHealthRisk([cvRisk, diabetesRisk, osteoporosisRisk])
        
        return RiskAssessment(
            patient: patient,
            cardiovascularRisk: cvRisk,
            cancerRisks: cancerRisks,
            diabetesRisk: diabetesRisk,
            osteoporosisRisk: osteoporosisRisk,
            infectiousRisks: infectiousRisks,
            overallRisk: overallRisk,
            assessmentDate: Date()
        )
    }
    
    // MARK: - Specific Recommendation Generation
    
    /// Generate screening recommendations
    private func generateScreeningRecommendations(
        _ patient: PatientProfile,
        _ riskAssessment: RiskAssessment,
        _ guidelines: [ClinicalGuideline]
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Cancer screening
        let cancerScreenings = try await generateCancerScreeningRecommendations(patient, riskAssessment)
        recommendations.append(contentsOf: cancerScreenings)
        
        // Cardiovascular screening
        let cvScreenings = try await generateCardiovascularScreeningRecommendations(patient, riskAssessment)
        recommendations.append(contentsOf: cvScreenings)
        
        // Diabetes screening
        if shouldScreenForDiabetes(patient, riskAssessment) {
            let diabetesScreening = createDiabetesScreeningRecommendation(patient, riskAssessment)
            recommendations.append(diabetesScreening)
        }
        
        // Osteoporosis screening
        if shouldScreenForOsteoporosis(patient, riskAssessment) {
            let osteoporosisScreening = createOsteoporosisScreeningRecommendation(patient, riskAssessment)
            recommendations.append(osteoporosisScreening)
        }
        
        return recommendations
    }
    
    /// Generate vaccination recommendations
    private func generateVaccinationRecommendations(
        _ patient: PatientProfile,
        _ guidelines: [ClinicalGuideline]
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Get vaccination history
        let vaccinationHistory = patient.vaccinationHistory ?? []
        
        // Check routine adult vaccinations
        let routineVaccinations = getRoutineVaccinations(for: patient.age)
        
        for vaccination in routineVaccinations {
            if !isVaccinationUpToDate(vaccination, history: vaccinationHistory) {
                let recommendation = createVaccinationRecommendation(vaccination, patient: patient)
                recommendations.append(recommendation)
            }
        }
        
        // Check risk-based vaccinations
        let riskBasedVaccinations = getRiskBasedVaccinations(for: patient)
        
        for vaccination in riskBasedVaccinations {
            if !isVaccinationUpToDate(vaccination, history: vaccinationHistory) {
                let recommendation = createVaccinationRecommendation(vaccination, patient: patient)
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    /// Generate lifestyle recommendations
    private func generateLifestyleRecommendations(
        _ patient: PatientProfile,
        _ riskAssessment: RiskAssessment
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Smoking cessation
        if patient.lifestyle.smokingStatus == "current" {
            let smokingCessation = createSmokingCessationRecommendation(patient, riskAssessment)
            recommendations.append(smokingCessation)
        }
        
        // Weight management
        if patient.bmi >= 25.0 {
            let weightManagement = createWeightManagementRecommendation(patient, riskAssessment)
            recommendations.append(weightManagement)
        }
        
        // Physical activity
        if patient.lifestyle.exerciseFrequency < 150 { // minutes per week
            let exerciseRecommendation = createExerciseRecommendation(patient, riskAssessment)
            recommendations.append(exerciseRecommendation)
        }
        
        // Nutrition
        let nutritionRecommendation = createNutritionRecommendation(patient, riskAssessment)
        recommendations.append(nutritionRecommendation)
        
        // Alcohol moderation
        if patient.lifestyle.alcoholConsumption == "excessive" {
            let alcoholRecommendation = createAlcoholModerationRecommendation(patient, riskAssessment)
            recommendations.append(alcoholRecommendation)
        }
        
        return recommendations
    }
    
    /// Generate medication recommendations
    private func generateMedicationRecommendations(
        _ patient: PatientProfile,
        _ riskAssessment: RiskAssessment
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Aspirin for cardiovascular prevention
        if shouldRecommendAspirin(patient, riskAssessment) {
            let aspirinRecommendation = createAspirinRecommendation(patient, riskAssessment)
            recommendations.append(aspirinRecommendation)
        }
        
        // Statin therapy
        if shouldRecommendStatin(patient, riskAssessment) {
            let statinRecommendation = createStatinRecommendation(patient, riskAssessment)
            recommendations.append(statinRecommendation)
        }
        
        // Calcium and Vitamin D
        if shouldRecommendCalciumVitaminD(patient, riskAssessment) {
            let supplementRecommendation = createSupplementRecommendation(patient, riskAssessment)
            recommendations.append(supplementRecommendation)
        }
        
        return recommendations
    }
    
    /// Generate monitoring recommendations
    private func generateMonitoringRecommendations(
        _ patient: PatientProfile,
        _ riskAssessment: RiskAssessment
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Blood pressure monitoring
        let bpMonitoring = createBloodPressureMonitoringRecommendation(patient, riskAssessment)
        recommendations.append(bpMonitoring)
        
        // Cholesterol monitoring
        let cholesterolMonitoring = createCholesterolMonitoringRecommendation(patient, riskAssessment)
        recommendations.append(cholesterolMonitoring)
        
        // Blood glucose monitoring
        if riskAssessment.diabetesRisk > 0.1 {
            let glucoseMonitoring = createGlucoseMonitoringRecommendation(patient, riskAssessment)
            recommendations.append(glucoseMonitoring)
        }
        
        return recommendations
    }
    
    /// Generate counseling recommendations
    private func generateCounselingRecommendations(
        _ patient: PatientProfile,
        _ riskAssessment: RiskAssessment
    ) async throws -> [PreventiveCareRecommendation] {
        
        var recommendations: [PreventiveCareRecommendation] = []
        
        // Diet counseling
        if patient.bmi >= 25.0 || riskAssessment.cardiovascularRisk > 0.1 {
            let dietCounseling = createDietCounselingRecommendation(patient, riskAssessment)
            recommendations.append(dietCounseling)
        }
        
        // Exercise counseling
        if patient.lifestyle.exerciseFrequency < 150 {
            let exerciseCounseling = createExerciseCounselingRecommendation(patient, riskAssessment)
            recommendations.append(exerciseCounseling)
        }
        
        // Stress management counseling
        if patient.lifestyle.stressLevel == "high" {
            let stressCounseling = createStressCounselingRecommendation(patient, riskAssessment)
            recommendations.append(stressCounseling)
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func setupPreventiveCare() {
        // Initialize preventive care system
    }
    
    private func prioritizeRecommendations(
        _ recommendations: [PreventiveCareRecommendation],
        patient: PatientProfile
    ) -> [PreventiveCareRecommendation] {
        
        return recommendations.sorted { first, second in
            // Prioritize by urgency first
            if first.urgency != second.urgency {
                return first.urgency.rawValue > second.urgency.rawValue
            }
            
            // Then by impact
            if first.impact != second.impact {
                return first.impact.rawValue > second.impact.rawValue
            }
            
            // Finally by cost-effectiveness
            return first.costEffectiveness > second.costEffectiveness
        }
    }
    
    private func applyPatientPreferences(
        _ recommendations: [PreventiveCareRecommendation],
        preferences: PatientPreferences
    ) -> [PreventiveCareRecommendation] {
        
        return recommendations.filter { recommendation in
            // Filter based on patient preferences
            if preferences.excludedCategories.contains(recommendation.category) {
                return false
            }
            
            if let maxCost = preferences.maxCostPerRecommendation,
               recommendation.estimatedCost > maxCost {
                return false
            }
            
            return true
        }
    }
    
    private func analyzeCostEffectiveness(
        _ recommendations: [PreventiveCareRecommendation],
        patient: PatientProfile
    ) async throws -> [PreventiveCareRecommendation] {
        
        var updatedRecommendations: [PreventiveCareRecommendation] = []
        
        for recommendation in recommendations {
            let costEffectiveness = try await costEffectivenessAnalyzer.analyze(
                recommendation: recommendation,
                patient: patient
            )
            
            var updatedRecommendation = recommendation
            updatedRecommendation.costEffectiveness = costEffectiveness
            updatedRecommendations.append(updatedRecommendation)
        }
        
        return updatedRecommendations
    }
    
    // Additional helper methods would be implemented here...
    private func calculateOverallHealthRisk(_ risks: [Double]) -> Double { return risks.reduce(0, +) / Double(risks.count) }
    private func generateCancerScreeningRecommendations(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) async throws -> [PreventiveCareRecommendation] { return [] }
    private func generateCardiovascularScreeningRecommendations(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) async throws -> [PreventiveCareRecommendation] { return [] }
    private func shouldScreenForDiabetes(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> Bool { return riskAssessment.diabetesRisk > 0.1 }
    private func createDiabetesScreeningRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "screening", type: "diabetes", description: "Diabetes screening", urgency: .medium, impact: .high, estimatedCost: 50, costEffectiveness: 0.8) }
    private func shouldScreenForOsteoporosis(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> Bool { return patient.age >= 65 || riskAssessment.osteoporosisRisk > 0.2 }
    private func createOsteoporosisScreeningRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "screening", type: "osteoporosis", description: "Bone density screening", urgency: .medium, impact: .medium, estimatedCost: 200, costEffectiveness: 0.7) }
    private func getRoutineVaccinations(for age: Int) -> [String] { return ["flu", "tetanus", "shingles"] }
    private func isVaccinationUpToDate(_ vaccination: String, history: [VaccinationRecord]) -> Bool { return false }
    private func createVaccinationRecommendation(_ vaccination: String, patient: PatientProfile) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "vaccination", type: vaccination, description: "\(vaccination) vaccination", urgency: .medium, impact: .high, estimatedCost: 25, costEffectiveness: 0.9) }
    private func getRiskBasedVaccinations(for patient: PatientProfile) -> [String] { return [] }
    private func createSmokingCessationRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "lifestyle", type: "smoking_cessation", description: "Smoking cessation program", urgency: .high, impact: .high, estimatedCost: 300, costEffectiveness: 0.95) }
    private func createWeightManagementRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "lifestyle", type: "weight_management", description: "Weight management program", urgency: .medium, impact: .high, estimatedCost: 200, costEffectiveness: 0.8) }
    private func createExerciseRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "lifestyle", type: "exercise", description: "Exercise program", urgency: .medium, impact: .high, estimatedCost: 100, costEffectiveness: 0.9) }
    private func createNutritionRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "lifestyle", type: "nutrition", description: "Nutrition counseling", urgency: .medium, impact: .medium, estimatedCost: 150, costEffectiveness: 0.7) }
    private func createAlcoholModerationRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "lifestyle", type: "alcohol_moderation", description: "Alcohol moderation counseling", urgency: .medium, impact: .medium, estimatedCost: 100, costEffectiveness: 0.6) }
    private func shouldRecommendAspirin(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> Bool { return riskAssessment.cardiovascularRisk > 0.1 && patient.age >= 40 }
    private func createAspirinRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "medication", type: "aspirin", description: "Low-dose aspirin therapy", urgency: .medium, impact: .medium, estimatedCost: 20, costEffectiveness: 0.8) }
    private func shouldRecommendStatin(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> Bool { return riskAssessment.cardiovascularRisk > 0.2 }
    private func createStatinRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "medication", type: "statin", description: "Statin therapy", urgency: .medium, impact: .high, estimatedCost: 100, costEffectiveness: 0.85) }
    private func shouldRecommendCalciumVitaminD(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> Bool { return patient.age >= 50 || riskAssessment.osteoporosisRisk > 0.1 }
    private func createSupplementRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "medication", type: "supplements", description: "Calcium and Vitamin D supplementation", urgency: .low, impact: .medium, estimatedCost: 50, costEffectiveness: 0.6) }
    private func createBloodPressureMonitoringRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "monitoring", type: "blood_pressure", description: "Regular blood pressure monitoring", urgency: .medium, impact: .high, estimatedCost: 30, costEffectiveness: 0.9) }
    private func createCholesterolMonitoringRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "monitoring", type: "cholesterol", description: "Cholesterol screening", urgency: .medium, impact: .medium, estimatedCost: 40, costEffectiveness: 0.8) }
    private func createGlucoseMonitoringRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "monitoring", type: "glucose", description: "Blood glucose monitoring", urgency: .medium, impact: .high, estimatedCost: 25, costEffectiveness: 0.85) }
    private func createDietCounselingRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "counseling", type: "diet", description: "Dietary counseling", urgency: .medium, impact: .medium, estimatedCost: 120, costEffectiveness: 0.7) }
    private func createExerciseCounselingRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "counseling", type: "exercise", description: "Exercise counseling", urgency: .medium, impact: .medium, estimatedCost: 100, costEffectiveness: 0.75) }
    private func createStressCounselingRecommendation(_ patient: PatientProfile, _ riskAssessment: RiskAssessment) -> PreventiveCareRecommendation { return PreventiveCareRecommendation(id: UUID(), category: "counseling", type: "stress", description: "Stress management counseling", urgency: .medium, impact: .medium, estimatedCost: 150, costEffectiveness: 0.6) }
    private func createPreventionTimeline(_ recommendations: [PreventiveCareRecommendation], timeFrame: TimeFrame) -> PreventionTimeline { return PreventionTimeline(events: []) }
    private func calculateCostProjections(_ recommendations: [PreventiveCareRecommendation], timeFrame: TimeFrame) -> CostProjections { return CostProjections(total: 0, breakdown: [:]) }
    private func estimateHealthOutcomes(_ recommendations: [PreventiveCareRecommendation], patient: PatientProfile) async throws -> HealthOutcomeProjections { return HealthOutcomeProjections(projections: [:]) }
    private func createFollowUpSchedule(_ recommendations: [PreventiveCareRecommendation], timeFrame: TimeFrame) -> FollowUpSchedule { return FollowUpSchedule(appointments: []) }
    private func updateRiskAssessment(_ patient: PatientProfile, newData: HealthData) async throws -> RiskAssessment { return RiskAssessment(patient: patient, cardiovascularRisk: 0.1, cancerRisks: [:], diabetesRisk: 0.05, osteoporosisRisk: 0.1, infectiousRisks: [:], overallRisk: 0.1, assessmentDate: Date()) }
    private func identifyRecommendationChanges(current: [PreventiveCareRecommendation], updated: [PreventiveCareRecommendation]) -> RecommendationChanges { return RecommendationChanges(significant: [], minor: []) }
    private func notifySignificantChanges(_ changes: [PreventiveCareRecommendation], patient: PatientProfile) async { }
}

// MARK: - Supporting Types

public struct PreventiveCareRecommendation: Identifiable {
    public let id: UUID
    public let category: String
    public let type: String
    public let description: String
    public let urgency: Urgency
    public let impact: Impact
    public let estimatedCost: Double
    public var costEffectiveness: Double
    
    public enum Urgency: Int {
        case low = 1, medium = 2, high = 3, urgent = 4
    }
    
    public enum Impact: Int {
        case low = 1, medium = 2, high = 3
    }
}

public struct PreventionPlan: Identifiable {
    public let id: UUID
    public let patient: PatientProfile
    public let recommendations: [PreventiveCareRecommendation]
    public let timeline: PreventionTimeline
    public let costProjections: CostProjections
    public let outcomeProjections: HealthOutcomeProjections
    public let followUpSchedule: FollowUpSchedule
    public let timeFrame: TimeFrame
    public let createdDate: Date
}

public struct RiskAssessment {
    public let patient: PatientProfile
    public let cardiovascularRisk: Double
    public let cancerRisks: [String: Double]
    public let diabetesRisk: Double
    public let osteoporosisRisk: Double
    public let infectiousRisks: [String: Double]
    public let overallRisk: Double
    public let assessmentDate: Date
}

public struct PatientPreferences {
    public let excludedCategories: [String]
    public let maxCostPerRecommendation: Double?
    public let preferredProviders: [String]
    public let schedulingPreferences: SchedulingPreferences
}

public struct SchedulingPreferences {
    public let preferredDays: [String]
    public let preferredTimes: [String]
    public let maxAppointmentsPerMonth: Int
}

public enum TimeFrame {
    case sixMonths, oneYear, twoYears, fiveYears
}

// Additional supporting types...
public struct ClinicalGuideline {
    public let organization: String
    public let recommendation: String
    public let evidenceLevel: String
}

public struct VaccinationRecord {
    public let vaccine: String
    public let date: Date
    public let provider: String
}

public struct HealthData {
    public let vitals: [String: Double]
    public let labResults: [String: Double]
    public let symptoms: [String]
}

public struct PreventionTimeline {
    public let events: [PreventionEvent]
}

public struct PreventionEvent {
    public let date: Date
    public let type: String
    public let description: String
}

public struct CostProjections {
    public let total: Double
    public let breakdown: [String: Double]
}

public struct HealthOutcomeProjections {
    public let projections: [String: Double]
}

public struct FollowUpSchedule {
    public let appointments: [FollowUpAppointment]
}

public struct FollowUpAppointment {
    public let date: Date
    public let type: String
    public let provider: String
}

public struct RecommendationChanges {
    public let significant: [PreventiveCareRecommendation]
    public let minor: [PreventiveCareRecommendation]
}

// MARK: - Helper Classes

private class RiskCalculator {
    func calculateCardiovascularRisk(_ patient: PatientProfile) async throws -> Double { return 0.1 }
    func calculateCancerRisks(_ patient: PatientProfile) async throws -> [String: Double] { return [:] }
    func calculateDiabetesRisk(_ patient: PatientProfile) async throws -> Double { return 0.05 }
    func calculateOsteoporosisRisk(_ patient: PatientProfile) async throws -> Double { return 0.1 }
    func calculateInfectiousRisks(_ patient: PatientProfile) async throws -> [String: Double] { return [:] }
}

private class ClinicalGuidelinesEngine {
    func getApplicableGuidelines(for patient: PatientProfile) async throws -> [ClinicalGuideline] { return [] }
}

private class EvidenceBasedEngine {
    // Implementation for evidence-based recommendations
}

private class CostEffectivenessAnalyzer {
    func analyze(recommendation: PreventiveCareRecommendation, patient: PatientProfile) async throws -> Double { return 0.8 }
}

// Extensions to existing types
extension PatientProfile {
    var vaccinationHistory: [VaccinationRecord]? { return nil }
}

extension LifestyleProfile {
    var exerciseFrequency: Double { return 120 } // minutes per week
    var stressLevel: String { return "moderate" }
}
