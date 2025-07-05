import Foundation
import CryptoKit

/// Simple E2EE utility for encrypting/decrypting user health data.
public struct E2EE {
    public static func encrypt(_ data: Data, withKey key: SymmetricKey) -> Data? {
        try? ChaChaPoly.seal(data, using: key).combined
    }
    public static func decrypt(_ data: Data, withKey key: SymmetricKey) -> Data? {
        guard let box = try? ChaChaPoly.SealedBox(combined: data) else { return nil }
        return try? ChaChaPoly.open(box, using: key)
    }
    public static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
}
