import Foundation

/// Example plugin protocol for community-contributed features
public protocol HealthAIPlugin {
    var pluginName: String { get }
    var pluginDescription: String { get }
    func activate()
}

public class PluginManager {
    public static let shared = PluginManager()
    private var plugins: [HealthAIPlugin] = []
    private init() {}
    public func register(plugin: HealthAIPlugin) {
        plugins.append(plugin)
    }
    public func activateAll() {
        plugins.forEach { $0.activate() }
    }
}
