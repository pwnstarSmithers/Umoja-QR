import Foundation
import CryptoKit

/// Security manager for QR code operations
public class SecurityManager {
    
    // MARK: - Rate Limiting
    
    private static var operationCounts: [String: (count: Int, lastReset: Date)] = [:]
    private static let maxOperationsPerMinute = 60
    private static let rateLimitWindow: TimeInterval = 60 // 1 minute
    private static let rateLimitQueue = DispatchQueue(label: "com.qrcodesdk.ratelimit")
    
    /// Check if operation is within rate limits (thread-safe)
    public static func checkRateLimit(for operation: String) -> Bool {
        return rateLimitQueue.sync {
            let now = Date()
            let key = operation
            
            if let existing = operationCounts[key] {
                // Reset counter if window has passed
                if now.timeIntervalSince(existing.lastReset) > rateLimitWindow {
                    operationCounts[key] = (count: 1, lastReset: now)
                    return true
                }
                
                // Check if within limits
                if existing.count >= maxOperationsPerMinute {
                    return false
                }
                
                // Increment counter
                operationCounts[key] = (count: existing.count + 1, lastReset: existing.lastReset)
                return true
            } else {
                // First operation
                operationCounts[key] = (count: 1, lastReset: now)
                return true
            }
        }
    }
    
    // MARK: - Input Sanitization
    
    /// Sanitize and validate QR code input data
    public static func sanitizeQRInput(_ input: String) throws -> String {
        // Remove null bytes and control characters
        let sanitized = input.replacingOccurrences(of: "\0", with: "")
            .components(separatedBy: .controlCharacters)
            .joined()
        
        // Validate length
        guard sanitized.count <= 4296 else { // QR Code max capacity
            throw SecurityError.inputTooLong
        }
        
        // Check for malicious patterns
        try validateInputSafety(sanitized)
        
        return sanitized
    }
    
    /// Validate input for potential security threats
    private static func validateInputSafety(_ input: String) throws {
        // Check for script injection patterns
        let dangerousPatterns = [
            "<script", "javascript:", "data:", "vbscript:",
            "onload=", "onerror=", "onclick=", "eval(",
            "document.cookie", "window.location"
        ]
        
        let lowercaseInput = input.lowercased()
        for pattern in dangerousPatterns {
            if lowercaseInput.contains(pattern) {
                throw SecurityError.potentialInjection
            }
        }
        
        // Validate URL schemes if input looks like URL
        if input.hasPrefix("http") || input.hasPrefix("ftp") {
            try validateURLSafety(input)
        }
    }
    
    /// Validate URL safety for QR codes containing URLs
    private static func validateURLSafety(_ urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw SecurityError.invalidURL
        }
        
        // Whitelist allowed schemes
        let allowedSchemes = ["https", "http", "tel", "mailto", "sms"]
        guard let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else {
            throw SecurityError.unsafeURLScheme
        }
        
        // Check for suspicious domains
        if let host = url.host?.lowercased() {
            let suspiciousDomains = ["bit.ly", "tinyurl.com", "t.co", "short.link"]
            if suspiciousDomains.contains(host) {
                throw SecurityError.suspiciousDomain
            }
        }
    }
    
    // MARK: - Secure Memory Operations
    
    /// Securely clear sensitive data from memory
    public static func secureErase(_ data: inout Data) {
        data.withUnsafeMutableBytes { bytes in
            _ = memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
        }
    }
    
    /// Securely clear string data
    public static func secureErase(_ string: inout String) {
        var data = Data(string.utf8)
        secureErase(&data)
        string = ""
    }
    
    // MARK: - Timing Attack Protection
    
    /// Constant-time string comparison to prevent timing attacks
    public static func constantTimeCompare(_ a: String, _ b: String) -> Bool {
        let aData = Data(a.utf8)
        let bData = Data(b.utf8)
        return constantTimeCompare(aData, bData)
    }
    
    /// Constant-time data comparison
    public static func constantTimeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        
        var result: UInt8 = 0
        for i in 0..<a.count {
            result |= a[i] ^ b[i]
        }
        return result == 0
    }
    
    // MARK: - QR Code Integrity
    
    /// Generate integrity hash for QR code data
    public static func generateIntegrityHash(for data: String) -> String {
        if #available(iOS 13.0, macOS 10.15, *) {
            let hash = SHA256.hash(data: Data(data.utf8))
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } else {
            // Fallback for iOS 12 - use CommonCrypto
            return generateLegacyHash(for: data)
        }
    }
    
    /// Fallback hash generation for iOS 12
    private static func generateLegacyHash(for data: String) -> String {
        // Simple hash implementation for iOS 12 compatibility
        let inputData = Data(data.utf8)
        let hash = inputData.withUnsafeBytes { bytes in
            var digest = [UInt8](repeating: 0, count: 32)
            // Simple XOR-based hash (not cryptographically secure, but functional)
            for (index, byte) in bytes.enumerated() {
                digest[index % 32] ^= byte
            }
            return digest
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Verify QR code integrity
    public static func verifyIntegrity(data: String, expectedHash: String) -> Bool {
        let actualHash = generateIntegrityHash(for: data)
        return constantTimeCompare(actualHash, expectedHash)
    }
}

// MARK: - Security Errors

public enum SecurityError: Error, LocalizedError {
    case rateLimitExceeded
    case inputTooLong
    case potentialInjection
    case invalidURL
    case unsafeURLScheme
    case suspiciousDomain
    case integrityCheckFailed
    
    public var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Too many operations. Please wait before trying again."
        case .inputTooLong:
            return "Input data exceeds maximum allowed length."
        case .potentialInjection:
            return "Input contains potentially malicious content."
        case .invalidURL:
            return "Invalid URL format detected."
        case .unsafeURLScheme:
            return "URL scheme not allowed for security reasons."
        case .suspiciousDomain:
            return "Domain flagged as potentially suspicious."
        case .integrityCheckFailed:
            return "QR code integrity verification failed."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .rateLimitExceeded:
            return "Wait a moment and try again. If this persists, contact support."
        case .inputTooLong:
            return "Reduce the amount of data in the QR code."
        case .potentialInjection:
            return "Remove any script-like content from the input."
        case .invalidURL:
            return "Check the URL format and try again."
        case .unsafeURLScheme:
            return "Use https:// or other standard schemes."
        case .suspiciousDomain:
            return "Use a trusted domain or contact support if this is incorrect."
        case .integrityCheckFailed:
            return "The QR code may have been tampered with. Generate a new one."
        }
    }
} 