import Foundation

/// Example plugin: Activity Streak Tracker
public class ActivityStreakTrackerPlugin: HealthAIPlugin {
    public let pluginName = "Activity Streak Tracker"
    public let pluginDescription = "Tracks daily activity streaks and motivates users to keep moving."
    public func activate() {
        // TODO: Integrate with activity analytics and notification APIs
        print("Activity Streak Tracker activated!")
    }
}

// Register plugin
PluginManager.shared.register(plugin: ActivityStreakTrackerPlugin())
