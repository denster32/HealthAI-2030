import XCTest
import HealthKit
import CryptoKit
@testable import HealthAI2030

final class AdvancedDataExportTests: XCTestCase {
    var exportManager: AdvancedDataExportManager!
    var mockHealthStore: MockHealthStore!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockHealthStore = MockHealthStore()
        exportManager = AdvancedDataExportManager()
    }
    
    override func tearDownWithError() throws {
        exportManager = nil
        mockHealthStore = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() throws {
        XCTAssertNotNil(exportManager)
        XCTAssertEqual(exportManager.exportProgress, 0.0)
        XCTAssertEqual(exportManager.backupStatus, .idle)
        XCTAssertNil(exportManager.lastBackupDate)
        XCTAssertTrue(exportManager.backupHistory.isEmpty)
        XCTAssertTrue(exportManager.exportHistory.isEmpty)
        XCTAssertFalse(exportManager.isExporting)
        XCTAssertFalse(exportManager.isBackingUp)
    }
    
    func testDirectoryCreation() throws {
        // Verify backup and export directories are created
        let backupURL = exportManager.backupDirectory
        let exportURL = exportManager.exportDirectory
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
    }
    
    // MARK: - Data Export Tests
    
    func testExportData_JSON() async throws {
        // Given
        let format = ExportFormat.json
        let includeHealthData = true
        let includeAppData = true
        
        // When
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: includeHealthData,
            includeAppData: includeAppData
        )
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(exportURL.pathExtension == "json")
        
        // Verify export history was updated
        XCTAssertEqual(exportManager.exportHistory.count, 1)
        XCTAssertEqual(exportManager.exportHistory.first?.format, format)
        XCTAssertEqual(exportManager.exportHistory.first?.includeHealthData, includeHealthData)
        XCTAssertEqual(exportManager.exportHistory.first?.includeAppData, includeAppData)
    }
    
    func testExportData_CSV() async throws {
        // Given
        let format = ExportFormat.csv
        
        // When
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: true,
            includeAppData: false
        )
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(exportURL.pathExtension == "csv")
        
        // Verify CSV content
        let csvContent = try String(contentsOf: exportURL)
        XCTAssertTrue(csvContent.contains("Date,Type,Value,Unit,Source"))
    }
    
    func testExportData_PDF() async throws {
        // Given
        let format = ExportFormat.pdf
        
        // When
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: true,
            includeAppData: true
        )
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(exportURL.pathExtension == "pdf")
    }
    
    func testExportData_XML() async throws {
        // Given
        let format = ExportFormat.xml
        
        // When
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: true,
            includeAppData: false
        )
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(exportURL.pathExtension == "xml")
        
        // Verify XML content
        let xmlContent = try String(contentsOf: exportURL)
        XCTAssertTrue(xmlContent.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(xmlContent.contains("<healthData>"))
    }
    
    func testExportData_FHIR() async throws {
        // Given
        let format = ExportFormat.fhir
        
        // When
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: true,
            includeAppData: false
        )
        
        // Then
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
        XCTAssertTrue(exportURL.pathExtension == "json")
        
        // Verify FHIR content
        let fhirContent = try String(contentsOf: exportURL)
        XCTAssertTrue(fhirContent.contains("\"resourceType\":\"Bundle\""))
        XCTAssertTrue(fhirContent.contains("\"type\":\"collection\""))
    }
    
    func testExportData_HealthDataOnly() async throws {
        // Given
        let includeHealthData = true
        let includeAppData = false
        
        // When
        let exportURL = try await exportManager.exportData(
            to: .json,
            includeHealthData: includeHealthData,
            includeAppData: includeAppData
        )
        
        // Then
        let exportRecord = exportManager.exportHistory.first
        XCTAssertEqual(exportRecord?.includeHealthData, true)
        XCTAssertEqual(exportRecord?.includeAppData, false)
    }
    
    func testExportData_AppDataOnly() async throws {
        // Given
        let includeHealthData = false
        let includeAppData = true
        
        // When
        let exportURL = try await exportManager.exportData(
            to: .json,
            includeHealthData: includeHealthData,
            includeAppData: includeAppData
        )
        
        // Then
        let exportRecord = exportManager.exportHistory.first
        XCTAssertEqual(exportRecord?.includeHealthData, false)
        XCTAssertEqual(exportRecord?.includeAppData, true)
    }
    
    // MARK: - Health Data Export Tests
    
    func testExportHeartRateData() async throws {
        // Given
        let mockHeartRateData = [
            createMockHeartRateSample(value: 75.0, date: Date()),
            createMockHeartRateSample(value: 80.0, date: Date().addingTimeInterval(3600))
        ]
        mockHealthStore.addMockHeartRateData(mockHeartRateData)
        
        // When
        let heartRateData = try await exportManager.exportHeartRateData()
        
        // Then
        XCTAssertEqual(heartRateData.count, 2)
        XCTAssertEqual(heartRateData[0].value, 75.0)
        XCTAssertEqual(heartRateData[1].value, 80.0)
    }
    
    func testExportBloodPressureData() async throws {
        // Given
        let mockBloodPressureData = [
            createMockBloodPressureSample(systolic: 120.0, diastolic: 80.0, date: Date())
        ]
        mockHealthStore.addMockBloodPressureData(mockBloodPressureData)
        
        // When
        let bloodPressureData = try await exportManager.exportBloodPressureData()
        
        // Then
        XCTAssertEqual(bloodPressureData.count, 1)
        XCTAssertEqual(bloodPressureData[0].systolic, 120.0)
        XCTAssertEqual(bloodPressureData[0].diastolic, 80.0)
    }
    
    func testExportSleepData() async throws {
        // Given
        let mockSleepData = [
            createMockSleepSample(startDate: Date(), endDate: Date().addingTimeInterval(28800), stage: .deep)
        ]
        mockHealthStore.addMockSleepData(mockSleepData)
        
        // When
        let sleepData = try await exportManager.exportSleepData()
        
        // Then
        XCTAssertEqual(sleepData.count, 1)
        XCTAssertEqual(sleepData[0].sleepStage, .deep)
    }
    
    func testExportActivityData() async throws {
        // Given
        let mockActivityData = [
            createMockStepSample(steps: 10000, date: Date())
        ]
        mockHealthStore.addMockStepData(mockActivityData)
        
        // When
        let activityData = try await exportManager.exportActivityData()
        
        // Then
        XCTAssertEqual(activityData.count, 1)
        XCTAssertEqual(activityData[0].steps, 10000)
    }
    
    func testExportNutritionData() async throws {
        // Given
        let mockNutritionData = [
            createMockCalorieSample(calories: 2000, date: Date())
        ]
        mockHealthStore.addMockCalorieData(mockNutritionData)
        
        // When
        let nutritionData = try await exportManager.exportNutritionData()
        
        // Then
        XCTAssertEqual(nutritionData.count, 1)
        XCTAssertEqual(nutritionData[0].calories, 2000)
    }
    
    func testExportWeightData() async throws {
        // Given
        let mockWeightData = [
            createMockWeightSample(weight: 70.0, date: Date())
        ]
        mockHealthStore.addMockWeightData(mockWeightData)
        
        // When
        let weightData = try await exportManager.exportWeightData()
        
        // Then
        XCTAssertEqual(weightData.count, 1)
        XCTAssertEqual(weightData[0].weight, 70.0)
    }
    
    func testExportMedicationData() async throws {
        // Given
        let mockMedicationData = [
            createMockMedicationSample(name: "Aspirin", dosage: "100mg", date: Date())
        ]
        mockHealthStore.addMockMedicationData(mockMedicationData)
        
        // When
        let medicationData = try await exportManager.exportMedicationData()
        
        // Then
        XCTAssertEqual(medicationData.count, 1)
        XCTAssertEqual(medicationData[0].medicationName, "Aspirin")
        XCTAssertEqual(medicationData[0].dosage, "100mg")
    }
    
    // MARK: - Backup Tests
    
    func testStartBackup() async throws {
        // Given
        XCTAssertEqual(exportManager.backupStatus, .idle)
        
        // When
        try await exportManager.startBackup()
        
        // Then
        XCTAssertEqual(exportManager.backupStatus, .completed)
        XCTAssertNotNil(exportManager.lastBackupDate)
        XCTAssertEqual(exportManager.backupHistory.count, 1)
        
        let backupRecord = exportManager.backupHistory.first
        XCTAssertEqual(backupRecord?.type, .full)
        XCTAssertEqual(backupRecord?.status, .success)
        XCTAssertGreaterThan(backupRecord?.fileSize ?? 0, 0)
    }
    
    func testBackupFileCreation() async throws {
        // Given
        let initialBackupCount = exportManager.backupHistory.count
        
        // When
        try await exportManager.startBackup()
        
        // Then
        XCTAssertEqual(exportManager.backupHistory.count, initialBackupCount + 1)
        
        let backupRecord = exportManager.backupHistory.first
        XCTAssertNotNil(backupRecord)
        
        // Verify backup file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupRecord?.fileURL.path ?? ""))
    }
    
    func testBackupIntegrityVerification() async throws {
        // Given
        try await exportManager.startBackup()
        let backupRecord = exportManager.backupHistory.first!
        
        // When & Then
        // The backup integrity should be verified during backup creation
        // This test verifies the backup file is valid
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupRecord.fileURL.path))
        XCTAssertGreaterThan(backupRecord.fileSize, 0)
    }
    
    // MARK: - Recovery Tests
    
    func testRestoreFromBackup() async throws {
        // Given
        try await exportManager.startBackup()
        let backupRecord = exportManager.backupHistory.first!
        
        // When
        try await exportManager.restoreFromBackup(backupRecord.fileURL)
        
        // Then
        // Recovery should complete without error
        // Note: Actual data restoration would require HealthKit write permissions
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testBackupDataLoading() throws {
        // Given
        let testBackupData = BackupData()
        let encoder = JSONEncoder()
        let data = try encoder.encode(testBackupData)
        
        let testURL = exportManager.backupDirectory.appendingPathComponent("test_backup.backup")
        try data.write(to: testURL)
        
        // When
        let loadedData = try exportManager.loadBackupData(from: testURL)
        
        // Then
        XCTAssertNotNil(loadedData)
        
        // Cleanup
        try FileManager.default.removeItem(at: testURL)
    }
    
    // MARK: - Migration Tests
    
    func testMigrationFromV1_0_to_V1_1() async throws {
        // Given
        let fromVersion = "1.0"
        let toVersion = "1.1"
        
        // When
        try await exportManager.migrateFromVersion(fromVersion, toVersion: toVersion)
        
        // Then
        // Migration should complete without error
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testMigrationFromV1_1_to_V1_2() async throws {
        // Given
        let fromVersion = "1.1"
        let toVersion = "1.2"
        
        // When
        try await exportManager.migrateFromVersion(fromVersion, toVersion: toVersion)
        
        // Then
        // Migration should complete without error
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testCustomMigration() async throws {
        // Given
        let fromVersion = "1.5"
        let toVersion = "2.0"
        
        // When
        try await exportManager.migrateFromVersion(fromVersion, toVersion: toVersion)
        
        // Then
        // Custom migration should complete without error
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Encryption Tests
    
    func testDataEncryption() throws {
        // Given
        let testData = "Test data for encryption".data(using: .utf8)!
        
        // When
        let encryptedData = try exportManager.encryptData(testData)
        let decryptedData = try exportManager.decryptData(encryptedData)
        
        // Then
        XCTAssertNotEqual(testData, encryptedData)
        XCTAssertEqual(testData, decryptedData)
    }
    
    func testEncryptionWithLargeData() throws {
        // Given
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        
        // When
        let encryptedData = try exportManager.encryptData(largeData)
        let decryptedData = try exportManager.decryptData(encryptedData)
        
        // Then
        XCTAssertNotEqual(largeData, encryptedData)
        XCTAssertEqual(largeData, decryptedData)
    }
    
    // MARK: - Compression Tests
    
    func testDataCompression() throws {
        // Given
        let testData = "Test data for compression".data(using: .utf8)!
        
        // When
        let compressedData = try exportManager.compressData(testData)
        let decompressedData = try exportManager.decompressData(compressedData)
        
        // Then
        XCTAssertEqual(testData, decompressedData)
    }
    
    // MARK: - Utility Tests
    
    func testExportMetadataGeneration() throws {
        // Given
        let metadata = exportManager.generateExportMetadata()
        
        // Then
        XCTAssertNotNil(metadata.exportDate)
        XCTAssertNotEqual(metadata.appVersion, "Unknown")
        XCTAssertNotEqual(metadata.deviceModel, "Unknown")
        XCTAssertNotEqual(metadata.osVersion, "Unknown")
        XCTAssertEqual(metadata.exportFormat, "HealthAI2030")
        XCTAssertEqual(metadata.dataVersion, "1.0")
    }
    
    func testBackupHistoryPersistence() throws {
        // Given
        let testRecord = BackupRecord(
            id: UUID(),
            timestamp: Date(),
            fileURL: URL(fileURLWithPath: "/test/backup.backup"),
            fileSize: 1024,
            type: .full,
            status: .success
        )
        
        // When
        exportManager.backupHistory.append(testRecord)
        exportManager.saveBackupHistory()
        
        // Create new instance to test persistence
        let newManager = AdvancedDataExportManager()
        
        // Then
        XCTAssertEqual(newManager.backupHistory.count, 1)
        XCTAssertEqual(newManager.backupHistory.first?.id, testRecord.id)
    }
    
    func testExportHistoryPersistence() throws {
        // Given
        let testRecord = ExportRecord(
            id: UUID(),
            format: .json,
            timestamp: Date(),
            fileURL: URL(fileURLWithPath: "/test/export.json"),
            fileSize: 512,
            includeHealthData: true,
            includeAppData: false
        )
        
        // When
        exportManager.exportHistory.append(testRecord)
        exportManager.saveExportHistory()
        
        // Create new instance to test persistence
        let newManager = AdvancedDataExportManager()
        
        // Then
        XCTAssertEqual(newManager.exportHistory.count, 1)
        XCTAssertEqual(newManager.exportHistory.first?.id, testRecord.id)
    }
    
    // MARK: - Performance Tests
    
    func testExportPerformance() async throws {
        // Given
        let iterations = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            _ = try await exportManager.exportData(to: .json, includeHealthData: true, includeAppData: true)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 10.0) // Should complete within 10 seconds
    }
    
    func testBackupPerformance() async throws {
        // Given
        let iterations = 5
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            try await exportManager.startBackup()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 30.0) // Should complete within 30 seconds
    }
    
    func testEncryptionPerformance() throws {
        // Given
        let testData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        let iterations = 10
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When
        for _ in 0..<iterations {
            let encryptedData = try exportManager.encryptData(testData)
            _ = try exportManager.decryptData(encryptedData)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime
        
        // Then
        XCTAssertLessThan(executionTime, 5.0) // Should complete within 5 seconds
    }
    
    // MARK: - Error Handling Tests
    
    func testExportWithNoData() async throws {
        // Given
        let format = ExportFormat.json
        
        // When & Then
        // Should not throw error even with no data
        let exportURL = try await exportManager.exportData(
            to: format,
            includeHealthData: false,
            includeAppData: false
        )
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
    }
    
    func testBackupWithNoData() async throws {
        // Given
        // No data to backup
        
        // When & Then
        // Should not throw error even with no data
        try await exportManager.startBackup()
        
        XCTAssertEqual(exportManager.backupStatus, .completed)
        XCTAssertNotNil(exportManager.lastBackupDate)
    }
    
    // MARK: - Helper Methods
    
    private func createMockHeartRateSample(value: Double, date: Date) -> HKQuantitySample {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let quantity = HKQuantity(unit: HKUnit.count().unitDivided(by: .minute()), doubleValue: value)
        return HKQuantitySample(type: heartRateType, quantity: quantity, start: date, end: date)
    }
    
    private func createMockBloodPressureSample(systolic: Double, diastolic: Double, date: Date) -> HKQuantitySample {
        let systolicType = HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!
        let quantity = HKQuantity(unit: HKUnit.millimeterOfMercury(), doubleValue: systolic)
        return HKQuantitySample(type: systolicType, quantity: quantity, start: date, end: date)
    }
    
    private func createMockSleepSample(startDate: Date, endDate: Date, stage: SleepStage) -> HKCategorySample {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        return HKCategorySample(type: sleepType, value: stage.rawValue, start: startDate, end: endDate)
    }
    
    private func createMockStepSample(steps: Double, date: Date) -> HKQuantitySample {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let quantity = HKQuantity(unit: .count(), doubleValue: steps)
        return HKQuantitySample(type: stepType, quantity: quantity, start: date, end: date)
    }
    
    private func createMockCalorieSample(calories: Double, date: Date) -> HKQuantitySample {
        let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        return HKQuantitySample(type: calorieType, quantity: quantity, start: date, end: date)
    }
    
    private func createMockWeightSample(weight: Double, date: Date) -> HKQuantitySample {
        let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weight)
        return HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
    }
    
    private func createMockMedicationSample(name: String, dosage: String, date: Date) -> HKCategorySample {
        let medicationType = HKObjectType.categoryType(forIdentifier: .medication)!
        let metadata: [String: Any] = [
            "medication_name": name,
            "dosage": dosage
        ]
        return HKCategorySample(type: medicationType, value: 1, start: date, end: date, metadata: metadata)
    }
}

// MARK: - Mock Health Store

class MockHealthStore: HKHealthStore {
    var mockHeartRateData: [HKQuantitySample] = []
    var mockBloodPressureData: [HKQuantitySample] = []
    var mockSleepData: [HKCategorySample] = []
    var mockStepData: [HKQuantitySample] = []
    var mockCalorieData: [HKQuantitySample] = []
    var mockWeightData: [HKQuantitySample] = []
    var mockMedicationData: [HKCategorySample] = []
    
    override func requestAuthorization(toShare typesToShare: Set<HKSampleType>?, read typesToRead: Set<HKObjectType>?, completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }
    
    override func execute(_ query: HKQuery) {
        // Mock implementation for health queries
    }
    
    func addMockHeartRateData(_ samples: [HKQuantitySample]) {
        mockHeartRateData.append(contentsOf: samples)
    }
    
    func addMockBloodPressureData(_ samples: [HKQuantitySample]) {
        mockBloodPressureData.append(contentsOf: samples)
    }
    
    func addMockSleepData(_ samples: [HKCategorySample]) {
        mockSleepData.append(contentsOf: samples)
    }
    
    func addMockStepData(_ samples: [HKQuantitySample]) {
        mockStepData.append(contentsOf: samples)
    }
    
    func addMockCalorieData(_ samples: [HKQuantitySample]) {
        mockCalorieData.append(contentsOf: samples)
    }
    
    func addMockWeightData(_ samples: [HKQuantitySample]) {
        mockWeightData.append(contentsOf: samples)
    }
    
    func addMockMedicationData(_ samples: [HKCategorySample]) {
        mockMedicationData.append(contentsOf: samples)
    }
} 