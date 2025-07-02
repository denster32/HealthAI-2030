import SwiftUI

/// Custom hosting controller that sets the preferred status-bar style without using the deprecated global API.
/// This becomes the single place where the app decides how the status bar should look on iPhone.
@available(iOS 13.0, *)
class AppHostingController<Content: View>: UIHostingController<Content> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Match your design system—lightContent looks good on dark navigation bars.
        return .lightContent
    }
} 