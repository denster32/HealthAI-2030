import Foundation
import Combine
import SwiftUI

/// Workflow Automation System
/// Advanced workflow automation system for healthcare providers with intelligent process automation, task management, and workflow optimization
@available(iOS 18.0, macOS 15.0, *)
public actor WorkflowAutomation: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var automationStatus: AutomationStatus = .idle
    @Published public private(set) var currentOperation: AutomationOperation = .none
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var workflowData: WorkflowData = WorkflowData()
    @Published public private(set) var lastError: String?
    @Published public private(set) var notifications: [WorkflowNotification] = []
    
    // MARK: - Private Properties
    private let workflowManager: WorkflowManager
    private let taskManager: TaskManager
    private let automationEngine: AutomationEngine
    private let optimizationEngine: WorkflowOptimizationEngine
    private let analyticsEngine: AnalyticsEngine
    
    private var cancellables = Set<AnyCancellable>()
    private let automationQueue = DispatchQueue(label: "health.workflow.automation", qos: .userInitiated)
    
    // Workflow data
    private var activeWorkflows: [String: Workflow] = [:]
    private var taskQueue: [WorkflowTask] = []
    private var automationRules: [AutomationRule] = []
    private var workflowTemplates: [WorkflowTemplate] = []
    
    // MARK: - Initialization
    public init(workflowManager: WorkflowManager,
                taskManager: TaskManager,
                automationEngine: AutomationEngine,
                optimizationEngine: WorkflowOptimizationEngine,
                analyticsEngine: AnalyticsEngine) {
        self.workflowManager = workflowManager
        self.taskManager = taskManager
        self.automationEngine = automationEngine
        self.optimizationEngine = optimizationEngine
        self.analyticsEngine = analyticsEngine
        
        setupWorkflowAutomation()
        setupTaskManagement()
        setupAutomationEngine()
        setupOptimizationEngine()
        setupNotificationSystem()
    }
    
    // MARK: - Public Methods
    
    /// Load workflow data
    public func loadWorkflowData(providerId: String, department: Department) async throws -> WorkflowData {
        automationStatus = .loading
        currentOperation = .dataLoading
        progress = 0.0
        lastError = nil
        
        do {
            // Load active workflows
            let activeWorkflows = try await loadActiveWorkflows(providerId: providerId, department: department)
            await updateProgress(operation: .workflowLoading, progress: 0.2)
            
            // Load task queue
            let taskQueue = try await loadTaskQueue(providerId: providerId)
            await updateProgress(operation: .taskLoading, progress: 0.4)
            
            // Load automation rules
            let automationRules = try await loadAutomationRules(department: department)
            await updateProgress(operation: .ruleLoading, progress: 0.6)
            
            // Load workflow templates
            let workflowTemplates = try await loadWorkflowTemplates(department: department)
            await updateProgress(operation: .templateLoading, progress: 0.8)
            
            // Compile workflow data
            let workflowData = try await compileWorkflowData(
                activeWorkflows: activeWorkflows,
                taskQueue: taskQueue,
                automationRules: automationRules,
                workflowTemplates: workflowTemplates
            )
            await updateProgress(operation: .compilation, progress: 1.0)
            
            // Complete loading
            automationStatus = .loaded
            
            // Update workflow data
            await MainActor.run {
                self.workflowData = workflowData
            }
            
            // Track analytics
            analyticsEngine.trackEvent("workflow_data_loaded", properties: [
                "provider_id": providerId,
                "department": department.rawValue,
                "workflows_count": activeWorkflows.count,
                "timestamp": Date().timeIntervalSince1970
            ])
            
            return workflowData
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.automationStatus = .error
            }
            throw error
        }
    }
    
    /// Create workflow
    public func createWorkflow(template: WorkflowTemplate, parameters: WorkflowParameters) async throws -> Workflow {
        automationStatus = .creating
        currentOperation = .workflowCreation
        progress = 0.0
        lastError = nil
        
        do {
            // Validate template
            try await validateTemplate(template: template)
            await updateProgress(operation: .validation, progress: 0.1)
            
            // Initialize workflow
            let workflow = try await initializeWorkflow(template: template, parameters: parameters)
            await updateProgress(operation: .initialization, progress: 0.3)
            
            // Create tasks
            let tasks = try await createTasks(workflow: workflow)
            await updateProgress(operation: .taskCreation, progress: 0.5)
            
            // Apply automation rules
            try await applyAutomationRules(workflow: workflow)
            await updateProgress(operation: .ruleApplication, progress: 0.7)
            
            // Activate workflow
            let activatedWorkflow = try await activateWorkflow(workflow: workflow)
            await updateProgress(operation: .activation, progress: 0.9)
            
            // Complete creation
            automationStatus = .created
            
            // Store workflow
            activeWorkflows[activatedWorkflow.workflowId] = activatedWorkflow
            
            return activatedWorkflow
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.automationStatus = .error
            }
            throw error
        }
    }
    
    /// Execute workflow task
    public func executeWorkflowTask(taskId: String, data: TaskData) async throws -> TaskResult {
        automationStatus = .executing
        currentOperation = .taskExecution
        progress = 0.0
        lastError = nil
        
        do {
            // Find task
            guard let task = taskQueue.first(where: { $0.taskId == taskId }) else {
                throw WorkflowError.taskNotFound
            }
            
            // Validate task data
            try await validateTaskData(task: task, data: data)
            await updateProgress(operation: .validation, progress: 0.2)
            
            // Execute task
            let result = try await executeTask(task: task, data: data)
            await updateProgress(operation: .execution, progress: 0.6)
            
            // Update workflow state
            try await updateWorkflowState(task: task, result: result)
            await updateProgress(operation: .stateUpdate, progress: 0.8)
            
            // Trigger next steps
            try await triggerNextSteps(task: task, result: result)
            await updateProgress(operation: .triggering, progress: 1.0)
            
            // Complete execution
            automationStatus = .executed
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.automationStatus = .error
            }
            throw error
        }
    }
    
    /// Optimize workflow
    public func optimizeWorkflow(workflowId: String) async throws -> OptimizationResult {
        automationStatus = .optimizing
        currentOperation = .workflowOptimization
        progress = 0.0
        lastError = nil
        
        do {
            // Find workflow
            guard let workflow = activeWorkflows[workflowId] else {
                throw WorkflowError.workflowNotFound
            }
            
            // Analyze workflow
            let analysis = try await analyzeWorkflow(workflow: workflow)
            await updateProgress(operation: .analysis, progress: 0.3)
            
            // Generate optimizations
            let optimizations = try await generateOptimizations(analysis: analysis)
            await updateProgress(operation: .optimizationGeneration, progress: 0.6)
            
            // Apply optimizations
            let result = try await applyOptimizations(workflow: workflow, optimizations: optimizations)
            await updateProgress(operation: .optimizationApplication, progress: 1.0)
            
            // Complete optimization
            automationStatus = .optimized
            
            return result
            
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.automationStatus = .error
            }
            throw error
        }
    }
    
    /// Get workflow status
    public func getWorkflowStatus(workflowId: String) async throws -> WorkflowStatus {
        guard let workflow = activeWorkflows[workflowId] else {
            throw WorkflowError.workflowNotFound
        }
        
        return workflow.status
    }
    
    /// Get pending tasks
    public func getPendingTasks(providerId: String) async throws -> [WorkflowTask] {
        let taskRequest = PendingTasksRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await taskManager.getPendingTasks(taskRequest)
    }
    
    /// Get automation status
    public func getAutomationStatus() -> AutomationStatus {
        return automationStatus
    }
    
    /// Get current notifications
    public func getCurrentNotifications() -> [WorkflowNotification] {
        return notifications
    }
    
    // MARK: - Private Methods
    
    private func setupWorkflowAutomation() {
        // Setup workflow automation
        setupWorkflowManagement()
        setupProcessAutomation()
        setupStateManagement()
        setupErrorHandling()
    }
    
    private func setupTaskManagement() {
        // Setup task management
        setupTaskCreation()
        setupTaskExecution()
        setupTaskMonitoring()
        setupTaskPrioritization()
    }
    
    private func setupAutomationEngine() {
        // Setup automation engine
        setupRuleEngine()
        setupTriggerSystem()
        setupActionExecution()
        setupConditionEvaluation()
    }
    
    private func setupOptimizationEngine() {
        // Setup optimization engine
        setupPerformanceAnalysis()
        setupOptimizationAlgorithms()
        setupRecommendationEngine()
        setupOptimizationTracking()
    }
    
    private func setupNotificationSystem() {
        // Setup notification system
        setupTaskNotifications()
        setupWorkflowNotifications()
        setupAutomationNotifications()
        setupNotificationDelivery()
    }
    
    private func loadActiveWorkflows(providerId: String, department: Department) async throws -> [Workflow] {
        // Load active workflows
        let workflowRequest = ActiveWorkflowsRequest(
            providerId: providerId,
            department: department,
            timestamp: Date()
        )
        
        return try await workflowManager.loadActiveWorkflows(workflowRequest)
    }
    
    private func loadTaskQueue(providerId: String) async throws -> [WorkflowTask] {
        // Load task queue
        let taskRequest = TaskQueueRequest(
            providerId: providerId,
            timestamp: Date()
        )
        
        return try await taskManager.loadTaskQueue(taskRequest)
    }
    
    private func loadAutomationRules(department: Department) async throws -> [AutomationRule] {
        // Load automation rules
        let ruleRequest = AutomationRulesRequest(
            department: department,
            timestamp: Date()
        )
        
        return try await automationEngine.loadAutomationRules(ruleRequest)
    }
    
    private func loadWorkflowTemplates(department: Department) async throws -> [WorkflowTemplate] {
        // Load workflow templates
        let templateRequest = WorkflowTemplatesRequest(
            department: department,
            timestamp: Date()
        )
        
        return try await workflowManager.loadWorkflowTemplates(templateRequest)
    }
    
    private func compileWorkflowData(activeWorkflows: [Workflow],
                                   taskQueue: [WorkflowTask],
                                   automationRules: [AutomationRule],
                                   workflowTemplates: [WorkflowTemplate]) async throws -> WorkflowData {
        // Compile workflow data
        return WorkflowData(
            activeWorkflows: activeWorkflows,
            taskQueue: taskQueue,
            automationRules: automationRules,
            workflowTemplates: workflowTemplates,
            totalWorkflows: activeWorkflows.count,
            lastUpdated: Date()
        )
    }
    
    private func validateTemplate(template: WorkflowTemplate) async throws {
        // Validate template
        guard !template.templateId.isEmpty else {
            throw WorkflowError.invalidTemplateId
        }
        
        guard !template.steps.isEmpty else {
            throw WorkflowError.invalidTemplateSteps
        }
        
        guard template.department.isValid else {
            throw WorkflowError.invalidDepartment
        }
    }
    
    private func initializeWorkflow(template: WorkflowTemplate, parameters: WorkflowParameters) async throws -> Workflow {
        // Initialize workflow
        let initRequest = WorkflowInitRequest(
            template: template,
            parameters: parameters,
            timestamp: Date()
        )
        
        return try await workflowManager.initializeWorkflow(initRequest)
    }
    
    private func createTasks(workflow: Workflow) async throws -> [WorkflowTask] {
        // Create tasks
        let taskRequest = TaskCreationRequest(
            workflow: workflow,
            timestamp: Date()
        )
        
        return try await taskManager.createTasks(taskRequest)
    }
    
    private func applyAutomationRules(workflow: Workflow) async throws {
        // Apply automation rules
        let ruleRequest = RuleApplicationRequest(
            workflow: workflow,
            timestamp: Date()
        )
        
        try await automationEngine.applyRules(ruleRequest)
    }
    
    private func activateWorkflow(workflow: Workflow) async throws -> Workflow {
        // Activate workflow
        let activationRequest = WorkflowActivationRequest(
            workflow: workflow,
            timestamp: Date()
        )
        
        return try await workflowManager.activateWorkflow(activationRequest)
    }
    
    private func validateTaskData(task: WorkflowTask, data: TaskData) async throws {
        // Validate task data
        guard !data.input.isEmpty else {
            throw WorkflowError.invalidTaskData
        }
        
        guard task.status == .pending else {
            throw WorkflowError.taskNotPending
        }
    }
    
    private func executeTask(task: WorkflowTask, data: TaskData) async throws -> TaskResult {
        // Execute task
        let executionRequest = TaskExecutionRequest(
            task: task,
            data: data,
            timestamp: Date()
        )
        
        return try await taskManager.executeTask(executionRequest)
    }
    
    private func updateWorkflowState(task: WorkflowTask, result: TaskResult) async throws {
        // Update workflow state
        let stateRequest = WorkflowStateRequest(
            task: task,
            result: result,
            timestamp: Date()
        )
        
        try await workflowManager.updateWorkflowState(stateRequest)
    }
    
    private func triggerNextSteps(task: WorkflowTask, result: TaskResult) async throws {
        // Trigger next steps
        let triggerRequest = NextStepsRequest(
            task: task,
            result: result,
            timestamp: Date()
        )
        
        try await automationEngine.triggerNextSteps(triggerRequest)
    }
    
    private func analyzeWorkflow(workflow: Workflow) async throws -> WorkflowAnalysis {
        // Analyze workflow
        let analysisRequest = WorkflowAnalysisRequest(
            workflow: workflow,
            timestamp: Date()
        )
        
        return try await optimizationEngine.analyzeWorkflow(analysisRequest)
    }
    
    private func generateOptimizations(analysis: WorkflowAnalysis) async throws -> [WorkflowOptimization] {
        // Generate optimizations
        let optimizationRequest = OptimizationGenerationRequest(
            analysis: analysis,
            timestamp: Date()
        )
        
        return try await optimizationEngine.generateOptimizations(optimizationRequest)
    }
    
    private func applyOptimizations(workflow: Workflow, optimizations: [WorkflowOptimization]) async throws -> OptimizationResult {
        // Apply optimizations
        let applicationRequest = OptimizationApplicationRequest(
            workflow: workflow,
            optimizations: optimizations,
            timestamp: Date()
        )
        
        return try await optimizationEngine.applyOptimizations(applicationRequest)
    }
    
    private func updateProgress(operation: AutomationOperation, progress: Double) async {
        await MainActor.run {
            self.currentOperation = operation
            self.progress = progress
        }
    }
}

// MARK: - Data Models

public struct WorkflowData: Codable {
    public let activeWorkflows: [Workflow]
    public let taskQueue: [WorkflowTask]
    public let automationRules: [AutomationRule]
    public let workflowTemplates: [WorkflowTemplate]
    public let totalWorkflows: Int
    public let lastUpdated: Date
}

public struct Workflow: Codable {
    public let workflowId: String
    public let templateId: String
    public let name: String
    public let description: String
    public let department: Department
    public let steps: [WorkflowStep]
    public let currentStep: Int
    public let status: WorkflowStatus
    public let priority: Priority
    public let assignedTo: String
    public let createdAt: Date
    public let updatedAt: Date
    public let estimatedCompletion: Date?
}

public struct WorkflowTask: Codable {
    public let taskId: String
    public let workflowId: String
    public let stepId: String
    public let name: String
    public let description: String
    public let type: TaskType
    public let status: TaskStatus
    public let priority: Priority
    public let assignedTo: String
    public let dueDate: Date?
    public let dependencies: [String]
    public let data: TaskData?
    public let createdAt: Date
    public let updatedAt: Date
}

public struct AutomationRule: Codable {
    public let ruleId: String
    public let name: String
    public let description: String
    public let department: Department
    public let conditions: [RuleCondition]
    public let actions: [RuleAction]
    public let priority: Int
    public let isActive: Bool
    public let createdAt: Date
}

public struct WorkflowTemplate: Codable {
    public let templateId: String
    public let name: String
    public let description: String
    public let department: Department
    public let steps: [TemplateStep]
    public let parameters: [TemplateParameter]
    public let version: String
    public let isActive: Bool
    public let createdAt: Date
}

public struct WorkflowParameters: Codable {
    public let patientId: String?
    public let providerId: String
    public let department: Department
    public let priority: Priority
    public let customData: [String: String]
}

public struct TaskData: Codable {
    public let input: [String: Any]
    public let metadata: [String: String]
    public let attachments: [String]
}

public struct TaskResult: Codable {
    public let success: Bool
    public let output: [String: Any]
    public let errors: [String]
    public let executionTime: TimeInterval
    public let timestamp: Date
}

public struct OptimizationResult: Codable {
    public let success: Bool
    public let optimizations: [WorkflowOptimization]
    public let performanceImprovement: Double
    public let timeSaved: TimeInterval
    public let timestamp: Date
}

public struct WorkflowNotification: Codable {
    public let notificationId: String
    public let workflowId: String
    public let type: NotificationType
    public let message: String
    public let priority: Priority
    public let isRead: Bool
    public let timestamp: Date
}

public struct WorkflowStep: Codable {
    public let stepId: String
    public let name: String
    public let description: String
    public let type: StepType
    public let status: StepStatus
    public let assignedTo: String?
    public let dueDate: Date?
    public let dependencies: [String]
    public let data: [String: String]
}

public struct TemplateStep: Codable {
    public let stepId: String
    public let name: String
    public let description: String
    public let type: StepType
    public let required: Bool
    public let estimatedDuration: TimeInterval
    public let dependencies: [String]
    public let automation: [String]
}

public struct TemplateParameter: Codable {
    public let parameterId: String
    public let name: String
    public let type: ParameterType
    public let required: Bool
    public let defaultValue: String?
    public let validation: [String]
}

public struct RuleCondition: Codable {
    public let conditionId: String
    public let field: String
    public let operator: ConditionOperator
    public let value: String
    public let logicalOperator: LogicalOperator?
}

public struct RuleAction: Codable {
    public let actionId: String
    public let type: ActionType
    public let parameters: [String: String]
    public let delay: TimeInterval?
}

public struct WorkflowAnalysis: Codable {
    public let analysisId: String
    public let workflowId: String
    public let performance: PerformanceMetrics
    public let bottlenecks: [Bottleneck]
    public let inefficiencies: [Inefficiency]
    public let recommendations: [Recommendation]
    public let timestamp: Date
}

public struct WorkflowOptimization: Codable {
    public let optimizationId: String
    public let type: OptimizationType
    public let description: String
    public let impact: Impact
    public let effort: Effort
    public let implementation: String
    public let expectedImprovement: Double
}

public struct PerformanceMetrics: Codable {
    public let totalTime: TimeInterval
    public let averageStepTime: TimeInterval
    public let completionRate: Double
    public let errorRate: Double
    public let efficiency: Double
}

public struct Bottleneck: Codable {
    public let stepId: String
    public let description: String
    public let impact: Double
    public let cause: String
    public let solution: String
}

public struct Inefficiency: Codable {
    public let stepId: String
    public let type: InefficiencyType
    public let description: String
    public let impact: Double
    public let recommendation: String
}

public struct Recommendation: Codable {
    public let recommendationId: String
    public let type: RecommendationType
    public let description: String
    public let priority: Priority
    public let impact: Impact
    public let implementation: String
}

// MARK: - Enums

public enum AutomationStatus: String, Codable, CaseIterable {
    case idle, loading, loaded, creating, created, executing, executed, optimizing, optimized, error
}

public enum AutomationOperation: String, Codable, CaseIterable {
    case none, dataLoading, workflowLoading, taskLoading, ruleLoading, templateLoading, compilation, workflowCreation, taskExecution, workflowOptimization, validation, initialization, taskCreation, ruleApplication, activation, execution, stateUpdate, triggering, analysis, optimizationGeneration, optimizationApplication
}

public enum Department: String, Codable, CaseIterable {
    case emergency, cardiology, neurology, oncology, pediatrics, psychiatry, surgery, internal, family, obstetrics, gynecology, dermatology, ophthalmology, orthopedics, radiology, laboratory, pharmacy, administration
    
    public var isValid: Bool {
        return true
    }
}

public enum WorkflowStatus: String, Codable, CaseIterable {
    case draft, active, paused, completed, cancelled, failed
}

public enum TaskStatus: String, Codable, CaseIterable {
    case pending, inProgress, completed, failed, cancelled, blocked
}

public enum TaskType: String, Codable, CaseIterable {
    case manual, automated, approval, notification, dataEntry, review, decision
}

public enum StepType: String, Codable, CaseIterable {
    case task, decision, approval, notification, automation, integration
}

public enum StepStatus: String, Codable, CaseIterable {
    case pending, inProgress, completed, failed, skipped, blocked
}

public enum ParameterType: String, Codable, CaseIterable {
    case string, number, boolean, date, select, multiselect
}

public enum ConditionOperator: String, Codable, CaseIterable {
    case equals, notEquals, greaterThan, lessThan, contains, notContains, startsWith, endsWith
}

public enum LogicalOperator: String, Codable, CaseIterable {
    case and, or, not
}

public enum ActionType: String, Codable, CaseIterable {
    case assign, notify, approve, reject, complete, skip, escalate, automate
}

public enum OptimizationType: String, Codable, CaseIterable {
    case parallelization, automation, simplification, prioritization, resourceAllocation
}

public enum InefficiencyType: String, Codable, CaseIterable {
    case redundant, sequential, manual, delayed, overcomplicated
}

public enum RecommendationType: String, Codable, CaseIterable {
    case process, automation, training, technology, workflow
}

public enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

public enum Impact: String, Codable, CaseIterable {
    case low, medium, high, veryHigh
}

public enum Effort: String, Codable, CaseIterable {
    case low, medium, high, veryHigh
}

public enum NotificationType: String, Codable, CaseIterable {
    case task, workflow, automation, optimization, alert
}

// MARK: - Errors

public enum WorkflowError: Error, LocalizedError {
    case invalidTemplateId
    case invalidTemplateSteps
    case invalidDepartment
    case invalidTaskData
    case taskNotPending
    case taskNotFound
    case workflowNotFound
    case templateNotFound
    case ruleNotFound
    case executionFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidTemplateId:
            return "Invalid template ID"
        case .invalidTemplateSteps:
            return "Invalid template steps"
        case .invalidDepartment:
            return "Invalid department"
        case .invalidTaskData:
            return "Invalid task data"
        case .taskNotPending:
            return "Task is not pending"
        case .taskNotFound:
            return "Task not found"
        case .workflowNotFound:
            return "Workflow not found"
        case .templateNotFound:
            return "Template not found"
        case .ruleNotFound:
            return "Rule not found"
        case .executionFailed:
            return "Task execution failed"
        }
    }
}

// MARK: - Protocols

public protocol WorkflowManager {
    func loadActiveWorkflows(_ request: ActiveWorkflowsRequest) async throws -> [Workflow]
    func loadWorkflowTemplates(_ request: WorkflowTemplatesRequest) async throws -> [WorkflowTemplate]
    func initializeWorkflow(_ request: WorkflowInitRequest) async throws -> Workflow
    func activateWorkflow(_ request: WorkflowActivationRequest) async throws -> Workflow
    func updateWorkflowState(_ request: WorkflowStateRequest) async throws
}

public protocol TaskManager {
    func loadTaskQueue(_ request: TaskQueueRequest) async throws -> [WorkflowTask]
    func createTasks(_ request: TaskCreationRequest) async throws -> [WorkflowTask]
    func executeTask(_ request: TaskExecutionRequest) async throws -> TaskResult
    func getPendingTasks(_ request: PendingTasksRequest) async throws -> [WorkflowTask]
}

public protocol AutomationEngine {
    func loadAutomationRules(_ request: AutomationRulesRequest) async throws -> [AutomationRule]
    func applyRules(_ request: RuleApplicationRequest) async throws
    func triggerNextSteps(_ request: NextStepsRequest) async throws
}

public protocol WorkflowOptimizationEngine {
    func analyzeWorkflow(_ request: WorkflowAnalysisRequest) async throws -> WorkflowAnalysis
    func generateOptimizations(_ request: OptimizationGenerationRequest) async throws -> [WorkflowOptimization]
    func applyOptimizations(_ request: OptimizationApplicationRequest) async throws -> OptimizationResult
}

// MARK: - Supporting Types

public struct ActiveWorkflowsRequest: Codable {
    public let providerId: String
    public let department: Department
    public let timestamp: Date
}

public struct TaskQueueRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct AutomationRulesRequest: Codable {
    public let department: Department
    public let timestamp: Date
}

public struct WorkflowTemplatesRequest: Codable {
    public let department: Department
    public let timestamp: Date
}

public struct WorkflowInitRequest: Codable {
    public let template: WorkflowTemplate
    public let parameters: WorkflowParameters
    public let timestamp: Date
}

public struct WorkflowActivationRequest: Codable {
    public let workflow: Workflow
    public let timestamp: Date
}

public struct WorkflowStateRequest: Codable {
    public let task: WorkflowTask
    public let result: TaskResult
    public let timestamp: Date
}

public struct TaskCreationRequest: Codable {
    public let workflow: Workflow
    public let timestamp: Date
}

public struct TaskExecutionRequest: Codable {
    public let task: WorkflowTask
    public let data: TaskData
    public let timestamp: Date
}

public struct PendingTasksRequest: Codable {
    public let providerId: String
    public let timestamp: Date
}

public struct RuleApplicationRequest: Codable {
    public let workflow: Workflow
    public let timestamp: Date
}

public struct NextStepsRequest: Codable {
    public let task: WorkflowTask
    public let result: TaskResult
    public let timestamp: Date
}

public struct WorkflowAnalysisRequest: Codable {
    public let workflow: Workflow
    public let timestamp: Date
}

public struct OptimizationGenerationRequest: Codable {
    public let analysis: WorkflowAnalysis
    public let timestamp: Date
}

public struct OptimizationApplicationRequest: Codable {
    public let workflow: Workflow
    public let optimizations: [WorkflowOptimization]
    public let timestamp: Date
} 