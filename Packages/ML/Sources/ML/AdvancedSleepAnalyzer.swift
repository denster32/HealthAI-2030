import Foundation
import CoreML
import Accelerate
import Combine

class AdvancedSleepAnalyzer: ObservableObject {
    static let shared = AdvancedSleepAnalyzer()
    
    // MARK: - Published Properties
    @Published var currentSleepAnalysis: SleepAnalysisResult?
    @Published var sleepCycleData: [SleepCycle] = []
    @Published var sleepTrends: SleepTrendAnalysis?
    @Published var circadianRhythmData: CircadianRhythmAnalysis?
    
    // MARK: - Private Properties
    private let sleepStageClassifier: SleepStageClassifier
    private let circadianRhythmAnalyzer: CircadianRhythmAnalyzer
    private let sleepQualityPredictor: SleepQualityPredictor
    private let sleepDisturbanceDetector: SleepDisturbanceDetector
    
    private var historicalSleepData: [SleepSession] = []
    private var realtimeBuffer: [HealthDataPoint] = []
    private let bufferSize = 300 // 5 minutes of data at 1Hz
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.sleepStageClassifier = SleepStageClassifier()
        self.circadianRhythmAnalyzer = CircadianRhythmAnalyzer()
        self.sleepQualityPredictor = SleepQualityPredictor()
        self.sleepDisturbanceDetector = SleepDisturbanceDetector()
        
        setupRealtimeAnalysis()
        loadHistoricalData()
    }
    
    // MARK: - Setup
    
    private func setupRealtimeAnalysis() {
        // Monitor health data changes for real-time analysis
        HealthDataManager.shared.$rawSensorData
            .debounce(for: .seconds(30), scheduler: DispatchQueue.main)
            .sink { [weak self] sensorData in
                self?.processSensorDataForSleep(sensorData)
            }
            .store(in: &cancellables)
    }
    
    private func loadHistoricalData() {
        // Load historical sleep sessions from Core Data
        DispatchQueue.global(qos: .background).async { [weak self] in
            let sessions = CoreDataManager.shared.fetchSleepSessions(limit: 100)
            
            DispatchQueue.main.async {
                self?.historicalSleepData = sessions
                self?.analyzeSleepTrends()
                self?.analyzeCircadianRhythm()
            }
        }
    }
    
    // MARK: - Real-time Sleep Analysis
    
    private func processSensorDataForSleep(_ sensorData: [SensorSample]) {
        // Convert sensor data to health data points
        let dataPoints = sensorData.map { sample in
            HealthDataPoint(
                heartRate: sample.type == .heartRate ? sample.value : 0,
                hrv: sample.type == .hrv ? sample.value : 0,
                oxygenSaturation: sample.type == .oxygenSaturation ? sample.value : 0,
                bodyTemperature: sample.type == .bodyTemperature ? sample.value : 0,
                movement: sample.type == .walkingSpeed ? sample.value : 0,
                timestamp: sample.timestamp
            )
        }
        
        // Add to real-time buffer
        realtimeBuffer.append(contentsOf: dataPoints)
        
        // Maintain buffer size
        if realtimeBuffer.count > bufferSize {
            realtimeBuffer.removeFirst(realtimeBuffer.count - bufferSize)
        }
        
        // Perform real-time analysis if we have enough data
        if realtimeBuffer.count >= 60 { // At least 1 minute of data
            performRealtimeSleepAnalysis()
        }
    }
    
    private func performRealtimeSleepAnalysis() {
        guard !realtimeBuffer.isEmpty else { return }
        
        // Extract features for sleep stage classification
        let features = extractSleepFeatures(from: realtimeBuffer)
        
        // Classify current sleep stage
        let stageResult = sleepStageClassifier.classifySleepStage(features: features)
        
        // Detect sleep disturbances
        let disturbances = sleepDisturbanceDetector.detectDisturbances(in: realtimeBuffer)
        
        // Predict sleep quality
        let qualityPrediction = sleepQualityPredictor.predictQuality(
            from: features,
            disturbances: disturbances
        )
        
        // ENHANCED: Perform predictive analytics
        let riskAnalysis = performSleepRiskAnalysis(features: features, stage: stageResult.stage, disturbances: disturbances)
        let interventionSuggestions = generatePredictiveInterventions(riskAnalysis: riskAnalysis, currentStage: stageResult.stage)
        let healthDeteriorationRisk = assessHealthDeteriorationRisk(features: features, historicalData: historicalSleepData)
        
        // Create enhanced analysis result
        let analysis = EnhancedSleepAnalysisResult(
            currentStage: stageResult.stage,
            stageConfidence: stageResult.confidence,
            sleepQuality: qualityPrediction.quality,
            qualityFactors: qualityPrediction.factors,
            disturbances: disturbances,
            riskAnalysis: riskAnalysis,
            interventionSuggestions: interventionSuggestions,
            healthDeteriorationRisk: healthDeteriorationRisk,
            recommendations: generateSleepRecommendations(
                stage: stageResult.stage,
                quality: qualityPrediction.quality,
                disturbances: disturbances
            ),
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.currentSleepAnalysis = analysis
        }
        
        // Trigger alerts if high risk detected
        if healthDeteriorationRisk.severity > 0.7 {
            triggerPredictiveHealthAlert(analysis: analysis)
        }
        
        // Update sleep cycle tracking
        updateSleepCycleTracking(stage: stageResult.stage, timestamp: Date())
    }
    
    // MARK: - Sleep Feature Extraction
    
    private func extractSleepFeatures(from dataPoints: [HealthDataPoint]) -> SleepFeatures {
        let heartRates = dataPoints.compactMap { $0.heartRate > 0 ? $0.heartRate : nil }
        let hrvValues = dataPoints.compactMap { $0.hrv > 0 ? $0.hrv : nil }
        let movements = dataPoints.map { $0.movement }
        let temperatures = dataPoints.compactMap { $0.bodyTemperature > 0 ? $0.bodyTemperature : nil }
        let oxygenLevels = dataPoints.compactMap { $0.oxygenSaturation > 0 ? $0.oxygenSaturation : nil }
        
        return SleepFeatures(
            heartRateAverage: calculateMean(heartRates),
            heartRateVariability: calculateStandardDeviation(heartRates),
            hrv: calculateMean(hrvValues),
            movementVariance: calculateVariance(movements),
            temperatureAverage: calculateMean(temperatures),
            temperatureStability: 1.0 - calculateStandardDeviation(temperatures) / calculateMean(temperatures),
            oxygenSaturationAverage: calculateMean(oxygenLevels),
            breathingPatternRegularity: calculateBreathingRegularity(heartRates),
            circadianPhase: calculateCircadianPhase(),
            timeSinceLastWake: calculateTimeSinceLastWake()
        )
    }
    
    // MARK: - Sleep Cycle Tracking
    
    private func updateSleepCycleTracking(stage: SleepStageType, timestamp: Date) {
        // Update current sleep cycle
        if let lastCycle = sleepCycleData.last,
           !lastCycle.isComplete {
            
            // Add stage transition to current cycle
            let transition = SleepStageTransition(
                fromStage: lastCycle.stages.last?.stage ?? .unknown,
                toStage: stage,
                timestamp: timestamp,
                duration: timestamp.timeIntervalSince(lastCycle.stages.last?.timestamp ?? timestamp)
            )
            
            lastCycle.addStageTransition(stage: stage, timestamp: timestamp, transition: transition)
            
            // Check if cycle is complete (typically 90-120 minutes)
            if lastCycle.duration >= 5400 && stage == .awake { // 90 minutes
                lastCycle.markAsComplete()
                startNewSleepCycle(initialStage: stage, timestamp: timestamp)
            }
        } else {
            // Start new sleep cycle
            startNewSleepCycle(initialStage: stage, timestamp: timestamp)
        }
    }
    
    private func startNewSleepCycle(initialStage: SleepStageType, timestamp: Date) {
        let newCycle = SleepCycle(startTime: timestamp, initialStage: initialStage)
        sleepCycleData.append(newCycle)
        
        // Limit to last 10 cycles
        if sleepCycleData.count > 10 {
            sleepCycleData.removeFirst()
        }
    }
    
    // MARK: - Sleep Trend Analysis
    
    private func analyzeSleepTrends() {
        guard historicalSleepData.count >= 7 else { return } // Need at least a week of data
        
        let last7Days = Array(historicalSleepData.suffix(7))
        let last30Days = Array(historicalSleepData.suffix(min(30, historicalSleepData.count)))
        
        // Analyze sleep duration trends
        let durationTrend = analyzeDurationTrend(sessions: last30Days)
        
        // Analyze sleep quality trends
        let qualityTrend = analyzeQualityTrend(sessions: last30Days)
        
        // Analyze sleep consistency
        let consistencyScore = analyzeSleepConsistency(sessions: last7Days)
        
        // Analyze sleep debt
        let sleepDebt = calculateSleepDebt(sessions: last7Days)
        
        // Generate insights
        let insights = generateTrendInsights(
            durationTrend: durationTrend,
            qualityTrend: qualityTrend,
            consistency: consistencyScore,
            sleepDebt: sleepDebt
        )
        
        let trendAnalysis = SleepTrendAnalysis(
            durationTrend: durationTrend,
            qualityTrend: qualityTrend,
            consistencyScore: consistencyScore,
            sleepDebt: sleepDebt,
            insights: insights,
            lastUpdated: Date()
        )
        
        DispatchQueue.main.async {
            self.sleepTrends = trendAnalysis
        }
    }
    
    // MARK: - Circadian Rhythm Analysis
    
    private func analyzeCircadianRhythm() {
        let analysis = circadianRhythmAnalyzer.analyzeRhythm(
            from: historicalSleepData,
            currentData: realtimeBuffer
        )
        
        DispatchQueue.main.async {
            self.circadianRhythmData = analysis
        }
    }
    
    // MARK: - Sleep Recommendations
    
    private func generateSleepRecommendations(
        stage: SleepStageType,
        quality: Double,
        disturbances: [SleepDisturbance]
    ) -> [SleepRecommendation] {
        var recommendations: [SleepRecommendation] = []
        
        // Stage-specific recommendations
        switch stage {
        case .awake:
            if Calendar.current.component(.hour, from: Date()) < 6 {
                recommendations.append(
                    SleepRecommendation(
                        type: .environmental,
                        priority: .high,
                        title: "Optimize Sleep Environment",
                        description: "Consider reducing light and noise to promote sleep onset",
                        action: "Activate sleep mode on smart home devices"
                    )
                )
            }
            
        case .lightSleep:
            recommendations.append(
                SleepRecommendation(
                    type: .behavioral,
                    priority: .medium,
                    title: "Maintain Sleep Environment",
                    description: "Keep environment conducive to deeper sleep",
                    action: "Avoid disruptions and maintain optimal temperature"
                )
            )
            
        case .deepSleep:
            // No recommendations during deep sleep to avoid disruption
            break
            
        case .remSleep:
            if quality < 0.7 {
                recommendations.append(
                    SleepRecommendation(
                        type: .health,
                        priority: .medium,
                        title: "REM Sleep Quality",
                        description: "REM sleep quality could be improved",
                        action: "Review stress levels and evening routine"
                    )
                )
            }
            
        case .unknown:
            recommendations.append(
                SleepRecommendation(
                    type: .technical,
                    priority: .low,
                    title: "Sleep Monitoring",
                    description: "Sleep stage detection needs more data",
                    action: "Ensure consistent wearing of monitoring devices"
                )
            )
        }
        
        // Quality-based recommendations
        if quality < 0.6 {
            recommendations.append(
                SleepRecommendation(
                    type: .lifestyle,
                    priority: .high,
                    title: "Improve Sleep Quality",
                    description: "Multiple factors affecting sleep quality detected",
                    action: "Review sleep hygiene and consider lifestyle changes"
                )
            )
        }
        
        // Disturbance-based recommendations
        for disturbance in disturbances {
            switch disturbance.type {
            case .movement:
                recommendations.append(
                    SleepRecommendation(
                        type: .environmental,
                        priority: .medium,
                        title: "Reduce Sleep Disruptions",
                        description: "Excessive movement detected during sleep",
                        action: "Check mattress comfort and room temperature"
                    )
                )
                
            case .heartRateSpike:
                recommendations.append(
                    SleepRecommendation(
                        type: .health,
                        priority: .high,
                        title: "Heart Rate Irregularity",
                        description: "Elevated heart rate during sleep detected",
                        action: "Consider stress management and consult healthcare provider"
                    )
                )
                
            case .breathingIrregularity:
                recommendations.append(
                    SleepRecommendation(
                        type: .health,
                        priority: .high,
                        title: "Breathing Pattern Alert",
                        description: "Irregular breathing patterns detected",
                        action: "Consider sleep apnea screening with healthcare provider"
                    )
                )
                
            case .temperatureFluctuation:
                recommendations.append(
                    SleepRecommendation(
                        type: .environmental,
                        priority: .medium,
                        title: "Temperature Regulation",
                        description: "Body temperature fluctuations affecting sleep",
                        action: "Adjust room temperature and bedding"
                    )
                )
            }
        }
        
        return recommendations
    }
    
    // MARK: - Utility Methods
    
    private func calculateMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = calculateMean(values)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = calculateMean(values)
        return values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count - 1)
    }
    
    private func calculateBreathingRegularity(_ heartRates: [Double]) -> Double {
        // Simplified breathing regularity calculation based on heart rate variability
        guard heartRates.count > 10 else { return 0.5 }
        
        let intervalVariations = (1..<heartRates.count).map { i in
            abs(heartRates[i] - heartRates[i-1])
        }
        
        let avgVariation = calculateMean(intervalVariations)
        return max(0, 1.0 - (avgVariation / 20.0)) // Normalize to 0-1 scale
    }
    
    private func calculateCircadianPhase() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        let minute = Calendar.current.component(.minute, from: Date())
        let timeOfDay = Double(hour) + Double(minute) / 60.0
        
        // Convert to circadian phase (0-1 scale, peak around 2-4 AM for sleep)
        let phase = (timeOfDay + 6) / 24.0 // Offset so sleep peak is around 0.33-0.5
        return phase.truncatingRemainder(dividingBy: 1.0)
    }
    
    private func calculateTimeSinceLastWake() -> Double {
        // Simplified calculation - would use actual sleep session data
        let calendar = Calendar.current
        let now = Date()
        
        // Assume typical wake time around 7 AM
        var wakeTime = calendar.startOfDay(for: now)
        wakeTime = calendar.date(byAdding: .hour, value: 7, to: wakeTime) ?? wakeTime
        
        if now < wakeTime {
            // Add previous day
            wakeTime = calendar.date(byAdding: .day, value: -1, to: wakeTime) ?? wakeTime
        }
        
        return now.timeIntervalSince(wakeTime) / 3600.0 // Hours since last wake
    }
    
    private func analyzeDurationTrend(sessions: [SleepSession]) -> TrendDirection {
        guard sessions.count >= 3 else { return .stable }
        
        let recentDurations = sessions.suffix(7).map { $0.duration }
        let earlierDurations = sessions.prefix(sessions.count - 7).suffix(7).map { $0.duration }
        
        let recentAvg = calculateMean(recentDurations)
        let earlierAvg = calculateMean(earlierDurations)
        
        let change = (recentAvg - earlierAvg) / earlierAvg
        
        if change > 0.05 { return .improving }
        if change < -0.05 { return .declining }
        return .stable
    }
    
    private func analyzeQualityTrend(sessions: [SleepSession]) -> TrendDirection {
        guard sessions.count >= 3 else { return .stable }
        
        let recentQuality = sessions.suffix(7).map { $0.qualityScore }
        let earlierQuality = sessions.prefix(sessions.count - 7).suffix(7).map { $0.qualityScore }
        
        let recentAvg = calculateMean(recentQuality)
        let earlierAvg = calculateMean(earlierQuality)
        
        let change = (recentAvg - earlierAvg) / earlierAvg
        
        if change > 0.05 { return .improving }
        if change < -0.05 { return .declining }
        return .stable
    }
    
    private func analyzeSleepConsistency(sessions: [SleepSession]) -> Double {
        guard sessions.count >= 3 else { return 0.5 }
        
        let bedtimes = sessions.map { session in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: session.startTime)
            let minute = calendar.component(.minute, from: session.startTime)
            return Double(hour) + Double(minute) / 60.0
        }
        
        let bedtimeVariation = calculateStandardDeviation(bedtimes)
        return max(0, 1.0 - (bedtimeVariation / 3.0)) // Normalize to 0-1 scale
    }
    
    private func calculateSleepDebt(sessions: [SleepSession]) -> Double {
        let targetSleepHours = 8.0
        let totalSleep = sessions.reduce(0) { $0 + $1.duration / 3600.0 }
        let targetTotal = targetSleepHours * Double(sessions.count)
        return max(0, targetTotal - totalSleep)
    }
    
    private func generateTrendInsights(
        durationTrend: TrendDirection,
        qualityTrend: TrendDirection,
        consistency: Double,
        sleepDebt: Double
    ) -> [String] {
        var insights: [String] = []
        
        switch durationTrend {
        case .improving:
            insights.append("Your sleep duration has been increasing - great progress!")
        case .declining:
            insights.append("Sleep duration has been decreasing. Consider prioritizing bedtime.")
        case .stable:
            if consistency > 0.8 {
                insights.append("Excellent sleep schedule consistency!")
            }
        }
        
        switch qualityTrend {
        case .improving:
            insights.append("Sleep quality is improving. Keep up the good habits!")
        case .declining:
            insights.append("Sleep quality has declined. Review your sleep environment and routine.")
        case .stable:
            break
        }
        
        if sleepDebt > 2.0 {
            insights.append("You have significant sleep debt (\(sleepDebt, specifier: "%.1f") hours). Prioritize catching up.")
        } else if sleepDebt < 0.5 {
            insights.append("Excellent sleep balance - you're well-rested!")
        }
        
        if consistency < 0.6 {
            insights.append("Sleep schedule consistency could improve. Try to maintain regular bedtimes.")
        }
        
        return insights
    }
    
    // MARK: - Predictive Analytics
    
    private func performSleepRiskAnalysis(features: SleepFeatures, stage: SleepStageType, disturbances: [SleepDisturbance]) -> SleepRiskAnalysis {
        var riskFactors: [RiskFactor] = []
        var overallRiskScore: Double = 0.0
        
        // Heart rate risk analysis
        if features.heartRateAverage > 85 {
            let severity = min(1.0, (features.heartRateAverage - 85) / 30.0)
            riskFactors.append(RiskFactor(
                type: .elevatedHeartRate,
                severity: severity,
                description: "Heart rate elevated during sleep (\(Int(features.heartRateAverage)) BPM)",
                predictedImpact: severity * 0.3
            ))
            overallRiskScore += severity * 0.2
        }
        
        // HRV risk analysis
        if features.hrv < 20 {
            let severity = min(1.0, (20 - features.hrv) / 15.0)
            riskFactors.append(RiskFactor(
                type: .lowHRV,
                severity: severity,
                description: "Low heart rate variability indicating stress/fatigue (\(Int(features.hrv))ms)",
                predictedImpact: severity * 0.4
            ))
            overallRiskScore += severity * 0.25
        }
        
        // Movement-based risk
        if features.movementVariance > 0.6 {
            let severity = min(1.0, (features.movementVariance - 0.6) / 0.4)
            riskFactors.append(RiskFactor(
                type: .excessiveMovement,
                severity: severity,
                description: "Excessive movement during sleep indicating restlessness",
                predictedImpact: severity * 0.2
            ))
            overallRiskScore += severity * 0.15
        }
        
        // Temperature instability risk
        if features.temperatureStability < 0.7 {
            let severity = 1.0 - features.temperatureStability
            riskFactors.append(RiskFactor(
                type: .temperatureInstability,
                severity: severity,
                description: "Body temperature regulation issues during sleep",
                predictedImpact: severity * 0.15
            ))
            overallRiskScore += severity * 0.1
        }
        
        // Breathing irregularity risk
        if features.breathingPatternRegularity < 0.6 {
            let severity = 1.0 - features.breathingPatternRegularity
            riskFactors.append(RiskFactor(
                type: .breathingIrregularity,
                severity: severity,
                description: "Irregular breathing patterns detected",
                predictedImpact: severity * 0.5
            ))
            overallRiskScore += severity * 0.3
        }
        
        // Oxygen saturation risk
        if features.oxygenSaturationAverage < 95 {
            let severity = min(1.0, (95 - features.oxygenSaturationAverage) / 10.0)
            riskFactors.append(RiskFactor(
                type: .lowOxygenSaturation,
                severity: severity,
                description: "Low oxygen saturation (\(Int(features.oxygenSaturationAverage))%)",
                predictedImpact: severity * 0.6
            ))
            overallRiskScore += severity * 0.35
        }
        
        // Disturbance-based risk
        let disturbanceRisk = calculateDisturbanceRisk(disturbances)
        overallRiskScore += disturbanceRisk * 0.2
        
        return SleepRiskAnalysis(
            overallRiskScore: min(1.0, overallRiskScore),
            riskFactors: riskFactors,
            predictedSleepQualityImpact: calculatePredictedQualityImpact(riskFactors),
            interventionUrgency: calculateInterventionUrgency(overallRiskScore),
            timestamp: Date()
        )
    }
    
    private func generatePredictiveInterventions(riskAnalysis: SleepRiskAnalysis, currentStage: SleepStageType) -> [PredictiveIntervention] {
        var interventions: [PredictiveIntervention] = []
        
        for riskFactor in riskAnalysis.riskFactors {
            switch riskFactor.type {
            case .elevatedHeartRate:
                if currentStage != .awake {
                    interventions.append(PredictiveIntervention(
                        type: .environmentalAdjustment,
                        action: "Reduce room temperature by 2°C",
                        timing: .immediate,
                        expectedBenefit: 0.3,
                        confidence: 0.8
                    ))
                }
                
            case .lowHRV:
                interventions.append(PredictiveIntervention(
                    type: .biofeedbackGuidance,
                    action: "Initiate gentle breathing guidance if in light sleep",
                    timing: .nextLightSleepPhase,
                    expectedBenefit: 0.4,
                    confidence: 0.7
                ))
                
            case .excessiveMovement:
                interventions.append(PredictiveIntervention(
                    type: .environmentalAdjustment,
                    action: "Activate white noise and reduce ambient light",
                    timing: .immediate,
                    expectedBenefit: 0.25,
                    confidence: 0.75
                ))
                
            case .breathingIrregularity:
                interventions.append(PredictiveIntervention(
                    type: .healthAlert,
                    action: "Monitor for sleep apnea symptoms - consider medical consultation",
                    timing: .immediate,
                    expectedBenefit: 0.8,
                    confidence: 0.9
                ))
                
            case .lowOxygenSaturation:
                interventions.append(PredictiveIntervention(
                    type: .emergencyAlert,
                    action: "Severe: Wake user if SpO2 < 90%, seek medical attention",
                    timing: .immediate,
                    expectedBenefit: 1.0,
                    confidence: 0.95
                ))
                
            case .temperatureInstability:
                interventions.append(PredictiveIntervention(
                    type: .environmentalAdjustment,
                    action: "Adjust bedding and room climate control",
                    timing: .immediate,
                    expectedBenefit: 0.2,
                    confidence: 0.6
                ))
            }
        }
        
        return interventions
    }
    
    private func assessHealthDeteriorationRisk(features: SleepFeatures, historicalData: [SleepSession]) -> HealthDeteriorationRisk {
        var riskScore: Double = 0.0
        var riskFactors: [String] = []
        
        // Analyze trends over the past week
        if historicalData.count >= 7 {
            let recentSessions = Array(historicalData.suffix(7))
            let qualityTrend = analyzeQualityTrend(sessions: recentSessions)
            
            if qualityTrend == .declining {
                riskScore += 0.3
                riskFactors.append("Declining sleep quality trend over past week")
            }
            
            // Check for concerning patterns
            let avgHeartRate = recentSessions.map { $0.averageHeartRate ?? 70 }.reduce(0, +) / Double(recentSessions.count)
            if avgHeartRate > 80 {
                riskScore += 0.2
                riskFactors.append("Consistently elevated sleep heart rate")
            }
            
            let avgHRV = recentSessions.map { $0.averageHRV ?? 35 }.reduce(0, +) / Double(recentSessions.count)
            if avgHRV < 25 {
                riskScore += 0.25
                riskFactors.append("Persistently low HRV indicating chronic stress")
            }
        }
        
        // Current acute risks
        if features.heartRateAverage > 90 {
            riskScore += 0.4
            riskFactors.append("Acute: Very high heart rate during sleep")
        }
        
        if features.oxygenSaturationAverage < 93 {
            riskScore += 0.6
            riskFactors.append("Critical: Low oxygen saturation")
        }
        
        if features.breathingPatternRegularity < 0.5 {
            riskScore += 0.5
            riskFactors.append("Severe breathing irregularities")
        }
        
        let severity = min(1.0, riskScore)
        
        return HealthDeteriorationRisk(
            severity: severity,
            riskFactors: riskFactors,
            recommendedActions: generateHealthRiskActions(severity: severity),
            timeToIntervention: calculateTimeToIntervention(severity: severity),
            confidence: calculateRiskConfidence(riskFactors.count, historicalDataPoints: historicalData.count)
        )
    }
    
    private func triggerPredictiveHealthAlert(analysis: EnhancedSleepAnalysisResult) {
        // Send alert to alert manager for immediate processing
        let alert = PredictiveHealthAlert(
            severity: analysis.healthDeteriorationRisk.severity,
            message: "Health deterioration risk detected during sleep",
            riskFactors: analysis.healthDeteriorationRisk.riskFactors,
            recommendedActions: analysis.healthDeteriorationRisk.recommendedActions,
            interventions: analysis.interventionSuggestions,
            timestamp: Date()
        )
        
        // Post notification for background processing
        NotificationCenter.default.post(
            name: .predictiveHealthAlertTriggered,
            object: alert
        )
        
        print("AdvancedSleepAnalyzer: Predictive health alert triggered - severity: \(analysis.healthDeteriorationRisk.severity)")
    }
    
    // MARK: - Risk Calculation Helpers
    
    private func calculateDisturbanceRisk(_ disturbances: [SleepDisturbance]) -> Double {
        let totalSeverity = disturbances.reduce(0) { $0 + $1.severity }
        return min(1.0, totalSeverity / 3.0) // Normalize based on expected max disturbances
    }
    
    private func calculatePredictedQualityImpact(_ riskFactors: [RiskFactor]) -> Double {
        return riskFactors.reduce(0) { $0 + $1.predictedImpact } / Double(max(1, riskFactors.count))
    }
    
    private func calculateInterventionUrgency(_ riskScore: Double) -> InterventionUrgency {
        if riskScore > 0.8 { return .critical }
        else if riskScore > 0.6 { return .high }
        else if riskScore > 0.4 { return .medium }
        else { return .low }
    }
    
    private func generateHealthRiskActions(severity: Double) -> [String] {
        var actions: [String] = []
        
        if severity > 0.8 {
            actions.append("Consider waking user and seeking immediate medical attention")
            actions.append("Document current symptoms and vital signs")
        }
        
        if severity > 0.6 {
            actions.append("Increase monitoring frequency to every 30 seconds")
            actions.append("Prepare emergency contact protocols")
        }
        
        if severity > 0.4 {
            actions.append("Implement immediate environmental interventions")
            actions.append("Schedule follow-up analysis in 15 minutes")
        }
        
        actions.append("Log event for medical review")
        return actions
    }
    
    private func calculateTimeToIntervention(severity: Double) -> TimeInterval {
        if severity > 0.8 { return 30 } // 30 seconds
        else if severity > 0.6 { return 120 } // 2 minutes
        else if severity > 0.4 { return 300 } // 5 minutes
        else { return 900 } // 15 minutes
    }
    
    private func calculateRiskConfidence(_ factorCount: Int, historicalDataPoints: Int) -> Double {
        let factorConfidence = min(1.0, Double(factorCount) / 3.0)
        let dataConfidence = min(1.0, Double(historicalDataPoints) / 14.0)
        return (factorConfidence + dataConfidence) / 2.0
    }
}

// MARK: - Enhanced Supporting Types

struct EnhancedSleepAnalysisResult {
    let currentStage: SleepStageType
    let stageConfidence: Double
    let sleepQuality: Double
    let qualityFactors: [QualityFactor]
    let disturbances: [SleepDisturbance]
    let riskAnalysis: SleepRiskAnalysis
    let interventionSuggestions: [PredictiveIntervention]
    let healthDeteriorationRisk: HealthDeteriorationRisk
    let recommendations: [SleepRecommendation]
    let timestamp: Date
}

struct SleepRiskAnalysis {
    let overallRiskScore: Double
    let riskFactors: [RiskFactor]
    let predictedSleepQualityImpact: Double
    let interventionUrgency: InterventionUrgency
    let timestamp: Date
}

struct RiskFactor {
    let type: RiskType
    let severity: Double
    let description: String
    let predictedImpact: Double
}

enum RiskType {
    case elevatedHeartRate
    case lowHRV
    case excessiveMovement
    case temperatureInstability
    case breathingIrregularity
    case lowOxygenSaturation
}

struct PredictiveIntervention {
    let type: InterventionType
    let action: String
    let timing: InterventionTiming
    let expectedBenefit: Double
    let confidence: Double
}

enum InterventionType {
    case environmentalAdjustment
    case biofeedbackGuidance
    case healthAlert
    case emergencyAlert
}

enum InterventionTiming {
    case immediate
    case nextLightSleepPhase
    case nextREMPhase
    case uponWaking
}

enum InterventionUrgency {
    case low
    case medium
    case high
    case critical
}

struct HealthDeteriorationRisk {
    let severity: Double
    let riskFactors: [String]
    let recommendedActions: [String]
    let timeToIntervention: TimeInterval
    let confidence: Double
}

struct PredictiveHealthAlert {
    let severity: Double
    let message: String
    let riskFactors: [String]
    let recommendedActions: [String]
    let interventions: [PredictiveIntervention]
    let timestamp: Date
}

extension Notification.Name {
    static let predictiveHealthAlertTriggered = Notification.Name("predictiveHealthAlertTriggered")
}

// MARK: - Supporting Types

struct SleepAnalysisResult {
    let currentStage: SleepStageType
    let stageConfidence: Double
    let sleepQuality: Double
    let qualityFactors: [QualityFactor]
    let disturbances: [SleepDisturbance]
    let recommendations: [SleepRecommendation]
    let timestamp: Date
}

struct SleepFeatures {
    let heartRateAverage: Double
    let heartRateVariability: Double
    let hrv: Double
    let movementVariance: Double
    let temperatureAverage: Double
    let temperatureStability: Double
    let oxygenSaturationAverage: Double
    let breathingPatternRegularity: Double
    let circadianPhase: Double
    let timeSinceLastWake: Double
}

struct HealthDataPoint {
    let heartRate: Double
    let hrv: Double
    let oxygenSaturation: Double
    let bodyTemperature: Double
    let movement: Double
    let timestamp: Date
}

struct SleepCycle {
    let id = UUID()
    let startTime: Date
    var endTime: Date?
    var stages: [SleepStageData] = []
    var transitions: [SleepStageTransition] = []
    var isComplete = false
    
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    init(startTime: Date, initialStage: SleepStageType) {
        self.startTime = startTime
        self.stages.append(SleepStageData(stage: initialStage, timestamp: startTime, duration: 0))
    }
    
    mutating func addStageTransition(stage: SleepStageType, timestamp: Date, transition: SleepStageTransition) {
        // Update duration of last stage
        if var lastStage = stages.last {
            lastStage.duration = timestamp.timeIntervalSince(lastStage.timestamp)
            stages[stages.count - 1] = lastStage
        }
        
        // Add new stage
        stages.append(SleepStageData(stage: stage, timestamp: timestamp, duration: 0))
        transitions.append(transition)
    }
    
    mutating func markAsComplete() {
        isComplete = true
        endTime = Date()
        
        // Update final stage duration
        if var lastStage = stages.last {
            lastStage.duration = (endTime ?? Date()).timeIntervalSince(lastStage.timestamp)
            stages[stages.count - 1] = lastStage
        }
    }
}

struct SleepStageData {
    let stage: SleepStageType
    let timestamp: Date
    var duration: TimeInterval
}

struct SleepStageTransition {
    let fromStage: SleepStageType
    let toStage: SleepStageType
    let timestamp: Date
    let duration: TimeInterval
}

struct SleepDisturbance {
    let type: DisturbanceType
    let severity: Double
    let timestamp: Date
    let duration: TimeInterval
    let context: [String: Any]
}

enum DisturbanceType {
    case movement
    case heartRateSpike
    case breathingIrregularity
    case temperatureFluctuation
}

struct SleepRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
}

enum RecommendationType {
    case environmental
    case behavioral
    case health
    case lifestyle
    case technical
}

enum RecommendationPriority {
    case low
    case medium
    case high
}

struct SleepTrendAnalysis {
    let durationTrend: TrendDirection
    let qualityTrend: TrendDirection
    let consistencyScore: Double
    let sleepDebt: Double
    let insights: [String]
    let lastUpdated: Date
}

enum TrendDirection {
    case improving
    case stable
    case declining
}

struct QualityFactor {
    let name: String
    let impact: Double // -1.0 to 1.0
    let description: String
}