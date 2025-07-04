import Foundation
import Combine
import WatchKit

class WatchEnvironmentMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published var temperature: Double = 20.0
    @Published var humidity: Double = 45.0
    @Published var noiseLevel: Double = 35.0
    @Published var airQuality: Double = 0.85
    @Published var lightLevel: Double = 0.1
    
    @Published var overallScore: Double = 0.8
    @Published var environmentStatus: EnvironmentStatus = .optimal
    
    // Status for individual metrics
    @Published var temperatureStatus: EnvironmentStatus = .optimal
    @Published var humidityStatus: EnvironmentStatus = .optimal
    @Published var noiseStatus: EnvironmentStatus = .optimal
    @Published var airQualityStatus: EnvironmentStatus = .optimal
    
    // Optimization scores
    @Published var temperatureOptimization: Double = 0.8
    @Published var noiseOptimization: Double = 0.9
    @Published var airQualityOptimization: Double = 0.85
    
    // Alert settings
    @Published var temperatureAlertsEnabled: Bool = true
    @Published var noiseAlertsEnabled: Bool = true
    @Published var airQualityAlertsEnabled: Bool = true
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var monitoringTimer: Timer?
    private var isMonitoring = false
    
    // Simulation data for realistic environment changes
    private var baseTemperature: Double = 20.0
    private var baseHumidity: Double = 45.0
    private var baseNoiseLevel: Double = 35.0
    private var baseAirQuality: Double = 0.85
    
    // MARK: - Initialization
    
    init() {
        setupEnvironmentSimulation()
        calculateOptimizationScores()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Start periodic environment updates
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateEnvironmentData()
        }
        
        // Initial update
        updateEnvironmentData()
        
        print("WatchEnvironmentMonitor: Started monitoring")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        print("WatchEnvironmentMonitor: Stopped monitoring")
    }
    
    func refreshData() {
        updateEnvironmentData()
    }
    
    // MARK: - Private Methods
    
    private func setupEnvironmentSimulation() {
        // Simulate realistic environment changes throughout the day
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Adjust base values based on time of day
        switch hour {
        case 0...6: // Night
            baseTemperature = 18.0
            baseHumidity = 50.0
            baseNoiseLevel = 25.0
            baseAirQuality = 0.9
        case 7...11: // Morning
            baseTemperature = 20.0
            baseHumidity = 45.0
            baseNoiseLevel = 40.0
            baseAirQuality = 0.8
        case 12...17: // Afternoon
            baseTemperature = 22.0
            baseHumidity = 40.0
            baseNoiseLevel = 45.0
            baseAirQuality = 0.75
        case 18...23: // Evening
            baseTemperature = 21.0
            baseHumidity = 48.0
            baseNoiseLevel = 35.0
            baseAirQuality = 0.85
        default:
            break
        }
    }
    
    private func updateEnvironmentData() {
        // Simulate realistic variations in environment data
        let temperatureVariation = Double.random(in: -2...2)
        let humidityVariation = Double.random(in: -5...5)
        let noiseVariation = Double.random(in: -10...15)
        let airQualityVariation = Double.random(in: -0.1...0.1)
        
        DispatchQueue.main.async {
            self.temperature = max(15, min(30, self.baseTemperature + temperatureVariation))
            self.humidity = max(20, min(80, self.baseHumidity + humidityVariation))
            self.noiseLevel = max(20, min(70, self.baseNoiseLevel + noiseVariation))
            self.airQuality = max(0.3, min(1.0, self.baseAirQuality + airQualityVariation))
            self.lightLevel = self.calculateLightLevel()
            
            self.updateEnvironmentStatuses()
            self.calculateOptimizationScores()
            self.calculateOverallScore()
            self.checkForAlerts()
        }
        
        // Send environment data to iPhone
        sendEnvironmentDataToiPhone()
    }
    
    private func calculateLightLevel() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Simulate light levels throughout the day
        switch hour {
        case 0...5: return 0.0 // Complete darkness
        case 6...7: return 0.1 // Dawn
        case 8...17: return 0.8 // Daylight
        case 18...19: return 0.4 // Dusk
        case 20...21: return 0.2 // Evening
        case 22...23: return 0.1 // Night
        default: return 0.0
        }
    }
    
    private func updateEnvironmentStatuses() {
        // Temperature status
        temperatureStatus = evaluateTemperature(temperature)
        
        // Humidity status
        humidityStatus = evaluateHumidity(humidity)
        
        // Noise status
        noiseStatus = evaluateNoise(noiseLevel)
        
        // Air quality status
        airQualityStatus = evaluateAirQuality(airQuality)
        
        // Overall environment status
        let statuses = [temperatureStatus, humidityStatus, noiseStatus, airQualityStatus]
        let averageScore = statuses.map { $0.score }.reduce(0, +) / Double(statuses.count)
        environmentStatus = EnvironmentStatus.fromScore(averageScore)
    }
    
    private func evaluateTemperature(_ temp: Double) -> EnvironmentStatus {
        let optimalRange = 18.0...22.0
        
        if optimalRange.contains(temp) {
            return .optimal
        } else if (16.0...24.0).contains(temp) {
            return .good
        } else if (14.0...26.0).contains(temp) {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func evaluateHumidity(_ humidity: Double) -> EnvironmentStatus {
        let optimalRange = 40.0...60.0
        
        if optimalRange.contains(humidity) {
            return .optimal
        } else if (30.0...70.0).contains(humidity) {
            return .good
        } else if (20.0...80.0).contains(humidity) {
            return .fair
        } else {
            return .poor
        }
    }
    
    private func evaluateNoise(_ noise: Double) -> EnvironmentStatus {
        switch noise {
        case 0...30: return .optimal
        case 31...40: return .good
        case 41...50: return .fair
        default: return .poor
        }
    }
    
    private func evaluateAirQuality(_ quality: Double) -> EnvironmentStatus {
        switch quality {
        case 0.8...1.0: return .optimal
        case 0.6...0.79: return .good
        case 0.4...0.59: return .fair
        default: return .poor
        }
    }
    
    private func calculateOptimizationScores() {
        // Temperature optimization (closer to 20°C is better)
        let tempDiff = abs(temperature - 20.0)
        temperatureOptimization = max(0, 1.0 - (tempDiff / 10.0))
        
        // Noise optimization (lower is better for sleep)
        noiseOptimization = max(0, 1.0 - (noiseLevel / 50.0))
        
        // Air quality optimization
        airQualityOptimization = airQuality
    }
    
    private func calculateOverallScore() {
        let scores = [
            temperatureStatus.score,
            humidityStatus.score,
            noiseStatus.score,
            airQualityStatus.score
        ]
        
        overallScore = scores.reduce(0, +) / Double(scores.count)
    }
    
    private func checkForAlerts() {
        // Temperature alerts
        if temperatureAlertsEnabled {
            if temperature > 24.0 || temperature < 16.0 {
                let message = temperature > 24.0 ? 
                    "Room temperature is \(temperature, specifier: "%.1f")°C. Consider cooling." :
                    "Room temperature is \(temperature, specifier: "%.1f")°C. Consider warming."
                
                WatchNotificationManager.shared.notifyEnvironmentalChange(
                    type: temperature > 24.0 ? .temperatureHigh : .temperatureLow,
                    value: temperature,
                    recommendation: message
                )
            }
        }
        
        // Noise alerts
        if noiseAlertsEnabled && noiseLevel > 45.0 {
            WatchNotificationManager.shared.notifyEnvironmentalChange(
                type: .noiseHigh,
                value: noiseLevel,
                recommendation: "Noise level is \(Int(noiseLevel)) dB. Consider reducing noise sources."
            )
        }
        
        // Air quality alerts
        if airQualityAlertsEnabled && airQuality < 0.6 {
            WatchNotificationManager.shared.notifyEnvironmentalChange(
                type: .airQualityPoor,
                value: airQuality,
                recommendation: "Air quality is poor. Consider improving ventilation."
            )
        }
    }
    
    private func sendEnvironmentDataToiPhone() {
        let environmentData: [String: Any] = [
            "temperature": temperature,
            "humidity": humidity,
            "noiseLevel": noiseLevel,
            "airQuality": airQuality,
            "lightLevel": lightLevel,
            "overallScore": overallScore,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let message = WatchMessage(
            command: "environmentUpdate",
            data: environmentData,
            source: "watch"
        )
        
        WatchConnectivityManager.shared.sendMessage(message)
    }
    
    // MARK: - Computed Properties
    
    var airQualityDescription: String {
        switch airQuality {
        case 0.8...1.0: return "Excellent"
        case 0.6...0.79: return "Good"
        case 0.4...0.59: return "Fair"
        case 0.2...0.39: return "Poor"
        default: return "Unhealthy"
        }
    }
    
    // MARK: - Public Interface
    
    func getEnvironmentSummary() -> [String: Any] {
        return [
            "temperature": temperature,
            "humidity": humidity,
            "noiseLevel": noiseLevel,
            "airQuality": airQuality,
            "lightLevel": lightLevel,
            "overallScore": overallScore,
            "environmentStatus": environmentStatus.description,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    func optimizeForSleep() {
        // Send optimization request to connected smart home devices
        let optimizationRequest: [String: Any] = [
            "action": "optimizeForSleep",
            "targetTemperature": 19.0,
            "targetHumidity": 45.0,
            "reduceNoise": true,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        let message = WatchMessage(
            command: "environmentOptimization",
            data: optimizationRequest,
            source: "watch"
        )
        
        WatchConnectivityManager.shared.sendMessage(message)
    }
}

// MARK: - Supporting Types

enum EnvironmentStatus {
    case optimal
    case good
    case fair
    case poor
    
    var score: Double {
        switch self {
        case .optimal: return 1.0
        case .good: return 0.75
        case .fair: return 0.5
        case .poor: return 0.25
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return .green
        case .good: return .yellow
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .fair: return "exclamationmark.circle"
        case .poor: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .optimal: return "Optimal"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    static func fromScore(_ score: Double) -> EnvironmentStatus {
        switch score {
        case 0.8...1.0: return .optimal
        case 0.6...0.79: return .good
        case 0.4...0.59: return .fair
        default: return .poor
        }
    }
}