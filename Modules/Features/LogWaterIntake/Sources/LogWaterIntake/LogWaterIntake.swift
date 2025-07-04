import Foundation
import HealthKit
import AppIntents

// MARK: - Core Logging Logic

public class WaterIntakeLogger {
    private let healthStore: HKHealthStore

    public init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    public func logWaterIntake(amountInMilliliters: Double) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            // In a real app, throw a specific error here
            print("HealthKit is not available.")
            return
        }

        let waterQuantity = HKQuantity(unit: .literUnit(with: .milli), doubleValue: amountInMilliliters)
        let waterSample = HKQuantitySample(type: waterType, quantity: waterQuantity, start: Date(), end: Date())

        try await healthStore.save(waterSample)
    }
}

// MARK: - App Intent

@available(iOS 18.0, *)
public struct LogWaterIntakeAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Water Intake"
    public static var description = IntentDescription("Logs a specified amount of water intake.")

    @Parameter(title: "Amount", description: "The amount of water in milliliters.")
    public var amount: Double

    public init() {}

    public init(amount: Double) {
        self.amount = amount
    }

    public func perform() async throws -> some IntentResult & ProvidesStringResult {
        let logger = WaterIntakeLogger()
        try await logger.logWaterIntake(amountInMilliliters: amount)
        let result = "Logged \(Int(amount)) ml of water intake."
        return .result(value: result)
    }
}