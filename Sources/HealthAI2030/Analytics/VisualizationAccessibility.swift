// VisualizationAccessibility.swift
// HealthAI 2030 - Agent 6 Analytics
// Accessibility features for analytics visualizations

import Foundation

public struct VisualizationAccessibilityOption {
    public let description: String
    public let enabled: Bool
}

public class VisualizationAccessibility {
    private(set) public var options: [VisualizationAccessibilityOption] = []
    
    public init() {}
    
    public func addOption(_ option: VisualizationAccessibilityOption) {
        options.append(option)
    }
    
    public func enabledOptions() -> [VisualizationAccessibilityOption] {
        return options.filter { $0.enabled }
    }
    
    public func disableAll() {
        options = options.map { VisualizationAccessibilityOption(description: $0.description, enabled: false) }
    }
}
