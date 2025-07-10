import Foundation
import SwiftUI
import Combine

/// Adaptive Dashboard Layout System
/// Provides intelligent dashboard layout that adapts to user preferences, health priorities, and usage patterns
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class AdaptiveDashboardLayout: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentLayout: DashboardLayout = DashboardLayout()
    @Published public private(set) var layoutHistory: [LayoutChange] = []
    @Published public private(set) var userPreferences: DashboardPreferences = DashboardPreferences()
    @Published public private(set) var healthPriorities: [HealthPriority] = []
    @Published public private(set) var layoutAnalytics: LayoutAnalytics = LayoutAnalytics()
    @Published public private(set) var isLayoutActive = false
    @Published public private(set) var lastError: String?
    @Published public private(set) var layoutPerformance: LayoutPerformance = LayoutPerformance()
    
    // MARK: - Private Properties
    private let healthDataManager: HealthDataManager
    private let analyticsEngine: AnalyticsEngine
    private var cancellables = Set<AnyCancellable>()
    private let layoutQueue = DispatchQueue(label: "health.layout", qos: .userInitiated)
    
    // Layout data caches
    private var layoutData: [String: LayoutData] = [:]
    private var preferenceData: [String: PreferenceData] = [:]
    private var priorityData: [String: PriorityData] = [:]
    
    // Layout parameters
    private let layoutUpdateInterval: TimeInterval = 300.0 // 5 minutes
    private var lastLayoutUpdate: Date = Date()
    
    // MARK: - Initialization
    public init(healthDataManager: HealthDataManager, analyticsEngine: AnalyticsEngine) {
        self.healthDataManager = healthDataManager
        self.analyticsEngine = analyticsEngine
        
        setupLayoutSystem()
        setupPreferenceTracking()
        setupPriorityAnalysis()
        initializeLayoutPlatform()
    }
    
    // MARK: - Public Methods
    
    /// Start adaptive layout system
    public func startLayoutSystem() async throws {
        isLayoutActive = true
        lastError = nil
        
        do {
            // Initialize layout platform
            try await initializeLayoutPlatform()
            
            // Start continuous layout optimization
            try await startContinuousLayoutOptimization()
            
            // Update layout status
            await updateLayoutStatus()
            
            // Track layout start
            analyticsEngine.trackEvent("layout_system_started", properties: [
                "timestamp": Date().timeIntervalSince1970,
                "current_layout": currentLayout.id.uuidString
            ])
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.isLayoutActive = false
            }
            throw error
        }
    }
    
    /// Stop adaptive layout system
    public func stopLayoutSystem() async {
        await MainActor.run {
            self.isLayoutActive = false
        }
        
        // Track layout stop
        analyticsEngine.trackEvent("layout_system_stopped", properties: [
            "timestamp": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(lastLayoutUpdate)
        ])
    }
    
    /// Update dashboard layout
    public func updateLayout(components: [DashboardComponent], context: LayoutContext? = nil) async throws {
        do {
            // Validate layout components
            try await validateLayoutComponents(components)
            
            // Create layout change
            let change = LayoutChange(
                id: UUID(),
                fromLayout: currentLayout,
                toComponents: components,
                context: context,
                timestamp: Date()
            )
            
            // Generate new layout
            let newLayout = try await generateAdaptiveLayout(components: components, context: context)
            
            // Update layout state
            await MainActor.run {
                self.layoutHistory.append(change)
                self.currentLayout = newLayout
            }
            
            // Track layout change
            await trackLayoutChange(change: change)
            
            // Update preference patterns
            await updatePreferencePatterns(change: change)
            
            // Optimize layout performance
            await optimizeLayoutPerformance()
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Get layout suggestions
    public func getLayoutSuggestions(context: LayoutContext? = nil) async -> [LayoutSuggestion] {
        do {
            // Analyze user preferences
            let preferenceAnalysis = try await analyzeUserPreferences()
            
            // Generate suggestions based on preferences
            let suggestions = try await generateSuggestionsFromPreferences(analysis: preferenceAnalysis, context: context)
            
            // Apply priority filtering
            let prioritySuggestions = try await applyPriorityFiltering(suggestions: suggestions, context: context)
            
            return prioritySuggestions
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Get layout analytics
    public func getLayoutAnalytics() async -> LayoutAnalytics {
        do {
            // Calculate layout metrics
            let metrics = try await calculateLayoutMetrics()
            
            // Analyze layout patterns
            let patterns = try await analyzeLayoutPatterns()
            
            // Generate insights
            let insights = try await generateLayoutInsights(metrics: metrics, patterns: patterns)
            
            let analytics = LayoutAnalytics(
                totalLayoutChanges: metrics.totalLayoutChanges,
                averageLayoutPerformance: metrics.averageLayoutPerformance,
                mostUsedComponents: metrics.mostUsedComponents,
                layoutPatterns: patterns,
                insights: insights,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.layoutAnalytics = analytics
            }
            
            return analytics
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return LayoutAnalytics()
        }
    }
    
    /// Get user preferences analysis
    public func getUserPreferencesAnalysis() async -> DashboardPreferences {
        do {
            // Analyze layout patterns
            let patterns = try await analyzeLayoutPatterns()
            
            // Calculate preference metrics
            let metrics = try await calculatePreferenceMetrics()
            
            // Generate preference insights
            let insights = try await generatePreferenceInsights(patterns: patterns, metrics: metrics)
            
            let preferences = DashboardPreferences(
                preferredComponents: patterns.preferredComponents,
                layoutFrequency: metrics.layoutFrequency,
                componentUsage: metrics.componentUsage,
                preferencePatterns: patterns.patterns,
                insights: insights,
                timestamp: Date()
            )
            
            await MainActor.run {
                self.userPreferences = preferences
            }
            
            return preferences
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return DashboardPreferences()
        }
    }
    
    /// Get health priorities
    public func getHealthPriorities() async -> [HealthPriority] {
        do {
            // Analyze health data
            let healthAnalysis = try await analyzeHealthData()
            
            // Calculate priorities
            let priorities = try await calculateHealthPriorities(analysis: healthAnalysis)
            
            await MainActor.run {
                self.healthPriorities = priorities
            }
            
            return priorities
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return []
        }
    }
    
    /// Clear layout history
    public func clearLayoutHistory() async {
        await MainActor.run {
            self.layoutHistory.removeAll()
        }
        
        // Track history clear
        analyticsEngine.trackEvent("layout_history_cleared", properties: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Get layout history
    public func getLayoutHistory(limit: Int = 50) async -> [LayoutChange] {
        let history = layoutHistory.suffix(limit)
        return Array(history)
    }
    
    /// Export layout data
    public func exportLayoutData(format: ExportFormat = .json) async throws -> Data {
        do {
            let exportData = LayoutExportData(
                layoutHistory: layoutHistory,
                userPreferences: userPreferences,
                layoutAnalytics: layoutAnalytics,
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
    
    private func setupLayoutSystem() {
        // Setup layout system
        setupComponentManagement()
        setupLayoutOptimization()
        setupPerformanceTracking()
        setupAccessibilityFeatures()
    }
    
    private func setupPreferenceTracking() {
        // Setup preference tracking
        setupPreferenceCollection()
        setupPatternAnalysis()
        setupPreferencePrediction()
        setupPreferenceOptimization()
    }
    
    private func setupPriorityAnalysis() {
        // Setup priority analysis
        setupHealthDataAnalysis()
        setupPriorityCalculation()
        setupPriorityOptimization()
        setupPriorityTracking()
    }
    
    private func initializeLayoutPlatform() async throws {
        // Initialize layout platform
        try await loadLayoutData()
        try await setupLayoutComponents()
        try await initializePreferenceTracking()
    }
    
    private func startContinuousLayoutOptimization() async throws {
        // Start continuous layout optimization
        try await startLayoutUpdates()
        try await startPreferenceTracking()
        try await startPriorityUpdates()
    }
    
    private func validateLayoutComponents(_ components: [DashboardComponent]) async throws {
        // Validate layout components
        for component in components {
            guard component.isValid else {
                throw LayoutError.invalidComponent(component.id.uuidString)
            }
            
            // Check component permissions
            if component.requiresPermissions {
                let hasPermissions = await checkComponentPermissions(component)
                guard hasPermissions else {
                    throw LayoutError.insufficientPermissions(component.id.uuidString)
                }
            }
        }
    }
    
    private func trackLayoutChange(change: LayoutChange) async {
        // Track layout change analytics
        analyticsEngine.trackEvent("layout_changed", properties: [
            "from_layout": change.fromLayout.id.uuidString,
            "component_count": change.toComponents.count,
            "timestamp": change.timestamp.timeIntervalSince1970,
            "context": change.context?.description ?? "none"
        ])
    }
    
    private func updatePreferencePatterns(change: LayoutChange) async {
        // Update preference patterns
        await updateComponentPreferences(change: change)
        await updateLayoutTiming(change: change)
        await updateContextPatterns(change: change)
    }
    
    private func optimizeLayoutPerformance() async {
        // Optimize layout performance
        let performance = await calculateLayoutPerformance()
        await MainActor.run {
            self.layoutPerformance = performance
        }
    }
    
    private func analyzeUserPreferences() async throws -> PreferenceAnalysis {
        // Analyze user preferences
        let patterns = await analyzeLayoutPatterns()
        let metrics = await calculatePreferenceMetrics()
        
        return PreferenceAnalysis(
            patterns: patterns,
            metrics: metrics,
            timestamp: Date()
        )
    }
    
    private func generateSuggestionsFromPreferences(analysis: PreferenceAnalysis, context: LayoutContext?) async throws -> [LayoutSuggestion] {
        // Generate suggestions based on preference analysis
        var suggestions: [LayoutSuggestion] = []
        
        // Add preferred components
        for component in analysis.patterns.preferredComponents.prefix(5) {
            suggestions.append(LayoutSuggestion(
                id: UUID(),
                component: component.component,
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
    
    private func applyPriorityFiltering(suggestions: [LayoutSuggestion], context: LayoutContext?) async throws -> [LayoutSuggestion] {
        // Apply priority filtering
        var filteredSuggestions = suggestions
        
        // Filter by health priorities
        if let context = context {
            filteredSuggestions = filteredSuggestions.filter { suggestion in
                suggestion.component.isAppropriateForHealthPriorities(context.healthPriorities)
            }
        }
        
        // Filter by time of day
        if let context = context {
            filteredSuggestions = filteredSuggestions.filter { suggestion in
                suggestion.component.isAppropriateForTime(context.timeOfDay)
            }
        }
        
        return filteredSuggestions
    }
    
    private func calculateLayoutMetrics() async throws -> LayoutMetrics {
        // Calculate layout metrics
        let totalLayoutChanges = layoutHistory.count
        let averageLayoutPerformance = calculateAverageLayoutPerformance()
        let mostUsedComponents = calculateMostUsedComponents()
        
        return LayoutMetrics(
            totalLayoutChanges: totalLayoutChanges,
            averageLayoutPerformance: averageLayoutPerformance,
            mostUsedComponents: mostUsedComponents,
            timestamp: Date()
        )
    }
    
    private func analyzeLayoutPatterns() async throws -> LayoutPatterns {
        // Analyze layout patterns
        let preferredComponents = calculatePreferredComponents()
        let patterns = calculatePreferencePatterns()
        
        return LayoutPatterns(
            preferredComponents: preferredComponents,
            patterns: patterns,
            timestamp: Date()
        )
    }
    
    private func generateLayoutInsights(metrics: LayoutMetrics, patterns: LayoutPatterns) async throws -> [LayoutInsight] {
        // Generate layout insights
        var insights: [LayoutInsight] = []
        
        // Most used component insight
        if let mostUsed = metrics.mostUsedComponents.first {
            insights.append(LayoutInsight(
                id: UUID(),
                title: "Most Used Component",
                description: "You use \(mostUsed.component.displayName) most frequently",
                type: .usage,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        // Performance insight
        if metrics.averageLayoutPerformance > 0.8 {
            insights.append(LayoutInsight(
                id: UUID(),
                title: "High Performance",
                description: "Your dashboard performs excellently with \(Int(metrics.averageLayoutPerformance * 100))% efficiency",
                type: .performance,
                priority: .low,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func calculatePreferenceMetrics() async throws -> PreferenceMetrics {
        // Calculate preference metrics
        let layoutFrequency = calculateLayoutFrequency()
        let componentUsage = calculateComponentUsage()
        
        return PreferenceMetrics(
            layoutFrequency: layoutFrequency,
            componentUsage: componentUsage,
            timestamp: Date()
        )
    }
    
    private func generatePreferenceInsights(patterns: LayoutPatterns, metrics: PreferenceMetrics) async throws -> [PreferenceInsight] {
        // Generate preference insights
        var insights: [PreferenceInsight] = []
        
        // Layout frequency insight
        if metrics.layoutFrequency > 5 {
            insights.append(PreferenceInsight(
                id: UUID(),
                title: "Active Customizer",
                description: "You frequently customize your dashboard layout",
                type: .frequency,
                priority: .medium,
                timestamp: Date()
            ))
        }
        
        return insights
    }
    
    private func analyzeHealthData() async throws -> HealthAnalysis {
        // Analyze health data
        let healthData = await healthDataManager.getCurrentHealthData()
        let trends = await healthDataManager.getHealthTrends()
        
        return HealthAnalysis(
            currentData: healthData,
            trends: trends,
            timestamp: Date()
        )
    }
    
    private func calculateHealthPriorities(analysis: HealthAnalysis) async throws -> [HealthPriority] {
        // Calculate health priorities based on analysis
        var priorities: [HealthPriority] = []
        
        // Add critical health priorities
        if analysis.currentData.heartRate > 100 {
            priorities.append(HealthPriority(
                id: UUID(),
                category: .cardiovascular,
                priority: .high,
                reason: "Elevated heart rate detected",
                timestamp: Date()
            ))
        }
        
        // Add trend-based priorities
        if analysis.trends.sleepQuality < 0.6 {
            priorities.append(HealthPriority(
                id: UUID(),
                category: .sleep,
                priority: .medium,
                reason: "Sleep quality declining",
                timestamp: Date()
            ))
        }
        
        return priorities
    }
    
    private func generateAdaptiveLayout(components: [DashboardComponent], context: LayoutContext?) async throws -> DashboardLayout {
        // Generate adaptive layout
        let layout = DashboardLayout(
            id: UUID(),
            components: components,
            arrangement: calculateOptimalArrangement(components: components),
            performance: LayoutPerformance(),
            timestamp: Date()
        )
        
        return layout
    }
    
    private func updateLayoutStatus() async {
        // Update layout status
        lastLayoutUpdate = Date()
    }
    
    private func loadLayoutData() async throws {
        // Load layout data
        try await loadComponentData()
        try await loadPreferenceData()
        try await loadPriorityData()
    }
    
    private func setupLayoutComponents() async throws {
        // Setup layout components
        try await registerLayoutComponents()
        try await setupComponentPermissions()
        try await setupComponentAnalytics()
    }
    
    private func initializePreferenceTracking() async throws {
        // Initialize preference tracking
        try await setupPreferenceCollection()
        try await setupPatternAnalysis()
        try await setupPreferencePrediction()
    }
    
    private func startLayoutUpdates() async throws {
        // Start layout updates
        try await startComponentUpdates()
        try await startPerformanceUpdates()
        try await startAnalyticsUpdates()
    }
    
    private func startPreferenceTracking() async throws {
        // Start preference tracking
        try await startPreferenceCollection()
        try await startPatternAnalysis()
        try await startPreferencePrediction()
    }
    
    private func startPriorityUpdates() async throws {
        // Start priority updates
        try await startHealthDataAnalysis()
        try await startPriorityCalculation()
        try await startPriorityOptimization()
    }
    
    private func checkComponentPermissions(_ component: DashboardComponent) async -> Bool {
        // Check component permissions
        return true // Placeholder
    }
    
    private func updateComponentPreferences(change: LayoutChange) async {
        // Update component preferences
    }
    
    private func updateLayoutTiming(change: LayoutChange) async {
        // Update layout timing
    }
    
    private func updateContextPatterns(change: LayoutChange) async {
        // Update context patterns
    }
    
    private func calculateLayoutPerformance() async -> LayoutPerformance {
        // Calculate layout performance
        return LayoutPerformance(
            renderTime: 0.1,
            memoryUsage: 50.0,
            cpuUsage: 10.0,
            batteryImpact: 2.0,
            timestamp: Date()
        )
    }
    
    private func generateContextualSuggestions(context: LayoutContext) async throws -> [LayoutSuggestion] {
        // Generate contextual suggestions
        return []
    }
    
    private func calculateAverageLayoutPerformance() -> Double {
        // Calculate average layout performance
        return 0.85 // 85% performance placeholder
    }
    
    private func calculateMostUsedComponents() -> [ComponentUsage] {
        // Calculate most used components
        return []
    }
    
    private func calculatePreferredComponents() -> [PreferredComponent] {
        // Calculate preferred components
        return []
    }
    
    private func calculatePreferencePatterns() -> [PreferencePattern] {
        // Calculate preference patterns
        return []
    }
    
    private func calculateLayoutFrequency() -> Double {
        // Calculate layout frequency
        return 3.0 // 3 layout changes per day placeholder
    }
    
    private func calculateComponentUsage() -> [String: Int] {
        // Calculate component usage
        return [:]
    }
    
    private func calculateOptimalArrangement(components: [DashboardComponent]) -> ComponentArrangement {
        // Calculate optimal arrangement
        return ComponentArrangement(
            grid: GridLayout(columns: 2, rows: 3),
            components: components,
            timestamp: Date()
        )
    }
    
    private func loadComponentData() async throws {
        // Load component data
    }
    
    private func loadPreferenceData() async throws {
        // Load preference data
    }
    
    private func loadPriorityData() async throws {
        // Load priority data
    }
    
    private func registerLayoutComponents() async throws {
        // Register layout components
    }
    
    private func setupComponentPermissions() async throws {
        // Setup component permissions
    }
    
    private func setupComponentAnalytics() async throws {
        // Setup component analytics
    }
    
    private func setupPreferenceCollection() async throws {
        // Setup preference collection
    }
    
    private func setupPatternAnalysis() async throws {
        // Setup pattern analysis
    }
    
    private func setupPreferencePrediction() async throws {
        // Setup preference prediction
    }
    
    private func startComponentUpdates() async throws {
        // Start component updates
    }
    
    private func startPerformanceUpdates() async throws {
        // Start performance updates
    }
    
    private func startAnalyticsUpdates() async throws {
        // Start analytics updates
    }
    
    private func startPreferenceCollection() async throws {
        // Start preference collection
    }
    
    private func startPatternAnalysis() async throws {
        // Start pattern analysis
    }
    
    private func startPreferencePrediction() async throws {
        // Start preference prediction
    }
    
    private func startHealthDataAnalysis() async throws {
        // Start health data analysis
    }
    
    private func startPriorityCalculation() async throws {
        // Start priority calculation
    }
    
    private func startPriorityOptimization() async throws {
        // Start priority optimization
    }
    
    private func exportToCSV(data: LayoutExportData) async throws -> Data {
        // Export to CSV
        return Data()
    }
    
    private func exportToXML(data: LayoutExportData) async throws -> Data {
        // Export to XML
        return Data()
    }
}

// MARK: - Data Models

public struct DashboardLayout: Identifiable, Codable {
    public let id: UUID
    public let components: [DashboardComponent]
    public let arrangement: ComponentArrangement
    public let performance: LayoutPerformance
    public let timestamp: Date
    
    public init() {
        self.id = UUID()
        self.components = []
        self.arrangement = ComponentArrangement()
        self.performance = LayoutPerformance()
        self.timestamp = Date()
    }
}

public struct DashboardComponent: Identifiable, Codable {
    public let id: UUID
    public let type: ComponentType
    public let title: String
    public let description: String
    public let priority: ComponentPriority
    public let size: ComponentSize
    public let position: ComponentPosition
    public let isVisible: Bool
    public let requiresPermissions: Bool
    public let timestamp: Date
    
    var isValid: Bool {
        return !title.isEmpty && !description.isEmpty
    }
    
    var displayName: String {
        return title
    }
    
    func isAppropriateForHealthPriorities(_ priorities: [HealthPriority]) -> Bool {
        // Check if component is appropriate for health priorities
        return true // Placeholder
    }
    
    func isAppropriateForTime(_ timeOfDay: TimeOfDay) -> Bool {
        // Check if component is appropriate for time of day
        switch type {
        case .sleep:
            return timeOfDay == .night || timeOfDay == .evening
        case .fitness:
            return timeOfDay == .morning || timeOfDay == .afternoon
        default:
            return true
        }
    }
}

public struct LayoutChange: Identifiable, Codable {
    public let id: UUID
    public let fromLayout: DashboardLayout
    public let toComponents: [DashboardComponent]
    public let context: LayoutContext?
    public let timestamp: Date
}

public struct LayoutSuggestion: Identifiable, Codable {
    public let id: UUID
    public let component: DashboardComponent
    public let priority: SuggestionPriority
    public let reason: String
    public let context: LayoutContext?
    public let timestamp: Date
}

public struct LayoutContext: Codable {
    public let timeOfDay: TimeOfDay
    public let healthPriorities: [HealthPriority]
    public let userActivity: [String]
    public let deviceType: DeviceType
    
    var description: String {
        return "Time: \(timeOfDay.rawValue), Priorities: \(healthPriorities.count), Device: \(deviceType.rawValue)"
    }
}

public struct DashboardPreferences: Codable {
    public let preferredComponents: [PreferredComponent]
    public let layoutFrequency: Double
    public let componentUsage: [String: Int]
    public let preferencePatterns: [PreferencePattern]
    public let insights: [PreferenceInsight]
    public let timestamp: Date
    
    public init() {
        self.preferredComponents = []
        self.layoutFrequency = 0.0
        self.componentUsage = [:]
        self.preferencePatterns = []
        self.insights = []
        self.timestamp = Date()
    }
}

public struct LayoutAnalytics: Codable {
    public let totalLayoutChanges: Int
    public let averageLayoutPerformance: Double
    public let mostUsedComponents: [ComponentUsage]
    public let layoutPatterns: LayoutPatterns
    public let insights: [LayoutInsight]
    public let timestamp: Date
    
    public init() {
        self.totalLayoutChanges = 0
        self.averageLayoutPerformance = 0.0
        self.mostUsedComponents = []
        self.layoutPatterns = LayoutPatterns()
        self.insights = []
        self.timestamp = Date()
    }
}

public struct LayoutExportData: Codable {
    public let layoutHistory: [LayoutChange]
    public let userPreferences: DashboardPreferences
    public let layoutAnalytics: LayoutAnalytics
    public let timestamp: Date
}

public struct LayoutPerformance: Codable {
    public let renderTime: TimeInterval
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let batteryImpact: Double
    public let timestamp: Date
    
    public init() {
        self.renderTime = 0.0
        self.memoryUsage = 0.0
        self.cpuUsage = 0.0
        self.batteryImpact = 0.0
        self.timestamp = Date()
    }
}

public enum ComponentType: String, Codable {
    case health = "health"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case sleep = "sleep"
    case mentalHealth = "mental_health"
    case social = "social"
    case analytics = "analytics"
    case coaching = "coaching"
    case challenges = "challenges"
    case achievements = "achievements"
    case voice = "voice"
    case research = "research"
    case privacy = "privacy"
    case deviceIntegration = "device_integration"
    case gamification = "gamification"
}

public enum ComponentPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum ComponentSize: String, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case full = "full"
}

public struct ComponentPosition: Codable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int
}

public struct ComponentArrangement: Codable {
    public let grid: GridLayout
    public let components: [DashboardComponent]
    public let timestamp: Date
    
    public init() {
        self.grid = GridLayout()
        self.components = []
        self.timestamp = Date()
    }
}

public struct GridLayout: Codable {
    public let columns: Int
    public let rows: Int
    
    public init(columns: Int = 2, rows: Int = 3) {
        self.columns = columns
        self.rows = rows
    }
}

public struct HealthPriority: Identifiable, Codable {
    public let id: UUID
    public let category: HealthCategory
    public let priority: PriorityLevel
    public let reason: String
    public let timestamp: Date
}

public enum HealthCategory: String, Codable {
    case cardiovascular = "cardiovascular"
    case respiratory = "respiratory"
    case sleep = "sleep"
    case fitness = "fitness"
    case nutrition = "nutrition"
    case mentalHealth = "mental_health"
    case social = "social"
}

public enum PriorityLevel: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
}

public enum DeviceType: String, Codable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case mac = "mac"
    case watch = "watch"
    case tv = "tv"
}

public struct PreferredComponent: Codable {
    public let component: DashboardComponent
    public let usageCount: Int
    public let lastUsed: Date
    public let averageSessionDuration: TimeInterval
}

public struct PreferencePattern: Codable {
    public let pattern: String
    public let frequency: Double
    public let confidence: Double
    public let timestamp: Date
}

public struct PreferenceInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct ComponentUsage: Codable {
    public let component: DashboardComponent
    public let usageCount: Int
    public let lastUsed: Date
}

public struct LayoutPatterns: Codable {
    public let preferredComponents: [PreferredComponent]
    public let patterns: [PreferencePattern]
    public let timestamp: Date
    
    public init() {
        self.preferredComponents = []
        self.patterns = []
        self.timestamp = Date()
    }
}

public struct LayoutInsight: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let type: InsightType
    public let priority: InsightPriority
    public let timestamp: Date
}

public struct PreferenceAnalysis: Codable {
    public let patterns: LayoutPatterns
    public let metrics: PreferenceMetrics
    public let timestamp: Date
}

public struct PreferenceMetrics: Codable {
    public let layoutFrequency: Double
    public let componentUsage: [String: Int]
    public let timestamp: Date
}

public struct LayoutMetrics: Codable {
    public let totalLayoutChanges: Int
    public let averageLayoutPerformance: Double
    public let mostUsedComponents: [ComponentUsage]
    public let timestamp: Date
}

public struct HealthAnalysis: Codable {
    public let currentData: HealthData
    public let trends: HealthTrends
    public let timestamp: Date
}

public struct HealthData: Codable {
    public let heartRate: Double
    public let sleepQuality: Double
    public let activityLevel: Double
    public let stressLevel: Double
}

public struct HealthTrends: Codable {
    public let sleepQuality: Double
    public let activityLevel: Double
    public let stressLevel: Double
}

public enum InsightType: String, Codable {
    case usage = "usage"
    case performance = "performance"
    case frequency = "frequency"
    case pattern = "pattern"
}

public enum InsightPriority: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"
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

public enum ExportFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

public enum LayoutError: Error, LocalizedError {
    case invalidComponent(String)
    case insufficientPermissions(String)
    case invalidContext(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidComponent(let component):
            return "Invalid component: \(component)"
        case .insufficientPermissions(let component):
            return "Insufficient permissions for component: \(component)"
        case .invalidContext(let context):
            return "Invalid layout context: \(context)"
        }
    }
}

// MARK: - Supporting Structures

public struct LayoutData: Codable {
    public let components: [DashboardComponent]
    public let arrangement: ComponentArrangement
    public let analytics: LayoutAnalytics
}

public struct PreferenceData: Codable {
    public let patterns: [PreferencePattern]
    public let preferences: [String: Any]
    public let analytics: PreferenceAnalytics
}

public struct PriorityData: Codable {
    public let priorities: [HealthPriority]
    public let analysis: HealthAnalysis
    public let analytics: PriorityAnalytics
}

public struct PreferenceAnalytics: Codable {
    public let totalPreferences: Int
    public let averagePreferenceScore: Double
    public let mostPreferredComponents: [String]
}

public struct PriorityAnalytics: Codable {
    public let totalPriorities: Int
    public let averagePriorityLevel: PriorityLevel
    public let mostCommonCategories: [HealthCategory]
} 