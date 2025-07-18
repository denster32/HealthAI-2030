import Foundation
import HealthAI2030Core

/// Advanced circadian rhythm tracking and optimization engine
@globalActor
public actor CircadianRhythmEngine {
    public static let shared = CircadianRhythmEngine()
    
    private var lightExposureHistory: [LightExposureEvent] = []
    private var melatoninCurve: MelatoninCurve?
    private var personalCircadianProfile: CircadianProfile?
    private var chronotype: Chronotype = .neutral
    
    private init() {
        startCircadianTracking()
        calculatePersonalChronotype()
    }
    
    // MARK: - Public Interface
    
    /// Get current circadian phase with precision timing
    public func getCurrentCircadianPhase() -> CircadianPhase {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let timeOfDay = Double(hour) + Double(minute) / 60.0
        
        // Adjust for personal chronotype
        let adjustedTime = adjustForChronotype(timeOfDay)
        
        return calculatePhaseFromTime(adjustedTime)
    }
    
    /// Predict optimal light exposure recommendations
    public func getLightExposureRecommendations() async -> [LightRecommendation] {
        let currentPhase = getCurrentCircadianPhase()
        let profile = personalCircadianProfile ?? defaultCircadianProfile()
        
        return generateLightRecommendations(phase: currentPhase, profile: profile)
    }
    
    /// Update with light exposure data (from sensors or user input)
    public func recordLightExposure(_ exposure: LightExposureEvent) async {
        lightExposureHistory.append(exposure)
        
        // Maintain rolling window of 7 days
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        lightExposureHistory.removeAll { $0.timestamp < sevenDaysAgo }
        
        // Update circadian model
        await updateCircadianModel()
    }
    
    /// Calculate shift work adjustment recommendations
    public func getShiftWorkAdjustments(for schedule: WorkSchedule) async -> ShiftWorkAdjustment {
        let currentPhase = getCurrentCircadianPhase()
        
        return ShiftWorkAdjustment(
            lightTherapyTiming: calculateLightTherapyTiming(schedule),
            melatoninTiming: calculateMelatoninTiming(schedule),
            sleepSchedule: calculateOptimalSleepSchedule(schedule),
            adjustmentDuration: calculateAdjustmentDuration(schedule)
        )
    }
    
    /// Get jet lag recovery recommendations
    public func getJetLagRecovery(
        from originTimeZone: TimeZone,
        to destinationTimeZone: TimeZone,
        travelDate: Date
    ) async -> JetLagRecovery {
        let timeDifference = calculateTimeDifference(
            from: originTimeZone,
            to: destinationTimeZone
        )
        
        return JetLagRecovery(
            adjustmentDays: calculateAdjustmentDays(timeDifference),
            lightSchedule: calculateJetLagLightSchedule(timeDifference, travelDate),
            sleepSchedule: calculateJetLagSleepSchedule(timeDifference, travelDate),
            melatoninProtocol: calculateJetLagMelatoninProtocol(timeDifference)
        )
    }
    
    /// Get seasonal affective adjustments
    public func getSeasonalAdjustments() async -> SeasonalAdjustment {
        let currentSeason = getCurrentSeason()
        let latitude = getCurrentLatitude() // Would get from location services
        
        return SeasonalAdjustment(
            season: currentSeason,
            lightTherapyRecommendation: calculateSeasonalLightTherapy(currentSeason, latitude),
            vitaminDRecommendation: calculateVitaminDRecommendation(currentSeason, latitude),
            scheduleAdjustment: calculateSeasonalScheduleAdjustment(currentSeason)
        )
    }
    
    // MARK: - Private Implementation
    
    private func startCircadianTracking() {
        Task {
            // Monitor ambient light and update circadian model
            while !Task.isCancelled {
                let ambientLight = await getAmbientLightLevel()
                let lightEvent = LightExposureEvent(
                    timestamp: Date(),
                    lightLevel: ambientLight,
                    duration: 60, // 1 minute sampling
                    source: .ambient
                )
                
                await recordLightExposure(lightEvent)
                
                // Update every minute during wake hours
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }
    
    private func calculatePersonalChronotype() {
        // Analyze sleep/wake patterns to determine chronotype
        // This would integrate with sleep data from SleepOptimization module
        
        // Simplified chronotype calculation
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            chronotype = .earlyBird
        } else if hour > 23 {
            chronotype = .nightOwl
        } else {
            chronotype = .neutral
        }
    }
    
    private func adjustForChronotype(_ timeOfDay: Double) -> Double {
        switch chronotype {
        case .earlyBird:
            return timeOfDay - 1.0 // Shift earlier
        case .nightOwl:
            return timeOfDay + 1.0 // Shift later
        case .neutral:
            return timeOfDay
        }
    }
    
    private func calculatePhaseFromTime(_ adjustedTime: Double) -> CircadianPhase {
        switch adjustedTime {
        case 4.0..<6.0:
            return .earlyMorning
        case 6.0..<10.0:
            return .morning
        case 10.0..<14.0:
            return .midday
        case 14.0..<18.0:
            return .afternoon
        case 18.0..<22.0:
            return .evening
        case 22.0..<24.0, 0.0..<4.0:
            return .night
        default:
            return .night
        }
    }
    
    private func generateLightRecommendations(
        phase: CircadianPhase,
        profile: CircadianProfile
    ) -> [LightRecommendation] {
        var recommendations: [LightRecommendation] = []
        
        switch phase {
        case .earlyMorning:
            recommendations.append(LightRecommendation(
                type: .brightLight,
                intensity: 10000, // lux
                duration: 30 * 60, // 30 minutes
                timing: .now,
                purpose: "Advance circadian phase and promote alertness"
            ))
            
        case .morning:
            recommendations.append(LightRecommendation(
                type: .naturalSunlight,
                intensity: 10000,
                duration: 15 * 60, // 15 minutes
                timing: .now,
                purpose: "Reinforce natural circadian rhythm"
            ))
            
        case .evening:
            recommendations.append(LightRecommendation(
                type: .dimLight,
                intensity: 50, // lux
                duration: 60 * 60, // 1 hour
                timing: .now,
                purpose: "Promote natural melatonin production"
            ))
            
        case .night:
            recommendations.append(LightRecommendation(
                type: .redLight,
                intensity: 10, // lux
                duration: 0, // As needed
                timing: .asNeeded,
                purpose: "Minimize circadian disruption"
            ))
            
        default:
            break
        }
        
        return recommendations
    }
    
    private func updateCircadianModel() async {
        // Update personal circadian profile based on light exposure history
        guard lightExposureHistory.count > 7 else { return }
        
        let recentExposure = Array(lightExposureHistory.suffix(168)) // Last 7 days (24h * 7)
        
        personalCircadianProfile = CircadianProfile(
            chronotype: chronotype,
            lightSensitivity: calculateLightSensitivity(recentExposure),
            melatoninOnset: calculateMelatoninOnset(recentExposure),
            optimalBedtime: calculateOptimalBedtime(recentExposure),
            optimalWakeTime: calculateOptimalWakeTime(recentExposure)
        )
    }
    
    private func calculateLightSensitivity(_ exposureHistory: [LightExposureEvent]) -> Double {
        // Calculate how sensitive the user is to light based on response patterns
        // Higher sensitivity means smaller light changes have bigger impacts
        
        let brightLightExposures = exposureHistory.filter { $0.lightLevel > 1000 }
        let averageResponse = brightLightExposures.count > 0 ? 0.8 : 0.4
        
        return averageResponse
    }
    
    private func calculateMelatoninOnset(_ exposureHistory: [LightExposureEvent]) -> Date {
        // Calculate when melatonin production typically begins
        // Based on light exposure patterns in the evening
        
        let eveningExposures = exposureHistory.filter { exposure in
            let hour = Calendar.current.component(.hour, from: exposure.timestamp)
            return hour >= 18 && hour <= 23
        }
        
        // Find average time when light levels drop below 100 lux
        let lowLightTimes = eveningExposures.filter { $0.lightLevel < 100 }.map(\.timestamp)
        
        if !lowLightTimes.isEmpty {
            let averageTime = lowLightTimes.map(\.timeIntervalSince1970).reduce(0, +) / Double(lowLightTimes.count)
            return Date(timeIntervalSince1970: averageTime)
        }
        
        // Default to 9 PM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        return calendar.date(from: components) ?? Date()
    }
    
    private func calculateOptimalBedtime(_ exposureHistory: [LightExposureEvent]) -> Date {
        // Calculate optimal bedtime based on circadian pattern
        guard let melatoninOnset = personalCircadianProfile?.melatoninOnset else {
            return calculateMelatoninOnset(exposureHistory).addingTimeInterval(2 * 3600) // 2 hours after melatonin onset
        }
        
        return melatoninOnset.addingTimeInterval(2 * 3600)
    }
    
    private func calculateOptimalWakeTime(_ exposureHistory: [LightExposureEvent]) -> Date {
        // Calculate optimal wake time based on sleep need and circadian pattern
        let bedtime = calculateOptimalBedtime(exposureHistory)
        return bedtime.addingTimeInterval(8 * 3600) // 8 hours sleep
    }
    
    private func defaultCircadianProfile() -> CircadianProfile {
        let calendar = Calendar.current
        let now = Date()
        
        var bedtimeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        bedtimeComponents.hour = 22
        let bedtime = calendar.date(from: bedtimeComponents) ?? now
        
        var waketimeComponents = calendar.dateComponents([.year, .month, .day], from: now)
        waketimeComponents.hour = 7
        let waketime = calendar.date(from: waketimeComponents) ?? now
        
        var melatoninComponents = calendar.dateComponents([.year, .month, .day], from: now)
        melatoninComponents.hour = 21
        let melatonin = calendar.date(from: melatoninComponents) ?? now
        
        return CircadianProfile(
            chronotype: .neutral,
            lightSensitivity: 0.6,
            melatoninOnset: melatonin,
            optimalBedtime: bedtime,
            optimalWakeTime: waketime
        )
    }
    
    private func calculateLightTherapyTiming(_ schedule: WorkSchedule) -> LightTherapyTiming {
        return LightTherapyTiming(
            startTime: schedule.shiftStart.addingTimeInterval(-2 * 3600),
            duration: 30 * 60,
            intensity: 10000
        )
    }
    
    private func calculateMelatoninTiming(_ schedule: WorkSchedule) -> MelatoninTiming {
        return MelatoninTiming(
            dosageTime: schedule.shiftEnd.addingTimeInterval(2 * 3600),
            dosage: 0.5, // mg
            duration: 7 // days
        )
    }
    
    private func calculateOptimalSleepSchedule(_ schedule: WorkSchedule) -> SleepSchedule {
        return SleepSchedule(
            bedtime: schedule.shiftEnd.addingTimeInterval(3 * 3600),
            wakeTime: schedule.shiftStart.addingTimeInterval(-2 * 3600),
            duration: 8 * 3600
        )
    }
    
    private func calculateAdjustmentDuration(_ schedule: WorkSchedule) -> TimeInterval {
        // Typically takes 1 day per hour of schedule shift
        return 7 * 24 * 3600 // 7 days for full adjustment
    }
    
    private func calculateTimeDifference(from origin: TimeZone, to destination: TimeZone) -> TimeInterval {
        let now = Date()
        let originOffset = origin.secondsFromGMT(for: now)
        let destinationOffset = destination.secondsFromGMT(for: now)
        return TimeInterval(destinationOffset - originOffset)
    }
    
    private func calculateAdjustmentDays(_ timeDifference: TimeInterval) -> Int {
        let hoursDifference = abs(timeDifference / 3600)
        return max(1, Int(hoursDifference * 0.75)) // Rule of thumb: 3/4 day per hour
    }
    
    private func calculateJetLagLightSchedule(_ timeDifference: TimeInterval, _ travelDate: Date) -> [LightScheduleEntry] {
        // Generate light therapy schedule for jet lag recovery
        var schedule: [LightScheduleEntry] = []
        
        let direction = timeDifference > 0 ? "east" : "west"
        let hoursDifference = Int(abs(timeDifference) / 3600)
        
        for day in 0..<min(hoursDifference, 7) {
            let date = travelDate.addingTimeInterval(TimeInterval(day * 24 * 3600))
            
            if direction == "east" {
                // Eastward travel: use morning light
                schedule.append(LightScheduleEntry(
                    date: date,
                    time: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: date)!,
                    intensity: 10000,
                    duration: 30 * 60
                ))
            } else {
                // Westward travel: use evening light
                schedule.append(LightScheduleEntry(
                    date: date,
                    time: Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: date)!,
                    intensity: 5000,
                    duration: 60 * 60
                ))
            }
        }
        
        return schedule
    }
    
    private func calculateJetLagSleepSchedule(_ timeDifference: TimeInterval, _ travelDate: Date) -> [SleepScheduleEntry] {
        // Generate sleep schedule for gradual adjustment
        var schedule: [SleepScheduleEntry] = []
        
        let hoursDifference = timeDifference / 3600
        let dailyAdjustment = hoursDifference / 7.0 // Spread over 7 days
        
        for day in 0..<7 {
            let adjustedTime = Double(day) * dailyAdjustment
            let date = travelDate.addingTimeInterval(TimeInterval(day * 24 * 3600))
            
            let bedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: date)!
                .addingTimeInterval(adjustedTime * 3600)
            let wakeTime = bedtime.addingTimeInterval(8 * 3600)
            
            schedule.append(SleepScheduleEntry(
                date: date,
                bedtime: bedtime,
                wakeTime: wakeTime
            ))
        }
        
        return schedule
    }
    
    private func calculateJetLagMelatoninProtocol(_ timeDifference: TimeInterval) -> MelatoninProtocol {
        let hoursDifference = abs(timeDifference / 3600)
        
        return MelatoninProtocol(
            startDays: -3, // Start 3 days before travel
            dosage: 0.5, // mg
            timing: "30 minutes before desired bedtime",
            duration: Int(hoursDifference) + 3 // Continue for adjustment period + 3 days
        )
    }
    
    private func getCurrentSeason() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .fall
        default: return .spring
        }
    }
    
    private func getCurrentLatitude() -> Double {
        // Would get from location services
        return 40.7128 // Default to NYC latitude
    }
    
    private func calculateSeasonalLightTherapy(_ season: Season, _ latitude: Double) -> SeasonalLightTherapy {
        switch season {
        case .winter:
            // Higher latitude = more light therapy needed
            let intensity = latitude > 45 ? 10000.0 : 5000.0
            let duration = latitude > 45 ? 60 * 60 : 30 * 60 // 1 hour vs 30 minutes
            
            return SeasonalLightTherapy(
                recommended: true,
                intensity: intensity,
                duration: duration,
                timing: "Morning within 1 hour of waking",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            )
            
        case .fall:
            return SeasonalLightTherapy(
                recommended: latitude > 50,
                intensity: 5000,
                duration: 30 * 60,
                timing: "Morning",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()
            )
            
        default:
            return SeasonalLightTherapy(
                recommended: false,
                intensity: 0,
                duration: 0,
                timing: "Not needed",
                startDate: Date(),
                endDate: Date()
            )
        }
    }
    
    private func calculateVitaminDRecommendation(_ season: Season, _ latitude: Double) -> VitaminDRecommendation {
        let baseIU = 1000.0
        let latitudeMultiplier = latitude > 45 ? 2.0 : 1.5
        let seasonMultiplier = (season == .winter || season == .fall) ? 2.0 : 1.0
        
        let recommendedIU = baseIU * latitudeMultiplier * seasonMultiplier
        
        return VitaminDRecommendation(
            dailyIU: recommendedIU,
            duration: season == .winter ? "October through March" : "Year-round",
            testing: "Check vitamin D levels every 6 months"
        )
    }
    
    private func calculateSeasonalScheduleAdjustment(_ season: Season) -> ScheduleAdjustment {
        switch season {
        case .winter:
            return ScheduleAdjustment(
                bedtimeShift: 30 * 60, // 30 minutes earlier
                waketimeShift: 30 * 60, // 30 minutes later
                reasoning: "Compensate for reduced daylight hours"
            )
        case .summer:
            return ScheduleAdjustment(
                bedtimeShift: -30 * 60, // 30 minutes later
                waketimeShift: -30 * 60, // 30 minutes earlier
                reasoning: "Take advantage of extended daylight"
            )
        default:
            return ScheduleAdjustment(
                bedtimeShift: 0,
                waketimeShift: 0,
                reasoning: "No adjustment needed"
            )
        }
    }
    
    private func getAmbientLightLevel() async -> Double {
        // Would integrate with device sensors
        return 500.0 // Placeholder lux value
    }
}

// MARK: - Supporting Types

public struct LightExposureEvent: Sendable {
    public let timestamp: Date
    public let lightLevel: Double // lux
    public let duration: TimeInterval // seconds
    public let source: LightSource
    
    public enum LightSource: Sendable {
        case natural
        case artificial
        case lightTherapy
        case ambient
    }
}

public struct MelatoninCurve: Sendable {
    public let onsetTime: Date
    public let peakTime: Date
    public let offsetTime: Date
    public let baselineLevel: Double
    public let peakLevel: Double
}

public struct CircadianProfile: Sendable {
    public let chronotype: Chronotype
    public let lightSensitivity: Double // 0-1
    public let melatoninOnset: Date
    public let optimalBedtime: Date
    public let optimalWakeTime: Date
}

public enum Chronotype: Sendable {
    case earlyBird
    case neutral
    case nightOwl
}

public enum CircadianPhase: Sendable, CaseIterable {
    case earlyMorning // 4-6 AM
    case morning      // 6-10 AM
    case midday       // 10 AM-2 PM
    case afternoon    // 2-6 PM
    case evening      // 6-10 PM
    case night        // 10 PM-4 AM
    
    public var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }
    
    public var timeRange: String {
        switch self {
        case .earlyMorning: return "4-6 AM"
        case .morning: return "6-10 AM"
        case .midday: return "10 AM-2 PM"
        case .afternoon: return "2-6 PM"
        case .evening: return "6-10 PM"
        case .night: return "10 PM-4 AM"
        }
    }
}

public struct LightRecommendation: Sendable {
    public enum LightType: Sendable {
        case brightLight
        case naturalSunlight
        case dimLight
        case redLight
        case blueLight
    }
    
    public enum Timing: Sendable {
        case now
        case specific(Date)
        case asNeeded
    }
    
    public let type: LightType
    public let intensity: Double // lux
    public let duration: TimeInterval // seconds
    public let timing: Timing
    public let purpose: String
}

public struct WorkSchedule: Sendable {
    public let shiftStart: Date
    public let shiftEnd: Date
    public let daysPerWeek: Int
    public let isNightShift: Bool
}

public struct ShiftWorkAdjustment: Sendable {
    public let lightTherapyTiming: LightTherapyTiming
    public let melatoninTiming: MelatoninTiming
    public let sleepSchedule: SleepSchedule
    public let adjustmentDuration: TimeInterval
}

public struct LightTherapyTiming: Sendable {
    public let startTime: Date
    public let duration: TimeInterval
    public let intensity: Double // lux
}

public struct MelatoninTiming: Sendable {
    public let dosageTime: Date
    public let dosage: Double // mg
    public let duration: Int // days
}

public struct SleepSchedule: Sendable {
    public let bedtime: Date
    public let wakeTime: Date
    public let duration: TimeInterval
}

public struct JetLagRecovery: Sendable {
    public let adjustmentDays: Int
    public let lightSchedule: [LightScheduleEntry]
    public let sleepSchedule: [SleepScheduleEntry]
    public let melatoninProtocol: MelatoninProtocol
}

public struct LightScheduleEntry: Sendable {
    public let date: Date
    public let time: Date
    public let intensity: Double // lux
    public let duration: TimeInterval
}

public struct SleepScheduleEntry: Sendable {
    public let date: Date
    public let bedtime: Date
    public let wakeTime: Date
}

public struct MelatoninProtocol: Sendable {
    public let startDays: Int // Negative for days before travel
    public let dosage: Double // mg
    public let timing: String
    public let duration: Int // days
}

public enum Season: Sendable {
    case spring
    case summer
    case fall
    case winter
}

public struct SeasonalAdjustment: Sendable {
    public let season: Season
    public let lightTherapyRecommendation: SeasonalLightTherapy
    public let vitaminDRecommendation: VitaminDRecommendation
    public let scheduleAdjustment: ScheduleAdjustment
}

public struct SeasonalLightTherapy: Sendable {
    public let recommended: Bool
    public let intensity: Double // lux
    public let duration: TimeInterval
    public let timing: String
    public let startDate: Date
    public let endDate: Date
}

public struct VitaminDRecommendation: Sendable {
    public let dailyIU: Double
    public let duration: String
    public let testing: String
}

public struct ScheduleAdjustment: Sendable {
    public let bedtimeShift: TimeInterval // seconds
    public let waketimeShift: TimeInterval // seconds
    public let reasoning: String
}