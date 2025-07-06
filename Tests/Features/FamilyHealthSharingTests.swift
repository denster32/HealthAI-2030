import XCTest
import HealthKit
import Combine
@testable import HealthAI2030

/// Comprehensive Unit Tests for Family Health Sharing & Monitoring Manager
/// Tests all functionality including member management, permissions, alerts, goals, and caregiver tools
@MainActor
final class FamilyHealthSharingTests: XCTestCase {
    
    // MARK: - Properties
    
    var familyManager: FamilyHealthSharingManager!
    var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        familyManager = FamilyHealthSharingManager()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        familyManager = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Family Member Management Tests
    
    func testAddFamilyMember() async throws {
        // Given
        let member = createTestFamilyMember(name: "John Doe", age: 35, relationship: .parent)
        
        // When
        try await familyManager.addFamilyMember(member)
        
        // Then
        XCTAssertEqual(familyManager.familyMembers.count, 1)
        XCTAssertEqual(familyManager.familyMembers.first?.name, "John Doe")
        XCTAssertEqual(familyManager.familyMembers.first?.age, 35)
        XCTAssertEqual(familyManager.familyMembers.first?.relationship, .parent)
    }
    
    func testAddFamilyMemberWithInvalidAge() async throws {
        // Given
        let member = createTestFamilyMember(name: "Invalid", age: -5, relationship: .child)
        
        // When & Then
        do {
            try await familyManager.addFamilyMember(member)
            XCTFail("Should throw invalid age error")
        } catch FamilyHealthError.invalidAge {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAddDuplicateFamilyMember() async throws {
        // Given
        let member = createTestFamilyMember(name: "John Doe", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        
        // When & Then
        do {
            try await familyManager.addFamilyMember(member)
            XCTFail("Should throw duplicate member error")
        } catch FamilyHealthError.duplicateMember {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRemoveFamilyMember() async throws {
        // Given
        let member = createTestFamilyMember(name: "John Doe", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        XCTAssertEqual(familyManager.familyMembers.count, 1)
        
        // When
        try await familyManager.removeFamilyMember(member.id)
        
        // Then
        XCTAssertEqual(familyManager.familyMembers.count, 0)
    }
    
    func testRemoveNonExistentFamilyMember() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await familyManager.removeFamilyMember(nonExistentId)
            XCTFail("Should throw member not found error")
        } catch FamilyHealthError.memberNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateFamilyMember() async throws {
        // Given
        let member = createTestFamilyMember(name: "John Doe", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        
        var updatedMember = member
        updatedMember.name = "John Smith"
        updatedMember.age = 36
        
        // When
        try await familyManager.updateFamilyMember(updatedMember)
        
        // Then
        XCTAssertEqual(familyManager.familyMembers.first?.name, "John Smith")
        XCTAssertEqual(familyManager.familyMembers.first?.age, 36)
    }
    
    func testUpdateNonExistentFamilyMember() async throws {
        // Given
        let nonExistentMember = createTestFamilyMember(name: "Non Existent", age: 25, relationship: .sibling)
        
        // When & Then
        do {
            try await familyManager.updateFamilyMember(nonExistentMember)
            XCTFail("Should throw member not found error")
        } catch FamilyHealthError.memberNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Health Sharing Permissions Tests
    
    func testAgeAppropriatePermissionsForChild() async throws {
        // Given
        let child = createTestFamilyMember(name: "Child", age: 8, relationship: .child)
        
        // When
        try await familyManager.addFamilyMember(child)
        let permissions = familyManager.familyMembers.first?.sharingPermissions
        
        // Then
        XCTAssertNotNil(permissions)
        XCTAssertTrue(permissions?.canShareHeartRate == true)
        XCTAssertTrue(permissions?.canShareSteps == true)
        XCTAssertTrue(permissions?.canShareSleep == true)
        XCTAssertTrue(permissions?.canShareLocation == true)
        XCTAssertTrue(permissions?.canShareEmergencyContacts == true)
        XCTAssertFalse(permissions?.canShareMedications == true)
        XCTAssertFalse(permissions?.canShareMentalHealth == true)
        XCTAssertFalse(permissions?.canShareReproductiveHealth == true)
    }
    
    func testAgeAppropriatePermissionsForTeenager() async throws {
        // Given
        let teenager = createTestFamilyMember(name: "Teen", age: 15, relationship: .child, consentGiven: true)
        
        // When
        try await familyManager.addFamilyMember(teenager)
        let permissions = familyManager.familyMembers.first?.sharingPermissions
        
        // Then
        XCTAssertNotNil(permissions)
        XCTAssertTrue(permissions?.canShareHeartRate == true)
        XCTAssertTrue(permissions?.canShareSteps == true)
        XCTAssertTrue(permissions?.canShareSleep == true)
        XCTAssertTrue(permissions?.canShareLocation == true)
        XCTAssertTrue(permissions?.canShareEmergencyContacts == true)
        XCTAssertTrue(permissions?.canShareMedications == true)
        XCTAssertTrue(permissions?.canShareMentalHealth == true) // With consent
        XCTAssertFalse(permissions?.canShareReproductiveHealth == true)
    }
    
    func testAgeAppropriatePermissionsForAdult() async throws {
        // Given
        let adult = createTestFamilyMember(name: "Adult", age: 30, relationship: .parent)
        
        // When
        try await familyManager.addFamilyMember(adult)
        let permissions = familyManager.familyMembers.first?.sharingPermissions
        
        // Then
        XCTAssertNotNil(permissions)
        XCTAssertTrue(permissions?.canShareHeartRate == true)
        XCTAssertTrue(permissions?.canShareSteps == true)
        XCTAssertTrue(permissions?.canShareSleep == true)
        XCTAssertTrue(permissions?.canShareLocation == true)
        XCTAssertTrue(permissions?.canShareEmergencyContacts == true)
        XCTAssertTrue(permissions?.canShareMedications == true)
        XCTAssertTrue(permissions?.canShareMentalHealth == true)
        XCTAssertTrue(permissions?.canShareReproductiveHealth == true)
    }
    
    func testAgeAppropriatePermissionsForSenior() async throws {
        // Given
        let senior = createTestFamilyMember(name: "Senior", age: 75, relationship: .grandparent)
        
        // When
        try await familyManager.addFamilyMember(senior)
        let permissions = familyManager.familyMembers.first?.sharingPermissions
        
        // Then
        XCTAssertNotNil(permissions)
        XCTAssertTrue(permissions?.canShareHeartRate == true)
        XCTAssertTrue(permissions?.canShareSteps == true)
        XCTAssertTrue(permissions?.canShareSleep == true)
        XCTAssertTrue(permissions?.canShareLocation == true)
        XCTAssertTrue(permissions?.canShareEmergencyContacts == true)
        XCTAssertTrue(permissions?.canShareMedications == true)
        XCTAssertTrue(permissions?.canShareMentalHealth == true)
        XCTAssertFalse(permissions?.canShareReproductiveHealth == true)
    }
    
    func testUpdateSharingPermissions() async throws {
        // Given
        let member = createTestFamilyMember(name: "John", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        
        var newPermissions = FamilySharingPermissions()
        newPermissions.canShareHeartRate = false
        newPermissions.canShareSteps = true
        
        // When
        try await familyManager.updateSharingPermissions(for: member.id, permissions: newPermissions)
        
        // Then
        let updatedMember = familyManager.familyMembers.first
        XCTAssertEqual(updatedMember?.sharingPermissions.canShareHeartRate, false)
        XCTAssertEqual(updatedMember?.sharingPermissions.canShareSteps, true)
    }
    
    func testUpdateSharingPermissionsForNonExistentMember() async throws {
        // Given
        let nonExistentId = UUID()
        let permissions = FamilySharingPermissions()
        
        // When & Then
        do {
            try await familyManager.updateSharingPermissions(for: nonExistentId, permissions: permissions)
            XCTFail("Should throw member not found error")
        } catch FamilyHealthError.memberNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Family Health Dashboard Tests
    
    func testUpdateFamilyHealthDashboard() async {
        // Given
        let member1 = createTestFamilyMember(name: "John", age: 35, relationship: .parent)
        let member2 = createTestFamilyMember(name: "Jane", age: 32, relationship: .parent)
        
        try? await familyManager.addFamilyMember(member1)
        try? await familyManager.addFamilyMember(member2)
        
        // When
        await familyManager.updateFamilyHealthDashboard()
        
        // Then
        XCTAssertEqual(familyManager.familyHealthDashboard.totalMembers, 2)
        XCTAssertEqual(familyManager.familyHealthDashboard.activeMembers, 2)
    }
    
    func testFamilyHealthDashboardWithInactiveMembers() async {
        // Given
        let activeMember = createTestFamilyMember(name: "Active", age: 35, relationship: .parent)
        var inactiveMember = createTestFamilyMember(name: "Inactive", age: 30, relationship: .parent)
        inactiveMember.isActive = false
        
        try? await familyManager.addFamilyMember(activeMember)
        try? await familyManager.addFamilyMember(inactiveMember)
        
        // When
        await familyManager.updateFamilyHealthDashboard()
        
        // Then
        XCTAssertEqual(familyManager.familyHealthDashboard.totalMembers, 2)
        XCTAssertEqual(familyManager.familyHealthDashboard.activeMembers, 1)
    }
    
    // MARK: - Health Alerts Tests
    
    func testAcknowledgeHealthAlert() async {
        // Given
        let alert = createTestHealthAlert()
        familyManager.healthAlerts = [alert]
        XCTAssertFalse(alert.isAcknowledged)
        
        // When
        await familyManager.acknowledgeAlert(alert.id)
        
        // Then
        let updatedAlert = familyManager.healthAlerts.first
        XCTAssertTrue(updatedAlert?.isAcknowledged == true)
        XCTAssertNotNil(updatedAlert?.acknowledgedAt)
    }
    
    func testAcknowledgeNonExistentAlert() async {
        // Given
        let nonExistentId = UUID()
        let initialCount = familyManager.healthAlerts.count
        
        // When
        await familyManager.acknowledgeAlert(nonExistentId)
        
        // Then
        XCTAssertEqual(familyManager.healthAlerts.count, initialCount)
    }
    
    // MARK: - Family Health Goals Tests
    
    func testCreateFamilyGoal() async throws {
        // Given
        let goal = createTestFamilyGoal()
        
        // When
        try await familyManager.createFamilyGoal(goal)
        
        // Then
        XCTAssertEqual(familyManager.sharedGoals.count, 1)
        XCTAssertEqual(familyManager.sharedGoals.first?.title, "Family Steps Goal")
        XCTAssertEqual(familyManager.sharedGoals.first?.goalType, .steps)
    }
    
    func testCreateFamilyGoalWithInvalidDate() async throws {
        // Given
        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        var goal = createTestFamilyGoal()
        goal.targetDate = pastDate
        
        // When & Then
        do {
            try await familyManager.createFamilyGoal(goal)
            XCTFail("Should throw invalid goal date error")
        } catch FamilyHealthError.invalidGoalDate {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUpdateGoalProgress() async throws {
        // Given
        let goal = createTestFamilyGoal()
        try await familyManager.createFamilyGoal(goal)
        
        // When
        await familyManager.updateGoalProgress(goal.id, progress: 0.5)
        
        // Then
        let updatedGoal = familyManager.sharedGoals.first
        XCTAssertEqual(updatedGoal?.currentProgress, 0.5)
        XCTAssertFalse(updatedGoal?.isCompleted == true)
    }
    
    func testCompleteGoal() async throws {
        // Given
        let goal = createTestFamilyGoal()
        try await familyManager.createFamilyGoal(goal)
        
        // When
        await familyManager.updateGoalProgress(goal.id, progress: 1.0)
        
        // Then
        let completedGoal = familyManager.sharedGoals.first
        XCTAssertTrue(completedGoal?.isCompleted == true)
        XCTAssertNotNil(completedGoal?.completedAt)
    }
    
    func testUpdateNonExistentGoalProgress() async {
        // Given
        let nonExistentId = UUID()
        let initialCount = familyManager.sharedGoals.count
        
        // When
        await familyManager.updateGoalProgress(nonExistentId, progress: 0.5)
        
        // Then
        XCTAssertEqual(familyManager.sharedGoals.count, initialCount)
    }
    
    // MARK: - Caregiver Tools Tests
    
    func testUpdateCaregiverTools() async {
        // When
        await familyManager.updateCaregiverTools()
        
        // Then
        // Verify caregiver tools are updated (implementation dependent on actual data)
        XCTAssertNotNil(familyManager.caregiverTools)
    }
    
    func testAddMedicationReminder() async throws {
        // Given
        let member = createTestFamilyMember(name: "John", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        
        let reminder = createTestMedicationReminder(for: member.id)
        
        // When
        try await familyManager.addMedicationReminder(for: member.id, medication: reminder)
        
        // Then
        XCTAssertTrue(familyManager.caregiverTools.medicationReminders.contains { $0.id == reminder.id })
    }
    
    func testAddMedicationReminderForNonExistentMember() async throws {
        // Given
        let nonExistentId = UUID()
        let reminder = createTestMedicationReminder(for: nonExistentId)
        
        // When & Then
        do {
            try await familyManager.addMedicationReminder(for: nonExistentId, medication: reminder)
            XCTFail("Should throw member not found error")
        } catch FamilyHealthError.memberNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAddAppointment() async throws {
        // Given
        let member = createTestFamilyMember(name: "John", age: 35, relationship: .parent)
        try await familyManager.addFamilyMember(member)
        
        let appointment = createTestAppointment(for: member.id)
        
        // When
        try await familyManager.addAppointment(for: member.id, appointment: appointment)
        
        // Then
        XCTAssertTrue(familyManager.caregiverTools.appointments.contains { $0.id == appointment.id })
    }
    
    func testAddAppointmentForNonExistentMember() async throws {
        // Given
        let nonExistentId = UUID()
        let appointment = createTestAppointment(for: nonExistentId)
        
        // When & Then
        do {
            try await familyManager.addAppointment(for: nonExistentId, appointment: appointment)
            XCTFail("Should throw member not found error")
        } catch FamilyHealthError.memberNotFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Health Reports Tests
    
    func testGenerateFamilyHealthReport() async {
        // Given
        let member = createTestFamilyMember(name: "John", age: 35, relationship: .parent)
        try? await familyManager.addFamilyMember(member)
        
        // When
        let report = await familyManager.generateFamilyHealthReport(timeRange: .week)
        
        // Then
        XCTAssertNotNil(report)
        XCTAssertEqual(report.timeRange, .week)
        XCTAssertEqual(report.familyMembers.count, 1)
        XCTAssertNotNil(report.generatedAt)
    }
    
    func testExportFamilyHealthReportAsJSON() async throws {
        // Given
        let report = await familyManager.generateFamilyHealthReport(timeRange: .week)
        
        // When
        let data = try await familyManager.exportFamilyHealthReport(report, format: .json)
        
        // Then
        XCTAssertFalse(data.isEmpty)
    }
    
    func testExportFamilyHealthReportAsPDF() async throws {
        // Given
        let report = await familyManager.generateFamilyHealthReport(timeRange: .week)
        
        // When
        let data = try await familyManager.exportFamilyHealthReport(report, format: .pdf)
        
        // Then
        XCTAssertFalse(data.isEmpty)
    }
    
    func testExportFamilyHealthReportAsCSV() async throws {
        // Given
        let report = await familyManager.generateFamilyHealthReport(timeRange: .week)
        
        // When
        let data = try await familyManager.exportFamilyHealthReport(report, format: .csv)
        
        // Then
        XCTAssertFalse(data.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteFamilyHealthWorkflow() async throws {
        // Given
        let parent = createTestFamilyMember(name: "Parent", age: 35, relationship: .parent)
        let child = createTestFamilyMember(name: "Child", age: 8, relationship: .child)
        
        // When - Add family members
        try await familyManager.addFamilyMember(parent)
        try await familyManager.addFamilyMember(child)
        
        // Then - Verify members added
        XCTAssertEqual(familyManager.familyMembers.count, 2)
        
        // When - Update dashboard
        await familyManager.updateFamilyHealthDashboard()
        
        // Then - Verify dashboard updated
        XCTAssertEqual(familyManager.familyHealthDashboard.totalMembers, 2)
        
        // When - Create family goal
        let goal = createTestFamilyGoal()
        try await familyManager.createFamilyGoal(goal)
        
        // Then - Verify goal created
        XCTAssertEqual(familyManager.sharedGoals.count, 1)
        
        // When - Update goal progress
        await familyManager.updateGoalProgress(goal.id, progress: 0.75)
        
        // Then - Verify progress updated
        let updatedGoal = familyManager.sharedGoals.first
        XCTAssertEqual(updatedGoal?.currentProgress, 0.75)
        
        // When - Add medication reminder
        let reminder = createTestMedicationReminder(for: parent.id)
        try await familyManager.addMedicationReminder(for: parent.id, medication: reminder)
        
        // Then - Verify reminder added
        XCTAssertTrue(familyManager.caregiverTools.medicationReminders.contains { $0.id == reminder.id })
        
        // When - Generate health report
        let report = await familyManager.generateFamilyHealthReport(timeRange: .month)
        
        // Then - Verify report generated
        XCTAssertNotNil(report)
        XCTAssertEqual(report.familyMembers.count, 2)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeFamily() async throws {
        // Given
        let familySize = 10
        
        // When
        let startTime = Date()
        
        for i in 1...familySize {
            let member = createTestFamilyMember(name: "Member \(i)", age: 20 + i, relationship: .sibling)
            try await familyManager.addFamilyMember(member)
        }
        
        await familyManager.updateFamilyHealthDashboard()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(familyManager.familyMembers.count, familySize)
        XCTAssertLessThan(duration, 5.0, "Family management should complete within 5 seconds")
    }
    
    func testConcurrentFamilyOperations() async throws {
        // Given
        let operationCount = 10
        
        // When
        await withThrowingTaskGroup(of: Void.self) { group in
            for i in 1...operationCount {
                group.addTask {
                    let member = self.createTestFamilyMember(name: "Concurrent \(i)", age: 20 + i, relationship: .sibling)
                    try await self.familyManager.addFamilyMember(member)
                }
            }
        }
        
        // Then
        XCTAssertEqual(familyManager.familyMembers.count, operationCount)
    }
    
    // MARK: - Helper Methods
    
    private func createTestFamilyMember(name: String, age: Int, relationship: FamilyRelationship, consentGiven: Bool = false) -> FamilyMember {
        return FamilyMember(
            id: UUID(),
            name: name,
            age: age,
            relationship: relationship,
            isActive: true,
            consentGiven: consentGiven,
            sharingPermissions: FamilySharingPermissions(),
            emergencyContacts: [],
            healthProfile: HealthProfile(),
            createdAt: Date(),
            lastUpdated: Date()
        )
    }
    
    private func createTestHealthAlert() -> FamilyHealthAlert {
        return FamilyHealthAlert(
            id: UUID(),
            memberId: UUID(),
            memberName: "Test Member",
            alertType: .warning,
            severity: .medium,
            message: "Test alert message",
            timestamp: Date(),
            isAcknowledged: false
        )
    }
    
    private func createTestFamilyGoal() -> FamilyHealthGoal {
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return FamilyHealthGoal(
            id: UUID(),
            title: "Family Steps Goal",
            description: "Walk 10,000 steps together",
            targetDate: futureDate,
            goalType: .steps,
            targetValue: 10000,
            createdBy: UUID()
        )
    }
    
    private func createTestMedicationReminder(for memberId: UUID) -> MedicationReminder {
        return MedicationReminder(
            id: UUID(),
            medicationId: UUID(),
            memberId: memberId,
            time: Date(),
            frequency: "Daily"
        )
    }
    
    private func createTestAppointment(for memberId: UUID) -> FamilyAppointment {
        let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return FamilyAppointment(
            id: UUID(),
            title: "Doctor Checkup",
            description: "Annual physical examination",
            date: futureDate,
            location: "Medical Center",
            memberId: memberId,
            type: .doctor
        )
    }
} 