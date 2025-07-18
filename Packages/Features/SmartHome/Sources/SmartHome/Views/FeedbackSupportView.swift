import SwiftUI
import Combine

/// Comprehensive SwiftUI view for Feedback & Support
/// Provides interface for submitting feedback, bug reports, and support tickets
public struct FeedbackSupportView: View {
    @StateObject private var manager = FeedbackSupportManager.shared
    @State private var selectedTab = 0
    @State private var feedbackType: FeedbackSupportManager.FeedbackType = .general
    @State private var feedbackMessage = ""
    @State private var feedbackEmail = ""
    @State private var feedbackScreenshot: Data? = nil
    @State private var ticketSubject = ""
    @State private var ticketDescription = ""
    @State private var ticketEmail = ""
    @State private var showSubmissionAlert = false
    @State private var submissionMessage = ""
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                tabSelectionView
                
                TabView(selection: $selectedTab) {
                    feedbackTabView
                        .tag(0)
                    
                    bugReportTabView
                        .tag(1)
                    
                    supportTabView
                        .tag(2)
                    
                    historyTabView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Feedback & Support")
            .navigationBarTitleDisplayMode(.large)
            .alert(isPresented: $showSubmissionAlert) {
                Alert(title: Text("Submission"), message: Text(submissionMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Tab Selection
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(["Feedback", "Bug Report", "Support", "History"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Feedback", "Bug Report", "Support", "History"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(tab)
                            .font(.subheadline)
                            .fontWeight(selectedTab == ["Feedback", "Bug Report", "Support", "History"].firstIndex(of: tab) ? .semibold : .regular)
                            .foregroundColor(selectedTab == ["Feedback", "Bug Report", "Support", "History"].firstIndex(of: tab) ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == ["Feedback", "Bug Report", "Support", "History"].firstIndex(of: tab) ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(width: 100)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Feedback Tab
    private var feedbackTabView: some View {
        Form {
            Picker("Type", selection: $feedbackType) {
                ForEach(FeedbackSupportManager.FeedbackType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            
            TextField("Your feedback...", text: $feedbackMessage, axis: .vertical)
                .lineLimit(3...6)
            
            TextField("Email (optional)", text: $feedbackEmail)
                .keyboardType(.emailAddress)
            
            Button("Submit Feedback") {
                submitFeedback()
            }
            .disabled(feedbackMessage.isEmpty || manager.isSubmitting)
        }
        .padding()
    }
    
    // MARK: - Bug Report Tab
    private var bugReportTabView: some View {
        Form {
            TextField("Describe the bug...", text: $feedbackMessage, axis: .vertical)
                .lineLimit(3...6)
            
            TextField("Email (optional)", text: $feedbackEmail)
                .keyboardType(.emailAddress)
            
            Button("Submit Bug Report") {
                feedbackType = .bug
                submitFeedback()
            }
            .disabled(feedbackMessage.isEmpty || manager.isSubmitting)
        }
        .padding()
    }
    
    // MARK: - Support Tab
    private var supportTabView: some View {
        Form {
            TextField("Subject", text: $ticketSubject)
            TextField("Describe your issue...", text: $ticketDescription, axis: .vertical)
                .lineLimit(3...6)
            TextField("Email (optional)", text: $ticketEmail)
                .keyboardType(.emailAddress)
            Button("Submit Support Ticket") {
                submitTicket()
            }
            .disabled(ticketSubject.isEmpty || ticketDescription.isEmpty || manager.isSubmitting)
        }
        .padding()
    }
    
    // MARK: - History Tab
    private var historyTabView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Feedback History")
                    .font(.headline)
                ForEach(manager.feedbacks) { entry in
                    FeedbackHistoryCard(entry: entry)
                }
                Divider()
                Text("Support Tickets")
                    .font(.headline)
                ForEach(manager.tickets) { ticket in
                    TicketHistoryCard(ticket: ticket)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Submission Methods
    private func submitFeedback() {
        let entry = FeedbackSupportManager.FeedbackEntry(
            type: feedbackType,
            message: feedbackMessage,
            email: feedbackEmail.isEmpty ? nil : feedbackEmail,
            screenshot: feedbackScreenshot
        )
        manager.submitFeedback(entry)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            submissionMessage = manager.submissionResult?.successMessage ?? manager.submissionResult?.failureMessage ?? "Unknown result."
            showSubmissionAlert = true
            feedbackMessage = ""
            feedbackEmail = ""
        }
    }
    
    private func submitTicket() {
        let ticket = FeedbackSupportManager.SupportTicket(
            subject: ticketSubject,
            description: ticketDescription,
            email: ticketEmail.isEmpty ? nil : ticketEmail
        )
        manager.submitTicket(ticket)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            submissionMessage = manager.submissionResult?.successMessage ?? manager.submissionResult?.failureMessage ?? "Unknown result."
            showSubmissionAlert = true
            ticketSubject = ""
            ticketDescription = ""
            ticketEmail = ""
        }
    }
}

// MARK: - Supporting Views

struct FeedbackHistoryCard: View {
    let entry: FeedbackSupportManager.FeedbackEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.type.rawValue)
                    .font(.headline)
                Spacer()
                Text(entry.status.rawValue)
                    .font(.caption)
                    .foregroundColor(entry.status == .resolved ? .green : .orange)
            }
            Text(entry.message)
                .font(.body)
            if let email = entry.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(entry.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TicketHistoryCard: View {
    let ticket: FeedbackSupportManager.SupportTicket
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(ticket.subject)
                    .font(.headline)
                Spacer()
                Text(ticket.status.rawValue)
                    .font(.caption)
                    .foregroundColor(ticket.status == .resolved ? .green : .orange)
            }
            Text(ticket.description)
                .font(.body)
            if let email = ticket.email {
                Text(email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(ticket.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

private extension FeedbackSupportManager.SubmissionResult {
    var successMessage: String? {
        if case let .success(msg) = self { return msg } else { return nil }
    }
    var failureMessage: String? {
        if case let .failure(msg) = self { return msg } else { return nil }
    }
}

#Preview {
    FeedbackSupportView()
} 