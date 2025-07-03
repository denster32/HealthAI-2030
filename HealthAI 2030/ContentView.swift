//
//  ContentView.swift
//  HealthAI 2030
//
//  Created by Denster on 7/1/25.
//

import SwiftUI
import FamilyGroupView
import ProactiveNudgeSettingsView

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @ObservedObject var aiCoach = AIHealthCoach.shared
    @ObservedObject var analytics = DeepHealthAnalytics.shared
    @ObservedObject var biofeedback = BiofeedbackEngine.shared
    @ObservedObject var copilotChat = CopilotSkillChatEngine.shared
    @State private var showAR = false
    @State private var showSmartHome = false
    @State private var copilotInput: String = ""
    @State private var isUsingCopilot: Bool = false
    @StateObject private var familyGroupSkill = FamilyGroupHealthSkill()
    @StateObject private var proactiveNudgeSkill = ProactiveNudgeSkill()

    var body: some View {
        TabView(selection: $selectedTab) {
            // AI Health Coach
            NavigationView {
                VStack {
                    Image("AIHealthCoachIcon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .padding(.top, 32)
                    Text("AI Health Coach")
                        .font(.largeTitle).bold()
                        .padding(.bottom, 8)
                    Picker("Mode", selection: $isUsingCopilot) {
                        Text("Coach").tag(false)
                        Text("Copilot").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 8)
                    if isUsingCopilot {
                        List(copilotChat.chatHistory) { msg in
                            HStack(alignment: .top) {
                                if msg.role == .copilot {
                                    Image(systemName: "sparkles.circle.fill").foregroundColor(.purple)
                                } else {
                                    Image(systemName: "person.crop.circle").foregroundColor(.gray)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    // Try to parse JSON for explanation/graph
                                    if let data = msg.content.data(using: .utf8),
                                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                        if let explanation = obj["explanation"] as? String {
                                            Text(explanation).font(.body)
                                        }
                                        if let markdown = obj["markdown"] as? String {
                                            Text(markdown).font(.callout).foregroundColor(.secondary)
                                        }
                                        if let graph = obj["causalGraph"] as? [String: Any] {
                                            CausalGraphView(graph: graph)
                                        }
                                    } else {
                                        Text(msg.content)
                                    }
                                }
                            }
                        }
                        HStack {
                            TextField("Ask Copilot...", text: $copilotInput)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Send") {
                                let input = copilotInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !input.isEmpty else { return }
                                Task {
                                    await copilotChat.sendUserMessage(input, context: /* TODO: Provide real context */ CopilotSkillChatEngineContext.default)
                                }
                                copilotInput = ""
                            }
                        }.padding()
                    } else {
                        List(aiCoach.conversationHistory, id: \.timestamp) { msg in
                            HStack(alignment: .top) {
                                Image(systemName: "person.crop.circle").foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(msg.userMessage)
                                    Text(msg.coachResponse).foregroundColor(.blue)
                                }
                            }
                        }
                        HStack {
                            TextField("Ask your coach...", text: .constant(""), onCommit: {})
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Send") {}
                        }.padding()
                    }
                }
            }
            .tabItem {
                Image("AIHealthCoachIcon")
                Text("Coach")
            }.tag(0)
            
            // AR Health Visualizer
            Button(action: { showAR.toggle() }) {
                VStack {
                    Image("ARVisualizerIcon").resizable().frame(width: 80, height: 80)
                    Text("AR Health Visualizer").font(.title2).bold()
                }
            }
            .sheet(isPresented: $showAR) {
                ARHealthVisualizerView()
            }
            .tabItem {
                Image("ARVisualizerIcon")
                Text("AR")
            }.tag(1)
            
            // Biofeedback
            NavigationView {
                VStack {
                    Image("BiofeedbackIcon").resizable().frame(width: 80, height: 80)
                    Text("Biofeedback & Mindfulness").font(.title2).bold()
                    if let session = biofeedback.currentSession {
                        Text("Session: \(session.type.rawValue.capitalized)")
                    } else {
                        Text("No session active")
                    }
                    HStack {
                        ForEach(BiofeedbackType.allCases, id: \ .self) { type in
                            Button(type.rawValue.capitalized) {
                                biofeedback.startSession(type: type)
                            }.padding(8)
                        }
                    }
                    Button("Stop") { biofeedback.stopSession() }.padding(.top, 8)
                }
            }
            .tabItem {
                Image("BiofeedbackIcon")
                Text("Biofeedback")
            }.tag(2)
            
            // Smart Home
            Button(action: { showSmartHome.toggle() }) {
                VStack {
                    Image("SmartHomeIcon").resizable().frame(width: 80, height: 80)
                    Text("Smart Home").font(.title2).bold()
                }
            }
            .sheet(isPresented: $showSmartHome) {
                SmartHomeIntegrationView()
            }
            .tabItem {
                Image("SmartHomeIcon")
                Text("Home")
            }.tag(3)
            
            // Deep Analytics
            NavigationView {
                VStack {
                    Image("AnalyticsIcon").resizable().frame(width: 80, height: 80)
                    Text("Deep Analytics").font(.title2).bold()
                    List(analytics.trends, id: \ .metric) { trend in
                        VStack(alignment: .leading) {
                            Text("\(trend.metric): \(trend.direction.capitalized)")
                            Text("Confidence: \(Int(trend.confidence * 100))%")
                                .font(.caption)
                        }
                    }
                    List(analytics.predictions, id: \ .event) { pred in
                        VStack(alignment: .leading) {
                            Text("Prediction: \(pred.event)")
                            Text("Probability: \(Int(pred.probability * 100))% in \(pred.timeframe)")
                                .font(.caption)
                        }
                    }
                }
            }
            .tabItem {
                Image("AnalyticsIcon")
                Text("Analytics")
            }.tag(4)

            // Copilot Skills Marketplace
            FederatedLearningSection()
            SkillMarketplaceView()
                .tabItem {
                    Image(systemName: "puzzlepiece.extension")
                    Text("Skills")
                }.tag(5)

            // Family Group Management
            FamilyGroupView(familyGroupSkill: familyGroupSkill)
                .tabItem {
                    Label("Group", systemImage: "person.3.fill")
                }.tag(6)

            // Proactive Nudges
            ProactiveNudgeSettingsView(nudgeSkill: proactiveNudgeSkill)
                .tabItem {
                    Label("Nudges", systemImage: "bell.badge")
                }.tag(7)
        }
        .accentColor(.purple)
        .background(LinearGradient(gradient: Gradient(colors: [.white, .purple.opacity(0.1)]), startPoint: .top, endPoint: .bottom))
    }
}

// MARK: - ARHealthVisualizerView
struct ARHealthVisualizerView: View {
    var body: some View {
        Text("[ARKit Health Visualizer goes here]")
        // Integrate ARHealthVisualizer with ARSCNView
    }
}

// MARK: - SmartHomeIntegrationView
struct SmartHomeIntegrationView: View {
    var body: some View {
        Text("[Smart Home Controls and Automation go here]")
        // Integrate SmartHomeIntegration logic
    }
}

#Preview {
    ContentView()
}
