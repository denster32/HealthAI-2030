import Foundation
import StoreKit

/// Protocol defining the requirements for API monetization management
protocol APIMonetizationProtocol {
    func createSubscriptionPlan(_ plan: SubscriptionPlan) async throws -> SubscriptionPlan
    func processUsageBilling(for clientID: String, usage: APIUsage) async throws -> BillingResult
    func generateInvoice(for clientID: String, period: BillingPeriod) async throws -> Invoice
    func handlePayment(_ payment: Payment) async throws -> PaymentResult
    func getRevenueAnalytics(for period: AnalyticsPeriod) async throws -> RevenueAnalytics
}

/// Structure representing a subscription plan
struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Decimal
    let currency: String
    let billingCycle: BillingCycle
    let features: [PlanFeature]
    let rateLimits: RateLimitTier
    let isActive: Bool
    let createdAt: Date
    
    init(name: String, description: String, price: Decimal, currency: String = "USD", billingCycle: BillingCycle, features: [PlanFeature], rateLimits: RateLimitTier) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.price = price
        self.currency = currency
        self.billingCycle = billingCycle
        self.features = features
        self.rateLimits = rateLimits
        self.isActive = true
        self.createdAt = Date()
    }
}

/// Structure representing a plan feature
struct PlanFeature: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let isIncluded: Bool
    let limit: Int?
    
    init(name: String, description: String, isIncluded: Bool = true, limit: Int? = nil) {
        self.id = UUID().uuidString
        self.name = name
        self.description = description
        self.isIncluded = isIncluded
        self.limit = limit
    }
}

/// Structure representing API usage
struct APIUsage: Codable, Identifiable {
    let id: String
    let clientID: String
    let period: BillingPeriod
    let requests: Int
    let dataTransfer: Int64
    let endpoints: [String: Int]
    let overages: [String: Int]
    let timestamp: Date
    
    init(clientID: String, period: BillingPeriod, requests: Int, dataTransfer: Int64, endpoints: [String: Int] = [:], overages: [String: Int] = [:]) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.period = period
        self.requests = requests
        self.dataTransfer = dataTransfer
        self.endpoints = endpoints
        self.overages = overages
        self.timestamp = Date()
    }
}

/// Structure representing billing result
struct BillingResult: Codable, Identifiable {
    let id: String
    let clientID: String
    let period: BillingPeriod
    let baseAmount: Decimal
    let overageAmount: Decimal
    let totalAmount: Decimal
    let currency: String
    let status: BillingStatus
    let processedAt: Date
    
    init(clientID: String, period: BillingPeriod, baseAmount: Decimal, overageAmount: Decimal, currency: String = "USD", status: BillingStatus = .pending) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.period = period
        self.baseAmount = baseAmount
        self.overageAmount = overageAmount
        self.totalAmount = baseAmount + overageAmount
        self.currency = currency
        self.status = status
        self.processedAt = Date()
    }
}

/// Structure representing an invoice
struct Invoice: Codable, Identifiable {
    let id: String
    let clientID: String
    let billingResultID: String
    let invoiceNumber: String
    let amount: Decimal
    let currency: String
    let status: InvoiceStatus
    let dueDate: Date
    let issuedDate: Date
    let items: [InvoiceItem]
    
    init(clientID: String, billingResultID: String, amount: Decimal, currency: String = "USD", dueDate: Date, items: [InvoiceItem]) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.billingResultID = billingResultID
        self.invoiceNumber = generateInvoiceNumber()
        self.amount = amount
        self.currency = currency
        self.status = .pending
        self.dueDate = dueDate
        self.issuedDate = Date()
        self.items = items
    }
}

/// Structure representing an invoice item
struct InvoiceItem: Codable, Identifiable {
    let id: String
    let description: String
    let quantity: Int
    let unitPrice: Decimal
    let totalPrice: Decimal
    
    init(description: String, quantity: Int, unitPrice: Decimal) {
        self.id = UUID().uuidString
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = unitPrice * Decimal(quantity)
    }
}

/// Structure representing a payment
struct Payment: Codable, Identifiable {
    let id: String
    let invoiceID: String
    let amount: Decimal
    let currency: String
    let method: PaymentMethod
    let status: PaymentStatus
    let processedAt: Date
    
    init(invoiceID: String, amount: Decimal, currency: String = "USD", method: PaymentMethod) {
        self.id = UUID().uuidString
        self.invoiceID = invoiceID
        self.amount = amount
        self.currency = currency
        self.method = method
        self.status = .pending
        self.processedAt = Date()
    }
}

/// Structure representing payment result
struct PaymentResult: Codable, Identifiable {
    let id: String
    let paymentID: String
    let success: Bool
    let transactionID: String?
    let errorMessage: String?
    let processedAt: Date
    
    init(paymentID: String, success: Bool, transactionID: String? = nil, errorMessage: String? = nil) {
        self.id = UUID().uuidString
        self.paymentID = paymentID
        self.success = success
        self.transactionID = transactionID
        self.errorMessage = errorMessage
        self.processedAt = Date()
    }
}

/// Structure representing revenue analytics
struct RevenueAnalytics: Codable, Identifiable {
    let id: String
    let period: AnalyticsPeriod
    let totalRevenue: Decimal
    let subscriptionRevenue: Decimal
    let overageRevenue: Decimal
    let activeSubscriptions: Int
    let newSubscriptions: Int
    let churnedSubscriptions: Int
    let averageRevenuePerUser: Decimal
    let revenueByPlan: [String: Decimal]
    let revenueTrend: [RevenueDataPoint]
    
    init(period: AnalyticsPeriod, totalRevenue: Decimal, subscriptionRevenue: Decimal, overageRevenue: Decimal, activeSubscriptions: Int, newSubscriptions: Int, churnedSubscriptions: Int, averageRevenuePerUser: Decimal, revenueByPlan: [String: Decimal], revenueTrend: [RevenueDataPoint]) {
        self.id = UUID().uuidString
        self.period = period
        self.totalRevenue = totalRevenue
        self.subscriptionRevenue = subscriptionRevenue
        self.overageRevenue = overageRevenue
        self.activeSubscriptions = activeSubscriptions
        self.newSubscriptions = newSubscriptions
        self.churnedSubscriptions = churnedSubscriptions
        self.averageRevenuePerUser = averageRevenuePerUser
        self.revenueByPlan = revenueByPlan
        self.revenueTrend = revenueTrend
    }
}

/// Structure representing revenue data point
struct RevenueDataPoint: Codable, Identifiable {
    let id: String
    let date: Date
    let revenue: Decimal
    let subscriptions: Int
    
    init(date: Date, revenue: Decimal, subscriptions: Int) {
        self.id = UUID().uuidString
        self.date = date
        self.revenue = revenue
        self.subscriptions = subscriptions
    }
}

/// Structure representing a subscription
struct Subscription: Codable, Identifiable {
    let id: String
    let clientID: String
    let planID: String
    let status: SubscriptionStatus
    let startDate: Date
    let endDate: Date?
    let autoRenew: Bool
    let lastBillingDate: Date?
    let nextBillingDate: Date?
    
    init(clientID: String, planID: String, status: SubscriptionStatus = .active, startDate: Date, endDate: Date? = nil, autoRenew: Bool = true) {
        self.id = UUID().uuidString
        self.clientID = clientID
        self.planID = planID
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.autoRenew = autoRenew
        self.lastBillingDate = nil
        self.nextBillingDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate)
    }
}

/// Enum representing billing cycle
enum BillingCycle: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
    case payPerUse = "Pay Per Use"
}

/// Enum representing billing period
enum BillingPeriod: String, Codable, CaseIterable {
    case current = "Current"
    case previous = "Previous"
    case custom = "Custom"
}

/// Enum representing billing status
enum BillingStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processed = "Processed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

/// Enum representing invoice status
enum InvoiceStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case paid = "Paid"
    case overdue = "Overdue"
    case cancelled = "Cancelled"
}

/// Enum representing payment method
enum PaymentMethod: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case bankTransfer = "Bank Transfer"
    case paypal = "PayPal"
    case applePay = "Apple Pay"
    case googlePay = "Google Pay"
}

/// Enum representing payment status
enum PaymentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case completed = "Completed"
    case failed = "Failed"
    case refunded = "Refunded"
}

/// Enum representing subscription status
enum SubscriptionStatus: String, Codable, CaseIterable {
    case active = "Active"
    case cancelled = "Cancelled"
    case suspended = "Suspended"
    case expired = "Expired"
    case pending = "Pending"
}

/// Enum representing analytics period
enum AnalyticsPeriod: String, Codable, CaseIterable {
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case yearToDate = "Year to Date"
    case allTime = "All Time"
}

/// Actor responsible for managing API monetization
actor APIMonetizationSystem: APIMonetizationProtocol {
    private let planStore: SubscriptionPlanStore
    private let subscriptionStore: SubscriptionStore
    private let billingEngine: BillingEngine
    private let paymentProcessor: PaymentProcessor
    private let analyticsEngine: RevenueAnalyticsEngine
    private let logger: Logger
    
    init() {
        self.planStore = SubscriptionPlanStore()
        self.subscriptionStore = SubscriptionStore()
        self.billingEngine = BillingEngine()
        self.paymentProcessor = PaymentProcessor()
        self.analyticsEngine = RevenueAnalyticsEngine()
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "Monetization")
    }
    
    /// Creates a new subscription plan
    /// - Parameter plan: The subscription plan to create
    /// - Returns: SubscriptionPlan object
    func createSubscriptionPlan(_ plan: SubscriptionPlan) async throws -> SubscriptionPlan {
        logger.info("Creating subscription plan: \(plan.name)")
        
        // Validate plan
        try validateSubscriptionPlan(plan)
        
        // Store plan
        await planStore.savePlan(plan)
        
        logger.info("Created subscription plan: \(plan.name) with ID: \(plan.id)")
        return plan
    }
    
    /// Processes usage billing for a client
    /// - Parameters:
    ///   - clientID: The client ID to bill
    ///   - usage: The API usage data
    /// - Returns: BillingResult object
    func processUsageBilling(for clientID: String, usage: APIUsage) async throws -> BillingResult {
        logger.info("Processing usage billing for client: \(clientID)")
        
        // Get client's subscription
        guard let subscription = await subscriptionStore.getSubscription(for: clientID) else {
            throw MonetizationError.noActiveSubscription(clientID)
        }
        
        // Get subscription plan
        guard let plan = await planStore.getPlan(byID: subscription.planID) else {
            throw MonetizationError.planNotFound(subscription.planID)
        }
        
        // Calculate billing
        let billingResult = try await billingEngine.calculateBilling(
            usage: usage,
            plan: plan,
            subscription: subscription
        )
        
        // Store billing result
        await billingEngine.storeBillingResult(billingResult)
        
        logger.info("Processed billing for client: \(clientID), amount: \(billingResult.totalAmount)")
        return billingResult
    }
    
    /// Generates an invoice for a client
    /// - Parameters:
    ///   - clientID: The client ID to generate invoice for
    ///   - period: The billing period
    /// - Returns: Invoice object
    func generateInvoice(for clientID: String, period: BillingPeriod) async throws -> Invoice {
        logger.info("Generating invoice for client: \(clientID), period: \(period.rawValue)")
        
        // Get billing result for the period
        guard let billingResult = await billingEngine.getBillingResult(for: clientID, period: period) else {
            throw MonetizationError.noBillingData(clientID, period)
        }
        
        // Generate invoice items
        let items = generateInvoiceItems(from: billingResult)
        
        // Calculate due date (30 days from now)
        let dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        
        // Create invoice
        let invoice = Invoice(
            clientID: clientID,
            billingResultID: billingResult.id,
            amount: billingResult.totalAmount,
            currency: billingResult.currency,
            dueDate: dueDate,
            items: items
        )
        
        // Store invoice
        await billingEngine.storeInvoice(invoice)
        
        logger.info("Generated invoice: \(invoice.invoiceNumber) for client: \(clientID)")
        return invoice
    }
    
    /// Handles a payment
    /// - Parameter payment: The payment to process
    /// - Returns: PaymentResult object
    func handlePayment(_ payment: Payment) async throws -> PaymentResult {
        logger.info("Processing payment: \(payment.id)")
        
        // Process payment through payment processor
        let result = try await paymentProcessor.processPayment(payment)
        
        // Update invoice status if payment successful
        if result.success {
            await billingEngine.updateInvoiceStatus(payment.invoiceID, status: .paid)
        }
        
        logger.info("Payment processed: \(payment.id), success: \(result.success)")
        return result
    }
    
    /// Gets revenue analytics for a period
    /// - Parameter period: The analytics period
    /// - Returns: RevenueAnalytics object
    func getRevenueAnalytics(for period: AnalyticsPeriod) async throws -> RevenueAnalytics {
        logger.info("Generating revenue analytics for period: \(period.rawValue)")
        
        let analytics = try await analyticsEngine.generateAnalytics(for: period)
        
        logger.info("Generated revenue analytics for period: \(period.rawValue)")
        return analytics
    }
    
    /// Validates a subscription plan
    private func validateSubscriptionPlan(_ plan: SubscriptionPlan) throws {
        guard !plan.name.isEmpty else {
            throw MonetizationError.invalidPlan("Plan name cannot be empty")
        }
        
        guard plan.price >= 0 else {
            throw MonetizationError.invalidPlan("Plan price cannot be negative")
        }
        
        guard !plan.features.isEmpty else {
            throw MonetizationError.invalidPlan("Plan must have at least one feature")
        }
    }
    
    /// Generates invoice items from billing result
    private func generateInvoiceItems(from billingResult: BillingResult) -> [InvoiceItem] {
        var items: [InvoiceItem] = []
        
        // Add base subscription item
        if billingResult.baseAmount > 0 {
            items.append(InvoiceItem(
                description: "API Subscription",
                quantity: 1,
                unitPrice: billingResult.baseAmount
            ))
        }
        
        // Add overage items
        if billingResult.overageAmount > 0 {
            items.append(InvoiceItem(
                description: "API Usage Overage",
                quantity: 1,
                unitPrice: billingResult.overageAmount
            ))
        }
        
        return items
    }
    
    /// Generates invoice number
    private func generateInvoiceNumber() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        let randomSuffix = String(format: "%04d", Int.random(in: 1000...9999))
        return "INV-\(dateString)-\(randomSuffix)"
    }
}

/// Class managing subscription plan storage
class SubscriptionPlanStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.planstore")
    private var plans: [String: SubscriptionPlan] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "PlanStore")
        loadDefaultPlans()
    }
    
    /// Saves a subscription plan
    func savePlan(_ plan: SubscriptionPlan) async {
        storageQueue.sync {
            plans[plan.id] = plan
            logger.info("Saved plan: \(plan.name)")
        }
    }
    
    /// Gets a plan by ID
    func getPlan(byID id: String) async -> SubscriptionPlan? {
        var plan: SubscriptionPlan?
        storageQueue.sync {
            plan = plans[id]
        }
        return plan
    }
    
    /// Gets all active plans
    func getActivePlans() async -> [SubscriptionPlan] {
        var activePlans: [SubscriptionPlan] = []
        storageQueue.sync {
            activePlans = plans.values.filter { $0.isActive }
        }
        return activePlans
    }
    
    /// Loads default subscription plans
    private func loadDefaultPlans() {
        let defaultPlans = [
            SubscriptionPlan(
                name: "Basic",
                description: "Basic API access with limited features",
                price: 29.99,
                billingCycle: .monthly,
                features: [
                    PlanFeature(name: "API Access", description: "Basic API endpoints"),
                    PlanFeature(name: "Rate Limiting", description: "1,000 requests/hour"),
                    PlanFeature(name: "Support", description: "Email support")
                ],
                rateLimits: .basic
            ),
            SubscriptionPlan(
                name: "Professional",
                description: "Professional API access with advanced features",
                price: 99.99,
                billingCycle: .monthly,
                features: [
                    PlanFeature(name: "API Access", description: "All API endpoints"),
                    PlanFeature(name: "Rate Limiting", description: "10,000 requests/hour"),
                    PlanFeature(name: "Priority Support", description: "Priority email and phone support"),
                    PlanFeature(name: "Analytics", description: "Advanced analytics dashboard")
                ],
                rateLimits: .premium
            ),
            SubscriptionPlan(
                name: "Enterprise",
                description: "Enterprise API access with unlimited features",
                price: 299.99,
                billingCycle: .monthly,
                features: [
                    PlanFeature(name: "API Access", description: "All API endpoints"),
                    PlanFeature(name: "Rate Limiting", description: "Unlimited requests"),
                    PlanFeature(name: "Dedicated Support", description: "Dedicated account manager"),
                    PlanFeature(name: "Custom Integration", description: "Custom integration support"),
                    PlanFeature(name: "SLA", description: "99.9% uptime SLA")
                ],
                rateLimits: .enterprise
            )
        ]
        
        storageQueue.sync {
            for plan in defaultPlans {
                plans[plan.id] = plan
            }
        }
        
        logger.info("Loaded \(defaultPlans.count) default subscription plans")
    }
}

/// Class managing subscription storage
class SubscriptionStore {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.subscriptionstore")
    private var subscriptions: [String: Subscription] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "SubscriptionStore")
    }
    
    /// Gets subscription for a client
    func getSubscription(for clientID: String) async -> Subscription? {
        var subscription: Subscription?
        storageQueue.sync {
            subscription = subscriptions[clientID]
        }
        return subscription
    }
    
    /// Creates a subscription for a client
    func createSubscription(_ subscription: Subscription) async {
        storageQueue.sync {
            subscriptions[subscription.clientID] = subscription
            logger.info("Created subscription for client: \(subscription.clientID)")
        }
    }
    
    /// Updates a subscription
    func updateSubscription(_ subscription: Subscription) async {
        storageQueue.sync {
            subscriptions[subscription.clientID] = subscription
            logger.info("Updated subscription for client: \(subscription.clientID)")
        }
    }
}

/// Class managing billing engine
class BillingEngine {
    private let logger: Logger
    private let storageQueue = DispatchQueue(label: "com.healthai2030.billingengine")
    private var billingResults: [String: BillingResult] = [:]
    private var invoices: [String: Invoice] = [:]
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "BillingEngine")
    }
    
    /// Calculates billing for usage
    func calculateBilling(usage: APIUsage, plan: SubscriptionPlan, subscription: Subscription) async throws -> BillingResult {
        logger.info("Calculating billing for client: \(usage.clientID)")
        
        // Calculate base amount (subscription cost)
        let baseAmount = plan.price
        
        // Calculate overage amount
        let overageAmount = calculateOverageAmount(usage: usage, plan: plan)
        
        let billingResult = BillingResult(
            clientID: usage.clientID,
            period: usage.period,
            baseAmount: baseAmount,
            overageAmount: overageAmount
        )
        
        return billingResult
    }
    
    /// Stores a billing result
    func storeBillingResult(_ result: BillingResult) async {
        storageQueue.sync {
            billingResults[result.id] = result
            logger.info("Stored billing result: \(result.id)")
        }
    }
    
    /// Gets billing result for a client and period
    func getBillingResult(for clientID: String, period: BillingPeriod) async -> BillingResult? {
        var result: BillingResult?
        storageQueue.sync {
            result = billingResults.values.first { $0.clientID == clientID && $0.period == period }
        }
        return result
    }
    
    /// Stores an invoice
    func storeInvoice(_ invoice: Invoice) async {
        storageQueue.sync {
            invoices[invoice.id] = invoice
            logger.info("Stored invoice: \(invoice.invoiceNumber)")
        }
    }
    
    /// Updates invoice status
    func updateInvoiceStatus(_ invoiceID: String, status: InvoiceStatus) async {
        storageQueue.sync {
            if var invoice = invoices[invoiceID] {
                invoice.status = status
                invoices[invoiceID] = invoice
                logger.info("Updated invoice status: \(invoiceID) to \(status.rawValue)")
            }
        }
    }
    
    /// Calculates overage amount
    private func calculateOverageAmount(usage: APIUsage, plan: SubscriptionPlan) -> Decimal {
        // In a real implementation, this would calculate based on plan limits
        // For now, return a simple calculation
        let baseRequests = plan.rateLimits.requestsPerHour * 24 * 30 // Monthly limit
        let overageRequests = max(0, usage.requests - baseRequests)
        let overageRate: Decimal = 0.001 // $0.001 per request overage
        
        return Decimal(overageRequests) * overageRate
    }
}

/// Class managing payment processing
class PaymentProcessor {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "PaymentProcessor")
    }
    
    /// Processes a payment
    func processPayment(_ payment: Payment) async throws -> PaymentResult {
        logger.info("Processing payment: \(payment.id)")
        
        // Simulate payment processing
        let success = Bool.random() // In real implementation, would integrate with payment gateway
        let transactionID = success ? "TXN_\(UUID().uuidString)" : nil
        let errorMessage = success ? nil : "Payment processing failed"
        
        let result = PaymentResult(
            paymentID: payment.id,
            success: success,
            transactionID: transactionID,
            errorMessage: errorMessage
        )
        
        logger.info("Payment processed: \(payment.id), success: \(success)")
        return result
    }
}

/// Class managing revenue analytics engine
class RevenueAnalyticsEngine {
    private let logger: Logger
    
    init() {
        self.logger = Logger(subsystem: "com.healthai2030.api", category: "AnalyticsEngine")
    }
    
    /// Generates revenue analytics for a period
    func generateAnalytics(for period: AnalyticsPeriod) async throws -> RevenueAnalytics {
        logger.info("Generating revenue analytics for period: \(period.rawValue)")
        
        // In a real implementation, this would query the database for actual data
        // For now, return simulated data
        let totalRevenue: Decimal = 50000.00
        let subscriptionRevenue: Decimal = 45000.00
        let overageRevenue: Decimal = 5000.00
        let activeSubscriptions = 150
        let newSubscriptions = 25
        let churnedSubscriptions = 5
        let averageRevenuePerUser: Decimal = 333.33
        
        let revenueByPlan = [
            "Basic": 15000.00,
            "Professional": 25000.00,
            "Enterprise": 10000.00
        ]
        
        let revenueTrend = generateRevenueTrend(for: period)
        
        let analytics = RevenueAnalytics(
            period: period,
            totalRevenue: totalRevenue,
            subscriptionRevenue: subscriptionRevenue,
            overageRevenue: overageRevenue,
            activeSubscriptions: activeSubscriptions,
            newSubscriptions: newSubscriptions,
            churnedSubscriptions: churnedSubscriptions,
            averageRevenuePerUser: averageRevenuePerUser,
            revenueByPlan: revenueByPlan,
            revenueTrend: revenueTrend
        )
        
        return analytics
    }
    
    /// Generates revenue trend data
    private func generateRevenueTrend(for period: AnalyticsPeriod) -> [RevenueDataPoint] {
        var trend: [RevenueDataPoint] = []
        let calendar = Calendar.current
        let now = Date()
        
        let days: Int
        switch period {
        case .last7Days: days = 7
        case .last30Days: days = 30
        case .last90Days: days = 90
        case .yearToDate: days = calendar.ordinality(of: .day, in: .year, for: now) ?? 365
        case .allTime: days = 365
        }
        
        for i in 0..<days {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let revenue = Decimal.random(in: 1000...2000)
            let subscriptions = Int.random(in: 140...160)
            
            trend.append(RevenueDataPoint(
                date: date,
                revenue: revenue,
                subscriptions: subscriptions
            ))
        }
        
        return trend.reversed()
    }
}

/// Custom error types for monetization operations
enum MonetizationError: Error {
    case invalidPlan(String)
    case planNotFound(String)
    case noActiveSubscription(String)
    case noBillingData(String, BillingPeriod)
    case paymentFailed(String)
    case invalidAmount(Decimal)
}

extension APIMonetizationSystem {
    /// Configuration for monetization system
    struct Configuration {
        let enableAutoBilling: Bool
        let gracePeriodDays: Int
        let lateFeePercentage: Decimal
        let enableOverageBilling: Bool
        
        static let `default` = Configuration(
            enableAutoBilling: true,
            gracePeriodDays: 7,
            lateFeePercentage: 0.05, // 5%
            enableOverageBilling: true
        )
    }
    
    /// Creates a subscription for a client
    func createSubscription(clientID: String, planID: String) async throws -> Subscription {
        guard let plan = await planStore.getPlan(byID: planID) else {
            throw MonetizationError.planNotFound(planID)
        }
        
        let subscription = Subscription(
            clientID: clientID,
            planID: planID,
            startDate: Date()
        )
        
        await subscriptionStore.createSubscription(subscription)
        
        logger.info("Created subscription for client: \(clientID), plan: \(plan.name)")
        return subscription
    }
    
    /// Cancels a subscription
    func cancelSubscription(for clientID: String) async throws {
        guard var subscription = await subscriptionStore.getSubscription(for: clientID) else {
            throw MonetizationError.noActiveSubscription(clientID)
        }
        
        subscription.status = .cancelled
        subscription.endDate = Date()
        
        await subscriptionStore.updateSubscription(subscription)
        
        logger.info("Cancelled subscription for client: \(clientID)")
    }
    
    /// Processes automatic billing for all active subscriptions
    func processAutomaticBilling() async throws {
        logger.info("Processing automatic billing for all active subscriptions")
        
        // In a real implementation, this would:
        // 1. Get all active subscriptions
        // 2. Calculate usage for each
        // 3. Generate invoices
        // 4. Process payments
        
        logger.info("Completed automatic billing processing")
    }
} 