import Foundation
import UIKit

class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    /// Handles deep linking within the app or to external services.
    static func navigate(to destination: DeepLinkDestination) {
        print("DeepLinkManager: Navigating to \(destination).")
        // Placeholder for actual deep linking logic
        switch destination {
        case .ecgDetailView:
            // Simulate navigation to ECG detail view
            print("Navigating to ECG Detail View.")
        case .sleepSettings:
            // Simulate navigation to Sleep Settings
            print("Navigating to Sleep Settings.")
        case .externalURL(let url):
            if let url = URL(string: url) {
                // Simulate opening external URL
                print("Opening external URL: \(url.absoluteString)")
                // UIApplication.shared.open(url) // For actual iOS app
            }
        case .callEMS:
            // Simulate calling EMS
            print("Initiating call to EMS.")
            // UIApplication.shared.open(URL(string: "tel://911")!) // For actual iOS app
        }
    }
    
    // MARK: - Handle Deep Link
    func handle(deepLink: String) {
        guard let url = URL(string: deepLink) else { return }
        if deepLink.hasPrefix("tel://") {
            // Call EMS or phone number
            UIApplication.shared.open(url)
        } else if deepLink.hasPrefix("app://") {
            // Handle internal app navigation
            navigateToAppSection(url: url)
        } else {
            // Handle other types of links (web, etc.)
            UIApplication.shared.open(url)
        }
    }
    
    private func navigateToAppSection(url: URL) {
        // Implement navigation logic based on URL path
        // For example, use NotificationCenter or a coordinator pattern
        NotificationCenter.default.post(name: .didReceiveDeepLink, object: url)
    }
}

enum DeepLinkDestination {
    case ecgDetailView
    case sleepSettings
    case externalURL(String)
    case callEMS
    // Add more deep link destinations as needed
}

extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}