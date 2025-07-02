import SwiftUI
import HealthKit
import AVFoundation
import CoreHaptics
import Combine
import os.log

// MARK: - Main Sleep View

struct SleepView: View {
    @StateObject private var sleepManager = SleepManager()
    @StateObject private var healthKitManager = HealthKitManager()
    @StateObject private var appleWatchManager = AppleWatchManager()
    @StateObject private var audioEngine = AudioGenerationEngine()
    @StateObject private var smartAlarm = SmartAlarmSystem()
    
    @State private var showingSleepSession = false
    @State private var showingSettings = false
    @State private var showingAppleWatchSetup = false
    @State private var isAnalyzingHistoricalData = false
    @State private var analysisProgress: Double = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with sleep score
                    SleepScoreHeader(sleepManager: sleepManager)
                    
                    // Sleep session controls
                    SleepSessionControls(
                        sleepManager: sleepManager,
                        showingSession: $showingSleepSession
                    )
                    
                    // Enhanced Audio Controls
                    AudioControlsSection(audioEngine: audioEngine)
                    
                    // Smart alarm section
                    SmartAlarmSection(smartAlarm: smartAlarm)
                    
                    // Apple Watch integration
                    AppleWatchSection(
                        appleWatchManager: appleWatchManager,
                        showingSetup: $showingAppleWatchSetup
                    )
                    
                    // Sleep insights
                    SleepInsightsSection(sleepManager: sleepManager)
                    
                    // Health data summary
                    HealthDataSection(healthKitManager: healthKitManager)
                }
                .padding()
            }
            .navigationTitle("SomnaSync Pro")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSleepSession) {
                SleepSessionView(sleepManager: sleepManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    sleepManager: sleepManager,
                    healthKitManager: healthKitManager,
                    appleWatchManager: appleWatchManager
                )
            }
            .sheet(isPresented: $showingAppleWatchSetup) {
                AppleWatchSetupView(appleWatchManager: appleWatchManager)
            }
            .onAppear {
                setupApp()
            }
            .overlay(
                // Historical data analysis overlay
                Group {
                    if isAnalyzingHistoricalData {
                        HistoricalDataAnalysisOverlay(
                            progress: analysisProgress,
                            onComplete: {
                                isAnalyzingHistoricalData = false
                                analysisProgress = 0.0
                            }
                        )
                    }
                }
            )
        }
    }
    
    private func setupApp() {
        Task {
            // Request HealthKit permissions
            await healthKitManager.requestPermissions()
            
            // Check if historical data analysis is needed
            if !UserDefaults.standard.bool(forKey: "historicalDataAnalyzed") {
                isAnalyzingHistoricalData = true
                await analyzeHistoricalData()
            }
            
            // Start Apple Watch monitoring
            await appleWatchManager.startMonitoring()
        }
    }
    
    private func analyzeHistoricalData() async {
        let dataManager = DataManager()
        
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                analysisProgress = Double(i) / 10.0
            }
        }
        
        await dataManager.analyzeHistoricalData()
        UserDefaults.standard.set(true, forKey: "historicalDataAnalyzed")
    }
}

