// PremiumAssets.swift
// Centralized access to high-resolution images, 3D models, and AR/VR assets for HealthAI 2030

import SwiftUI
import RealityKit

public struct PremiumAssets {
    // Example: High-res images
    public static let onboardingBackground = Image("onboarding_background")
    public static let dashboardHero = Image("dashboard_hero")
    public static let sleepHero = Image("sleep_hero")
    public static let analyticsHero = Image("analytics_hero")
    public static let environmentHero = Image("environment_hero")
    public static let avatarGallery = Image("avatar_gallery")
    
    // Example: 3D/AR assets
    public static let heartModel = try? Entity.load(named: "HeartModel.usdz")
    public static let brainModel = try? Entity.load(named: "BrainModel.usdz")
    public static let lungModel = try? Entity.load(named: "LungModel.usdz")
    public static let sleepPodModel = try? Entity.load(named: "SleepPod.usdz")
    public static let environmentModel = try? Entity.load(named: "EnvironmentModel.usdz")
    
    // Add more assets as they are created and imported
}
