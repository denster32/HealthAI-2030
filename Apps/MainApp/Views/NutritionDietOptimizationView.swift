import SwiftUI
import Charts

/// Nutrition & Diet Optimization View
/// Provides a comprehensive dashboard for nutrition tracking, meal planning,
/// diet optimization tools, shopping, and nutritional insights
struct NutritionDietOptimizationView: View {
    @StateObject private var engine: NutritionDietOptimizationEngine
    @State private var selectedTab = 0
    @State private var showingMealEntry = false
    @State private var showingHydrationEntry = false
    @State private var showingShoppingList = false
    @State private var showingMealPrep = false
    @State private var showingRecommendation = false
    @State private var selectedRecommendation: DietRecommendation?

    init(healthDataManager: HealthDataManager, mlModelManager: MLModelManager, notificationManager: NotificationManager) {
        self._engine = StateObject(wrappedValue: NutritionDietOptimizationEngine(
            healthDataManager: healthDataManager,
            mlModelManager: mlModelManager,
            notificationManager: notificationManager
        ))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                nutritionTabSelector
                TabView(selection: $selectedTab) {
                    nutritionDashboard.tag(0)
                    mealPlanningView.tag(1)
                    dietOptimizationToolsView.tag(2)
                    shoppingView.tag(3)
                    insightsView.tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Nutrition & Diet")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingMealEntry.toggle() }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.green)
                    }
                }
            }
            .sheet(isPresented: $showingMealEntry) {
                MealEntryView(engine: engine)
            }
            .sheet(isPresented: $showingHydrationEntry) {
                HydrationEntryView(engine: engine)
            }
            .sheet(isPresented: $showingShoppingList) {
                ShoppingListView(engine: engine)
            }
            .sheet(isPresented: $showingMealPrep) {
                MealPrepView(engine: engine)
            }
            .sheet(isPresented: $showingRecommendation) {
                if let recommendation = selectedRecommendation {
                    RecommendationDetailView(engine: engine, recommendation: recommendation)
                }
            }
            .onAppear {
                Task {
                    try? await engine.generateNutritionPlan()
                }
            }
        }
    }

    // MARK: - Tab Selector
    private var nutritionTabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Dashboard", icon: "leaf.fill", isSelected: selectedTab == 0, action: { selectedTab = 0 })
            TabButton(title: "Meals", icon: "fork.knife", isSelected: selectedTab == 1, action: { selectedTab = 1 })
            TabButton(title: "Optimize", icon: "wand.and.stars", isSelected: selectedTab == 2, action: { selectedTab = 2 })
            TabButton(title: "Shop", icon: "cart.fill", isSelected: selectedTab == 3, action: { selectedTab = 3 })
            TabButton(title: "Insights", icon: "chart.bar.xaxis", isSelected: selectedTab == 4, action: { selectedTab = 4 })
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Dashboard
    private var nutritionDashboard: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Nutrition summary card
                nutritionSummaryCard
                
                // Quick actions
                quickActionsSection
                
                // Macro breakdown
                macroBreakdownSection
                
                // Hydration tracking
                hydrationSection
                
                // Recent meals
                recentMealsSection
                
                // AI recommendations
                aiRecommendationsSection
            }
            .padding()
        }
        .refreshable {
            Task {
                try? await engine.generateNutritionPlan()
            }
        }
    }

    private var nutritionSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Today's Nutrition")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Your daily nutrition summary")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(Int(engine.nutritionData.dailyCalories))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            let progress = engine.nutritionData.dailyCalories / engine.nutritionData.calorieNeeds
            ProgressView(value: min(progress, 1.0), total: 1.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            Text("Goal: \(Int(engine.nutritionData.calorieNeeds)) calories")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Log Meal",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingMealEntry.toggle()
                }
                
                QuickActionButton(
                    title: "Add Water",
                    icon: "drop.fill",
                    color: .blue
                ) {
                    showingHydrationEntry.toggle()
                }
                
                QuickActionButton(
                    title: "Shopping",
                    icon: "cart.fill",
                    color: .orange
                ) {
                    showingShoppingList.toggle()
                }
            }
        }
    }

    private var macroBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                MacroNutrientCard(
                    label: "Protein",
                    value: "\(Int(engine.nutritionData.dailyProtein))g",
                    target: "120g",
                    color: .red
                )
                
                MacroNutrientCard(
                    label: "Carbs",
                    value: "\(Int(engine.nutritionData.dailyCarbs))g",
                    target: "250g",
                    color: .orange
                )
                
                MacroNutrientCard(
                    label: "Fat",
                    value: "\(Int(engine.nutritionData.dailyFat))g",
                    target: "65g",
                    color: .yellow
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var hydrationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hydration")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(engine.nutritionData.dailyWaterIntake))ml")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("of 2000ml goal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(
                    progress: engine.nutritionData.dailyWaterIntake / 2000.0,
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Meals")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.mealHistory.isEmpty {
                Text("No meals logged today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.mealHistory.prefix(3), id: \.id) { meal in
                    MealRowView(meal: meal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var aiRecommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.aiRecommendations.isEmpty {
                Text("No recommendations yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.aiRecommendations.prefix(2), id: \.id) { recommendation in
                    RecommendationRowView(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                        showingRecommendation = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Meal Planning
    private var mealPlanningView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let plan = engine.nutritionPlan {
                    nutritionPlanCard(plan)
                    mealSuggestionsSection(plan)
                } else {
                    emptyNutritionPlanView
                }
                
                mealHistorySection
            }
            .padding()
        }
    }

    private func nutritionPlanCard(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Nutrition Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(Int(plan.dailyCalories)) calories")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Daily target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(plan.meals.count) meals")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("planned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private func mealSuggestionsSection(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(plan.meals, id: \.name) { meal in
                MealSuggestionRow(meal: meal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var emptyNutritionPlanView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("No Nutrition Plan")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Generate a personalized nutrition plan based on your goals and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Plan") {
                Task {
                    try? await engine.generateNutritionPlan()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var mealHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal History")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.mealHistory.isEmpty {
                Text("No meals logged yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.mealHistory, id: \.id) { meal in
                    MealRowView(meal: meal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Diet Optimization Tools
    private var dietOptimizationToolsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // AI recommendations
                aiRecommendationsToolsSection
                
                // Health condition support
                healthConditionSection
                
                // Nutrition goals
                nutritionGoalsSection
                
                // Meal prep tools
                mealPrepToolsSection
            }
            .padding()
        }
    }

    private var aiRecommendationsToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Diet Optimization")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.aiRecommendations.isEmpty {
                Text("No AI recommendations available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.aiRecommendations, id: \.id) { recommendation in
                    RecommendationCard(recommendation: recommendation) {
                        selectedRecommendation = recommendation
                        showingRecommendation = true
                    }
                }
            }
            
            Button("Generate New Recommendations") {
                Task {
                    try? await engine.generateDietRecommendations()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var healthConditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Condition Support")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.healthConditionSupport.isEmpty {
                Text("No health conditions configured")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.healthConditionSupport, id: \.id) { condition in
                    ConditionSupportCard(condition: condition)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var nutritionGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            if engine.nutritionData.nutritionGoals.isEmpty {
                Text("No nutrition goals set")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.nutritionData.nutritionGoals, id: \.type) { goal in
                    NutritionGoalCard(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var mealPrepToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Prep Tools")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button("View Meal Prep Plans") {
                showingMealPrep.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Shopping
    private var shoppingView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Shopping list
                shoppingListSection
                
                // Smart suggestions
                smartSuggestionsSection
                
                // Budget tracking
                budgetTrackingSection
            }
            .padding()
        }
    }

    private var shoppingListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Shopping List")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    showingShoppingList.toggle()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if engine.shoppingList.isEmpty {
                Text("No items in shopping list")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(engine.shoppingList.prefix(5), id: \.id) { item in
                    ShoppingItemRow(item: item)
                }
            }
            
            Button("Generate Shopping List") {
                Task {
                    try? await engine.generateShoppingList()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Suggestions")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Based on your nutrition plan and preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for smart suggestions
            Text("Smart suggestions will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var budgetTrackingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Tracking")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Track your grocery spending")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for budget tracking
            Text("Budget tracking will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    // MARK: - Insights
    private var insightsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Nutrition insights
                nutritionInsightsSection
                
                // Health correlations
                healthCorrelationsSection
                
                // Trends and patterns
                trendsSection
                
                // Educational content
                educationalContentSection
            }
            .padding()
        }
    }

    private var nutritionInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let correlations = engine.nutritionData.healthCorrelations {
                VStack(spacing: 8) {
                    InsightRow(label: "Overall Health Score", value: "\(Int(correlations.overallHealthScore * 100))%", color: .green)
                    InsightRow(label: "Weight Correlation", value: "\(Int(correlations.weightCorrelation * 100))%", color: .blue)
                    InsightRow(label: "Energy Correlation", value: "\(Int(correlations.energyCorrelation * 100))%", color: .orange)
                    InsightRow(label: "Mood Correlation", value: "\(Int(correlations.moodCorrelation * 100))%", color: .purple)
                }
            } else {
                Text("No nutrition insights available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var healthCorrelationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Health Correlations")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("How your nutrition affects your health")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for health correlations chart
            Text("Health correlations chart will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Trends")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Your nutrition patterns over time")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for trends chart
            Text("Nutrition trends chart will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }

    private var educationalContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition Education")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Learn about healthy eating")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Placeholder for educational content
            Text("Educational content will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MacroNutrientCard: View {
    let label: String
    let value: String
    let target: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(target)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
        .frame(width: 40, height: 40)
    }
}

struct MealRowView: View {
    let meal: MealEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(meal.mealType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(meal.calories)) cal")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(meal.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct RecommendationRowView: View {
    let recommendation: DietRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MealSuggestionRow: View {
    let meal: PlannedMeal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(meal.calories)) cal • \(meal.prepTime + meal.cookTime) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(meal.mealType.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
}

struct RecommendationCard: View {
    let recommendation: DietRecommendation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(recommendation.priority.rawValue)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priorityColor)
                        .cornerRadius(8)
                }
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                if !recommendation.actionItems.isEmpty {
                    Text("Actions: \(recommendation.actionItems.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct ConditionSupportCard: View {
    let condition: ConditionSupport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(condition.condition.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
            
            if !condition.recommendations.isEmpty {
                Text("Recommendations: \(condition.recommendations.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if !condition.restrictions.isEmpty {
                Text("Restrictions: \(condition.restrictions.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NutritionGoalCard: View {
    let goal: NutritionGoal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.type.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Target: \(Int(goal.target)) \(goal.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(goal.current)) \(goal.unit)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ProgressView(value: goal.current, total: goal.target)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(width: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.quantity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let cost = item.estimatedCost {
                    Text("$\(String(format: "%.2f", cost))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct InsightRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Placeholder Views

struct MealEntryView: View {
    let engine: NutritionDietOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Meal Entry View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Log Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct HydrationEntryView: View {
    let engine: NutritionDietOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Hydration Entry View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Add Hydration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct ShoppingListView: View {
    let engine: NutritionDietOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Shopping List View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct MealPrepView: View {
    let engine: NutritionDietOptimizationEngine
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Meal Prep View")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Meal Prep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct RecommendationDetailView: View {
    let engine: NutritionDietOptimizationEngine
    let recommendation: DietRecommendation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Recommendation Detail")
                    .font(.title)
                Text("Implementation coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Recommendation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
} 