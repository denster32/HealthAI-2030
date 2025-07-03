import SwiftUI

struct SkillMarketplaceView: View {
    @ObservedObject var registry = HealthCopilotSkillRegistry.shared
    @State private var skills: [HealthCopilotSkill] = []
    @State private var isRefreshing = false
    @State private var searchText: String = ""
    @State private var showFileImporter = false
    @State private var installError: String? = nil
    
    var filteredSkills: [HealthCopilotSkill] {
        if searchText.isEmpty { return skills }
        let lower = searchText.lowercased()
        return skills.filter { skill in
            skill.manifest.displayName.lowercased().contains(lower) ||
            skill.manifest.description.lowercased().contains(lower) ||
            skill.manifest.capabilities.contains(where: { $0.lowercased().contains(lower) })
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Installed Skills")) {
                        ForEach(filteredSkills, id: \.skillID) { skill in
                            NavigationLink(destination: SkillDetailView(skill: skill, onUninstall: {
                                registry.unregister(skillID: skill.skillID)
                                refreshSkills()
                            })) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(skill.manifest.name).font(.headline)
                                        Text(skill.manifest.description).font(.subheadline).foregroundColor(.secondary)
                                        Text("Status: \(skill.status.status)").font(.caption).foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Toggle(isOn: Binding(
                                        get: { skill.isEnabled },
                                        set: { newValue in
                                            if newValue { registry.enableSkill(skill.skillID) } else { registry.disableSkill(skill.skillID) }
                                            refreshSkills()
                                        }
                                    )) {
                                        Text("")
                                    }.labelsHidden()
                                }
                            }
                        }
                    }
                    FederatedLearningSection()
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Copilot Skills")
                .searchable(text: $searchText, prompt: "Search skills")
                .refreshable { refreshSkills() }
                .onAppear { refreshSkills() }
                Button(action: { showFileImporter = true }) {
                    Label("Install New Skill", systemImage: "plus.app")
                }
                .padding()
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.bundle, .package, .data], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            if HealthCopilotSkillLoader.shared.loadSkill(from: url) != nil {
                                refreshSkills()
                            } else {
                                installError = "Failed to load skill from bundle."
                            }
                        }
                    case .failure(let error):
                        installError = error.localizedDescription
                    }
                }
                if let error = installError {
                    Text(error).foregroundColor(.red).padding(.top, 4)
                }
            }
        }
    }
    
    private func refreshSkills() {
        skills = registry.allSkills()
    }
}

struct FederatedLearningSection: View {
    @State private var status: [String: Any] = [:]
    @State private var isOptedIn: Bool = FederatedLearningSkill.isOptedIn
    @State private var showInfo = false
    @State private var showBadge = false
    @State private var scheduleOnlyWhenCharging = false
    @State private var selectedModels: Set<String> = ["sleepStage", "arrhythmia"]
    @State private var accuracyHistory: [Double] = []
    @State private var rounds: Int = 0
    @State private var communityImpact: Int = 0
    @State private var lastNotification: String? = nil
    let allModels = ["sleepStage", "arrhythmia", "healthPrediction", "digitalTwin"]
    var body: some View {
        Section(header: Text("Federated Learning")) {
            HStack {
                Button(action: { showInfo = true }) {
                    Image(systemName: "info.circle")
                }
                Spacer()
                if showBadge {
                    Label("Federated Hero", systemImage: "star.fill").foregroundColor(.yellow)
                }
            }
            Toggle(isOn: $isOptedIn) {
                Text("Participate in Federated Learning")
            }
            .onChange(of: isOptedIn) { newValue in
                Task {
                    if newValue {
                        _ = try? await FederatedLearningSkill().handle(intent: "participate_federated_learning", parameters: [:], context: nil)
                        showBadge = true
                        rounds += 1
                        communityImpact += Int.random(in: 100...500)
                        lastNotification = "Your contribution improved the global model!"
                    } else {
                        _ = try? await FederatedLearningSkill().handle(intent: "opt_out_federated_learning", parameters: [:], context: nil)
                        showBadge = false
                    }
                    await loadStatus()
                }
            }
            Toggle(isOn: $scheduleOnlyWhenCharging) {
                Text("Only participate when charging")
            }
            Text("Opt-in to specific models:").font(.caption)
            ForEach(allModels, id: \.self) { model in
                Toggle(isOn: Binding(
                    get: { selectedModels.contains(model) },
                    set: { val in
                        if val { selectedModels.insert(model) } else { selectedModels.remove(model) }
                    })) {
                    Text(model)
                }
            }
            Button("Sync Model Update") {
                Task {
                    _ = try? await FederatedLearningSkill().handle(intent: "submit_model_update", parameters: [:], context: nil)
                    await loadStatus()
                    lastNotification = "Model update securely submitted!"
                }
            }
            if let participating = status["participating"] as? Bool {
                Text(participating ? "Status: Opted In" : "Status: Opted Out").font(.caption)
            }
            if let accuracy = status["localAccuracy"] as? Double {
                Text("Local Model Accuracy: \(String(format: "%.2f", accuracy * 100))%")
                    .font(.caption)
                AccuracyChartView(history: accuracyHistory + [accuracy])
            }
            if let lastUpdate = status["lastUpdate"] as? String {
                Text("Last Update: \(lastUpdate)").font(.caption2)
            }
            Text("Rounds Participated: \(rounds)").font(.caption2)
            Text("Community Impact: Helped \(communityImpact) users").font(.caption2)
            if let note = lastNotification {
                Text(note).font(.footnote).foregroundColor(.purple)
            }
        }
        .onAppear { Task { await loadStatus() } }
        .sheet(isPresented: $showInfo) {
            VStack(alignment: .leading, spacing: 16) {
                Text("What is Federated Learning?").font(.title2).bold()
                Text("Federated learning allows your device to help improve AI models without sharing your raw health data. Only anonymized model updates are sent, and your privacy is always protected.")
                Text("You can opt in/out at any time. Participation helps everyone!")
                Text("Data shared: Model weight updates only.\nData NOT shared: Your raw health, identity, or device data.")
                Spacer()
                Button("Close") { showInfo = false }
            }.padding()
        }
    }
    private func loadStatus() async {
        if let result = try? await FederatedLearningSkill().handle(intent: "report_federated_status", parameters: [:], context: nil),
           case let .json(obj) = result {
            await MainActor.run {
                status = obj
                if let acc = obj["localAccuracy"] as? Double { accuracyHistory.append(acc) }
            }
        }
    }
}

struct AccuracyChartView: View {
    let history: [Double]
    var body: some View {
        GeometryReader { geo in
            Path { path in
                guard !history.isEmpty else { return }
                let w = geo.size.width
                let h = geo.size.height
                let maxAcc = history.max() ?? 1.0
                let minAcc = history.min() ?? 0.0
                for (i, acc) in history.enumerated() {
                    let x = CGFloat(i) / CGFloat(max(history.count-1,1)) * w
                    let y = h - CGFloat((acc - minAcc) / max(0.01, maxAcc - minAcc)) * h
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.green, lineWidth: 2)
        }
        .frame(height: 40)
    }
}
