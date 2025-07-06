import Foundation
import SwiftUI
import Combine
import CoreML
import HealthKit

/// Advanced Nutrition & Diet Optimization Engine
/// Provides comprehensive nutrition tracking, AI-powered diet optimization,
/// health condition integration, and smart shopping/meal prep features
@MainActor
final class NutritionDietOptimizationEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var nutritionData: NutritionData = NutritionData()
    @Published var mealHistory: [MealEntry] = []
    @Published var hydrationHistory: [HydrationEntry] = []
    @Published var nutritionPlan: NutritionPlan?
    @Published var aiRecommendations: [DietRecommendation] = []
    @Published var healthConditionSupport: [ConditionSupport] = []
    @Published var shoppingList: [ShoppingItem] = []
    @Published var mealPrepPlans: [MealPrepPlan] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let healthDataManager: HealthDataManager
    private let mlModelManager: MLModelManager
    private let notificationManager: NotificationManager

    // MARK: - Initialization
    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager) {
        self.healthDataManager = healthDataManager
        self.mlModelManager = mlModelManager
        self.notificationManager = notificationManager
        setupSubscriptions()
        loadNutritionData()
    }

    // MARK: - Setup
    private func setupSubscriptions() {
        // Monitor health data changes for nutrition correlations
        healthDataManager.healthDataPublisher
            .debounce(for: .seconds(5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateNutritionCorrelations()
            }
            .store(in: &cancellables)
        
        // Monitor activity data for calorie needs
        healthDataManager.activityDataPublisher
            .sink { [weak self] _ in
                self?.updateCalorieNeeds()
            }
            .store(in: &cancellables)
        
        // Monitor weight changes for nutrition adjustments
        healthDataManager.weightDataPublisher
            .sink { [weak self] _ in
                self?.updateNutritionGoals()
            }
            .store(in: &cancellables)
    }

    // MARK: - Nutrition Tracking
    func recordMealEntry(_ entry: MealEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add to meal history
            await MainActor.run {
                mealHistory.append(entry)
                nutritionData.mealHistory = mealHistory
            }
            
            // Save to persistent storage
            try await NutritionPersistenceManager.shared.saveMealEntry(entry)
            
            // Update nutrition data
            await updateNutritionData()
            
            // Generate AI recommendations
            await generateDietRecommendations()
            
            // Update health condition support
            await updateConditionSupport()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to record meal entry: \(error.localizedDescription)"
            }
            throw error
        }
    }

    func recordHydrationEntry(_ entry: HydrationEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Add to hydration history
            await MainActor.run {
                hydrationHistory.append(entry)
                nutritionData.hydrationHistory = hydrationHistory
            }
            
            // Save to persistent storage
            try await NutritionPersistenceManager.shared.saveHydrationEntry(entry)
            
            // Update hydration tracking
            await updateHydrationData()
            
            // Check hydration goals
            await checkHydrationGoals()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to record hydration entry: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // MARK: - AI-Powered Diet Optimization
    func generateNutritionPlan() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let healthData = await healthDataManager.getHealthData(for: .week)
            let plan = try await mlModelManager.generateNutritionPlan(
                nutritionData: nutritionData,
                healthData: healthData,
                userPreferences: getUserPreferences()
            )
            
            await MainActor.run {
                self.nutritionPlan = plan
            }
            
            // Generate shopping list based on plan
            await generateShoppingList()
            
            // Generate meal prep plans
            await generateMealPrepPlans()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate nutrition plan: \(error.localizedDescription)"
            }
            throw error
        }
    }

    func generateDietRecommendations() async throws {
        do {
            let healthData = await healthDataManager.getHealthData(for: .week)
            let recommendations = try await mlModelManager.generateDietRecommendations(
                nutritionData: nutritionData,
                healthData: healthData,
                userPreferences: getUserPreferences()
            )
            
            await MainActor.run {
                self.aiRecommendations = recommendations
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate diet recommendations: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // MARK: - Health Condition Integration
    func updateConditionSupport() async throws {
        do {
            let healthData = await healthDataManager.getHealthData(for: .week)
            let conditions = try await mlModelManager.generateConditionSupport(
                nutritionData: nutritionData,
                healthData: healthData,
                userConditions: getUserHealthConditions()
            )
            
            await MainActor.run {
                self.healthConditionSupport = conditions
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update condition support: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // MARK: - Smart Shopping & Meal Prep
    func generateShoppingList() async throws {
        guard let plan = nutritionPlan else { return }
        
        do {
            let items = try await mlModelManager.generateShoppingList(
                nutritionPlan: plan,
                userPreferences: getUserPreferences(),
                existingItems: shoppingList
            )
            
            await MainActor.run {
                self.shoppingList = items
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate shopping list: \(error.localizedDescription)"
            }
            throw error
        }
    }

    func generateMealPrepPlans() async throws {
        guard let plan = nutritionPlan else { return }
        
        do {
            let prepPlans = try await mlModelManager.generateMealPrepPlans(
                nutritionPlan: plan,
                userPreferences: getUserPreferences(),
                availableTime: getUserAvailableTime()
            )
            
            await MainActor.run {
                self.mealPrepPlans = prepPlans
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to generate meal prep plans: \(error.localizedDescription)"
            }
            throw error
        }
    }

    // MARK: - Helper Methods
    private func updateNutritionData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let todayMeals = mealHistory.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        
        var totalCalories = 0.0
        var totalProtein = 0.0
        var totalCarbs = 0.0
        var totalFat = 0.0
        var totalFiber = 0.0
        var totalSugar = 0.0
        var totalSodium = 0.0
        
        for meal in todayMeals {
            totalCalories += meal.calories
            totalProtein += meal.protein
            totalCarbs += meal.carbs
            totalFat += meal.fat
            totalFiber += meal.fiber
            totalSugar += meal.sugar
            totalSodium += meal.sodium
        }
        
        await MainActor.run {
            nutritionData.dailyCalories = totalCalories
            nutritionData.dailyProtein = totalProtein
            nutritionData.dailyCarbs = totalCarbs
            nutritionData.dailyFat = totalFat
            nutritionData.dailyFiber = totalFiber
            nutritionData.dailySugar = totalSugar
            nutritionData.dailySodium = totalSodium
        }
    }

    private func updateHydrationData() async {
        let today = Calendar.current.startOfDay(for: Date())
        let todayHydration = hydrationHistory.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        
        let totalWater = todayHydration.reduce(0.0) { $0 + $1.amount }
        
        await MainActor.run {
            nutritionData.dailyWaterIntake = totalWater
        }
    }

    private func updateNutritionCorrelations() async {
        do {
            let healthData = await healthDataManager.getHealthData(for: .week)
            let correlations = try await mlModelManager.analyzeNutritionCorrelations(
                nutritionData: nutritionData,
                healthData: healthData
            )
            
            await MainActor.run {
                nutritionData.healthCorrelations = correlations
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update nutrition correlations: \(error.localizedDescription)"
            }
        }
    }

    private func updateCalorieNeeds() async {
        do {
            let activityData = await healthDataManager.getActivityData(for: .day)
            let calorieNeeds = try await mlModelManager.calculateCalorieNeeds(
                activityData: activityData,
                userProfile: getUserProfile()
            )
            
            await MainActor.run {
                nutritionData.calorieNeeds = calorieNeeds
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update calorie needs: \(error.localizedDescription)"
            }
        }
    }

    private func updateNutritionGoals() async {
        do {
            let weightData = await healthDataManager.getWeightData(for: .month)
            let goals = try await mlModelManager.updateNutritionGoals(
                weightData: weightData,
                nutritionData: nutritionData,
                userGoals: getUserGoals()
            )
            
            await MainActor.run {
                nutritionData.nutritionGoals = goals
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update nutrition goals: \(error.localizedDescription)"
            }
        }
    }

    private func checkHydrationGoals() async {
        let targetHydration = getUserHydrationTarget()
        let currentHydration = nutritionData.dailyWaterIntake
        
        if currentHydration < targetHydration * 0.8 {
            await notificationManager.sendNotification(
                title: "Hydration Reminder",
                body: "You're below your hydration goal. Consider drinking more water.",
                category: .nutrition
            )
        }
    }

    // MARK: - Data Loading
    private func loadNutritionData() {
        Task {
            do {
                let data = try await NutritionPersistenceManager.shared.loadNutritionData()
                await MainActor.run {
                    self.nutritionData = data
                    self.mealHistory = data.mealHistory
                    self.hydrationHistory = data.hydrationHistory
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load nutrition data: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - User Preferences & Data
    private func getUserPreferences() -> UserNutritionPreferences {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<UserNutritionPreferences>()
            let preferences = try context.fetch(descriptor)
            return preferences.first ?? UserNutritionPreferences()
        } catch {
            print("Failed to load user preferences: \(error)")
            return UserNutritionPreferences()
        }
    }

    private func getUserHealthConditions() -> [HealthCondition] {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<HealthCondition>()
            return try context.fetch(descriptor)
        } catch {
            print("Failed to load health conditions: \(error)")
            return []
        }
    }

    private func getUserProfile() -> UserProfile {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            return profiles.first ?? UserProfile()
        } catch {
            print("Failed to load user profile: \(error)")
            return UserProfile()
        }
    }

    private func getUserGoals() -> [NutritionGoal] {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<NutritionGoal>(
                sortBy: [SortDescriptor(\.deadline)]
            )
            return try context.fetch(descriptor)
        } catch {
            print("Failed to load nutrition goals: \(error)")
            return []
        }
    }

    private func getUserHydrationTarget() -> Double {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<UserNutritionPreferences>()
            let preferences = try context.fetch(descriptor)
            if let hydrationTarget = preferences.first?.hydrationTarget {
                return hydrationTarget
            }
        } catch {
            print("Failed to load hydration target: \(error)")
        }
        return 2000.0 // Default 2L
    }

    private func getUserAvailableTime() -> TimeAvailability {
        do {
            let context = ModelContainer.shared.mainContext
            let descriptor = FetchDescriptor<TimeAvailability>()
            let timeAvailability = try context.fetch(descriptor)
            return timeAvailability.first ?? TimeAvailability()
        } catch {
            print("Failed to load time availability: \(error)")
            return TimeAvailability()
        }
    }
}

// MARK: - Supporting Types

struct NutritionData {
    var dailyCalories: Double = 0.0
    var dailyProtein: Double = 0.0
    var dailyCarbs: Double = 0.0
    var dailyFat: Double = 0.0
    var dailyFiber: Double = 0.0
    var dailySugar: Double = 0.0
    var dailySodium: Double = 0.0
    var dailyWaterIntake: Double = 0.0
    var calorieNeeds: Double = 2000.0
    var mealHistory: [MealEntry] = []
    var hydrationHistory: [HydrationEntry] = []
    var healthCorrelations: NutritionHealthCorrelations?
    var nutritionGoals: [NutritionGoal] = []
}

struct MealEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let mealType: MealType
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double
    let sugar: Double
    let sodium: Double
    let ingredients: [String]
    let notes: String?
}

enum MealType: String, CaseIterable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

struct HydrationEntry: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let amount: Double // in ml
    let type: HydrationType
    let notes: String?
}

enum HydrationType: String, CaseIterable, Codable {
    case water = "Water"
    case tea = "Tea"
    case coffee = "Coffee"
    case juice = "Juice"
    case other = "Other"
}

struct NutritionPlan: Codable {
    let dailyCalories: Double
    let dailyProtein: Double
    let dailyCarbs: Double
    let dailyFat: Double
    let meals: [PlannedMeal]
    let hydrationTarget: Double
    let supplements: [Supplement]
    let recommendations: [String]
}

struct PlannedMeal: Codable {
    let mealType: MealType
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let ingredients: [String]
    let instructions: [String]
    let prepTime: Int // in minutes
    let cookTime: Int // in minutes
}

struct Supplement: Codable {
    let name: String
    let dosage: String
    let frequency: String
    let purpose: String
}

struct DietRecommendation: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: Priority
    let confidence: Double
    let actionable: Bool
    let actionItems: [String]
    let estimatedImpact: Double
}

enum RecommendationCategory: String, CaseIterable, Codable {
    case mealPlanning = "Meal Planning"
    case nutritionOptimization = "Nutrition Optimization"
    case healthCondition = "Health Condition"
    case lifestyle = "Lifestyle"
}

enum Priority: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct ConditionSupport: Identifiable, Codable {
    let id = UUID()
    let condition: HealthCondition
    let recommendations: [String]
    let restrictions: [String]
    let monitoring: [String]
    let emergencyContacts: [String]
}

enum HealthCondition: String, CaseIterable, Codable {
    case diabetes = "Diabetes"
    case heartDisease = "Heart Disease"
    case hypertension = "Hypertension"
    case celiac = "Celiac Disease"
    case lactoseIntolerance = "Lactose Intolerance"
    case nutAllergy = "Nut Allergy"
    case other = "Other"
}

struct ShoppingItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: ShoppingCategory
    let quantity: String
    let priority: Priority
    let estimatedCost: Double?
    let store: String?
    let notes: String?
}

enum ShoppingCategory: String, CaseIterable, Codable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case grains = "Grains"
    case pantry = "Pantry"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case other = "Other"
}

struct MealPrepPlan: Identifiable, Codable {
    let id = UUID()
    let name: String
    let meals: [PlannedMeal]
    let prepTime: Int // in minutes
    let storageInstructions: [String]
    let reheatingInstructions: [String]
    let estimatedCost: Double
    let servings: Int
}

// MARK: - Additional Supporting Types

struct NutritionHealthCorrelations: Codable {
    let weightCorrelation: Double
    let energyCorrelation: Double
    let moodCorrelation: Double
    let sleepCorrelation: Double
    let overallHealthScore: Double
}

struct NutritionGoal: Codable {
    let type: GoalType
    let target: Double
    let current: Double
    let deadline: Date
    let unit: String
}

enum GoalType: String, CaseIterable, Codable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case maintenance = "Maintenance"
    case muscleGain = "Muscle Gain"
    case calorieTarget = "Calorie Target"
    case proteinTarget = "Protein Target"
}

struct UserNutritionPreferences: Codable {
    let dietaryRestrictions: [String]
    let allergies: [String]
    let intolerances: [String]
    let cuisinePreferences: [String]
    let cookingSkill: CookingSkill
    let mealPrepPreference: Bool
    let budget: BudgetRange
}

enum CookingSkill: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
}

enum BudgetRange: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct UserProfile: Codable {
    let age: Int
    let gender: Gender
    let weight: Double
    let height: Double
    let activityLevel: ActivityLevel
    let fitnessGoals: [String]
}

enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case extremelyActive = "Extremely Active"
}

struct TimeAvailability: Codable {
    let weekdayPrepTime: Int // in minutes
    let weekendPrepTime: Int // in minutes
    let preferredPrepDays: [Weekday]
    let maxPrepTime: Int // in minutes
}

enum Weekday: String, CaseIterable, Codable {
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
}

// MARK: - Persistence Manager

class NutritionPersistenceManager {
    static let shared = NutritionPersistenceManager()
    
    private init() {}
    
    func saveMealEntry(_ entry: MealEntry) async throws {
        let context = ModelContainer.shared.mainContext
        
        // Create a new meal entry entity
        let mealEntry = MealEntryEntity()
        mealEntry.id = entry.id
        mealEntry.timestamp = entry.timestamp
        mealEntry.mealType = entry.mealType.rawValue
        mealEntry.name = entry.name
        mealEntry.calories = entry.calories
        mealEntry.protein = entry.protein
        mealEntry.carbs = entry.carbs
        mealEntry.fat = entry.fat
        mealEntry.fiber = entry.fiber
        mealEntry.sugar = entry.sugar
        mealEntry.sodium = entry.sodium
        mealEntry.ingredients = entry.ingredients
        mealEntry.notes = entry.notes
        
        context.insert(mealEntry)
        try context.save()
    }
    
    func saveHydrationEntry(_ entry: HydrationEntry) async throws {
        let context = ModelContainer.shared.mainContext
        
        // Create a new hydration entry entity
        let hydrationEntry = HydrationEntryEntity()
        hydrationEntry.id = entry.id
        hydrationEntry.timestamp = entry.timestamp
        hydrationEntry.amount = entry.amount
        hydrationEntry.type = entry.type.rawValue
        hydrationEntry.notes = entry.notes
        
        context.insert(hydrationEntry)
        try context.save()
    }
    
    func loadNutritionData() async throws -> NutritionData {
        let context = ModelContainer.shared.mainContext
        
        // Load meal entries
        let mealDescriptor = FetchDescriptor<MealEntryEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let mealEntities = try context.fetch(mealDescriptor)
        let mealEntries = mealEntities.map { entity in
            MealEntry(
                timestamp: entity.timestamp,
                mealType: MealType(rawValue: entity.mealType) ?? .snack,
                name: entity.name,
                calories: entity.calories,
                protein: entity.protein,
                carbs: entity.carbs,
                fat: entity.fat,
                fiber: entity.fiber,
                sugar: entity.sugar,
                sodium: entity.sodium,
                ingredients: entity.ingredients,
                notes: entity.notes
            )
        }
        
        // Load hydration entries
        let hydrationDescriptor = FetchDescriptor<HydrationEntryEntity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let hydrationEntities = try context.fetch(hydrationDescriptor)
        let hydrationEntries = hydrationEntities.map { entity in
            HydrationEntry(
                timestamp: entity.timestamp,
                amount: entity.amount,
                type: HydrationType(rawValue: entity.type) ?? .water,
                notes: entity.notes
            )
        }
        
        // Calculate daily totals
        let today = Calendar.current.startOfDay(for: Date())
        let todayMeals = mealEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        let todayHydration = hydrationEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        
        let dailyCalories = todayMeals.reduce(0) { $0 + $1.calories }
        let dailyProtein = todayMeals.reduce(0) { $0 + $1.protein }
        let dailyCarbs = todayMeals.reduce(0) { $0 + $1.carbs }
        let dailyFat = todayMeals.reduce(0) { $0 + $1.fat }
        let dailyFiber = todayMeals.reduce(0) { $0 + $1.fiber }
        let dailySugar = todayMeals.reduce(0) { $0 + $1.sugar }
        let dailySodium = todayMeals.reduce(0) { $0 + $1.sodium }
        let dailyWaterIntake = todayHydration.reduce(0) { $0 + $1.amount }
        
        return NutritionData(
            dailyCalories: dailyCalories,
            dailyProtein: dailyProtein,
            dailyCarbs: dailyCarbs,
            dailyFat: dailyFat,
            dailyFiber: dailyFiber,
            dailySugar: dailySugar,
            dailySodium: dailySodium,
            dailyWaterIntake: dailyWaterIntake,
            calorieNeeds: calculateCalorieNeeds(),
            mealHistory: mealEntries,
            hydrationHistory: hydrationEntries,
            healthCorrelations: calculateHealthCorrelations(meals: mealEntries, hydration: hydrationEntries),
            nutritionGoals: getUserGoals()
        )
    }
    
    private func calculateCalorieNeeds() -> Double {
        // Basic BMR calculation using Harris-Benedict equation
        let profile = getUserProfile()
        let age = profile.age
        let weight = profile.weight // in kg
        let height = profile.height // in cm
        let gender = profile.gender
        
        let bmr: Double
        if gender == .male {
            bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * Double(age))
        } else {
            bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * Double(age))
        }
        
        // Apply activity level multiplier
        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .lightlyActive: activityMultiplier = 1.375
        case .moderatelyActive: activityMultiplier = 1.55
        case .veryActive: activityMultiplier = 1.725
        case .extremelyActive: activityMultiplier = 1.9
        }
        
        return bmr * activityMultiplier
    }
    
    private func calculateHealthCorrelations(meals: [MealEntry], hydration: [HydrationEntry]) -> NutritionHealthCorrelations {
        // Calculate correlations between nutrition and health metrics
        // This is a simplified implementation - in a real app, you'd use more sophisticated analysis
        
        let totalCalories = meals.reduce(0) { $0 + $1.calories }
        let totalProtein = meals.reduce(0) { $0 + $1.protein }
        let totalHydration = hydration.reduce(0) { $0 + $1.amount }
        
        // Simplified correlation calculations
        let weightCorrelation = min(1.0, max(-1.0, (totalCalories - 2000) / 1000))
        let energyCorrelation = min(1.0, max(-1.0, (totalProtein - 50) / 50))
        let moodCorrelation = min(1.0, max(-1.0, (totalHydration - 2000) / 1000))
        let sleepCorrelation = min(1.0, max(-1.0, (totalCalories - 2000) / 1000))
        
        let overallHealthScore = (weightCorrelation + energyCorrelation + moodCorrelation + sleepCorrelation) / 4.0
        
        return NutritionHealthCorrelations(
            weightCorrelation: weightCorrelation,
            energyCorrelation: energyCorrelation,
            moodCorrelation: moodCorrelation,
            sleepCorrelation: sleepCorrelation,
            overallHealthScore: overallHealthScore
        )
    }
}

// MARK: - SwiftData Entities

@Model
class MealEntryEntity {
    var id: UUID
    var timestamp: Date
    var mealType: String
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double
    var ingredients: [String]
    var notes: String?
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
        self.mealType = ""
        self.name = ""
        self.calories = 0.0
        self.protein = 0.0
        self.carbs = 0.0
        self.fat = 0.0
        self.fiber = 0.0
        self.sugar = 0.0
        self.sodium = 0.0
        self.ingredients = []
        self.notes = nil
    }
}

@Model
class HydrationEntryEntity {
    var id: UUID
    var timestamp: Date
    var amount: Double
    var type: String
    var notes: String?
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
        self.amount = 0.0
        self.type = ""
        self.notes = nil
    }
} 