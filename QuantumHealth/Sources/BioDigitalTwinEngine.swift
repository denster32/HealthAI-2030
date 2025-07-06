import Foundation
import HealthKit
import Accelerate

public class BioDigitalTwinEngine {
    private let cardiovascularSystem: CardiovascularSystem
    private let neurologicalSystem: NeurologicalSystem
    private let endocrineSystem: EndocrineSystem
    private let immuneSystem: ImmuneSystem
    private let metabolicSystem: MetabolicSystem
    private var systemInteractions: [SystemInteraction] = []
    
    public init() {
        self.cardiovascularSystem = CardiovascularSystem()
        self.neurologicalSystem = NeurologicalSystem()
        self.endocrineSystem = EndocrineSystem()
        self.immuneSystem = ImmuneSystem()
        self.metabolicSystem = MetabolicSystem()
        
        setupSystemInteractions()
    }
    
    public func createDigitalTwin(from healthData: HealthProfile) -> BioDigitalTwin {
        let cardiovascularModel = cardiovascularSystem.createModel(from: healthData.cardiovascularData)
        let neurologicalModel = neurologicalSystem.createModel(from: healthData.neurologicalData)
        let endocrineModel = endocrineSystem.createModel(from: healthData.endocrineData)
        let immuneModel = immuneSystem.createModel(from: healthData.immuneData)
        let metabolicModel = metabolicSystem.createModel(from: healthData.metabolicData)
        
        let digitalTwin = BioDigitalTwin(
            id: UUID(),
            patientId: healthData.patientId,
            cardiovascularModel: cardiovascularModel,
            neurologicalModel: neurologicalModel,
            endocrineModel: endocrineModel,
            immuneModel: immuneModel,
            metabolicModel: metabolicModel,
            systemInteractions: systemInteractions,
            createdAt: Date()
        )
        
        calibrateSystemInteractions(digitalTwin: digitalTwin, healthData: healthData)
        
        return digitalTwin
    }
    
    public func simulateHealthScenario(
        digitalTwin: BioDigitalTwin,
        scenario: HealthScenario,
        duration: TimeInterval
    ) -> SimulationResult {
        let timeSteps = Int(duration / scenario.timeStepSize)
        var simulationStates: [SimulationState] = []
        var currentState = createInitialState(from: digitalTwin)
        
        for step in 0..<timeSteps {
            let time = Double(step) * scenario.timeStepSize
            
            currentState = simulateTimeStep(
                currentState: currentState,
                digitalTwin: digitalTwin,
                scenario: scenario,
                time: time
            )
            
            simulationStates.append(currentState)
            
            if shouldTerminateSimulation(state: currentState, scenario: scenario) {
                break
            }
        }
        
        return SimulationResult(
            scenario: scenario,
            states: simulationStates,
            finalState: currentState,
            duration: Double(simulationStates.count) * scenario.timeStepSize
        )
    }
    
    public func predictDiseaseProgression(
        digitalTwin: BioDigitalTwin,
        disease: DiseaseModel,
        timeframe: TimeInterval
    ) -> DiseaseProgressionPrediction {
        let progressionModel = createProgressionModel(disease: disease, digitalTwin: digitalTwin)
        let timeSteps = Int(timeframe / 86400) // Daily progression
        
        var progressionStates: [DiseaseProgressionState] = []
        var currentSeverity = disease.currentSeverity
        var currentSymptoms = disease.currentSymptoms
        
        for day in 0..<timeSteps {
            let dayTime = Double(day) * 86400
            
            let progressionRate = calculateProgressionRate(
                digitalTwin: digitalTwin,
                disease: disease,
                currentSeverity: currentSeverity,
                time: dayTime
            )
            
            currentSeverity = updateSeverity(
                current: currentSeverity,
                rate: progressionRate,
                timeStep: 86400
            )
            
            currentSymptoms = updateSymptoms(
                symptoms: currentSymptoms,
                severity: currentSeverity,
                digitalTwin: digitalTwin
            )
            
            let state = DiseaseProgressionState(
                day: day,
                severity: currentSeverity,
                symptoms: currentSymptoms,
                affectedSystems: identifyAffectedSystems(disease: disease, severity: currentSeverity),
                biomarkers: predictBiomarkers(digitalTwin: digitalTwin, disease: disease, severity: currentSeverity)
            )
            
            progressionStates.append(state)
        }
        
        return DiseaseProgressionPrediction(
            disease: disease,
            progressionStates: progressionStates,
            riskFactors: identifyRiskFactors(digitalTwin: digitalTwin, disease: disease),
            interventionOpportunities: identifyInterventionOpportunities(progressionStates: progressionStates)
        )
    }
    
    public func optimizeTreatment(
        digitalTwin: BioDigitalTwin,
        condition: MedicalCondition,
        availableTreatments: [Treatment]
    ) -> TreatmentOptimizationResult {
        var treatmentEvaluations: [TreatmentEvaluation] = []
        
        for treatment in availableTreatments {
            let evaluation = evaluateTreatment(
                digitalTwin: digitalTwin,
                condition: condition,
                treatment: treatment
            )
            treatmentEvaluations.append(evaluation)
        }
        
        let rankedTreatments = treatmentEvaluations.sorted { $0.overallScore > $1.overallScore }
        let optimalTreatment = rankedTreatments.first
        
        let combinationTherapies = generateCombinationTherapies(
            treatments: availableTreatments,
            digitalTwin: digitalTwin,
            condition: condition
        )
        
        return TreatmentOptimizationResult(
            condition: condition,
            optimalTreatment: optimalTreatment,
            rankedTreatments: rankedTreatments,
            combinationTherapies: combinationTherapies,
            personalizedRecommendations: generatePersonalizedRecommendations(
                digitalTwin: digitalTwin,
                condition: condition,
                optimalTreatment: optimalTreatment
            )
        )
    }
    
    private func setupSystemInteractions() {
        systemInteractions = [
            SystemInteraction(
                sourceSystem: .cardiovascular,
                targetSystem: .neurological,
                interactionType: .bloodFlow,
                strength: 0.8
            ),
            SystemInteraction(
                sourceSystem: .endocrine,
                targetSystem: .cardiovascular,
                interactionType: .hormonal,
                strength: 0.7
            ),
            SystemInteraction(
                sourceSystem: .immune,
                targetSystem: .cardiovascular,
                interactionType: .inflammatory,
                strength: 0.6
            ),
            SystemInteraction(
                sourceSystem: .metabolic,
                targetSystem: .endocrine,
                interactionType: .metabolic,
                strength: 0.9
            ),
            SystemInteraction(
                sourceSystem: .neurological,
                targetSystem: .endocrine,
                interactionType: .neuralControl,
                strength: 0.8
            )
        ]
    }
    
    private func calibrateSystemInteractions(digitalTwin: BioDigitalTwin, healthData: HealthProfile) {
        for interaction in systemInteractions {
            let calibratedStrength = calculateInteractionStrength(
                interaction: interaction,
                healthData: healthData,
                digitalTwin: digitalTwin
            )
            
            if let index = systemInteractions.firstIndex(where: { $0.id == interaction.id }) {
                systemInteractions[index].strength = calibratedStrength
            }
        }
    }
    
    private func createInitialState(from digitalTwin: BioDigitalTwin) -> SimulationState {
        return SimulationState(
            time: 0.0,
            cardiovascularState: digitalTwin.cardiovascularModel.initialState,
            neurologicalState: digitalTwin.neurologicalModel.initialState,
            endocrineState: digitalTwin.endocrineModel.initialState,
            immuneState: digitalTwin.immuneModel.initialState,
            metabolicState: digitalTwin.metabolicModel.initialState,
            vitalSigns: VitalSigns(
                heartRate: digitalTwin.cardiovascularModel.restingHeartRate,
                bloodPressure: digitalTwin.cardiovascularModel.restingBloodPressure,
                respiratoryRate: 16.0,
                bodyTemperature: 37.0,
                oxygenSaturation: 98.0
            )
        )
    }
    
    private func simulateTimeStep(
        currentState: SimulationState,
        digitalTwin: BioDigitalTwin,
        scenario: HealthScenario,
        time: Double
    ) -> SimulationState {
        var newState = currentState
        newState.time = time
        
        applyScenarioEffects(state: &newState, scenario: scenario, time: time)
        
        newState.cardiovascularState = cardiovascularSystem.updateState(
            currentState: newState.cardiovascularState,
            digitalTwin: digitalTwin,
            timeStep: scenario.timeStepSize
        )
        
        newState.neurologicalState = neurologicalSystem.updateState(
            currentState: newState.neurologicalState,
            digitalTwin: digitalTwin,
            timeStep: scenario.timeStepSize
        )
        
        newState.endocrineState = endocrineSystem.updateState(
            currentState: newState.endocrineState,
            digitalTwin: digitalTwin,
            timeStep: scenario.timeStepSize
        )
        
        newState.immuneState = immuneSystem.updateState(
            currentState: newState.immuneState,
            digitalTwin: digitalTwin,
            timeStep: scenario.timeStepSize
        )
        
        newState.metabolicState = metabolicSystem.updateState(
            currentState: newState.metabolicState,
            digitalTwin: digitalTwin,
            timeStep: scenario.timeStepSize
        )
        
        applySystemInteractions(state: &newState, digitalTwin: digitalTwin)
        updateVitalSigns(state: &newState)
        
        return newState
    }
    
    private func applyScenarioEffects(state: inout SimulationState, scenario: HealthScenario, time: Double) {
        for effect in scenario.effects {
            switch effect.type {
            case .exercise:
                applyExerciseEffect(state: &state, intensity: effect.intensity, duration: effect.duration)
            case .stress:
                applyStressEffect(state: &state, level: effect.intensity)
            case .medication:
                applyMedicationEffect(state: &state, medication: effect.medication, dose: effect.dose)
            case .infection:
                applyInfectionEffect(state: &state, pathogen: effect.pathogen, severity: effect.intensity)
            case .nutrition:
                applyNutritionalEffect(state: &state, nutrients: effect.nutrients)
            }
        }
    }
    
    private func applyExerciseEffect(state: inout SimulationState, intensity: Double, duration: Double) {
        let heartRateIncrease = intensity * 40.0
        state.cardiovascularState.currentHeartRate += heartRateIncrease
        
        let metabolicRateIncrease = intensity * 2.0
        state.metabolicState.metabolicRate *= (1.0 + metabolicRateIncrease)
        
        let oxygenDemandIncrease = intensity * 1.5
        state.cardiovascularState.oxygenDemand *= (1.0 + oxygenDemandIncrease)
    }
    
    private func applyStressEffect(state: inout SimulationState, level: Double) {
        let cortisolIncrease = level * 50.0
        state.endocrineState.cortisolLevel += cortisolIncrease
        
        let heartRateIncrease = level * 20.0
        state.cardiovascularState.currentHeartRate += heartRateIncrease
        
        let bloodPressureIncrease = level * 10.0
        state.cardiovascularState.systolicPressure += bloodPressureIncrease
        state.cardiovascularState.diastolicPressure += bloodPressureIncrease * 0.7
    }
    
    private func applyMedicationEffect(state: inout SimulationState, medication: Medication?, dose: Double) {
        guard let medication = medication else { return }
        
        switch medication.type {
        case .betaBlocker:
            state.cardiovascularState.currentHeartRate *= (1.0 - dose * 0.2)
            state.cardiovascularState.systolicPressure *= (1.0 - dose * 0.15)
        case .insulin:
            state.metabolicState.glucoseLevel *= (1.0 - dose * 0.3)
        case .antibiotic:
            state.immuneState.infectionLevel *= (1.0 - dose * 0.4)
        case .antidepressant:
            state.neurologicalState.serotoninLevel *= (1.0 + dose * 0.25)
        }
    }
    
    private func applyInfectionEffect(state: inout SimulationState, pathogen: Pathogen?, severity: Double) {
        guard let pathogen = pathogen else { return }
        
        state.immuneState.infectionLevel += severity
        state.immuneState.whiteBloodCellCount *= (1.0 + severity * 0.5)
        state.vitalSigns.bodyTemperature += severity * 2.0
        
        if pathogen.affectsRespiratory {
            state.vitalSigns.respiratoryRate += severity * 4.0
            state.vitalSigns.oxygenSaturation -= severity * 5.0
        }
    }
    
    private func applyNutritionalEffect(state: inout SimulationState, nutrients: [Nutrient]) {
        for nutrient in nutrients {
            switch nutrient.type {
            case .glucose:
                state.metabolicState.glucoseLevel += nutrient.amount * 0.1
            case .protein:
                state.metabolicState.proteinLevel += nutrient.amount * 0.05
            case .fat:
                state.metabolicState.lipidLevel += nutrient.amount * 0.03
            case .vitamin:
                state.immuneState.immuneFunction *= (1.0 + nutrient.amount * 0.01)
            }
        }
    }
    
    private func applySystemInteractions(state: inout SimulationState, digitalTwin: BioDigitalTwin) {
        for interaction in systemInteractions {
            let sourceValue = getSystemValue(system: interaction.sourceSystem, state: state)
            let targetSystem = interaction.targetSystem
            let interactionEffect = sourceValue * interaction.strength * 0.1
            
            modifySystemValue(
                system: targetSystem,
                state: &state,
                modification: interactionEffect,
                interactionType: interaction.interactionType
            )
        }
    }
    
    private func getSystemValue(system: BiologicalSystem, state: SimulationState) -> Double {
        switch system {
        case .cardiovascular:
            return state.cardiovascularState.currentHeartRate / 100.0
        case .neurological:
            return state.neurologicalState.activityLevel
        case .endocrine:
            return state.endocrineState.hormonalBalance
        case .immune:
            return state.immuneState.immuneFunction
        case .metabolic:
            return state.metabolicState.metabolicRate
        }
    }
    
    private func modifySystemValue(
        system: BiologicalSystem,
        state: inout SimulationState,
        modification: Double,
        interactionType: InteractionType
    ) {
        switch system {
        case .cardiovascular:
            if interactionType == .hormonal {
                state.cardiovascularState.currentHeartRate += modification * 10.0
            }
        case .neurological:
            if interactionType == .bloodFlow {
                state.neurologicalState.activityLevel += modification * 0.1
            }
        case .endocrine:
            if interactionType == .neuralControl {
                state.endocrineState.hormonalBalance += modification * 0.2
            }
        case .immune:
            if interactionType == .inflammatory {
                state.immuneState.inflammationLevel += modification * 0.3
            }
        case .metabolic:
            if interactionType == .metabolic {
                state.metabolicState.metabolicRate += modification * 0.15
            }
        }
    }
    
    private func updateVitalSigns(state: inout SimulationState) {
        state.vitalSigns.heartRate = state.cardiovascularState.currentHeartRate
        state.vitalSigns.bloodPressure = BloodPressure(
            systolic: state.cardiovascularState.systolicPressure,
            diastolic: state.cardiovascularState.diastolicPressure
        )
        
        state.vitalSigns.respiratoryRate = calculateRespiratoryRate(state: state)
        state.vitalSigns.oxygenSaturation = calculateOxygenSaturation(state: state)
        state.vitalSigns.bodyTemperature = calculateBodyTemperature(state: state)
    }
    
    private func calculateRespiratoryRate(state: SimulationState) -> Double {
        let baseRate = 16.0
        let heartRateEffect = (state.cardiovascularState.currentHeartRate - 70.0) / 10.0
        let metabolicEffect = (state.metabolicState.metabolicRate - 1.0) * 5.0
        
        return max(10.0, min(30.0, baseRate + heartRateEffect + metabolicEffect))
    }
    
    private func calculateOxygenSaturation(state: SimulationState) -> Double {
        let baseSaturation = 98.0
        let cardiovascularEffect = (state.cardiovascularState.oxygenDelivery - 1.0) * 5.0
        let infectionEffect = -state.immuneState.infectionLevel * 2.0
        
        return max(85.0, min(100.0, baseSaturation + cardiovascularEffect + infectionEffect))
    }
    
    private func calculateBodyTemperature(state: SimulationState) -> Double {
        let baseTemperature = 37.0
        let metabolicEffect = (state.metabolicState.metabolicRate - 1.0) * 0.5
        let infectionEffect = state.immuneState.infectionLevel * 0.8
        let inflammationEffect = state.immuneState.inflammationLevel * 0.3
        
        return max(35.0, min(42.0, baseTemperature + metabolicEffect + infectionEffect + inflammationEffect))
    }
    
    private func shouldTerminateSimulation(state: SimulationState, scenario: HealthScenario) -> Bool {
        return state.vitalSigns.heartRate < 30.0 ||
               state.vitalSigns.heartRate > 200.0 ||
               state.vitalSigns.oxygenSaturation < 70.0 ||
               state.vitalSigns.bodyTemperature > 42.0 ||
               state.vitalSigns.bodyTemperature < 32.0
    }
    
    private func calculateInteractionStrength(
        interaction: SystemInteraction,
        healthData: HealthProfile,
        digitalTwin: BioDigitalTwin
    ) -> Double {
        let baseStrength = interaction.strength
        let ageModifier = calculateAgeModifier(age: healthData.age)
        let healthModifier = calculateHealthModifier(healthData: healthData, interaction: interaction)
        
        return max(0.1, min(1.0, baseStrength * ageModifier * healthModifier))
    }
    
    private func calculateAgeModifier(age: Int) -> Double {
        if age < 30 {
            return 1.0
        } else if age < 60 {
            return 1.0 - Double(age - 30) * 0.01
        } else {
            return 0.7 - Double(age - 60) * 0.005
        }
    }
    
    private func calculateHealthModifier(healthData: HealthProfile, interaction: SystemInteraction) -> Double {
        var modifier = 1.0
        
        for condition in healthData.medicalConditions {
            if condition.affectedSystems.contains(interaction.sourceSystem) ||
               condition.affectedSystems.contains(interaction.targetSystem) {
                modifier *= (1.0 - condition.severity * 0.3)
            }
        }
        
        return max(0.5, modifier)
    }
    
    private func createProgressionModel(disease: DiseaseModel, digitalTwin: BioDigitalTwin) -> DiseaseProgressionModel {
        return DiseaseProgressionModel(
            disease: disease,
            baseProgressionRate: disease.baseProgressionRate,
            riskFactors: identifyRiskFactors(digitalTwin: digitalTwin, disease: disease),
            protectiveFactors: identifyProtectiveFactors(digitalTwin: digitalTwin, disease: disease)
        )
    }
    
    private func calculateProgressionRate(
        digitalTwin: BioDigitalTwin,
        disease: DiseaseModel,
        currentSeverity: Double,
        time: Double
    ) -> Double {
        var rate = disease.baseProgressionRate
        
        let ageEffect = calculateAgeEffect(age: digitalTwin.age, disease: disease)
        let severityEffect = calculateSeverityEffect(severity: currentSeverity)
        let comorbidityEffect = calculateComorbidityEffect(digitalTwin: digitalTwin, disease: disease)
        
        rate *= ageEffect * severityEffect * comorbidityEffect
        
        return max(-0.1, min(0.1, rate))
    }
    
    private func calculateAgeEffect(age: Int, disease: DiseaseModel) -> Double {
        switch disease.type {
        case .cardiovascular:
            return 1.0 + Double(max(0, age - 40)) * 0.02
        case .neurological:
            return 1.0 + Double(max(0, age - 50)) * 0.03
        case .metabolic:
            return 1.0 + Double(max(0, age - 35)) * 0.015
        case .autoimmune:
            return age < 30 ? 1.2 : (age > 60 ? 1.3 : 1.0)
        case .cancer:
            return 1.0 + Double(max(0, age - 50)) * 0.025
        }
    }
    
    private func calculateSeverityEffect(severity: Double) -> Double {
        return 1.0 + severity * 0.5
    }
    
    private func calculateComorbidityEffect(digitalTwin: BioDigitalTwin, disease: DiseaseModel) -> Double {
        let comorbidityCount = digitalTwin.medicalConditions.count
        return 1.0 + Double(comorbidityCount) * 0.1
    }
    
    private func updateSeverity(current: Double, rate: Double, timeStep: Double) -> Double {
        let newSeverity = current + rate * (timeStep / 86400.0)
        return max(0.0, min(1.0, newSeverity))
    }
    
    private func updateSymptoms(
        symptoms: [Symptom],
        severity: Double,
        digitalTwin: BioDigitalTwin
    ) -> [Symptom] {
        return symptoms.map { symptom in
            var updatedSymptom = symptom
            updatedSymptom.intensity = min(1.0, symptom.intensity * (1.0 + severity * 0.2))
            return updatedSymptom
        }
    }
    
    private func identifyAffectedSystems(disease: DiseaseModel, severity: Double) -> [BiologicalSystem] {
        var systems = disease.primaryAffectedSystems
        
        if severity > 0.5 {
            systems.append(contentsOf: disease.secondaryAffectedSystems)
        }
        
        if severity > 0.8 {
            systems.append(contentsOf: disease.systemicEffects)
        }
        
        return Array(Set(systems))
    }
    
    private func predictBiomarkers(
        digitalTwin: BioDigitalTwin,
        disease: DiseaseModel,
        severity: Double
    ) -> [Biomarker] {
        var biomarkers: [Biomarker] = []
        
        for biomarkerType in disease.associatedBiomarkers {
            let baseValue = getBiomarkerBaseValue(type: biomarkerType, digitalTwin: digitalTwin)
            let diseaseEffect = calculateDiseaseEffect(disease: disease, biomarkerType: biomarkerType, severity: severity)
            let predictedValue = baseValue * diseaseEffect
            
            biomarkers.append(Biomarker(
                type: biomarkerType,
                value: predictedValue,
                unit: getBiomarkerUnit(type: biomarkerType),
                timestamp: Date()
            ))
        }
        
        return biomarkers
    }
    
    private func getBiomarkerBaseValue(type: BiomarkerType, digitalTwin: BioDigitalTwin) -> Double {
        switch type {
        case .crp:
            return 1.0
        case .troponin:
            return 0.01
        case .glucose:
            return digitalTwin.metabolicModel.baselineGlucose
        case .cholesterol:
            return digitalTwin.cardiovascularModel.baselineCholesterol
        case .hemoglobin:
            return 14.0
        }
    }
    
    private func calculateDiseaseEffect(disease: DiseaseModel, biomarkerType: BiomarkerType, severity: Double) -> Double {
        let baseEffect = disease.biomarkerEffects[biomarkerType] ?? 1.0
        return baseEffect * (1.0 + severity)
    }
    
    private func getBiomarkerUnit(type: BiomarkerType) -> String {
        switch type {
        case .crp:
            return "mg/L"
        case .troponin:
            return "ng/mL"
        case .glucose:
            return "mg/dL"
        case .cholesterol:
            return "mg/dL"
        case .hemoglobin:
            return "g/dL"
        }
    }
    
    private func identifyRiskFactors(digitalTwin: BioDigitalTwin, disease: DiseaseModel) -> [RiskFactor] {
        var riskFactors: [RiskFactor] = []
        
        if digitalTwin.age > disease.ageRiskThreshold {
            riskFactors.append(RiskFactor(
                type: .age,
                value: Double(digitalTwin.age),
                riskMultiplier: 1.0 + Double(digitalTwin.age - disease.ageRiskThreshold) * 0.02
            ))
        }
        
        for condition in digitalTwin.medicalConditions {
            if disease.comorbidityRisks.keys.contains(condition.type) {
                riskFactors.append(RiskFactor(
                    type: .comorbidity,
                    value: condition.severity,
                    riskMultiplier: disease.comorbidityRisks[condition.type] ?? 1.0
                ))
            }
        }
        
        return riskFactors
    }
    
    private func identifyProtectiveFactors(digitalTwin: BioDigitalTwin, disease: DiseaseModel) -> [ProtectiveFactor] {
        var protectiveFactors: [ProtectiveFactor] = []
        
        if digitalTwin.lifestyle.exerciseFrequency > 3 {
            protectiveFactors.append(ProtectiveFactor(
                type: .exercise,
                value: Double(digitalTwin.lifestyle.exerciseFrequency),
                protectionMultiplier: 0.8
            ))
        }
        
        if digitalTwin.lifestyle.dietQuality > 0.7 {
            protectiveFactors.append(ProtectiveFactor(
                type: .diet,
                value: digitalTwin.lifestyle.dietQuality,
                protectionMultiplier: 0.9
            ))
        }
        
        return protectiveFactors
    }
    
    private func identifyInterventionOpportunities(
        progressionStates: [DiseaseProgressionState]
    ) -> [InterventionOpportunity] {
        var opportunities: [InterventionOpportunity] = []
        
        for (index, state) in progressionStates.enumerated() {
            if index > 0 {
                let previousState = progressionStates[index - 1]
                let severityIncrease = state.severity - previousState.severity
                
                if severityIncrease > 0.05 {
                    opportunities.append(InterventionOpportunity(
                        day: state.day,
                        severity: state.severity,
                        type: .medicationAdjustment,
                        urgency: severityIncrease > 0.1 ? .high : .medium,
                        description: "Consider medication adjustment due to rapid progression"
                    ))
                }
            }
            
            if state.severity > 0.7 && state.severity < 0.9 {
                opportunities.append(InterventionOpportunity(
                    day: state.day,
                    severity: state.severity,
                    type: .lifestyleModification,
                    urgency: .medium,
                    description: "Lifestyle modifications may help slow progression"
                ))
            }
        }
        
        return opportunities
    }
    
    private func evaluateTreatment(
        digitalTwin: BioDigitalTwin,
        condition: MedicalCondition,
        treatment: Treatment
    ) -> TreatmentEvaluation {
        let efficacyScore = calculateEfficacyScore(digitalTwin: digitalTwin, condition: condition, treatment: treatment)
        let safetyScore = calculateSafetyScore(digitalTwin: digitalTwin, treatment: treatment)
        let tolerabilityScore = calculateTolerabilityScore(digitalTwin: digitalTwin, treatment: treatment)
        let costScore = calculateCostScore(treatment: treatment)
        
        let overallScore = (efficacyScore * 0.4 + safetyScore * 0.3 + tolerabilityScore * 0.2 + costScore * 0.1)
        
        return TreatmentEvaluation(
            treatment: treatment,
            efficacyScore: efficacyScore,
            safetyScore: safetyScore,
            tolerabilityScore: tolerabilityScore,
            costScore: costScore,
            overallScore: overallScore,
            contraindications: identifyContraindications(digitalTwin: digitalTwin, treatment: treatment),
            expectedSideEffects: predictSideEffects(digitalTwin: digitalTwin, treatment: treatment)
        )
    }
    
    private func calculateEfficacyScore(
        digitalTwin: BioDigitalTwin,
        condition: MedicalCondition,
        treatment: Treatment
    ) -> Double {
        var score = treatment.baseEfficacy
        
        let ageModifier = calculateAgeEfficacyModifier(age: digitalTwin.age, treatment: treatment)
        let severityModifier = calculateSeverityEfficacyModifier(severity: condition.severity, treatment: treatment)
        let comorbidityModifier = calculateComorbidityEfficacyModifier(digitalTwin: digitalTwin, treatment: treatment)
        
        score *= ageModifier * severityModifier * comorbidityModifier
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateSafetyScore(digitalTwin: BioDigitalTwin, treatment: Treatment) -> Double {
        var score = treatment.baseSafety
        
        for condition in digitalTwin.medicalConditions {
            if treatment.contraindications.contains(condition.type) {
                score *= 0.3
            }
        }
        
        let ageRisk = digitalTwin.age > 65 ? 0.9 : 1.0
        score *= ageRisk
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateTolerabilityScore(digitalTwin: BioDigitalTwin, treatment: Treatment) -> Double {
        var score = treatment.baseTolerability
        
        for allergy in digitalTwin.allergies {
            if treatment.allergens.contains(allergy) {
                score *= 0.2
            }
        }
        
        return max(0.0, min(1.0, score))
    }
    
    private func calculateCostScore(treatment: Treatment) -> Double {
        let maxAcceptableCost = 1000.0
        return max(0.0, min(1.0, (maxAcceptableCost - treatment.cost) / maxAcceptableCost))
    }
    
    private func calculateAgeEfficacyModifier(age: Int, treatment: Treatment) -> Double {
        if age < treatment.optimalAgeRange.lowerBound {
            return 0.8
        } else if age > treatment.optimalAgeRange.upperBound {
            return 0.7
        } else {
            return 1.0
        }
    }
    
    private func calculateSeverityEfficacyModifier(severity: Double, treatment: Treatment) -> Double {
        if severity < treatment.optimalSeverityRange.lowerBound {
            return 0.9
        } else if severity > treatment.optimalSeverityRange.upperBound {
            return 0.8
        } else {
            return 1.0
        }
    }
    
    private func calculateComorbidityEfficacyModifier(digitalTwin: BioDigitalTwin, treatment: Treatment) -> Double {
        let comorbidityCount = digitalTwin.medicalConditions.count
        return max(0.5, 1.0 - Double(comorbidityCount) * 0.1)
    }
    
    private func identifyContraindications(digitalTwin: BioDigitalTwin, treatment: Treatment) -> [Contraindication] {
        var contraindications: [Contraindication] = []
        
        for condition in digitalTwin.medicalConditions {
            if treatment.contraindications.contains(condition.type) {
                contraindications.append(Contraindication(
                    condition: condition.type,
                    severity: .absolute,
                    reason: "Treatment is contraindicated for this condition"
                ))
            }
        }
        
        return contraindications
    }
    
    private func predictSideEffects(digitalTwin: BioDigitalTwin, treatment: Treatment) -> [SideEffect] {
        var sideEffects: [SideEffect] = []
        
        for potentialSideEffect in treatment.potentialSideEffects {
            let probability = calculateSideEffectProbability(
                digitalTwin: digitalTwin,
                treatment: treatment,
                sideEffect: potentialSideEffect
            )
            
            if probability > 0.1 {
                sideEffects.append(SideEffect(
                    type: potentialSideEffect.type,
                    probability: probability,
                    severity: potentialSideEffect.severity,
                    onset: potentialSideEffect.onset
                ))
            }
        }
        
        return sideEffects
    }
    
    private func calculateSideEffectProbability(
        digitalTwin: BioDigitalTwin,
        treatment: Treatment,
        sideEffect: PotentialSideEffect
    ) -> Double {
        var probability = sideEffect.baseProbability
        
        let ageModifier = digitalTwin.age > 65 ? 1.3 : 1.0
        let comorbidityModifier = 1.0 + Double(digitalTwin.medicalConditions.count) * 0.1
        
        probability *= ageModifier * comorbidityModifier
        
        return min(1.0, probability)
    }
    
    private func generateCombinationTherapies(
        treatments: [Treatment],
        digitalTwin: BioDigitalTwin,
        condition: MedicalCondition
    ) -> [CombinationTherapy] {
        var combinations: [CombinationTherapy] = []
        
        for i in 0..<treatments.count {
            for j in (i+1)..<treatments.count {
                let treatment1 = treatments[i]
                let treatment2 = treatments[j]
                
                if !hasNegativeInteraction(treatment1: treatment1, treatment2: treatment2) {
                    let combination = CombinationTherapy(
                        primaryTreatment: treatment1,
                        secondaryTreatment: treatment2,
                        synergy: calculateSynergy(treatment1: treatment1, treatment2: treatment2),
                        safetyProfile: evaluateCombinationSafety(
                            treatment1: treatment1,
                            treatment2: treatment2,
                            digitalTwin: digitalTwin
                        )
                    )
                    combinations.append(combination)
                }
            }
        }
        
        return combinations.sorted { $0.synergy > $1.synergy }
    }
    
    private func hasNegativeInteraction(treatment1: Treatment, treatment2: Treatment) -> Bool {
        return treatment1.drugInteractions.contains(treatment2.id) ||
               treatment2.drugInteractions.contains(treatment1.id)
    }
    
    private func calculateSynergy(treatment1: Treatment, treatment2: Treatment) -> Double {
        if treatment1.mechanismOfAction == treatment2.mechanismOfAction {
            return 0.3
        } else if treatment1.targetPathways.contains(where: treatment2.targetPathways.contains) {
            return 0.8
        } else {
            return 0.5
        }
    }
    
    private func evaluateCombinationSafety(
        treatment1: Treatment,
        treatment2: Treatment,
        digitalTwin: BioDigitalTwin
    ) -> Double {
        let individual1Safety = calculateSafetyScore(digitalTwin: digitalTwin, treatment: treatment1)
        let individual2Safety = calculateSafetyScore(digitalTwin: digitalTwin, treatment: treatment2)
        
        let interactionRisk = hasNegativeInteraction(treatment1: treatment1, treatment2: treatment2) ? 0.5 : 1.0
        
        return min(individual1Safety, individual2Safety) * interactionRisk
    }
    
    private func generatePersonalizedRecommendations(
        digitalTwin: BioDigitalTwin,
        condition: MedicalCondition,
        optimalTreatment: TreatmentEvaluation?
    ) -> [PersonalizedRecommendation] {
        var recommendations: [PersonalizedRecommendation] = []
        
        if let treatment = optimalTreatment {
            recommendations.append(PersonalizedRecommendation(
                type: .treatment,
                priority: .high,
                description: "Recommended treatment: \(treatment.treatment.name)",
                rationale: "Based on your health profile, this treatment has the highest efficacy and safety score"
            ))
            
            if treatment.safetyScore < 0.8 {
                recommendations.append(PersonalizedRecommendation(
                    type: .monitoring,
                    priority: .high,
                    description: "Enhanced monitoring recommended during treatment",
                    rationale: "Lower safety score requires closer monitoring for adverse effects"
                ))
            }
        }
        
        if digitalTwin.lifestyle.exerciseFrequency < 3 {
            recommendations.append(PersonalizedRecommendation(
                type: .lifestyle,
                priority: .medium,
                description: "Increase exercise frequency to 3-4 times per week",
                rationale: "Regular exercise can improve treatment outcomes and overall health"
            ))
        }
        
        if condition.severity > 0.7 {
            recommendations.append(PersonalizedRecommendation(
                type: .monitoring,
                priority: .high,
                description: "Frequent monitoring recommended due to condition severity",
                rationale: "High severity conditions require close monitoring for progression"
            ))
        }
        
        return recommendations
    }
}