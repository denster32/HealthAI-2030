import Foundation
import Accelerate

class CircadianRhythmAnalyzer {
    
    // MARK: - Properties
    private let chronotypeClassifier: ChronotypeClassifier
    private let lightExposureAnalyzer: LightExposureAnalyzer
    private let melatoninRhythmPredictor: MelatoninRhythmPredictor
    
    // Circadian parameters
    private let circadianPeriod: TimeInterval = 24.1 * 3600 // ~24.1 hours in seconds
    private let sleepDriveDecayRate: Double = 0.05 // Homeostatic sleep pressure decay
    
    // Personal circadian parameters (learned from user data)
    private var personalCircadianPhase: Double = 0.0 // Phase shift from population average
    private var personalPeriodLength: TimeInterval = 24.1 * 3600
    private var personalChronotype: Chronotype = .neutral
    
    init() {
        self.chronotypeClassifier = ChronotypeClassifier()
        self.lightExposureAnalyzer = LightExposureAnalyzer()
        self.melatoninRhythmPredictor = MelatoninRhythmPredictor()
    }
    
    // MARK: - Circadian Rhythm Analysis
    
    func analyzeRhythm(from sleepSessions: [SleepSession], currentData: [HealthDataPoint]) -> CircadianRhythmAnalysis {
        
        // Analyze sleep timing patterns
        let sleepTimingAnalysis = analyzeSleepTiming(sessions: sleepSessions)
        
        // Determine chronotype
        let chronotype = chronotypeClassifier.classifyChronotype(from: sleepSessions)
        personalChronotype = chronotype
        
        // Analyze circadian phase
        let phaseAnalysis = analyzeCircadianPhase(from: sleepSessions, currentData: currentData)
        
        // Predict optimal sleep/wake times
        let optimalTiming = predictOptimalSleepTiming(chronotype: chronotype, phase: phaseAnalysis.currentPhase)
        
        // Analyze light exposure patterns
        let lightExposure = lightExposureAnalyzer.analyzeLightExposure(from: currentData)
        
        // Predict melatonin rhythm
        let melatoninRhythm = melatoninRhythmPredictor.predictMelatoninCurve(
            chronotype: chronotype,
            lightExposure: lightExposure,
            currentPhase: phaseAnalysis.currentPhase
        )
        
        // Calculate circadian disruption risk
        let disruptionRisk = calculateCircadianDisruptionRisk(
            timing: sleepTimingAnalysis,
            lightExposure: lightExposure,
            chronotype: chronotype
        )
        
        // Generate recommendations
        let recommendations = generateCircadianRecommendations(
            chronotype: chronotype,
            timing: optimalTiming,
            disruptionRisk: disruptionRisk,
            lightExposure: lightExposure
        )
        
        return CircadianRhythmAnalysis(
            chronotype: chronotype,
            currentPhase: phaseAnalysis.currentPhase,
            phaseShift: phaseAnalysis.phaseShift,
            rhythmStability: sleepTimingAnalysis.consistency,
            optimalBedtime: optimalTiming.bedtime,
            optimalWakeTime: optimalTiming.wakeTime,
            melatoninCurve: melatoninRhythm,
            lightExposureProfile: lightExposure,
            disruptionRisk: disruptionRisk,
            recommendations: recommendations,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Sleep Timing Analysis
    
    private func analyzeSleepTiming(sessions: [SleepSession]) -> SleepTimingAnalysis {
        guard !sessions.isEmpty else {
            return SleepTimingAnalysis(
                averageBedtime: Date(),
                averageWakeTime: Date(),
                bedtimeVariation: 0,
                wakeTimeVariation: 0,
                consistency: 0,
                weekdayWeekendShift: 0
            )
        }
        
        // Extract bedtimes and wake times
        let bedtimes = sessions.map { timeOfDayFromDate($0.startTime) }
        let wakeTimes = sessions.map { timeOfDayFromDate($0.endTime ?? $0.startTime) }
        
        // Calculate averages
        let avgBedtime = calculateCircularMean(bedtimes)
        let avgWakeTime = calculateCircularMean(wakeTimes)
        
        // Calculate variations (standard deviations)
        let bedtimeVariation = calculateCircularStandardDeviation(bedtimes)
        let wakeTimeVariation = calculateCircularStandardDeviation(wakeTimes)
        
        // Calculate consistency score (lower variation = higher consistency)
        let consistency = max(0, 1.0 - (bedtimeVariation + wakeTimeVariation) / 4.0)
        
        // Analyze weekday vs weekend patterns
        let weekdayWeekendShift = analyzeWeekdayWeekendShift(sessions: sessions)
        
        return SleepTimingAnalysis(
            averageBedtime: dateFromTimeOfDay(avgBedtime),
            averageWakeTime: dateFromTimeOfDay(avgWakeTime),
            bedtimeVariation: bedtimeVariation,
            wakeTimeVariation: wakeTimeVariation,
            consistency: consistency,
            weekdayWeekendShift: weekdayWeekendShift
        )
    }
    
    // MARK: - Circadian Phase Analysis
    
    private func analyzeCircadianPhase(from sessions: [SleepSession], currentData: [HealthDataPoint]) -> CircadianPhaseAnalysis {
        
        // Analyze core body temperature rhythm (if available)
        let temperaturePhase = analyzeTemperatureRhythm(from: currentData)
        
        // Analyze heart rate rhythm
        let heartRatePhase = analyzeHeartRateRhythm(from: currentData)
        
        // Analyze sleep timing phase
        let sleepPhase = analyzeSleepPhase(from: sessions)
        
        // Combine multiple phase markers
        let currentPhase = combinePhaseMarkers([
            (temperaturePhase, 0.4),    // Temperature is most reliable
            (heartRatePhase, 0.3),      // Heart rate is secondary
            (sleepPhase, 0.3)           // Sleep timing supports others
        ])
        
        // Calculate phase shift from population average
        let populationAveragePhase = 0.25 // Assuming population sleeps around 6 AM (0.25 * 24 hours)
        let phaseShift = currentPhase - populationAveragePhase
        
        personalCircadianPhase = phaseShift
        
        return CircadianPhaseAnalysis(
            currentPhase: currentPhase,
            phaseShift: phaseShift,
            confidence: calculatePhaseConfidence(temperaturePhase, heartRatePhase, sleepPhase),
            temperaturePhase: temperaturePhase,
            heartRatePhase: heartRatePhase,
            sleepPhase: sleepPhase
        )
    }
    
    private func analyzeTemperatureRhythm(from dataPoints: [HealthDataPoint]) -> Double {
        let temperatures = dataPoints.compactMap { point in
            point.bodyTemperature > 0 ? (point.bodyTemperature, timeOfDayFromDate(point.timestamp)) : nil
        }
        
        guard temperatures.count > 10 else { return 0.25 } // Default phase
        
        // Find minimum temperature time (typically 4-6 AM, around phase 0.17-0.25)
        let smoothedTemperatures = applySmoothingFilter(to: temperatures)
        let minTempTime = findMinimumTemperatureTime(smoothedTemperatures)
        
        return minTempTime / 24.0 // Convert to phase (0-1)
    }
    
    private func analyzeHeartRateRhythm(from dataPoints: [HealthDataPoint]) -> Double {
        let heartRates = dataPoints.compactMap { point in
            point.heartRate > 0 ? (point.heartRate, timeOfDayFromDate(point.timestamp)) : nil
        }
        
        guard heartRates.count > 10 else { return 0.25 } // Default phase
        
        // Find minimum heart rate time (typically during deep sleep)
        let smoothedHeartRates = applySmoothingFilter(to: heartRates)
        let minHRTime = findMinimumHeartRateTime(smoothedHeartRates)
        
        return minHRTime / 24.0 // Convert to phase (0-1)
    }
    
    private func analyzeSleepPhase(from sessions: [SleepSession]) -> Double {
        guard !sessions.isEmpty else { return 0.25 }
        
        // Use sleep midpoint as phase marker
        let sleepMidpoints = sessions.compactMap { session -> Double? in
            guard let endTime = session.endTime else { return nil }
            let midpoint = Date(timeIntervalSince1970: (session.startTime.timeIntervalSince1970 + endTime.timeIntervalSince1970) / 2)
            return timeOfDayFromDate(midpoint)
        }
        
        return calculateCircularMean(sleepMidpoints) / 24.0
    }
    
    // MARK: - Optimal Sleep Timing Prediction
    
    private func predictOptimalSleepTiming(chronotype: Chronotype, phase: Double) -> OptimalSleepTiming {
        // Base timing for neutral chronotype
        var baseBedtime: Double = 22.5  // 10:30 PM
        var baseWakeTime: Double = 6.5  // 6:30 AM
        
        // Adjust for chronotype
        switch chronotype {
        case .earlyBird:
            baseBedtime -= 1.5  // 9:00 PM
            baseWakeTime -= 1.5 // 5:00 AM
        case .nightOwl:
            baseBedtime += 2.0  // 12:30 AM
            baseWakeTime += 2.0 // 8:30 AM
        case .neutral:
            break // Keep base times
        }
        
        // Adjust for personal circadian phase
        let phaseAdjustment = personalCircadianPhase * 24.0 // Convert to hours
        baseBedtime += phaseAdjustment
        baseWakeTime += phaseAdjustment
        
        // Ensure times are within 24-hour bounds
        baseBedtime = baseBedtime.truncatingRemainder(dividingBy: 24.0)
        baseWakeTime = baseWakeTime.truncatingRemainder(dividingBy: 24.0)
        
        return OptimalSleepTiming(
            bedtime: dateFromTimeOfDay(baseBedtime),
            wakeTime: dateFromTimeOfDay(baseWakeTime),
            sleepDuration: calculateOptimalSleepDuration(chronotype: chronotype),
            confidence: 0.8
        )
    }
    
    private func calculateOptimalSleepDuration(chronotype: Chronotype) -> TimeInterval {
        // Base duration of 8 hours
        var duration: TimeInterval = 8 * 3600
        
        // Adjust slightly for chronotype
        switch chronotype {
        case .earlyBird:
            duration += 0.25 * 3600 // +15 minutes
        case .nightOwl:
            duration += 0.5 * 3600  // +30 minutes
        case .neutral:
            break
        }
        
        return duration
    }
    
    // MARK: - Circadian Disruption Risk
    
    private func calculateCircadianDisruptionRisk(
        timing: SleepTimingAnalysis,
        lightExposure: LightExposureProfile,
        chronotype: Chronotype
    ) -> CircadianDisruptionRisk {
        
        var riskFactors: [String] = []
        var riskScore: Double = 0.0
        
        // Irregular sleep timing
        if timing.consistency < 0.7 {
            riskFactors.append("Irregular sleep schedule")
            riskScore += 0.3
        }
        
        // Large weekday-weekend shift (social jet lag)
        if abs(timing.weekdayWeekendShift) > 1.0 {
            riskFactors.append("Social jet lag (large weekday-weekend sleep shift)")
            riskScore += 0.2
        }
        
        // Late night light exposure
        if lightExposure.lateNightExposure > 0.3 {
            riskFactors.append("Excessive late-night light exposure")
            riskScore += 0.25
        }
        
        // Insufficient morning light
        if lightExposure.morningLightExposure < 0.4 {
            riskFactors.append("Insufficient morning light exposure")
            riskScore += 0.2
        }
        
        // Chronotype mismatch (forced early wake for night owls, etc.)
        let chronotypeMismatch = calculateChronotypeMismatch(timing: timing, chronotype: chronotype)
        if chronotypeMismatch > 0.5 {
            riskFactors.append("Schedule conflicts with natural chronotype")
            riskScore += 0.3
        }
        
        // Blue light exposure before bedtime
        if lightExposure.blueLightExposure > 0.4 {
            riskFactors.append("High blue light exposure before bedtime")
            riskScore += 0.15
        }
        
        riskScore = min(1.0, riskScore)
        
        let riskLevel: RiskLevel
        switch riskScore {
        case 0.0..<0.3:
            riskLevel = .low
        case 0.3..<0.6:
            riskLevel = .moderate
        case 0.6..<0.8:
            riskLevel = .high
        default:
            riskLevel = .severe
        }
        
        return CircadianDisruptionRisk(
            level: riskLevel,
            score: riskScore,
            factors: riskFactors,
            recommendations: generateRiskMitigationRecommendations(factors: riskFactors)
        )
    }
    
    // MARK: - Utility Methods
    
    private func timeOfDayFromDate(_ date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return Double(hour) + Double(minute) / 60.0
    }
    
    private func dateFromTimeOfDay(_ timeOfDay: Double) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hours = Int(timeOfDay)
        let minutes = Int((timeOfDay - Double(hours)) * 60)
        
        return calendar.date(byAdding: .hour, value: hours, to: today)
            .flatMap { calendar.date(byAdding: .minute, value: minutes, to: $0) } ?? today
    }
    
    private func calculateCircularMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let angles = values.map { $0 * 2 * Double.pi / 24.0 } // Convert to radians
        let sumSin = angles.reduce(0) { $0 + sin($1) }
        let sumCos = angles.reduce(0) { $0 + cos($1) }
        
        let meanAngle = atan2(sumSin, sumCos)
        let meanTime = meanAngle * 24.0 / (2 * Double.pi)
        
        return meanTime < 0 ? meanTime + 24.0 : meanTime
    }
    
    private func calculateCircularStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        
        let mean = calculateCircularMean(values)
        let angles = values.map { $0 * 2 * Double.pi / 24.0 }
        let meanAngle = mean * 2 * Double.pi / 24.0
        
        let sumCos = angles.reduce(0) { $0 + cos($1 - meanAngle) }
        let r = sumCos / Double(values.count)
        
        return sqrt(-2 * log(r)) * 24.0 / (2 * Double.pi)
    }
    
    private func analyzeWeekdayWeekendShift(sessions: [SleepSession]) -> Double {
        let calendar = Calendar.current
        
        let weekdaySessions = sessions.filter { session in
            let weekday = calendar.component(.weekday, from: session.startTime)
            return weekday >= 2 && weekday <= 6 // Monday to Friday
        }
        
        let weekendSessions = sessions.filter { session in
            let weekday = calendar.component(.weekday, from: session.startTime)
            return weekday == 1 || weekday == 7 // Saturday and Sunday
        }
        
        guard !weekdaySessions.isEmpty && !weekendSessions.isEmpty else { return 0 }
        
        let weekdayBedtimes = weekdaySessions.map { timeOfDayFromDate($0.startTime) }
        let weekendBedtimes = weekendSessions.map { timeOfDayFromDate($0.startTime) }
        
        let weekdayMean = calculateCircularMean(weekdayBedtimes)
        let weekendMean = calculateCircularMean(weekendBedtimes)
        
        var shift = weekendMean - weekdayMean
        
        // Handle circular nature of time
        if shift > 12 {
            shift -= 24
        } else if shift < -12 {
            shift += 24
        }
        
        return shift
    }
    
    private func combinePhaseMarkers(_ markers: [(Double, Double)]) -> Double {
        let weightedSum = markers.reduce(0) { $0 + $1.0 * $1.1 }
        let totalWeight = markers.reduce(0) { $0 + $1.1 }
        
        return weightedSum / totalWeight
    }
    
    private func calculatePhaseConfidence(_ temp: Double, _ hr: Double, _ sleep: Double) -> Double {
        // Simple confidence based on consistency between markers
        let maxDiff = max(abs(temp - hr), abs(hr - sleep), abs(sleep - temp))
        return max(0.3, 1.0 - maxDiff * 2.0)
    }
    
    private func applySmoothingFilter(to data: [(Double, Double)]) -> [(Double, Double)] {
        // Simple moving average smoothing
        guard data.count > 3 else { return data }
        
        var smoothed: [(Double, Double)] = []
        let windowSize = 3
        
        for i in 0..<data.count {
            let startIndex = max(0, i - windowSize/2)
            let endIndex = min(data.count - 1, i + windowSize/2)
            
            let window = Array(data[startIndex...endIndex])
            let avgValue = window.reduce(0) { $0 + $1.0 } / Double(window.count)
            
            smoothed.append((avgValue, data[i].1))
        }
        
        return smoothed
    }
    
    private func findMinimumTemperatureTime(_ data: [(Double, Double)]) -> Double {
        guard !data.isEmpty else { return 5.0 } // Default 5 AM
        
        let minEntry = data.min(by: { $0.0 < $1.0 })
        return minEntry?.1 ?? 5.0
    }
    
    private func findMinimumHeartRateTime(_ data: [(Double, Double)]) -> Double {
        guard !data.isEmpty else { return 4.0 } // Default 4 AM
        
        let minEntry = data.min(by: { $0.0 < $1.0 })
        return minEntry?.1 ?? 4.0
    }
    
    private func calculateChronotypeMismatch(timing: SleepTimingAnalysis, chronotype: Chronotype) -> Double {
        let actualBedtime = timeOfDayFromDate(timing.averageBedtime)
        let actualWakeTime = timeOfDayFromDate(timing.averageWakeTime)
        
        let optimalTiming = predictOptimalSleepTiming(chronotype: chronotype, phase: personalCircadianPhase)
        let optimalBedtime = timeOfDayFromDate(optimalTiming.bedtime)
        let optimalWakeTime = timeOfDayFromDate(optimalTiming.wakeTime)
        
        let bedtimeDiff = abs(actualBedtime - optimalBedtime)
        let wakeTimeDiff = abs(actualWakeTime - optimalWakeTime)
        
        return (bedtimeDiff + wakeTimeDiff) / 24.0 // Normalize to 0-1
    }
    
    private func generateCircadianRecommendations(
        chronotype: Chronotype,
        timing: OptimalSleepTiming,
        disruptionRisk: CircadianDisruptionRisk,
        lightExposure: LightExposureProfile
    ) -> [CircadianRecommendation] {
        
        var recommendations: [CircadianRecommendation] = []
        
        // Light exposure recommendations
        if lightExposure.morningLightExposure < 0.5 {
            recommendations.append(
                CircadianRecommendation(
                    type: .lightExposure,
                    priority: .high,
                    title: "Increase Morning Light Exposure",
                    description: "Get bright light exposure within 30 minutes of waking",
                    action: "Spend 15-30 minutes outdoors or use a bright light therapy lamp"
                )
            )
        }
        
        if lightExposure.lateNightExposure > 0.3 {
            recommendations.append(
                CircadianRecommendation(
                    type: .lightExposure,
                    priority: .high,
                    title: "Reduce Evening Light Exposure",
                    description: "Minimize bright light 2-3 hours before bedtime",
                    action: "Use dim lighting and blue light filters in the evening"
                )
            )
        }
        
        // Timing recommendations
        recommendations.append(
            CircadianRecommendation(
                type: .timing,
                priority: .medium,
                title: "Optimize Sleep Schedule",
                description: "Align sleep timing with your chronotype",
                action: "Target bedtime: \(formatTime(timing.bedtime)), wake time: \(formatTime(timing.wakeTime))"
            )
        )
        
        // Chronotype-specific recommendations
        switch chronotype {
        case .nightOwl:
            recommendations.append(
                CircadianRecommendation(
                    type: .lifestyle,
                    priority: .medium,
                    title: "Night Owl Optimization",
                    description: "Gradually shift bedtime earlier if needed",
                    action: "Move bedtime 15 minutes earlier each week until reaching target"
                )
            )
            
        case .earlyBird:
            recommendations.append(
                CircadianRecommendation(
                    type: .lifestyle,
                    priority: .medium,
                    title: "Early Bird Maintenance",
                    description: "Maintain consistent early schedule",
                    action: "Keep wake time consistent, even on weekends"
                )
            )
            
        case .neutral:
            break
        }
        
        // Risk-specific recommendations
        recommendations.append(contentsOf: disruptionRisk.recommendations.map { riskRec in
            CircadianRecommendation(
                type: .lifestyle,
                priority: .medium,
                title: "Address Disruption Risk",
                description: riskRec,
                action: riskRec
            )
        })
        
        return recommendations
    }
    
    private func generateRiskMitigationRecommendations(factors: [String]) -> [String] {
        var recommendations: [String] = []
        
        for factor in factors {
            switch factor {
            case let f where f.contains("Irregular"):
                recommendations.append("Establish consistent sleep and wake times")
            case let f where f.contains("Social jet lag"):
                recommendations.append("Minimize weekday-weekend sleep schedule differences")
            case let f where f.contains("late-night light"):
                recommendations.append("Use blue light filters and dim lighting after sunset")
            case let f where f.contains("morning light"):
                recommendations.append("Get bright light exposure within 1 hour of waking")
            case let f where f.contains("chronotype"):
                recommendations.append("Adjust schedule to better match natural sleep preference")
            default:
                recommendations.append("Review sleep hygiene practices")
            }
        }
        
        return recommendations
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct CircadianRhythmAnalysis {
    let chronotype: Chronotype
    let currentPhase: Double // 0-1, where 0 is midnight
    let phaseShift: Double // Hours shifted from population average
    let rhythmStability: Double // 0-1, consistency of rhythm
    let optimalBedtime: Date
    let optimalWakeTime: Date
    let melatoninCurve: MelatoninRhythmCurve
    let lightExposureProfile: LightExposureProfile
    let disruptionRisk: CircadianDisruptionRisk
    let recommendations: [CircadianRecommendation]
    let lastUpdated: Date
}

struct SleepTimingAnalysis {
    let averageBedtime: Date
    let averageWakeTime: Date
    let bedtimeVariation: Double // Hours of standard deviation
    let wakeTimeVariation: Double
    let consistency: Double // 0-1 score
    let weekdayWeekendShift: Double // Hours difference
}

struct CircadianPhaseAnalysis {
    let currentPhase: Double
    let phaseShift: Double
    let confidence: Double
    let temperaturePhase: Double
    let heartRatePhase: Double
    let sleepPhase: Double
}

struct OptimalSleepTiming {
    let bedtime: Date
    let wakeTime: Date
    let sleepDuration: TimeInterval
    let confidence: Double
}

struct CircadianDisruptionRisk {
    let level: RiskLevel
    let score: Double // 0-1
    let factors: [String]
    let recommendations: [String]
}

enum RiskLevel {
    case low
    case moderate
    case high
    case severe
}

struct CircadianRecommendation {
    let type: CircadianRecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
}

enum CircadianRecommendationType {
    case lightExposure
    case timing
    case lifestyle
    case environment
}

// Placeholder classes for future implementation
class ChronotypeClassifier {
    func classifyChronotype(from sessions: [SleepSession]) -> Chronotype {
        // Implementation would analyze sleep timing patterns
        return .neutral
    }
}

class LightExposureAnalyzer {
    func analyzeLightExposure(from data: [HealthDataPoint]) -> LightExposureProfile {
        // Implementation would analyze ambient light data
        return LightExposureProfile(
            morningLightExposure: 0.6,
            lateNightExposure: 0.2,
            blueLightExposure: 0.3,
            totalDailyExposure: 0.7
        )
    }
}

class MelatoninRhythmPredictor {
    func predictMelatoninCurve(chronotype: Chronotype, lightExposure: LightExposureProfile, currentPhase: Double) -> MelatoninRhythmCurve {
        // Implementation would predict melatonin levels throughout the day
        return MelatoninRhythmCurve(
            peakTime: Date(),
            peakLevel: 0.8,
            onsetTime: Date(),
            offsetTime: Date(),
            curve: []
        )
    }
}

struct LightExposureProfile {
    let morningLightExposure: Double // 0-1
    let lateNightExposure: Double // 0-1
    let blueLightExposure: Double // 0-1
    let totalDailyExposure: Double // 0-1
}

struct MelatoninRhythmCurve {
    let peakTime: Date
    let peakLevel: Double
    let onsetTime: Date
    let offsetTime: Date
    let curve: [(time: Date, level: Double)]
}