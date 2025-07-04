import Foundation
import HealthKit
import os.log

// MARK: - Cardiovascular Feature Processor
class CardiovascularFeatureProcessor {
    private let logger = Logger(subsystem: "com.healthai.2030", category: "CardiovascularProcessor")
    
    func process(
        heartRateData: [HKQuantitySample],
        hrvData: [HKQuantitySample],
        respiratoryData: [HKQuantitySample],
        oxygenData: [HKQuantitySample]
    ) -> CardiovascularFeatures {
        
        // Heart Rate Processing
        let heartRates = heartRateData.map { $0.quantity.doubleValue(for: .beatsPerMinute()) }
        let heartRateAverage = heartRates.isEmpty ? 0.0 : heartRates.reduce(0, +) / Double(heartRates.count)
        let heartRateVariability = calculateStandardDeviation(heartRates)
        let heartRateMin = heartRates.min() ?? 0.0
        let heartRateMax = heartRates.max() ?? 0.0
        let heartRateRange = heartRateMax - heartRateMin
        let restingHeartRate = calculateRestingHeartRate(heartRates)
        
        // HRV Processing
        let hrvValues = hrvData.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        let hrvAverage = hrvValues.isEmpty ? 0.0 : hrvValues.reduce(0, +) / Double(hrvValues.count)
        let hrvVariability = calculateStandardDeviation(hrvValues)
        let rmssd = calculateRMSSD(from: heartRateData)
        let sdnn = calculateSDNN(from: heartRateData)
        let pnn50 = calculatePNN50(from: heartRateData)
        
        // Respiratory Rate Processing
        let respiratoryRates = respiratoryData.map { $0.quantity.doubleValue(for: .hertz()) }
        let respiratoryRateAverage = respiratoryRates.isEmpty ? 0.0 : respiratoryRates.reduce(0, +) / Double(respiratoryRates.count)
        let respiratoryRateVariability = calculateStandardDeviation(respiratoryRates)
        
        // Oxygen Saturation Processing
        let oxygenSaturations = oxygenData.map { $0.quantity.doubleValue(for: .percent()) * 100 }
        let oxygenSaturationAverage = oxygenSaturations.isEmpty ? 0.0 : oxygenSaturations.reduce(0, +) / Double(oxygenSaturations.count)
        let oxygenSaturationVariability = calculateStandardDeviation(oxygenSaturations)
        let oxygenSaturationMin = oxygenSaturations.min() ?? 0.0
        
        // Derived Metrics
        let cardiovascularStress = calculateCardiovascularStress(
            heartRateAverage: heartRateAverage,
            hrvAverage: hrvAverage,
            respiratoryRateAverage: respiratoryRateAverage
        )
        
        let autonomicBalance = calculateAutonomicBalance(
            hrvAverage: hrvAverage,
            heartRateAverage: heartRateAverage,
            respiratoryRateAverage: respiratoryRateAverage
        )
        
        return CardiovascularFeatures(
            heartRateAverage: heartRateAverage,
            heartRateVariability: heartRateVariability,
            heartRateMin: heartRateMin,
            heartRateMax: heartRateMax,
            heartRateRange: heartRateRange,
            restingHeartRate: restingHeartRate,
            hrvAverage: hrvAverage,
            hrvVariability: hrvVariability,
            rmssd: rmssd,
            sdnn: sdnn,
            pnn50: pnn50,
            respiratoryRateAverage: respiratoryRateAverage,
            respiratoryRateVariability: respiratoryRateVariability,
            oxygenSaturationAverage: oxygenSaturationAverage,
            oxygenSaturationVariability: oxygenSaturationVariability,
            oxygenSaturationMin: oxygenSaturationMin,
            cardiovascularStress: cardiovascularStress,
            autonomicBalance: autonomicBalance,
            timestamp: Date()
        )
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func calculateRestingHeartRate(_ heartRates: [Double]) -> Double {
        guard !heartRates.isEmpty else { return 0.0 }
        let sortedRates = heartRates.sorted()
        let bottomPercentile = Int(Double(sortedRates.count) * 0.1)
        let restingRates = Array(sortedRates[0..<max(1, bottomPercentile)])
        return restingRates.reduce(0, +) / Double(restingRates.count)
    }
    
    private func calculateRMSSD(from heartRateData: [HKQuantitySample]) -> Double {
        guard heartRateData.count > 1 else { return 0.0 }
        
        let rrIntervals = heartRateData.map { 60.0 / $0.quantity.doubleValue(for: .beatsPerMinute()) }
        guard rrIntervals.count > 1 else { return 0.0 }
        
        var squaredDifferences: [Double] = []
        for i in 0..<(rrIntervals.count - 1) {
            let diff = rrIntervals[i+1] - rrIntervals[i]
            squaredDifferences.append(pow(diff, 2))
        }
        
        let meanSquaredDifference = squaredDifferences.reduce(0, +) / Double(squaredDifferences.count)
        return sqrt(meanSquaredDifference) * 1000 // Convert to milliseconds
    }
    
    private func calculateSDNN(from heartRateData: [HKQuantitySample]) -> Double {
        guard heartRateData.count > 1 else { return 0.0 }
        
        let rrIntervals = heartRateData.map { 60.0 / $0.quantity.doubleValue(for: .beatsPerMinute()) }
        return calculateStandardDeviation(rrIntervals) * 1000 // Convert to milliseconds
    }
    
    private func calculatePNN50(from heartRateData: [HKQuantitySample]) -> Double {
        guard heartRateData.count > 1 else { return 0.0 }
        
        let rrIntervals = heartRateData.map { 60.0 / $0.quantity.doubleValue(for: .beatsPerMinute()) }
        guard rrIntervals.count > 1 else { return 0.0 }
        
        var consecutiveDifferences: [Double] = []
        for i in 0..<(rrIntervals.count - 1) {
            let diff = abs(rrIntervals[i+1] - rrIntervals[i])
            consecutiveDifferences.append(diff)
        }
        
        let nn50Count = consecutiveDifferences.filter { $0 > 0.05 }.count // 50ms threshold
        return Double(nn50Count) / Double(consecutiveDifferences.count) * 100
    }
    
    private func calculateCardiovascularStress(
        heartRateAverage: Double,
        hrvAverage: Double,
        respiratoryRateAverage: Double
    ) -> Double {
        let normalizedHR = min(1.0, max(0.0, (heartRateAverage - 60) / 40))
        let normalizedHRV = min(1.0, max(0.0, (50 - hrvAverage) / 50))
        let normalizedRR = min(1.0, max(0.0, (respiratoryRateAverage - 12) / 8))
        
        return (normalizedHR * 0.5) + (normalizedHRV * 0.3) + (normalizedRR * 0.2)
    }
    
    private func calculateAutonomicBalance(
        hrvAverage: Double,
        heartRateAverage: Double,
        respiratoryRateAverage: Double
    ) -> Double {
        let sympatheticScore = (heartRateAverage - 60) / 40
        let parasympatheticScore = (hrvAverage - 20) / 80
        let respiratoryScore = (respiratoryRateAverage - 12) / 8
        
        return (parasympatheticScore - sympatheticScore - respiratoryScore) / 3
    }
}

// MARK: - Sleep Feature Processor
class SleepFeatureProcessor {
    private let logger = Logger(subsystem: "com.healthai.2030", category: "SleepProcessor")
    
    func process(sleepData: [HKCategorySample]) -> SleepFeatures {
        let sleepSessions = analyzeSleepSessions(sleepData)
        
        let totalSleepTime = sleepSessions.reduce(0) { $0 + $1.duration }
        let averageSleepTime = sleepSessions.isEmpty ? 0.0 : totalSleepTime / Double(sleepSessions.count)
        
        let sleepEfficiency = calculateSleepEfficiency(sleepSessions)
        let sleepOnset = calculateAverageSleepOnset(sleepSessions)
        let wakingCount = calculateAverageWakingCount(sleepSessions)
        
        let deepSleepPercentage = calculateDeepSleepPercentage(sleepSessions)
        let remSleepPercentage = calculateREMSleepPercentage(sleepSessions)
        let lightSleepPercentage = calculateLightSleepPercentage(sleepSessions)
        
        let sleepRegularity = calculateSleepRegularity(sleepSessions)
        let sleepDebt = calculateSleepDebt(sleepSessions)
        
        return SleepFeatures(
            totalSleepTime: totalSleepTime,
            averageSleepTime: averageSleepTime,
            sleepEfficiency: sleepEfficiency,
            sleepOnset: sleepOnset,
            wakingCount: wakingCount,
            deepSleepPercentage: deepSleepPercentage,
            remSleepPercentage: remSleepPercentage,
            lightSleepPercentage: lightSleepPercentage,
            sleepRegularity: sleepRegularity,
            sleepDebt: sleepDebt,
            timestamp: Date()
        )
    }
    
    private func analyzeSleepSessions(_ sleepData: [HKCategorySample]) -> [SleepSession] {
        var sessions: [SleepSession] = []
        
        let sleepSamples = sleepData.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
        
        for sample in sleepSamples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600 // Convert to hours
            let session = SleepSession(
                startTime: sample.startDate,
                endTime: sample.endDate,
                duration: duration,
                qualityScore: Double.random(in: 0.6...1.0), // Placeholder
                timeInBed: duration * 1.1 // Estimate time in bed
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func calculateSleepEfficiency(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let totalSleep = sessions.reduce(0) { $0 + $1.duration }
        let totalTimeInBed = sessions.reduce(0) { $0 + $1.timeInBed }
        
        return totalTimeInBed > 0 ? totalSleep / totalTimeInBed : 0.0
    }
    
    private func calculateAverageSleepOnset(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let onsetTimes = sessions.map { session in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: session.startTime)
            return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        }
        
        return onsetTimes.reduce(0, +) / Double(onsetTimes.count)
    }
    
    private func calculateAverageWakingCount(_ sessions: [SleepSession]) -> Double {
        return Double.random(in: 1...5) // Placeholder - would need accelerometer data
    }
    
    private func calculateDeepSleepPercentage(_ sessions: [SleepSession]) -> Double {
        return Double.random(in: 0.15...0.25) // Placeholder - would need sleep staging
    }
    
    private func calculateREMSleepPercentage(_ sessions: [SleepSession]) -> Double {
        return Double.random(in: 0.20...0.30) // Placeholder - would need sleep staging
    }
    
    private func calculateLightSleepPercentage(_ sessions: [SleepSession]) -> Double {
        return Double.random(in: 0.45...0.65) // Placeholder - would need sleep staging
    }
    
    private func calculateSleepRegularity(_ sessions: [SleepSession]) -> Double {
        guard sessions.count > 1 else { return 0.0 }
        
        let bedtimes = sessions.map { session in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: session.startTime)
            return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
        }
        
        let standardDeviation = calculateStandardDeviation(bedtimes)
        return max(0.0, 1.0 - (standardDeviation / 2.0)) // Normalize to 0-1 scale
    }
    
    private func calculateSleepDebt(_ sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        
        let averageSleep = sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
        let targetSleep = 8.0 // hours
        
        return max(0.0, targetSleep - averageSleep)
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - Activity Feature Processor
class ActivityFeatureProcessor {
    private let logger = Logger(subsystem: "com.healthai.2030", category: "ActivityProcessor")
    
    func process(
        stepData: [HKQuantitySample],
        activeEnergyData: [HKQuantitySample],
        workoutData: [HKWorkout]
    ) -> ActivityFeatures {
        
        let steps = stepData.map { $0.quantity.doubleValue(for: .count()) }
        let stepCount = steps.reduce(0, +)
        let stepCountVariability = calculateStandardDeviation(steps)
        
        let activeEnergy = activeEnergyData.map { $0.quantity.doubleValue(for: .kilocalorie()) }
        let activeEnergyBurned = activeEnergy.reduce(0, +)
        
        let workoutDuration = workoutData.reduce(0) { $0 + $1.duration / 60 } // Convert to minutes
        let workoutIntensity = calculateWorkoutIntensity(workoutData)
        
        let activeMinutes = calculateActiveMinutes(stepData, activeEnergyData)
        let sedentaryMinutes = max(0, 1440 - activeMinutes) // 24 hours - active minutes
        
        let activityConsistency = calculateActivityConsistency(stepData)
        let dailyActivityGoalProgress = calculateActivityGoalProgress(stepCount, activeEnergyBurned)
        
        return ActivityFeatures(
            stepCount: stepCount,
            stepCountVariability: stepCountVariability,
            activeMinutes: activeMinutes,
            sedentaryMinutes: sedentaryMinutes,
            activeEnergyBurned: activeEnergyBurned,
            workoutDuration: workoutDuration,
            workoutIntensity: workoutIntensity,
            activityConsistency: activityConsistency,
            dailyActivityGoalProgress: dailyActivityGoalProgress,
            timestamp: Date()
        )
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func calculateWorkoutIntensity(_ workouts: [HKWorkout]) -> Double {
        guard !workouts.isEmpty else { return 0.0 }
        
        let totalEnergy = workouts.reduce(0) { $0 + ($1.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0) }
        let totalDuration = workouts.reduce(0) { $0 + $1.duration / 60 } // minutes
        
        return totalDuration > 0 ? totalEnergy / totalDuration : 0.0
    }
    
    private func calculateActiveMinutes(_ stepData: [HKQuantitySample], _ energyData: [HKQuantitySample]) -> Double {
        let stepThreshold = 100.0 // steps per minute for active
        let energyThreshold = 3.0 // kcal per minute for active
        
        let activeStepMinutes = stepData.filter { sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60 // minutes
            let stepsPerMinute = sample.quantity.doubleValue(for: .count()) / duration
            return stepsPerMinute >= stepThreshold
        }.count
        
        let activeEnergyMinutes = energyData.filter { sample in
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60 // minutes
            let energyPerMinute = sample.quantity.doubleValue(for: .kilocalorie()) / duration
            return energyPerMinute >= energyThreshold
        }.count
        
        return Double(max(activeStepMinutes, activeEnergyMinutes))
    }
    
    private func calculateActivityConsistency(_ stepData: [HKQuantitySample]) -> Double {
        guard stepData.count > 1 else { return 0.0 }
        
        let dailySteps = groupStepsByDay(stepData)
        let steps = dailySteps.map { $0.value }
        
        guard steps.count > 1 else { return 0.0 }
        
        let mean = steps.reduce(0, +) / Double(steps.count)
        let standardDeviation = calculateStandardDeviation(steps)
        
        let coefficientOfVariation = mean > 0 ? standardDeviation / mean : 0.0
        return max(0.0, 1.0 - coefficientOfVariation) // Higher consistency = lower CV
    }
    
    private func groupStepsByDay(_ stepData: [HKQuantitySample]) -> [String: Double] {
        var dailySteps: [String: Double] = [:]
        let calendar = Calendar.current
        
        for sample in stepData {
            let dateString = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
            let key = "\\(dateString.year!)-\\(dateString.month!)-\\(dateString.day!)"
            dailySteps[key, default: 0.0] += sample.quantity.doubleValue(for: .count())
        }
        
        return dailySteps
    }
    
    private func calculateActivityGoalProgress(_ stepCount: Double, _ activeEnergy: Double) -> Double {
        let stepGoal = 10000.0
        let energyGoal = 400.0 // kcal
        
        let stepProgress = min(1.0, stepCount / stepGoal)
        let energyProgress = min(1.0, activeEnergy / energyGoal)
        
        return (stepProgress + energyProgress) / 2.0
    }
}

// MARK: - Environmental Feature Processor
class EnvironmentalFeatureProcessor {
    func process(audioExposureData: [HKQuantitySample]) -> EnvironmentalFeatures {
        let audioLevels = audioExposureData.map { $0.quantity.doubleValue(for: .decibelAWeighted()) }
        
        let audioExposureLevel = audioLevels.isEmpty ? 0.0 : audioLevels.reduce(0, +) / Double(audioLevels.count)
        let audioExposureVariability = calculateStandardDeviation(audioLevels)
        let noisePollutionScore = calculateNoisePollutionScore(audioLevels)
        
        return EnvironmentalFeatures(
            audioExposureLevel: audioExposureLevel,
            audioExposureVariability: audioExposureVariability,
            noisePollutionScore: noisePollutionScore,
            timestamp: Date()
        )
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    private func calculateNoisePollutionScore(_ audioLevels: [Double]) -> Double {
        guard !audioLevels.isEmpty else { return 0.0 }
        
        let noisyLevels = audioLevels.filter { $0 > 70.0 } // WHO noise pollution threshold
        return Double(noisyLevels.count) / Double(audioLevels.count)
    }
}

// MARK: - Circadian Feature Processor
class CircadianFeatureProcessor {
    func process(sleepData: [HKCategorySample], activityData: [HKQuantitySample]) -> CircadianFeatures {
        let sleepRegularity = calculateSleepRegularity(sleepData)
        let sleepMidpoint = calculateSleepMidpoint(sleepData)
        let sleepMidpointVariability = calculateSleepMidpointVariability(sleepData)
        let socialJetlag = calculateSocialJetlag(sleepData)
        let chronotype = calculateChronotype(sleepData)
        let lightExposureScore = calculateLightExposureScore() // Placeholder
        let activityRhythmStrength = calculateActivityRhythmStrength(activityData)
        
        return CircadianFeatures(
            sleepRegularity: sleepRegularity,
            sleepMidpoint: sleepMidpoint,
            sleepMidpointVariability: sleepMidpointVariability,
            socialJetlag: socialJetlag,
            chronotype: chronotype,
            lightExposureScore: lightExposureScore,
            activityRhythmStrength: activityRhythmStrength,
            timestamp: Date()
        )
    }
    
    private func calculateSleepRegularity(_ sleepData: [HKCategorySample]) -> Double {
        return Double.random(in: 0.6...0.9) // Placeholder implementation
    }
    
    private func calculateSleepMidpoint(_ sleepData: [HKCategorySample]) -> Double {
        return Double.random(in: 2...4) // Placeholder: 2-4 AM
    }
    
    private func calculateSleepMidpointVariability(_ sleepData: [HKCategorySample]) -> Double {
        return Double.random(in: 0.5...2.0) // Placeholder: hours of variability
    }
    
    private func calculateSocialJetlag(_ sleepData: [HKCategorySample]) -> Double {
        return Double.random(in: 0...2) // Placeholder: hours of social jetlag
    }
    
    private func calculateChronotype(_ sleepData: [HKCategorySample]) -> Double {
        return Double.random(in: -2...2) // Placeholder: -2 (evening) to 2 (morning)
    }
    
    private func calculateLightExposureScore() -> Double {
        return Double.random(in: 0.5...1.0) // Placeholder
    }
    
    private func calculateActivityRhythmStrength(_ activityData: [HKQuantitySample]) -> Double {
        return Double.random(in: 0.6...0.95) // Placeholder
    }
}

// MARK: - Nutrition Feature Processor
class NutritionFeatureProcessor {
    func process() -> NutritionFeatures {
        // Placeholder implementation - would integrate with nutrition tracking
        return NutritionFeatures(
            nutritionScore: Double.random(in: 0.6...0.9),
            hydrationLevel: Double.random(in: 0.5...1.0),
            caffeineIntake: Double.random(in: 0...300), // mg
            lastMealTiming: Double.random(in: 1...12), // hours ago
            timestamp: Date()
        )
    }
}

// MARK: - Stress Feature Processor
class StressFeatureProcessor {
    func process(
        hrvData: [HKQuantitySample],
        heartRateData: [HKQuantitySample],
        mindfulnessData: [HKCategorySample]
    ) -> StressFeatures {
        
        let stressScore = calculateStressScore(hrvData, heartRateData)
        let stressVariability = calculateStressVariability(hrvData)
        let mindfulnessMinutes = calculateMindfulnessMinutes(mindfulnessData)
        let stressRecoveryRate = calculateStressRecoveryRate(hrvData)
        let autonomicStressIndex = calculateAutonomicStressIndex(hrvData, heartRateData)
        
        return StressFeatures(
            stressScore: stressScore,
            stressVariability: stressVariability,
            mindfulnessMinutes: mindfulnessMinutes,
            stressRecoveryRate: stressRecoveryRate,
            autonomicStressIndex: autonomicStressIndex,
            timestamp: Date()
        )
    }
    
    private func calculateStressScore(_ hrvData: [HKQuantitySample], _ heartRateData: [HKQuantitySample]) -> Double {
        let hrvValues = hrvData.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        let heartRates = heartRateData.map { $0.quantity.doubleValue(for: .beatsPerMinute()) }
        
        let avgHRV = hrvValues.isEmpty ? 0.0 : hrvValues.reduce(0, +) / Double(hrvValues.count)
        let avgHR = heartRates.isEmpty ? 0.0 : heartRates.reduce(0, +) / Double(heartRates.count)
        
        // Stress inversely correlated with HRV, positively with HR
        let hrvStress = max(0.0, 1.0 - (avgHRV / 50.0))
        let hrStress = max(0.0, (avgHR - 60.0) / 40.0)
        
        return min(1.0, (hrvStress + hrStress) / 2.0)
    }
    
    private func calculateStressVariability(_ hrvData: [HKQuantitySample]) -> Double {
        let hrvValues = hrvData.map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        return calculateStandardDeviation(hrvValues) / 50.0 // Normalize
    }
    
    private func calculateMindfulnessMinutes(_ mindfulnessData: [HKCategorySample]) -> Double {
        return mindfulnessData.reduce(0) { result, sample in
            result + sample.endDate.timeIntervalSince(sample.startDate) / 60 // Convert to minutes
        }
    }
    
    private func calculateStressRecoveryRate(_ hrvData: [HKQuantitySample]) -> Double {
        guard hrvData.count > 1 else { return 0.0 }
        
        let sortedData = hrvData.sorted { $0.startDate < $1.startDate }
        let recentHRV = sortedData.suffix(10).map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        let earlierHRV = sortedData.prefix(10).map { $0.quantity.doubleValue(for: .secondUnit(with: .milli)) }
        
        let recentAvg = recentHRV.reduce(0, +) / Double(recentHRV.count)
        let earlierAvg = earlierHRV.reduce(0, +) / Double(earlierHRV.count)
        
        return (recentAvg - earlierAvg) / max(1.0, earlierAvg) // Recovery rate
    }
    
    private func calculateAutonomicStressIndex(_ hrvData: [HKQuantitySample], _ heartRateData: [HKQuantitySample]) -> Double {
        let stressScore = calculateStressScore(hrvData, heartRateData)
        let stressVariability = calculateStressVariability(hrvData)
        
        return (stressScore + stressVariability) / 2.0
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - Supporting Structures
struct SleepSession {
    let startTime: Date
    let endTime: Date
    let duration: Double
    let qualityScore: Double
    let timeInBed: Double
}