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
        // TODO: Integrate with notification system to send invite
    }

    // Create a new group goal
    public func createGoal(title: String, description: String) {
        let newGoal = GroupGoal(title: title, description: description, progress: 0.0)
        goals.append(newGoal)
        // TODO: Integrate with analytics and notification system
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
