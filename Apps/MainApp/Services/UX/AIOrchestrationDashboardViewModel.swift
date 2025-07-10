import Foundation
import SwiftUI
import Combine

/// AI Orchestration Dashboard ViewModel
/// Manages real-time data, service monitoring, and analytics for the AI orchestration dashboard
@available(iOS 18.0, macOS 15.0, *)
@MainActor
public class AIOrchestrationDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var activeServices: [AIService] = []
    @Published public var aiInsights: [AIInsight] = []
    @Published public var aiPredictions: [AIPrediction] = []
    @Published public var aiPerformance: AIPerformance = AIPerformance()
    @Published public var orchestrationStatus: OrchestrationStatus = .idle
    @Published public var orchestrationProgress: Double = 0.0
    @Published public var serviceStatuses: [AIServiceStatus] = []
    @Published public var recentActivity: [ActivityItem] = []
    @Published public var lastError: String?
    @Published public var isLoading = false
    
    // MARK: - Private Properties
    private let orchestrationService: AdvancedAIOrchestration
    private var cancellables = Set<AnyCancellable>()
    private let updateTimer: Timer?
    
    // MARK: - Initialization
    public init(orchestrationService: AdvancedAIOrchestration? = nil) {
        self.orchestrationService = orchestrationService ?? AdvancedAIOrchestration(
            healthDataManager: HealthDataManager(),
            analyticsEngine: AnalyticsEngine()
        )
        
        setupBindings()
        setupMockData()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring the AI orchestration system
    public func startMonitoring() {
        isLoading = true
        
        Task {
            do {
                // Start orchestration system
                try await orchestrationService.startOrchestrationSystem()
                
                // Load initial data
                await loadInitialData()
                
                // Start continuous monitoring
                startContinuousMonitoring()
                
                await MainActor.run {
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Stop monitoring the AI orchestration system
    public func stopMonitoring() {
        Task {
            await orchestrationService.stopOrchestrationSystem()
        }
    }
    
    /// Refresh all data
    public func refreshData() {
        Task {
            await loadInitialData()
        }
    }
    
    /// Generate new AI insights
    public func generateInsights() {
        Task {
            do {
                try await orchestrationService.generateAIInsights()
                await loadInitialData()
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    /// Generate new AI predictions
    public func generatePredictions() {
        Task {
            do {
                try await orchestrationService.generateAIPredictions()
                await loadInitialData()
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    /// Monitor performance
    public func monitorPerformance() {
        Task {
            do {
                try await orchestrationService.monitorAIPerformance()
                await loadInitialData()
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to orchestration service updates
        orchestrationService.$activeAIServices
            .receive(on: DispatchQueue.main)
            .assign(to: \.activeServices, on: self)
            .store(in: &cancellables)
        
        orchestrationService.$aiInsights
            .receive(on: DispatchQueue.main)
            .assign(to: \.aiInsights, on: self)
            .store(in: &cancellables)
        
        orchestrationService.$aiPredictions
            .receive(on: DispatchQueue.main)
            .assign(to: \.aiPredictions, on: self)
            .store(in: &cancellables)
        
        orchestrationService.$aiPerformance
            .receive(on: DispatchQueue.main)
            .assign(to: \.aiPerformance, on: self)
            .store(in: &cancellables)
        
        orchestrationService.$orchestrationStatus
            .receive(on: DispatchQueue.main)
            .assign(to: \.orchestrationStatus, on: self)
            .store(in: &cancellables)
        
        orchestrationService.$orchestrationProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.orchestrationProgress, on: self)
            .store(in: &cancellables)
    }
    
    private func setupMockData() {
        // Setup mock data for preview and testing
        setupMockServices()
        setupMockInsights()
        setupMockPredictions()
        setupMockPerformance()
        setupMockActivity()
    }
    
    private func loadInitialData() async {
        // Load service statuses
        let statuses = await orchestrationService.getAIServiceStatus()
        await MainActor.run {
            self.serviceStatuses = statuses
        }
        
        // Load analytics
        let analytics = await orchestrationService.getOrchestrationAnalytics()
        await MainActor.run {
            // Update insights count
            if analytics.totalInsights > self.aiInsights.count {
                self.aiInsights = Array(self.aiInsights.prefix(analytics.totalInsights))
            }
            
            // Update predictions count
            if analytics.totalPredictions > self.aiPredictions.count {
                self.aiPredictions = Array(self.aiPredictions.prefix(analytics.totalPredictions))
            }
        }
    }
    
    private func startContinuousMonitoring() {
        // Start timer for continuous updates
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.updateData()
            }
        }
    }
    
    private func updateData() async {
        // Update service statuses
        let statuses = await orchestrationService.getAIServiceStatus()
        await MainActor.run {
            self.serviceStatuses = statuses
        }
        
        // Update performance
        do {
            try await orchestrationService.monitorAIPerformance()
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
        }
        
        // Update recent activity
        await updateRecentActivity()
    }
    
    private func updateRecentActivity() async {
        let newActivity = ActivityItem(
            title: "System Update",
            description: "Updated AI orchestration metrics",
            icon: "arrow.clockwise",
            color: .blue,
            timestamp: Date()
        )
        
        await MainActor.run {
            self.recentActivity.insert(newActivity, at: 0)
            
            // Keep only last 10 activities
            if self.recentActivity.count > 10 {
                self.recentActivity = Array(self.recentActivity.prefix(10))
            }
        }
    }
    
    // MARK: - Mock Data Setup
    
    private func setupMockServices() {
        activeServices = [
            AIService(
                id: UUID(),
                name: "Health Insight Service",
                type: .healthInsight,
                status: .active,
                version: "2.1.0",
                capabilities: [
                    ServiceCapability(name: "Pattern Recognition", description: "Advanced pattern recognition", version: "1.0", isEnabled: true),
                    ServiceCapability(name: "Trend Analysis", description: "Real-time trend analysis", version: "1.2", isEnabled: true),
                    ServiceCapability(name: "Anomaly Detection", description: "Anomaly detection algorithms", version: "1.1", isEnabled: true)
                ],
                performance: ServicePerformance(
                    responseTime: 0.8,
                    throughput: 150,
                    errorRate: 0.02,
                    availability: 0.99
                ),
                timestamp: Date()
            ),
            AIService(
                id: UUID(),
                name: "Recommendation Engine",
                type: .recommendation,
                status: .active,
                version: "1.8.0",
                capabilities: [
                    ServiceCapability(name: "Personalization", description: "Personalized recommendations", version: "2.0", isEnabled: true),
                    ServiceCapability(name: "Context Awareness", description: "Context-aware suggestions", version: "1.5", isEnabled: true),
                    ServiceCapability(name: "Learning", description: "Continuous learning", version: "1.3", isEnabled: true)
                ],
                performance: ServicePerformance(
                    responseTime: 1.2,
                    throughput: 100,
                    errorRate: 0.03,
                    availability: 0.98
                ),
                timestamp: Date()
            ),
            AIService(
                id: UUID(),
                name: "Prediction Service",
                type: .prediction,
                status: .active,
                version: "1.5.0",
                capabilities: [
                    ServiceCapability(name: "Time Series", description: "Time series analysis", version: "1.4", isEnabled: true),
                    ServiceCapability(name: "Risk Assessment", description: "Health risk assessment", version: "1.2", isEnabled: true),
                    ServiceCapability(name: "Forecasting", description: "Health forecasting", version: "1.1", isEnabled: true)
                ],
                performance: ServicePerformance(
                    responseTime: 2.1,
                    throughput: 75,
                    errorRate: 0.04,
                    availability: 0.97
                ),
                timestamp: Date()
            ),
            AIService(
                id: UUID(),
                name: "Performance Monitor",
                type: .performance,
                status: .active,
                version: "1.3.0",
                capabilities: [
                    ServiceCapability(name: "Metrics Collection", description: "Real-time metrics", version: "1.0", isEnabled: true),
                    ServiceCapability(name: "Alerting", description: "Performance alerts", version: "1.1", isEnabled: true),
                    ServiceCapability(name: "Optimization", description: "Auto-optimization", version: "1.2", isEnabled: true)
                ],
                performance: ServicePerformance(
                    responseTime: 0.5,
                    throughput: 200,
                    errorRate: 0.01,
                    availability: 0.995
                ),
                timestamp: Date()
            ),
            AIService(
                id: UUID(),
                name: "Coordination Service",
                type: .coordination,
                status: .active,
                version: "1.0.0",
                capabilities: [
                    ServiceCapability(name: "Load Balancing", description: "Intelligent load balancing", version: "1.0", isEnabled: true),
                    ServiceCapability(name: "Failover", description: "Automatic failover", version: "1.0", isEnabled: true),
                    ServiceCapability(name: "Scheduling", description: "Task scheduling", version: "1.0", isEnabled: true)
                ],
                performance: ServicePerformance(
                    responseTime: 0.3,
                    throughput: 300,
                    errorRate: 0.005,
                    availability: 0.999
                ),
                timestamp: Date()
            )
        ]
    }
    
    private func setupMockInsights() {
        aiInsights = [
            AIInsight(
                id: UUID(),
                title: "Sleep Pattern Optimization",
                description: "Your sleep patterns show improvement with consistent bedtime routines. Consider maintaining this schedule for optimal health benefits.",
                type: .health,
                category: .sleep,
                priority: .high,
                relevance: 0.92,
                confidence: 0.88,
                source: "Health Insight Service",
                metadata: ["pattern_type": "sleep", "trend": "improving"],
                timestamp: Date().addingTimeInterval(-3600)
            ),
            AIInsight(
                id: UUID(),
                title: "Exercise Consistency",
                description: "Your exercise routine is showing excellent consistency. This pattern correlates with improved cardiovascular health markers.",
                type: .behavior,
                category: .fitness,
                priority: .medium,
                relevance: 0.85,
                confidence: 0.91,
                source: "Health Insight Service",
                metadata: ["pattern_type": "exercise", "frequency": "daily"],
                timestamp: Date().addingTimeInterval(-7200)
            ),
            AIInsight(
                id: UUID(),
                title: "Stress Management",
                description: "Stress levels have decreased by 25% over the past week. Your mindfulness practices are effectively reducing stress indicators.",
                type: .pattern,
                category: .mental,
                priority: .high,
                relevance: 0.89,
                confidence: 0.87,
                source: "Health Insight Service",
                metadata: ["trend": "decreasing", "improvement": "25%"],
                timestamp: Date().addingTimeInterval(-10800)
            ),
            AIInsight(
                id: UUID(),
                title: "Nutrition Balance",
                description: "Your nutrition intake shows good balance across macronutrients. Consider increasing protein intake for muscle recovery.",
                type: .recommendation,
                category: .nutrition,
                priority: .medium,
                relevance: 0.78,
                confidence: 0.82,
                source: "Recommendation Engine",
                metadata: ["category": "nutrition", "suggestion": "protein"],
                timestamp: Date().addingTimeInterval(-14400)
            ),
            AIInsight(
                id: UUID(),
                title: "Heart Rate Variability",
                description: "Heart rate variability has improved, indicating better cardiovascular fitness and stress resilience.",
                type: .health,
                category: .general,
                priority: .medium,
                relevance: 0.81,
                confidence: 0.89,
                source: "Health Insight Service",
                metadata: ["metric": "hrv", "trend": "improving"],
                timestamp: Date().addingTimeInterval(-18000)
            )
        ]
    }
    
    private func setupMockPredictions() {
        aiPredictions = [
            AIPrediction(
                id: UUID(),
                title: "Cardiovascular Health",
                description: "Based on current patterns, your cardiovascular health is predicted to improve by 15% over the next 30 days.",
                type: .health,
                category: .cardiovascular,
                confidence: 0.87,
                timeHorizon: 30,
                impact: .medium,
                probability: 0.85,
                source: "Prediction Service",
                metadata: ["improvement": "15%", "confidence": "high"],
                timestamp: Date().addingTimeInterval(-3600)
            ),
            AIPrediction(
                id: UUID(),
                title: "Sleep Quality",
                description: "Sleep quality is expected to improve by 20% in the next 14 days with continued consistent bedtime routine.",
                type: .health,
                category: .sleep,
                confidence: 0.91,
                timeHorizon: 14,
                impact: .high,
                probability: 0.88,
                source: "Prediction Service",
                metadata: ["improvement": "20%", "timeframe": "14 days"],
                timestamp: Date().addingTimeInterval(-7200)
            ),
            AIPrediction(
                id: UUID(),
                title: "Stress Level Trend",
                description: "Stress levels are predicted to continue decreasing by 10% over the next 7 days with current mindfulness practices.",
                type: .trend,
                category: .stress,
                confidence: 0.84,
                timeHorizon: 7,
                impact: .medium,
                probability: 0.82,
                source: "Prediction Service",
                metadata: ["trend": "decreasing", "rate": "10%"],
                timestamp: Date().addingTimeInterval(-10800)
            ),
            AIPrediction(
                id: UUID(),
                title: "Fitness Performance",
                description: "Exercise performance is predicted to increase by 12% over the next 21 days with current training intensity.",
                type: .behavior,
                category: .general,
                confidence: 0.89,
                timeHorizon: 21,
                impact: .medium,
                probability: 0.86,
                source: "Prediction Service",
                metadata: ["improvement": "12%", "category": "fitness"],
                timestamp: Date().addingTimeInterval(-14400)
            ),
            AIPrediction(
                id: UUID(),
                title: "Metabolic Health",
                description: "Metabolic markers are predicted to show 8% improvement over the next 30 days with current nutrition and exercise patterns.",
                type: .health,
                category: .metabolic,
                confidence: 0.86,
                timeHorizon: 30,
                impact: .medium,
                probability: 0.83,
                source: "Prediction Service",
                metadata: ["improvement": "8%", "markers": "metabolic"],
                timestamp: Date().addingTimeInterval(-18000)
            )
        ]
    }
    
    private func setupMockPerformance() {
        aiPerformance = AIPerformance(
            averageResponseTime: 1.2,
            serviceUptime: 0.985,
            errorRate: 0.025,
            throughput: 125,
            latency: 0.8,
            accuracy: 0.89,
            timestamp: Date()
        )
    }
    
    private func setupMockActivity() {
        recentActivity = [
            ActivityItem(
                title: "AI Insights Generated",
                description: "Generated 5 new health insights",
                icon: "lightbulb.fill",
                color: .orange,
                timestamp: Date().addingTimeInterval(-300)
            ),
            ActivityItem(
                title: "Predictions Updated",
                description: "Updated cardiovascular health predictions",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple,
                timestamp: Date().addingTimeInterval(-600)
            ),
            ActivityItem(
                title: "Performance Monitor",
                description: "System performance optimized",
                icon: "speedometer",
                color: .green,
                timestamp: Date().addingTimeInterval(-900)
            ),
            ActivityItem(
                title: "Service Health Check",
                description: "All AI services operational",
                icon: "checkmark.circle.fill",
                color: .blue,
                timestamp: Date().addingTimeInterval(-1200)
            ),
            ActivityItem(
                title: "Data Sync",
                description: "Health data synchronized",
                icon: "arrow.triangle.2.circlepath",
                color: .gray,
                timestamp: Date().addingTimeInterval(-1500)
            )
        ]
    }
    
    private func setupMockServiceStatuses() {
        serviceStatuses = [
            AIServiceStatus(
                id: UUID(),
                serviceName: "Health Insight Service",
                status: .active,
                health: ServiceHealth(
                    status: .healthy,
                    score: 0.95,
                    issues: [],
                    lastCheck: Date()
                ),
                performance: ServicePerformance(
                    responseTime: 0.8,
                    throughput: 150,
                    errorRate: 0.02,
                    availability: 0.99
                ),
                lastUpdate: Date()
            ),
            AIServiceStatus(
                id: UUID(),
                serviceName: "Recommendation Engine",
                status: .active,
                health: ServiceHealth(
                    status: .healthy,
                    score: 0.92,
                    issues: [],
                    lastCheck: Date()
                ),
                performance: ServicePerformance(
                    responseTime: 1.2,
                    throughput: 100,
                    errorRate: 0.03,
                    availability: 0.98
                ),
                lastUpdate: Date()
            ),
            AIServiceStatus(
                id: UUID(),
                serviceName: "Prediction Service",
                status: .active,
                health: ServiceHealth(
                    status: .healthy,
                    score: 0.88,
                    issues: [],
                    lastCheck: Date()
                ),
                performance: ServicePerformance(
                    responseTime: 2.1,
                    throughput: 75,
                    errorRate: 0.04,
                    availability: 0.97
                ),
                lastUpdate: Date()
            ),
            AIServiceStatus(
                id: UUID(),
                serviceName: "Performance Monitor",
                status: .active,
                health: ServiceHealth(
                    status: .healthy,
                    score: 0.98,
                    issues: [],
                    lastCheck: Date()
                ),
                performance: ServicePerformance(
                    responseTime: 0.5,
                    throughput: 200,
                    errorRate: 0.01,
                    availability: 0.995
                ),
                lastUpdate: Date()
            ),
            AIServiceStatus(
                id: UUID(),
                serviceName: "Coordination Service",
                status: .active,
                health: ServiceHealth(
                    status: .healthy,
                    score: 0.99,
                    issues: [],
                    lastCheck: Date()
                ),
                performance: ServicePerformance(
                    responseTime: 0.3,
                    throughput: 300,
                    errorRate: 0.005,
                    availability: 0.999
                ),
                lastUpdate: Date()
            )
        ]
    }
}

// MARK: - Extensions

extension Date {
    func relativeTimeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
} 