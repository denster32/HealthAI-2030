import Foundation
import SwiftUI
import Combine

/// Intelligent Navigation System
/// Provides smart navigation with user behavior learning, adaptive routing, and contextual suggestions
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class IntelligentNavigationSystem: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentRoute: NavigationRoute = .dashboard
    @Published public private(set) var navigationHistory: [NavigationEntry] = []
    @Published public private(set) var suggestedRoutes: [NavigationSuggestion] = []
    @Published public private(set) var userBehavior: UserNavigationBehavior = UserNavigationBehavior()
    @Published public private(set) var navigationAnalytics: NavigationAnalytics = NavigationAnalytics()
    @Published public private(set) var isNavigationActive = false
    @Published public private(set) var lastError: String?
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let navigationQueue = DispatchQueue(label: "health.navigation", qos: .userInitiated)
    
    // Navigation data caches
    private var routeData: [String: RouteData] = [:]
    private var behaviorData: [String: BehaviorData] = [:]
    private var suggestionData: [String: SuggestionData] = [:]
    
    // Navigation parameters
    private let navigationUpdateInterval: TimeInterval = 60.0 // 1 minute
    private var lastNavigationUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupNavigationSystem()
        setupBehaviorTracking()
        setupSuggestionEngine()
        initializeNavigationPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start intelligent navigation system
    public func startNavigation() async throws {
        isNavigationActive = true
        lastError = nil
        
        do {
            // Initialize navigation platform
            try await initializeNavigationPlatform()
            
            // Start continuous navigation
            try await startContinuousNavigation()
            
            // Update navigation status
            await updateNavigationStatus()
            
            // Track navigation start
            analyticsEngine.trackEvent("navigation_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "current_route": currentRoute.rawValue
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isNavigationActive = false
            }
            throw error
        }
    }
    
    /// Stop intelligent navigation system
    public func stopNavigation() async {
        await MainActor.run {
            self.isNavigationActive = false
        }
        
        // Track navigation stop
        analyticsEngine.trackEvent("navigation_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastNavigationUpdate)
        ])
    }
    
    /// Navigate to route
    public func navigateToRoute(_ route: NavigationRoute, context: NavigationContext? = nil) async throws {
        do {
            // Validate route
            try await validateRoute(route)
            
            // Create navigation entry
            let entry = NavigationEntry(
                id: UUID(),
                fromRoute: currentRoute,
                toRoute: route,
                context: context,
                timestamp: Date()
            )
            
            // Update navigation state
            await MainActor.run {
                self.navigationHistory.append(entry)
                self.currentRoute = route
            }
            
            // Track navigation
            await trackNavigation(entry: entry)
            
            // Update behavior patterns
            await updateBehaviorPatterns(entry: entry)
            
            // Generate new suggestions
            await generateNavigationSuggestions()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get navigation suggestions
    public func getNavigationSuggestions(context: NavigationContext? = nil) async -> [NavigationSuggestion] {
        do {
            // Analyze user behavior
            let behaviorAnalysis = try await analyzeUserBehavior()
            
            // Generate suggestions based on behavior
            let suggestions = try await generateSuggestionsFromBehavior(analysis: behaviorAnalysis, context: context)
            
            // Apply contextual filtering
            let contextualSuggestions = try await applyContextualFiltering(suggestions: suggestions, context: context)
            
            await MainActor.run {
                self.suggestedRoutes = contextualSuggestions
            }
            
            return contextualSuggestions
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get navigation analytics
    public func getNavigationAnalytics() async -> NavigationAnalytics {
        do {
            // Calculate navigation metrics
            let metrics = try await calculateNavigationMetrics()
            
            // Analyze user patterns
            let patterns = try await analyzeNavigationPatterns()
            
            // Generate insights
            let insights = try await generateNavigationInsights(metrics: metrics, patterns: patterns)
            
            let analytics = NavigationAnalytics(
                totalNavigations: metrics.totalNavigations,
                averageSessionDuration: metrics.averageSessionDuration,
                mostVisitedRoutes: metrics.mostVisitedRoutes,
                navigationPatterns: patterns,
                insights: insights,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.navigationAnalytics = analytics
            }
            
            return analytics
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return NavigationAnalytics()
        }
    }
    
    /// Get user behavior analysis
    public func getUserBehaviorAnalysis() async -> UserNavigationBehavior {
        do {
            // Analyze navigation patterns
            let patterns = try await analyzeNavigationPatterns()
            
            // Calculate behavior metrics
            let metrics = try await calculateBehaviorMetrics()
            
            // Generate behavior insights
            let insights = try await generateBehaviorInsights(patterns: patterns, metrics: metrics)
            
            let behavior = UserNavigationBehavior(
                preferredRoutes: patterns.preferredRoutes,
                navigationFrequency: metrics.navigationFrequency,
                sessionDuration: metrics.sessionDuration,
                behaviorPatterns: patterns.patterns,
                insights: insights,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.userBehavior = behavior
            }
            
            return behavior
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return UserNavigationBehavior()
        }
    }
    
    /// Clear navigation history
    public func clearNavigationHistory() async {
        await MainActor.run {
            self.navigationHistory.removeAll()
        }
        
        // Track history clear
        analyticsEngine.trackEvent("navigation_history_cleared", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Get navigation history
    public func getNavigationHistory(limit: Int = 50) async -> [NavigationEntry] {
        let history = navigationHistory.suffix(limit)
        return Array(history)
    }
    
    /// Export navigation data
    public func exportNavigationData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = NavigationExportData(
                navigationHistory: navigationHistory,
                userBehavior: userBehavior,
                navigationAnalytics: navigationAnalytics,
                timestamp: Date()
            )
            
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                return try encoder.encode(exportData)
                
            case .csv:
                return try await exportToCSV(data: exportData)
                
            case .xml:
                return try await exportToXML(data: exportData)
            }
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNavigationSystem() {
        // Setup navigation system
        setupRouteManagement()
        setupContextTracking()
        setupAnalyticsTracking()
        setupAccessibilityFeatures()
    }
    
    private func setupBehaviorTracking() {
        // Setup behavior tracking
        setupBehaviorCollection()
        setupPatternAnalysis()
        setupBehaviorPrediction()
        setupBehaviorOptimization()
    }
    
    private func setupSuggestionEngine() {
        // Setup suggestion engine
        setupSuggestionGeneration()
        setupSuggestionRanking()
        setupSuggestionFiltering()
        setupSuggestionOptimization()
    }
    
    private func initializeNavigationPlatform() async throws {
        // Initialize navigation platform
        try await loadNavigationData()
        try await setupNavigationRoutes()
        try await initializeBehaviorTracking()
    }
    
    private func startContinuousNavigation() async throws {
        // Start continuous navigation
        try await startNavigationUpdates()
        try await startBehaviorTracking()
        try await startSuggestionUpdates()
    }
    
    private func validateRoute(_ route: NavigationRoute) async throws {
        // Validate route accessibility and permissions
        guard route.isAccessible else {
            throw NavigationError.routeNotAccessible(route.rawValue)
        }
        
        // Check route permissions
        if route.requiresPermissions {
            let hasPermissions = await checkRoutePermissions(route)
            guard hasPermissions else {
                throw NavigationError.insufficientPermissions(route.rawValue)
            }
        }
    }
    
    private func trackNavigation(entry: NavigationEntry) async {
        // Track navigation analytics
        analyticsEngine.trackEvent("navigation_occurred", properties: [
            "from_route": entry.fromRoute.rawValue,
            "to_route": entry.toRoute.rawValue,
            "timestamp": entry.timestamp.timeIntervalSince1970,
            "context": entry.context?.description ?? "none"
        ])
    }
    
    private func updateBehaviorPatterns(entry: NavigationEntry) async {
        // Update behavior patterns
        await updateRoutePreferences(entry: entry)
        await updateNavigationTiming(entry: entry)
        await updateContextPatterns(entry: entry)
    }
    
    private func generateNavigationSuggestions() async {
        // Generate new navigation suggestions
        let context = NavigationContext(
            currentRoute: currentRoute,
            timeOfDay: getCurrentTimeOfDay(),
            userHealthStatus: await getCurrentHealthStatus(),
            recentActivity: getRecentActivity()
        )
        
        let suggestions = await getNavigationSuggestions(context: context)
        await MainActor.run {
            self.suggestedRoutes = suggestions
        }
    }
    
    private func analyzeUserBehavior() async throws -> BehaviorAnalysis {
        // Analyze user behavior patterns
        let patterns = await analyzeNavigationPatterns()
        let metrics = await calculateBehaviorMetrics()
        
        return BehaviorAnalysis(
            patterns: patterns,
            metrics: metrics,
            timestamp: Date()
        )
    }
    
    private func generateSuggestionsFromBehavior(analysis: BehaviorAnalysis, context: NavigationContext?) async throws -> [NavigationSuggestion] {
        // Generate suggestions based on behavior analysis
        var suggestions: [NavigationSuggestion] = []
        
        // Add preferred routes
        for route in analysis.patterns.preferredRoutes.prefix(3) {
            suggestions.append(NavigationSuggestion(
                id: UUID(),
                route: route.route,
                priority: .high,
                reason: "Based on your preferences",
                context: context,
                timestamp: Date()
            ))
        }
        
        // Add contextual suggestions
        if let context = context {
            let contextualSuggestions = try await generateContextualSuggestions(context: context)
            suggestions.append(contentsOf: contextualSuggestions)
        }
        
        return suggestions
    }
    
    private func applyContextualFiltering(suggestions: [NavigationSuggestion], context: NavigationContext?) async throws -> [NavigationSuggestion] {
        // Apply contextual filtering
        var filteredSuggestions = suggestions
        
        // Filter by time of day
        if let context = context {
            filteredSuggestions = filteredSuggestions.filter { suggestion in
                suggestion.route.isAppropriateForTime(context.timeOfDay)
            }
        }
        
        // Filter by health status
        if let context = context {
            filteredSuggestions = filteredSuggestions.filter { suggestion in
                suggestion.route.isAppropriateForHealthStatus(context.userHealthStatus)
            }
        }
        
        return filteredSuggestions
    }
    
    private func calculateNavigationMetrics() async throws -> NavigationMetrics {
        // Calculate navigation metrics
        let totalNavigations = navigationHistory.count
        let averageSessionDuration = calculateAverageSessionDuration()
        let mostVisitedRoutes = calculateMostVisitedRoutes()
        
        return NavigationMetrics(
            totalNavigations: totalNavigations,
            averageSessionDuration: averageSessionDuration,
            mostVisitedRoutes: mostVisitedRoutes,
            timestamp: Date()
        )
    }
    
    private func analyzeNavigationPatterns() async throws -> NavigationPatterns {
        // Analyze navigation patterns
        let preferredRoutes = calculatePreferredRoutes()
        let patterns = calculateBehaviorPatterns()
        
        return NavigationPatterns(
            preferredRoutes: preferredRoutes,
            patterns: patterns,
            timestamp: Date()
        )
    }
    
    private func generateNavigationInsights(metrics: NavigationMetrics, patterns: NavigationPatterns) async throws -> [NavigationInsight] {
        // Generate navigation insights
        var insights: [NavigationInsight] = []
        
        // Most visited route insight
        if let mostVisited = metrics.mostVisitedRoutes.first {
            insights.append(NavigationInsight(
                id: UUID(),
                title: "Most Visited Route",
                description: "You visit \(mostVisited.route.displayName) most frequently",
                type: .usage,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        // Session duration insight
        if metrics.averageSessionDuration > 300 { // 5 minutes
            insights.append(NavigationInsight(
                id: UUID(),
                title: "Engaged User",
                description: "You spend an average of \(Int(metrics.averageSessionDuration/60)) minutes per session",
                type: .engagement,
                priority: .low,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func calculateBehaviorMetrics() async throws -> BehaviorMetrics {
        // Calculate behavior metrics
        let navigationFrequency = calculateNavigationFrequency()
        let sessionDuration = calculateAverageSessionDuration()
        
        return BehaviorMetrics(
            navigationFrequency: navigationFrequency,
            sessionDuration: sessionDuration,
            timestamp: Date()
        )
    }
    
    private func generateBehaviorInsights(patterns: NavigationPatterns, metrics: BehaviorMetrics) async throws -> [BehaviorInsight] {
        // Generate behavior insights
        var insights: [BehaviorInsight] = []
        
        // Navigation frequency insight
        if metrics.navigationFrequency > 10 {
            insights.append(BehaviorInsight(
                id: UUID(),
                title: "Active Navigator",
                description: "You navigate frequently throughout the day",
                type: .frequency,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func updateNavigationStatus() async {
        // Update navigation status
        lastNavigationUpdate = Date()
    }
    
    private func loadNavigationData() async throws {
        // Load navigation data
        try await loadRouteData()
        try await loadBehaviorData()
        try await loadSuggestionData()
    }
    
    private func setupNavigationRoutes() async throws {
        // Setup navigation routes
        try await registerNavigationRoutes()
        try await setupRoutePermissions()
        try await setupRouteAnalytics()
    }
    
    private func initializeBehaviorTracking() async throws {
        // Initialize behavior tracking
        try await setupBehaviorCollection()
        try await setupPatternAnalysis()
        try await setupBehaviorPrediction()
    }
    
    private func startNavigationUpdates() async throws {
        // Start navigation updates
        try await startRouteUpdates()
        try await startContextUpdates()
        try await startAnalyticsUpdates()
    }
    
    private func startBehaviorTracking() async throws {
        // Start behavior tracking
        try await startBehaviorCollection()
        try await startPatternAnalysis()
        try await startBehaviorPrediction()
    }
    
    private func startSuggestionUpdates() async throws {
        // Start suggestion updates
        try await startSuggestionGeneration()
        try await startSuggestionRanking()
        try await startSuggestionFiltering()
    }
    
    private func checkRoutePermissions(_ route: NavigationRoute) async -> Bool {
        // Check route permissions
        return true // Placeholder
    }
    
    private func updateRoutePreferences(entry: NavigationEntry) async {
        // Update route preferences
    }
    
    private func updateNavigationTiming(entry: NavigationEntry) async {
        // Update navigation timing
    }
    
    private func updateContextPatterns(entry: NavigationEntry) async {
        // Update context patterns
    }
    
    private func getCurrentTimeOfDay() -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default: return .night
        }
    }
    
    private func getCurrentHealthStatus() async -> HealthStatus {
        // Get current health status
        return .normal
    }
    
    private func getRecentActivity() -> [String] {
        // Get recent activity
        return []
    }
    
    private func generateContextualSuggestions(context: NavigationContext) async throws -> [NavigationSuggestion] {
        // Generate contextual suggestions
        return []
    }
    
    private func calculateAverageSessionDuration() -> TimeInterval {
        // Calculate average session duration
        return 300.0 // 5 minutes placeholder
    }
    
    private func calculateMostVisitedRoutes() -> [RouteVisit] {
        // Calculate most visited routes
        return []
    }
    
    private func calculatePreferredRoutes() -> [PreferredRoute] {
        // Calculate preferred routes
        return []
    }
    
    private func calculateBehaviorPatterns() -> [BehaviorPattern] {
        // Calculate behavior patterns
        return []
    }
    
    private func calculateNavigationFrequency() -> Double {
        // Calculate navigation frequency
        return 5.0 // 5 navigations per day placeholder
    }
    
    private func loadRouteData() async throws {
        // Load route data
    }
    
    private func loadBehaviorData() async throws {
        // Load behavior data
    }
    
    private func loadSuggestionData() async throws {
        // Load suggestion data
    }
    
    private func registerNavigationRoutes() async throws {
        // Register navigation routes
    }
    
    private func setupRoutePermissions() async throws {
        // Setup route permissions
    }
    
    private func setupRouteAnalytics() async throws {
        // Setup route analytics
    }
    
    private func setupBehaviorCollection() async throws {
        // Setup behavior collection
    }
    
    private func setupPatternAnalysis() async throws {
        // Setup pattern analysis
    }
    
    private func setupBehaviorPrediction() async throws {
        // Setup behavior prediction
    }
    
    private func startRouteUpdates() async throws {
        // Start route updates
    }
    
    private func startContextUpdates() async throws {
        // Start context updates
    }
    
    private func startAnalyticsUpdates() async throws {
        // Start analytics updates
    }
    
    private func startBehaviorCollection() async throws {
        // Start behavior collection
    }
    
    private func startPatternAnalysis() async throws {
        // Start pattern analysis
    }
    
    private func startBehaviorPrediction() async throws {
        // Start behavior prediction
    }
    
    private func startSuggestionGeneration() async throws {
        // Start suggestion generation
    }
    
    private func startSuggestionRanking() async throws {
        // Start suggestion ranking
    }
    
    private func startSuggestionFiltering() async throws {
        // Start suggestion filtering
    }
    
    private func exportToCSV(data: NavigationExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: NavigationExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public enum NavigationRoute: String, CaseIterable, Codable {
    case dashboard = "dashboard"
    case health = "health"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case mentalHealth = "mental_health"
    case social = "social"
    case settings = "settings"
    case profile = "profile"
    case analytics = "analytics"
    case coaching = "coaching"
    case challenges = "challenges"
    case achievements = "achievements"
    case voice = "voice"
    case research = "research"
    case privacy = "privacy"
    case deviceIntegration = "device_integration"
    case gamification = "gamification"
    
    var displayName: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .health: return "Health"
        case .fitness: return "Fitness"
        case .nutrition: return "Nutrition"
        case .sleep: return "Sleep"
        case .mentalHealth: return "Mental Health"
        case .social: return "Social"
        case .settings: return "Settings"
        case .profile: return "Profile"
        case .analytics: return "Analytics"
        case .coaching: return "Coaching"
        case .challenges: return "Challenges"
        case .achievements: return "Achievements"
        case .voice: return "Voice"
        case .research: return "Research"
        case .privacy: return "Privacy"
        case .deviceIntegration: return "Device Integration"
        case .gamification: return "Gamification"
        }
    }
    
    var isAccessible: Bool {
        return true // All routes are accessible by default
    }
    
    var requiresPermissions: Bool {
        switch self {
        case .health, .fitness, .sleep, .mentalHealth:
            return true
        default:
            return false
        }
    }
    
    func isAppropriateForTime(_ timeOfDay: TimeOfDay) -> Bool {
        switch self {
        case .sleep:
            return timeOfDay == .night || timeOfDay == .evening
        case .fitness:
            return timeOfDay == .morning || timeOfDay == .afternoon
        default:
            return true
        }
    }
    
    func isAppropriateForHealthStatus(_ status: HealthStatus) -> Bool {
        switch self {
        case .fitness:
            return status != .critical
        case .challenges:
            return status == .normal || status == .good
        default:
            return true
        }
    }
}

public struct NavigationEntry: Identifiable, Codable {
    public let id: UUID
    public let fromRoute: NavigationRoute
    public let toRoute: NavigationRoute
    public let context: NavigationContext?
    public let timestamp: Date
}

public struct NavigationSuggestion: Identifiable, Codable {
    public let id: UUID
    public let route: NavigationRoute
    public let priority: SuggestionPriority
    public let reason: String
    public let context: NavigationContext?
    public let timestamp: Date
}

public struct NavigationContext: Codable {
    public let currentRoute: NavigationRoute
    public let timeOfDay: TimeOfDay
    public let userHealthStatus: HealthStatus
    public let recentActivity: [String]
    
    var description: String {
        return "Route: \(currentRoute.rawValue), Time: \(timeOfDay.rawValue), Health: \(userHealthStatus.rawValue)"
    }
}

public struct UserNavigationBehavior: Codable {
    public let preferredRoutes: [PreferredRoute]
    public let navigationFrequency: Double
    public let sessionDuration: TimeInterval
    public let behaviorPatterns: [BehaviorPattern]
    public let insights: [BehaviorInsight]
    public let timestamp: Date
    
    public init() {
        self.preferredRoutes = []
        self.navigationFrequency = 0.0
        self.sessionDuration = 0.0
        self.behaviorPatterns = []
        self.insights = []
        self.timestamp = Date()
    }
}

public struct NavigationAnalytics: Codable {
    public let totalNavigations: Int
    public let averageSessionDuration: TimeInterval
    public let mostVisitedRoutes: [RouteVisit]
    public let navigationPatterns: NavigationPatterns
    public let insights: [NavigationInsight]
    public let timestamp: Date
    
    public init() {
        self.totalNavigations = 0
        self.averageSessionDuration = 0.0
        self.mostVisitedRoutes = []
        self.navigationPatterns = NavigationPatterns()
        self.insights = []
        self.timestamp = Date()
    }
}

public struct NavigationExportData: Codable {
    public let navigationHistory: [NavigationEntry]
    public let userBehavior: UserNavigationBehavior
    public let navigationAnalytics: NavigationAnalytics
    public let timestamp: Date
}

public enum SuggestionPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum TimeOfDay: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

public enum HealthStatus: String, Codable {
    case critical = "critical"
    case poor = "poor"
    case normal = "normal"
    case good = "good"
    case excellent = "excellent"
}

public struct PreferredRoute: Codable {
    public let route: NavigationRoute
    public let visitCount: Int
    public let lastVisit: Date
    public let averageSessionDuration: TimeInterval
}

public struct BehaviorPattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct BehaviorInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct RouteVisit: Codable {
    public let route: NavigationRoute
    public let visitCount: Int
    public let lastVisit: Date
}

public struct NavigationPatterns: Codable {
    public let preferredRoutes: [PreferredRoute]
    public let patterns: [BehaviorPattern]
    public let timestamp: Date
    
    public init() {
        self.preferredRoutes = []
        self.patterns = []
        self.timestamp = Date()
    }
}

public struct NavigationInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct BehaviorAnalysis: Codable {
    public let patterns: NavigationPatterns
    public let metrics: BehaviorMetrics
    public let timestamp: Date
}

public struct BehaviorMetrics: Codable {
    public let navigationFrequency: Double
    public let sessionDuration: TimeInterval
    public let timestamp: Date
}

public struct NavigationMetrics: Codable {
    public let totalNavigations: Int
    public let averageSessionDuration: TimeInterval
    public let mostVisitedRoutes: [RouteVisit]
    public let timestamp: Date
}

public enum InsightType: String, Codable {
    case usage = "usage"
    case engagement = "engagement"
    case frequency = "frequency"
    case pattern = "pattern"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum NavigationError: Error, LocalizedError {
    case routeNotAccessible(String)
    case insufficientPermissions(String)
    case invalidContext(String)
    
    public var errorDescription: String? {
        switch self {
        case .routeNotAccessible(let route):
            return "Route not accessible: \(route)"
        case .insufficientPermissions(let route):
            return "Insufficient permissions for route: \(route)"
        case .invalidContext(let context):
            return "Invalid navigation context: \(context)"
        }
    }
}

// MARK: - Supporting Structures

public struct RouteData: Codable {
    public let route: NavigationRoute
    public let accessibility: Bool
    public let permissions: [String]
    public let analytics: RouteAnalytics
}

public struct BehaviorData: Codable {
    public let patterns: [BehaviorPattern]
    public let preferences: [String: Any]
    public let analytics: BehaviorAnalytics
}

public struct SuggestionData: Codable {
    public let suggestions: [NavigationSuggestion]
    public let ranking: [String: Double]
    public let filtering: [String: Bool]
}

public struct RouteAnalytics: Codable {
    public let visitCount: Int
    public let averageSessionDuration: TimeInterval
    public let lastVisit: Date
}

public struct BehaviorAnalytics: Codable {
    public let totalSessions: Int
    public let averageSessionDuration: TimeInterval
    public let preferredTimes: [TimeOfDay]
} 