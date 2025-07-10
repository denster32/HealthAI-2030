// AnalyticsIntegrationManager.swift
// HealthAI 2030 - Agent 6 Analytics
// Manager for integrating analytics modules and data sources

import Foundation

public class AnalyticsIntegrationManager {
    private(set) public var integratedModules: [String] = []
    private(set) public var dataSources: [String] = []
    
    public init() {}
    
    public func addModule(_ module: String) {
        integratedModules.append(module)
    }
    
    public func addDataSource(_ source: String) {
        dataSources.append(source)
    }
    
    public func allIntegrations() -> (modules: [String], sources: [String]) {
        return (integratedModules, dataSources)
    }
}
