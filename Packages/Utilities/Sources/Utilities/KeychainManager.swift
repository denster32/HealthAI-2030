import Foundation
import Security

/// A utility class for securely storing and retrieving sensitive information in the Keychain.
public class KeychainManager {
    /// Shared instance of the KeychainManager.
    public static let shared = KeychainManager()
    
    private let service: String
    
    private init(service: String = Bundle.main.bundleIdentifier ?? "com.healthai2030") {
        self.service = service
    }
    
    /// Saves a value to the Keychain.
    /// - Parameters:
    ///   - value: The string value to save.
    ///   - key: The key to associate with the value.
    /// - Returns: A boolean indicating whether the operation was successful.
    @discardableResult
    public func save(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieves a value from the Keychain.
    /// - Parameter key: The key associated with the value.
    /// - Returns: The stored string value, or nil if not found.
    public func getValue(for key: String) -> String? {
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Updates a value in the Keychain.
    /// - Parameters:
    ///   - value: The new string value.
    ///   - key: The key associated with the value.
    /// - Returns: A boolean indicating whether the operation was successful.
    @discardableResult
    public func update(value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Create update dictionary
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        // Update the item
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // If item doesn't exist, create it
        if status == errSecItemNotFound {
            return save(value: value, for: key)
        }
        
        return status == errSecSuccess
    }
    
    /// Deletes a value from the Keychain.
    /// - Parameter key: The key associated with the value.
    /// - Returns: A boolean indicating whether the operation was successful.
    @discardableResult
    public func delete(for key: String) -> Bool {
        // Create query dictionary
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // Delete the item
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}