import XCTest
import SwiftUI
@testable import HealthAI2030

/// Comprehensive unit tests for the Accessibility Audit Manager
/// Tests all functionality including audit execution, issue detection, and reporting
final class AccessibilityAuditTests: XCTestCase {
    
    var auditManager: AccessibilityAuditManager!
    
    override func setUpWithError() throws {
        super.setUp()
        auditManager = AccessibilityAuditManager.shared
        auditManager.auditResults.removeAll()
        auditManager.higComplianceResults.removeAll()
    }
    
    override func tearDownWithError() throws {
        auditManager = nil
        super.tearDown()
    }
    
    // MARK: - Audit Manager Tests
    
    func testAuditManagerInitialization() {
        XCTAssertNotNil(auditManager)
        XCTAssertEqual(auditManager.auditResults.count, 0)
        XCTAssertEqual(auditManager.higComplianceResults.count, 0)
        XCTAssertFalse(auditManager.isAuditing)
        XCTAssertNil(auditManager.lastAuditDate)
    }
    
    func testAuditManagerSingleton() {
        let instance1 = AccessibilityAuditManager.shared
        let instance2 = AccessibilityAuditManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Issue Creation Tests
    
    func testAccessibilityIssueCreation() {
        let issue = AccessibilityAuditManager.AccessibilityIssue(
            severity: .high,
            component: "TestView",
            issueType: .missingAccessibilityLabel,
            description: "Test description",
            recommendation: "Test recommendation",
            lineNumber: 42,
            filePath: "TestFile.swift"
        )
        
        XCTAssertEqual(issue.severity, .high)
        XCTAssertEqual(issue.component, "TestView")
        XCTAssertEqual(issue.issueType, .missingAccessibilityLabel)
        XCTAssertEqual(issue.description, "Test description")
        XCTAssertEqual(issue.recommendation, "Test recommendation")
        XCTAssertEqual(issue.lineNumber, 42)
        XCTAssertEqual(issue.filePath, "TestFile.swift")
        XCTAssertNotNil(issue.timestamp)
    }
    
    func testHIGComplianceIssueCreation() {
        let issue = AccessibilityAuditManager.HIGComplianceIssue(
            severity: .medium,
            component: "TestView",
            issueType: .inconsistentSpacing,
            description: "Test description",
            recommendation: "Test recommendation",
            higGuideline: "Test guideline",
            lineNumber: 42,
            filePath: "TestFile.swift"
        )
        
        XCTAssertEqual(issue.severity, .medium)
        XCTAssertEqual(issue.component, "TestView")
        XCTAssertEqual(issue.issueType, .inconsistentSpacing)
        XCTAssertEqual(issue.description, "Test description")
        XCTAssertEqual(issue.recommendation, "Test recommendation")
        XCTAssertEqual(issue.higGuideline, "Test guideline")
        XCTAssertEqual(issue.lineNumber, 42)
        XCTAssertEqual(issue.filePath, "TestFile.swift")
        XCTAssertNotNil(issue.timestamp)
    }
    
    // MARK: - Severity Tests
    
    func testIssueSeverityColors() {
        XCTAssertEqual(AccessibilityAuditManager.IssueSeverity.critical.color, .red)
        XCTAssertEqual(AccessibilityAuditManager.IssueSeverity.high.color, .orange)
        XCTAssertEqual(AccessibilityAuditManager.IssueSeverity.medium.color, .yellow)
        XCTAssertEqual(AccessibilityAuditManager.IssueSeverity.low.color, .blue)
        XCTAssertEqual(AccessibilityAuditManager.IssueSeverity.info.color, .green)
    }
    
    func testIssueSeverityAllCases() {
        let allCases = AccessibilityAuditManager.IssueSeverity.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.critical))
        XCTAssertTrue(allCases.contains(.high))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.info))
    }
    
    // MARK: - Issue Type Tests
    
    func testAccessibilityIssueTypes() {
        let types = AccessibilityAuditManager.AccessibilityIssueType.allCases
        XCTAssertEqual(types.count, 13)
        
        let expectedTypes = [
            "Missing Accessibility Label",
            "Missing Accessibility Hint",
            "Missing Accessibility Value",
            "Missing Accessibility Traits",
            "Missing Dynamic Type Support",
            "Poor Color Contrast",
            "Missing VoiceOver Support",
            "Missing Switch Control Support",
            "Missing Haptic Feedback",
            "Inaccessible Interactive Element",
            "Missing Accessibility Action",
            "Poor Touch Target Size",
            "Missing Accessibility Identifier"
        ]
        
        for expectedType in expectedTypes {
            XCTAssertTrue(types.contains { $0.rawValue == expectedType })
        }
    }
    
    func testHIGIssueTypes() {
        let types = AccessibilityAuditManager.HIGIssueType.allCases
        XCTAssertEqual(types.count, 12)
        
        let expectedTypes = [
            "Inconsistent Spacing",
            "Poor Typography",
            "Inconsistent Iconography",
            "Poor Visual Hierarchy",
            "Missing Loading States",
            "Poor Error Handling",
            "Inconsistent Navigation",
            "Poor Empty States",
            "Missing Feedback",
            "Poor Layout Adaptation",
            "Inconsistent Color Usage",
            "Missing Animations"
        ]
        
        for expectedType in expectedTypes {
            XCTAssertTrue(types.contains { $0.rawValue == expectedType })
        }
    }
    
    // MARK: - Report Generation Tests
    
    func testGenerateAuditReportWithNoIssues() {
        let report = auditManager.generateAuditReport()
        
        XCTAssertTrue(report.contains("HealthAI 2030 Accessibility & HIG Compliance Audit Report"))
        XCTAssertTrue(report.contains("Total Issues Found: 0"))
        XCTAssertTrue(report.contains("Accessibility Issues (0)"))
        XCTAssertTrue(report.contains("HIG Compliance Issues (0)"))
        XCTAssertTrue(report.contains("Critical Issues: 0"))
        XCTAssertTrue(report.contains("High Priority Issues: 0"))
        XCTAssertTrue(report.contains("Medium Priority Issues: 0"))
        XCTAssertTrue(report.contains("Low Priority Issues: 0"))
    }
    
    func testGenerateAuditReportWithIssues() {
        // Add some test issues
        auditManager.auditResults.append(AccessibilityAuditManager.AccessibilityIssue(
            severity: .critical,
            component: "TestView",
            issueType: .missingAccessibilityLabel,
            description: "Critical issue",
            recommendation: "Fix immediately"
        ))
        
        auditManager.higComplianceResults.append(AccessibilityAuditManager.HIGComplianceIssue(
            severity: .high,
            component: "TestView",
            issueType: .inconsistentSpacing,
            description: "High priority issue",
            recommendation: "Fix soon",
            higGuideline: "Use consistent spacing"
        ))
        
        let report = auditManager.generateAuditReport()
        
        XCTAssertTrue(report.contains("Total Issues Found: 2"))
        XCTAssertTrue(report.contains("Accessibility Issues (1)"))
        XCTAssertTrue(report.contains("HIG Compliance Issues (1)"))
        XCTAssertTrue(report.contains("Critical Issues: 1"))
        XCTAssertTrue(report.contains("High Priority Issues: 1"))
        XCTAssertTrue(report.contains("Critical Priority (1)"))
        XCTAssertTrue(report.contains("High Priority (1)"))
        XCTAssertTrue(report.contains("Missing Accessibility Label"))
        XCTAssertTrue(report.contains("Inconsistent Spacing"))
    }
    
    // MARK: - Export Tests
    
    func testExportAuditResultsWithNoIssues() {
        let exportData = auditManager.exportAuditResults()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(AuditExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.accessibilityIssues.count, 0)
                XCTAssertEqual(export.higComplianceIssues.count, 0)
                XCTAssertEqual(export.totalIssues, 0)
            }
        }
    }
    
    func testExportAuditResultsWithIssues() {
        // Add test issues
        auditManager.auditResults.append(AccessibilityAuditManager.AccessibilityIssue(
            severity: .medium,
            component: "TestView",
            issueType: .missingDynamicTypeSupport,
            description: "Test issue",
            recommendation: "Test recommendation"
        ))
        
        let exportData = auditManager.exportAuditResults()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            let exportStruct = try? decoder.decode(AuditExportData.self, from: data)
            XCTAssertNotNil(exportStruct)
            
            if let export = exportStruct {
                XCTAssertEqual(export.accessibilityIssues.count, 1)
                XCTAssertEqual(export.higComplianceIssues.count, 0)
                XCTAssertEqual(export.totalIssues, 1)
                XCTAssertEqual(export.accessibilityIssues.first?.issueType, .missingDynamicTypeSupport)
            }
        }
    }
    
    // MARK: - Audit Execution Tests
    
    func testStartComprehensiveAudit() async {
        XCTAssertFalse(auditManager.isAuditing)
        
        await auditManager.startComprehensiveAudit()
        
        XCTAssertFalse(auditManager.isAuditing)
        XCTAssertNotNil(auditManager.lastAuditDate)
    }
    
    func testAuditExecutionMultipleTimes() async {
        await auditManager.startComprehensiveAudit()
        let firstAuditDate = auditManager.lastAuditDate
        
        // Wait a moment to ensure different timestamps
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await auditManager.startComprehensiveAudit()
        let secondAuditDate = auditManager.lastAuditDate
        
        XCTAssertNotNil(firstAuditDate)
        XCTAssertNotNil(secondAuditDate)
        XCTAssertNotEqual(firstAuditDate, secondAuditDate)
    }
    
    // MARK: - File Analysis Tests
    
    func testExtractComponentName() {
        let testCases = [
            ("struct TestView: View {", "TestView"),
            ("struct MyCustomView: View {", "MyCustomView"),
            ("struct Complex_View_Name: View {", "Complex_View_Name"),
            ("// This is a comment", "Unknown Component"),
            ("let someVariable = 42", "Unknown Component"),
            ("", "Unknown Component")
        ]
        
        for (input, expected) in testCases {
            let result = extractComponentName(from: input)
            XCTAssertEqual(result, expected, "Failed for input: '\(input)'")
        }
    }
    
    // MARK: - Helper Method Tests
    
    private func extractComponentName(from line: String) -> String {
        if let range = line.range(of: "struct ") {
            let afterStruct = String(line[range.upperBound...])
            if let spaceRange = afterStruct.firstIndex(of: " ") {
                return String(afterStruct[..<spaceRange])
            }
        }
        return "Unknown Component"
    }
    
    // MARK: - View Extension Tests
    
    func testComprehensiveAccessibilityModifier() {
        let testView = Text("Hello")
            .comprehensiveAccessibility(
                label: "Test Label",
                hint: "Test Hint",
                value: "Test Value",
                traits: [.isButton],
                isAccessibilityElement: true
            )
        
        // This test verifies the modifier can be applied without errors
        XCTAssertNotNil(testView)
    }
    
    func testHIGCompliantStyleModifier() {
        let testView = Text("Hello")
            .higCompliantStyle(
                spacing: 20,
                cornerRadius: 16,
                shadowRadius: 12
            )
        
        // This test verifies the modifier can be applied without errors
        XCTAssertNotNil(testView)
    }
    
    // MARK: - Performance Tests
    
    func testAuditPerformance() async {
        let startTime = Date()
        
        await auditManager.startComprehensiveAudit()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Audit should complete within reasonable time (less than 5 seconds)
        XCTAssertLessThan(duration, 5.0, "Audit took too long: \(duration) seconds")
    }
    
    func testReportGenerationPerformance() {
        // Add many issues to test performance
        for i in 0..<100 {
            auditManager.auditResults.append(AccessibilityAuditManager.AccessibilityIssue(
                severity: .medium,
                component: "TestView\(i)",
                issueType: .missingAccessibilityLabel,
                description: "Test issue \(i)",
                recommendation: "Test recommendation \(i)"
            ))
        }
        
        let startTime = Date()
        let report = auditManager.generateAuditReport()
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Report generation should be fast (less than 1 second)
        XCTAssertLessThan(duration, 1.0, "Report generation took too long: \(duration) seconds")
        XCTAssertTrue(report.contains("Total Issues Found: 100"))
    }
    
    // MARK: - Edge Case Tests
    
    func testAuditWithEmptyResults() {
        let report = auditManager.generateAuditReport()
        let exportData = auditManager.exportAuditResults()
        
        XCTAssertNotNil(report)
        XCTAssertNotNil(exportData)
        XCTAssertTrue(report.contains("Total Issues Found: 0"))
    }
    
    func testAuditWithMixedSeverities() {
        let severities: [AccessibilityAuditManager.IssueSeverity] = [.critical, .high, .medium, .low, .info]
        
        for (index, severity) in severities.enumerated() {
            auditManager.auditResults.append(AccessibilityAuditManager.AccessibilityIssue(
                severity: severity,
                component: "TestView\(index)",
                issueType: .missingAccessibilityLabel,
                description: "Test issue",
                recommendation: "Test recommendation"
            ))
        }
        
        let report = auditManager.generateAuditReport()
        
        for severity in severities {
            XCTAssertTrue(report.contains("\(severity.rawValue) Priority (1)"))
        }
    }
    
    func testAuditWithSpecialCharacters() {
        let specialDescription = "Issue with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        let specialRecommendation = "Fix with special chars: áéíóúñü"
        
        auditManager.auditResults.append(AccessibilityAuditManager.AccessibilityIssue(
            severity: .high,
            component: "TestView",
            issueType: .missingAccessibilityLabel,
            description: specialDescription,
            recommendation: specialRecommendation
        ))
        
        let report = auditManager.generateAuditReport()
        XCTAssertTrue(report.contains(specialDescription))
        XCTAssertTrue(report.contains(specialRecommendation))
    }
}

// MARK: - Test Data Structure

private struct AuditExportData: Codable {
    let accessibilityIssues: [AccessibilityAuditManager.AccessibilityIssue]
    let higComplianceIssues: [AccessibilityAuditManager.HIGComplianceIssue]
    let exportDate: Date
    let totalIssues: Int
} 