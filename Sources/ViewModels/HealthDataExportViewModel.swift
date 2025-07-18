import SwiftUI
import Combine
import Foundation

@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
@MainActor
class HealthDataExportViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Export State
    @Published var isExporting = false
    @Published var currentExport: ExportProgress?
    @Published var exportHistory: [ExportResult] = []
    @Published var lastError: ExportError?
    
    // Format Selection
    @Published var selectedFormat: ExportFormat = .json
    @Published var availableFormats: [ExportFormat] = ExportFormat.allCases
    
    // Data Type Selection
    @Published var selectedDataTypes: Set<HealthDataType> = Set(HealthDataType.allCases)
    @Published var isAllDataTypesSelected = true
    @Published var dataTypesByCategory: [HealthDataCategory: [HealthDataType]] = [:]
    
    // Date Range Selection
    @Published var selectedDateRange: DateRange = DateRange.lastDays(30)
    @Published var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var customEndDate = Date()
    @Published var isCustomDateRange = false
    
    // Privacy Settings
    @Published var privacySettings = ExportPrivacySettings.default
    @Published var showPrivacyOptions = false
    
    // Encryption Settings
    @Published var encryptionSettings = ExportEncryptionSettings.none
    @Published var showEncryptionOptions = false
    @Published var encryptionPassword = ""
    @Published var confirmPassword = ""
    
    // UI State
    @Published var showingExportSheet = false
    @Published var showingHistorySheet = false
    @Published var showingErrorAlert = false
    @Published var showingDeleteConfirmation = false
    @Published var selectedExportForDeletion: ExportResult?
    
    // Progress and Estimates
    @Published var estimatedExport: ExportEstimate?
    @Published var isCalculatingEstimate = false
    
    // MARK: - Private Properties
    
    private let exportManager = HealthDataExportManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupDataTypesByCategory()
        setupObservers()
        loadExportHistory()
    }
    
    // MARK: - Setup Methods
    
    private func setupDataTypesByCategory() {
        dataTypesByCategory = Dictionary(grouping: HealthDataType.allCases) { $0.category }
    }
    
    private func setupObservers() {
        // Observe export manager state
        exportManager.$isExporting
            .receive(on: DispatchQueue.main)
            .assign(to: \.isExporting, on: self)
            .store(in: &cancellables)
        
        exportManager.$currentExport
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentExport, on: self)
            .store(in: &cancellables)
        
        exportManager.$exportHistory
            .receive(on: DispatchQueue.main)
            .assign(to: \.exportHistory, on: self)
            .store(in: &cancellables)
        
        exportManager.$lastError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.lastError = error
                if error != nil {
                    self?.showingErrorAlert = true
                }
            }
            .store(in: &cancellables)
        
        // Auto-calculate estimates when parameters change
        Publishers.CombineLatest4(
            $selectedFormat,
            $selectedDataTypes,
            $selectedDateRange.removeDuplicates { $0.startDate == $1.startDate && $0.endDate == $1.endDate },
            $isCustomDateRange
        )
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.calculateEstimate()
            }
        }
        .store(in: &cancellables)
        
        // Update date range when custom dates change
        Publishers.CombineLatest($customStartDate, $customEndDate)
            .sink { [weak self] startDate, endDate in
                if self?.isCustomDateRange == true {
                    self?.selectedDateRange = DateRange(startDate: startDate, endDate: endDate)
                }
            }
            .store(in: &cancellables)
        
        // Validate encryption passwords
        Publishers.CombineLatest($encryptionPassword, $confirmPassword)
            .sink { [weak self] password, confirm in
                if self?.encryptionSettings.encryptFile == true {
                    let isValid = !password.isEmpty && password == confirm
                    if isValid {
                        self?.encryptionSettings = .encrypted(password: password)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadExportHistory() {
        // Export history is automatically loaded through the observable
    }
    
    // MARK: - Public Methods
    
    func startExport() async {
        do {
            let request = createExportRequest()
            let exportId = try await exportManager.startExport(request)
            print("Export started with ID: \(exportId)")
        } catch {
            lastError = error as? ExportError ?? ExportError.unknown(error)
            showingErrorAlert = true
        }
    }
    
    func cancelExport() {
        exportManager.cancelExport()
    }
    
    func deleteExport(_ exportResult: ExportResult) async {
        do {
            try await exportManager.deleteExport(id: exportResult.id)
        } catch {
            lastError = error as? ExportError ?? ExportError.unknown(error)
            showingErrorAlert = true
        }
    }
    
    func retryExport(_ exportResult: ExportResult) async {
        await startExport()
    }
    
    func shareExport(_ exportResult: ExportResult) -> [URL] {
        guard let filePath = exportResult.filePath else { return [] }
        return [filePath]
    }
    
    // MARK: - Data Type Selection Methods
    
    func selectAllDataTypes() {
        selectedDataTypes = Set(HealthDataType.allCases)
        isAllDataTypesSelected = true
    }
    
    func deselectAllDataTypes() {
        selectedDataTypes.removeAll()
        isAllDataTypesSelected = false
    }
    
    func toggleDataType(_ dataType: HealthDataType) {
        if selectedDataTypes.contains(dataType) {
            selectedDataTypes.remove(dataType)
        } else {
            selectedDataTypes.insert(dataType)
        }
        updateAllDataTypesSelection()
    }
    
    func toggleDataTypeCategory(_ category: HealthDataCategory) {
        let categoryDataTypes = dataTypesByCategory[category] ?? []
        let isAllSelected = categoryDataTypes.allSatisfy { selectedDataTypes.contains($0) }
        
        if isAllSelected {
            // Deselect all in category
            categoryDataTypes.forEach { selectedDataTypes.remove($0) }
        } else {
            // Select all in category
            categoryDataTypes.forEach { selectedDataTypes.insert($0) }
        }
        updateAllDataTypesSelection()
    }
    
    private func updateAllDataTypesSelection() {
        isAllDataTypesSelected = selectedDataTypes.count == HealthDataType.allCases.count
    }
    
    func isCategoryFullySelected(_ category: HealthDataCategory) -> Bool {
        let categoryDataTypes = dataTypesByCategory[category] ?? []
        return categoryDataTypes.allSatisfy { selectedDataTypes.contains($0) }
    }
    
    func isCategoryPartiallySelected(_ category: HealthDataCategory) -> Bool {
        let categoryDataTypes = dataTypesByCategory[category] ?? []
        let selectedInCategory = categoryDataTypes.filter { selectedDataTypes.contains($0) }
        return !selectedInCategory.isEmpty && selectedInCategory.count < categoryDataTypes.count
    }
    
    // MARK: - Date Range Methods
    
    func selectPredefinedDateRange(_ range: DateRange) {
        selectedDateRange = range
        isCustomDateRange = false
    }
    
    func selectCustomDateRange() {
        isCustomDateRange = true
        selectedDateRange = DateRange(startDate: customStartDate, endDate: customEndDate)
    }
    
    func setQuickDateRange(_ days: Int) {
        let range = DateRange.lastDays(days)
        selectPredefinedDateRange(range)
    }
    
    // MARK: - Privacy and Encryption Methods
    
    func togglePrivacyOption(_ keyPath: WritableKeyPath<ExportPrivacySettings, Bool>) {
        privacySettings[keyPath: keyPath].toggle()
    }
    
    func enableEncryption() {
        encryptionSettings = ExportEncryptionSettings(encryptFile: true, password: "", useSecureEncryption: true)
        showEncryptionOptions = true
    }
    
    func disableEncryption() {
        encryptionSettings = .none
        encryptionPassword = ""
        confirmPassword = ""
        showEncryptionOptions = false
    }
    
    // MARK: - Validation Methods
    
    var canStartExport: Bool {
        return !isExporting &&
               !selectedDataTypes.isEmpty &&
               selectedDateRange.startDate <= selectedDateRange.endDate &&
               (!encryptionSettings.encryptFile || isEncryptionValid)
    }
    
    var isEncryptionValid: Bool {
        return !encryptionSettings.encryptFile ||
               (!encryptionPassword.isEmpty && encryptionPassword == confirmPassword)
    }
    
    var exportValidationMessage: String? {
        if selectedDataTypes.isEmpty {
            return "Please select at least one data type to export."
        }
        
        if selectedDateRange.startDate > selectedDateRange.endDate {
            return "Start date must be before end date."
        }
        
        if selectedDateRange.endDate > Date() {
            return "End date cannot be in the future."
        }
        
        let daysBetween = Calendar.current.dateComponents([.day], from: selectedDateRange.startDate, to: selectedDateRange.endDate).day ?? 0
        if daysBetween > 3650 {
            return "Date range cannot exceed 10 years."
        }
        
        if encryptionSettings.encryptFile && encryptionPassword.isEmpty {
            return "Encryption password is required."
        }
        
        if encryptionSettings.encryptFile && encryptionPassword != confirmPassword {
            return "Encryption passwords do not match."
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func createExportRequest() -> ExportRequest {
        let dataTypes = isAllDataTypesSelected ? [] : Array(selectedDataTypes)
        
        return ExportRequest(
            format: selectedFormat,
            dataTypes: dataTypes,
            dateRange: selectedDateRange,
            privacySettings: privacySettings,
            encryptionSettings: encryptionSettings,
            customOptions: [:],
            requestedBy: "User"
        )
    }
    
    private func calculateEstimate() async {
        isCalculatingEstimate = true
        
        let request = createExportRequest()
        let estimate = await exportManager.estimateExport(request)
        
        estimatedExport = estimate
        isCalculatingEstimate = false
    }
    
    // MARK: - Computed Properties
    
    var selectedDataTypesCount: Int {
        return selectedDataTypes.count
    }
    
    var selectedDataTypesDescription: String {
        if isAllDataTypesSelected {
            return "All Data Types (\(HealthDataType.allCases.count))"
        } else if selectedDataTypes.isEmpty {
            return "No Data Types Selected"
        } else {
            return "\(selectedDataTypes.count) Data Types Selected"
        }
    }
    
    var dateRangeDescription: String {
        if isCustomDateRange {
            return "Custom: \(selectedDateRange.displayString)"
        } else {
            // Determine which predefined range this matches
            if selectedDateRange.dayCount <= 1 {
                return "Today"
            } else if selectedDateRange.dayCount <= 7 {
                return "Last 7 Days"
            } else if selectedDateRange.dayCount <= 30 {
                return "Last 30 Days"
            } else if selectedDateRange.dayCount <= 90 {
                return "Last 3 Months"
            } else if selectedDateRange.dayCount <= 365 {
                return "Last Year"
            } else {
                return "Custom Range"
            }
        }
    }
    
    var exportSummary: String {
        let format = selectedFormat.displayName
        let dataTypeText = selectedDataTypesDescription
        let dateText = dateRangeDescription
        
        return "\(format) export with \(dataTypeText) for \(dateText)"
    }
    
    var progressPercentage: Double {
        return currentExport?.progress ?? 0.0
    }
    
    var progressDescription: String {
        guard let export = currentExport else { return "" }
        
        if let step = export.currentStep {
            return step
        }
        
        switch export.status {
        case .preparing:
            return "Preparing export..."
        case .inProgress:
            return "Exporting data..."
        case .completed:
            return "Export completed"
        case .failed:
            return "Export failed"
        case .cancelled:
            return "Export cancelled"
        }
    }
    
    var timeRemainingDescription: String {
        guard let export = currentExport,
              let timeRemaining = export.estimatedTimeRemaining,
              timeRemaining > 0 else {
            return ""
        }
        
        let minutes = Int(timeRemaining / 60)
        let seconds = Int(timeRemaining.truncatingRemainder(dividingBy: 60))
        
        if minutes > 0 {
            return "\(minutes)m \(seconds)s remaining"
        } else {
            return "\(seconds)s remaining"
        }
    }
    
    // MARK: - Error Handling
    
    func dismissError() {
        lastError = nil
        showingErrorAlert = false
    }
    
    var errorTitle: String {
        return "Export Error"
    }
    
    var errorMessage: String {
        return lastError?.userFriendlyMessage ?? "An unknown error occurred."
    }
    
    var canRetryAfterError: Bool {
        return lastError?.isRecoverable ?? false
    }
    
    // MARK: - UI Actions
    
    func showExportOptions() {
        showingExportSheet = true
    }
    
    func hideExportOptions() {
        showingExportSheet = false
    }
    
    func showExportHistory() {
        showingHistorySheet = true
    }
    
    func hideExportHistory() {
        showingHistorySheet = false
    }
    
    func confirmDeleteExport(_ exportResult: ExportResult) {
        selectedExportForDeletion = exportResult
        showingDeleteConfirmation = true
    }
    
    func cancelDeleteExport() {
        selectedExportForDeletion = nil
        showingDeleteConfirmation = false
    }
    
    func performDeleteExport() async {
        guard let exportToDelete = selectedExportForDeletion else { return }
        
        await deleteExport(exportToDelete)
        
        selectedExportForDeletion = nil
        showingDeleteConfirmation = false
    }
    
    // MARK: - Quick Actions
    
    func quickExportJSON() async {
        selectedFormat = .json
        await startExport()
    }
    
    func quickExportCSV() async {
        selectedFormat = .csv
        await startExport()
    }
    
    func quickExportPDF() async {
        selectedFormat = .pdf
        await startExport()
    }
    
    func quickExportLastWeek() async {
        selectPredefinedDateRange(.lastDays(7))
        await startExport()
    }
    
    func quickExportLastMonth() async {
        selectPredefinedDateRange(.lastDays(30))
        await startExport()
    }
}

// MARK: - Extensions

extension HealthDataExportViewModel {
    
    /// Convenience method to check if a specific export format is selected
    func isFormatSelected(_ format: ExportFormat) -> Bool {
        return selectedFormat == format
    }
    
    /// Get the icon name for the current export status
    var currentStatusIcon: String {
        guard let export = currentExport else { return "tray.and.arrow.up" }
        return export.status.icon
    }
    
    /// Get the color for the current export status
    var currentStatusColor: String {
        guard let export = currentExport else { return "blue" }
        return export.status.color
    }
    
    /// Get formatted file size for estimates
    var estimatedFileSizeFormatted: String {
        return estimatedExport?.fileSizeFormatted ?? "Calculating..."
    }
    
    /// Get formatted duration for estimates
    var estimatedDurationFormatted: String {
        return estimatedExport?.durationFormatted ?? "Calculating..."
    }
}