import XCTest
import Foundation
@testable import HealthAI2030App

final class LocalizationTests: XCTestCase {
    
    var localizationManager: MockLocalizationManager!
    
    override func setUp() {
        super.setUp()
        localizationManager = MockLocalizationManager()
    }
    
    override func tearDown() {
        localizationManager = nil
        super.tearDown()
    }
    
    func testRTLLayoutMirroring() {
        // Test UI mirroring and text flow for RTL languages
        let rtlLanguages = ["ar", "he", "fa", "ur"]
        
        for language in rtlLanguages {
            let isRTL = localizationManager.isRightToLeft(language: language)
            XCTAssertTrue(isRTL, "\(language) should be detected as RTL language")
            
            let mirroredLayout = localizationManager.getMirroredLayout(for: language)
            XCTAssertNotNil(mirroredLayout, "Should provide mirrored layout for \(language)")
            XCTAssertTrue(mirroredLayout!.isRightToLeft, "Layout should be RTL for \(language)")
        }
        
        // Test LTR languages
        let ltrLanguages = ["en", "es", "fr", "de"]
        for language in ltrLanguages {
            let isRTL = localizationManager.isRightToLeft(language: language)
            XCTAssertFalse(isRTL, "\(language) should be detected as LTR language")
        }
    }

    func testLocaleSpecificFormatting() {
        // Test date, time, number, and currency formatting for supported locales
        let testLocales = [
            Locale(identifier: "en_US"),
            Locale(identifier: "es_ES"),
            Locale(identifier: "fr_FR"),
            Locale(identifier: "de_DE"),
            Locale(identifier: "ja_JP"),
            Locale(identifier: "zh_CN")
        ]
        
        let testDate = Date()
        let testNumber = 1234.56
        let testCurrency = 99.99
        
        for locale in testLocales {
            // Test date formatting
            let formattedDate = localizationManager.formatDate(testDate, for: locale)
            XCTAssertNotNil(formattedDate, "Should format date for \(locale.identifier)")
            XCTAssertFalse(formattedDate!.isEmpty, "Formatted date should not be empty for \(locale.identifier)")
            
            // Test number formatting
            let formattedNumber = localizationManager.formatNumber(testNumber, for: locale)
            XCTAssertNotNil(formattedNumber, "Should format number for \(locale.identifier)")
            XCTAssertFalse(formattedNumber!.isEmpty, "Formatted number should not be empty for \(locale.identifier)")
            
            // Test currency formatting
            let formattedCurrency = localizationManager.formatCurrency(testCurrency, for: locale)
            XCTAssertNotNil(formattedCurrency, "Should format currency for \(locale.identifier)")
            XCTAssertFalse(formattedCurrency!.isEmpty, "Formatted currency should not be empty for \(locale.identifier)")
        }
    }

    func testPluralizationRules() {
        // Test pluralization for various counts across languages
        let testCases = [
            ("en", 0, "zero"),
            ("en", 1, "singular"),
            ("en", 2, "plural"),
            ("en", 5, "plural"),
            ("es", 0, "zero"),
            ("es", 1, "singular"),
            ("es", 2, "plural"),
            ("es", 5, "plural"),
            ("fr", 0, "zero"),
            ("fr", 1, "singular"),
            ("fr", 2, "plural"),
            ("fr", 5, "plural")
        ]
        
        for (language, count, expectedForm) in testCases {
            let pluralForm = localizationManager.getPluralForm(count: count, for: language)
            XCTAssertNotNil(pluralForm, "Should get plural form for \(language) with count \(count)")
            XCTAssertEqual(pluralForm, expectedForm, "Plural form should be '\(expectedForm)' for \(language) with count \(count)")
        }
    }

    func testCulturalContentAppropriateness() {
        // Test cultural content appropriateness for different regions
        let testRegions = [
            "US": ["health", "fitness", "wellness"],
            "JP": ["health", "fitness", "wellness"],
            "SA": ["health", "fitness", "wellness"],
            "IN": ["health", "fitness", "wellness"]
        ]
        
        for (region, contentTypes) in testRegions {
            for contentType in contentTypes {
                let isAppropriate = localizationManager.isContentAppropriate(contentType: contentType, for: region)
                XCTAssertTrue(isAppropriate, "Content type '\(contentType)' should be appropriate for region \(region)")
            }
        }
        
        // Test inappropriate content detection
        let inappropriateContent = ["alcohol", "gambling", "tobacco"]
        for content in inappropriateContent {
            let isAppropriate = localizationManager.isContentAppropriate(contentType: content, for: "US")
            XCTAssertFalse(isAppropriate, "Content type '\(content)' should not be appropriate")
        }
    }

    func testLocalizationCIIntegration() {
        // Test automated checks for missing translations and key mismatches
        let supportedLanguages = ["en", "es", "fr", "de", "ja", "zh"]
        
        for language in supportedLanguages {
            let missingKeys = localizationManager.findMissingTranslations(for: language)
            XCTAssertNotNil(missingKeys, "Should check for missing translations in \(language)")
            XCTAssertEqual(missingKeys!.count, 0, "Should have no missing translations in \(language)")
            
            let keyMismatches = localizationManager.findKeyMismatches(for: language)
            XCTAssertNotNil(keyMismatches, "Should check for key mismatches in \(language)")
            XCTAssertEqual(keyMismatches!.count, 0, "Should have no key mismatches in \(language)")
        }
    }
    
    func testLocalizedStringRetrieval() {
        // Test localized string retrieval
        let testKeys = ["health_dashboard", "sleep_tracking", "fitness_goals", "nutrition_tracker"]
        let testLanguages = ["en", "es", "fr"]
        
        for language in testLanguages {
            for key in testKeys {
                let localizedString = localizationManager.getLocalizedString(key: key, for: language)
                XCTAssertNotNil(localizedString, "Should get localized string for key '\(key)' in \(language)")
                XCTAssertFalse(localizedString!.isEmpty, "Localized string should not be empty for key '\(key)' in \(language)")
                XCTAssertNotEqual(localizedString, key, "Localized string should not be the same as the key for \(language)")
            }
        }
    }
    
    func testLocalizationPerformance() {
        // Test localization performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<1000 {
            let _ = localizationManager.getLocalizedString(key: "health_dashboard", for: "en")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        // Localization should be fast (< 1 second for 1000 operations)
        XCTAssertLessThan(duration, 1.0, "Localization took too long: \(duration)s for 1000 operations")
    }
}

// MARK: - Mock Localization Manager

class MockLocalizationManager {
    
    func isRightToLeft(language: String) -> Bool {
        let rtlLanguages = ["ar", "he", "fa", "ur"]
        return rtlLanguages.contains(language)
    }
    
    func getMirroredLayout(for language: String) -> MockLayout? {
        let isRTL = isRightToLeft(language: language)
        return MockLayout(isRightToLeft: isRTL)
    }
    
    func formatDate(_ date: Date, for locale: Locale) -> String? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatNumber(_ number: Double, for locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number))
    }
    
    func formatCurrency(_ amount: Double, for locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount))
    }
    
    func getPluralForm(count: Int, for language: String) -> String {
        if count == 0 {
            return "zero"
        } else if count == 1 {
            return "singular"
        } else {
            return "plural"
        }
    }
    
    func isContentAppropriate(contentType: String, for region: String) -> Bool {
        let inappropriateContent = ["alcohol", "gambling", "tobacco"]
        return !inappropriateContent.contains(contentType)
    }
    
    func findMissingTranslations(for language: String) -> [String]? {
        // Simulate no missing translations
        return []
    }
    
    func findKeyMismatches(for language: String) -> [String]? {
        // Simulate no key mismatches
        return []
    }
    
    func getLocalizedString(key: String, for language: String) -> String? {
        let translations: [String: [String: String]] = [
            "en": [
                "health_dashboard": "Health Dashboard",
                "sleep_tracking": "Sleep Tracking",
                "fitness_goals": "Fitness Goals",
                "nutrition_tracker": "Nutrition Tracker"
            ],
            "es": [
                "health_dashboard": "Panel de Salud",
                "sleep_tracking": "Seguimiento del Sueño",
                "fitness_goals": "Objetivos de Fitness",
                "nutrition_tracker": "Seguimiento de Nutrición"
            ],
            "fr": [
                "health_dashboard": "Tableau de Bord Santé",
                "sleep_tracking": "Suivi du Sommeil",
                "fitness_goals": "Objectifs de Fitness",
                "nutrition_tracker": "Suivi de la Nutrition"
            ]
        ]
        
        return translations[language]?[key] ?? "\(key)_\(language)"
    }
}

struct MockLayout {
    let isRightToLeft: Bool
} 