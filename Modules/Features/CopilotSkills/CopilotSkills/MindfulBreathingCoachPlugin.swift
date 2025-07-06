import Foundation

/// Example plugin: Mindful Breathing Coach
public class MindfulBreathingCoachPlugin: HealthAIPlugin {
    public let pluginName = "Mindful Breathing Coach"
    public let pluginDescription = "Guides users through breathing exercises based on stress levels."
    public func activate() {
        // TODO: Integrate with stress analytics and audio APIs
        print("Mindful Breathing Coach activated!")
    }
}

// Register plugin
PluginManager.shared.register(plugin: MindfulBreathingCoachPlugin())
