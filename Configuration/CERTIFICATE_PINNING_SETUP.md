# Certificate Pinning Setup Guide

## Overview
This guide explains how to implement production certificate pinning for HealthAI2030 to replace the placeholder configuration in SecurityConfig.swift.

## Current Status
⚠️ **PRODUCTION BLOCKER**: Certificate pinning contains placeholder values at SecurityConfig.swift:217-220

## Required Actions

### 1. Generate Production Certificate Hashes

```bash
# For your production domain (example: api.healthai2030.com)
openssl s_client -connect api.healthai2030.com:443 -servername api.healthai2030.com | \
openssl x509 -pubkey -noout | \
openssl rsa -pubin -outform der | \
openssl dgst -sha256 -binary | \
openssl enc -base64

# For backup/fallback certificates
openssl s_client -connect backup-api.healthai2030.com:443 -servername backup-api.healthai2030.com | \
openssl x509 -pubkey -noout | \
openssl rsa -pubin -outform der | \
openssl dgst -sha256 -binary | \
openssl enc -base64
```

### 2. Update SecurityConfig.swift

Replace the placeholder array in SecurityConfig.swift lines 217-220:

```swift
// BEFORE (placeholder)
let pinnedCertificates = [
    // Add your pinned certificate hashes here
    // Example: "a1b2c3d4e5f6..."
]

// AFTER (production values)
let pinnedCertificates = [
    "PRIMARY_CERT_HASH_HERE",      // Main production certificate
    "BACKUP_CERT_HASH_HERE",       // Backup certificate
    "INTERMEDIATE_CERT_HASH_HERE"  // Intermediate CA certificate
]
```

### 3. Secure Storage Implementation

Consider moving certificate hashes to secure storage:

```swift
// Option 1: Bundle-embedded plist (recommended for certificate hashes)
private static func loadPinnedCertificates() -> [String] {
    guard let path = Bundle.main.path(forResource: "PinnedCertificates", ofType: "plist"),
          let certificates = NSArray(contentsOfFile: path) as? [String] else {
        return []
    }
    return certificates
}

// Option 2: Keychain storage for highly sensitive data
private static func loadCertificatesFromKeychain() -> [String] {
    // Implementation for keychain storage
}
```

### 4. Certificate Rotation Strategy

```swift
public struct CertificateManager {
    static func validateCertificateRotation() -> Bool {
        // Check certificate expiration dates
        // Implement automatic rotation alerts
        // Validate backup certificates
        return true
    }
}
```

### 5. Testing

```swift
#if DEBUG
func testCertificatePinning() {
    // Test with known good certificates
    // Test failure scenarios
    // Test certificate rotation
}
#endif
```

## Implementation Checklist

- [ ] Generate production certificate hashes
- [ ] Update SecurityConfig.swift with real values
- [ ] Implement secure certificate storage
- [ ] Add certificate rotation monitoring
- [ ] Test certificate pinning in staging
- [ ] Validate with production domains
- [ ] Document certificate update procedures

## Security Notes

1. **Never commit certificate hashes to public repositories**
2. **Implement certificate rotation monitoring**
3. **Maintain backup certificates for continuity**
4. **Test pinning thoroughly before production deployment**
5. **Have emergency certificate update procedures**

## Emergency Procedures

If certificate pinning fails in production:

1. **Immediate**: Deploy app update with corrected certificates
2. **Communication**: Notify users of temporary connectivity issues
3. **Monitoring**: Track failed connection attempts
4. **Rollback**: Have ability to disable pinning remotely if needed

## Contact Information

- Security Team: security@healthai2030.com
- Infrastructure Team: infrastructure@healthai2030.com
- Emergency Contact: emergency@healthai2030.com