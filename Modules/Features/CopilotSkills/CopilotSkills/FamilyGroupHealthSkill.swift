import Foundation
import SwiftUI

// MARK: - Models

public struct FamilyGroupMember: Identifiable, Codable, Hashable {
    public let id: UUID
    public var displayName: String
    public var email: String
    public var isOwner: Bool
    public init(id: UUID = UUID(), displayName: String, email: String, isOwner: Bool = false) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.isOwner = isOwner
    }
}

public struct GroupGoal: Identifiable, Codable, Hashable {
    public let id: UUID
    public var title: String
    public var description: String
    public var progress: Double // 0.0 - 1.0
    public init(id: UUID = UUID(), title: String, description: String, progress: Double = 0.0) {
        self.id = id
        self.title = title
        self.description = description
        self.progress = progress
    }
}

public struct GroupAnalytics: Codable, Hashable {
    public var activeMembers: Int
    public var averageSteps: Double
    public var sharedAchievements: Int
    public static let empty = GroupAnalytics(activeMembers: 0, averageSteps: 0, sharedAchievements: 0)
}

/// Family/Group Health Skill Plugin
public class FamilyGroupHealthSkill: HealthCopilotSkill, ObservableObject {
    public let skillID = "family.group.health"
    public let displayName = "Family & Group Health"
    public let description = "Enables group health analytics, shared goals, and collaborative insights."
    public let supportedIntents = ["get_group_summary", "set_group_goal", "join_group_challenge", "report_group_progress"]
    public var manifest: HealthCopilotSkillManifest { HealthCopilotSkillManifest(
        skillID: skillID,
        displayName: displayName,
        description: description,
        version: "1.0.0",
        author: "HealthAI 2030 Team",
        supportedIntents: supportedIntents,
        capabilities: ["group_analytics", "shared_goals", "challenges"],
        url: nil
    )}
    public var status: HealthCopilotSkillStatus { .healthy }
    
    @Published public var members: [FamilyGroupMember] = [
        FamilyGroupMember(displayName: "Alice", email: "alice@email.com", isOwner: true),
        FamilyGroupMember(displayName: "Bob", email: "bob@email.com", isOwner: false),
        FamilyGroupMember(displayName: "Charlie", email: "charlie@email.com", isOwner: false)
    ]
    @Published public var goals: [GroupGoal] = [
        GroupGoal(title: "10,000 steps/day", description: "Everyone walks 10,000 steps daily", progress: 0.85)
    ]
    @Published public var groupAnalytics: GroupAnalytics = GroupAnalytics(activeMembers: 3, averageSteps: 8500, sharedAchievements: 5)

    public init() {}
    
    // Invite a new member
    public func inviteMember(email: String) {
        let newMember = FamilyGroupMember(displayName: email.components(separatedBy: "@").first?.capitalized ?? email, email: email, isOwner: false)
        members.append(newMember)
        
        // Integrate with notification system to send invite
        Task {
            await sendInvitationNotification(email: email, member: newMember)
            await trackInvitationAnalytics(email: email)
        }
    }

    // Create a new group goal
    public func createGoal(title: String, description: String) {
        let newGoal = GroupGoal(title: title, description: description, progress: 0.0)
        goals.append(newGoal)
        
        // Integrate with analytics and notification system
        Task {
            await trackGoalCreationAnalytics(goal: newGoal)
            await sendGoalCreationNotification(goal: newGoal)
            await updateGroupAnalytics()
        }
    }
    
    // MARK: - Notification System Integration
    private func sendInvitationNotification(email: String, member: FamilyGroupMember) async {
        do {
            // Create invitation notification
            let notification = GroupInvitationNotification(
                recipientEmail: email,
                senderName: getCurrentUserDisplayName(),
                groupName: getGroupName(),
                invitationCode: generateInvitationCode(),
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            )
            
            // Send invitation via notification system
            let notificationManager = NotificationManager()
            try await notificationManager.sendGroupInvitation(notification)
            
            // Store invitation in local database
            await storeInvitation(notification)
            
            print("Invitation sent to \(email) successfully")
            
        } catch {
            print("Failed to send invitation to \(email): \(error)")
        }
    }
    
    private func sendGoalCreationNotification(goal: GroupGoal) async {
        do {
            // Create goal notification for all group members
            let notification = GroupGoalNotification(
                goalTitle: goal.title,
                goalDescription: goal.description,
                createdBy: getCurrentUserDisplayName(),
                groupName: getGroupName(),
                members: members.map { $0.email }
            )
            
            // Send notification to all group members
            let notificationManager = NotificationManager()
            try await notificationManager.sendGroupGoalNotification(notification)
            
            // Track notification delivery
            await trackNotificationDelivery(notification)
            
            print("Goal creation notification sent to group members")
            
        } catch {
            print("Failed to send goal creation notification: \(error)")
        }
    }
    
    // MARK: - Analytics Integration
    private func trackInvitationAnalytics(email: String) async {
        do {
            // Create analytics event
            let analyticsEvent = GroupAnalyticsEvent(
                eventType: "member_invitation_sent",
                timestamp: Date(),
                data: [
                    "invited_email": email,
                    "group_size": members.count,
                    "inviter_id": getCurrentUserID(),
                    "group_id": getGroupID()
                ]
            )
            
            // Send to analytics service
            let analyticsManager = AnalyticsManager()
            try await analyticsManager.trackGroupEvent(analyticsEvent)
            
            // Update local analytics
            await updateInvitationAnalytics(email: email)
            
        } catch {
            print("Failed to track invitation analytics: \(error)")
        }
    }
    
    private func trackGoalCreationAnalytics(goal: GroupGoal) async {
        do {
            // Create analytics event
            let analyticsEvent = GroupAnalyticsEvent(
                eventType: "group_goal_created",
                timestamp: Date(),
                data: [
                    "goal_id": goal.id.uuidString,
                    "goal_title": goal.title,
                    "goal_description": goal.description,
                    "creator_id": getCurrentUserID(),
                    "group_id": getGroupID(),
                    "group_size": members.count
                ]
            )
            
            // Send to analytics service
            let analyticsManager = AnalyticsManager()
            try await analyticsManager.trackGroupEvent(analyticsEvent)
            
            // Update local analytics
            await updateGoalAnalytics(goal: goal)
            
        } catch {
            print("Failed to track goal creation analytics: \(error)")
        }
    }
    
    private func updateGroupAnalytics() async {
        // Update group analytics with new data
        let updatedAnalytics = await calculateGroupAnalytics()
        
        await MainActor.run {
            self.groupAnalytics = updatedAnalytics
        }
        
        // Send updated analytics to backend
        await syncGroupAnalytics(updatedAnalytics)
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserDisplayName() -> String {
        // Get current user's display name
        return UserDefaults.standard.string(forKey: "UserDisplayName") ?? "Group Member"
    }
    
    private func getCurrentUserID() -> String {
        // Get current user's ID
        return UserDefaults.standard.string(forKey: "UserID") ?? UUID().uuidString
    }
    
    private func getGroupName() -> String {
        // Get group name
        return UserDefaults.standard.string(forKey: "GroupName") ?? "Family Health Group"
    }
    
    private func getGroupID() -> String {
        // Get group ID
        return UserDefaults.standard.string(forKey: "GroupID") ?? UUID().uuidString
    }
    
    private func generateInvitationCode() -> String {
        // Generate unique invitation code
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let code = String((0..<8).map { _ in characters.randomElement()! })
        return code
    }
    
    private func storeInvitation(_ notification: GroupInvitationNotification) async {
        // Store invitation in local database
        let invitationData = InvitationData(
            id: UUID(),
            recipientEmail: notification.recipientEmail,
            senderName: notification.senderName,
            groupName: notification.groupName,
            invitationCode: notification.invitationCode,
            expiresAt: notification.expiresAt,
            status: .pending,
            createdAt: Date()
        )
        
        // Save to local storage
        let invitationManager = InvitationManager()
        try? await invitationManager.storeInvitation(invitationData)
    }
    
    private func trackNotificationDelivery(_ notification: GroupGoalNotification) async {
        // Track notification delivery for analytics
        let deliveryEvent = NotificationDeliveryEvent(
            notificationType: "group_goal_creation",
            recipients: notification.members.count,
            deliveredAt: Date(),
            groupID: getGroupID()
        )
        
        let analyticsManager = AnalyticsManager()
        try? await analyticsManager.trackNotificationDelivery(deliveryEvent)
    }
    
    private func updateInvitationAnalytics(email: String) async {
        // Update local invitation analytics
        let invitationAnalytics = InvitationAnalytics(
            totalInvitations: getTotalInvitations() + 1,
            pendingInvitations: getPendingInvitations() + 1,
            acceptedInvitations: getAcceptedInvitations(),
            lastInvitationDate: Date()
        )
        
        // Store updated analytics
        await storeInvitationAnalytics(invitationAnalytics)
    }
    
    private func updateGoalAnalytics(goal: GroupGoal) async {
        // Update local goal analytics
        let goalAnalytics = GoalAnalytics(
            totalGoals: goals.count,
            activeGoals: goals.filter { $0.progress < 1.0 }.count,
            completedGoals: goals.filter { $0.progress >= 1.0 }.count,
            averageProgress: goals.map { $0.progress }.reduce(0, +) / Double(max(goals.count, 1)),
            lastGoalCreated: Date()
        )
        
        // Store updated analytics
        await storeGoalAnalytics(goalAnalytics)
    }
    
    private func calculateGroupAnalytics() async -> GroupAnalytics {
        // Calculate updated group analytics
        let activeMembers = await calculateActiveMembers()
        let averageSteps = await calculateAverageSteps()
        let sharedAchievements = await calculateSharedAchievements()
        
        return GroupAnalytics(
            activeMembers: activeMembers,
            averageSteps: averageSteps,
            sharedAchievements: sharedAchievements
        )
    }
    
    private func calculateActiveMembers() async -> Int {
        // Calculate number of active members in the last 7 days
        let healthKitManager = HealthKitManager()
        var activeCount = 0
        
        for member in members {
            let isActive = await healthKitManager.isMemberActive(memberID: member.id.uuidString, days: 7)
            if isActive {
                activeCount += 1
            }
        }
        
        return activeCount
    }
    
    private func calculateAverageSteps() async -> Double {
        // Calculate average steps across all group members
        let healthKitManager = HealthKitManager()
        var totalSteps = 0.0
        var memberCount = 0
        
        for member in members {
            let steps = await healthKitManager.getMemberSteps(memberID: member.id.uuidString, days: 7)
            totalSteps += steps
            memberCount += 1
        }
        
        return memberCount > 0 ? totalSteps / Double(memberCount) : 0.0
    }
    
    private func calculateSharedAchievements() async -> Int {
        // Calculate number of shared achievements
        let achievementManager = AchievementManager()
        return await achievementManager.getSharedAchievements(groupID: getGroupID())
    }
    
    private func syncGroupAnalytics(_ analytics: GroupAnalytics) async {
        // Sync group analytics with backend
        do {
            let analyticsManager = AnalyticsManager()
            try await analyticsManager.syncGroupAnalytics(analytics, groupID: getGroupID())
        } catch {
            print("Failed to sync group analytics: \(error)")
        }
    }
    
    // MARK: - Local Storage Helpers
    private func getTotalInvitations() -> Int {
        return UserDefaults.standard.integer(forKey: "TotalInvitations")
    }
    
    private func getPendingInvitations() -> Int {
        return UserDefaults.standard.integer(forKey: "PendingInvitations")
    }
    
    private func getAcceptedInvitations() -> Int {
        return UserDefaults.standard.integer(forKey: "AcceptedInvitations")
    }
    
    private func storeInvitationAnalytics(_ analytics: InvitationAnalytics) async {
        // Store invitation analytics locally
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(analytics)
            UserDefaults.standard.set(data, forKey: "InvitationAnalytics")
        } catch {
            print("Failed to store invitation analytics: \(error)")
        }
    }
    
    private func storeGoalAnalytics(_ analytics: GoalAnalytics) async {
        // Store goal analytics locally
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(analytics)
            UserDefaults.standard.set(data, forKey: "GoalAnalytics")
        } catch {
            print("Failed to store goal analytics: \(error)")
        }
    }

    public func handle(intent: String, parameters: [String: Any], context: HealthCopilotContext?) async throws -> HealthCopilotSkillResult {
        switch intent {
        case "get_group_summary":
            // Simulate group health summary
            let summary = [
                "members": ["Alice", "Bob", "Charlie"],
                "averageSteps": 8500,
                "groupGoal": "10,000 steps/day",
                "progress": 0.85
            ]
            return .json(summary)
        case "set_group_goal":
            let goal = parameters["goal"] as? String ?? ""
            return .text("Group goal set to: \(goal)")
        case "join_group_challenge":
            let challenge = parameters["challenge"] as? String ?? ""
            return .text("You have joined the group challenge: \(challenge)")
        case "report_group_progress":
            let progress = parameters["progress"] as? Double ?? 0.0
            return .text("Group progress updated: \(Int(progress * 100))% complete.")
        default:
            return .error("Intent not supported by FamilyGroupHealthSkill.")
        }
    }
}

#if DEBUG
extension FamilyGroupHealthSkill {
    public static var preview: FamilyGroupHealthSkill {
        let skill = FamilyGroupHealthSkill()
        return skill
    }
}
#endif
