// LocalizationManager.swift
// Handles multi-language support and localized asset access

import Foundation

public struct LocalizationManager {
    public static func localizedString(forKey key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    // Add methods for localized images, audio, and onboarding flows as needed
}
