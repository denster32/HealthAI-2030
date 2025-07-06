import XCTest
import Combine
@testable import HealthAI2030

/// Unit tests for Nutrition & Diet Optimization Engine
final class NutritionDietOptimizationTests: XCTestCase {
    var engine: NutritionDietOptimizationEngine!
    var mockHealthDataManager: MockHealthDataManager!
    var mockMLModelManager: MockMLModelManager!
    var mockNotificationManager: MockNotificationManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockHealthDataManager = MockHealthDataManager()
        mockMLModelManager = MockMLModelManager()
        mockNotificationManager = MockNotificationManager()
        cancellables = Set<AnyCancellable>()
        
        engine = NutritionDietOptimizationEngine(
            healthDataManager: mockHealthDataManager,
            mlModelManager: mockMLModelManager,
            notificationManager: mockNotificationManager
        )
    }

    override func tearDown() {
        engine = nil
        mockHealthDataManager = nil
        mockMLModelManager = nil
        mockNotificationManager = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Nutrition Tracking Tests

    func testRecordMealEntry() async throws {
        // Given
        let mealEntry = MealEntry(
            timestamp: Date(),
            mealType: .breakfast,
            name: "Oatmeal with Berries",
            calories: 350,
            protein: 12,
            carbs: 60,
            fat: 8,
            fiber: 8,
            sugar: 20,
            sodium: 150,
            ingredients: ["oats", "berries", "milk"],
            notes: "Healthy breakfast"
        )

        // When
        try await engine.recordMealEntry(mealEntry)

        // Then
        XCTAssertEqual(engine.mealHistory.count, 1)
        XCTAssertEqual(engine.mealHistory.first?.name, "Oatmeal with Berries")
        XCTAssertEqual(engine.nutritionData.dailyCalories, 350)
        XCTAssertEqual(engine.nutritionData.dailyProtein, 12)
        XCTAssertEqual(engine.nutritionData.dailyCarbs, 60)
        XCTAssertEqual(engine.nutritionData.dailyFat, 8)
    }

    func testRecordHydrationEntry() async throws {
        // Given
        let hydrationEntry = HydrationEntry(
            timestamp: Date(),
            amount: 500,
            type: .water,
            notes: "Morning hydration"
        )

        // When
        try await engine.recordHydrationEntry(hydrationEntry)

        // Then
        XCTAssertEqual(engine.hydrationHistory.count, 1)
        XCTAssertEqual(engine.hydrationHistory.first?.amount, 500)
        XCTAssertEqual(engine.nutritionData.dailyWaterIntake, 500)
    }

    func testUpdateNutritionDataWithMultipleMeals() async {
        // Given
        let breakfast = MealEntry(
            timestamp: Date(),
            mealType: .breakfast,
            name: "Breakfast",
            calories: 400,
            protein: 15,
            carbs: 50,
            fat: 10,
            fiber: 5,
            sugar: 15,
            sodium: 200,
            ingredients: [],
            notes: nil
        )
        
        let lunch = MealEntry(
            timestamp: Date(),
            mealType: .lunch,
            name: "Lunch",
            calories: 600,
            protein: 25,
            carbs: 70,
            fat: 20,
            fiber: 8,
            sugar: 25,
            sodium: 400,
            ingredients: [],
            notes: nil
        )

        // When
        try? await engine.recordMealEntry(breakfast)
        try? await engine.recordMealEntry(lunch)

        // Then
        XCTAssertEqual(engine.nutritionData.dailyCalories, 1000)
        XCTAssertEqual(engine.nutritionData.dailyProtein, 40)
        XCTAssertEqual(engine.nutritionData.dailyCarbs, 120)
        XCTAssertEqual(engine.nutritionData.dailyFat, 30)
    }

    func testUpdateHydrationDataWithMultipleEntries() async {
        // Given
        let water1 = HydrationEntry(
            timestamp: Date(),
            amount: 300,
            type: .water,
            notes: nil
        )
        
        let water2 = HydrationEntry(
            timestamp: Date(),
            amount: 400,
            type: .water,
            notes: nil
        )

        // When
        try? await engine.recordHydrationEntry(water1)
        try? await engine.recordHydrationEntry(water2)

        // Then
        XCTAssertEqual(engine.nutritionData.dailyWaterIntake, 700)
    }

    // MARK: - AI-Powered Diet Optimization Tests

    func testGenerateNutritionPlan() async throws {
        // Given
        let mockPlan = NutritionPlan(
            dailyCalories: 2000,
            dailyProtein: 150,
            dailyCarbs: 200,
            dailyFat: 65,
            meals: [
                PlannedMeal(
                    mealType: .breakfast,
                    name: "Protein Oatmeal",
                    calories: 400,
                    protein: 25,
                    carbs: 50,
                    fat: 15,
                    ingredients: ["oats", "protein powder", "berries"],
                    instructions: ["Mix ingredients", "Cook for 5 minutes"],
                    prepTime: 5,
                    cookTime: 5
                )
            ],
            hydrationTarget: 2500,
            supplements: [
                Supplement(
                    name: "Vitamin D",
                    dosage: "1000 IU",
                    frequency: "Daily",
                    purpose: "Bone health"
                )
            ],
            recommendations: ["Eat more protein", "Stay hydrated"]
        )
        
        mockMLModelManager.mockNutritionPlan = mockPlan

        // When
        try await engine.generateNutritionPlan()

        // Then
        XCTAssertNotNil(engine.nutritionPlan)
        XCTAssertEqual(engine.nutritionPlan?.dailyCalories, 2000)
        XCTAssertEqual(engine.nutritionPlan?.meals.count, 1)
        XCTAssertEqual(engine.nutritionPlan?.supplements.count, 1)
    }

    func testGenerateDietRecommendations() async throws {
        // Given
        let mockRecommendations = [
            DietRecommendation(
                title: "Increase Protein Intake",
                description: "Your protein intake is below recommended levels",
                category: .nutritionOptimization,
                priority: .high,
                confidence: 0.85,
                actionable: true,
                actionItems: ["Add protein powder to smoothies", "Include lean meats in meals"],
                estimatedImpact: 0.3
            ),
            DietRecommendation(
                title: "Reduce Sugar Consumption",
                description: "Your sugar intake is above recommended levels",
                category: .healthCondition,
                priority: .medium,
                confidence: 0.75,
                actionable: true,
                actionItems: ["Replace sugary drinks with water", "Choose fruits over desserts"],
                estimatedImpact: 0.2
            )
        ]
        
        mockMLModelManager.mockDietRecommendations = mockRecommendations

        // When
        try await engine.generateDietRecommendations()

        // Then
        XCTAssertEqual(engine.aiRecommendations.count, 2)
        XCTAssertEqual(engine.aiRecommendations.first?.title, "Increase Protein Intake")
        XCTAssertEqual(engine.aiRecommendations.first?.priority, .high)
        XCTAssertEqual(engine.aiRecommendations.first?.actionItems.count, 2)
    }

    // MARK: - Health Condition Integration Tests

    func testUpdateConditionSupport() async throws {
        // Given
        let mockConditions = [
            ConditionSupport(
                condition: .diabetes,
                recommendations: ["Monitor blood sugar", "Eat regular meals"],
                restrictions: ["Limit simple carbs", "Avoid sugary drinks"],
                monitoring: ["Blood glucose levels", "Carbohydrate intake"],
                emergencyContacts: ["Primary care doctor", "Endocrinologist"]
            ),
            ConditionSupport(
                condition: .heartDisease,
                recommendations: ["Reduce sodium intake", "Eat heart-healthy fats"],
                restrictions: ["Limit saturated fats", "Reduce salt"],
                monitoring: ["Blood pressure", "Cholesterol levels"],
                emergencyContacts: ["Cardiologist", "Emergency services"]
            )
        ]
        
        mockMLModelManager.mockConditionSupport = mockConditions

        // When
        try await engine.updateConditionSupport()

        // Then
        XCTAssertEqual(engine.healthConditionSupport.count, 2)
        XCTAssertEqual(engine.healthConditionSupport.first?.condition, .diabetes)
        XCTAssertEqual(engine.healthConditionSupport.first?.recommendations.count, 2)
        XCTAssertEqual(engine.healthConditionSupport.first?.restrictions.count, 2)
    }

    // MARK: - Smart Shopping & Meal Prep Tests

    func testGenerateShoppingList() async throws {
        // Given
        let nutritionPlan = NutritionPlan(
            dailyCalories: 2000,
            dailyProtein: 150,
            dailyCarbs: 200,
            dailyFat: 65,
            meals: [
                PlannedMeal(
                    mealType: .breakfast,
                    name: "Protein Oatmeal",
                    calories: 400,
                    protein: 25,
                    carbs: 50,
                    fat: 15,
                    ingredients: ["oats", "protein powder", "berries"],
                    instructions: [],
                    prepTime: 5,
                    cookTime: 5
                )
            ],
            hydrationTarget: 2500,
            supplements: [],
            recommendations: []
        )
        
        engine.nutritionPlan = nutritionPlan
        
        let mockShoppingItems = [
            ShoppingItem(
                name: "Oats",
                category: .grains,
                quantity: "1 lb",
                priority: .high,
                estimatedCost: 3.99,
                store: "Grocery Store",
                notes: "Organic preferred"
            ),
            ShoppingItem(
                name: "Protein Powder",
                category: .pantry,
                quantity: "2 lb",
                priority: .high,
                estimatedCost: 25.99,
                store: "Health Food Store",
                notes: "Whey protein isolate"
            ),
            ShoppingItem(
                name: "Mixed Berries",
                category: .produce,
                quantity: "1 lb",
                priority: .medium,
                estimatedCost: 4.99,
                store: "Grocery Store",
                notes: "Fresh or frozen"
            )
        ]
        
        mockMLModelManager.mockShoppingList = mockShoppingItems

        // When
        try await engine.generateShoppingList()

        // Then
        XCTAssertEqual(engine.shoppingList.count, 3)
        XCTAssertEqual(engine.shoppingList.first?.name, "Oats")
        XCTAssertEqual(engine.shoppingList.first?.category, .grains)
        XCTAssertEqual(engine.shoppingList.first?.priority, .high)
    }

    func testGenerateMealPrepPlans() async throws {
        // Given
        let nutritionPlan = NutritionPlan(
            dailyCalories: 2000,
            dailyProtein: 150,
            dailyCarbs: 200,
            dailyFat: 65,
            meals: [
                PlannedMeal(
                    mealType: .breakfast,
                    name: "Protein Oatmeal",
                    calories: 400,
                    protein: 25,
                    carbs: 50,
                    fat: 15,
                    ingredients: ["oats", "protein powder", "berries"],
                    instructions: [],
                    prepTime: 5,
                    cookTime: 5
                )
            ],
            hydrationTarget: 2500,
            supplements: [],
            recommendations: []
        )
        
        engine.nutritionPlan = nutritionPlan
        
        let mockMealPrepPlans = [
            MealPrepPlan(
                name: "Weekly Breakfast Prep",
                meals: [
                    PlannedMeal(
                        mealType: .breakfast,
                        name: "Overnight Oats",
                        calories: 350,
                        protein: 20,
                        carbs: 45,
                        fat: 12,
                        ingredients: ["oats", "milk", "berries"],
                        instructions: ["Mix ingredients", "Refrigerate overnight"],
                        prepTime: 10,
                        cookTime: 0
                    )
                ],
                prepTime: 30,
                storageInstructions: ["Store in airtight containers", "Keep refrigerated for up to 5 days"],
                reheatingInstructions: ["Microwave for 1 minute", "Add fresh berries before serving"],
                estimatedCost: 25.0,
                servings: 5
            )
        ]
        
        mockMLModelManager.mockMealPrepPlans = mockMealPrepPlans

        // When
        try await engine.generateMealPrepPlans()

        // Then
        XCTAssertEqual(engine.mealPrepPlans.count, 1)
        XCTAssertEqual(engine.mealPrepPlans.first?.name, "Weekly Breakfast Prep")
        XCTAssertEqual(engine.mealPrepPlans.first?.servings, 5)
        XCTAssertEqual(engine.mealPrepPlans.first?.estimatedCost, 25.0)
    }

    // MARK: - Helper Method Tests

    func testUpdateNutritionCorrelations() async {
        // Given
        let mockCorrelations = NutritionHealthCorrelations(
            weightCorrelation: 0.75,
            energyCorrelation: 0.85,
            moodCorrelation: 0.65,
            sleepCorrelation: 0.70,
            overallHealthScore: 0.80
        )
        
        mockMLModelManager.mockNutritionCorrelations = mockCorrelations

        // When
        await engine.updateNutritionCorrelations()

        // Then
        XCTAssertNotNil(engine.nutritionData.healthCorrelations)
        XCTAssertEqual(engine.nutritionData.healthCorrelations?.weightCorrelation, 0.75)
        XCTAssertEqual(engine.nutritionData.healthCorrelations?.overallHealthScore, 0.80)
    }

    func testUpdateCalorieNeeds() async {
        // Given
        let mockCalorieNeeds = 2200.0
        mockMLModelManager.mockCalorieNeeds = mockCalorieNeeds

        // When
        await engine.updateCalorieNeeds()

        // Then
        XCTAssertEqual(engine.nutritionData.calorieNeeds, 2200.0)
    }

    func testUpdateNutritionGoals() async {
        // Given
        let mockGoals = [
            NutritionGoal(
                type: .weightLoss,
                target: 10.0,
                current: 5.0,
                deadline: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
                unit: "kg"
            ),
            NutritionGoal(
                type: .proteinTarget,
                target: 150.0,
                current: 120.0,
                deadline: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
                unit: "g"
            )
        ]
        
        mockMLModelManager.mockNutritionGoals = mockGoals

        // When
        await engine.updateNutritionGoals()

        // Then
        XCTAssertEqual(engine.nutritionData.nutritionGoals.count, 2)
        XCTAssertEqual(engine.nutritionData.nutritionGoals.first?.type, .weightLoss)
        XCTAssertEqual(engine.nutritionData.nutritionGoals.first?.target, 10.0)
    }

    func testCheckHydrationGoals() async {
        // Given
        engine.nutritionData.dailyWaterIntake = 1200 // Below 80% of 2000ml target

        // When
        await engine.checkHydrationGoals()

        // Then
        // Verify notification was sent (this would be tested through the mock notification manager)
        XCTAssertTrue(mockNotificationManager.notificationsSent.contains { notification in
            notification.title == "Hydration Reminder"
        })
    }

    // MARK: - Error Handling Tests

    func testRecordMealEntryWithError() async {
        // Given
        mockMLModelManager.shouldThrowError = true
        let mealEntry = MealEntry(
            timestamp: Date(),
            mealType: .breakfast,
            name: "Test Meal",
            calories: 300,
            protein: 10,
            carbs: 40,
            fat: 10,
            fiber: 5,
            sugar: 15,
            sodium: 200,
            ingredients: [],
            notes: nil
        )

        // When & Then
        do {
            try await engine.recordMealEntry(mealEntry)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(engine.errorMessage)
            XCTAssertTrue(engine.errorMessage?.contains("Failed to record meal entry") ?? false)
        }
    }

    func testGenerateNutritionPlanWithError() async {
        // Given
        mockMLModelManager.shouldThrowError = true

        // When & Then
        do {
            try await engine.generateNutritionPlan()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(engine.errorMessage)
            XCTAssertTrue(engine.errorMessage?.contains("Failed to generate nutrition plan") ?? false)
        }
    }

    // MARK: - Data Loading Tests

    func testLoadNutritionData() async {
        // Given
        let mockNutritionData = NutritionData(
            dailyCalories: 1800,
            dailyProtein: 120,
            dailyCarbs: 180,
            dailyFat: 60,
            dailyFiber: 25,
            dailySugar: 45,
            dailySodium: 1800,
            dailyWaterIntake: 2000,
            calorieNeeds: 2000,
            mealHistory: [],
            hydrationHistory: [],
            healthCorrelations: nil,
            nutritionGoals: []
        )
        
        // Mock the persistence manager to return the test data
        // This would require dependency injection or a mock persistence manager

        // When
        // The loadNutritionData method is called in setUp, so we can verify the initial state

        // Then
        XCTAssertNotNil(engine.nutritionData)
        // Note: The actual loading would be tested with a mock persistence manager
    }

    // MARK: - Integration Tests

    func testCompleteNutritionWorkflow() async throws {
        // Given
        let mealEntry = MealEntry(
            timestamp: Date(),
            mealType: .breakfast,
            name: "Complete Breakfast",
            calories: 500,
            protein: 25,
            carbs: 60,
            fat: 20,
            fiber: 10,
            sugar: 20,
            sodium: 300,
            ingredients: ["eggs", "toast", "avocado"],
            notes: "Complete breakfast meal"
        )
        
        let hydrationEntry = HydrationEntry(
            timestamp: Date(),
            amount: 500,
            type: .water,
            notes: "Morning water"
        )

        // When
        try await engine.recordMealEntry(mealEntry)
        try await engine.recordHydrationEntry(hydrationEntry)
        try await engine.generateNutritionPlan()
        try await engine.generateDietRecommendations()

        // Then
        XCTAssertEqual(engine.mealHistory.count, 1)
        XCTAssertEqual(engine.hydrationHistory.count, 1)
        XCTAssertEqual(engine.nutritionData.dailyCalories, 500)
        XCTAssertEqual(engine.nutritionData.dailyWaterIntake, 500)
        XCTAssertNotNil(engine.nutritionPlan)
        XCTAssertFalse(engine.aiRecommendations.isEmpty)
    }

    // MARK: - Performance Tests

    func testPerformanceWithLargeMealHistory() async {
        // Given
        let largeMealHistory = (0..<100).map { index in
            MealEntry(
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                mealType: MealType.allCases[index % MealType.allCases.count],
                name: "Meal \(index)",
                calories: Double(300 + index * 10),
                protein: Double(10 + index),
                carbs: Double(40 + index * 2),
                fat: Double(10 + index),
                fiber: Double(5 + index),
                sugar: Double(15 + index),
                sodium: Double(200 + index * 5),
                ingredients: ["ingredient\(index)"],
                notes: "Note \(index)"
            )
        }

        // When
        let startTime = Date()
        
        for meal in largeMealHistory {
            try? await engine.recordMealEntry(meal)
        }
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)

        // Then
        XCTAssertEqual(engine.mealHistory.count, 100)
        XCTAssertLessThan(executionTime, 5.0, "Performance test failed: took longer than 5 seconds")
    }

    // MARK: - Edge Case Tests

    func testEmptyMealHistory() {
        // Given
        let emptyEngine = NutritionDietOptimizationEngine(
            healthDataManager: mockHealthDataManager,
            mlModelManager: mockMLModelManager,
            notificationManager: mockNotificationManager
        )

        // Then
        XCTAssertTrue(emptyEngine.mealHistory.isEmpty)
        XCTAssertTrue(emptyEngine.hydrationHistory.isEmpty)
        XCTAssertEqual(emptyEngine.nutritionData.dailyCalories, 0)
        XCTAssertEqual(emptyEngine.nutritionData.dailyWaterIntake, 0)
    }

    func testZeroCalorieMeal() async throws {
        // Given
        let zeroCalorieMeal = MealEntry(
            timestamp: Date(),
            mealType: .snack,
            name: "Water",
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            sugar: 0,
            sodium: 0,
            ingredients: ["water"],
            notes: "Just water"
        )

        // When
        try await engine.recordMealEntry(zeroCalorieMeal)

        // Then
        XCTAssertEqual(engine.nutritionData.dailyCalories, 0)
        XCTAssertEqual(engine.mealHistory.count, 1)
    }

    func testNegativeValuesHandling() async {
        // Given
        let negativeMeal = MealEntry(
            timestamp: Date(),
            mealType: .breakfast,
            name: "Invalid Meal",
            calories: -100,
            protein: -10,
            carbs: -20,
            fat: -5,
            fiber: -2,
            sugar: -5,
            sodium: -50,
            ingredients: [],
            notes: nil
        )

        // When
        try? await engine.recordMealEntry(negativeMeal)

        // Then
        // The engine should handle negative values gracefully
        XCTAssertEqual(engine.nutritionData.dailyCalories, -100)
        XCTAssertEqual(engine.mealHistory.count, 1)
    }
}

// MARK: - Mock Classes

class MockHealthDataManager: HealthDataManager {
    var healthDataPublisher = PassthroughSubject<HealthData, Never>()
    var activityDataPublisher = PassthroughSubject<ActivityData, Never>()
    var weightDataPublisher = PassthroughSubject<WeightData, Never>()
    
    func getHealthData(for period: TimePeriod) async -> HealthData {
        return HealthData() // Return mock health data
    }
    
    func getActivityData(for period: TimePeriod) async -> ActivityData {
        return ActivityData() // Return mock activity data
    }
    
    func getWeightData(for period: TimePeriod) async -> WeightData {
        return WeightData() // Return mock weight data
    }
}

class MockMLModelManager: MLModelManager {
    var mockNutritionPlan: NutritionPlan?
    var mockDietRecommendations: [DietRecommendation] = []
    var mockConditionSupport: [ConditionSupport] = []
    var mockShoppingList: [ShoppingItem] = []
    var mockMealPrepPlans: [MealPrepPlan] = []
    var mockNutritionCorrelations: NutritionHealthCorrelations?
    var mockCalorieNeeds: Double = 2000.0
    var mockNutritionGoals: [NutritionGoal] = []
    var shouldThrowError = false
    
    func generateNutritionPlan(nutritionData: NutritionData, healthData: HealthData, userPreferences: UserNutritionPreferences) async throws -> NutritionPlan {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockNutritionPlan ?? NutritionPlan(
            dailyCalories: 2000,
            dailyProtein: 150,
            dailyCarbs: 200,
            dailyFat: 65,
            meals: [],
            hydrationTarget: 2500,
            supplements: [],
            recommendations: []
        )
    }
    
    func generateDietRecommendations(nutritionData: NutritionData, healthData: HealthData, userPreferences: UserNutritionPreferences) async throws -> [DietRecommendation] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockDietRecommendations
    }
    
    func generateConditionSupport(nutritionData: NutritionData, healthData: HealthData, userConditions: [HealthCondition]) async throws -> [ConditionSupport] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockConditionSupport
    }
    
    func generateShoppingList(nutritionPlan: NutritionPlan, userPreferences: UserNutritionPreferences, existingItems: [ShoppingItem]) async throws -> [ShoppingItem] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockShoppingList
    }
    
    func generateMealPrepPlans(nutritionPlan: NutritionPlan, userPreferences: UserNutritionPreferences, availableTime: TimeAvailability) async throws -> [MealPrepPlan] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockMealPrepPlans
    }
    
    func analyzeNutritionCorrelations(nutritionData: NutritionData, healthData: HealthData) async throws -> NutritionHealthCorrelations {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockNutritionCorrelations ?? NutritionHealthCorrelations(
            weightCorrelation: 0.5,
            energyCorrelation: 0.6,
            moodCorrelation: 0.4,
            sleepCorrelation: 0.3,
            overallHealthScore: 0.7
        )
    }
    
    func calculateCalorieNeeds(activityData: ActivityData, userProfile: UserProfile) async throws -> Double {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockCalorieNeeds
    }
    
    func updateNutritionGoals(weightData: WeightData, nutritionData: NutritionData, userGoals: [NutritionGoal]) async throws -> [NutritionGoal] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return mockNutritionGoals
    }
}

class MockNotificationManager: NotificationManager {
    var notificationsSent: [NotificationData] = []
    
    func sendNotification(title: String, body: String, category: NotificationCategory) async {
        notificationsSent.append(NotificationData(title: title, body: body, category: category))
    }
}

// MARK: - Supporting Types for Tests

struct NotificationData {
    let title: String
    let body: String
    let category: NotificationCategory
}

struct HealthData {
    // Mock health data structure
}

struct ActivityData {
    // Mock activity data structure
}

struct WeightData {
    // Mock weight data structure
}

enum TimePeriod {
    case day
    case week
    case month
}

enum NotificationCategory {
    case nutrition
    case health
    case fitness
    case general
} 