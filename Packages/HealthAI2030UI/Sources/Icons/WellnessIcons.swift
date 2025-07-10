import SwiftUI

// MARK: - Wellness Icons
/// Comprehensive wellness icons for HealthAI 2030
/// Provides fitness, nutrition, mental health, and lifestyle wellness activities
public struct WellnessIcons {
    
    // MARK: - Fitness Icons
    
    /// Exercise activity icons
    public struct Exercise {
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
    
    /// Workout type icons
    public struct Workout {
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
    
    /// Fitness equipment icons
    public struct Equipment {
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
    
    // MARK: - Nutrition Icons
    
    /// Food group icons
    public struct FoodGroups {
        public static let fruits = "leaf.fill"
        public static let vegetables = "leaf"
        public static let grains = "circle.fill"
        public static let protein = "dumbbell.fill"
        public static let dairy = "drop.fill"
        public static let fats = "circle.fill"
        public static let nuts = "circle.fill"
        public static let seeds = "circle.fill"
        public static let legumes = "circle.fill"
        public static let herbs = "leaf"
    }
    
    /// Meal type icons
    public struct Meals {
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
    
    /// Nutrition tracking icons
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
    
    // MARK: - Mental Health Icons
    
    /// Mindfulness icons
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
    
    /// Mental health activity icons
    public struct MentalHealth {
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
    
    /// Emotional wellness icons
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
    
    // MARK: - Lifestyle Icons
    
    /// Sleep wellness icons
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
    
    /// Social wellness icons
    public struct SocialWellness {
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
    
    /// Environmental wellness icons
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
    
    // MARK: - Preventive Health Icons
    
    /// Preventive care icons
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
    
    /// Health monitoring icons
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
    
    // MARK: - Recovery Icons
    
    /// Recovery and healing icons
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
    
    /// Stress management icons
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
    
    // MARK: - Goal Setting Icons
    
    /// Wellness goal icons
    public struct Goals {
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
    
    /// Progress tracking icons
    public struct Progress {
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
}

// MARK: - Wellness Icon Extensions
public extension WellnessIcons {
    
    /// Get icon for wellness category
    static func iconForCategory(_ category: WellnessCategory) -> String {
        switch category {
        case .fitness:
            return Exercise.running
        case .nutrition:
            return FoodGroups.fruits
        case .mentalHealth:
            return Mindfulness.meditation
        case .lifestyle:
            return SleepWellness.sleep
        case .preventive:
            return PreventiveCare.checkup
        case .recovery:
            return Recovery.healing
        case .stressManagement:
            return StressManagement.stressRelief
        case .goals:
            return Goals.fitnessGoal
        }
    }
    
    /// Get icon for wellness activity
    static func iconForActivity(_ activity: WellnessActivity) -> String {
        switch activity {
        case .exercise:
            return Exercise.running
        case .meditation:
            return Mindfulness.meditation
        case .nutrition:
            return NutritionTracking.calories
        case .sleep:
            return SleepWellness.sleep
        case .social:
            return SocialWellness.friendship
        case .nature:
            return EnvironmentalWellness.nature
        case .therapy:
            return MentalHealth.therapy
        case .preventive:
            return PreventiveCare.checkup
        }
    }
    
    /// Get icon for wellness goal type
    static func iconForGoalType(_ goalType: WellnessGoalType) -> String {
        switch goalType {
        case .fitness:
            return Goals.fitnessGoal
        case .nutrition:
            return Goals.nutritionGoal
        case .mentalHealth:
            return Goals.mentalHealthGoal
        case .sleep:
            return Goals.sleepGoal
        case .stress:
            return Goals.stressGoal
        case .weight:
            return Goals.weightGoal
        case .strength:
            return Goals.strengthGoal
        case .flexibility:
            return Goals.flexibilityGoal
        case .endurance:
            return Goals.enduranceGoal
        case .general:
            return Goals.wellnessGoal
        }
    }
}

// MARK: - Supporting Enums
public enum WellnessCategory {
    case fitness
    case nutrition
    case mentalHealth
    case lifestyle
    case preventive
    case recovery
    case stressManagement
    case goals
}

public enum WellnessActivity {
    case exercise
    case meditation
    case nutrition
    case sleep
    case social
    case nature
    case therapy
    case preventive
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