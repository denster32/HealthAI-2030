import Foundation
import SwiftUI
import Combine

/// Manages health data across the application
@MainActor
public final class HealthDataManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = HealthDataManager()
    
    // MARK: - Published Properties
    @Published public var latestHealthData: HealthData?
    @Published public var healthDataHistory: [HealthData] = []
    @Published public var isRefreshing = false
    @Published public var lastSyncDate: Date?
    
    // MARK: - Private Properties
    private let swiftDataManager = SwiftDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Refresh health data from various sources
    public func refreshHealthData() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        // Simulate fetching health data
        // In a real app, this would fetch from HealthKit, wearables, etc.
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Update last sync date
        lastSyncDate = Date()
    }
    
    /// Setup tvOS-specific health sync
    public func setupTVOSHealthSync() {
        // Configure sync for tvOS platform
        // This would handle syncing with iPhone/Apple Watch data
    }
    
    /// Fetch specific health metrics
    public func fetchHealthMetric(type: String) async throws -> Double? {
        // Fetch specific metric from health data
        return latestHealthData?.value
    }
    
    /// Store health data
    public func storeHealthData(_ data: HealthData) async throws {
        latestHealthData = data
        healthDataHistory.append(data)
        
        // Limit history to last 100 entries
        if healthDataHistory.count > 100 {
            healthDataHistory.removeFirst()
        }
    }
    
    /// Clear all health data
    public func clearHealthData() {
        latestHealthData = nil
        healthDataHistory.removeAll()
        lastSyncDate = nil
    }
}