import SwiftUI
import Foundation

// MARK: - UX Testing & Feedback Protocol
protocol UXTestingFeedbackProtocol {
    func collectFeedback(_ feedback: UserFeedback) async throws
    func createABTest(_ test: ABTest) async throws -> ABTestResult
    func conductUsabilityTest(_ test: UsabilityTest) async throws -> UsabilityTestResult
    func analyzeFeedback(for feature: String) async throws -> FeedbackAnalysis
    func generateUXInsights() async throws -> [UXInsight]
}

// MARK: - User Feedback Model
struct UserFeedback: Identifiable, Codable {
    let id: String
    let userID: String
    let feature: String
    let rating: Int // 1-5 scale
    let comment: String
    let category: FeedbackCategory
    let timestamp: Date
    let metadata: [String: String]
    
    init(userID: String, feature: String, rating: Int, comment: String, category: FeedbackCategory, metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.userID = userID
        self.feature = feature
        self.rating = max(1, min(5, rating))
        self.comment = comment
        self.category = category
        self.timestamp = Date()
        self.metadata = metadata
    }
}

// MARK: - A/B Test Model
struct ABTest: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let variantA: TestVariant
    let variantB: TestVariant
    let targetMetric: String
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    let status: TestStatus
    
    init(name: String, description: String, variantA: TestVariant, variantB: TestVariant, targetMetric: String, duration: TimeInterval) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.variantA = variantA
        self.variantB = variantB
        self.targetMetric = targetMetric
        self.duration = duration
        self.startDate = Date()
        self.endDate = Date().addingTimeInterval(duration)
        self.status = .active
    }
}

// MARK: - Test Variant
struct TestVariant: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let configuration: [String: Any]
    
    init(name: String, description: String, configuration: [String: Any]) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.configuration = configuration
    }
}

// MARK: - A/B Test Result
struct ABTestResult: Identifiable, Codable {
    let id: String
    let testID: String
    let variantAResults: VariantResults
    let variantBResults: VariantResults
    let winner: String?
    let confidence: Double
    let conclusion: String
    
    init(testID: String, variantAResults: VariantResults, variantBResults: VariantResults, winner: String?, confidence: Double, conclusion: String) {
        self.id = UUID().uuidString
        self.testID = testID
        self.variantAResults = variantAResults
        self.variantBResults = variantBResults
        self.winner = winner
        self.confidence = confidence
        self.conclusion = conclusion
    }
}

// MARK: - Variant Results
struct VariantResults: Codable {
    let variantName: String
    let metricValue: Double
    let sampleSize: Int
    let conversionRate: Double
    let averageTime: TimeInterval
    
    init(variantName: String, metricValue: Double, sampleSize: Int, conversionRate: Double, averageTime: TimeInterval) {
        self.variantName = variantName
        self.metricValue = metricValue
        self.sampleSize = sampleSize
        self.conversionRate = conversionRate
        self.averageTime = averageTime
    }
}

// MARK: - Usability Test Model
struct UsabilityTest: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tasks: [UsabilityTask]
    let participants: [String]
    let duration: TimeInterval
    let startDate: Date
    let endDate: Date
    
    init(name: String, description: String, tasks: [UsabilityTask], participants: [String], duration: TimeInterval) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.tasks = tasks
        self.participants = participants
        self.duration = duration
        self.startDate = Date()
        self.endDate = Date().addingTimeInterval(duration)
    }
}

// MARK: - Usability Task
struct UsabilityTask: Identifiable, Codable {
    let id: String
    let description: String
    let expectedOutcome: String
    let difficulty: TaskDifficulty
    let timeLimit: TimeInterval?
    
    init(description: String, expectedOutcome: String, difficulty: TaskDifficulty, timeLimit: TimeInterval? = nil) {
        self.id = UUID().uuidString
        self.description = description
        self.expectedOutcome = expectedOutcome
        self.difficulty = difficulty
        self.timeLimit = timeLimit
    }
}

// MARK: - Usability Test Result
struct UsabilityTestResult: Identifiable, Codable {
    let id: String
    let testID: String
    let taskResults: [TaskResult]
    let overallScore: Double
    let insights: [String]
    let recommendations: [String]
    
    init(testID: String, taskResults: [TaskResult], overallScore: Double, insights: [String], recommendations: [String]) {
        self.id = UUID().uuidString
        self.testID = testID
        self.taskResults = taskResults
        self.overallScore = overallScore
        self.insights = insights
        self.recommendations = recommendations
    }
}

// MARK: - Task Result
struct TaskResult: Identifiable, Codable {
    let id: String
    let taskID: String
    let participantID: String
    let completionTime: TimeInterval
    let success: Bool
    let errors: Int
    let satisfaction: Int // 1-5 scale
    let comments: String
    
    init(taskID: String, participantID: String, completionTime: TimeInterval, success: Bool, errors: Int, satisfaction: Int, comments: String) {
        self.id = UUID().uuidString
        self.taskID = taskID
        self.participantID = participantID
        self.completionTime = completionTime
        self.success = success
        self.errors = errors
        self.satisfaction = max(1, min(5, satisfaction))
        self.comments = comments
    }
}

// MARK: - Feedback Analysis
struct FeedbackAnalysis: Identifiable, Codable {
    let id: String
    let feature: String
    let averageRating: Double
    let totalFeedback: Int
    let sentiment: Sentiment
    let commonThemes: [String]
    let recommendations: [String]
    
    init(feature: String, averageRating: Double, totalFeedback: Int, sentiment: Sentiment, commonThemes: [String], recommendations: [String]) {
        self.id = UUID().uuidString
        self.feature = feature
        self.averageRating = averageRating
        self.totalFeedback = totalFeedback
        self.sentiment = sentiment
        self.commonThemes = commonThemes
        self.recommendations = recommendations
    }
}

// MARK: - UX Insight
struct UXInsight: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: InsightCategory
    let priority: Priority
    let impact: Impact
    let recommendations: [String]
    
    init(title: String, description: String, category: InsightCategory, priority: Priority, impact: Impact, recommendations: [String]) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.impact = impact
        self.recommendations = recommendations
    }
}

// MARK: - Enums
enum FeedbackCategory: String, Codable, CaseIterable {
    case bug = "Bug"
    case feature = "Feature"
    case usability = "Usability"
    case performance = "Performance"
    case design = "Design"
    case general = "General"
}

enum TestStatus: String, Codable, CaseIterable {
    case active = "Active"
    case completed = "Completed"
    case paused = "Paused"
    case cancelled = "Cancelled"
}

enum TaskDifficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

enum Sentiment: String, Codable, CaseIterable {
    case positive = "Positive"
    case neutral = "Neutral"
    case negative = "Negative"
}

enum InsightCategory: String, Codable, CaseIterable {
    case usability = "Usability"
    case accessibility = "Accessibility"
    case performance = "Performance"
    case engagement = "Engagement"
    case conversion = "Conversion"
}

enum Priority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

enum Impact: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// MARK: - UX Testing & Feedback Implementation
actor UXTestingFeedback: UXTestingFeedbackProtocol {
    private let feedbackManager = FeedbackManager()
    private let abTestManager = ABTestManager()
    private let usabilityManager = UsabilityManager()
    private let analyticsManager = UXAnalyticsManager()
    private let logger = Logger(subsystem: "com.healthai2030.ux", category: "UXTestingFeedback")
    
    func collectFeedback(_ feedback: UserFeedback) async throws {
        logger.info("Collecting feedback for feature: \(feedback.feature)")
        try await feedbackManager.store(feedback)
    }
    
    func createABTest(_ test: ABTest) async throws -> ABTestResult {
        logger.info("Creating A/B test: \(test.name)")
        return try await abTestManager.create(test)
    }
    
    func conductUsabilityTest(_ test: UsabilityTest) async throws -> UsabilityTestResult {
        logger.info("Conducting usability test: \(test.name)")
        return try await usabilityManager.conduct(test)
    }
    
    func analyzeFeedback(for feature: String) async throws -> FeedbackAnalysis {
        logger.info("Analyzing feedback for feature: \(feature)")
        return try await analyticsManager.analyzeFeedback(for: feature)
    }
    
    func generateUXInsights() async throws -> [UXInsight] {
        logger.info("Generating UX insights")
        return try await analyticsManager.generateInsights()
    }
}

// MARK: - Feedback Manager
class FeedbackManager {
    func store(_ feedback: UserFeedback) async throws {
        // Store feedback in database/analytics
        print("Feedback stored: \(feedback.feature) - Rating: \(feedback.rating)")
    }
}

// MARK: - A/B Test Manager
class ABTestManager {
    func create(_ test: ABTest) async throws -> ABTestResult {
        // Simulate A/B test results
        let variantAResults = VariantResults(
            variantName: test.variantA.name,
            metricValue: Double.random(in: 0.6...0.8),
            sampleSize: Int.random(in: 100...500),
            conversionRate: Double.random(in: 0.15...0.25),
            averageTime: Double.random(in: 30...60)
        )
        
        let variantBResults = VariantResults(
            variantName: test.variantB.name,
            metricValue: Double.random(in: 0.5...0.9),
            sampleSize: Int.random(in: 100...500),
            conversionRate: Double.random(in: 0.12...0.28),
            averageTime: Double.random(in: 25...70)
        )
        
        let winner = variantAResults.metricValue > variantBResults.metricValue ? test.variantA.name : test.variantB.name
        let confidence = Double.random(in: 0.7...0.95)
        let conclusion = "Variant \(winner) performed better with \(String(format: "%.1f", confidence * 100))% confidence"
        
        return ABTestResult(
            testID: test.id,
            variantAResults: variantAResults,
            variantBResults: variantBResults,
            winner: winner,
            confidence: confidence,
            conclusion: conclusion
        )
    }
}

// MARK: - Usability Manager
class UsabilityManager {
    func conduct(_ test: UsabilityTest) async throws -> UsabilityTestResult {
        var taskResults: [TaskResult] = []
        
        for task in test.tasks {
            for participant in test.participants {
                let result = TaskResult(
                    taskID: task.id,
                    participantID: participant,
                    completionTime: Double.random(in: 10...120),
                    success: Bool.random(),
                    errors: Int.random(in: 0...3),
                    satisfaction: Int.random(in: 3...5),
                    comments: "Task completed successfully"
                )
                taskResults.append(result)
            }
        }
        
        let overallScore = Double.random(in: 0.7...0.9)
        let insights = [
            "Users found the navigation intuitive",
            "Some participants struggled with advanced features",
            "Overall satisfaction was high"
        ]
        let recommendations = [
            "Simplify advanced feature access",
            "Add more contextual help",
            "Consider progressive disclosure"
        ]
        
        return UsabilityTestResult(
            testID: test.id,
            taskResults: taskResults,
            overallScore: overallScore,
            insights: insights,
            recommendations: recommendations
        )
    }
}

// MARK: - UX Analytics Manager
class UXAnalyticsManager {
    func analyzeFeedback(for feature: String) async throws -> FeedbackAnalysis {
        let averageRating = Double.random(in: 3.5...4.5)
        let totalFeedback = Int.random(in: 50...200)
        let sentiment: Sentiment = averageRating > 4.0 ? .positive : averageRating > 3.0 ? .neutral : .negative
        
        let commonThemes = [
            "Easy to use",
            "Intuitive interface",
            "Fast performance"
        ]
        
        let recommendations = [
            "Continue current design direction",
            "Monitor performance metrics",
            "Gather more user feedback"
        ]
        
        return FeedbackAnalysis(
            feature: feature,
            averageRating: averageRating,
            totalFeedback: totalFeedback,
            sentiment: sentiment,
            commonThemes: commonThemes,
            recommendations: recommendations
        )
    }
    
    func generateInsights() async throws -> [UXInsight] {
        return [
            UXInsight(
                title: "Navigation Simplification",
                description: "Users prefer simplified navigation with fewer clicks",
                category: .usability,
                priority: .high,
                impact: .high,
                recommendations: ["Reduce navigation depth", "Add breadcrumbs", "Implement search"]
            ),
            UXInsight(
                title: "Accessibility Improvements",
                description: "VoiceOver users need better screen reader support",
                category: .accessibility,
                priority: .medium,
                impact: .medium,
                recommendations: ["Add ARIA labels", "Improve focus management", "Test with screen readers"]
            ),
            UXInsight(
                title: "Performance Optimization",
                description: "Page load times affect user satisfaction",
                category: .performance,
                priority: .high,
                impact: .high,
                recommendations: ["Optimize images", "Implement lazy loading", "Cache static content"]
            )
        ]
    }
}

// MARK: - SwiftUI Views for UX Testing & Feedback
struct FeedbackCollectionView: View {
    @State private var rating = 3
    @State private var comment = ""
    @State private var category = FeedbackCategory.general
    @State private var feature = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Share Your Feedback")
                .font(.title2.bold())
            
            VStack(alignment: .leading) {
                Text("Feature")
                TextField("Enter feature name", text: $feature)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Category")
                Picker("Category", selection: $category) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Rating")
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .onTapGesture {
                                rating = star
                            }
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Comments")
                TextEditor(text: $comment)
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
            }
            
            Button("Submit Feedback") {
                // Submit feedback
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct ABTestDashboardView: View {
    @State private var tests: [ABTest] = []
    
    var body: some View {
        List(tests) { test in
            VStack(alignment: .leading) {
                Text(test.name)
                    .font(.headline)
                Text(test.description)
                    .font(.caption)
                Text("Status: \(test.status.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("A/B Tests")
    }
}

struct UsabilityTestView: View {
    @State private var currentTask: UsabilityTask?
    @State private var taskResults: [TaskResult] = []
    
    var body: some View {
        VStack {
            if let task = currentTask {
                VStack(spacing: 20) {
                    Text("Task: \(task.description)")
                        .font(.headline)
                    Text("Expected: \(task.expectedOutcome)")
                        .font(.subheadline)
                    
                    Button("Start Task") {
                        // Start task timer
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("No active tasks")
                    .font(.title2)
            }
        }
        .padding()
    }
}

// MARK: - Preview
struct UXTestingFeedback_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeedbackCollectionView()
        }
        .previewDevice("iPhone 15 Pro")
    }
} 