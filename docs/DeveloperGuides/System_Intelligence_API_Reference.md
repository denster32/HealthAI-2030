# System Intelligence API Reference

## Overview

The System Intelligence API provides comprehensive access to iOS 18/19 intelligent features including Siri suggestions, app shortcuts, automation rules, and predictive insights. This reference covers all public APIs, their parameters, return values, and usage examples.

## Table of Contents

1. [SystemIntelligenceManager](#systemintelligencemanager)
2. [SiriSuggestion](#sirisuggestion)
3. [AppShortcut](#appshortcut)
4. [AutomationRule](#automationrule)
5. [PredictiveInsight](#predictiveinsight)
6. [IntelligentAlert](#intelligentalert)
7. [Supporting Types](#supporting-types)
8. [Usage Examples](#usage-examples)
9. [Error Handling](#error-handling)
10. [Performance Guidelines](#performance-guidelines)

---

## SystemIntelligenceManager

### Class Overview
The main manager class for system intelligence features. Provides centralized access to Siri suggestions, app shortcuts, automation rules, and predictive insights.

### Properties

```swift
class SystemIntelligenceManager: ObservableObject {
    // Published properties for SwiftUI integration
    @Published var siriSuggestions: [SiriSuggestion]
    @Published var appShortcuts: [AppShortcut]
    @Published var intelligentAlerts: [IntelligentAlert]
    @Published var predictiveInsights: [PredictiveInsight]
    @Published var automationRules: [AutomationRule]
}
```

### Initialization

```swift
// Singleton instance
static let shared = SystemIntelligenceManager()

// Private initializer
private init()
```

### Public Methods

#### Siri Suggestions

```swift
/// Generate contextual suggestions based on current health data
/// - Returns: Array of contextual Siri suggestions
func generateContextualSuggestions() async -> [SiriSuggestion]

/// Update Siri suggestions based on latest health data
func updateSiriSuggestions()

/// Activate a specific Siri suggestion
/// - Parameter suggestion: The suggestion to activate
func activateSuggestion(_ suggestion: SiriSuggestion)
```

#### App Shortcuts

```swift
/// Register app shortcuts for voice activation
func registerAppShortcuts()

/// Handle app shortcut execution
/// - Parameter shortcut: The shortcut to execute
func handleAppShortcut(_ shortcut: AppShortcut)

/// Monitor shortcut usage for optimization
func monitorShortcutUsage()
```

#### Automation Rules

```swift
/// Add a new automation rule
/// - Parameter rule: The automation rule to add
func addAutomationRule(_ rule: AutomationRule)

/// Remove an automation rule by ID
/// - Parameter ruleId: The ID of the rule to remove
func removeAutomationRule(_ ruleId: String)

/// Update an existing automation rule
/// - Parameter rule: The updated automation rule
func updateAutomationRule(_ rule: AutomationRule)

/// Check all automation rules for triggers
func checkAutomationRules()
```

#### Predictive Insights

```swift
/// Generate predictive insights based on health data
func generatePredictiveInsights()

/// Get recommendations from predictive insights
/// - Returns: Array of recommendation strings
func getInsightRecommendations() -> [String]

/// Update confidence level for an insight
/// - Parameters:
///   - insightId: The ID of the insight
///   - confidence: The new confidence level (0.0-1.0)
func updateInsightConfidence(_ insightId: String, confidence: Double)
```

#### Notifications

```swift
/// Send an intelligent notification
/// - Parameters:
///   - title: Notification title
///   - body: Notification body
///   - category: Notification category
func sendNotification(title: String, body: String, category: NotificationCategory) async
```

### Private Methods

```swift
/// Setup system intelligence features
private func setupSystemIntelligence()

/// Request notification permissions
private func requestNotificationPermissions()

/// Setup Siri suggestions
private func setupSiriSuggestions()

/// Setup app shortcuts
private func setupAppShortcuts()

/// Setup intelligent automation
private func setupIntelligentAutomation()

/// Setup predictive insights
private func setupPredictiveInsights()

/// Start intelligence monitoring
private func startIntelligenceMonitoring()

/// Start suggestion monitoring
private func startSuggestionMonitoring()

/// Start automation monitoring
private func startAutomationMonitoring()

/// Start predictive analysis
private func startPredictiveAnalysis()

/// Execute automation rule actions
/// - Parameters:
///   - rule: The automation rule to execute
private func executeAutomationRule(_ rule: AutomationRule)

/// Execute a specific automation action
/// - Parameters:
///   - action: The action to execute
///   - rule: The rule context
private func executeAction(_ action: AutomationAction, for rule: AutomationRule) async
```

---

## SiriSuggestion

### Structure Overview
Represents a Siri suggestion with type, content, trigger, and priority information.

### Properties

```swift
struct SiriSuggestion {
    let type: SuggestionType
    let title: String
    let description: String
    let trigger: SuggestionTrigger
    let priority: SuggestionPriority
}
```

### SuggestionType Enum

```swift
enum SuggestionType {
    case mindfulness
    case breathing
    case sleep
    case cardiac
    case respiratory
    case general
}
```

### SuggestionTrigger Enum

```swift
enum SuggestionTrigger {
    case stressLevel
    case respiratoryRate
    case circadianRhythm
    case heartRate
    case afibStatus
    case sleepQuality
    case automation
}
```

### SuggestionPriority Enum

```swift
enum SuggestionPriority {
    case low
    case medium
    case high
    case critical
}
```

### Usage Example

```swift
let suggestion = SiriSuggestion(
    type: .mindfulness,
    title: "Time for mindfulness",
    description: "Based on your stress levels, consider a 5-minute meditation",
    trigger: .stressLevel,
    priority: .high
)
```

---

## AppShortcut

### Structure Overview
Represents an app shortcut for voice activation with intent, content, and activation phrases.

### Properties

```swift
struct AppShortcut {
    let intent: String
    let title: String
    let subtitle: String
    let icon: String
    let phrases: [String]
}
```

### Usage Example

```swift
let shortcut = AppShortcut(
    intent: "LogMoodIntent",
    title: "Log Mood",
    subtitle: "Quickly record your current mood",
    icon: "face.smiling",
    phrases: ["Log my mood", "Record mood", "How I'm feeling"]
)
```

---

## AutomationRule

### Structure Overview
Represents an automation rule with trigger conditions and actions to execute.

### Properties

```swift
struct AutomationRule {
    let id: String
    let name: String
    let description: String
    let trigger: AutomationTrigger
    let condition: () -> Bool
    let actions: [AutomationAction]
    var isActive: Bool
}
```

### AutomationTrigger Enum

```swift
enum AutomationTrigger {
    case stressLevel
    case circadianRhythm
    case afibStatus
    case oxygenSaturation
    case sleepQuality
    case timeOfDay
    case location
}
```

### AutomationAction Enum

```swift
enum AutomationAction {
    case suggestMindfulness
    case adjustEnvironment
    case sendNotification
    case suggestWindDown
    case startSleepOptimization
    case sendEmergencyAlert
    case suggestCardiacCheck
    case recordHealthData
    case suggestBreathingExercise
    case sendAlert
}
```

### Usage Example

```swift
let rule = AutomationRule(
    id: "stress_automation",
    name: "Stress Response",
    description: "Automatically suggest mindfulness when stress is high",
    trigger: .stressLevel,
    condition: { MentalHealthManager.shared.stressLevel == .high },
    actions: [.suggestMindfulness, .adjustEnvironment, .sendNotification],
    isActive: true
)
```

---

## PredictiveInsight

### Structure Overview
Represents a predictive insight with confidence level and recommendations.

### Properties

```swift
struct PredictiveInsight {
    let id: String
    let title: String
    let description: String
    let confidence: Double
    let category: InsightCategory
    let timestamp: Date
    let recommendations: [String]
}
```

### InsightCategory Enum

```swift
enum InsightCategory {
    case health
    case behavior
    case environment
    case lifestyle
}
```

### Usage Example

```swift
let insight = PredictiveInsight(
    id: "sleep_insight_001",
    title: "Sleep Quality Decline",
    description: "Your sleep quality has declined by 15% this week",
    confidence: 0.85,
    category: .health,
    timestamp: Date(),
    recommendations: [
        "Reduce screen time before bed",
        "Maintain consistent sleep schedule",
        "Optimize bedroom environment"
    ]
)
```

---

## IntelligentAlert

### Structure Overview
Represents an intelligent alert with category, priority, and actions.

### Properties

```swift
struct IntelligentAlert {
    let id: String
    let title: String
    let message: String
    let category: AlertCategory
    let priority: AlertPriority
    let timestamp: Date
    let actions: [AlertAction]
}
```

### AlertCategory Enum

```swift
enum AlertCategory {
    case health
    case wellness
    case emergency
    case reminder
}
```

### AlertPriority Enum

```swift
enum AlertPriority {
    case low
    case medium
    case high
    case critical
}
```

### AlertAction Enum

```swift
enum AlertAction {
    case dismiss
    case view
    case takeAction
    case snooze
}
```

### Usage Example

```swift
let alert = IntelligentAlert(
    id: "cardiac_alert_001",
    title: "Cardiac Health Alert",
    message: "Unusual heart rate patterns detected",
    category: .health,
    priority: .high,
    timestamp: Date(),
    actions: [.view, .takeAction, .dismiss]
)
```

---

## Supporting Types

### NotificationCategory Enum

```swift
enum NotificationCategory: String {
    case mindfulness = "mindfulness"
    case sleep = "sleep"
    case cardiac = "cardiac"
    case respiratory = "respiratory"
    case automation = "automation"
    case alert = "alert"
}
```

### Extensions

#### SuggestionTrigger Extension

```swift
extension SiriSuggestion.SuggestionTrigger {
    var displayName: String {
        switch self {
        case .stressLevel: return "Stress Level"
        case .respiratoryRate: return "Respiratory Rate"
        case .circadianRhythm: return "Circadian Rhythm"
        case .heartRate: return "Heart Rate"
        case .afibStatus: return "AFib Status"
        case .sleepQuality: return "Sleep Quality"
        case .automation: return "Automation"
        }
    }
}
```

#### SuggestionPriority Extension

```swift
extension SiriSuggestion.SuggestionPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}
```

#### AutomationTrigger Extension

```swift
extension AutomationRule.AutomationTrigger: CaseIterable {
    var displayName: String {
        switch self {
        case .stressLevel: return "Stress Level"
        case .circadianRhythm: return "Circadian Rhythm"
        case .afibStatus: return "AFib Status"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .sleepQuality: return "Sleep Quality"
        case .timeOfDay: return "Time of Day"
        case .location: return "Location"
        }
    }
}
```

#### AutomationAction Extension

```swift
extension AutomationRule.AutomationAction: CaseIterable {
    var displayName: String {
        switch self {
        case .suggestMindfulness: return "Suggest Mindfulness"
        case .adjustEnvironment: return "Adjust Environment"
        case .sendNotification: return "Send Notification"
        case .suggestWindDown: return "Suggest Wind Down"
        case .startSleepOptimization: return "Start Sleep Optimization"
        case .sendEmergencyAlert: return "Send Emergency Alert"
        case .suggestCardiacCheck: return "Suggest Cardiac Check"
        case .recordHealthData: return "Record Health Data"
        case .suggestBreathingExercise: return "Suggest Breathing Exercise"
        case .sendAlert: return "Send Alert"
        }
    }
}
```

#### InsightCategory Extension

```swift
extension PredictiveInsight.InsightCategory {
    var displayName: String {
        switch self {
        case .health: return "Health"
        case .behavior: return "Behavior"
        case .environment: return "Environment"
        case .lifestyle: return "Lifestyle"
        }
    }
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .behavior: return "person.fill"
        case .environment: return "house.fill"
        case .lifestyle: return "figure.walk"
        }
    }
}
```

---

## Usage Examples

### Basic Setup

```swift
// Initialize system intelligence
let intelligenceManager = SystemIntelligenceManager.shared

// Observe changes
intelligenceManager.$siriSuggestions
    .sink { suggestions in
        print("Updated suggestions: \(suggestions.count)")
    }
    .store(in: &cancellables)
```

### Creating Automation Rules

```swift
// Create a stress response rule
let stressRule = AutomationRule(
    id: "stress_response",
    name: "Stress Response",
    description: "Respond to high stress levels",
    trigger: .stressLevel,
    condition: { MentalHealthManager.shared.stressLevel == .high },
    actions: [.suggestMindfulness, .adjustEnvironment],
    isActive: true
)

// Add the rule
intelligenceManager.addAutomationRule(stressRule)
```

### Handling App Shortcuts

```swift
// Create a custom shortcut
let moodShortcut = AppShortcut(
    intent: "LogMoodIntent",
    title: "Log Mood",
    subtitle: "Record your current mood",
    icon: "face.smiling",
    phrases: ["Log my mood", "Record mood"]
)

// Handle shortcut execution
intelligenceManager.handleAppShortcut(moodShortcut)
```

### Generating Predictive Insights

```swift
// Generate insights
Task {
    await intelligenceManager.generatePredictiveInsights()
    
    // Get recommendations
    let recommendations = intelligenceManager.getInsightRecommendations()
    print("Recommendations: \(recommendations)")
}
```

### Sending Intelligent Notifications

```swift
// Send a notification
Task {
    await intelligenceManager.sendNotification(
        title: "Health Alert",
        body: "Your stress levels are elevated",
        category: .health
    )
}
```

### SwiftUI Integration

```swift
struct IntelligenceView: View {
    @StateObject private var intelligenceManager = SystemIntelligenceManager.shared
    
    var body: some View {
        List {
            Section("Siri Suggestions") {
                ForEach(intelligenceManager.siriSuggestions, id: \.title) { suggestion in
                    SuggestionRow(suggestion: suggestion)
                }
            }
            
            Section("Automation Rules") {
                ForEach(intelligenceManager.automationRules, id: \.id) { rule in
                    RuleRow(rule: rule)
                }
            }
        }
    }
}
```

---

## Error Handling

### Common Errors

```swift
enum IntelligenceError: Error {
    case suggestionNotFound
    case ruleNotFound
    case invalidAction
    case permissionDenied
    case dataUnavailable
}

// Error handling example
func handleSuggestion(_ suggestion: SiriSuggestion) {
    do {
        try validateSuggestion(suggestion)
        intelligenceManager.activateSuggestion(suggestion)
    } catch IntelligenceError.suggestionNotFound {
        print("Suggestion not found")
    } catch IntelligenceError.permissionDenied {
        print("Permission denied")
    } catch {
        print("Unknown error: \(error)")
    }
}
```

### Error Recovery

```swift
// Retry mechanism
func retryOperation<T>(_ operation: () async throws -> T, maxRetries: Int = 3) async throws -> T {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            return try await operation()
        } catch {
            lastError = error
            if attempt < maxRetries {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
            }
        }
    }
    
    throw lastError ?? IntelligenceError.dataUnavailable
}
```

---

## Performance Guidelines

### Optimization Tips

1. **Async Operations**: Use async/await for all network and heavy operations
2. **Memory Management**: Properly manage cancellables and observers
3. **Update Frequency**: Limit update frequency to prevent excessive processing
4. **Caching**: Cache frequently accessed data
5. **Background Processing**: Use background tasks for heavy computations

### Best Practices

```swift
// Efficient data observation
class OptimizedIntelligenceManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let updateQueue = DispatchQueue(label: "intelligence.updates", qos: .userInitiated)
    
    func setupOptimizedMonitoring() {
        // Debounce updates
        healthDataManager.$healthData
            .debounce(for: .seconds(1), scheduler: updateQueue)
            .sink { [weak self] data in
                self?.processHealthData(data)
            }
            .store(in: &cancellables)
    }
    
    private func processHealthData(_ data: HealthData) {
        // Process on background queue
        updateQueue.async { [weak self] in
            self?.updateSuggestions()
            self?.checkRules()
        }
    }
}
```

### Memory Management

```swift
// Proper cleanup
class IntelligenceViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupIntelligence()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancellables.removeAll()
    }
}
```

---

## Testing

### Unit Tests

```swift
class SystemIntelligenceManagerTests: XCTestCase {
    var manager: SystemIntelligenceManager!
    
    override func setUp() {
        super.setUp()
        manager = SystemIntelligenceManager.shared
    }
    
    func testSuggestionGeneration() async {
        let suggestions = await manager.generateContextualSuggestions()
        XCTAssertFalse(suggestions.isEmpty)
    }
    
    func testAutomationRuleExecution() {
        let rule = AutomationRule(
            id: "test_rule",
            name: "Test Rule",
            description: "Test automation rule",
            trigger: .stressLevel,
            condition: { true },
            actions: [.sendNotification],
            isActive: true
        )
        
        manager.addAutomationRule(rule)
        XCTAssertTrue(manager.automationRules.contains { $0.id == "test_rule" })
    }
}
```

### Integration Tests

```swift
class IntelligenceIntegrationTests: XCTestCase {
    func testHealthDataIntegration() {
        let expectation = XCTestExpectation(description: "Health data integration")
        
        // Test health data triggers intelligence updates
        healthDataManager.updateHealthData(sampleData)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            XCTAssertFalse(self.intelligenceManager.siriSuggestions.isEmpty)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
}
```

---

## Migration Guide

### From iOS 17 to iOS 18/19

1. **Update HealthKit Permissions**: Add new data type permissions
2. **Widget Updates**: Implement new widget families and features
3. **Siri Integration**: Update SiriKit integration for new capabilities
4. **Automation Rules**: Migrate existing rules to new format
5. **Notification Categories**: Add new notification categories

### Breaking Changes

- Widget timeline providers now require async/await
- Siri suggestions have new trigger types
- Automation rules use new action types
- HealthKit data types have been updated

---

*This API reference is maintained for HealthAI 2030 System Intelligence features. For questions or contributions, please refer to the project repository.* 