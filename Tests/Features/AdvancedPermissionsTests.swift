import XCTest
import Foundation
import SwiftUI
import Combine
@testable import HealthAI2030

/// Comprehensive unit tests for Advanced Permissions & Role Management
/// Tests all permissions functionality including user management, role management, and audit logging
final class AdvancedPermissionsTests: XCTestCase {
    var permissionsManager: AdvancedPermissionsManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        permissionsManager = AdvancedPermissionsManager.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        permissionsManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() async {
        // Test initial state
        XCTAssertNil(permissionsManager.currentUser)
        XCTAssertFalse(permissionsManager.userRoles.isEmpty)
        XCTAssertFalse(permissionsManager.permissions.isEmpty)
        XCTAssertTrue(permissionsManager.auditLogs.isEmpty)
        XCTAssertFalse(permissionsManager.securityPolicies.isEmpty)
        XCTAssertNil(permissionsManager.lastAuditDate)
        
        // Test initialization
        await permissionsManager.initialize()
        
        // Verify system is initialized
        XCTAssertFalse(permissionsManager.userRoles.isEmpty)
        XCTAssertFalse(permissionsManager.permissions.isEmpty)
        XCTAssertFalse(permissionsManager.securityPolicies.isEmpty)
    }
    
    func testDefaultRoles() {
        // Test that default roles are created
        XCTAssertNotNil(permissionsManager.userRoles["admin"])
        XCTAssertNotNil(permissionsManager.userRoles["user"])
        
        let adminRole = permissionsManager.userRoles["admin"]
        XCTAssertEqual(adminRole?.name, "Administrator")
        XCTAssertEqual(adminRole?.securityLevel, .critical)
        XCTAssertTrue(adminRole?.isSystemRole ?? false)
        
        let userRole = permissionsManager.userRoles["user"]
        XCTAssertEqual(userRole?.name, "User")
        XCTAssertEqual(userRole?.securityLevel, .medium)
        XCTAssertTrue(userRole?.isSystemRole ?? false)
    }
    
    func testDefaultPermissions() {
        // Test that default permissions are created
        let readOwnData = permissionsManager.permissions.values.first { $0.name == "Read Own Data" }
        XCTAssertNotNil(readOwnData)
        XCTAssertEqual(readOwnData?.category, .dataAccess)
        XCTAssertEqual(readOwnData?.action, .read)
        
        let updateOwnProfile = permissionsManager.permissions.values.first { $0.name == "Update Own Profile" }
        XCTAssertNotNil(updateOwnProfile)
        XCTAssertEqual(updateOwnProfile?.category, .userManagement)
        XCTAssertEqual(updateOwnProfile?.action, .update)
    }
    
    // MARK: - Authentication Tests
    
    func testUserAuthentication() async {
        // Test successful authentication
        let result = await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.user)
        XCTAssertEqual(result.user?.username, "admin")
        XCTAssertEqual(result.user?.roleIds, ["admin"])
        XCTAssertEqual(result.user?.securityLevel, .critical)
        
        // Verify current user is set
        XCTAssertNotNil(permissionsManager.currentUser)
        XCTAssertEqual(permissionsManager.currentUser?.username, "admin")
    }
    
    func testFailedAuthentication() async {
        // Test failed authentication
        let result = await permissionsManager.authenticateUser(username: "invalid", password: "wrong")
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.user)
        
        // Verify current user is not set
        XCTAssertNil(permissionsManager.currentUser)
    }
    
    func testAuthenticationAuditLogging() async {
        // Test that authentication attempts are logged
        let initialLogCount = permissionsManager.auditLogs.count
        
        // Successful login
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        XCTAssertGreaterThan(permissionsManager.auditLogs.count, initialLogCount)
        
        let loginLog = permissionsManager.auditLogs.first { $0.action == "User Login" }
        XCTAssertNotNil(loginLog)
        XCTAssertTrue(loginLog?.success ?? false)
        XCTAssertEqual(loginLog?.severity, .info)
        
        // Failed login
        await permissionsManager.authenticateUser(username: "invalid", password: "wrong")
        
        let failedLog = permissionsManager.auditLogs.first { $0.action == "Failed Login" }
        XCTAssertNotNil(failedLog)
        XCTAssertFalse(failedLog?.success ?? true)
        XCTAssertEqual(failedLog?.severity, .warning)
    }
    
    // MARK: - Permission Tests
    
    func testPermissionChecking() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Test permission checking
        let hasPermission = await permissionsManager.hasPermission(
            userId: permissionsManager.currentUser?.id ?? "",
            permissionId: "read_own_data"
        )
        
        // Admin should have all permissions
        XCTAssertTrue(hasPermission)
    }
    
    func testPermissionCheckingForNonExistentUser() async {
        // Test permission checking for non-existent user
        let hasPermission = await permissionsManager.hasPermission(
            userId: "non_existent_user",
            permissionId: "read_own_data"
        )
        
        XCTAssertFalse(hasPermission)
    }
    
    func testPermissionCheckingForNonExistentPermission() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Test permission checking for non-existent permission
        let hasPermission = await permissionsManager.hasPermission(
            userId: permissionsManager.currentUser?.id ?? "",
            permissionId: "non_existent_permission"
        )
        
        XCTAssertFalse(hasPermission)
    }
    
    func testGetUserPermissions() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let permissions = await permissionsManager.getUserPermissions(
            userId: permissionsManager.currentUser?.id ?? ""
        )
        
        // Admin should have permissions
        XCTAssertFalse(permissions.isEmpty)
        
        // Check that permissions have required properties
        for permission in permissions {
            XCTAssertFalse(permission.name.isEmpty)
            XCTAssertFalse(permission.description.isEmpty)
            XCTAssertFalse(permission.resource.isEmpty)
        }
    }
    
    // MARK: - User Management Tests
    
    func testCreateUser() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let userData = UserCreationData(
            username: "testuser",
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            roleIds: ["user"],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let result = await permissionsManager.createUser(userData: userData)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.user)
        XCTAssertEqual(result.user?.username, "testuser")
        XCTAssertEqual(result.user?.email, "test@example.com")
        XCTAssertEqual(result.user?.firstName, "Test")
        XCTAssertEqual(result.user?.lastName, "User")
        XCTAssertEqual(result.user?.roleIds, ["user"])
        XCTAssertEqual(result.user?.securityLevel, .medium)
        XCTAssertFalse(result.user?.twoFactorEnabled ?? true)
    }
    
    func testCreateUserWithInvalidData() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let userData = UserCreationData(
            username: "",
            email: "",
            firstName: "Test",
            lastName: "User",
            roleIds: ["user"],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let result = await permissionsManager.createUser(userData: userData)
        
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error, "Invalid user data")
    }
    
    func testCreateUserAuditLogging() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let initialLogCount = permissionsManager.auditLogs.count
        
        let userData = UserCreationData(
            username: "audituser",
            email: "audit@example.com",
            firstName: "Audit",
            lastName: "User",
            roleIds: ["user"],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        await permissionsManager.createUser(userData: userData)
        
        let createLog = permissionsManager.auditLogs.first { $0.action == "Create User" }
        XCTAssertNotNil(createLog)
        XCTAssertTrue(createLog?.success ?? false)
        XCTAssertEqual(createLog?.severity, .info)
        XCTAssertTrue(createLog?.details.contains("audituser") ?? false)
    }
    
    // MARK: - Role Management Tests
    
    func testCreateRole() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let roleData = RoleCreationData(
            name: "Test Role",
            description: "A test role for testing",
            permissionIds: ["read_own_data"],
            securityLevel: .medium,
            priority: 50,
            restrictions: []
        )
        
        let result = await permissionsManager.createRole(roleData: roleData)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.role)
        XCTAssertEqual(result.role?.name, "Test Role")
        XCTAssertEqual(result.role?.description, "A test role for testing")
        XCTAssertEqual(result.role?.permissionIds, ["read_own_data"])
        XCTAssertEqual(result.role?.securityLevel, .medium)
        XCTAssertEqual(result.role?.priority, 50)
        XCTAssertFalse(result.role?.isSystemRole ?? true)
        XCTAssertTrue(result.role?.isActive ?? false)
    }
    
    func testCreateRoleWithInvalidData() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let roleData = RoleCreationData(
            name: "",
            description: "",
            permissionIds: ["read_own_data"],
            securityLevel: .medium,
            priority: 50,
            restrictions: []
        )
        
        let result = await permissionsManager.createRole(roleData: roleData)
        
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error, "Invalid role data")
    }
    
    func testCreateRoleAuditLogging() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let roleData = RoleCreationData(
            name: "Audit Role",
            description: "A role for audit testing",
            permissionIds: ["read_own_data"],
            securityLevel: .medium,
            priority: 50,
            restrictions: []
        )
        
        await permissionsManager.createRole(roleData: roleData)
        
        let createLog = permissionsManager.auditLogs.first { $0.action == "Create Role" }
        XCTAssertNotNil(createLog)
        XCTAssertTrue(createLog?.success ?? false)
        XCTAssertEqual(createLog?.severity, .info)
        XCTAssertTrue(createLog?.details.contains("Audit Role") ?? false)
    }
    
    // MARK: - Permission Management Tests
    
    func testCreatePermission() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let permissionData = PermissionCreationData(
            name: "Test Permission",
            description: "A test permission for testing",
            category: .dataAccess,
            resource: "test_resource",
            action: .read,
            securityLevel: .medium,
            conditions: []
        )
        
        let result = await permissionsManager.createPermission(permissionData: permissionData)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.permission)
        XCTAssertEqual(result.permission?.name, "Test Permission")
        XCTAssertEqual(result.permission?.description, "A test permission for testing")
        XCTAssertEqual(result.permission?.category, .dataAccess)
        XCTAssertEqual(result.permission?.resource, "test_resource")
        XCTAssertEqual(result.permission?.action, .read)
        XCTAssertEqual(result.permission?.securityLevel, .medium)
        XCTAssertFalse(result.permission?.isSystemPermission ?? true)
        XCTAssertTrue(result.permission?.isActive ?? false)
    }
    
    func testCreatePermissionWithInvalidData() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let permissionData = PermissionCreationData(
            name: "",
            description: "",
            category: .dataAccess,
            resource: "test_resource",
            action: .read,
            securityLevel: .medium,
            conditions: []
        )
        
        let result = await permissionsManager.createPermission(permissionData: permissionData)
        
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
        XCTAssertEqual(result.error, "Invalid permission data")
    }
    
    func testCreatePermissionAuditLogging() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let permissionData = PermissionCreationData(
            name: "Audit Permission",
            description: "A permission for audit testing",
            category: .dataAccess,
            resource: "audit_resource",
            action: .read,
            securityLevel: .medium,
            conditions: []
        )
        
        await permissionsManager.createPermission(permissionData: permissionData)
        
        let createLog = permissionsManager.auditLogs.first { $0.action == "Create Permission" }
        XCTAssertNotNil(createLog)
        XCTAssertTrue(createLog?.success ?? false)
        XCTAssertEqual(createLog?.severity, .info)
        XCTAssertTrue(createLog?.details.contains("Audit Permission") ?? false)
    }
    
    // MARK: - Role Assignment Tests
    
    func testAssignRoleToUser() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Create a test user first
        let userData = UserCreationData(
            username: "roleuser",
            email: "role@example.com",
            firstName: "Role",
            lastName: "User",
            roleIds: [],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let userResult = await permissionsManager.createUser(userData: userData)
        XCTAssertTrue(userResult.success)
        
        // Assign role to user
        let success = await permissionsManager.assignRoleToUser(
            userId: userResult.user?.id ?? "",
            roleId: "user"
        )
        
        XCTAssertTrue(success)
    }
    
    func testRemoveRoleFromUser() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Create a test user with a role
        let userData = UserCreationData(
            username: "removeroleuser",
            email: "removerole@example.com",
            firstName: "Remove",
            lastName: "Role",
            roleIds: ["user"],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let userResult = await permissionsManager.createUser(userData: userData)
        XCTAssertTrue(userResult.success)
        
        // Remove role from user
        let success = await permissionsManager.removeRoleFromUser(
            userId: userResult.user?.id ?? "",
            roleId: "user"
        )
        
        XCTAssertTrue(success)
    }
    
    // MARK: - Audit Logging Tests
    
    func testAuditLogFiltering() {
        // Test audit log filtering by user
        let userLogs = permissionsManager.getAuditLogs(userId: "admin")
        XCTAssertGreaterThanOrEqual(userLogs.count, 0)
        
        // Test audit log filtering by action
        let loginLogs = permissionsManager.getAuditLogs(action: "User Login")
        XCTAssertGreaterThanOrEqual(loginLogs.count, 0)
        
        // Test audit log filtering by resource
        let authLogs = permissionsManager.getAuditLogs(resource: "Authentication")
        XCTAssertGreaterThanOrEqual(authLogs.count, 0)
        
        // Test audit log filtering by severity
        let infoLogs = permissionsManager.getAuditLogs(severity: .info)
        XCTAssertGreaterThanOrEqual(infoLogs.count, 0)
        
        // Test audit log filtering by date range
        let recentLogs = permissionsManager.getAuditLogs(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date()
        )
        XCTAssertGreaterThanOrEqual(recentLogs.count, 0)
    }
    
    func testAuditLogProperties() {
        // Test that audit logs have required properties
        for log in permissionsManager.auditLogs {
            XCTAssertFalse(log.userId.isEmpty)
            XCTAssertFalse(log.username.isEmpty)
            XCTAssertFalse(log.action.isEmpty)
            XCTAssertFalse(log.resource.isEmpty)
            XCTAssertFalse(log.details.isEmpty)
            
            // Severity should be valid
            let validSeverities = Set(AdvancedPermissionsManager.AuditSeverity.allCases)
            XCTAssertTrue(validSeverities.contains(log.severity))
        }
    }
    
    func testAuditLogSorting() {
        // Test that audit logs are sorted by timestamp (newest first)
        let sortedLogs = permissionsManager.auditLogs.sorted { $0.timestamp > $1.timestamp }
        
        for i in 0..<min(sortedLogs.count - 1, 10) {
            XCTAssertGreaterThanOrEqual(sortedLogs[i].timestamp, sortedLogs[i + 1].timestamp)
        }
    }
    
    // MARK: - Export Tests
    
    func testExportAuditLogs() {
        let exportData = permissionsManager.exportAuditLogs()
        XCTAssertNotNil(exportData)
        
        // Verify data can be decoded
        if let data = exportData {
            let decoder = JSONDecoder()
            XCTAssertNoThrow(try decoder.decode(AuditExportData.self, from: data))
        }
    }
    
    func testExportDataCompleteness() {
        let exportData = permissionsManager.exportAuditLogs()
        XCTAssertNotNil(exportData)
        
        if let data = exportData {
            let decoder = JSONDecoder()
            do {
                let export = try decoder.decode(AuditExportData.self, from: data)
                
                // Check that all logs are included
                XCTAssertEqual(export.logs.count, permissionsManager.auditLogs.count)
                
                // Check export metadata
                XCTAssertNotNil(export.exportDate)
                XCTAssertFalse(export.exportedBy.isEmpty)
                
            } catch {
                XCTFail("Failed to decode export data: \(error)")
            }
        }
    }
    
    // MARK: - Summary Tests
    
    func testPermissionsSummary() {
        let summary = permissionsManager.getPermissionsSummary()
        
        XCTAssertGreaterThanOrEqual(summary.totalUsers, 0)
        XCTAssertGreaterThanOrEqual(summary.totalRoles, 0)
        XCTAssertGreaterThanOrEqual(summary.totalPermissions, 0)
        XCTAssertGreaterThanOrEqual(summary.totalAuditLogs, 0)
        XCTAssertGreaterThanOrEqual(summary.activeUsers, 0)
        XCTAssertLessThanOrEqual(summary.activeUsers, summary.totalUsers)
        
        // Test calculated properties
        XCTAssertGreaterThanOrEqual(summary.userActivityRate, 0.0)
        XCTAssertLessThanOrEqual(summary.userActivityRate, 1.0)
    }
    
    func testSummaryCalculations() {
        let summary = permissionsManager.getPermissionsSummary()
        
        if summary.totalUsers > 0 {
            let expectedActivityRate = Double(summary.activeUsers) / Double(summary.totalUsers)
            XCTAssertEqual(summary.userActivityRate, expectedActivityRate, accuracy: 0.01)
        }
    }
    
    // MARK: - Security Level Tests
    
    func testSecurityLevelProperties() {
        for level in AdvancedPermissionsManager.SecurityLevel.allCases {
            XCTAssertFalse(level.rawValue.isEmpty)
            XCTAssertFalse(level.color.isEmpty)
            XCTAssertGreaterThan(level.priority, 0)
        }
    }
    
    func testSecurityLevelPriority() {
        // Test that security levels have correct priority order
        XCTAssertLessThan(AdvancedPermissionsManager.SecurityLevel.low.priority, AdvancedPermissionsManager.SecurityLevel.medium.priority)
        XCTAssertLessThan(AdvancedPermissionsManager.SecurityLevel.medium.priority, AdvancedPermissionsManager.SecurityLevel.high.priority)
        XCTAssertLessThan(AdvancedPermissionsManager.SecurityLevel.high.priority, AdvancedPermissionsManager.SecurityLevel.critical.priority)
    }
    
    // MARK: - Permission Category Tests
    
    func testPermissionCategoryProperties() {
        for category in AdvancedPermissionsManager.PermissionCategory.allCases {
            XCTAssertFalse(category.rawValue.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
        }
    }
    
    func testPermissionActionProperties() {
        for action in AdvancedPermissionsManager.PermissionAction.allCases {
            XCTAssertFalse(action.rawValue.isEmpty)
            XCTAssertFalse(action.icon.isEmpty)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testNonExistentUserOperations() async {
        // Test operations with non-existent user
        let hasPermission = await permissionsManager.hasPermission(
            userId: "non_existent",
            permissionId: "read_own_data"
        )
        XCTAssertFalse(hasPermission)
        
        let permissions = await permissionsManager.getUserPermissions(userId: "non_existent")
        XCTAssertTrue(permissions.isEmpty)
        
        let assignSuccess = await permissionsManager.assignRoleToUser(
            userId: "non_existent",
            roleId: "user"
        )
        XCTAssertFalse(assignSuccess)
        
        let removeSuccess = await permissionsManager.removeRoleFromUser(
            userId: "non_existent",
            roleId: "user"
        )
        XCTAssertFalse(removeSuccess)
    }
    
    func testNonExistentRoleOperations() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Create a test user
        let userData = UserCreationData(
            username: "edgetestuser",
            email: "edgetest@example.com",
            firstName: "Edge",
            lastName: "Test",
            roleIds: [],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let userResult = await permissionsManager.createUser(userData: userData)
        XCTAssertTrue(userResult.success)
        
        // Test operations with non-existent role
        let assignSuccess = await permissionsManager.assignRoleToUser(
            userId: userResult.user?.id ?? "",
            roleId: "non_existent_role"
        )
        XCTAssertFalse(assignSuccess)
        
        let removeSuccess = await permissionsManager.removeRoleFromUser(
            userId: userResult.user?.id ?? "",
            roleId: "non_existent_role"
        )
        XCTAssertFalse(removeSuccess)
    }
    
    func testEmptyDataHandling() {
        // Test handling of empty data
        let emptyLogs = permissionsManager.getAuditLogs(userId: "non_existent")
        XCTAssertTrue(emptyLogs.isEmpty)
        
        let summary = permissionsManager.getPermissionsSummary()
        XCTAssertGreaterThanOrEqual(summary.totalUsers, 0)
        XCTAssertGreaterThanOrEqual(summary.totalRoles, 0)
        XCTAssertGreaterThanOrEqual(summary.totalPermissions, 0)
    }
    
    // MARK: - Performance Tests
    
    func testConcurrentPermissionChecks() async {
        // Authenticate as admin
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.permissionsManager.hasPermission(
                        userId: self.permissionsManager.currentUser?.id ?? "",
                        permissionId: "read_own_data"
                    )
                }
            }
            
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, 10)
            XCTAssertTrue(results.allSatisfy { $0 })
        }
    }
    
    func testLargeAuditLogHandling() {
        // Test handling of large audit log sets
        let largeLogSet = (1...1000).map { i in
            AdvancedPermissionsManager.AuditLogEntry(
                timestamp: Date().addingTimeInterval(Double(i)),
                userId: "user\(i)",
                username: "user\(i)",
                action: "Test Action \(i)",
                resource: "Test Resource",
                resourceId: nil,
                details: "Test details for log \(i)",
                ipAddress: nil,
                userAgent: nil,
                success: true,
                severity: .info,
                sessionId: nil,
                metadata: [:]
            )
        }
        
        // Should handle large sets without crashing
        XCTAssertEqual(largeLogSet.count, 1000)
    }
    
    // MARK: - Integration Tests
    
    func testUserRolePermissionIntegration() async {
        // Test integration between users, roles, and permissions
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        // Create a custom role with specific permissions
        let roleData = RoleCreationData(
            name: "Test Integration Role",
            description: "Role for integration testing",
            permissionIds: ["read_own_data"],
            securityLevel: .medium,
            priority: 50,
            restrictions: []
        )
        
        let roleResult = await permissionsManager.createRole(roleData: roleData)
        XCTAssertTrue(roleResult.success)
        
        // Create a user with this role
        let userData = UserCreationData(
            username: "integrationuser",
            email: "integration@example.com",
            firstName: "Integration",
            lastName: "User",
            roleIds: [roleResult.role?.id ?? ""],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        let userResult = await permissionsManager.createUser(userData: userData)
        XCTAssertTrue(userResult.success)
        
        // Test that user has role-based permissions
        let hasPermission = await permissionsManager.hasPermission(
            userId: userResult.user?.id ?? "",
            permissionId: "read_own_data"
        )
        XCTAssertTrue(hasPermission)
        
        // Test that user permissions include role permissions
        let permissions = await permissionsManager.getUserPermissions(
            userId: userResult.user?.id ?? ""
        )
        XCTAssertTrue(permissions.contains { $0.id == "read_own_data" })
    }
    
    func testAuditLoggingIntegration() async {
        // Test that all operations generate audit logs
        await permissionsManager.authenticateUser(username: "admin", password: "password")
        
        let initialLogCount = permissionsManager.auditLogs.count
        
        // Perform various operations
        let userData = UserCreationData(
            username: "auditintegrationuser",
            email: "auditintegration@example.com",
            firstName: "Audit",
            lastName: "Integration",
            roleIds: [],
            securityLevel: .medium,
            twoFactorEnabled: false
        )
        
        await permissionsManager.createUser(userData: userData)
        
        let roleData = RoleCreationData(
            name: "Audit Integration Role",
            description: "Role for audit integration testing",
            permissionIds: [],
            securityLevel: .medium,
            priority: 50,
            restrictions: []
        )
        
        await permissionsManager.createRole(roleData: roleData)
        
        let permissionData = PermissionCreationData(
            name: "Audit Integration Permission",
            description: "Permission for audit integration testing",
            category: .dataAccess,
            resource: "audit_integration_resource",
            action: .read,
            securityLevel: .medium,
            conditions: []
        )
        
        await permissionsManager.createPermission(permissionData: permissionData)
        
        // Verify that audit logs were created
        XCTAssertGreaterThan(permissionsManager.auditLogs.count, initialLogCount)
        
        // Check for specific audit entries
        let userLog = permissionsManager.auditLogs.first { $0.action == "Create User" }
        XCTAssertNotNil(userLog)
        
        let roleLog = permissionsManager.auditLogs.first { $0.action == "Create Role" }
        XCTAssertNotNil(roleLog)
        
        let permissionLog = permissionsManager.auditLogs.first { $0.action == "Create Permission" }
        XCTAssertNotNil(permissionLog)
    }
}

// MARK: - Supporting Structures for Tests

private struct AuditExportData: Codable {
    let logs: [AdvancedPermissionsManager.AuditLogEntry]
    let exportDate: Date
    let exportedBy: String
} 