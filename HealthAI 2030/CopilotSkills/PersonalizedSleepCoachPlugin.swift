import Foundation

/// Example plugin: Personalized Sleep Coach
public class PersonalizedSleepCoachPlugin: HealthAIPlugin {
    public let pluginName = "Personalized Sleep Coach"
    public let pluginDescription = "Provides tailored sleep tips and reminders based on your data."
    public func activate() {
        // TODO: Integrate with sleep analytics and notification APIs
        print("Personalized Sleep Coach activated!")
    }
}

// Register plugin
PluginManager.shared.register(plugin: PersonalizedSleepCoachPlugin())
