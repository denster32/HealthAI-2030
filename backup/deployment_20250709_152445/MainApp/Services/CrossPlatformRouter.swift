import SwiftUI

// CrossPlatformRouter.swift
class CrossPlatformRouter: ObservableObject {
    enum Route: Hashable {
        case dashboard
        case settings
        // Add other routes
    }

    @Published var currentRoute: Route = .dashboard

    func navigate(to route: Route) {
        currentRoute = route
    }
}