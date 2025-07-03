import Foundation
import UIKit

class DeepLinkManager {
    static let shared = DeepLinkManager()
    
    /// Handles deep linking within the app or to external services.
    static func navigate(to destination: DeepLinkDestination) {
        switch destination {
        case .ecgDetailView:
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                let ecgVC = ECGDetailViewController()
                rootVC.present(ecgVC, animated: true)
            }
        case .sleepSettings:
            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                let settingsVC = SleepSettingsViewController()
                rootVC.present(settingsVC, animated: true)
            }
        case .externalURL(let url):
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        case .callEMS:
            if let url = URL(string: "tel://911") {
                UIApplication.shared.open(url)
            }
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