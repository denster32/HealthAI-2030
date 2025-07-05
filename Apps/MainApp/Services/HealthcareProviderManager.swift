import Foundation
import Combine

// MARK: - Models

struct HealthcareProvider: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var accessPermissions: [HealthDataType: SharingPermission] // Granular permissions for provider
    var isActive: Bool
}

// MARK: - HealthcareProviderManager

class HealthcareProviderManager: ObservableObject {
    @Published var providers: [HealthcareProvider] = []
    @Published var pendingProviderInvitations: [String: UUID] = [:] // [Email: ProviderID]

    init() {
        loadProviders()
    }

    // MARK: - Provider Management

    func addProvider(name: String, email: String) {
        let newProvider = HealthcareProvider(id: UUID(), name: name, email: email, accessPermissions: [:], isActive: false)
        providers.append(newProvider)
        saveProviders()
        // In a real app, this would trigger an invitation email
        print("Added healthcare provider: \(name) with email \(email)")
    }

    func updateProvider(_ provider: HealthcareProvider) {
        if let index = providers.firstIndex(where: { $0.id == provider.id }) {
            providers[index] = provider
            saveProviders()
            print("Updated healthcare provider: \(provider.name)")
        }
    }

    func removeProvider(id: UUID) {
        providers.removeAll(where: { $0.id == id })
        saveProviders()
        print("Removed healthcare provider with ID: \(id)")
    }

    // MARK: - Access Management

    func updateProviderAccessPermission(for providerID: UUID, dataType: HealthDataType, permission: SharingPermission) {
        if let index = providers.firstIndex(where: { $0.id == providerID }) {
            providers[index].accessPermissions[dataType] = permission
            saveProviders()
            print("Updated access permission for \(dataType.rawValue) to \(permission.rawValue) for provider \(providerID)")
        }
    }

    func getProviderAccessPermission(for providerID: UUID, dataType: HealthDataType) -> SharingPermission {
        return providers.first(where: { $0.id == providerID })?.accessPermissions[dataType] ?? .denied
    }

    func activateProviderAccess(providerID: UUID) {
        if let index = providers.firstIndex(where: { $0.id == providerID }) {
            providers[index].isActive = true
            saveProviders()
            print("Activated access for provider ID: \(providerID)")
        }
    }

    func deactivateProviderAccess(providerID: UUID) {
        if let index = providers.firstIndex(where: { $0.id == providerID }) {
            providers[index].isActive = false
            saveProviders()
            print("Deactivated access for provider ID: \(providerID)")
        }
    }

    // MARK: - Persistence (Simplified for demonstration)

    private func saveProviders() {
        if let encoded = try? JSONEncoder().encode(providers) {
            UserDefaults.standard.set(encoded, forKey: "healthcareProviders")
        }
    }

    private func loadProviders() {
        if let savedProviders = UserDefaults.standard.data(forKey: "healthcareProviders") {
            if let decodedProviders = try? JSONDecoder().decode([HealthcareProvider].self, from: savedProviders) {
                providers = decodedProviders
            }
        }
    }
}