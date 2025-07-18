import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif
import SwiftData

/// Utility to validate data integrity via SHA256 checksums
public struct DataIntegrityManager: Sendable {
    public static let shared = DataIntegrityManager()
    
    private init() {}
    
    /// Compute a SHA256 hash for a given Codable object
    public func computeChecksum<T: Codable>(_ object: T) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys // Ensure consistent encoding
            let data = try encoder.encode(object)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            print("Checksum computation failed: \(error)")
            return ""
        }
    }
    
    /// Validate data integrity by comparing computed checksum with stored checksum
    public func validateDataIntegrity<T: Codable & Identifiable>(
        _ object: T, 
        storedChecksum: String
    ) -> Bool {
        let computedChecksum = computeChecksum(object)
        return computedChecksum == storedChecksum
    }
    
    /// Extend SwiftData models to include checksum validation
    public func addChecksumValidation<T: Codable & Identifiable>(
        to modelContext: ModelContext, 
        object: T
    ) throws {
        let checksum = computeChecksum(object)
        
        // In a real implementation, you would extend your model to include a checksum property
        // This is a conceptual demonstration
        print("Computed checksum for object: \(checksum)")
        
        // Simulate storing or validating the checksum
        // In a production scenario, this would interact with your actual data model
    }
}

// Example usage:
// extension YourModel {
//     var dataChecksum: String {
//         DataIntegrityManager.shared.computeChecksum(self)
//     }
//     
//     func validateIntegrity() -> Bool {
//         return DataIntegrityManager.shared.validateDataIntegrity(
//             self, 
//             storedChecksum: self.storedChecksum ?? ""
//         )
//     }
// } 