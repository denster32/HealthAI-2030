import Foundation

/// Example plugin: Smart Hydration Reminder
public class SmartHydrationPlugin: HealthAIPlugin {
    public let pluginName = "Smart Hydration Reminder"
    public let pluginDescription = "Reminds users to drink water based on activity and weather."
    public func activate() {
        // TODO: Integrate with notification and weather APIs
        print("Hydration reminder activated!")
    }
}

// Register plugin
PluginManager.shared.register(plugin: SmartHydrationPlugin())
