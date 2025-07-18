import Foundation
import AppIntents

@available(iOS 18.0, *)
class SiriErrorHandler {
    
    // MARK: - Error Response Generation
    
    func generateErrorResponse(for error: Error, query: String) async -> SiriHealthResponse {
        let errorType = categorizeError(error)
        let response = await generateContextualErrorResponse(errorType: errorType, query: query)
        
        return SiriHealthResponse(
            spokenText: response.spokenText,
            displayText: response.displayText,
            confidence: 0.9, // High confidence in error handling
            insights: response.insights,
            followUpSuggestions: response.suggestions,
            timestamp: Date()
        )
    }
    
    private func categorizeError(_ error: Error) -> HealthErrorType {
        if let healthError = error as? HealthDataError {
            return .healthData(healthError)
        }
        
        if let permissionError = error as? PermissionError {
            return .permission(permissionError)
        }
        
        if let networkError = error as? NetworkError {
            return .network(networkError)
        }
        
        if let deviceError = error as? DeviceError {
            return .device(deviceError)
        }
        
        // Check error description for common patterns
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("permission") || errorDescription.contains("authorization") {
            return .permission(.healthKitNotAuthorized)
        }
        
        if errorDescription.contains("network") || errorDescription.contains("connection") {
            return .network(.noConnection)
        }
        
        if errorDescription.contains("data") || errorDescription.contains("not found") {
            return .healthData(.noDataAvailable)
        }
        
        return .unknown(error)
    }
    
    private func generateContextualErrorResponse(errorType: HealthErrorType, query: String) async -> ErrorResponse {
        switch errorType {
        case .healthData(let healthError):
            return await generateHealthDataErrorResponse(healthError, query: query)
        case .permission(let permissionError):
            return await generatePermissionErrorResponse(permissionError, query: query)
        case .network(let networkError):
            return await generateNetworkErrorResponse(networkError, query: query)
        case .device(let deviceError):
            return await generateDeviceErrorResponse(deviceError, query: query)
        case .unknown(let error):
            return await generateGenericErrorResponse(error, query: query)
        }
    }
    
    // MARK: - Health Data Error Responses
    
    private func generateHealthDataErrorResponse(_ error: HealthDataError, query: String) async -> ErrorResponse {
        switch error {
        case .noDataAvailable:
            return await generateNoDataResponse(query: query)
        case .insufficientData:
            return await generateInsufficientDataResponse(query: query)
        case .invalidDataType:
            return await generateInvalidDataTypeResponse(query: query)
        case .dataCorrupted:
            return await generateDataCorruptedResponse(query: query)
        case .syncError:
            return await generateSyncErrorResponse(query: query)
        }
    }
    
    private func generateNoDataResponse(query: String) async -> ErrorResponse {
        let dataType = extractDataTypeFromQuery(query)
        
        let spokenText: String
        let suggestions: [String]
        
        switch dataType {
        case "heart rate":
            spokenText = "I couldn't find recent heart rate data. This usually means your Apple Watch isn't connected or you haven't worn it recently."
            suggestions = [
                "Check Apple Watch connection",
                "Wear your Apple Watch",
                "Check Health app permissions",
                "Try again in a few minutes"
            ]
        case "sleep":
            spokenText = "I don't see any sleep data for the requested time period. Make sure sleep tracking is enabled on your iPhone or Apple Watch."
            suggestions = [
                "Enable sleep tracking",
                "Set up Sleep Schedule",
                "Check Health app settings",
                "Use Sleep Focus mode"
            ]
        case "steps":
            spokenText = "I couldn't find step data. Make sure your iPhone is with you or your Apple Watch is connected."
            suggestions = [
                "Carry your iPhone",
                "Check Apple Watch connection",
                "Enable Motion & Fitness",
                "Check Health app permissions"
            ]
        case "water":
            spokenText = "I don't see any water intake data. You'll need to log your water consumption manually or use a compatible app."
            suggestions = [
                "Log water intake",
                "Download water tracking app",
                "Set hydration reminders",
                "Enable Health app integration"
            ]
        default:
            spokenText = "I couldn't find the health data you requested. This might be because the data isn't available or hasn't been recorded yet."
            suggestions = [
                "Check Health app",
                "Verify data sources",
                "Check device connections",
                "Try a different time period"
            ]
        }
        
        let displayText = "📊 No Data Available\n\n" + spokenText
        
        let insights = [
            HealthInsight(
                type: .general,
                message: "Regular data collection helps provide better health insights.",
                confidence: 0.9,
                actionable: true
            )
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: insights,
            suggestions: suggestions
        )
    }
    
    private func generateInsufficientDataResponse(query: String) async -> ErrorResponse {
        let spokenText = "I found some data, but there isn't enough to provide meaningful insights. Try collecting data for a few more days."
        let displayText = "📈 Insufficient Data\n\n" + spokenText
        
        let suggestions = [
            "Continue tracking for more days",
            "Check data sources",
            "Enable automatic tracking",
            "Ask about available data"
        ]
        
        let insights = [
            HealthInsight(
                type: .general,
                message: "More data points lead to better health trend analysis.",
                confidence: 0.85,
                actionable: true
            )
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: insights,
            suggestions: suggestions
        )
    }
    
    private func generateInvalidDataTypeResponse(query: String) async -> ErrorResponse {
        let spokenText = "I'm not sure what type of health data you're asking about. Try asking about heart rate, sleep, steps, or water intake."
        let displayText = "❓ Unclear Request\n\n" + spokenText
        
        let suggestions = [
            "Ask about heart rate",
            "Ask about sleep data",
            "Ask about step count",
            "Ask about water intake",
            "See available data types"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateDataCorruptedResponse(query: String) async -> ErrorResponse {
        let spokenText = "There seems to be an issue with your health data. Try restarting the Health app or syncing your devices."
        let displayText = "⚠️ Data Issue\n\n" + spokenText
        
        let suggestions = [
            "Restart Health app",
            "Sync Apple Watch",
            "Check device storage",
            "Contact support if issue persists"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateSyncErrorResponse(query: String) async -> ErrorResponse {
        let spokenText = "Your devices aren't syncing properly. Make sure your iPhone and Apple Watch are connected and try again."
        let displayText = "🔄 Sync Issue\n\n" + spokenText
        
        let suggestions = [
            "Check Bluetooth connection",
            "Restart both devices",
            "Check internet connection",
            "Force sync in Health app"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    // MARK: - Permission Error Responses
    
    private func generatePermissionErrorResponse(_ error: PermissionError, query: String) async -> ErrorResponse {
        switch error {
        case .healthKitNotAuthorized:
            return await generateHealthKitPermissionResponse(query: query)
        case .siriNotAuthorized:
            return await generateSiriPermissionResponse(query: query)
        case .locationNotAuthorized:
            return await generateLocationPermissionResponse(query: query)
        case .motionNotAuthorized:
            return await generateMotionPermissionResponse(query: query)
        }
    }
    
    private func generateHealthKitPermissionResponse(query: String) async -> ErrorResponse {
        let spokenText = "I don't have permission to access your health data. You can grant permission in the Health app under Sharing."
        let displayText = "🔒 Permission Required\n\n" + spokenText
        
        let suggestions = [
            "Open Health app",
            "Go to Sharing settings",
            "Grant HealthAI permissions",
            "Try your request again"
        ]
        
        let insights = [
            HealthInsight(
                type: .general,
                message: "Granting health permissions allows for personalized insights.",
                confidence: 0.95,
                actionable: true
            )
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: insights,
            suggestions: suggestions
        )
    }
    
    private func generateSiriPermissionResponse(query: String) async -> ErrorResponse {
        let spokenText = "I need permission to work with Siri. You can enable this in Settings under Siri & Search."
        let displayText = "🎤 Siri Permission Required\n\n" + spokenText
        
        let suggestions = [
            "Open Settings",
            "Go to Siri & Search",
            "Enable HealthAI",
            "Try voice command again"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateLocationPermissionResponse(query: String) async -> ErrorResponse {
        let spokenText = "I need location access for context-aware health insights. You can enable this in Settings under Privacy & Security."
        let displayText = "📍 Location Permission Required\n\n" + spokenText
        
        let suggestions = [
            "Open Settings",
            "Go to Privacy & Security",
            "Enable location for HealthAI",
            "Try your request again"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateMotionPermissionResponse(query: String) async -> ErrorResponse {
        let spokenText = "I need access to motion and fitness data to track your activity. You can enable this in Settings under Privacy & Security."
        let displayText = "🏃 Motion Permission Required\n\n" + spokenText
        
        let suggestions = [
            "Open Settings",
            "Go to Privacy & Security",
            "Enable Motion & Fitness",
            "Try asking about steps again"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    // MARK: - Network Error Responses
    
    private func generateNetworkErrorResponse(_ error: NetworkError, query: String) async -> ErrorResponse {
        switch error {
        case .noConnection:
            return await generateNoConnectionResponse(query: query)
        case .timeout:
            return await generateTimeoutResponse(query: query)
        case .serverError:
            return await generateServerErrorResponse(query: query)
        }
    }
    
    private func generateNoConnectionResponse(query: String) async -> ErrorResponse {
        let spokenText = "I can't connect to the internet right now. I can still help with locally stored health data."
        let displayText = "🌐 No Internet Connection\n\n" + spokenText
        
        let suggestions = [
            "Check WiFi connection",
            "Try cellular data",
            "Ask about local data",
            "Try again when connected"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateTimeoutResponse(query: String) async -> ErrorResponse {
        let spokenText = "The request is taking longer than expected. This might be due to a slow connection or server issues."
        let displayText = "⏱️ Request Timeout\n\n" + spokenText
        
        let suggestions = [
            "Try again",
            "Check internet speed",
            "Try a simpler request",
            "Wait a moment and retry"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateServerErrorResponse(query: String) async -> ErrorResponse {
        let spokenText = "There's a temporary issue with our health services. Local health data is still available."
        let displayText = "🛠️ Service Temporarily Unavailable\n\n" + spokenText
        
        let suggestions = [
            "Try again later",
            "Ask about local data",
            "Check app status",
            "Contact support if persistent"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    // MARK: - Device Error Responses
    
    private func generateDeviceErrorResponse(_ error: DeviceError, query: String) async -> ErrorResponse {
        switch error {
        case .watchNotConnected:
            return await generateWatchNotConnectedResponse(query: query)
        case .lowBattery:
            return await generateLowBatteryResponse(query: query)
        case .deviceNotSupported:
            return await generateDeviceNotSupportedResponse(query: query)
        }
    }
    
    private func generateWatchNotConnectedResponse(query: String) async -> ErrorResponse {
        let spokenText = "Your Apple Watch isn't connected. Make sure it's nearby and paired with your iPhone."
        let displayText = "⌚ Apple Watch Disconnected\n\n" + spokenText
        
        let suggestions = [
            "Check Watch connection",
            "Move closer to iPhone",
            "Check Bluetooth",
            "Restart Watch app"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateLowBatteryResponse(query: String) async -> ErrorResponse {
        let spokenText = "Your device battery is low, which might affect health data collection. Consider charging your device."
        let displayText = "🔋 Low Battery Warning\n\n" + spokenText
        
        let suggestions = [
            "Charge your device",
            "Enable Low Power Mode",
            "Continue with limited features",
            "Check battery usage"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    private func generateDeviceNotSupportedResponse(query: String) async -> ErrorResponse {
        let spokenText = "This feature isn't available on your current device. Some health features require specific hardware."
        let displayText = "📱 Feature Not Supported\n\n" + spokenText
        
        let suggestions = [
            "Check device compatibility",
            "Update iOS",
            "Try alternative features",
            "Contact support"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    // MARK: - Generic Error Response
    
    private func generateGenericErrorResponse(_ error: Error, query: String) async -> ErrorResponse {
        let spokenText = "Something unexpected happened. Let me try to help you in a different way."
        let displayText = "❗ Unexpected Error\n\n" + spokenText + "\n\nError: \(error.localizedDescription)"
        
        let suggestions = [
            "Try again",
            "Rephrase your question",
            "Ask something else",
            "Contact support"
        ]
        
        return ErrorResponse(
            spokenText: spokenText,
            displayText: displayText,
            insights: [],
            suggestions: suggestions
        )
    }
    
    // MARK: - Helper Methods
    
    private func extractDataTypeFromQuery(_ query: String) -> String {
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("heart rate") || lowercaseQuery.contains("heartrate") {
            return "heart rate"
        }
        if lowercaseQuery.contains("sleep") {
            return "sleep"
        }
        if lowercaseQuery.contains("steps") {
            return "steps"
        }
        if lowercaseQuery.contains("water") {
            return "water"
        }
        if lowercaseQuery.contains("weight") {
            return "weight"
        }
        if lowercaseQuery.contains("workout") || lowercaseQuery.contains("exercise") {
            return "workout"
        }
        
        return "general"
    }
    
    // MARK: - Recovery Suggestions
    
    func generateRecoverySuggestions(for errorType: HealthErrorType, context: String) -> [RecoveryAction] {
        switch errorType {
        case .healthData(.noDataAvailable):
            return [
                RecoveryAction(title: "Enable Data Sources", action: "enableDataSources"),
                RecoveryAction(title: "Check Permissions", action: "checkPermissions"),
                RecoveryAction(title: "Sync Devices", action: "syncDevices")
            ]
        case .permission(.healthKitNotAuthorized):
            return [
                RecoveryAction(title: "Grant Permissions", action: "grantPermissions"),
                RecoveryAction(title: "Open Health App", action: "openHealthApp")
            ]
        case .network(.noConnection):
            return [
                RecoveryAction(title: "Check WiFi", action: "checkWiFi"),
                RecoveryAction(title: "Use Cellular", action: "useCellular"),
                RecoveryAction(title: "Work Offline", action: "workOffline")
            ]
        case .device(.watchNotConnected):
            return [
                RecoveryAction(title: "Connect Watch", action: "connectWatch"),
                RecoveryAction(title: "Check Bluetooth", action: "checkBluetooth")
            ]
        default:
            return [
                RecoveryAction(title: "Try Again", action: "retry"),
                RecoveryAction(title: "Contact Support", action: "contactSupport")
            ]
        }
    }
}

// MARK: - Error Types

enum HealthErrorType {
    case healthData(HealthDataError)
    case permission(PermissionError)
    case network(NetworkError)
    case device(DeviceError)
    case unknown(Error)
}

enum HealthDataError: Error {
    case noDataAvailable
    case insufficientData
    case invalidDataType
    case dataCorrupted
    case syncError
}

enum PermissionError: Error {
    case healthKitNotAuthorized
    case siriNotAuthorized
    case locationNotAuthorized
    case motionNotAuthorized
}

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError
}

enum DeviceError: Error {
    case watchNotConnected
    case lowBattery
    case deviceNotSupported
}

// MARK: - Response Structures

struct ErrorResponse {
    let spokenText: String
    let displayText: String
    let insights: [HealthInsight]
    let suggestions: [String]
}

struct RecoveryAction {
    let title: String
    let action: String
}