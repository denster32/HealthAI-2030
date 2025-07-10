import SwiftUI

// MARK: - Wellness Illustrations
/// Comprehensive wellness illustrations for HealthAI 2030
/// Provides visual representations of wellness activities, healthy lifestyles, and preventive health practices
public struct WellnessIllustrations {
    
    // MARK: - Fitness and Exercise
    
    /// Exercise activity illustrations
    public struct ExerciseActivities {
        public static let running = "figure.run"
        public static let walking = "figure.walk"
        public static let cycling = "bicycle"
        public static let swimming = "figure.pool.swim"
        public static let hiking = "figure.hiking"
        public static let yoga = "figure.mind.and.body"
        public static let pilates = "figure.mind.and.body"
        public static let strength = "dumbbell.fill"
        public static let cardio = "heart.circle.fill"
        public static let flexibility = "figure.flexibility"
    }
    
    /// Workout type illustrations
    public struct WorkoutTypes {
        public static let hiit = "bolt.fill"
        public static let circuit = "arrow.clockwise"
        public static let endurance = "timer"
        public static let powerlifting = "dumbbell.fill"
        public static let bodyweight = "figure.walk"
        public static let functional = "figure.walk"
        public static let crossfit = "dumbbell.fill"
        public static let martialArts = "figure.walk"
        public static let dance = "figure.walk"
        public static let sports = "sportscourt.fill"
    }
    
    /// Fitness equipment illustrations
    public struct FitnessEquipment {
        public static let dumbbell = "dumbbell.fill"
        public static let barbell = "dumbbell.fill"
        public static let kettlebell = "dumbbell.fill"
        public static let resistanceBand = "line.diagonal"
        public static let treadmill = "figure.walk"
        public static let elliptical = "figure.walk"
        public static let stationaryBike = "bicycle"
        public static let rowing = "figure.walk"
        public static let yogaMat = "rectangle.fill"
        public static let foamRoller = "cylinder.fill"
    }
    
    // MARK: - Nutrition and Diet
    
    /// Healthy food illustrations
    public struct HealthyFoods {
        public static let fruits = "leaf.fill"
        public static let vegetables = "leaf"
        public static let wholeGrains = "circle.fill"
        public static let leanProtein = "dumbbell.fill"
        public static let healthyFats = "circle.fill"
        public static let nuts = "circle.fill"
        public static let seeds = "circle.fill"
        public static let legumes = "circle.fill"
        public static let herbs = "leaf"
        public static let spices = "circle.fill"
    }
    
    /// Meal planning illustrations
    public struct MealPlanning {
        public static let breakfast = "sunrise.fill"
        public static let lunch = "sun.max.fill"
        public static let dinner = "sunset.fill"
        public static let snack = "circle.fill"
        public static let smoothie = "drop.fill"
        public static let salad = "leaf"
        public static let soup = "drop.fill"
        public static let sandwich = "rectangle.fill"
        public static let pasta = "circle.fill"
        public static let dessert = "star.fill"
    }
    
    /// Nutrition tracking illustrations
    public struct NutritionTracking {
        public static let calories = "flame.fill"
        public static let protein = "dumbbell.fill"
        public static let carbs = "circle.fill"
        public static let fat = "circle.fill"
        public static let fiber = "leaf"
        public static let vitamins = "pills.fill"
        public static let minerals = "circle.fill"
        public static let water = "drop.fill"
        public static let hydration = "drop.fill"
        public static let nutritionGoal = "target"
    }
    
    // MARK: - Mental Health and Wellness
    
    /// Mindfulness illustrations
    public struct Mindfulness {
        public static let meditation = "brain.head.profile"
        public static let breathing = "lungs.fill"
        public static let relaxation = "brain.head.profile"
        public static let stressRelief = "brain.head.profile"
        public static let anxietyRelief = "brain.head.profile"
        public static let focus = "target"
        public static let clarity = "eye.fill"
        public static let peace = "brain.head.profile"
        public static let gratitude = "heart.fill"
        public static let selfCare = "heart.fill"
    }
    
    /// Mental health activity illustrations
    public struct MentalHealthActivities {
        public static let therapy = "brain.head.profile"
        public static let counseling = "brain.head.profile"
        public static let journaling = "pencil"
        public static let art = "paintbrush.fill"
        public static let music = "music.note"
        public static let reading = "book.fill"
        public static let nature = "leaf.fill"
        public static let social = "person.2.fill"
        public static let creativity = "paintbrush.fill"
        public static let learning = "brain.head.profile"
    }
    
    /// Emotional wellness illustrations
    public struct EmotionalWellness {
        public static let happiness = "face.smiling.fill"
        public static let joy = "face.smiling.fill"
        public static let contentment = "face.smiling"
        public static let calm = "brain.head.profile"
        public static let confidence = "target"
        public static let resilience = "shield.fill"
        public static let optimism = "sun.max.fill"
        public static let hope = "heart.fill"
        public static let love = "heart.fill"
        public static let compassion = "heart.fill"
    }
    
    // MARK: - Sleep and Rest
    
    /// Sleep wellness illustrations
    public struct SleepWellness {
        public static let sleep = "bed.double.fill"
        public static let rest = "bed.double"
        public static let relaxation = "brain.head.profile"
        public static let bedtime = "moon.fill"
        public static let wakeup = "sunrise.fill"
        public static let sleepHygiene = "bed.double.fill"
        public static let sleepEnvironment = "house.fill"
        public static let sleepRoutine = "clock.fill"
        public static let sleepQuality = "star.fill"
        public static let sleepRecovery = "bed.double.fill"
    }
    
    /// Sleep stages illustrations
    public struct SleepStages {
        public static let stage1 = "bed.double"
        public static let stage2 = "bed.double.fill"
        public static let stage3 = "bed.double.fill"
        public static let stage4 = "bed.double.fill"
        public static let rem = "bed.double.fill"
        public static let awake = "bed.double"
        public static let deepSleep = "bed.double.fill"
        public static let lightSleep = "bed.double"
        public static let sleepCycle = "arrow.clockwise"
        public static let sleepPattern = "waveform.path.ecg"
    }
    
    // MARK: - Social Wellness
    
    /// Social connection illustrations
    public struct SocialConnection {
        public static let friendship = "person.2.fill"
        public static let family = "person.3.fill"
        public static let community = "person.3.sequence.fill"
        public static let support = "heart.fill"
        public static let connection = "link"
        public static let communication = "message.fill"
        public static let empathy = "heart.fill"
        public static let kindness = "heart.fill"
        public static let generosity = "heart.fill"
        public static let belonging = "person.2.fill"
    }
    
    /// Social activity illustrations
    public struct SocialActivities {
        public static let conversation = "message.fill"
        public static let groupActivity = "person.3.sequence.fill"
        public static let volunteering = "heart.fill"
        public static let mentoring = "person.2.fill"
        public static let networking = "person.3.sequence.fill"
        public static let celebration = "star.fill"
        public static let collaboration = "person.3.sequence.fill"
        public static let teamBuilding = "person.3.sequence.fill"
        public static let cultural = "person.3.sequence.fill"
        public static let spiritual = "heart.fill"
    }
    
    // MARK: - Environmental Wellness
    
    /// Environmental wellness illustrations
    public struct EnvironmentalWellness {
        public static let nature = "leaf.fill"
        public static let outdoors = "sun.max.fill"
        public static let freshAir = "wind"
        public static let sunlight = "sun.max.fill"
        public static let greenSpace = "leaf.fill"
        public static let sustainability = "leaf"
        public static let ecoFriendly = "leaf.fill"
        public static let cleanEnvironment = "sparkles"
        public static let naturalLight = "sun.max.fill"
        public static let freshWater = "drop.fill"
    }
    
    /// Outdoor activity illustrations
    public struct OutdoorActivities {
        public static let hiking = "figure.hiking"
        public static let camping = "tent.fill"
        public static let gardening = "leaf.fill"
        public static let birdWatching = "eye.fill"
        public static let photography = "camera.fill"
        public static let fishing = "figure.fishing"
        public static let kayaking = "figure.pool.swim"
        public static let rockClimbing = "figure.walk"
        public static let stargazing = "moon.stars.fill"
        public static let beach = "beach.umbrella.fill"
    }
    
    // MARK: - Preventive Health
    
    /// Preventive care illustrations
    public struct PreventiveCare {
        public static let checkup = "stethoscope"
        public static let screening = "magnifyingglass"
        public static let vaccination = "syringe"
        public static let dental = "mouth.fill"
        public static let vision = "eye.fill"
        public static let hearing = "ear.fill"
        public static let skin = "hand.raised.fill"
        public static let bone = "ruler.fill"
        public static let heart = "heart.circle.fill"
        public static let cancer = "exclamationmark.triangle"
    }
    
    /// Health monitoring illustrations
    public struct HealthMonitoring {
        public static let vitalSigns = "heart.circle.fill"
        public static let bloodPressure = "drop.fill"
        public static let temperature = "thermometer"
        public static let weight = "scalemass.fill"
        public static let bmi = "chart.bar.fill"
        public static let bodyComposition = "chart.pie.fill"
        public static let sleep = "bed.double.fill"
        public static let activity = "figure.walk"
        public static let nutrition = "fork.knife"
        public static let mentalHealth = "brain.head.profile"
    }
    
    // MARK: - Recovery and Healing
    
    /// Recovery illustrations
    public struct Recovery {
        public static let healing = "heart.fill"
        public static let rehabilitation = "figure.walk"
        public static let physicalTherapy = "figure.walk"
        public static let massage = "hand.raised.fill"
        public static let acupuncture = "needle"
        public static let chiropractic = "hand.raised.fill"
        public static let rest = "bed.double.fill"
        public static let ice = "thermometer.snowflake"
        public static let heat = "thermometer.sun.fill"
        public static let compression = "rectangle.fill"
    }
    
    /// Stress management illustrations
    public struct StressManagement {
        public static let stressRelief = "brain.head.profile"
        public static let relaxation = "brain.head.profile"
        public static let deepBreathing = "lungs.fill"
        public static let progressiveRelaxation = "brain.head.profile"
        public static let guidedImagery = "brain.head.profile"
        public static let biofeedback = "waveform.path.ecg"
        public static let timeManagement = "clock.fill"
        public static let boundaries = "shield.fill"
        public static let selfCare = "heart.fill"
        public static let workLifeBalance = "scale.3d"
    }
    
    // MARK: - Goal Setting and Progress
    
    /// Wellness goal illustrations
    public struct WellnessGoals {
        public static let fitnessGoal = "target"
        public static let nutritionGoal = "target"
        public static let mentalHealthGoal = "target"
        public static let sleepGoal = "target"
        public static let stressGoal = "target"
        public static let weightGoal = "target"
        public static let strengthGoal = "target"
        public static let flexibilityGoal = "target"
        public static let enduranceGoal = "target"
        public static let wellnessGoal = "target"
    }
    
    /// Progress tracking illustrations
    public struct ProgressTracking {
        public static let improvement = "arrow.up.circle.fill"
        public static let achievement = "star.fill"
        public static let milestone = "flag.fill"
        public static let streak = "flame.fill"
        public static let consistency = "checkmark.circle.fill"
        public static let motivation = "bolt.fill"
        public static let dedication = "heart.fill"
        public static let perseverance = "shield.fill"
        public static let growth = "arrow.up.right.circle.fill"
        public static let transformation = "arrow.clockwise"
    }
    
    // MARK: - Holistic Wellness
    
    /// Holistic wellness illustrations
    public struct HolisticWellness {
        public static let mindBodySpirit = "brain.head.profile"
        public static let energy = "bolt.fill"
        public static let chakras = "circle.fill"
        public static let meridians = "line.diagonal"
        public static let aura = "circle.fill"
        public static let balance = "scale.3d"
        public static let harmony = "music.note"
        public static let flow = "arrow.up.arrow.down"
        public static let alignment = "arrow.up.arrow.down"
        public static let wholeness = "circle.fill"
    }
    
    /// Wellness lifestyle illustrations
    public struct WellnessLifestyle {
        public static let healthyHabits = "checkmark.circle.fill"
        public static let routine = "clock.fill"
        public static let discipline = "shield.fill"
        public static let commitment = "heart.fill"
        public static let consistency = "checkmark.circle.fill"
        public static let patience = "clock"
        public static let persistence = "arrow.clockwise"
        public static let adaptability = "arrow.up.arrow.down"
        public static let resilience = "shield.fill"
        public static let growth = "arrow.up.right.circle.fill"
    }
}

// MARK: - Wellness Illustration Extensions
public extension WellnessIllustrations {
    
    /// Get illustration for wellness category
    static func illustrationForCategory(_ category: WellnessCategory) -> String {
        switch category {
        case .fitness:
            return ExerciseActivities.running
        case .nutrition:
            return HealthyFoods.fruits
        case .mentalHealth:
            return Mindfulness.meditation
        case .sleep:
            return SleepWellness.sleep
        case .social:
            return SocialConnection.friendship
        case .environmental:
            return EnvironmentalWellness.nature
        case .preventive:
            return PreventiveCare.checkup
        case .recovery:
            return Recovery.healing
        case .holistic:
            return HolisticWellness.mindBodySpirit
        case .lifestyle:
            return WellnessLifestyle.healthyHabits
        }
    }
    
    /// Get illustration for wellness activity
    static func illustrationForActivity(_ activity: WellnessActivity) -> String {
        switch activity {
        case .exercise:
            return ExerciseActivities.running
        case .meditation:
            return Mindfulness.meditation
        case .nutrition:
            return NutritionTracking.calories
        case .sleep:
            return SleepWellness.sleep
        case .social:
            return SocialConnection.friendship
        case .nature:
            return EnvironmentalWellness.nature
        case .preventive:
            return PreventiveCare.checkup
        case .recovery:
            return Recovery.healing
        case .stressManagement:
            return StressManagement.stressRelief
        case .goalSetting:
            return WellnessGoals.fitnessGoal
        }
    }
    
    /// Get illustration for wellness goal type
    static func illustrationForGoalType(_ goalType: WellnessGoalType) -> String {
        switch goalType {
        case .fitness:
            return WellnessGoals.fitnessGoal
        case .nutrition:
            return WellnessGoals.nutritionGoal
        case .mentalHealth:
            return WellnessGoals.mentalHealthGoal
        case .sleep:
            return WellnessGoals.sleepGoal
        case .stress:
            return WellnessGoals.stressGoal
        case .weight:
            return WellnessGoals.weightGoal
        case .strength:
            return WellnessGoals.strengthGoal
        case .flexibility:
            return WellnessGoals.flexibilityGoal
        case .endurance:
            return WellnessGoals.enduranceGoal
        case .general:
            return WellnessGoals.wellnessGoal
        }
    }
}

// MARK: - Supporting Enums
public enum WellnessCategory {
    case fitness
    case nutrition
    case mentalHealth
    case sleep
    case social
    case environmental
    case preventive
    case recovery
    case holistic
    case lifestyle
}

public enum WellnessActivity {
    case exercise
    case meditation
    case nutrition
    case sleep
    case social
    case nature
    case preventive
    case recovery
    case stressManagement
    case goalSetting
}

public enum WellnessGoalType {
    case fitness
    case nutrition
    case mentalHealth
    case sleep
    case stress
    case weight
    case strength
    case flexibility
    case endurance
    case general
} 