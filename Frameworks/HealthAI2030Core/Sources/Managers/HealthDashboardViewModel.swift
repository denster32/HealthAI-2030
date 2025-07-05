import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import HealthAI2030Core
import Foundation
import Combine
import HealthKit

class HealthDashboardViewModel: ObservableObject {
    private let healthKitManager = HealthKitManager.shared
    private let sleepAnalysisManager = SleepAnalysisManager()
    private let cardiacManager = AdvancedCardiacManager()
    private let mentalHealthManager = MentalHealthManager()
    private let dataManager = HealthDataManager()
    
    @Published var currentVitals = VitalSigns.defaultValues
    @Published var sleepReport: SleepAnalysisReport?
    @Published var cardiacMetrics = CardiacMetrics.defaultValues
    @Published var activityData: [ActivityDataPoint] = []
    @Published var mentalHealthScore: MentalHealthScore?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
        do {
            try healthKitManager.startRealTimeVitalMonitoring()
        } catch {
            print("Failed to start real-time vital monitoring: \(error)")
        }
    }
    
    deinit {
        healthKitManager.stopRealTimeVitalMonitoring()
    }
    
    func loadDashboardData() {
        fetchCurrentVitals()
        fetchSleepAnalysis()
        fetchCardiacMetrics()
        fetchActivityData()
        fetchMentalHealthScore()
    }
    
    func refreshData() {
        loadDashboardData()
    }
    
    private func setupSubscriptions() {
        // Real-time vital updates
        healthKitManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Heart rate monitoring error: \(error)")
                }
            }, receiveValue: { [weak self] value in
                self?.currentVitals.heartRate = Int(value)
                self?.currentVitals.heartRateTrend = self?.calculateTrend(old: self?.currentVitals.heartRate ?? 0, new: Int(value)) ?? .neutral
            })
            .store(in: &cancellables)
        
        healthKitManager.oxygenSaturationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Oxygen saturation monitoring error: \(error)")
                }
            }, receiveValue: { [weak self] value in
                self?.currentVitals.bloodOxygen = Int(value)
                self?.currentVitals.oxygenTrend = self?.calculateTrend(old: self?.currentVitals.bloodOxygen ?? 0, new: Int(value)) ?? .neutral
            })
            .store(in: &cancellables)
        
        healthKitManager.respiratoryRatePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Respiratory rate monitoring error: \(error)")
                }
            }, receiveValue: { [weak self] value in
                self?.currentVitals.respiratoryRate = Int(value)
                self?.currentVitals.respiratoryTrend = self?.calculateTrend(old: self?.currentVitals.respiratoryRate ?? 0, new: Int(value)) ?? .neutral
            })
            .store(in: &cancellables)
    }
    
    private func fetchCurrentVitals() {
        healthKitManager.readLatestVitalSigns { [weak self] vitals, error in
            guard let self = self, let vitals = vitals else { return }
            DispatchQueue.main.async {
                self.currentVitals = vitals
            }
        }
    }
    
    private func fetchSleepAnalysis() {
        Task {
            do {
                let report = try await sleepAnalysisManager.generateSleepReport()
                DispatchQueue.main.async {
                    self.sleepReport = report
                }
            } catch {
                print("Error fetching sleep report: \(error)")
            }
        }
    }
    
    private func fetchCardiacMetrics() {
        Task {
            do {
                let metrics = try await cardiacManager.getCurrentCardiacMetrics()
                DispatchQueue.main.async {
                    self.cardiacMetrics = metrics
                }
            } catch {
                print("Error fetching cardiac metrics: \(error)")
            }
        }
    }
    
    private func fetchActivityData() {
        dataManager.fetchActivityData(pastDays: 7) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.activityData = data
                }
            case .failure(let error):
                print("Error fetching activity data: \(error)")
            }
        }
    }
    
    private func fetchMentalHealthScore() {
        mentalHealthManager.getLatestMentalHealthScore { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let score):
                DispatchQueue.main.async {
                    self.mentalHealthScore = score
                }
            case .failure(let error):
                print("Error fetching mental health score: \(error)")
            }
        }
    }
    
    private func calculateTrend(old: Int, new: Int) -> TrendDirection {
        if new > old + 5 { return .up }
        if new < old - 5 { return .down }
        return .neutral
    }
}

// MARK: - Data Models

extension VitalSigns {
    static let defaultValues = VitalSigns(
        heartRate: 72,
        respiratoryRate: 16,
        bloodOxygen: 98,
        temperature: 98.6,
        heartRateTrend: .neutral,
        respiratoryTrend: .neutral,
        oxygenTrend: .neutral
    )
}

extension CardiacMetrics {
    static let defaultValues = CardiacMetrics(
        hrv: 65,
        systolic: 120,
        diastolic: 80,
        ecgPreview: [0.1, 0.3, 0.7, 1.0, 0.8, 0.4, 0.2, 0.1],
        arrhythmiaRisk: .low
    )
}

struct ActivityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let activeMinutes: Int
}