import Foundation
import FirebaseCrashlytics

/// Handles crash reporting and state preservation
public final class CrashReporter {
    private let crashlytics: Crashlytics
    private var lastKnownState: [String: Any] = [:]
    private let statePreservationQueue = DispatchQueue(label: "com.healthai.crashreporter.state", attributes: .concurrent)
    
    public static let shared = CrashReporter()
    
    private init() {
        self.crashlytics = Crashlytics.crashlytics()
        setupCrashReporting()
    }
    
    private func setupCrashReporting() {
        // Enable automatic data collection
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Set user identifier if available
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            Crashlytics.crashlytics().setUserID(userId)
        }
    }
    
    /// Records a non-fatal error with stack trace
    public func recordError(_ error: Error, 
                           withStackTrace stackTrace: [String]? = nil,
                           additionalInfo: [String: Any]? = nil) {
        var userInfo: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "error_description": error.localizedDescription
        ]
        
        if let stackTrace = stackTrace {
            userInfo["stack_trace"] = stackTrace.joined(separator: "\n")
        }
        
        if let additionalInfo = additionalInfo {
            userInfo.merge(additionalInfo) { (current, _) in current }
        }
        
        let nsError = NSError(
            domain: "com.healthai.crashreporter",
            code: 0,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: nsError)
    }
    
    /// Preserves last known good state before potential crash
    public func preserveState(_ state: [String: Any]) {
        statePreservationQueue.async(flags: .barrier) { [weak self] in
            self?.lastKnownState = state
            // Also store in Crashlytics for crash reports
            state.forEach { key, value in
                Crashlytics.crashlytics().setCustomValue(value, forKey: key)
            }
        }
    }
    
    /// Retrieves last known good state
    public func getLastKnownState() -> [String: Any] {
        statePreservationQueue.sync {
            return lastKnownState
        }
    }
    
    /// Logs a message to crash reports
    public func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
    
    /// Forces a crash (for testing only)
    public func forceCrash() {
        fatalError("Crash forced for testing purposes")
    }
}