import Foundation
import ResearchKit
import HealthKit
import CloudKit

/// Manages ResearchKit integration for clinical studies and data collection
@MainActor
class ResearchKitManager: ObservableObject {
    static let shared = ResearchKitManager()
    
    // MARK: - Published Properties
    @Published var activeStudies: [Study] = []
    @Published var userConsent: ConsentStatus = .notConsented
    @Published var dataCollectionStatus: DataCollectionStatus = .inactive
    @Published var studyProgress: [String: StudyProgress] = [:]
    
    // MARK: - Private Properties
    private let healthDataManager = HealthDataManager.shared
    private let cloudKitManager = CloudKitSyncManager.shared
    private var taskViewController: ORKTaskViewController?
    
    // MARK: - Study Management
    struct Study {
        let id: String
        let title: String
        let description: String
        let duration: TimeInterval
        let dataTypes: [HealthDataType]
        let consentRequired: Bool
        let compensation: String?
        let principalInvestigator: String
        let institution: String
    }
    
    struct StudyProgress {
        let studyId: String
        let startDate: Date
        let completedSurveys: Int
        let totalSurveys: Int
        let dataPointsCollected: Int
        let lastDataSync: Date?
    }
    
    enum ConsentStatus {
        case notConsented
        case consented(Date)
        case withdrawn(Date)
    }
    
    enum DataCollectionStatus {
        case inactive
        case active
        case paused
        case completed
    }
    
    enum HealthDataType: String, CaseIterable {
        case heartRate = "heart_rate"
        case sleepData = "sleep_data"
        case activityData = "activity_data"
        case ecgData = "ecg_data"
        case hrvData = "hrv_data"
        case environmentalData = "environmental_data"
        case audioData = "audio_data"
    }
    
    // MARK: - Initialization
    private init() {
        setupDefaultStudies()
        loadUserConsent()
        loadStudyProgress()
    }
    
    // MARK: - Study Setup
    private func setupDefaultStudies() {
        activeStudies = [
            Study(
                id: "sleep_optimization_2024",
                title: "AI-Powered Sleep Optimization Study",
                description: "Investigating the effectiveness of AI-driven sleep interventions on sleep quality and recovery",
                duration: 30 * 24 * 60 * 60, // 30 days
                dataTypes: [.sleepData, .heartRate, .hrvData, .environmentalData],
                consentRequired: true,
                compensation: "$50 Amazon gift card",
                principalInvestigator: "Dr. Sarah Chen",
                institution: "Stanford Sleep Research Center"
            ),
            Study(
                id: "cardiac_health_monitoring",
                title: "Continuous Cardiac Health Monitoring",
                description: "Long-term study of cardiac health patterns using advanced ECG analysis",
                duration: 90 * 24 * 60 * 60, // 90 days
                dataTypes: [.ecgData, .heartRate, .hrvData],
                consentRequired: true,
                compensation: "$100 Amazon gift card",
                principalInvestigator: "Dr. Michael Rodriguez",
                institution: "Mayo Clinic Cardiology"
            ),
            Study(
                id: "environmental_health_correlation",
                title: "Environmental Factors and Health Outcomes",
                description: "Correlating environmental data with health metrics for predictive modeling",
                duration: 60 * 24 * 60 * 60, // 60 days
                dataTypes: [.environmentalData, .heartRate, .sleepData, .activityData],
                consentRequired: true,
                compensation: "$75 Amazon gift card",
                principalInvestigator: "Dr. Emily Watson",
                institution: "Harvard Environmental Health"
            )
        ]
    }
    
    // MARK: - Consent Management
    func presentConsent(for study: Study) {
        let consentDocument = createConsentDocument(for: study)
        let consentStep = ORKVisualConsentStep(identifier: "consent", document: consentDocument)
        
        let reviewStep = ORKConsentReviewStep(identifier: "review", signature: nil, in: consentDocument)
        reviewStep.text = "Please review the consent document"
        reviewStep.reasonForConsent = "By tapping 'Agree', you consent to participate in this research study."
        
        let task = ORKOrderedTask(identifier: "consent", steps: [consentStep, reviewStep])
        presentTask(task)
    }
    
    private func createConsentDocument(for study: Study) -> ORKConsentDocument {
        let consentDocument = ORKConsentDocument()
        consentDocument.title = study.title
        consentDocument.signaturePageTitle = "Consent"
        consentDocument.signaturePageContent = "I agree to participate in this research study."
        
        // Add consent sections
        let overviewSection = ORKConsentSection(type: .overview)
        overviewSection.title = "Study Overview"
        overviewSection.content = study.description
        
        let dataGatheringSection = ORKConsentSection(type: .dataGathering)
        dataGatheringSection.title = "Data Collection"
        dataGatheringSection.content = "This study will collect the following health data: \(study.dataTypes.map { $0.rawValue }.joined(separator: ", "))"
        
        let privacySection = ORKConsentSection(type: .privacy)
        privacySection.title = "Privacy and Confidentiality"
        privacySection.content = "Your data will be anonymized and stored securely. Only authorized researchers will have access to your data."
        
        let timeCommitmentSection = ORKConsentSection(type: .timeCommitment)
        timeCommitmentSection.title = "Time Commitment"
        timeCommitmentSection.content = "This study will run for \(Int(study.duration / (24 * 60 * 60))) days. Data collection happens automatically in the background."
        
        let studySurveySection = ORKConsentSection(type: .studySurvey)
        studySurveySection.title = "Study Surveys"
        studySurveySection.content = "You may be asked to complete brief surveys about your health and sleep patterns."
        
        let withdrawalSection = ORKConsentSection(type: .withdrawing)
        withdrawalSection.title = "Withdrawal"
        withdrawalSection.content = "You may withdraw from this study at any time without penalty."
        
        consentDocument.sections = [
            overviewSection,
            dataGatheringSection,
            privacySection,
            timeCommitmentSection,
            studySurveySection,
            withdrawalSection
        ]
        
        return consentDocument
    }
    
    // MARK: - Survey Management
    func presentSurvey(for study: Study, surveyType: SurveyType) {
        let task = createSurveyTask(for: surveyType)
        presentTask(task)
    }
    
    enum SurveyType {
        case sleepQuality
        case moodAssessment
        case stressLevel
        case physicalActivity
        case medicationUse
        case custom(String)
    }
    
    private func createSurveyTask(for surveyType: SurveyType) -> ORKOrderedTask {
        var steps: [ORKStep] = []
        
        switch surveyType {
        case .sleepQuality:
            steps = createSleepQualitySurvey()
        case .moodAssessment:
            steps = createMoodAssessmentSurvey()
        case .stressLevel:
            steps = createStressLevelSurvey()
        case .physicalActivity:
            steps = createPhysicalActivitySurvey()
        case .medicationUse:
            steps = createMedicationUseSurvey()
        case .custom(let identifier):
            steps = createCustomSurvey(identifier: identifier)
        }
        
        return ORKOrderedTask(identifier: "survey_\(surveyType)", steps: steps)
    }
    
    private func createSleepQualitySurvey() -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "sleep_instruction")
        instructionStep.title = "Sleep Quality Assessment"
        instructionStep.text = "Please answer the following questions about your sleep last night."
        
        let sleepQualityStep = ORKQuestionStep(identifier: "sleep_quality")
        sleepQualityStep.title = "How would you rate your sleep quality?"
        sleepQualityStep.question = "On a scale of 1-10, how would you rate your overall sleep quality last night?"
        sleepQualityStep.answerFormat = ORKScaleAnswerFormat(maximumValue: 10, minimumValue: 1, defaultValue: 5, step: 1, vertical: false, maximumValueDescription: "Excellent", minimumValueDescription: "Poor")
        
        let sleepDurationStep = ORKQuestionStep(identifier: "sleep_duration")
        sleepDurationStep.title = "Sleep Duration"
        sleepDurationStep.question = "How many hours did you sleep last night?"
        sleepDurationStep.answerFormat = ORKNumericAnswerFormat(style: .decimal, unit: "hours", minimum: 0, maximum: 24)
        
        let difficultyFallingAsleepStep = ORKQuestionStep(identifier: "difficulty_falling_asleep")
        difficultyFallingAsleepStep.title = "Difficulty Falling Asleep"
        difficultyFallingAsleepStep.question = "How long did it take you to fall asleep?"
        difficultyFallingAsleepStep.answerFormat = ORKNumericAnswerFormat(style: .integer, unit: "minutes", minimum: 0, maximum: 300)
        
        return [instructionStep, sleepQualityStep, sleepDurationStep, difficultyFallingAsleepStep]
    }
    
    private func createMoodAssessmentSurvey() -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "mood_instruction")
        instructionStep.title = "Mood Assessment"
        instructionStep.text = "Please rate your current mood and emotional state."
        
        let moodStep = ORKQuestionStep(identifier: "current_mood")
        moodStep.title = "Current Mood"
        moodStep.question = "How would you describe your current mood?"
        moodStep.answerFormat = ORKTextChoiceAnswerFormat(style: .singleChoice, textChoices: [
            ORKTextChoice(text: "Very Happy", value: "very_happy"),
            ORKTextChoice(text: "Happy", value: "happy"),
            ORKTextChoice(text: "Neutral", value: "neutral"),
            ORKTextChoice(text: "Sad", value: "sad"),
            ORKTextChoice(text: "Very Sad", value: "very_sad")
        ])
        
        let energyStep = ORKQuestionStep(identifier: "energy_level")
        energyStep.title = "Energy Level"
        energyStep.question = "How would you rate your current energy level?"
        energyStep.answerFormat = ORKScaleAnswerFormat(maximumValue: 10, minimumValue: 1, defaultValue: 5, step: 1, vertical: false, maximumValueDescription: "Very High", minimumValueDescription: "Very Low")
        
        return [instructionStep, moodStep, energyStep]
    }
    
    private func createStressLevelSurvey() -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "stress_instruction")
        instructionStep.title = "Stress Assessment"
        instructionStep.text = "Please rate your current stress level and any stressors you're experiencing."
        
        let stressLevelStep = ORKQuestionStep(identifier: "stress_level")
        stressLevelStep.title = "Stress Level"
        stressLevelStep.question = "How stressed do you feel right now?"
        stressLevelStep.answerFormat = ORKScaleAnswerFormat(maximumValue: 10, minimumValue: 1, defaultValue: 5, step: 1, vertical: false, maximumValueDescription: "Extremely Stressed", minimumValueDescription: "Not Stressed")
        
        let stressorsStep = ORKQuestionStep(identifier: "stressors")
        stressorsStep.title = "Stressors"
        stressorsStep.question = "What is causing you stress? (Select all that apply)"
        stressorsStep.answerFormat = ORKTextChoiceAnswerFormat(style: .multipleChoice, textChoices: [
            ORKTextChoice(text: "Work", value: "work"),
            ORKTextChoice(text: "Family", value: "family"),
            ORKTextChoice(text: "Health", value: "health"),
            ORKTextChoice(text: "Financial", value: "financial"),
            ORKTextChoice(text: "Other", value: "other")
        ])
        
        return [instructionStep, stressLevelStep, stressorsStep]
    }
    
    private func createPhysicalActivitySurvey() -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "activity_instruction")
        instructionStep.title = "Physical Activity Assessment"
        instructionStep.text = "Please answer questions about your physical activity."
        
        let exerciseStep = ORKQuestionStep(identifier: "exercise_today")
        exerciseStep.title = "Exercise Today"
        exerciseStep.question = "Did you exercise today?"
        exerciseStep.answerFormat = ORKBooleanAnswerFormat()
        
        let exerciseDurationStep = ORKQuestionStep(identifier: "exercise_duration")
        exerciseDurationStep.title = "Exercise Duration"
        exerciseDurationStep.question = "How many minutes did you exercise today?"
        exerciseDurationStep.answerFormat = ORKNumericAnswerFormat(style: .integer, unit: "minutes", minimum: 0, maximum: 300)
        
        return [instructionStep, exerciseStep, exerciseDurationStep]
    }
    
    private func createMedicationUseSurvey() -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "medication_instruction")
        instructionStep.title = "Medication Use"
        instructionStep.text = "Please answer questions about any medications you're taking."
        
        let medicationStep = ORKQuestionStep(identifier: "taking_medication")
        medicationStep.title = "Medication Use"
        medicationStep.question = "Are you currently taking any medications?"
        medicationStep.answerFormat = ORKBooleanAnswerFormat()
        
        let medicationListStep = ORKQuestionStep(identifier: "medication_list")
        medicationListStep.title = "Medication List"
        medicationListStep.question = "Please list any medications you're currently taking:"
        medicationListStep.answerFormat = ORKTextAnswerFormat(maxLength: 500)
        
        return [instructionStep, medicationStep, medicationListStep]
    }
    
    private func createCustomSurvey(identifier: String) -> [ORKStep] {
        let instructionStep = ORKInstructionStep(identifier: "custom_instruction")
        instructionStep.title = "Custom Survey"
        instructionStep.text = "Please complete the following survey."
        
        let textStep = ORKQuestionStep(identifier: "custom_text")
        textStep.title = "Custom Question"
        textStep.question = "Please provide your response:"
        textStep.answerFormat = ORKTextAnswerFormat(maxLength: 1000)
        
        return [instructionStep, textStep]
    }
    
    // MARK: - Task Presentation
    private func presentTask(_ task: ORKTask) {
        taskViewController = ORKTaskViewController(task: task, taskRun: nil)
        taskViewController?.delegate = self
        
        // Present the task view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(taskViewController!, animated: true)
        }
    }
    
    // MARK: - Data Collection
    func startDataCollection(for study: Study) {
        guard userConsent != .notConsented else {
            print("User must consent before data collection can begin")
            return
        }
        
        dataCollectionStatus = .active
        setupDataCollection(for: study)
        updateStudyProgress(studyId: study.id, status: .active)
    }
    
    private func setupDataCollection(for study: Study) {
        // Set up HealthKit data collection based on study requirements
        for dataType in study.dataTypes {
            switch dataType {
            case .heartRate:
                healthDataManager.startHeartRateMonitoring()
            case .sleepData:
                healthDataManager.startSleepMonitoring()
            case .activityData:
                healthDataManager.startActivityMonitoring()
            case .ecgData:
                healthDataManager.startECGMonitoring()
            case .hrvData:
                healthDataManager.startHRVMonitoring()
            case .environmentalData:
                // Environmental data is collected by EnvironmentManager
                break
            case .audioData:
                // Audio data is collected by AdaptiveAudioManager
                break
            }
        }
    }
    
    func stopDataCollection(for study: Study) {
        dataCollectionStatus = .inactive
        updateStudyProgress(studyId: study.id, status: .completed)
    }
    
    // MARK: - Data Export
    func exportStudyData(for study: Study) async throws -> Data {
        let studyData = try await collectStudyData(for: study)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(studyData)
    }
    
    private func collectStudyData(for study: Study) async throws -> [String: Any] {
        var studyData: [String: Any] = [
            "study_id": study.id,
            "participant_id": generateParticipantID(),
            "consent_date": userConsent,
            "data_collection_start": Date(),
            "data_types": study.dataTypes.map { $0.rawValue }
        ]
        
        // Collect health data based on study requirements
        for dataType in study.dataTypes {
            switch dataType {
            case .heartRate:
                studyData["heart_rate_data"] = await healthDataManager.getHeartRateData()
            case .sleepData:
                studyData["sleep_data"] = await healthDataManager.getSleepData()
            case .activityData:
                studyData["activity_data"] = await healthDataManager.getActivityData()
            case .ecgData:
                studyData["ecg_data"] = await healthDataManager.getECGData()
            case .hrvData:
                studyData["hrv_data"] = await healthDataManager.getHRVData()
            case .environmentalData:
                studyData["environmental_data"] = EnvironmentManager.shared.getEnvironmentalData()
            case .audioData:
                studyData["audio_data"] = AdaptiveAudioManager.shared.getAudioData()
            }
        }
        
        return studyData
    }
    
    private func generateParticipantID() -> String {
        return "P\(Int.random(in: 10000...99999))"
    }
    
    // MARK: - Progress Tracking
    private func updateStudyProgress(studyId: String, status: DataCollectionStatus) {
        let progress = StudyProgress(
            studyId: studyId,
            startDate: Date(),
            completedSurveys: 0,
            totalSurveys: 10, // Placeholder
            dataPointsCollected: 0,
            lastDataSync: nil
        )
        
        studyProgress[studyId] = progress
        saveStudyProgress()
    }
    
    // MARK: - Persistence
    private func loadUserConsent() {
        if let consentDate = UserDefaults.standard.object(forKey: "user_consent_date") as? Date {
            userConsent = .consented(consentDate)
        }
    }
    
    private func saveUserConsent() {
        switch userConsent {
        case .consented(let date):
            UserDefaults.standard.set(date, forKey: "user_consent_date")
        case .withdrawn(let date):
            UserDefaults.standard.set(date, forKey: "user_withdrawal_date")
        case .notConsented:
            UserDefaults.standard.removeObject(forKey: "user_consent_date")
            UserDefaults.standard.removeObject(forKey: "user_withdrawal_date")
        }
    }
    
    private func loadStudyProgress() {
        // Load study progress from UserDefaults or Core Data
    }
    
    private func saveStudyProgress() {
        // Save study progress to UserDefaults or Core Data
    }
}

// MARK: - ORKTaskViewControllerDelegate
extension ResearchKitManager: ORKTaskViewControllerDelegate {
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        taskViewController.dismiss(animated: true) {
            if reason == .completed {
                // Handle completed task
                self.handleCompletedTask(taskViewController.task)
            }
        }
    }
    
    private func handleCompletedTask(_ task: ORKTask?) {
        guard let task = task else { return }
        
        if task.identifier.contains("consent") {
            userConsent = .consented(Date())
            saveUserConsent()
        } else if task.identifier.contains("survey") {
            // Handle survey completion
            updateSurveyProgress()
        }
    }
    
    private func updateSurveyProgress() {
        // Update survey completion progress
    }
} 