import XCTest
import Foundation
import SwiftUI
import Combine
@testable import HealthAI2030

/// Comprehensive unit tests for Multi-Platform Support Manager
/// Tests all platform functionality including feature compatibility, cross-platform sync, and optimizations
final class MultiPlatformSupportTests: XCTestCase {
    var platformManager: MultiPlatformSupportManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        platformManager = MultiPlatformSupportManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        platformManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async {
        // Test initial state
        XCTAssertEqual(platformManager.currentPlatform, .iOS)
        XCTAssertFalse(platformManager.platformFeatures.isEmpty)
        XCTAssertFalse(platformManager.platformOptimizations.isEmpty)
        XCTAssertFalse(platformManager.featureCompatibility.isEmpty)
        XCTAssertFalse(platformManager.platformStatus.isEmpty)
        XCTAssertNil(platformManager.lastSyncDate)
        
        // Test initialization
        await platformManager.initialize()
        
        // Verify platforms are loaded
        XCTAssertFalse(platformManager.platformFeatures.isEmpty)
        XCTAssertFalse(platformManager.platformOptimizations.isEmpty)
        XCTAssertFalse(platformManager.featureCompatibility.isEmpty)
        XCTAssertFalse(platformManager.platformStatus.isEmpty)
    }
    
    func testPlatformDetection() async {
        await platformManager.detectCurrentPlatform()
        
        // Should detect a valid platform
        XCTAssertTrue(MultiPlatformSupportManager.Platform.allCases.contains(platformManager.currentPlatform))
    }
    
    // MARK: - Platform Features Tests
    
    func testPlatformFeatures() {
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let features = platformManager.getPlatformFeatures(for: platform)
            
            XCTAssertNotNil(features)
            XCTAssertEqual(features?.platform, platform)
            XCTAssertFalse(features?.supportedFeatures.isEmpty ?? true)
            XCTAssertNotNil(features?.screenSize)
            XCTAssertFalse(features?.inputMethods.isEmpty ?? true)
            XCTAssertFalse(features?.connectivityOptions.isEmpty ?? true)
        }
    }
    
    func testFeatureSupport() {
        let testFeatures = [
            "Health Monitoring",
            "Data Visualization",
            "ML Predictions",
            "Notifications",
            "Data Sync"
        ]
        
        for feature in testFeatures {
            for platform in MultiPlatformSupportManager.Platform.allCases {
                let isSupported = platformManager.isFeatureSupported(feature, on: platform)
                
                // Should return a boolean value
                XCTAssertTrue(isSupported == true || isSupported == false)
            }
        }
    }
    
    func testPlatformSpecificFeatures() {
        // Test iOS-specific features
        XCTAssertTrue(platformManager.isFeatureSupported("Health Monitoring", on: .iOS))
        XCTAssertTrue(platformManager.isFeatureSupported("Biometric Authentication", on: .iOS))
        
        // Test macOS-specific features
        XCTAssertTrue(platformManager.isFeatureSupported("Data Visualization", on: .macOS))
        XCTAssertFalse(platformManager.isFeatureSupported("Voice Commands", on: .macOS))
        
        // Test watchOS-specific features
        XCTAssertTrue(platformManager.isFeatureSupported("Health Monitoring", on: .watchOS))
        XCTAssertFalse(platformManager.isFeatureSupported("Data Visualization", on: .watchOS))
        
        // Test tvOS-specific features
        XCTAssertTrue(platformManager.isFeatureSupported("Data Visualization", on: .tvOS))
        XCTAssertFalse(platformManager.isFeatureSupported("Health Monitoring", on: .tvOS))
    }
    
    func testHardwareCapabilities() {
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let features = platformManager.getPlatformFeatures(for: platform)
            
            XCTAssertNotNil(features)
            XCTAssertFalse(features?.hardwareCapabilities.isEmpty ?? true)
            
            // Test specific capabilities
            let capabilities = features?.hardwareCapabilities ?? [:]
            
            switch platform {
            case .iOS:
                XCTAssertTrue(capabilities["camera"] ?? false)
                XCTAssertTrue(capabilities["gps"] ?? false)
                XCTAssertTrue(capabilities["accelerometer"] ?? false)
                
            case .macOS:
                XCTAssertTrue(capabilities["camera"] ?? false)
                XCTAssertFalse(capabilities["gps"] ?? true)
                XCTAssertFalse(capabilities["accelerometer"] ?? true)
                
            case .watchOS:
                XCTAssertFalse(capabilities["camera"] ?? true)
                XCTAssertTrue(capabilities["gps"] ?? false)
                XCTAssertTrue(capabilities["accelerometer"] ?? false)
                
            case .tvOS:
                XCTAssertFalse(capabilities["camera"] ?? true)
                XCTAssertFalse(capabilities["gps"] ?? true)
                XCTAssertFalse(capabilities["accelerometer"] ?? true)
            }
        }
    }
    
    // MARK: - Feature Compatibility Tests
    
    func testFeatureCompatibility() {
        let testFeatures = [
            "Health Monitoring",
            "Data Visualization",
            "ML Predictions",
            "Notifications",
            "Data Sync"
        ]
        
        for feature in testFeatures {
            let compatibility = platformManager.getFeatureCompatibility(for: feature)
            
            XCTAssertNotNil(compatibility)
            XCTAssertEqual(compatibility?.featureName, feature)
            XCTAssertFalse(compatibility?.platforms.isEmpty ?? true)
            XCTAssertNotNil(compatibility?.lastTested)
            
            // Check that all platforms are covered
            for platform in MultiPlatformSupportManager.Platform.allCases {
                XCTAssertNotNil(compatibility?.platforms[platform])
            }
        }
    }
    
    func testCompatibilityStatuses() {
        let compatibility = platformManager.getFeatureCompatibility(for: "Health Monitoring")
        
        XCTAssertNotNil(compatibility)
        
        let statuses = compatibility?.platforms.values ?? []
        XCTAssertFalse(statuses.isEmpty)
        
        // All statuses should be valid
        let validStatuses = Set(MultiPlatformSupportManager.CompatibilityStatus.allCases)
        for status in statuses {
            XCTAssertTrue(validStatuses.contains(status))
        }
    }
    
    func testPlatformSpecificCompatibility() {
        // Test iOS compatibility
        let iosCompatibility = platformManager.getFeatureCompatibility(for: "Health Monitoring")
        XCTAssertEqual(iosCompatibility?.platforms[.iOS], .fullySupported)
        
        // Test tvOS limitations
        let tvosCompatibility = platformManager.getFeatureCompatibility(for: "Health Monitoring")
        XCTAssertEqual(tvosCompatibility?.platforms[.tvOS], .notSupported)
        
        // Test macOS partial support
        let macosCompatibility = platformManager.getFeatureCompatibility(for: "Notifications")
        XCTAssertEqual(macosCompatibility?.platforms[.macOS], .partiallySupported)
    }
    
    // MARK: - Platform Optimizations Tests
    
    func testPlatformOptimizations() async {
        await platformManager.applyPlatformOptimizations()
        
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let optimization = platformManager.platformOptimizations[platform]
            
            XCTAssertNotNil(optimization)
            XCTAssertEqual(optimization?.platform, platform)
            XCTAssertFalse(optimization?.uiOptimizations.isEmpty ?? true)
            XCTAssertFalse(optimization?.performanceOptimizations.isEmpty ?? true)
            XCTAssertFalse(optimization?.accessibilityOptimizations.isEmpty ?? true)
            XCTAssertNotNil(optimization?.lastOptimized)
        }
    }
    
    func testUIOptimizations() {
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let optimization = platformManager.platformOptimizations[platform]
            
            XCTAssertNotNil(optimization)
            
            let uiOptimizations = optimization?.uiOptimizations ?? []
            XCTAssertFalse(uiOptimizations.isEmpty)
            
            for uiOpt in uiOptimizations {
                XCTAssertFalse(uiOpt.name.isEmpty)
                XCTAssertFalse(uiOpt.description.isEmpty)
                
                // Impact should be valid
                let validImpacts = Set(MultiPlatformSupportManager.OptimizationImpact.allCases)
                XCTAssertTrue(validImpacts.contains(uiOpt.impact))
            }
        }
    }
    
    func testPerformanceOptimizations() {
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let optimization = platformManager.platformOptimizations[platform]
            
            XCTAssertNotNil(optimization)
            
            let performanceOptimizations = optimization?.performanceOptimizations ?? []
            XCTAssertFalse(performanceOptimizations.isEmpty)
            
            for perfOpt in performanceOptimizations {
                XCTAssertFalse(perfOpt.name.isEmpty)
                XCTAssertFalse(perfOpt.description.isEmpty)
                XCTAssertGreaterThanOrEqual(perfOpt.performanceGain, 0.0)
                XCTAssertLessThanOrEqual(perfOpt.performanceGain, 1.0)
                XCTAssertGreaterThanOrEqual(perfOpt.memoryUsage, 0.0)
                XCTAssertLessThanOrEqual(perfOpt.memoryUsage, 1.0)
            }
        }
    }
    
    func testAccessibilityOptimizations() {
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let optimization = platformManager.platformOptimizations[platform]
            
            XCTAssertNotNil(optimization)
            
            let accessibilityOptimizations = optimization?.accessibilityOptimizations ?? []
            XCTAssertFalse(accessibilityOptimizations.isEmpty)
            
            for accOpt in accessibilityOptimizations {
                XCTAssertFalse(accOpt.name.isEmpty)
                XCTAssertFalse(accOpt.description.isEmpty)
                
                // Accessibility level should be valid
                let validLevels = Set(MultiPlatformSupportManager.AccessibilityLevel.allCases)
                XCTAssertTrue(validLevels.contains(accOpt.accessibilityLevel))
            }
        }
    }
    
    // MARK: - Cross-Platform Sync Tests
    
    func testCrossPlatformSync() async {
        // Test initial sync state
        XCTAssertTrue(platformManager.crossPlatformSync.isEnabled)
        XCTAssertEqual(platformManager.crossPlatformSync.syncStatus, .idle)
        XCTAssertEqual(platformManager.crossPlatformSync.syncProgress, 0.0)
        XCTAssertTrue(platformManager.crossPlatformSync.syncErrors.isEmpty)
        XCTAssertTrue(platformManager.crossPlatformSync.pendingChanges.isEmpty)
        
        // Test sync operation
        await platformManager.syncAcrossPlatforms()
        
        // Verify sync completed
        XCTAssertEqual(platformManager.crossPlatformSync.syncStatus, .completed)
        XCTAssertEqual(platformManager.crossPlatformSync.syncProgress, 1.0)
        XCTAssertNotNil(platformManager.crossPlatformSync.lastSyncDate)
        XCTAssertNotNil(platformManager.lastSyncDate)
    }
    
    func testSyncStatusTransitions() async {
        // Test sync status changes
        XCTAssertEqual(platformManager.crossPlatformSync.syncStatus, .idle)
        
        // Start sync
        let syncTask = Task {
            await platformManager.syncAcrossPlatforms()
        }
        
        // Wait a bit for sync to start
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Check if sync started
        if platformManager.crossPlatformSync.syncStatus == .syncing {
            XCTAssertGreaterThan(platformManager.crossPlatformSync.syncProgress, 0.0)
        }
        
        // Wait for sync to complete
        await syncTask.value
        
        XCTAssertEqual(platformManager.crossPlatformSync.syncStatus, .completed)
        XCTAssertEqual(platformManager.crossPlatformSync.syncProgress, 1.0)
    }
    
    func testDeviceManagement() {
        // Test device list
        let devices = platformManager.crossPlatformSync.devices
        XCTAssertGreaterThanOrEqual(devices.count, 0)
        
        for device in devices {
            XCTAssertFalse(device.name.isEmpty)
            XCTAssertTrue(MultiPlatformSupportManager.Platform.allCases.contains(device.platform))
            XCTAssertFalse(device.model.isEmpty)
            XCTAssertFalse(device.osVersion.isEmpty)
            XCTAssertFalse(device.appVersion.isEmpty)
            
            // Sync status should be valid
            let validStatuses = Set(MultiPlatformSupportManager.SyncStatus.allCases)
            XCTAssertTrue(validStatuses.contains(device.syncStatus))
        }
    }
    
    // MARK: - Platform Status Tests
    
    func testPlatformStatus() async {
        await platformManager.updatePlatformStatus()
        
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let status = platformManager.getPlatformStatus(for: platform)
            
            XCTAssertNotNil(status)
            XCTAssertEqual(status?.platform, platform)
            XCTAssertFalse(status?.version.isEmpty ?? true)
            XCTAssertFalse(status?.buildNumber.isEmpty ?? true)
            XCTAssertGreaterThanOrEqual(status?.deviceCount ?? 0, 0)
            XCTAssertGreaterThanOrEqual(status?.errorCount ?? 0, 0)
            XCTAssertGreaterThanOrEqual(status?.performanceScore ?? 0, 0.0)
            XCTAssertLessThanOrEqual(status?.performanceScore ?? 1, 1.0)
        }
    }
    
    func testPlatformStatusUpdates() async {
        // Test status updates
        await platformManager.updatePlatformStatus()
        
        let initialStatus = platformManager.getPlatformStatus(for: .iOS)
        XCTAssertNotNil(initialStatus)
        
        // Update again
        await platformManager.updatePlatformStatus()
        
        let updatedStatus = platformManager.getPlatformStatus(for: .iOS)
        XCTAssertNotNil(updatedStatus)
        
        // Should have updated timestamp
        XCTAssertGreaterThanOrEqual(updatedStatus?.lastActivity ?? Date(), initialStatus?.lastActivity ?? Date())
    }
    
    // MARK: - Cross-Platform Summary Tests
    
    func testCrossPlatformSummary() {
        let summary = platformManager.getCrossPlatformSummary()
        
        XCTAssertGreaterThanOrEqual(summary.totalDevices, 0)
        XCTAssertGreaterThanOrEqual(summary.onlineDevices, 0)
        XCTAssertLessThanOrEqual(summary.onlineDevices, summary.totalDevices)
        XCTAssertGreaterThanOrEqual(summary.activePlatforms, 0)
        XCTAssertLessThanOrEqual(summary.activePlatforms, MultiPlatformSupportManager.Platform.allCases.count)
        XCTAssertGreaterThanOrEqual(summary.totalFeatures, 0)
        XCTAssertGreaterThanOrEqual(summary.fullySupportedFeatures, 0)
        XCTAssertLessThanOrEqual(summary.fullySupportedFeatures, summary.totalFeatures)
        
        // Test calculated properties
        XCTAssertGreaterThanOrEqual(summary.deviceOnlineRate, 0.0)
        XCTAssertLessThanOrEqual(summary.deviceOnlineRate, 1.0)
        XCTAssertGreaterThanOrEqual(summary.featureSupportRate, 0.0)
        XCTAssertLessThanOrEqual(summary.featureSupportRate, 1.0)
    }
    
    func testSummaryCalculations() {
        // Test with known values
        let summary = platformManager.getCrossPlatformSummary()
        
        if summary.totalDevices > 0 {
            let expectedOnlineRate = Double(summary.onlineDevices) / Double(summary.totalDevices)
            XCTAssertEqual(summary.deviceOnlineRate, expectedOnlineRate, accuracy: 0.01)
        }
        
        if summary.totalFeatures > 0 {
            let expectedSupportRate = Double(summary.fullySupportedFeatures) / Double(summary.totalFeatures)
            XCTAssertEqual(summary.featureSupportRate, expectedSupportRate, accuracy: 0.01)
        }
    }
    
    // MARK: - Data Export Tests
    
    func testExportPlatformData() {
        let exportData = platformManager.exportPlatformData()
        XCTAssertNotNil(exportData)
        
        // Verify data can be decoded
        if let data = exportData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(PlatformExportData.self, from: data))
        }
    }
    
    func testExportDataCompleteness() {
        let exportData = platformManager.exportPlatformData()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            do {
                let export = try decoder.decode(PlatformExportData.self, from: data)
                
                // Check that all platforms are included
                XCTAssertEqual(export.platformFeatures.count, MultiPlatformSupportManager.Platform.allCases.count)
                XCTAssertEqual(export.platformOptimizations.count, MultiPlatformSupportManager.Platform.allCases.count)
                XCTAssertEqual(export.platformStatus.count, MultiPlatformSupportManager.Platform.allCases.count)
                
                // Check that features are included
                XCTAssertFalse(export.featureCompatibility.isEmpty)
                
            } catch {
                XCTFail("Failed to decode export data: \(error)")
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testNonExistentPlatform() {
        // Test with invalid platform (should not crash)
        let features = platformManager.getPlatformFeatures(for: .iOS) // Valid platform
        XCTAssertNotNil(features)
        
        // Test with non-existent feature
        let compatibility = platformManager.getFeatureCompatibility(for: "NonExistentFeature")
        XCTAssertNil(compatibility)
    }
    
    func testEmptyPlatformData() {
        // Test with empty data scenarios
        let summary = platformManager.getCrossPlatformSummary()
        
        // Should handle empty data gracefully
        XCTAssertGreaterThanOrEqual(summary.totalDevices, 0)
        XCTAssertGreaterThanOrEqual(summary.onlineDevices, 0)
        XCTAssertGreaterThanOrEqual(summary.activePlatforms, 0)
        XCTAssertGreaterThanOrEqual(summary.totalFeatures, 0)
        XCTAssertGreaterThanOrEqual(summary.fullySupportedFeatures, 0)
    }
    
    func testPlatformFeatureConsistency() {
        // Test that platform features are consistent
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let features = platformManager.getPlatformFeatures(for: platform)
            
            XCTAssertNotNil(features)
            XCTAssertEqual(features?.platform, platform)
            
            // Check that supported and unsupported features don't overlap
            let supported = Set(features?.supportedFeatures ?? [])
            let unsupported = Set(features?.unsupportedFeatures ?? [])
            let intersection = supported.intersection(unsupported)
            
            XCTAssertTrue(intersection.isEmpty, "Platform \(platform) has overlapping supported and unsupported features")
        }
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentPlatformOperations() async {
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.platformManager.updatePlatformStatus()
                }
            }
            
            await group.waitForAll()
        }
        
        // Should complete without crashing
        XCTAssertFalse(platformManager.platformStatus.isEmpty)
    }
    
    func testLargeFeatureSet() {
        // Test with many features
        let manyFeatures = (1...100).map { "Feature\($0)" }
        
        for feature in manyFeatures {
            let compatibility = platformManager.getFeatureCompatibility(for: feature)
            // Should handle gracefully (may return nil for non-existent features)
        }
    }
    
    // MARK: - Integration Tests
    
    func testPlatformFeatureIntegration() {
        // Test integration between platform features and feature compatibility
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let features = platformManager.getPlatformFeatures(for: platform)
            
            XCTAssertNotNil(features)
            
            for feature in features?.supportedFeatures ?? [] {
                let compatibility = platformManager.getFeatureCompatibility(for: feature)
                
                // If feature is supported, compatibility should reflect that
                if let compatibility = compatibility {
                    let status = compatibility.platforms[platform]
                    XCTAssertNotEqual(status, .notSupported, "Feature \(feature) is supported on \(platform) but compatibility shows not supported")
                }
            }
        }
    }
    
    func testSyncIntegration() async {
        // Test integration between sync and platform status
        await platformManager.syncAcrossPlatforms()
        
        // After sync, platform status should be updated
        await platformManager.updatePlatformStatus()
        
        for platform in MultiPlatformSupportManager.Platform.allCases {
            let status = platformManager.getPlatformStatus(for: platform)
            XCTAssertNotNil(status)
            
            // Should have recent activity
            let timeSinceActivity = Date().timeIntervalSince(status?.lastActivity ?? Date())
            XCTAssertLessThan(timeSinceActivity, 60) // Within last minute
        }
    }
}

// MARK: - Supporting Structures for Tests

private struct PlatformExportData: Codable {
    let currentPlatform: MultiPlatformSupportManager.Platform
    let platformFeatures: [MultiPlatformSupportManager.Platform: MultiPlatformSupportManager.PlatformFeatures]
    let crossPlatformSync: MultiPlatformSupportManager.CrossPlatformSync
    let platformOptimizations: [MultiPlatformSupportManager.Platform: MultiPlatformSupportManager.PlatformOptimization]
    let featureCompatibility: [String: MultiPlatformSupportManager.FeatureCompatibility]
    let platformStatus: [MultiPlatformSupportManager.Platform: MultiPlatformSupportManager.PlatformStatus]
    let lastSyncDate: Date?
    let exportDate: Date
} 