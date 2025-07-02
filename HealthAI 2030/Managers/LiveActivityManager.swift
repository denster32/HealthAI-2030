import Foundation
import ActivityKit
import SwiftUI

class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published var currentActivity: Activity<HealthActivityAttributes>?

    private init() {}

    func startHealthActivity(activityName: String, patientName: String) {
        let initialContentState = HealthActivityAttributes.ContentState(heartRate: 70, steps: 0, caloriesBurned: 0, lastUpdated: Date())
        let attributes = HealthActivityAttributes(activityName: activityName, patientName: patientName)

        do {
            currentActivity = try Activity.request(attributes: attributes, contentState: initialContentState)
            print("Started Health Live Activity: \(currentActivity?.id ?? "N/A")")
        } catch {
            print("Error starting Health Live Activity: \(error.localizedDescription)")
        }
    }

    func updateHealthActivity(heartRate: Int, steps: Int, caloriesBurned: Int) {
        guard let activity = currentActivity else {
            print("No active Health Live Activity to update.")
            return
        }

        let updatedContentState = HealthActivityAttributes.ContentState(heartRate: heartRate, steps: steps, caloriesBurned: caloriesBurned, lastUpdated: Date())

        Task {
            await activity.update(using: updatedContentState)
            print("Updated Health Live Activity: \(activity.id)")
        }
    }

    func endHealthActivity() {
        guard let activity = currentActivity else {
            print("No active Health Live Activity to end.")
            return
        }

        Task {
            await activity.end(using: activity.contentState)
            print("Ended Health Live Activity: \(activity.id)")
            currentActivity = nil
        }
    }

    // Function to handle dismissal from the Live Activity UI (e.g., button tap)
    func handleDismissalRequest() {
        endHealthActivity()
    }
}