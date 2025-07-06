import Foundation
import HealthKit

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Codable {
    case json = "JSON"
    case csv = "CSV"
    case pdf = "PDF"
    case appleHealth = "Apple Health"
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .pdf: return "pdf"
        case .appleHealth: return "xml"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .pdf: return "application/pdf"
        case .appleHealth: return "application/xml"
        }
    }
    
    var displayName: String {
        return rawValue
    }
    
    var description: String {
        switch self {
        case .json:
            return "Structured data format ideal for developers and data analysis"
        case .csv:
            return "Spreadsheet-compatible format for easy viewing and analysis"
        case .pdf:
            return "Professional health report with charts and visualizations"
        case .appleHealth:
            return "Native Apple Health format for importing to other devices"
        }
    }
    
    var supportsCharts: Bool {
        return self == .pdf
    }
    
    var supportsCompression: Bool {
        switch self {
        case .json, .csv, .appleHealth: return true
        case .pdf: return false
        }
    }
}

// MARK: - Health Data Types

enum HealthDataType: String, CaseIterable, Codable {
    // Vitals
    case heartRate = "Heart Rate"
    case bloodPressure = "Blood Pressure"
    case bodyTemperature = "Body Temperature"
    case respiratoryRate = "Respiratory Rate"
    case oxygenSaturation = "Oxygen Saturation"
    
    // Activity
    case steps = "Steps"
    case distanceWalking = "Walking Distance"
    case flightsClimbed = "Flights Climbed"
    case activeEnergy = "Active Energy"
    case basalEnergy = "Basal Energy"
    case exerciseTime = "Exercise Time"
    case standTime = "Stand Time"
    
    // Body Measurements
    case height = "Height"
    case weight = "Weight"
    case bodyMassIndex = "Body Mass Index"
    case bodyFatPercentage = "Body Fat Percentage"
    case leanBodyMass = "Lean Body Mass"
    case waistCircumference = "Waist Circumference"
    
    // Nutrition
    case dietaryWater = "Water Intake"
    case dietaryCalories = "Calories"
    case dietaryProtein = "Protein"
    case dietaryCarbohydrates = "Carbohydrates"
    case dietaryFat = "Fat"
    case dietaryFiber = "Fiber"
    case dietarySugar = "Sugar"
    case dietarySodium = "Sodium"
    
    // Sleep
    case sleepAnalysis = "Sleep Analysis"
    case sleepDuration = "Sleep Duration"
    case sleepEfficiency = "Sleep Efficiency"
    case timeInBed = "Time in Bed"
    
    // Mental Health
    case mindfulSession = "Mindful Minutes"
    case mood = "Mood"
    case anxiety = "Anxiety"
    case depression = "Depression"
    
    // Workouts
    case workouts = "Workouts"
    
    // Health Records
    case medicalRecords = "Medical Records"
    case immunizations = "Immunizations"
    case allergies = "Allergies"
    case medications = "Medications"
    
    var category: HealthDataCategory {
        switch self {
        case .heartRate, .bloodPressure, .bodyTemperature, .respiratoryRate, .oxygenSaturation:
            return .vitals
        case .steps, .distanceWalking, .flightsClimbed, .activeEnergy, .basalEnergy, .exerciseTime, .standTime:
            return .activity
        case .height, .weight, .bodyMassIndex, .bodyFatPercentage, .leanBodyMass, .waistCircumference:
            return .bodyMeasurements
        case .dietaryWater, .dietaryCalories, .dietaryProtein, .dietaryCarbohydrates, .dietaryFat, .dietaryFiber, .dietarySugar, .dietarySodium:
            return .nutrition
        case .sleepAnalysis, .sleepDuration, .sleepEfficiency, .timeInBed:
            return .sleep
        case .mindfulSession, .mood, .anxiety, .depression:
            return .mentalHealth
        case .workouts:
            return .workouts
        case .medicalRecords, .immunizations, .allergies, .medications:
            return .healthRecords
        }
    }
    
    var unit: String {
        switch self {
        case .heartRate: return "bpm"
        case .bloodPressure: return "mmHg"
        case .bodyTemperature: return "°F"
        case .respiratoryRate: return "breaths/min"
        case .oxygenSaturation: return "%"
        case .steps: return "steps"
        case .distanceWalking: return "miles"
        case .flightsClimbed: return "flights"
        case .activeEnergy, .basalEnergy, .dietaryCalories: return "cal"
        case .exerciseTime, .standTime, .mindfulSession: return "min"
        case .height: return "ft"
        case .weight, .leanBodyMass: return "lbs"
        case .bodyMassIndex: return "kg/m²"
        case .bodyFatPercentage: return "%"
        case .waistCircumference: return "in"
        case .dietaryWater: return "fl oz"
        case .dietaryProtein, .dietaryCarbohydrates, .dietaryFat, .dietaryFiber, .dietarySugar, .dietarySodium: return "g"
        case .sleepAnalysis, .sleepDuration, .sleepEfficiency, .timeInBed: return "hours"
        case .mood, .anxiety, .depression: return "score"
        case .workouts, .medicalRecords, .immunizations, .allergies, .medications: return "count"
        }
    }
    
    var hkSampleType: HKSampleType {
        switch self {
        case .heartRate: return HKSampleType.quantityType(forIdentifier: .heartRate)!
        case .bloodPressure: return HKSampleType.correlationType(forIdentifier: .bloodPressure)!
        case .bodyTemperature: return HKSampleType.quantityType(forIdentifier: .bodyTemperature)!
        case .respiratoryRate: return HKSampleType.quantityType(forIdentifier: .respiratoryRate)!
        case .oxygenSaturation: return HKSampleType.quantityType(forIdentifier: .oxygenSaturation)!
        case .steps: return HKSampleType.quantityType(forIdentifier: .stepCount)!
        case .distanceWalking: return HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
        case .flightsClimbed: return HKSampleType.quantityType(forIdentifier: .flightsClimbed)!
        case .activeEnergy: return HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
        case .basalEnergy: return HKSampleType.quantityType(forIdentifier: .basalEnergyBurned)!
        case .exerciseTime: return HKSampleType.quantityType(forIdentifier: .appleExerciseTime)!
        case .standTime: return HKSampleType.quantityType(forIdentifier: .appleStandTime)!
        case .height: return HKSampleType.quantityType(forIdentifier: .height)!
        case .weight: return HKSampleType.quantityType(forIdentifier: .bodyMass)!
        case .bodyMassIndex: return HKSampleType.quantityType(forIdentifier: .bodyMassIndex)!
        case .bodyFatPercentage: return HKSampleType.quantityType(forIdentifier: .bodyFatPercentage)!
        case .leanBodyMass: return HKSampleType.quantityType(forIdentifier: .leanBodyMass)!
        case .waistCircumference: return HKSampleType.quantityType(forIdentifier: .waistCircumference)!
        case .dietaryWater: return HKSampleType.quantityType(forIdentifier: .dietaryWater)!
        case .dietaryCalories: return HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        case .dietaryProtein: return HKSampleType.quantityType(forIdentifier: .dietaryProtein)!
        case .dietaryCarbohydrates: return HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        case .dietaryFat: return HKSampleType.quantityType(forIdentifier: .dietaryFatTotal)!
        case .dietaryFiber: return HKSampleType.quantityType(forIdentifier: .dietaryFiber)!
        case .dietarySugar: return HKSampleType.quantityType(forIdentifier: .dietarySugar)!
        case .dietarySodium: return HKSampleType.quantityType(forIdentifier: .dietarySodium)!
        case .sleepAnalysis: return HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        case .sleepDuration, .sleepEfficiency, .timeInBed: return HKSampleType.categoryType(forIdentifier: .sleepAnalysis)!
        case .mindfulSession: return HKSampleType.categoryType(forIdentifier: .mindfulSession)!
        case .mood, .anxiety, .depression: return HKSampleType.categoryType(forIdentifier: .mindfulSession)! // Placeholder
        case .workouts: return HKSampleType.workoutType()
        case .medicalRecords, .immunizations, .allergies, .medications: return HKSampleType.clinicalType(forIdentifier: .allergyRecord)!
        }
    }
}

enum HealthDataCategory: String, CaseIterable, Codable {
    case vitals = "Vitals"
    case activity = "Activity"
    case bodyMeasurements = "Body Measurements"
    case nutrition = "Nutrition"
    case sleep = "Sleep"
    case mentalHealth = "Mental Health"
    case workouts = "Workouts"
    case healthRecords = "Health Records"
    
    var icon: String {
        switch self {
        case .vitals: return "heart.fill"
        case .activity: return "figure.walk"
        case .bodyMeasurements: return "scalemass.fill"
        case .nutrition: return "fork.knife"
        case .sleep: return "moon.zzz"
        case .mentalHealth: return "brain.head.profile"
        case .workouts: return "dumbbell.fill"
        case .healthRecords: return "doc.text.fill"
        }
    }
    
    var dataTypes: [HealthDataType] {
        return HealthDataType.allCases.filter { $0.category == self }
    }
}

// MARK: - Date Range

struct DateRange: Codable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    static func lastDays(_ days: Int) -> DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static func lastWeeks(_ weeks: Int) -> DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .weekOfYear, value: -weeks, to: endDate) ?? endDate
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static func lastMonths(_ months: Int) -> DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: -months, to: endDate) ?? endDate
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    static func lastYear() -> DateRange {
        return lastMonths(12)
    }
    
    static func allTime() -> DateRange {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        return DateRange(startDate: startDate, endDate: endDate)
    }
    
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    var dayCount: Int {
        return Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

// MARK: - Privacy Settings

struct ExportPrivacySettings: Codable {
    let anonymizeData: Bool
    let excludeSensitiveData: Bool
    let includeMetadata: Bool
    let includeDeviceInfo: Bool
    
    init(anonymizeData: Bool = false, excludeSensitiveData: Bool = false, includeMetadata: Bool = true, includeDeviceInfo: Bool = true) {
        self.anonymizeData = anonymizeData
        self.excludeSensitiveData = excludeSensitiveData
        self.includeMetadata = includeMetadata
        self.includeDeviceInfo = includeDeviceInfo
    }
    
    static let `default` = ExportPrivacySettings()
    static let anonymous = ExportPrivacySettings(anonymizeData: true, excludeSensitiveData: true, includeMetadata: false, includeDeviceInfo: false)
}

// MARK: - Encryption Settings

struct ExportEncryptionSettings: Codable {
    let encryptFile: Bool
    let password: String
    let useSecureEncryption: Bool
    
    init(encryptFile: Bool = false, password: String = "", useSecureEncryption: Bool = true) {
        self.encryptFile = encryptFile
        self.password = password
        self.useSecureEncryption = useSecureEncryption
    }
    
    static let none = ExportEncryptionSettings()
    static func encrypted(password: String) -> ExportEncryptionSettings {
        return ExportEncryptionSettings(encryptFile: true, password: password)
    }
}

// MARK: - Export Request

struct ExportRequest: Codable {
    let id: String
    let format: ExportFormat
    let dataTypes: [HealthDataType]
    let dateRange: DateRange
    let privacySettings: ExportPrivacySettings
    let encryptionSettings: ExportEncryptionSettings
    let customOptions: [String: String]
    let requestedBy: String
    let requestTime: Date
    
    init(
        format: ExportFormat,
        dataTypes: [HealthDataType] = [],
        dateRange: DateRange,
        privacySettings: ExportPrivacySettings = .default,
        encryptionSettings: ExportEncryptionSettings = .none,
        customOptions: [String: String] = [:],
        requestedBy: String = "User"
    ) {
        self.id = UUID().uuidString
        self.format = format
        self.dataTypes = dataTypes
        self.dateRange = dateRange
        self.privacySettings = privacySettings
        self.encryptionSettings = encryptionSettings
        self.customOptions = customOptions
        self.requestedBy = requestedBy
        self.requestTime = Date()
    }
    
    var isAllDataTypes: Bool {
        return dataTypes.isEmpty
    }
    
    var effectiveDataTypes: [HealthDataType] {
        return dataTypes.isEmpty ? HealthDataType.allCases : dataTypes
    }
    
    var displayName: String {
        let dataTypeCount = effectiveDataTypes.count
        let dataTypeText = dataTypeCount == HealthDataType.allCases.count ? "All Data" : "\(dataTypeCount) Data Types"
        return "\(format.displayName) - \(dataTypeText) - \(dateRange.displayString)"
    }
}

// MARK: - Export Progress

struct ExportProgress: Codable {
    let id: String
    let request: ExportRequest
    var status: ExportStatus
    let startTime: Date
    var progress: Double // 0.0 to 1.0
    var estimatedTimeRemaining: TimeInterval?
    var currentStep: String?
    var recordsProcessed: Int?
    var totalRecords: Int?
    
    init(id: String, request: ExportRequest, status: ExportStatus, startTime: Date, progress: Double, estimatedTimeRemaining: TimeInterval?) {
        self.id = id
        self.request = request
        self.status = status
        self.startTime = startTime
        self.progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var elapsedTime: TimeInterval {
        return Date().timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        return status == .preparing || status == .inProgress
    }
}

// MARK: - Export Status

enum ExportStatus: String, Codable, CaseIterable {
    case preparing = "Preparing"
    case inProgress = "In Progress"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    var isTerminal: Bool {
        return self != .preparing && self != .inProgress
    }
    
    var color: String {
        switch self {
        case .preparing, .inProgress: return "blue"
        case .completed: return "green"
        case .failed: return "red"
        case .cancelled: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .preparing: return "clock"
        case .inProgress: return "arrow.clockwise"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "stop.circle.fill"
        }
    }
}

// MARK: - Export Result

struct ExportResult: Codable, Identifiable {
    let id: String
    let request: ExportRequest
    let status: ExportStatus
    let startTime: Date
    let endTime: Date
    let filePath: URL?
    let fileSize: Int64
    let recordCount: Int
    let error: ExportError?
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var isSuccessful: Bool {
        return status == .completed
    }
    
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    var displayName: String {
        return request.displayName
    }
}

// MARK: - Export Estimate

struct ExportEstimate {
    let recordCount: Int
    let estimatedFileSize: Int64
    let estimatedDuration: TimeInterval
    
    var fileSizeFormatted: String {
        return ByteCountFormatter.string(fromByteCount: estimatedFileSize, countStyle: .file)
    }
    
    var durationFormatted: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: estimatedDuration) ?? "0s"
    }
}

// MARK: - Export Error

enum ExportError: Error, Codable {
    case exportInProgress
    case exportNotFound
    case invalidDateRange
    case futureDateNotAllowed
    case dateRangeTooLarge
    case encryptionPasswordRequired
    case healthKitError(Error)
    case fileSystemError(Error)
    case encryptionError(Error)
    case insufficientStorage
    case networkError
    case unknown(Error)
    
    var localizedDescription: String {
        switch self {
        case .exportInProgress:
            return "An export is already in progress. Please wait for it to complete or cancel it first."
        case .exportNotFound:
            return "The requested export could not be found."
        case .invalidDateRange:
            return "The start date must be before the end date."
        case .futureDateNotAllowed:
            return "Export dates cannot be in the future."
        case .dateRangeTooLarge:
            return "The date range is too large. Please select a range of 10 years or less."
        case .encryptionPasswordRequired:
            return "A password is required for encrypted exports."
        case .healthKitError(let error):
            return "HealthKit error: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .encryptionError(let error):
            return "Encryption error: \(error.localizedDescription)"
        case .insufficientStorage:
            return "Insufficient storage space to complete the export."
        case .networkError:
            return "Network error occurred during export."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .exportInProgress:
            return "Please wait for the current export to finish."
        case .exportNotFound:
            return "This export is no longer available."
        case .invalidDateRange, .futureDateNotAllowed, .dateRangeTooLarge:
            return "Please select a valid date range."
        case .encryptionPasswordRequired:
            return "Please provide a password for encryption."
        case .healthKitError:
            return "Unable to access health data. Please check your permissions."
        case .fileSystemError, .insufficientStorage:
            return "Unable to save the export file. Please free up storage space."
        case .encryptionError:
            return "Unable to encrypt the file. Please try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .exportInProgress, .exportNotFound, .invalidDateRange, .futureDateNotAllowed, .dateRangeTooLarge, .encryptionPasswordRequired:
            return false
        case .healthKitError, .fileSystemError, .encryptionError, .insufficientStorage, .networkError, .unknown:
            return true
        }
    }
}

// MARK: - Health Data Point

struct HealthDataPoint: Codable {
    let id: String
    let dataType: HealthDataType
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
    let source: String
    let device: String?
    let metadata: [String: String]
    
    static func fromHKSample(_ sample: HKSample, dataType: HealthDataType) -> HealthDataPoint? {
        var value: Double = 0.0
        var unit = dataType.unit
        
        if let quantitySample = sample as? HKQuantitySample {
            let hkUnit = quantitySample.quantityType.preferredUnit
            value = quantitySample.quantity.doubleValue(for: hkUnit)
            unit = hkUnit.unitString
        } else if let categorySample = sample as? HKCategorySample {
            value = Double(categorySample.value)
        } else if let workoutSample = sample as? HKWorkout {
            value = workoutSample.duration
            unit = "seconds"
        }
        
        return HealthDataPoint(
            id: sample.uuid.uuidString,
            dataType: dataType,
            value: value,
            unit: unit,
            startDate: sample.startDate,
            endDate: sample.endDate,
            source: sample.sourceRevision.source.name,
            device: sample.device?.name,
            metadata: sample.metadata?.compactMapValues { "\($0)" } ?? [:]
        )
    }
}

// MARK: - Processed Health Data

struct ProcessedHealthData: Codable {
    let dataPoints: [HealthDataPoint]
    let summary: HealthDataSummary
    let metadata: ExportMetadata
    
    var recordCount: Int {
        return dataPoints.count
    }
}

struct HealthDataSummary: Codable {
    let totalRecords: Int
    let dateRange: DateRange
    let dataTypeBreakdown: [HealthDataType: Int]
    let sourceBreakdown: [String: Int]
    
    init(dataPoints: [HealthDataPoint], dateRange: DateRange) {
        self.totalRecords = dataPoints.count
        self.dateRange = dateRange
        
        self.dataTypeBreakdown = Dictionary(grouping: dataPoints, by: { $0.dataType })
            .mapValues { $0.count }
        
        self.sourceBreakdown = Dictionary(grouping: dataPoints, by: { $0.source })
            .mapValues { $0.count }
    }
}

struct ExportMetadata: Codable {
    let exportId: String
    let exportDate: Date
    let appVersion: String
    let osVersion: String
    let deviceModel: String
    let exportFormat: ExportFormat
    let privacySettings: ExportPrivacySettings
    let generatedBy: String
    
    init(exportId: String, exportFormat: ExportFormat, privacySettings: ExportPrivacySettings) {
        self.exportId = exportId
        self.exportDate = Date()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.osVersion = UIDevice.current.systemVersion
        self.deviceModel = UIDevice.current.model
        self.exportFormat = exportFormat
        self.privacySettings = privacySettings
        self.generatedBy = "HealthAI 2030"
    }
}