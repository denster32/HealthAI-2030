import Foundation

@available(iOS 18.0, macOS 15.0, *)
public class CardiacHealth {
    public init() {}
    
    public func version() -> String {
        return "1.0.0"
    }
    
    public func getECGProcessor() -> ECGDataProcessor {
        return ECGDataProcessor()
    }
    
    public func getECGInsightManager() -> ECGInsightManager {
        return ECGInsightManager()
    }
} 