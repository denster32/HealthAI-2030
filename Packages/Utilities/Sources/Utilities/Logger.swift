import Foundation
import os.log

@available(iOS 17.0, *)
@available(macOS 14.0, *)

// MARK: - Centralized Logger Extensions

extension Logger {
    // Core app loggers
    static let app = Logger(subsystem: "com.somnasync.pro", category: "App")
    static let ui = Logger(subsystem: "com.somnasync.pro", category: "UI")
    
    // Service loggers
    static let audioEngine = Logger(subsystem: "com.somnasync.pro", category: "AudioEngine")
    static let aiEngine = Logger(subsystem: "com.somnasync.pro", category: "AIEngine")
    static let smartAlarm = Logger(subsystem: "com.somnasync.pro", category: "SmartAlarm")
    
    // Manager loggers
    static let sleepManager = Logger(subsystem: "com.somnasync.pro", category: "SleepManager")
    static let healthKit = Logger(subsystem: "com.somnasync.pro", category: "HealthKit")
    static let watchManager = Logger(subsystem: "com.somnasync.pro", category: "WatchManager")
    
    // Data and ML loggers
    static let dataManager = Logger(subsystem: "com.somnasync.pro", category: "DataManager")
    static let mlPredictor = Logger(subsystem: "com.somnasync.pro", category: "MLPredictor")
    
    // Watch app loggers
    static let watchApp = Logger(subsystem: "com.somnasync.pro", category: "WatchApp")
}

// MARK: - Logger Convenience Methods

extension Logger {
    func success(_ message: String, log: Logger? = nil) {
        let logger = log ?? self
        logger.info("✅ \(message)")
    }
    
    func warning(_ message: String, log: Logger? = nil) {
        let logger = log ?? self
        logger.warning("⚠️ \(message)")
    }
    
    func error(_ message: String, log: Logger? = nil) {
        let logger = log ?? self
        logger.error("❌ \(message)")
    }
    
    func debug(_ message: String, log: Logger? = nil) {
        let logger = log ?? self
        logger.debug("🔍 \(message)")
    }
} 