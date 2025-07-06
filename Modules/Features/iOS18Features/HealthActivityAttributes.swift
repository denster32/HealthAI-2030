import Foundation
import ActivityKit

struct HealthActivityAttributes: ActivityAttributes {
    public typealias ContentState = HealthActivityContentState

    public struct ContentState: Codable, Hashable {
        // Dynamic health data
        var heartRate: Int
        var steps: Int
        var caloriesBurned: Int
        var lastUpdated: Date
    }

    // Static data for the activity
    var activityName: String
    var patientName: String
}