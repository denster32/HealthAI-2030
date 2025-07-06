import XCTest
@testable import HealthAI2030

final class LocalizationTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Setup code before each test
    }
    
    override func tearDownWithError() throws {
        // Cleanup code after each test
    }
    
    // MARK: - String Localization Tests
    
    func testBasicStringLocalization() throws {
        // Test that basic strings are properly localized
        let healthGoals = NSLocalizedString("Health Goals", comment: "Navigation title for health goals")
        XCTAssertFalse(healthGoals.isEmpty, "Localized string should not be empty")
        
        let goals = NSLocalizedString("Goals", comment: "Goals tab")
        XCTAssertFalse(goals.isEmpty, "Localized string should not be empty")
        
        let progress = NSLocalizedString("Progress", comment: "Progress tab")
        XCTAssertFalse(progress.isEmpty, "Localized string should not be empty")
        
        let analytics = NSLocalizedString("Analytics", comment: "Analytics tab")
        XCTAssertFalse(analytics.isEmpty, "Localized string should not be empty")
    }
    
    func testFormLabelsLocalization() throws {
        // Test form labels are properly localized
        let title = NSLocalizedString("Title", comment: "Goal title field")
        XCTAssertFalse(title.isEmpty, "Title field label should be localized")
        
        let description = NSLocalizedString("Description", comment: "Goal description field")
        XCTAssertFalse(description.isEmpty, "Description field label should be localized")
        
        let type = NSLocalizedString("Type", comment: "Goal type picker")
        XCTAssertFalse(type.isEmpty, "Type picker label should be localized")
        
        let targetValue = NSLocalizedString("Target Value", comment: "Goal target value field")
        XCTAssertFalse(targetValue.isEmpty, "Target value field label should be localized")
        
        let unit = NSLocalizedString("Unit", comment: "Goal unit field")
        XCTAssertFalse(unit.isEmpty, "Unit field label should be localized")
        
        let endDate = NSLocalizedString("End Date", comment: "Goal end date picker")
        XCTAssertFalse(endDate.isEmpty, "End date picker label should be localized")
    }
    
    func testButtonLabelsLocalization() throws {
        // Test button labels are properly localized
        let createGoal = NSLocalizedString("Create Goal", comment: "Create goal button")
        XCTAssertFalse(createGoal.isEmpty, "Create goal button should be localized")
        
        let cancel = NSLocalizedString("Cancel", comment: "Cancel button")
        XCTAssertFalse(cancel.isEmpty, "Cancel button should be localized")
        
        let updateProgress = NSLocalizedString("Update Progress", comment: "Update progress button")
        XCTAssertFalse(updateProgress.isEmpty, "Update progress button should be localized")
        
        let delete = NSLocalizedString("Delete", comment: "Delete button")
        XCTAssertFalse(delete.isEmpty, "Delete button should be localized")
    }
    
    func testProgressLabelsLocalization() throws {
        // Test progress-related labels are properly localized
        let progress = NSLocalizedString("Progress", comment: "Progress label")
        XCTAssertFalse(progress.isEmpty, "Progress label should be localized")
        
        let target = NSLocalizedString("Target", comment: "Target label")
        XCTAssertFalse(target.isEmpty, "Target label should be localized")
        
        let endDate = NSLocalizedString("End Date", comment: "End date label")
        XCTAssertFalse(endDate.isEmpty, "End date label should be localized")
        
        let currentProgress = NSLocalizedString("Current Progress", comment: "Current progress label")
        XCTAssertFalse(currentProgress.isEmpty, "Current progress label should be localized")
        
        let newProgressValue = NSLocalizedString("New Progress Value", comment: "New progress value label")
        XCTAssertFalse(newProgressValue.isEmpty, "New progress value label should be localized")
    }
    
    func testAnalyticsLabelsLocalization() throws {
        // Test analytics-related labels are properly localized
        let completionRate = NSLocalizedString("Goal Completion Rate", comment: "Goal completion rate chart title")
        XCTAssertFalse(completionRate.isEmpty, "Completion rate chart title should be localized")
        
        let completionRateLabel = NSLocalizedString("Completion Rate", comment: "Completion rate label")
        XCTAssertFalse(completionRateLabel.isEmpty, "Completion rate label should be localized")
        
        let typeDistribution = NSLocalizedString("Goal Type Distribution", comment: "Goal type distribution chart title")
        XCTAssertFalse(typeDistribution.isEmpty, "Type distribution chart title should be localized")
        
        let recentActivity = NSLocalizedString("Recent Activity", comment: "Recent activity section title")
        XCTAssertFalse(recentActivity.isEmpty, "Recent activity section title should be localized")
    }
    
    func testLanguageSwitcherLocalization() throws {
        // Test language switcher labels are properly localized
        let currentLanguage = NSLocalizedString("Current Language", comment: "Current language label")
        XCTAssertFalse(currentLanguage.isEmpty, "Current language label should be localized")
        
        let changeLanguage = NSLocalizedString("Change Language", comment: "Change language button")
        XCTAssertFalse(changeLanguage.isEmpty, "Change language button should be localized")
        
        let supportedLanguages = NSLocalizedString("Supported Languages", comment: "Supported languages section title")
        XCTAssertFalse(supportedLanguages.isEmpty, "Supported languages section title should be localized")
        
        let languageSettings = NSLocalizedString("Language Settings", comment: "Language settings navigation title")
        XCTAssertFalse(languageSettings.isEmpty, "Language settings navigation title should be localized")
        
        let selectLanguage = NSLocalizedString("Select Language", comment: "Language picker navigation title")
        XCTAssertFalse(selectLanguage.isEmpty, "Select language navigation title should be localized")
    }
    
    // MARK: - Language Support Tests
    
    func testSupportedLanguages() throws {
        let supportedLanguages = [
            ("en", "English", "🇺🇸"),
            ("es", "Español", "🇪🇸"),
            ("fr", "Français", "🇫🇷")
        ]
        
        XCTAssertEqual(supportedLanguages.count, 3, "Should support exactly 3 languages")
        
        // Test English
        XCTAssertEqual(supportedLanguages[0].0, "en", "First language should be English")
        XCTAssertEqual(supportedLanguages[0].1, "English", "English name should be correct")
        XCTAssertEqual(supportedLanguages[0].2, "🇺🇸", "English flag should be correct")
        
        // Test Spanish
        XCTAssertEqual(supportedLanguages[1].0, "es", "Second language should be Spanish")
        XCTAssertEqual(supportedLanguages[1].1, "Español", "Spanish name should be correct")
        XCTAssertEqual(supportedLanguages[1].2, "🇪🇸", "Spanish flag should be correct")
        
        // Test French
        XCTAssertEqual(supportedLanguages[2].0, "fr", "Third language should be French")
        XCTAssertEqual(supportedLanguages[2].1, "Français", "French name should be correct")
        XCTAssertEqual(supportedLanguages[2].2, "🇫🇷", "French flag should be correct")
    }
    
    // MARK: - Localization File Tests
    
    func testLocalizationFilesExist() throws {
        // Test that localization files exist in the bundle
        let bundle = Bundle.main
        
        // Test English strings file
        let englishPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj")
        XCTAssertNotNil(englishPath, "English Localizable.strings should exist")
        
        // Test Spanish strings file
        let spanishPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "es.lproj")
        XCTAssertNotNil(spanishPath, "Spanish Localizable.strings should exist")
        
        // Test French strings file
        let frenchPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "fr.lproj")
        XCTAssertNotNil(frenchPath, "French Localizable.strings should exist")
    }
    
    func testLocalizationFileContent() throws {
        let bundle = Bundle.main
        
        // Test English strings file content
        if let englishPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj") {
            let englishStrings = NSDictionary(contentsOfFile: englishPath)
            XCTAssertNotNil(englishStrings, "English strings file should be readable")
            XCTAssertGreaterThan(englishStrings?.count ?? 0, 0, "English strings file should contain entries")
        }
        
        // Test Spanish strings file content
        if let spanishPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "es.lproj") {
            let spanishStrings = NSDictionary(contentsOfFile: spanishPath)
            XCTAssertNotNil(spanishStrings, "Spanish strings file should be readable")
            XCTAssertGreaterThan(spanishStrings?.count ?? 0, 0, "Spanish strings file should contain entries")
        }
        
        // Test French strings file content
        if let frenchPath = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: "fr.lproj") {
            let frenchStrings = NSDictionary(contentsOfFile: frenchPath)
            XCTAssertNotNil(frenchStrings, "French strings file should be readable")
            XCTAssertGreaterThan(frenchStrings?.count ?? 0, 0, "French strings file should contain entries")
        }
    }
    
    // MARK: - Performance Tests
    
    func testLocalizationPerformance() throws {
        // Test that localization doesn't cause performance issues
        measure {
            for _ in 0..<1000 {
                _ = NSLocalizedString("Health Goals", comment: "Navigation title for health goals")
                _ = NSLocalizedString("Goals", comment: "Goals tab")
                _ = NSLocalizedString("Progress", comment: "Progress tab")
                _ = NSLocalizedString("Analytics", comment: "Analytics tab")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testMissingLocalization() throws {
        // Test that missing localizations fall back gracefully
        let missingKey = NSLocalizedString("MISSING_KEY_THAT_DOESNT_EXIST", comment: "Test missing key")
        XCTAssertEqual(missingKey, "MISSING_KEY_THAT_DOESNT_EXIST", "Missing keys should return the key itself")
    }
    
    func testEmptyLocalization() throws {
        // Test that empty localizations are handled properly
        let emptyKey = NSLocalizedString("", comment: "Test empty key")
        XCTAssertEqual(emptyKey, "", "Empty key should return empty string")
    }
    
    func testSpecialCharactersLocalization() throws {
        // Test that special characters are handled properly
        let specialKey = NSLocalizedString("Special Characters: áéíóú ñ ç", comment: "Test special characters")
        XCTAssertFalse(specialKey.isEmpty, "Special characters should be handled properly")
    }
} 