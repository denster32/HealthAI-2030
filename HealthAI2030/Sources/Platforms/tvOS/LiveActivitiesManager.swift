import SwiftUI
import ActivityKit
import Combine

@available(tvOS 18.0, *)
class LiveActivitiesManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isLiveActivityActive = false
    @Published var currentActivity: Activity<HealthLiveActivityAttributes>?
    @Published var activeHealthMetrics: HealthMetricsLiveData = HealthMetricsLiveData()
    @Published var updateFrequency: LiveActivityUpdateFrequency = .realtime
    @Published var displayConfiguration: LiveActivityDisplayConfiguration = LiveActivityDisplayConfiguration()
    
    // MARK: - Private Properties
    
    private var healthDataTimer: Timer?
    private var activityUpdateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdate: Date = Date()
    
    // Health data providers
    private var heartRateProvider: HealthDataProvider?
    private var hrvProvider: HealthDataProvider?
    private var stressProvider: HealthDataProvider?
    private var sleepProvider: HealthDataProvider?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupHealthDataProviders()
        setupActivityObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupHealthDataProviders() {
        heartRateProvider = HealthDataProvider(type: .heartRate)
        hrvProvider = HealthDataProvider(type: .hrv)
        stressProvider = HealthDataProvider(type: .stress)
        sleepProvider = HealthDataProvider(type: .sleep)
        
        // Bind to health data updates
        bindHealthDataUpdates()
    }
    
    private func setupActivityObservers() {
        // Monitor activity authorization state
        Task {
            for await authorizationInfo in ActivityAuthorizationInfo.authorizationUpdates {
                await handleAuthorizationUpdate(authorizationInfo)
            }
        }
    }
    
    private func bindHealthDataUpdates() {
        // Combine all health data streams
        Publishers.CombineLatest4(
            heartRateProvider?.dataPublisher ?? Just(0.0).eraseToAnyPublisher(),
            hrvProvider?.dataPublisher ?? Just(0.0).eraseToAnyPublisher(),
            stressProvider?.dataPublisher ?? Just(0.0).eraseToAnyPublisher(),
            sleepProvider?.dataPublisher ?? Just(0.0).eraseToAnyPublisher()
        )
        .sink { [weak self] heartRate, hrv, stress, sleep in
            self?.updateHealthMetrics(
                heartRate: heartRate,
                hrv: hrv,
                stress: stress,
                sleep: sleep
            )
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Live Activity Management
    
    func startLiveActivity() async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let initialState = HealthLiveActivityAttributes.ContentState(
            heartRate: activeHealthMetrics.heartRate,
            hrv: activeHealthMetrics.hrv,
            stressLevel: activeHealthMetrics.stressLevel,
            sleepQuality: activeHealthMetrics.sleepQuality,
            lastUpdate: Date(),
            alertStatus: determineAlertStatus(),
            trend: calculateHealthTrend()
        )
        
        let attributes = HealthLiveActivityAttributes(
            userId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            displayName: "Health Monitor",
            configuration: displayConfiguration
        )
        
        let activityContent = ActivityContent(state: initialState, staleDate: nil)
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: activityContent,
                pushType: .token
            )
            
            await MainActor.run {
                self.currentActivity = activity
                self.isLiveActivityActive = true
            }
            
            startPeriodicUpdates()
            
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    func stopLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        stopPeriodicUpdates()
        
        let finalState = HealthLiveActivityAttributes.ContentState(
            heartRate: activeHealthMetrics.heartRate,
            hrv: activeHealthMetrics.hrv,
            stressLevel: activeHealthMetrics.stressLevel,
            sleepQuality: activeHealthMetrics.sleepQuality,
            lastUpdate: Date(),
            alertStatus: .normal,
            trend: .stable
        )
        
        let finalContent = ActivityContent(
            state: finalState,
            staleDate: Date().addingTimeInterval(60)
        )
        
        await activity.end(finalContent, dismissalPolicy: .immediate)
        
        await MainActor.run {
            self.currentActivity = nil
            self.isLiveActivityActive = false
        }
    }
    
    func updateLiveActivity() async {
        guard let activity = currentActivity else { return }
        
        let updatedState = HealthLiveActivityAttributes.ContentState(
            heartRate: activeHealthMetrics.heartRate,
            hrv: activeHealthMetrics.hrv,
            stressLevel: activeHealthMetrics.stressLevel,
            sleepQuality: activeHealthMetrics.sleepQuality,
            lastUpdate: Date(),
            alertStatus: determineAlertStatus(),
            trend: calculateHealthTrend()
        )
        
        let updatedContent = ActivityContent(
            state: updatedState,
            staleDate: Date().addingTimeInterval(300) // 5 minutes
        )
        
        await activity.update(updatedContent)
        lastUpdate = Date()
    }
    
    // MARK: - Periodic Updates
    
    private func startPeriodicUpdates() {
        stopPeriodicUpdates() // Ensure no duplicate timers
        
        let interval = updateFrequency.timeInterval
        
        activityUpdateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.updateLiveActivity()
            }
        }
        
        // Start health data monitoring
        startHealthDataMonitoring()
    }
    
    private func stopPeriodicUpdates() {
        activityUpdateTimer?.invalidate()
        activityUpdateTimer = nil
        
        stopHealthDataMonitoring()
    }
    
    private func startHealthDataMonitoring() {
        let monitoringInterval = min(updateFrequency.timeInterval, 5.0) // Max 5 second intervals
        
        healthDataTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.fetchAndUpdateHealthData()
        }
    }
    
    private func stopHealthDataMonitoring() {
        healthDataTimer?.invalidate()
        healthDataTimer = nil
    }
    
    // MARK: - Health Data Management
    
    private func fetchAndUpdateHealthData() {
        Task {
            let newMetrics = await fetchLatestHealthMetrics()
            
            await MainActor.run {
                self.activeHealthMetrics = newMetrics
            }
            
            // Check if significant change warrants immediate update
            if shouldTriggerImmediateUpdate(newMetrics) {
                await updateLiveActivity()
            }
        }
    }
    
    private func updateHealthMetrics(heartRate: Double, hrv: Double, stress: Double, sleep: Double) {
        activeHealthMetrics = HealthMetricsLiveData(
            heartRate: heartRate,
            hrv: hrv,
            stressLevel: stress,
            sleepQuality: sleep,
            timestamp: Date()
        )
        
        // Trigger live activity update if needed
        if isLiveActivityActive {
            Task {
                await updateLiveActivity()
            }
        }
    }
    
    private func fetchLatestHealthMetrics() async -> HealthMetricsLiveData {
        // Simulate fetching real health data
        return HealthMetricsLiveData(
            heartRate: Double.random(in: 60...100),
            hrv: Double.random(in: 25...65),
            stressLevel: Double.random(in: 15...85),
            sleepQuality: Double.random(in: 60...95),
            timestamp: Date()
        )
    }
    
    private func shouldTriggerImmediateUpdate(_ newMetrics: HealthMetricsLiveData) -> Bool {
        let heartRateChange = abs(newMetrics.heartRate - activeHealthMetrics.heartRate)
        let stressChange = abs(newMetrics.stressLevel - activeHealthMetrics.stressLevel)
        
        // Trigger immediate update for significant changes
        return heartRateChange > 10 || stressChange > 20
    }
    
    // MARK: - Health Analysis
    
    private func determineAlertStatus() -> HealthAlertStatus {
        let metrics = activeHealthMetrics
        
        // Check for concerning values
        if metrics.heartRate > 100 || metrics.heartRate < 50 {
            return .critical
        }
        
        if metrics.stressLevel > 80 {
            return .warning
        }
        
        if metrics.hrv < 20 {
            return .warning
        }
        
        return .normal
    }
    
    private func calculateHealthTrend() -> HealthTrend {
        // Simplified trend calculation
        // In a real implementation, this would analyze historical data
        let randomTrend = Double.random(in: 0...1)
        
        if randomTrend < 0.33 {
            return .declining
        } else if randomTrend < 0.66 {
            return .stable
        } else {
            return .improving
        }
    }
    
    // MARK: - Configuration
    
    func setUpdateFrequency(_ frequency: LiveActivityUpdateFrequency) {
        updateFrequency = frequency
        
        if isLiveActivityActive {
            startPeriodicUpdates()
        }
    }
    
    func setDisplayConfiguration(_ config: LiveActivityDisplayConfiguration) {
        displayConfiguration = config
        
        // Update current activity with new configuration
        if isLiveActivityActive {
            Task {
                await updateLiveActivity()
            }
        }
    }
    
    // MARK: - Authorization Handling
    
    private func handleAuthorizationUpdate(_ authInfo: ActivityAuthorizationInfo) async {
        await MainActor.run {
            if !authInfo.areActivitiesEnabled && self.isLiveActivityActive {
                Task {
                    await self.stopLiveActivity()
                }
            }
        }
    }
    
    // MARK: - Public Interface
    
    func requestActivityAuthorization() async -> Bool {
        let authInfo = ActivityAuthorizationInfo()
        return authInfo.areActivitiesEnabled
    }
    
    func getCurrentMetrics() -> HealthMetricsLiveData {
        return activeHealthMetrics
    }
    
    func getActivityInfo() -> Activity<HealthLiveActivityAttributes>? {
        return currentActivity
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopPeriodicUpdates()
        cancellables.removeAll()
    }
}

// MARK: - Live Activity Attributes

struct HealthLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        let heartRate: Double
        let hrv: Double
        let stressLevel: Double
        let sleepQuality: Double
        let lastUpdate: Date
        let alertStatus: HealthAlertStatus
        let trend: HealthTrend
    }
    
    let userId: String
    let displayName: String
    let configuration: LiveActivityDisplayConfiguration
}

// MARK: - Supporting Types

struct HealthMetricsLiveData {
    let heartRate: Double
    let hrv: Double
    let stressLevel: Double
    let sleepQuality: Double
    let timestamp: Date
    
    init() {
        self.heartRate = 0
        self.hrv = 0
        self.stressLevel = 0
        self.sleepQuality = 0
        self.timestamp = Date()
    }
    
    init(heartRate: Double, hrv: Double, stressLevel: Double, sleepQuality: Double, timestamp: Date) {
        self.heartRate = heartRate
        self.hrv = hrv
        self.stressLevel = stressLevel
        self.sleepQuality = sleepQuality
        self.timestamp = timestamp
    }
}

enum LiveActivityUpdateFrequency: String, CaseIterable {
    case realtime = "realtime"
    case frequent = "frequent"
    case moderate = "moderate"
    case minimal = "minimal"
    
    var displayName: String {
        switch self {
        case .realtime: return "Real-time (30s)"
        case .frequent: return "Frequent (1m)"
        case .moderate: return "Moderate (5m)"
        case .minimal: return "Minimal (15m)"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .realtime: return 30
        case .frequent: return 60
        case .moderate: return 300
        case .minimal: return 900
        }
    }
}

enum HealthAlertStatus: String, Codable {
    case normal = "normal"
    case warning = "warning"
    case critical = "critical"
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

enum HealthTrend: String, Codable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
}

struct LiveActivityDisplayConfiguration: Codable {
    let showHeartRate: Bool
    let showHRV: Bool
    let showStress: Bool
    let showSleep: Bool
    let compactMode: Bool
    let showTrends: Bool
    let showAlerts: Bool
    
    init() {
        self.showHeartRate = true
        self.showHRV = true
        self.showStress = true
        self.showSleep = false
        self.compactMode = false
        self.showTrends = true
        self.showAlerts = true
    }
    
    init(showHeartRate: Bool, showHRV: Bool, showStress: Bool, showSleep: Bool, compactMode: Bool, showTrends: Bool, showAlerts: Bool) {
        self.showHeartRate = showHeartRate
        self.showHRV = showHRV
        self.showStress = showStress
        self.showSleep = showSleep
        self.compactMode = compactMode
        self.showTrends = showTrends
        self.showAlerts = showAlerts
    }
}

// MARK: - Health Data Provider

class HealthDataProvider: ObservableObject {
    @Published var currentValue: Double = 0.0
    
    let type: HealthDataType
    private var updateTimer: Timer?
    
    lazy var dataPublisher: AnyPublisher<Double, Never> = {
        $currentValue.eraseToAnyPublisher()
    }()
    
    init(type: HealthDataType) {
        self.type = type
        startDataSimulation()
    }
    
    private func startDataSimulation() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.generateSimulatedData()
        }
    }
    
    private func generateSimulatedData() {
        switch type {
        case .heartRate:
            currentValue = Double.random(in: 60...100)
        case .hrv:
            currentValue = Double.random(in: 25...65)
        case .stress:
            currentValue = Double.random(in: 15...85)
        case .sleep:
            currentValue = Double.random(in: 60...95)
        default:
            currentValue = Double.random(in: 0...100)
        }
    }
    
    deinit {
        updateTimer?.invalidate()
    }
}

enum HealthDataType {
    case heartRate
    case hrv
    case stress
    case sleep
    case activity
    case bloodPressure
    case oxygenSaturation
    case temperature
}

// MARK: - Live Activity Widget Views

@available(tvOS 18.0, *)
struct HealthLiveActivityWidget: View {
    let state: HealthLiveActivityAttributes.ContentState
    let configuration: LiveActivityDisplayConfiguration
    
    var body: some View {
        if configuration.compactMode {
            CompactHealthView(state: state, configuration: configuration)
        } else {
            DetailedHealthView(state: state, configuration: configuration)
        }
    }
}

struct CompactHealthView: View {
    let state: HealthLiveActivityAttributes.ContentState
    let configuration: LiveActivityDisplayConfiguration
    
    var body: some View {
        HStack(spacing: 12) {
            // Alert Status Indicator
            if configuration.showAlerts {
                Image(systemName: state.alertStatus.icon)
                    .foregroundColor(state.alertStatus.color)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            // Key Metrics
            if configuration.showHeartRate {
                MetricCompactView(
                    icon: "heart.fill",
                    value: "\(Int(state.heartRate))",
                    unit: "BPM",
                    color: .red
                )
            }
            
            if configuration.showHRV {
                MetricCompactView(
                    icon: "waveform.path.ecg",
                    value: "\(Int(state.hrv))",
                    unit: "ms",
                    color: .green
                )
            }
            
            if configuration.showStress {
                MetricCompactView(
                    icon: "brain.head.profile",
                    value: "\(Int(state.stressLevel))",
                    unit: "%",
                    color: .purple
                )
            }
            
            // Trend Indicator
            if configuration.showTrends {
                Image(systemName: state.trend.icon)
                    .foregroundColor(state.trend.color)
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
}

struct DetailedHealthView: View {
    let state: HealthLiveActivityAttributes.ContentState
    let configuration: LiveActivityDisplayConfiguration
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with Alert Status
            if configuration.showAlerts {
                HStack {
                    Image(systemName: state.alertStatus.icon)
                        .foregroundColor(state.alertStatus.color)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Health Monitor")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if configuration.showTrends {
                        HStack(spacing: 4) {
                            Image(systemName: state.trend.icon)
                                .foregroundColor(state.trend.color)
                                .font(.system(size: 14))
                            
                            Text(state.trend.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(state.trend.color)
                        }
                    }
                }
            }
            
            // Metrics Grid
            HStack(spacing: 16) {
                if configuration.showHeartRate {
                    MetricDetailedView(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        value: "\(Int(state.heartRate))",
                        unit: "BPM",
                        color: .red
                    )
                }
                
                if configuration.showHRV {
                    MetricDetailedView(
                        icon: "waveform.path.ecg",
                        title: "HRV",
                        value: "\(Int(state.hrv))",
                        unit: "ms",
                        color: .green
                    )
                }
                
                if configuration.showStress {
                    MetricDetailedView(
                        icon: "brain.head.profile",
                        title: "Stress",
                        value: "\(Int(state.stressLevel))",
                        unit: "%",
                        color: .purple
                    )
                }
                
                if configuration.showSleep {
                    MetricDetailedView(
                        icon: "bed.double.fill",
                        title: "Sleep",
                        value: "\(Int(state.sleepQuality))",
                        unit: "%",
                        color: .blue
                    )
                }
            }
            
            // Last Update
            Text("Updated \(formatTime(state.lastUpdate))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MetricCompactView: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
    }
}

struct MetricDetailedView: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(unit)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Configuration View

@available(tvOS 18.0, *)
struct LiveActivitiesConfigurationView: View {
    @StateObject private var liveActivitiesManager = LiveActivitiesManager()
    @State private var selectedFrequency: LiveActivityUpdateFrequency = .moderate
    @State private var showHeartRate = true
    @State private var showHRV = true
    @State private var showStress = true
    @State private var showSleep = false
    @State private var compactMode = false
    @State private var showTrends = true
    @State private var showAlerts = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Text("Live Activities")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Real-time health monitoring on your Home Screen")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Current Status
                if liveActivitiesManager.isLiveActivityActive {
                    LiveActivityStatusView(manager: liveActivitiesManager)
                }
                
                // Configuration Options
                VStack(spacing: 20) {
                    // Update Frequency
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Update Frequency")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(LiveActivityUpdateFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.displayName).tag(frequency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Display Options
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Display Options")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            Toggle("Heart Rate", isOn: $showHeartRate)
                                .toggleStyle(HealthToggleStyle(color: .red))
                            
                            Toggle("HRV", isOn: $showHRV)
                                .toggleStyle(HealthToggleStyle(color: .green))
                            
                            Toggle("Stress Level", isOn: $showStress)
                                .toggleStyle(HealthToggleStyle(color: .purple))
                            
                            Toggle("Sleep Quality", isOn: $showSleep)
                                .toggleStyle(HealthToggleStyle(color: .blue))
                            
                            Toggle("Compact Mode", isOn: $compactMode)
                                .toggleStyle(HealthToggleStyle(color: .gray))
                            
                            Toggle("Show Trends", isOn: $showTrends)
                                .toggleStyle(HealthToggleStyle(color: .cyan))
                            
                            Toggle("Show Alerts", isOn: $showAlerts)
                                .toggleStyle(HealthToggleStyle(color: .orange))
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        updateConfiguration()
                        Task {
                            await liveActivitiesManager.startLiveActivity()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Live Activity")
                        }
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                    }
                    .disabled(liveActivitiesManager.isLiveActivityActive)
                    
                    Button(action: {
                        Task {
                            await liveActivitiesManager.stopLiveActivity()
                        }
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop Live Activity")
                        }
                        .foregroundColor(.white)
                        .frame(width: 250, height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .disabled(!liveActivitiesManager.isLiveActivityActive)
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.8), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onChange(of: selectedFrequency) { frequency in
            liveActivitiesManager.setUpdateFrequency(frequency)
        }
    }
    
    private func updateConfiguration() {
        let config = LiveActivityDisplayConfiguration(
            showHeartRate: showHeartRate,
            showHRV: showHRV,
            showStress: showStress,
            showSleep: showSleep,
            compactMode: compactMode,
            showTrends: showTrends,
            showAlerts: showAlerts
        )
        
        liveActivitiesManager.setDisplayConfiguration(config)
        liveActivitiesManager.setUpdateFrequency(selectedFrequency)
    }
}

struct LiveActivityStatusView: View {
    @ObservedObject var manager: LiveActivitiesManager
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Live Activity Active")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.green)
            
            // Current Metrics Preview
            HStack(spacing: 20) {
                MetricPreviewCard(
                    title: "Heart Rate",
                    value: "\(Int(manager.activeHealthMetrics.heartRate)) BPM",
                    color: .red
                )
                
                MetricPreviewCard(
                    title: "HRV",
                    value: "\(Int(manager.activeHealthMetrics.hrv)) ms",
                    color: .green
                )
                
                MetricPreviewCard(
                    title: "Stress",
                    value: "\(Int(manager.activeHealthMetrics.stressLevel))%",
                    color: .purple
                )
            }
            
            Text("Last updated: \(formatTime(manager.activeHealthMetrics.timestamp))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct MetricPreviewCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

struct HealthToggleStyle: ToggleStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundColor(.white)
                .font(.body)
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? color : Color.gray)
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    LiveActivitiesConfigurationView()
}