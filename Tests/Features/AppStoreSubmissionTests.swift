import XCTest
import SwiftUI
@testable import HealthAI2030

/// Comprehensive unit tests for the App Store Submission Manager
/// Tests all functionality including compliance checks, metadata validation, and submission workflow
final class AppStoreSubmissionTests: XCTestCase {
    
    var submissionManager: AppStoreSubmissionManager!
    
    override func setUpWithError() throws {
        super.setUp()
        submissionManager = AppStoreSubmissionManager.shared
        submissionManager.complianceChecks.removeAll()
        submissionManager.submissionStatus = .notStarted
        submissionManager.metadataStatus = .incomplete
        submissionManager.screenshotStatus = .incomplete
        submissionManager.buildStatus = .notBuilt
    }
    
    override func tearDownWithError() throws {
        submissionManager = nil
        super.tearDown()
    }
    
    // MARK: - Manager Tests
    
    func testSubmissionManagerInitialization() {
        XCTAssertNotNil(submissionManager)
        XCTAssertEqual(submissionManager.submissionStatus, .notStarted)
        XCTAssertEqual(submissionManager.complianceChecks.count, 0)
        XCTAssertEqual(submissionManager.metadataStatus, .incomplete)
        XCTAssertEqual(submissionManager.screenshotStatus, .incomplete)
        XCTAssertEqual(submissionManager.buildStatus, .notBuilt)
    }
    
    func testSubmissionManagerSingleton() {
        let instance1 = AppStoreSubmissionManager.shared
        let instance2 = AppStoreSubmissionManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Status Tests
    
    func testSubmissionStatusColors() {
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.notStarted.color, "gray")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.inProgress.color, "orange")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.readyForReview.color, "blue")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.submitted.color, "purple")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.approved.color, "green")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.rejected.color, "red")
        XCTAssertEqual(AppStoreSubmissionManager.SubmissionStatus.inReview.color, "yellow")
    }
    
    func testMetadataStatusColors() {
        XCTAssertEqual(AppStoreSubmissionManager.MetadataStatus.incomplete.color, "red")
        XCTAssertEqual(AppStoreSubmissionManager.MetadataStatus.complete.color, "orange")
        XCTAssertEqual(AppStoreSubmissionManager.MetadataStatus.validated.color, "green")
    }
    
    func testScreenshotStatusColors() {
        XCTAssertEqual(AppStoreSubmissionManager.ScreenshotStatus.incomplete.color, "red")
        XCTAssertEqual(AppStoreSubmissionManager.ScreenshotStatus.complete.color, "orange")
        XCTAssertEqual(AppStoreSubmissionManager.ScreenshotStatus.optimized.color, "green")
    }
    
    func testBuildStatusColors() {
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.notBuilt.color, "gray")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.building.color, "orange")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.built.color, "blue")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.uploaded.color, "purple")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.processing.color, "yellow")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.ready.color, "green")
        XCTAssertEqual(AppStoreSubmissionManager.BuildStatus.failed.color, "red")
    }
    
    // MARK: - Compliance Check Tests
    
    func testComplianceCheckCreation() {
        let check = AppStoreSubmissionManager.ComplianceCheck(
            category: .privacy,
            requirement: "Privacy Policy",
            status: .passed,
            description: "Privacy policy is implemented",
            recommendation: "Keep privacy policy updated",
            isRequired: true
        )
        
        XCTAssertEqual(check.category, .privacy)
        XCTAssertEqual(check.requirement, "Privacy Policy")
        XCTAssertEqual(check.status, .passed)
        XCTAssertEqual(check.description, "Privacy policy is implemented")
        XCTAssertEqual(check.recommendation, "Keep privacy policy updated")
        XCTAssertTrue(check.isRequired)
        XCTAssertNotNil(check.timestamp)
    }
    
    func testComplianceCategoryAllCases() {
        let categories = AppStoreSubmissionManager.ComplianceCategory.allCases
        XCTAssertEqual(categories.count, 7)
        
        let expectedCategories = [
            "Privacy", "Security", "Accessibility", "Performance",
            "Content", "Legal", "Technical"
        ]
        
        for expectedCategory in expectedCategories {
            XCTAssertTrue(categories.contains { $0.rawValue == expectedCategory })
        }
    }
    
    func testCheckStatusAllCases() {
        let statuses = AppStoreSubmissionManager.CheckStatus.allCases
        XCTAssertEqual(statuses.count, 5)
        
        let expectedStatuses = [
            "Pending", "Passed", "Failed", "Warning", "Not Applicable"
        ]
        
        for expectedStatus in expectedStatuses {
            XCTAssertTrue(statuses.contains { $0.rawValue == expectedStatus })
        }
    }
    
    func testCheckStatusColors() {
        XCTAssertEqual(AppStoreSubmissionManager.CheckStatus.pending.color, "gray")
        XCTAssertEqual(AppStoreSubmissionManager.CheckStatus.passed.color, "green")
        XCTAssertEqual(AppStoreSubmissionManager.CheckStatus.failed.color, "red")
        XCTAssertEqual(AppStoreSubmissionManager.CheckStatus.warning.color, "orange")
        XCTAssertEqual(AppStoreSubmissionManager.CheckStatus.notApplicable.color, "blue")
    }
    
    // MARK: - App Metadata Tests
    
    func testAppMetadataCreation() {
        let metadata = AppStoreSubmissionManager.AppMetadata(
            appName: "Test App",
            subtitle: "Test Subtitle",
            description: "Test description",
            keywords: ["test", "app"],
            category: .healthAndFitness,
            contentRating: .fourPlus,
            privacyPolicyURL: "https://test.com/privacy",
            supportURL: "https://test.com/support",
            marketingURL: "https://test.com",
            version: "1.0.0",
            buildNumber: "1",
            releaseNotes: "Test release notes"
        )
        
        XCTAssertEqual(metadata.appName, "Test App")
        XCTAssertEqual(metadata.subtitle, "Test Subtitle")
        XCTAssertEqual(metadata.description, "Test description")
        XCTAssertEqual(metadata.keywords, ["test", "app"])
        XCTAssertEqual(metadata.category, .healthAndFitness)
        XCTAssertEqual(metadata.contentRating, .fourPlus)
        XCTAssertEqual(metadata.privacyPolicyURL, "https://test.com/privacy")
        XCTAssertEqual(metadata.supportURL, "https://test.com/support")
        XCTAssertEqual(metadata.marketingURL, "https://test.com")
        XCTAssertEqual(metadata.version, "1.0.0")
        XCTAssertEqual(metadata.buildNumber, "1")
        XCTAssertEqual(metadata.releaseNotes, "Test release notes")
    }
    
    func testAppCategoryAppStoreCategory() {
        XCTAssertEqual(AppStoreSubmissionManager.AppCategory.healthAndFitness.appStoreCategory, "healthcare-fitness")
        XCTAssertEqual(AppStoreSubmissionManager.AppCategory.medical.appStoreCategory, "medical")
        XCTAssertEqual(AppStoreSubmissionManager.AppCategory.lifestyle.appStoreCategory, "lifestyle")
        XCTAssertEqual(AppStoreSubmissionManager.AppCategory.productivity.appStoreCategory, "productivity")
        XCTAssertEqual(AppStoreSubmissionManager.AppCategory.utilities.appStoreCategory, "utilities")
    }
    
    func testContentRatingDescription() {
        XCTAssertEqual(AppStoreSubmissionManager.ContentRating.fourPlus.description, "No objectionable content")
        XCTAssertEqual(AppStoreSubmissionManager.ContentRating.ninePlus.description, "Infrequent/Mild Cartoon or Fantasy Violence")
        XCTAssertEqual(AppStoreSubmissionManager.ContentRating.twelvePlus.description, "Infrequent/Mild Sexual Content and Nudity")
        XCTAssertEqual(AppStoreSubmissionManager.ContentRating.seventeenPlus.description, "Frequent/Intense Sexual Content and Nudity")
    }
    
    // MARK: - Screenshot Requirement Tests
    
    func testScreenshotRequirementCreation() {
        let requirement = AppStoreSubmissionManager.ScreenshotRequirement(
            device: .iPhone65,
            orientation: .portrait,
            requiredCount: 3,
            currentCount: 2
        )
        
        XCTAssertEqual(requirement.device, .iPhone65)
        XCTAssertEqual(requirement.orientation, .portrait)
        XCTAssertEqual(requirement.requiredCount, 3)
        XCTAssertEqual(requirement.currentCount, 2)
        XCTAssertEqual(requirement.status, .incomplete)
    }
    
    func testScreenshotRequirementComplete() {
        let requirement = AppStoreSubmissionManager.ScreenshotRequirement(
            device: .iPhone65,
            orientation: .portrait,
            requiredCount: 3,
            currentCount: 3
        )
        
        XCTAssertEqual(requirement.status, .complete)
    }
    
    func testDeviceTypeAllCases() {
        let devices = AppStoreSubmissionManager.DeviceType.allCases
        XCTAssertEqual(devices.count, 11)
        
        let expectedDevices = [
            "iPhone 6.5\" Display", "iPhone 5.8\" Display", "iPhone 5.5\" Display",
            "iPhone 4.7\" Display", "iPhone 4.0\" Display", "iPad Pro 12.9\" Display",
            "iPad Pro 11\" Display", "iPad 10.5\" Display", "iPad 9.7\" Display",
            "Apple Watch", "Apple TV"
        ]
        
        for expectedDevice in expectedDevices {
            XCTAssertTrue(devices.contains { $0.rawValue == expectedDevice })
        }
    }
    
    func testOrientationAllCases() {
        let orientations = AppStoreSubmissionManager.Orientation.allCases
        XCTAssertEqual(orientations.count, 2)
        XCTAssertTrue(orientations.contains(.portrait))
        XCTAssertTrue(orientations.contains(.landscape))
    }
    
    // MARK: - Compliance Check Tests
    
    func testPerformComplianceChecks() async {
        await submissionManager.performComplianceChecks()
        
        XCTAssertGreaterThan(submissionManager.complianceChecks.count, 0)
        
        // Check that all categories are represented
        let categories = Set(submissionManager.complianceChecks.map { $0.category })
        XCTAssertEqual(categories.count, 7) // All compliance categories
        
        // Check that we have some passed checks
        let passedChecks = submissionManager.complianceChecks.filter { $0.status == .passed }
        XCTAssertGreaterThan(passedChecks.count, 0)
    }
    
    func testPrivacyComplianceChecks() async {
        await submissionManager.performComplianceChecks()
        
        let privacyChecks = submissionManager.complianceChecks.filter { $0.category == .privacy }
        XCTAssertGreaterThan(privacyChecks.count, 0)
        
        // Check for specific privacy requirements
        let privacyPolicyCheck = privacyChecks.first { $0.requirement == "Privacy Policy" }
        XCTAssertNotNil(privacyPolicyCheck)
        XCTAssertEqual(privacyPolicyCheck?.status, .passed)
    }
    
    func testSecurityComplianceChecks() async {
        await submissionManager.performComplianceChecks()
        
        let securityChecks = submissionManager.complianceChecks.filter { $0.category == .security }
        XCTAssertGreaterThan(securityChecks.count, 0)
        
        // Check for specific security requirements
        let secureTransmissionCheck = securityChecks.first { $0.requirement == "Secure Data Transmission" }
        XCTAssertNotNil(secureTransmissionCheck)
        XCTAssertEqual(secureTransmissionCheck?.status, .passed)
    }
    
    func testAccessibilityComplianceChecks() async {
        await submissionManager.performComplianceChecks()
        
        let accessibilityChecks = submissionManager.complianceChecks.filter { $0.category == .accessibility }
        XCTAssertGreaterThan(accessibilityChecks.count, 0)
        
        // Check for specific accessibility requirements
        let voiceOverCheck = accessibilityChecks.first { $0.requirement == "VoiceOver Support" }
        XCTAssertNotNil(voiceOverCheck)
        XCTAssertEqual(voiceOverCheck?.status, .passed)
    }
    
    // MARK: - Metadata Validation Tests
    
    func testValidateMetadataWithCompleteData() async {
        // Set up complete metadata
        let metadata = AppStoreSubmissionManager.AppMetadata(
            appName: "Test App",
            description: "Test description",
            privacyPolicyURL: "https://test.com/privacy",
            supportURL: "https://test.com/support"
        )
        
        await submissionManager.validateMetadata()
        
        // Should pass validation
        XCTAssertEqual(submissionManager.metadataStatus, .complete)
    }
    
    func testValidateMetadataWithIncompleteData() async {
        // Metadata validation will fail due to missing required fields
        await submissionManager.validateMetadata()
        
        // Should fail validation
        XCTAssertEqual(submissionManager.metadataStatus, .incomplete)
        
        // Should have failed checks
        let failedChecks = submissionManager.complianceChecks.filter { $0.status == .failed }
        XCTAssertGreaterThan(failedChecks.count, 0)
    }
    
    // MARK: - Screenshot Validation Tests
    
    func testValidateScreenshots() async {
        await submissionManager.validateScreenshots()
        
        // Should have a status (either complete or incomplete)
        XCTAssertTrue([.complete, .incomplete].contains(submissionManager.screenshotStatus))
    }
    
    // MARK: - Build Status Tests
    
    func testCheckBuildStatus() async {
        await submissionManager.checkBuildStatus()
        
        // Should have a build status
        XCTAssertNotEqual(submissionManager.buildStatus, .notBuilt)
    }
    
    // MARK: - Submission Readiness Tests
    
    func testIsReadyForSubmissionWithAllPassed() async {
        // Set up all requirements as passed
        submissionManager.metadataStatus = .complete
        submissionManager.screenshotStatus = .complete
        submissionManager.buildStatus = .ready
        
        // Add some passed compliance checks
        submissionManager.complianceChecks.append(
            AppStoreSubmissionManager.ComplianceCheck(
                category: .privacy,
                requirement: "Test",
                status: .passed,
                description: "Test",
                isRequired: true
            )
        )
        
        XCTAssertTrue(submissionManager.isReadyForSubmission)
    }
    
    func testIsReadyForSubmissionWithFailedChecks() async {
        // Set up all status as complete but with failed required checks
        submissionManager.metadataStatus = .complete
        submissionManager.screenshotStatus = .complete
        submissionManager.buildStatus = .ready
        
        // Add a failed required compliance check
        submissionManager.complianceChecks.append(
            AppStoreSubmissionManager.ComplianceCheck(
                category: .privacy,
                requirement: "Test",
                status: .failed,
                description: "Test",
                isRequired: true
            )
        )
        
        XCTAssertFalse(submissionManager.isReadyForSubmission)
    }
    
    func testIsReadyForSubmissionWithIncompleteStatus() async {
        // Set up incomplete status
        submissionManager.metadataStatus = .incomplete
        submissionManager.screenshotStatus = .complete
        submissionManager.buildStatus = .ready
        
        XCTAssertFalse(submissionManager.isReadyForSubmission)
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateSubmissionChecklist() {
        let checklist = submissionManager.generateSubmissionChecklist()
        
        XCTAssertTrue(checklist.contains("App Store Submission Checklist"))
        XCTAssertTrue(checklist.contains("Compliance Checks"))
        XCTAssertTrue(checklist.contains("Metadata Status"))
        XCTAssertTrue(checklist.contains("Screenshot Status"))
        XCTAssertTrue(checklist.contains("Build Status"))
        XCTAssertTrue(checklist.contains("Required Actions"))
        XCTAssertTrue(checklist.contains("Ready for Submission"))
    }
    
    func testGenerateSubmissionChecklistWithIssues() async {
        // Add some failed checks
        submissionManager.complianceChecks.append(
            AppStoreSubmissionManager.ComplianceCheck(
                category: .privacy,
                requirement: "Privacy Policy",
                status: .failed,
                description: "Missing privacy policy",
                recommendation: "Add privacy policy",
                isRequired: true
            )
        )
        
        let checklist = submissionManager.generateSubmissionChecklist()
        
        XCTAssertTrue(checklist.contains("Failed: 1"))
        XCTAssertTrue(checklist.contains("Privacy Policy"))
        XCTAssertTrue(checklist.contains("Missing privacy policy"))
        XCTAssertTrue(checklist.contains("Add privacy policy"))
    }
    
    // MARK: - Export Tests
    
    func testExportSubmissionDataWithNoData() {
        let exportData = submissionManager.exportSubmissionData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(SubmissionExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.submissionStatus, .notStarted)
                XCTAssertEqual(export.complianceChecks.count, 0)
                XCTAssertEqual(export.metadataStatus, .incomplete)
                XCTAssertEqual(export.screenshotStatus, .incomplete)
                XCTAssertEqual(export.buildStatus, .notBuilt)
            }
        }
    }
    
    func testExportSubmissionDataWithData() async {
        // Add some data
        await submissionManager.performComplianceChecks()
        submissionManager.metadataStatus = .complete
        submissionManager.screenshotStatus = .complete
        submissionManager.buildStatus = .ready
        
        let exportData = submissionManager.exportSubmissionData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(SubmissionExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertGreaterThan(export.complianceChecks.count, 0)
                XCTAssertEqual(export.metadataStatus, .complete)
                XCTAssertEqual(export.screenshotStatus, .complete)
                XCTAssertEqual(export.buildStatus, .ready)
            }
        }
    }
    
    // MARK: - Initialization Tests
    
    func testInitialize() async {
        await submissionManager.initialize()
        
        // Should have performed compliance checks
        XCTAssertGreaterThan(submissionManager.complianceChecks.count, 0)
        
        // Should have validated metadata and screenshots
        XCTAssertNotEqual(submissionManager.metadataStatus, .incomplete)
        XCTAssertNotEqual(submissionManager.screenshotStatus, .incomplete)
        XCTAssertNotEqual(submissionManager.buildStatus, .notBuilt)
    }
    
    // MARK: - Performance Tests
    
    func testComplianceChecksPerformance() async {
        let startTime = Date()
        
        await submissionManager.performComplianceChecks()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Compliance checks should complete quickly (less than 1 second)
        XCTAssertLessThan(duration, 1.0, "Compliance checks took too long: \(duration) seconds")
        XCTAssertGreaterThan(submissionManager.complianceChecks.count, 0)
    }
    
    func testReportGenerationPerformance() async {
        // Add many compliance checks
        for i in 0..<50 {
            submissionManager.complianceChecks.append(
                AppStoreSubmissionManager.ComplianceCheck(
                    category: .privacy,
                    requirement: "Test \(i)",
                    status: .passed,
                    description: "Test description \(i)"
                )
            )
        }
        
        let startTime = Date()
        let checklist = submissionManager.generateSubmissionChecklist()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Report generation should be fast (less than 1 second)
        XCTAssertLessThan(duration, 1.0, "Report generation took too long: \(duration) seconds")
        XCTAssertTrue(checklist.contains("Test 0"))
        XCTAssertTrue(checklist.contains("Test 49"))
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyComplianceChecks() {
        let checklist = submissionManager.generateSubmissionChecklist()
        let exportData = submissionManager.exportSubmissionData()
        
        XCTAssertNotNil(checklist)
        XCTAssertNotNil(exportData)
        XCTAssertTrue(checklist.contains("Passed: 0/0"))
    }
    
    func testMixedComplianceCheckStatuses() async {
        let statuses: [AppStoreSubmissionManager.CheckStatus] = [.passed, .failed, .warning, .pending, .notApplicable]
        
        for (index, status) in statuses.enumerated() {
            submissionManager.complianceChecks.append(
                AppStoreSubmissionManager.ComplianceCheck(
                    category: .privacy,
                    requirement: "Test \(index)",
                    status: status,
                    description: "Test description"
                )
            )
        }
        
        let checklist = submissionManager.generateSubmissionChecklist()
        
        // Should handle all status types
        XCTAssertTrue(checklist.contains("Passed: 1/5"))
        XCTAssertTrue(checklist.contains("Failed: 1"))
        XCTAssertTrue(checklist.contains("Warnings: 1"))
    }
    
    func testSpecialCharactersInMetadata() {
        let specialDescription = "Description with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        let specialReleaseNotes = "Release notes with special chars: áéíóúñü"
        
        let metadata = AppStoreSubmissionManager.AppMetadata(
            description: specialDescription,
            releaseNotes: specialReleaseNotes
        )
        
        XCTAssertEqual(metadata.description, specialDescription)
        XCTAssertEqual(metadata.releaseNotes, specialReleaseNotes)
    }
}

// MARK: - Test Data Structure

private struct SubmissionExportData: Codable {
    let submissionStatus: AppStoreSubmissionManager.SubmissionStatus
    let complianceChecks: [AppStoreSubmissionManager.ComplianceCheck]
    let metadataStatus: AppStoreSubmissionManager.MetadataStatus
    let screenshotStatus: AppStoreSubmissionManager.ScreenshotStatus
    let buildStatus: AppStoreSubmissionManager.BuildStatus
    let exportDate: Date
} 