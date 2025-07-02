import SwiftUI

/// Custom hosting controller to manage status bar appearance in iOS 13+
class AppHostingController<Content: View>: UIHostingController<Content> {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

