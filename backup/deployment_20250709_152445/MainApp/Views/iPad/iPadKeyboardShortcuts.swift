import SwiftUI
import Combine

/// Manager for iPad keyboard shortcuts and menu system
@MainActor
class IPadKeyboardShortcutsManager: ObservableObject {
    @Published var currentSection: SidebarSection = .dashboard
    @Published var selectedItem: HealthItem?
    @Published var showingSearch = false
    @Published var showingSettings = false
    @Published var showingProfile = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardShortcuts()
    }
    
    // MARK: - Keyboard Shortcuts Setup
    
    private func setupKeyboardShortcuts() {
        // Navigation shortcuts
        setupNavigationShortcuts()
        
        // Action shortcuts
        setupActionShortcuts()
        
        // Search and utility shortcuts
        setupUtilityShortcuts()
    }
    
    private func setupNavigationShortcuts() {
        // Dashboard
        KeyboardShortcut(.init("1"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.dashboard)
            }
            .store(in: &cancellables)
        
        // Analytics
        KeyboardShortcut(.init("2"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.analytics)
            }
            .store(in: &cancellables)
        
        // Health Data
        KeyboardShortcut(.init("3"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.healthData)
            }
            .store(in: &cancellables)
        
        // AI Copilot
        KeyboardShortcut(.init("4"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.aiCopilot)
            }
            .store(in: &cancellables)
        
        // Sleep Tracking
        KeyboardShortcut(.init("5"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.sleepTracking)
            }
            .store(in: &cancellables)
        
        // Workouts
        KeyboardShortcut(.init("6"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.workouts)
            }
            .store(in: &cancellables)
        
        // Nutrition
        KeyboardShortcut(.init("7"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.nutrition)
            }
            .store(in: &cancellables)
        
        // Mental Health
        KeyboardShortcut(.init("8"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.mentalHealth)
            }
            .store(in: &cancellables)
        
        // Medications
        KeyboardShortcut(.init("9"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.medications)
            }
            .store(in: &cancellables)
        
        // Family
        KeyboardShortcut(.init("0"), modifiers: [.command])
            .sink { [weak self] in
                self?.navigateToSection(.family)
            }
            .store(in: &cancellables)
    }
    
    private func setupActionShortcuts() {
        // Search
        KeyboardShortcut(.init("f"), modifiers: [.command])
            .sink { [weak self] in
                self?.toggleSearch()
            }
            .store(in: &cancellables)
        
        // New conversation
        KeyboardShortcut(.init("n"), modifiers: [.command])
            .sink { [weak self] in
                self?.startNewConversation()
            }
            .store(in: &cancellables)
        
        // Quick health check
        KeyboardShortcut(.init("h"), modifiers: [.command])
            .sink { [weak self] in
                self?.performQuickHealthCheck()
            }
            .store(in: &cancellables)
        
        // Export data
        KeyboardShortcut(.init("e"), modifiers: [.command])
            .sink { [weak self] in
                self?.exportHealthData()
            }
            .store(in: &cancellables)
        
        // Refresh data
        KeyboardShortcut(.init("r"), modifiers: [.command])
            .sink { [weak self] in
                self?.refreshHealthData()
            }
            .store(in: &cancellables)
    }
    
    private func setupUtilityShortcuts() {
        // Settings
        KeyboardShortcut(.init(","), modifiers: [.command])
            .sink { [weak self] in
                self?.showSettings()
            }
            .store(in: &cancellables)
        
        // Profile
        KeyboardShortcut(.init("p"), modifiers: [.command])
            .sink { [weak self] in
                self?.showProfile()
            }
            .store(in: &cancellables)
        
        // Help
        KeyboardShortcut(.init("?"), modifiers: [.command])
            .sink { [weak self] in
                self?.showHelp()
            }
            .store(in: &cancellables)
        
        // Quit
        KeyboardShortcut(.init("q"), modifiers: [.command])
            .sink {
                NSApplication.shared.terminate(nil)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Actions
    
    private func navigateToSection(_ section: SidebarSection) {
        currentSection = section
        selectedItem = nil
    }
    
    // MARK: - Action Handlers
    
    private func toggleSearch() {
        showingSearch.toggle()
    }
    
    private func startNewConversation() {
        // Navigate to AI Copilot and start new conversation
        currentSection = .aiCopilot
        // Trigger new conversation creation
    }
    
    private func performQuickHealthCheck() {
        // Perform a quick health assessment
        print("Performing quick health check...")
    }
    
    private func exportHealthData() {
        // Export health data
        print("Exporting health data...")
    }
    
    private func refreshHealthData() {
        // Refresh health data from HealthKit
        print("Refreshing health data...")
    }
    
    private func showSettings() {
        showingSettings = true
    }
    
    private func showProfile() {
        showingProfile = true
    }
    
    private func showHelp() {
        // Show help documentation
        print("Showing help...")
    }
}

// MARK: - Menu System

struct IPadMenuSystem: Commands {
    @ObservedObject var shortcutsManager: IPadKeyboardShortcutsManager
    
    var body: some Commands {
        // File Menu
        CommandGroup(after: .newItem) {
            Button("New Conversation") {
                shortcutsManager.startNewConversation()
            }
            .keyboardShortcut("n", modifiers: [.command])
            
            Button("Export Health Data") {
                shortcutsManager.exportHealthData()
            }
            .keyboardShortcut("e", modifiers: [.command])
        }
        
        // Edit Menu
        CommandGroup(after: .pasteboard) {
            Button("Search") {
                shortcutsManager.toggleSearch()
            }
            .keyboardShortcut("f", modifiers: [.command])
            
            Button("Refresh Data") {
                shortcutsManager.refreshHealthData()
            }
            .keyboardShortcut("r", modifiers: [.command])
        }
        
        // View Menu
        CommandGroup(after: .sidebar) {
            Button("Dashboard") {
                shortcutsManager.navigateToSection(.dashboard)
            }
            .keyboardShortcut("1", modifiers: [.command])
            
            Button("Analytics") {
                shortcutsManager.navigateToSection(.analytics)
            }
            .keyboardShortcut("2", modifiers: [.command])
            
            Button("Health Data") {
                shortcutsManager.navigateToSection(.healthData)
            }
            .keyboardShortcut("3", modifiers: [.command])
            
            Button("AI Copilot") {
                shortcutsManager.navigateToSection(.aiCopilot)
            }
            .keyboardShortcut("4", modifiers: [.command])
            
            Button("Sleep Tracking") {
                shortcutsManager.navigateToSection(.sleepTracking)
            }
            .keyboardShortcut("5", modifiers: [.command])
            
            Button("Workouts") {
                shortcutsManager.navigateToSection(.workouts)
            }
            .keyboardShortcut("6", modifiers: [.command])
            
            Button("Nutrition") {
                shortcutsManager.navigateToSection(.nutrition)
            }
            .keyboardShortcut("7", modifiers: [.command])
            
            Button("Mental Health") {
                shortcutsManager.navigateToSection(.mentalHealth)
            }
            .keyboardShortcut("8", modifiers: [.command])
            
            Button("Medications") {
                shortcutsManager.navigateToSection(.medications)
            }
            .keyboardShortcut("9", modifiers: [.command])
            
            Button("Family") {
                shortcutsManager.navigateToSection(.family)
            }
            .keyboardShortcut("0", modifiers: [.command])
        }
        
        // Health Menu
        CommandGroup(after: .windowSize) {
            Button("Quick Health Check") {
                shortcutsManager.performQuickHealthCheck()
            }
            .keyboardShortcut("h", modifiers: [.command])
            
            Button("Start Workout") {
                shortcutsManager.navigateToSection(.workouts)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
            
            Button("Log Medication") {
                shortcutsManager.navigateToSection(.medications)
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
        }
        
        // Window Menu
        CommandGroup(after: .window) {
            Button("Show Profile") {
                shortcutsManager.showProfile()
            }
            .keyboardShortcut("p", modifiers: [.command])
        }
        
        // Help Menu
        CommandGroup(after: .help) {
            Button("HealthAI 2030 Help") {
                shortcutsManager.showHelp()
            }
            .keyboardShortcut("?", modifiers: [.command])
        }
    }
}

// MARK: - Keyboard Shortcut Extensions

extension KeyboardShortcut {
    init(_ key: KeyEquivalent, modifiers: EventModifiers = []) {
        self.init(key, modifiers: modifiers)
    }
}

// MARK: - Search View

struct IPadSearchView: View {
    @ObservedObject var shortcutsManager: IPadKeyboardShortcutsManager
    @State private var searchText = ""
    @State private var searchResults: [HealthItem] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search health data, conversations, workouts...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    Button("Cancel") {
                        shortcutsManager.showingSearch = false
                    }
                    .keyboardShortcut(.escape)
                }
                .padding()
                
                // Search results
                if searchResults.isEmpty && !searchText.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("No results found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Try searching for different terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        
                        Text("Search for health data, conversations, workouts, and more")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Use ⌘F to search anytime")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults, id: \.id) { item in
                        HealthItemRow(item: item)
                            .onTapGesture {
                                selectSearchResult(item)
                            }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func performSearch() {
        // Perform search based on searchText
        // This would integrate with the actual search functionality
        searchResults = sampleSearchResults
    }
    
    private func selectSearchResult(_ item: HealthItem) {
        shortcutsManager.selectedItem = item
        shortcutsManager.showingSearch = false
        
        // Navigate to appropriate section based on item type
        switch item.type {
        case .healthCategory:
            shortcutsManager.navigateToSection(.healthData)
        case .conversation:
            shortcutsManager.navigateToSection(.aiCopilot)
        case .workout:
            shortcutsManager.navigateToSection(.workouts)
        case .medication:
            shortcutsManager.navigateToSection(.medications)
        }
    }
    
    private var sampleSearchResults: [HealthItem] {
        [
            HealthItem(
                title: "Heart Rate",
                subtitle: "Current: 72 BPM",
                type: .healthCategory(.heartRate),
                icon: "heart.fill",
                color: .red
            ),
            HealthItem(
                title: "Morning Check-in",
                subtitle: "How are you feeling?",
                type: .conversation("conv_1"),
                icon: "message.fill",
                color: .blue
            ),
            HealthItem(
                title: "Running",
                subtitle: "30 min workout",
                type: .workout(.running),
                icon: "figure.run",
                color: .green
            )
        ]
    }
}

// MARK: - Settings View

struct IPadSettingsView: View {
    @ObservedObject var shortcutsManager: IPadKeyboardShortcutsManager
    @State private var selectedTab = "General"
    
    var body: some View {
        NavigationView {
            List {
                Section("Keyboard Shortcuts") {
                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutRow(command: "⌘1", description: "Dashboard")
                        ShortcutRow(command: "⌘2", description: "Analytics")
                        ShortcutRow(command: "⌘3", description: "Health Data")
                        ShortcutRow(command: "⌘4", description: "AI Copilot")
                        ShortcutRow(command: "⌘5", description: "Sleep Tracking")
                        ShortcutRow(command: "⌘6", description: "Workouts")
                        ShortcutRow(command: "⌘7", description: "Nutrition")
                        ShortcutRow(command: "⌘8", description: "Mental Health")
                        ShortcutRow(command: "⌘9", description: "Medications")
                        ShortcutRow(command: "⌘0", description: "Family")
                    }
                }
                
                Section("Actions") {
                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutRow(command: "⌘F", description: "Search")
                        ShortcutRow(command: "⌘N", description: "New Conversation")
                        ShortcutRow(command: "⌘H", description: "Quick Health Check")
                        ShortcutRow(command: "⌘E", description: "Export Data")
                        ShortcutRow(command: "⌘R", description: "Refresh Data")
                    }
                }
                
                Section("Utilities") {
                    VStack(alignment: .leading, spacing: 8) {
                        ShortcutRow(command: "⌘,", description: "Settings")
                        ShortcutRow(command: "⌘P", description: "Profile")
                        ShortcutRow(command: "⌘?", description: "Help")
                        ShortcutRow(command: "⌘Q", description: "Quit")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        shortcutsManager.showingSettings = false
                    }
                }
            }
        }
    }
}

struct ShortcutRow: View {
    let command: String
    let description: String
    
    var body: some View {
        HStack {
            Text(description)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

// MARK: - Preview

#Preview {
    IPadSearchView(shortcutsManager: IPadKeyboardShortcutsManager())
} 