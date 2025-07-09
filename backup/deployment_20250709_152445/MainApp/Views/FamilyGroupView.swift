import SwiftUI

/// Main view for managing family/group health, members, shared analytics, goals, and challenges.
struct FamilyGroupView: View {
    @ObservedObject var familyGroupSkill: FamilyGroupHealthSkill
    @State private var showingAddMember = false
    @State private var showingCreateGoal = false
    @State private var selectedMember: FamilyGroupMember? = nil
    @State private var showAR = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Group Members")) {
                    ForEach(familyGroupSkill.members) { member in
                        HStack {
                            Text(member.displayName)
                            Spacer()
                            if member.isOwner { Text("Owner").font(.caption).foregroundColor(.blue) }
                        }
                        .onTapGesture { selectedMember = member }
                    }
                    Button(action: { showingAddMember = true }) {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                }
                Section(header: Text("Shared Goals & Challenges")) {
                    ForEach(familyGroupSkill.goals) { goal in
                        VStack(alignment: .leading) {
                            Text(goal.title).bold()
                            ProgressView(value: goal.progress)
                            Text(goal.description).font(.caption)
                        }
                    }
                    Button(action: { showingCreateGoal = true }) {
                        Label("Create Goal/Challenge", systemImage: "target")
                    }
                }
                Section(header: Text("Group Analytics")) {
                    // Integrate with analytics engine
                    GroupAnalyticsView(analytics: familyGroupSkill.groupAnalytics)
                }
            }
            .navigationTitle("Family/Group Health")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAR = true }) {
                        Label("AR View", systemImage: "arkit")
                    }
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView(familyGroupSkill: familyGroupSkill)
            }
            .sheet(isPresented: $showingCreateGoal) {
                CreateGoalView(familyGroupSkill: familyGroupSkill)
            }
            .sheet(isPresented: $showAR) {
                ARHealthVisualizerView()
            }
            .alert(item: $selectedMember) { member in
                Alert(title: Text(member.displayName), message: Text("Email: \(member.email)\nRole: \(member.isOwner ? "Owner" : "Member")"), dismissButton: .default(Text("OK")))
            }
        }
    }
}

// MARK: - Supporting Views

struct AddMemberView: View {
    @ObservedObject var familyGroupSkill: FamilyGroupHealthSkill
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Invite Member").font(.headline)
            TextField("Email", text: $email).textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Send Invite") {
                familyGroupSkill.inviteMember(email: email)
                presentationMode.wrappedValue.dismiss()
            }.disabled(email.isEmpty)
            Spacer()
        }.padding()
    }
}

struct CreateGoalView: View {
    @ObservedObject var familyGroupSkill: FamilyGroupHealthSkill
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    @State private var description = ""
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Group Goal/Challenge").font(.headline)
            TextField("Title", text: $title).textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Description", text: $description).textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Create") {
                familyGroupSkill.createGoal(title: title, description: description)
                presentationMode.wrappedValue.dismiss()
            }.disabled(title.isEmpty)
            Spacer()
        }.padding()
    }
}

struct GroupAnalyticsView: View {
    let analytics: GroupAnalytics
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Members: \(analytics.activeMembers)")
            Text("Avg. Steps: \(analytics.averageSteps, specifier: "%.0f")")
            Text("Shared Achievements: \(analytics.sharedAchievements)")
            // Add more analytics as needed
        }
    }
}

// MARK: - Preview
#if DEBUG
struct FamilyGroupView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyGroupView(familyGroupSkill: .preview)
    }
}
#endif
