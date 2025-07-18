import SwiftUI

struct SecurityAuditView: View {
    @ObservedObject var securityManager: AdvancedSecurityPrivacyManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedEventType: AdvancedSecurityPrivacyManager.SecurityEventType?
    @State private var selectedSeverity: AdvancedSecurityPrivacyManager.SecuritySeverity?
    @State private var searchText = ""
    @State private var showingEventDetails = false
    @State private var selectedEvent: AdvancedSecurityPrivacyManager.SecurityAuditEntry?
    
    var filteredEvents: [AdvancedSecurityPrivacyManager.SecurityAuditEntry] {
        var events = securityManager.securityAuditLog
        
        // Filter by search text
        if !searchText.isEmpty {
            events = events.filter { event in
                event.description.localizedCaseInsensitiveContains(searchText) ||
                event.eventType.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by event type
        if let eventType = selectedEventType {
            events = events.filter { $0.eventType == eventType }
        }
        
        // Filter by severity
        if let severity = selectedSeverity {
            events = events.filter { $0.severity == severity }
        }
        
        return events.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters Section
                filtersSection
                
                // Statistics Section
                statisticsSection
                
                // Events List
                eventsList
            }
            .navigationTitle(NSLocalizedString("Security Audit", comment: "Security audit navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(NSLocalizedString("Close", comment: "Close button")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(NSLocalizedString("Export", comment: "Export button")) {
                    exportAuditLog()
                }
            )
            .searchable(text: $searchText, prompt: NSLocalizedString("Search events", comment: "Search events prompt"))
            .sheet(isPresented: $showingEventDetails) {
                if let event = selectedEvent {
                    SecurityEventDetailView(event: event)
                }
            }
        }
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Event Type Filter
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Event Type", comment: "Event type filter label"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: NSLocalizedString("All", comment: "All events filter"),
                            isSelected: selectedEventType == nil
                        ) {
                            selectedEventType = nil
                        }
                        
                        ForEach(AdvancedSecurityPrivacyManager.SecurityEventType.allCases, id: \.self) { eventType in
                            FilterChip(
                                title: eventType.rawValue.capitalized,
                                isSelected: selectedEventType == eventType
                            ) {
                                selectedEventType = selectedEventType == eventType ? nil : eventType
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Severity Filter
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Severity", comment: "Severity filter label"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: NSLocalizedString("All", comment: "All severities filter"),
                            isSelected: selectedSeverity == nil
                        ) {
                            selectedSeverity = nil
                        }
                        
                        ForEach(AdvancedSecurityPrivacyManager.SecuritySeverity.allCases, id: \.self) { severity in
                            FilterChip(
                                title: severity.rawValue.capitalized,
                                isSelected: selectedSeverity == severity,
                                color: severityColor(for: severity)
                            ) {
                                selectedSeverity = selectedSeverity == severity ? nil : severity
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Audit Statistics", comment: "Audit statistics section title"))
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: NSLocalizedString("Total Events", comment: "Total events stat"),
                    value: "\(filteredEvents.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: NSLocalizedString("Critical", comment: "Critical events stat"),
                    value: "\(criticalEventsCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                StatCard(
                    title: NSLocalizedString("Today", comment: "Today's events stat"),
                    value: "\(todayEventsCount)",
                    icon: "calendar",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    // MARK: - Events List
    private var eventsList: some View {
        List {
            ForEach(filteredEvents) { event in
                SecurityEventRow(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                        showingEventDetails = true
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Computed Properties
    private var criticalEventsCount: Int {
        filteredEvents.filter { $0.severity == .critical }.count
    }
    
    private var todayEventsCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return filteredEvents.filter { $0.timestamp >= today }.count
    }
    
    // MARK: - Helper Methods
    private func severityColor(for severity: AdvancedSecurityPrivacyManager.SecuritySeverity) -> Color {
        switch severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
    
    private func exportAuditLog() {
        // In a real implementation, this would export the audit log
        let exportData = filteredEvents.map { event in
            "\(event.timestamp), \(event.eventType.rawValue), \(event.severity.rawValue), \(event.description)"
        }.joined(separator: "\n")
        
        print("Audit log exported:\n\(exportData)")
    }
}

// MARK: - Supporting Views
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SecurityEventRow: View {
    let event: AdvancedSecurityPrivacyManager.SecurityAuditEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                    
                    Text(event.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(event.eventType.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(severityColor.opacity(0.1))
                        .foregroundColor(severityColor)
                        .cornerRadius(8)
                    
                    Text(event.severity.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(severityColor)
                }
            }
            
            if !event.metadata.isEmpty {
                HStack {
                    ForEach(Array(event.metadata.keys.prefix(3)), id: \.self) { key in
                        Text("\(key): \(event.metadata[key] ?? "")")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
        switch event.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct SecurityEventDetailView: View {
    let event: AdvancedSecurityPrivacyManager.SecurityAuditEntry
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event Overview
                    eventOverviewSection
                    
                    // Event Details
                    eventDetailsSection
                    
                    // Metadata
                    if !event.metadata.isEmpty {
                        metadataSection
                    }
                }
                .padding()
            }
            .navigationTitle(NSLocalizedString("Event Details", comment: "Event details navigation title"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("Done", comment: "Done button")) {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var eventOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Event Overview", comment: "Event overview section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: NSLocalizedString("Description", comment: "Description label"),
                    value: event.description
                )
                
                DetailRow(
                    title: NSLocalizedString("Type", comment: "Type label"),
                    value: event.eventType.rawValue.capitalized
                )
                
                DetailRow(
                    title: NSLocalizedString("Severity", comment: "Severity label"),
                    value: event.severity.rawValue.capitalized,
                    valueColor: severityColor
                )
                
                DetailRow(
                    title: NSLocalizedString("Timestamp", comment: "Timestamp label"),
                    value: event.timestamp.formatted(date: .complete, time: .complete)
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Event Details", comment: "Event details section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let userId = event.userId {
                    DetailRow(
                        title: NSLocalizedString("User ID", comment: "User ID label"),
                        value: userId
                    )
                }
                
                if let ipAddress = event.ipAddress {
                    DetailRow(
                        title: NSLocalizedString("IP Address", comment: "IP address label"),
                        value: ipAddress
                    )
                }
                
                if let deviceInfo = event.deviceInfo {
                    DetailRow(
                        title: NSLocalizedString("Device", comment: "Device label"),
                        value: deviceInfo
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("Additional Data", comment: "Additional data section title"))
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(Array(event.metadata.keys.sorted()), id: \.self) { key in
                    DetailRow(
                        title: key.capitalized,
                        value: event.metadata[key] ?? ""
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var severityColor: Color {
        switch event.severity {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    SecurityAuditView(securityManager: AdvancedSecurityPrivacyManager())
} 