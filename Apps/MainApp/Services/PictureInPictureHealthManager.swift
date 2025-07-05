import SwiftUI
import AVKit
import AVFoundation
import Combine

@available(tvOS 18.0, *)
class PictureInPictureHealthManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPictureInPictureActive = false
    @Published var healthMetrics: HealthMetricsSnapshot = HealthMetricsSnapshot()
    @Published var displayMode: PiPDisplayMode = .compact
    @Published var updateInterval: TimeInterval = 5.0
    @Published var selectedMetrics: Set<HealthMetricType> = [.heartRate, .hrv, .sleep]
    
    // MARK: - Private Properties
    
    private var pipController: AVPictureInPictureController?
    private var playerLayer: AVPlayerLayer?
    private var metricsTimer: Timer?
    private var healthDataManager: HealthDataManager?
    private var cancellables = Set<AnyCancellable>()
    
    // PiP Content
    private var contentView: UIView?
    private var metricsRenderer: HealthMetricsRenderer?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupPictureInPicture()
        setupHealthDataBinding()
    }
    
    // MARK: - Setup Methods
    
    private func setupPictureInPicture() {
        // Create a minimal player for PiP functionality
        let player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        
        // Configure PiP controller
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
            pipController?.delegate = self
            
            // Configure PiP controller for health metrics
            setupPiPController()
        }
        
        // Setup metrics renderer
        metricsRenderer = HealthMetricsRenderer()
        
        // Create content view for health metrics
        setupContentView()
    }
    
    private func setupPiPController() {
        guard let controller = pipController else { return }
        
        // Configure PiP behavior
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        
        // Set up content source
        if #available(tvOS 18.0, *) {
            let contentSource = AVPictureInPictureController.ContentSource(
                playerLayer: playerLayer!,
                videoCallViewController: nil,
                contentViewController: createHealthMetricsViewController()
            )
            controller.contentSource = contentSource
        }
    }
    
    private func setupContentView() {
        contentView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 180))
        contentView?.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        contentView?.layer.cornerRadius = 12
        contentView?.layer.masksToBounds = true
    }
    
    private func setupHealthDataBinding() {
        // Bind to health data updates
        NotificationCenter.default.publisher(for: .healthDataUpdated)
            .sink { [weak self] _ in
                self?.updateHealthMetrics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - PiP Control
    
    func startPictureInPicture() {
        guard let controller = pipController,
              AVPictureInPictureController.isPictureInPictureSupported() else {
            print("Picture in Picture not supported")
            return
        }
        
        // Start metrics updates
        startMetricsUpdates()
        
        // Start PiP
        controller.startPictureInPicture()
    }
    
    func stopPictureInPicture() {
        guard let controller = pipController else { return }
        
        // Stop metrics updates
        stopMetricsUpdates()
        
        // Stop PiP
        controller.stopPictureInPicture()
    }
    
    private func startMetricsUpdates() {
        stopMetricsUpdates() // Ensure no duplicate timers
        
        metricsTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateHealthMetrics()
        }
        
        // Initial update
        updateHealthMetrics()
    }
    
    private func stopMetricsUpdates() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    // MARK: - Health Metrics Updates
    
    private func updateHealthMetrics() {
        Task {
            let snapshot = await fetchCurrentHealthMetrics()
            
            DispatchQueue.main.async {
                self.healthMetrics = snapshot
                self.updatePiPContent()
            }
        }
    }
    
    private func fetchCurrentHealthMetrics() async -> HealthMetricsSnapshot {
        // Simulate fetching real health data
        return HealthMetricsSnapshot(
            heartRate: Double.random(in: 65...85),
            hrv: Double.random(in: 30...60),
            sleepQuality: Double.random(in: 70...95),
            stressLevel: Double.random(in: 20...80),
            activityLevel: Double.random(in: 5000...15000),
            bloodPressure: BloodPressureReading(systolic: 120, diastolic: 80),
            oxygenSaturation: Double.random(in: 95...99),
            temperature: Double.random(in: 36.0...37.5),
            timestamp: Date()
        )
    }
    
    private func updatePiPContent() {
        guard let contentView = contentView,
              let renderer = metricsRenderer else { return }
        
        // Clear previous content
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Render new metrics
        let metricsView = renderer.renderMetrics(
            healthMetrics,
            selectedMetrics: selectedMetrics,
            displayMode: displayMode,
            frame: contentView.bounds
        )
        
        contentView.addSubview(metricsView)
        
        // Update PiP controller with new content
        updatePiPViewController()
    }
    
    private func updatePiPViewController() {
        let viewController = createHealthMetricsViewController()
        
        if #available(tvOS 18.0, *) {
            let contentSource = AVPictureInPictureController.ContentSource(
                playerLayer: playerLayer!,
                videoCallViewController: nil,
                contentViewController: viewController
            )
            pipController?.contentSource = contentSource
        }
    }
    
    // MARK: - View Controller Creation
    
    private func createHealthMetricsViewController() -> UIViewController {
        let hostingController = UIHostingController(
            rootView: PictureInPictureHealthView(
                metrics: healthMetrics,
                selectedMetrics: selectedMetrics,
                displayMode: displayMode
            )
        )
        
        hostingController.view.backgroundColor = UIColor.clear
        return hostingController
    }
    
    // MARK: - Configuration
    
    func setDisplayMode(_ mode: PiPDisplayMode) {
        displayMode = mode
        updatePiPContent()
    }
    
    func setUpdateInterval(_ interval: TimeInterval) {
        updateInterval = interval
        if isPictureInPictureActive {
            startMetricsUpdates()
        }
    }
    
    func setSelectedMetrics(_ metrics: Set<HealthMetricType>) {
        selectedMetrics = metrics
        updatePiPContent()
    }
    
    // MARK: - Cleanup
    
    deinit {
        stopMetricsUpdates()
        cancellables.removeAll()
    }
}

// MARK: - AVPictureInPictureControllerDelegate

@available(tvOS 18.0, *)
extension PictureInPictureHealthManager: AVPictureInPictureControllerDelegate {
    
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPictureInPictureActive = true
        startMetricsUpdates()
    }
    
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP started successfully
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        print("Failed to start Picture in Picture: \(error)")
        isPictureInPictureActive = false
    }
    
    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPictureInPictureActive = false
        stopMetricsUpdates()
    }
    
    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // PiP stopped successfully
    }
    
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        // Restore main interface
        completionHandler(true)
    }
}

// MARK: - Supporting Types

enum PiPDisplayMode: String, CaseIterable {
    case compact = "compact"
    case detailed = "detailed"
    case chart = "chart"
    
    var displayName: String {
        switch self {
        case .compact: return "Compact"
        case .detailed: return "Detailed"
        case .chart: return "Chart"
        }
    }
}

enum HealthMetricType: String, CaseIterable {
    case heartRate = "heartRate"
    case hrv = "hrv"
    case sleep = "sleep"
    case stress = "stress"
    case activity = "activity"
    case bloodPressure = "bloodPressure"
    case oxygenSaturation = "oxygenSaturation"
    case temperature = "temperature"
    
    var displayName: String {
        switch self {
        case .heartRate: return "Heart Rate"
        case .hrv: return "HRV"
        case .sleep: return "Sleep"
        case .stress: return "Stress"
        case .activity: return "Activity"
        case .bloodPressure: return "Blood Pressure"
        case .oxygenSaturation: return "SpO2"
        case .temperature: return "Temperature"
        }
    }
    
    var icon: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .hrv: return "waveform.path.ecg"
        case .sleep: return "bed.double.fill"
        case .stress: return "brain.head.profile"
        case .activity: return "figure.walk"
        case .bloodPressure: return "heart.circle.fill"
        case .oxygenSaturation: return "lungs.fill"
        case .temperature: return "thermometer"
        }
    }
    
    var color: Color {
        switch self {
        case .heartRate: return .red
        case .hrv: return .green
        case .sleep: return .blue
        case .stress: return .purple
        case .activity: return .orange
        case .bloodPressure: return .pink
        case .oxygenSaturation: return .cyan
        case .temperature: return .yellow
        }
    }
}

struct HealthMetricsSnapshot {
    let heartRate: Double
    let hrv: Double
    let sleepQuality: Double
    let stressLevel: Double
    let activityLevel: Double
    let bloodPressure: BloodPressureReading
    let oxygenSaturation: Double
    let temperature: Double
    let timestamp: Date
    
    init() {
        self.heartRate = 0
        self.hrv = 0
        self.sleepQuality = 0
        self.stressLevel = 0
        self.activityLevel = 0
        self.bloodPressure = BloodPressureReading(systolic: 0, diastolic: 0)
        self.oxygenSaturation = 0
        self.temperature = 0
        self.timestamp = Date()
    }
    
    init(heartRate: Double, hrv: Double, sleepQuality: Double, stressLevel: Double, activityLevel: Double, bloodPressure: BloodPressureReading, oxygenSaturation: Double, temperature: Double, timestamp: Date) {
        self.heartRate = heartRate
        self.hrv = hrv
        self.sleepQuality = sleepQuality
        self.stressLevel = stressLevel
        self.activityLevel = activityLevel
        self.bloodPressure = bloodPressure
        self.oxygenSaturation = oxygenSaturation
        self.temperature = temperature
        self.timestamp = timestamp
    }
    
    func getValue(for metricType: HealthMetricType) -> String {
        switch metricType {
        case .heartRate:
            return "\(Int(heartRate)) BPM"
        case .hrv:
            return "\(String(format: "%.1f", hrv)) ms"
        case .sleep:
            return "\(Int(sleepQuality))%"
        case .stress:
            return "\(Int(stressLevel))%"
        case .activity:
            return "\(Int(activityLevel)) steps"
        case .bloodPressure:
            return "\(Int(bloodPressure.systolic))/\(Int(bloodPressure.diastolic))"
        case .oxygenSaturation:
            return "\(Int(oxygenSaturation))%"
        case .temperature:
            return "\(String(format: "%.1f", temperature))°C"
        }
    }
}

struct BloodPressureReading {
    let systolic: Double
    let diastolic: Double
}

// MARK: - Health Metrics Renderer

class HealthMetricsRenderer {
    
    func renderMetrics(
        _ metrics: HealthMetricsSnapshot,
        selectedMetrics: Set<HealthMetricType>,
        displayMode: PiPDisplayMode,
        frame: CGRect
    ) -> UIView {
        
        let containerView = UIView(frame: frame)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 12
        
        switch displayMode {
        case .compact:
            renderCompactView(metrics, selectedMetrics: selectedMetrics, in: containerView)
        case .detailed:
            renderDetailedView(metrics, selectedMetrics: selectedMetrics, in: containerView)
        case .chart:
            renderChartView(metrics, selectedMetrics: selectedMetrics, in: containerView)
        }
        
        return containerView
    }
    
    private func renderCompactView(
        _ metrics: HealthMetricsSnapshot,
        selectedMetrics: Set<HealthMetricType>,
        in containerView: UIView
    ) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for metricType in selectedMetrics.prefix(3) {
            let metricView = createCompactMetricView(metricType, metrics: metrics)
            stackView.addArrangedSubview(metricView)
        }
        
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    private func renderDetailedView(
        _ metrics: HealthMetricsSnapshot,
        selectedMetrics: Set<HealthMetricType>,
        in containerView: UIView
    ) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        for metricType in selectedMetrics.prefix(4) {
            let metricView = createDetailedMetricView(metricType, metrics: metrics)
            stackView.addArrangedSubview(metricView)
        }
        
        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
    }
    
    private func renderChartView(
        _ metrics: HealthMetricsSnapshot,
        selectedMetrics: Set<HealthMetricType>,
        in containerView: UIView
    ) {
        // Simplified chart representation
        let chartView = UIView()
        chartView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        chartView.layer.cornerRadius = 8
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add chart content here (simplified for PiP)
        let titleLabel = UILabel()
        titleLabel.text = "Health Trends"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        chartView.addSubview(titleLabel)
        containerView.addSubview(chartView)
        
        NSLayoutConstraint.activate([
            chartView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            chartView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            chartView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            chartView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            
            titleLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor)
        ])
    }
    
    private func createCompactMetricView(_ metricType: HealthMetricType, metrics: HealthMetricsSnapshot) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 6
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "❤️" // Simplified icon
        iconLabel.font = UIFont.systemFont(ofSize: 16)
        
        let valueLabel = UILabel()
        valueLabel.text = metrics.getValue(for: metricType)
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        valueLabel.textAlignment = .center
        
        stackView.addArrangedSubview(iconLabel)
        stackView.addArrangedSubview(valueLabel)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    private func createDetailedMetricView(_ metricType: HealthMetricType, metrics: HealthMetricsSnapshot) -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        view.layer.cornerRadius = 6
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = "❤️" // Simplified icon
        iconLabel.font = UIFont.systemFont(ofSize: 14)
        
        let titleLabel = UILabel()
        titleLabel.text = metricType.displayName
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        
        let valueLabel = UILabel()
        valueLabel.text = metrics.getValue(for: metricType)
        valueLabel.textColor = .white
        valueLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        valueLabel.textAlignment = .right
        
        stackView.addArrangedSubview(iconLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(valueLabel)
        
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
}

// MARK: - SwiftUI Views

@available(tvOS 18.0, *)
struct PictureInPictureHealthView: View {
    let metrics: HealthMetricsSnapshot
    let selectedMetrics: Set<HealthMetricType>
    let displayMode: PiPDisplayMode
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
            
            switch displayMode {
            case .compact:
                CompactMetricsView(metrics: metrics, selectedMetrics: selectedMetrics)
            case .detailed:
                DetailedMetricsView(metrics: metrics, selectedMetrics: selectedMetrics)
            case .chart:
                ChartMetricsView(metrics: metrics, selectedMetrics: selectedMetrics)
            }
        }
        .frame(width: 320, height: 180)
    }
}

struct CompactMetricsView: View {
    let metrics: HealthMetricsSnapshot
    let selectedMetrics: Set<HealthMetricType>
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(selectedMetrics.prefix(3)), id: \.self) { metricType in
                VStack(spacing: 4) {
                    Image(systemName: metricType.icon)
                        .foregroundColor(metricType.color)
                        .font(.system(size: 16))
                    
                    Text(metrics.getValue(for: metricType))
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(8)
    }
}

struct DetailedMetricsView: View {
    let metrics: HealthMetricsSnapshot
    let selectedMetrics: Set<HealthMetricType>
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(Array(selectedMetrics.prefix(4)), id: \.self) { metricType in
                HStack(spacing: 8) {
                    Image(systemName: metricType.icon)
                        .foregroundColor(metricType.color)
                        .font(.system(size: 12))
                        .frame(width: 16)
                    
                    Text(metricType.displayName)
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .medium))
                    
                    Spacer()
                    
                    Text(metrics.getValue(for: metricType))
                        .foregroundColor(.white)
                        .font(.system(size: 10, weight: .semibold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(8)
    }
}

struct ChartMetricsView: View {
    let metrics: HealthMetricsSnapshot
    let selectedMetrics: Set<HealthMetricType>
    
    var body: some View {
        VStack {
            Text("Health Trends")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            
            // Simplified chart representation
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(height: 80)
                .cornerRadius(8)
            
            HStack {
                ForEach(Array(selectedMetrics.prefix(3)), id: \.self) { metricType in
                    VStack {
                        Circle()
                            .fill(metricType.color)
                            .frame(width: 8, height: 8)
                        
                        Text(metricType.displayName)
                            .foregroundColor(.white)
                            .font(.system(size: 8))
                    }
                }
            }
        }
        .padding(8)
    }
}

// MARK: - Configuration View

@available(tvOS 18.0, *)
struct PictureInPictureConfigurationView: View {
    @StateObject private var pipManager = PictureInPictureHealthManager()
    @State private var selectedDisplayMode: PiPDisplayMode = .compact
    @State private var selectedMetrics: Set<HealthMetricType> = [.heartRate, .hrv, .sleep]
    @State private var updateInterval: Double = 5.0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Text("Picture-in-Picture Health Metrics")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Continuous health monitoring while using other apps")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Configuration Options
                VStack(spacing: 20) {
                    // Display Mode
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Display Mode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Picker("Display Mode", selection: $selectedDisplayMode) {
                            ForEach(PiPDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    // Metrics Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Health Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(HealthMetricType.allCases, id: \.self) { metricType in
                                MetricToggleButton(
                                    metricType: metricType,
                                    isSelected: selectedMetrics.contains(metricType)
                                ) {
                                    if selectedMetrics.contains(metricType) {
                                        selectedMetrics.remove(metricType)
                                    } else {
                                        selectedMetrics.insert(metricType)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Update Interval
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Update Interval: \(String(format: "%.0f", updateInterval)) seconds")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Slider(value: $updateInterval, in: 1...30, step: 1)
                            .accentColor(.blue)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        pipManager.setDisplayMode(selectedDisplayMode)
                        pipManager.setSelectedMetrics(selectedMetrics)
                        pipManager.setUpdateInterval(updateInterval)
                        pipManager.startPictureInPicture()
                    }) {
                        HStack {
                            Image(systemName: "pip.enter")
                            Text("Start PiP")
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(pipManager.isPictureInPictureActive)
                    
                    Button(action: {
                        pipManager.stopPictureInPicture()
                    }) {
                        HStack {
                            Image(systemName: "pip.exit")
                            Text("Stop PiP")
                        }
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .disabled(!pipManager.isPictureInPictureActive)
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
    }
}

struct MetricToggleButton: View {
    let metricType: HealthMetricType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 5) {
                Image(systemName: metricType.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? metricType.color : .gray)
                
                Text(metricType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? metricType.color.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? metricType.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
}

#Preview {
    PictureInPictureConfigurationView()
}