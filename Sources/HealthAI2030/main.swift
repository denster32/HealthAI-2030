import Foundation
import HealthAI2030UI
import HealthAI2030Core

#if canImport(UIKit)
import UIKit
import SwiftUI

@main
struct HealthAI2030App: App {
    var body: some Scene {
        WindowGroup {
            HealthDashboardView()
        }
    }
}

#elseif canImport(AppKit)
import AppKit
import SwiftUI
import HealthAI2030UI

@main
struct HealthAI2030MacApp: App {
    var body: some Scene {
        WindowGroup {
            HealthDashboardView()
        }
    }
}

#else
// Command line version for other platforms
@main
struct HealthAI2030CLI {
    static func main() {
        print("HealthAI 2030 - Advanced Health Analytics Platform")
        print("Version: \(HealthAI2030().version())")
        print("Starting health monitoring services...")
        
        // Initialize core services
        let healthAI = HealthAI2030()
        
        // Keep the process running
        RunLoop.main.run()
    }
}
#endif