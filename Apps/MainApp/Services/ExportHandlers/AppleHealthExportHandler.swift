import Foundation
import HealthKit

// MARK: - Apple Health Export Handler

@available(iOS 14.0, *)
class AppleHealthExportHandler: BaseExportHandler {
    
    override var fileExtension: String {
        return "xml"
    }
    
    override var mimeType: String {
        return "application/xml"
    }
    
    override func generateExport(
        data: ProcessedHealthData,
        request: ExportRequest,
        outputPath: URL,
        progressCallback: @escaping (Double) -> Void
    ) async throws {
        
        try validateData(data)
        
        let updateProgress = createProgressTracker(totalSteps: 5, callback: progressCallback)
        
        // Step 1: Create XML document structure
        updateProgress(1)
        let xmlDocument = createXMLDocumentStructure()
        
        // Step 2: Add export info and metadata
        updateProgress(2)
        try addExportInfo(to: xmlDocument, data: data, request: request)
        
        // Step 3: Convert health data to Apple Health format
        updateProgress(3)
        try addHealthData(to: xmlDocument, data: data, request: request)
        
        // Step 4: Add workouts and activities
        updateProgress(4)
        try addWorkoutsAndActivities(to: xmlDocument, data: data)
        
        // Step 5: Write XML to file
        updateProgress(5)
        try writeXMLDocument(xmlDocument, to: outputPath)
    }
    
    override func estimateFileSize(_ data: ProcessedHealthData) -> Int64 {
        // Apple Health XML is verbose: ~250 bytes per data point + structure
        let dataPointsSize = Int64(data.dataPoints.count * 250)
        let structureSize: Int64 = 10000 // Base XML structure
        return dataPointsSize + structureSize
    }
    
    // MARK: - XML Document Structure
    
    private func createXMLDocumentStructure() -> XMLDocument {
        let rootElement = XMLElement(name: "HealthData")
        rootElement.addAttribute(XMLNode.attribute(withName: "locale", stringValue: Locale.current.identifier) as! XMLNode)
        
        let document = XMLDocument(rootElement: rootElement)
        document.version = "1.0"
        document.characterEncoding = "UTF-8"
        document.isStandalone = true
        
        return document
    }
    
    // MARK: - Export Info
    
    private func addExportInfo(to document: XMLDocument, data: ProcessedHealthData, request: ExportRequest) throws {
        guard let root = document.rootElement() else {
            throw ExportError.fileGenerationError("Invalid XML document structure")
        }
        
        // Export date
        let exportDateElement = XMLElement(name: "ExportDate")
        exportDateElement.addAttribute(XMLNode.attribute(withName: "value", stringValue: formatAppleHealthDate(data.metadata.exportDate)) as! XMLNode)
        root.addChild(exportDateElement)
        
        // Me element (user info)
        let meElement = XMLElement(name: "Me")
        meElement.addAttribute(XMLNode.attribute(withName: "HKCharacteristicTypeIdentifierDateOfBirth", stringValue: "") as! XMLNode)
        meElement.addAttribute(XMLNode.attribute(withName: "HKCharacteristicTypeIdentifierBiologicalSex", stringValue: "") as! XMLNode)
        meElement.addAttribute(XMLNode.attribute(withName: "HKCharacteristicTypeIdentifierBloodType", stringValue: "") as! XMLNode)
        meElement.addAttribute(XMLNode.attribute(withName: "HKCharacteristicTypeIdentifierFitzpatrickSkinType", stringValue: "") as! XMLNode)
        root.addChild(meElement)
        
        // Export metadata
        let metadataElement = XMLElement(name: "Metadata")
        metadataElement.addAttribute(XMLNode.attribute(withName: "generatedBy", stringValue: data.metadata.generatedBy) as! XMLNode)
        metadataElement.addAttribute(XMLNode.attribute(withName: "appVersion", stringValue: data.metadata.appVersion) as! XMLNode)
        metadataElement.addAttribute(XMLNode.attribute(withName: "osVersion", stringValue: data.metadata.osVersion) as! XMLNode)
        metadataElement.addAttribute(XMLNode.attribute(withName: "deviceModel", stringValue: data.metadata.deviceModel) as! XMLNode)
        root.addChild(metadataElement)
    }
    
    // MARK: - Health Data Conversion
    
    private func addHealthData(to document: XMLDocument, data: ProcessedHealthData, request: ExportRequest) throws {
        guard let root = document.rootElement() else {
            throw ExportError.fileGenerationError("Invalid XML document structure")
        }
        
        // Group data by type for better organization
        let groupedData = Dictionary(grouping: data.dataPoints) { $0.dataType }
        
        for (dataType, points) in groupedData {
            for point in points {
                let recordElement = try createHealthRecord(from: point)
                root.addChild(recordElement)
            }
        }
    }
    
    private func createHealthRecord(from dataPoint: HealthDataPoint) throws -> XMLElement {
        let recordType = getAppleHealthRecordType(for: dataPoint.dataType)
        let recordElement = XMLElement(name: "Record")
        
        // Basic attributes
        recordElement.addAttribute(XMLNode.attribute(withName: "type", stringValue: recordType) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "sourceName", stringValue: dataPoint.source) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "sourceVersion", stringValue: "1.0") as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "device", stringValue: dataPoint.device ?? "Unknown") as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "unit", stringValue: dataPoint.unit) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "creationDate", stringValue: formatAppleHealthDate(dataPoint.startDate)) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "startDate", stringValue: formatAppleHealthDate(dataPoint.startDate)) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "endDate", stringValue: formatAppleHealthDate(dataPoint.endDate)) as! XMLNode)
        recordElement.addAttribute(XMLNode.attribute(withName: "value", stringValue: formatValue(dataPoint.value)) as! XMLNode)
        
        // Add metadata if present
        if !dataPoint.metadata.isEmpty {
            for (key, value) in dataPoint.metadata {
                let metadataEntry = XMLElement(name: "MetadataEntry")
                metadataEntry.addAttribute(XMLNode.attribute(withName: "key", stringValue: key) as! XMLNode)
                metadataEntry.addAttribute(XMLNode.attribute(withName: "value", stringValue: value) as! XMLNode)
                recordElement.addChild(metadataEntry)
            }
        }
        
        return recordElement
    }
    
    // MARK: - Workouts and Activities
    
    private func addWorkoutsAndActivities(to document: XMLDocument, data: ProcessedHealthData) throws {
        guard let root = document.rootElement() else {
            throw ExportError.fileGenerationError("Invalid XML document structure")
        }
        
        // Find workout-related data points
        let workoutPoints = data.dataPoints.filter { point in
            point.dataType == .workouts || 
            point.dataType == .activeEnergy || 
            point.dataType == .exerciseTime
        }
        
        // Group workout data by time proximity to create workout sessions
        let workoutSessions = groupWorkoutData(workoutPoints)
        
        for session in workoutSessions {
            let workoutElement = createWorkoutElement(from: session)
            root.addChild(workoutElement)
        }
    }
    
    private func groupWorkoutData(_ points: [HealthDataPoint]) -> [WorkoutSession] {
        // Simplified grouping - in a real implementation, you'd use more sophisticated logic
        var sessions: [WorkoutSession] = []
        
        let workoutTypePoints = points.filter { $0.dataType == .workouts }
        
        for workoutPoint in workoutTypePoints {
            let session = WorkoutSession(
                startDate: workoutPoint.startDate,
                endDate: workoutPoint.endDate,
                workoutType: inferWorkoutType(from: workoutPoint),
                duration: workoutPoint.endDate.timeIntervalSince(workoutPoint.startDate),
                totalEnergyBurned: findRelatedEnergyBurned(for: workoutPoint, in: points),
                dataPoints: [workoutPoint]
            )
            sessions.append(session)
        }
        
        return sessions
    }
    
    private func createWorkoutElement(from session: WorkoutSession) -> XMLElement {
        let workoutElement = XMLElement(name: "Workout")
        
        workoutElement.addAttribute(XMLNode.attribute(withName: "workoutActivityType", stringValue: session.workoutType) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "duration", stringValue: formatValue(session.duration)) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "durationUnit", stringValue: "s") as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "totalEnergyBurned", stringValue: formatValue(session.totalEnergyBurned ?? 0)) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "totalEnergyBurnedUnit", stringValue: "kcal") as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "creationDate", stringValue: formatAppleHealthDate(session.startDate)) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "startDate", stringValue: formatAppleHealthDate(session.startDate)) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "endDate", stringValue: formatAppleHealthDate(session.endDate)) as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "sourceName", stringValue: "HealthAI 2030") as! XMLNode)
        workoutElement.addAttribute(XMLNode.attribute(withName: "sourceVersion", stringValue: "1.0") as! XMLNode)
        
        return workoutElement
    }
    
    // MARK: - Helper Methods
    
    private func getAppleHealthRecordType(for dataType: HealthDataType) -> String {
        switch dataType {
        case .heartRate:
            return "HKQuantityTypeIdentifierHeartRate"
        case .bloodPressure:
            return "HKCorrelationTypeIdentifierBloodPressure"
        case .bodyTemperature:
            return "HKQuantityTypeIdentifierBodyTemperature"
        case .respiratoryRate:
            return "HKQuantityTypeIdentifierRespiratoryRate"
        case .oxygenSaturation:
            return "HKQuantityTypeIdentifierOxygenSaturation"
        case .steps:
            return "HKQuantityTypeIdentifierStepCount"
        case .distanceWalking:
            return "HKQuantityTypeIdentifierDistanceWalkingRunning"
        case .flightsClimbed:
            return "HKQuantityTypeIdentifierFlightsClimbed"
        case .activeEnergy:
            return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .basalEnergy:
            return "HKQuantityTypeIdentifierBasalEnergyBurned"
        case .exerciseTime:
            return "HKQuantityTypeIdentifierAppleExerciseTime"
        case .standTime:
            return "HKQuantityTypeIdentifierAppleStandTime"
        case .height:
            return "HKQuantityTypeIdentifierHeight"
        case .weight:
            return "HKQuantityTypeIdentifierBodyMass"
        case .bodyMassIndex:
            return "HKQuantityTypeIdentifierBodyMassIndex"
        case .bodyFatPercentage:
            return "HKQuantityTypeIdentifierBodyFatPercentage"
        case .leanBodyMass:
            return "HKQuantityTypeIdentifierLeanBodyMass"
        case .waistCircumference:
            return "HKQuantityTypeIdentifierWaistCircumference"
        case .dietaryWater:
            return "HKQuantityTypeIdentifierDietaryWater"
        case .dietaryCalories:
            return "HKQuantityTypeIdentifierDietaryEnergyConsumed"
        case .dietaryProtein:
            return "HKQuantityTypeIdentifierDietaryProtein"
        case .dietaryCarbohydrates:
            return "HKQuantityTypeIdentifierDietaryCarbohydrates"
        case .dietaryFat:
            return "HKQuantityTypeIdentifierDietaryFatTotal"
        case .dietaryFiber:
            return "HKQuantityTypeIdentifierDietaryFiber"
        case .dietarySugar:
            return "HKQuantityTypeIdentifierDietarySugar"
        case .dietarySodium:
            return "HKQuantityTypeIdentifierDietarySodium"
        case .sleepAnalysis:
            return "HKCategoryTypeIdentifierSleepAnalysis"
        case .sleepDuration, .sleepEfficiency, .timeInBed:
            return "HKCategoryTypeIdentifierSleepAnalysis"
        case .mindfulSession:
            return "HKCategoryTypeIdentifierMindfulSession"
        case .mood, .anxiety, .depression:
            return "HKCategoryTypeIdentifierMindfulSession" // Placeholder
        case .workouts:
            return "HKWorkoutTypeIdentifier"
        case .medicalRecords, .immunizations, .allergies, .medications:
            return "HKClinicalTypeIdentifierAllergyRecord"
        }
    }
    
    private func formatAppleHealthDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    private func inferWorkoutType(from dataPoint: HealthDataPoint) -> String {
        // Try to infer workout type from metadata or source
        if let workoutType = dataPoint.metadata["HKWorkoutActivityType"] {
            return workoutType
        }
        
        // Default workout types based on source or other indicators
        let source = dataPoint.source.lowercased()
        if source.contains("running") || source.contains("run") {
            return "HKWorkoutActivityTypeRunning"
        } else if source.contains("walking") || source.contains("walk") {
            return "HKWorkoutActivityTypeWalking"
        } else if source.contains("cycling") || source.contains("bike") {
            return "HKWorkoutActivityTypeCycling"
        } else if source.contains("swimming") || source.contains("swim") {
            return "HKWorkoutActivityTypeSwimming"
        } else {
            return "HKWorkoutActivityTypeOther"
        }
    }
    
    private func findRelatedEnergyBurned(for workoutPoint: HealthDataPoint, in allPoints: [HealthDataPoint]) -> Double? {
        // Find energy burned data points that overlap with the workout timeframe
        let energyPoints = allPoints.filter { $0.dataType == .activeEnergy }
        
        let overlappingPoints = energyPoints.filter { energyPoint in
            let workoutRange = workoutPoint.startDate...workoutPoint.endDate
            return workoutRange.contains(energyPoint.startDate) || workoutRange.contains(energyPoint.endDate)
        }
        
        return overlappingPoints.map { $0.value }.reduce(0, +)
    }
    
    private func writeXMLDocument(_ document: XMLDocument, to url: URL) throws {
        let xmlData = document.xmlData(options: [.nodePrettyPrint])
        try xmlData.write(to: url)
    }
}

// MARK: - Supporting Structures

private struct WorkoutSession {
    let startDate: Date
    let endDate: Date
    let workoutType: String
    let duration: TimeInterval
    let totalEnergyBurned: Double?
    let dataPoints: [HealthDataPoint]
}

// MARK: - XML Document Class

private class XMLDocument {
    var version: String?
    var characterEncoding: String?
    var isStandalone: Bool = false
    private var rootElement: XMLElement?
    
    init(rootElement: XMLElement? = nil) {
        self.rootElement = rootElement
    }
    
    func rootElement() -> XMLElement? {
        return rootElement
    }
    
    func xmlData(options: XMLDataOptions = []) -> Data {
        var xmlString = "<?xml version=\"\(version ?? "1.0")\" encoding=\"\(characterEncoding ?? "UTF-8")\""
        if isStandalone {
            xmlString += " standalone=\"yes\""
        }
        xmlString += "?>\n"
        
        if let root = rootElement {
            xmlString += root.xmlString(withOptions: options)
        }
        
        return xmlString.data(using: .utf8) ?? Data()
    }
}

private class XMLElement {
    let name: String
    private var attributes: [String: String] = [:]
    private var children: [XMLElement] = []
    
    init(name: String) {
        self.name = name
    }
    
    func addAttribute(_ attribute: XMLNode) {
        if let name = attribute.name, let value = attribute.stringValue {
            attributes[name] = value
        }
    }
    
    func addChild(_ child: XMLElement) {
        children.append(child)
    }
    
    func xmlString(withOptions options: XMLDataOptions = []) -> String {
        let prettyPrint = options.contains(.nodePrettyPrint)
        let indent = prettyPrint ? "  " : ""
        
        var xmlString = "<\(name)"
        
        // Add attributes
        for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
            xmlString += " \(key)=\"\(value.xmlEscaped)\""
        }
        
        if children.isEmpty {
            xmlString += "/>"
        } else {
            xmlString += ">"
            
            if prettyPrint {
                xmlString += "\n"
            }
            
            for child in children {
                if prettyPrint {
                    let childString = child.xmlString(withOptions: options)
                    xmlString += childString.components(separatedBy: "\n").map { indent + $0 }.joined(separator: "\n")
                    xmlString += "\n"
                } else {
                    xmlString += child.xmlString(withOptions: options)
                }
            }
            
            xmlString += "</\(name)>"
        }
        
        return xmlString
    }
}

private class XMLNode {
    let name: String?
    let stringValue: String?
    
    init(name: String?, stringValue: String?) {
        self.name = name
        self.stringValue = stringValue
    }
    
    static func attribute(withName name: String, stringValue: String) -> XMLNode {
        return XMLNode(name: name, stringValue: stringValue)
    }
}

private struct XMLDataOptions: OptionSet {
    let rawValue: Int
    
    static let nodePrettyPrint = XMLDataOptions(rawValue: 1 << 0)
}

// MARK: - String Extensions

private extension String {
    var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Apple Health Export Options

extension ExportRequest {
    /// Get Apple Health-specific export options
    var appleHealthExportOptions: AppleHealthExportOptions {
        return AppleHealthExportOptions(
            includeWorkouts: customOptions["includeWorkouts"] != "false",
            includeMetadata: privacySettings.includeMetadata,
            groupWorkouts: customOptions["groupWorkouts"] != "false",
            preserveSourceInfo: !privacySettings.anonymizeData
        )
    }
}

struct AppleHealthExportOptions {
    let includeWorkouts: Bool
    let includeMetadata: Bool
    let groupWorkouts: Bool
    let preserveSourceInfo: Bool
    
    init(includeWorkouts: Bool = true, includeMetadata: Bool = true, groupWorkouts: Bool = true, preserveSourceInfo: Bool = true) {
        self.includeWorkouts = includeWorkouts
        self.includeMetadata = includeMetadata
        self.groupWorkouts = groupWorkouts
        self.preserveSourceInfo = preserveSourceInfo
    }
}