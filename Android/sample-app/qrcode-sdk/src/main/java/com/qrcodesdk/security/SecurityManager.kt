package com.qrcodesdk.security

import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Security manager for QR code operations
 */
object SecurityManager {
    
    // MARK: - Rate Limiting
    
    private data class RateLimitInfo(
        val count: AtomicInteger = AtomicInteger(0),
        val lastReset: AtomicLong = AtomicLong(System.currentTimeMillis())
    )
    
    private val operationCounts = ConcurrentHashMap<String, RateLimitInfo>()
    private const val MAX_OPERATIONS_PER_MINUTE = 60
    private const val RATE_LIMIT_WINDOW = 60_000L // 1 minute in milliseconds
    
    /**
     * Check if operation is within rate limits
     */
    fun checkRateLimit(operation: String): Boolean {
        val now = System.currentTimeMillis()
        val info = operationCounts.getOrPut(operation) { RateLimitInfo() }
        
        // Reset counter if window has passed
        if (now - info.lastReset.get() > RATE_LIMIT_WINDOW) {
            info.count.set(1)
            info.lastReset.set(now)
            return true
        }
        
        // Check if within limits
        val currentCount = info.count.get()
        if (currentCount >= MAX_OPERATIONS_PER_MINUTE) {
            return false
        }
        
        // Increment counter
        info.count.incrementAndGet()
        return true
    }
    
    // MARK: - Input Sanitization
    
    /**
     * Sanitize and validate QR code input data
     */
    @Throws(SecurityException::class)
    fun sanitizeQRInput(input: String): String {
        // Remove null bytes and control characters
        val sanitized = input.replace("\u0000", "")
            .replace(Regex("\\p{Cntrl}"), "")
        
        // Validate length
        if (sanitized.length > 4296) { // QR Code max capacity
            throw SecurityException("Input data exceeds maximum allowed length")
        }
        
        // Check for malicious patterns
        validateInputSafety(sanitized)
        
        return sanitized
    }
    
    /**
     * Validate input for potential security threats
     */
    @Throws(SecurityException::class)
    private fun validateInputSafety(input: String) {
        // Check for script injection patterns
        val dangerousPatterns = listOf(
            "<script", "javascript:", "data:", "vbscript:",
            "onload=", "onerror=", "onclick=", "eval(",
            "document.cookie", "window.location"
        )
        
        val lowercaseInput = input.lowercase()
        dangerousPatterns.forEach { pattern ->
            if (lowercaseInput.contains(pattern)) {
                throw SecurityException("Input contains potentially malicious content")
            }
        }
        
        // Validate URL schemes if input looks like URL
        if (input.startsWith("http") || input.startsWith("ftp")) {
            validateURLSafety(input)
        }
    }
    
    /**
     * Validate URL safety for QR codes containing URLs
     */
    @Throws(SecurityException::class)
    private fun validateURLSafety(urlString: String) {
        try {
            val url = URL(urlString)
            
            // Whitelist allowed schemes
            val allowedSchemes = listOf("https", "http", "tel", "mailto", "sms")
            val scheme = url.protocol?.lowercase()
            if (scheme == null || !allowedSchemes.contains(scheme)) {
                throw SecurityException("URL scheme not allowed for security reasons")
            }
            
            // Check for suspicious domains
            url.host?.lowercase()?.let { host ->
                val suspiciousDomains = listOf("bit.ly", "tinyurl.com", "t.co", "short.link")
                if (suspiciousDomains.contains(host)) {
                    throw SecurityException("Domain flagged as potentially suspicious")
                }
            }
        } catch (e: Exception) {
            if (e is SecurityException) throw e
            throw SecurityException("Invalid URL format detected")
        }
    }
    
    // MARK: - Secure Memory Operations
    
    /**
     * Securely clear sensitive data from memory
     */
    fun secureErase(data: ByteArray) {
        data.fill(0)
    }
    
    /**
     * Securely clear string data
     */
    fun secureErase(string: StringBuilder) {
        repeat(string.length) { string.setCharAt(it, '\u0000') }
        string.clear()
    }
    
    // MARK: - Timing Attack Protection
    
    /**
     * Constant-time string comparison to prevent timing attacks
     */
    fun constantTimeCompare(a: String, b: String): Boolean {
        val aBytes = a.toByteArray()
        val bBytes = b.toByteArray()
        return constantTimeCompare(aBytes, bBytes)
    }
    
    /**
     * Constant-time byte array comparison
     */
    fun constantTimeCompare(a: ByteArray, b: ByteArray): Boolean {
        if (a.size != b.size) return false
        
        var result = 0
        for (i in a.indices) {
            result = result or (a[i].toInt() xor b[i].toInt())
        }
        return result == 0
    }
    
    // MARK: - QR Code Integrity
    
    /**
     * Generate integrity hash for QR code data
     */
    fun generateIntegrityHash(data: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(data.toByteArray())
        return hash.joinToString("") { "%02x".format(it) }
    }
    
    /**
     * Verify QR code integrity
     */
    fun verifyIntegrity(data: String, expectedHash: String): Boolean {
        val actualHash = generateIntegrityHash(data)
        return constantTimeCompare(actualHash, expectedHash)
    }
}

/**
 * Security-related exceptions
 */
sealed class SecurityException(message: String, val recoverySuggestion: String? = null) : Exception(message) {
    
    class RateLimitExceeded : SecurityException(
        "Too many operations. Please wait before trying again.",
        "Wait a moment and try again. If this persists, contact support."
    )
    
    class InputTooLong : SecurityException(
        "Input data exceeds maximum allowed length.",
        "Reduce the amount of data in the QR code."
    )
    
    class PotentialInjection : SecurityException(
        "Input contains potentially malicious content.",
        "Remove any script-like content from the input."
    )
    
    class InvalidURL : SecurityException(
        "Invalid URL format detected.",
        "Check the URL format and try again."
    )
    
    class UnsafeURLScheme : SecurityException(
        "URL scheme not allowed for security reasons.",
        "Use https:// or other standard schemes."
    )
    
    class SuspiciousDomain : SecurityException(
        "Domain flagged as potentially suspicious.",
        "Use a trusted domain or contact support if this is incorrect."
    )
    
    class IntegrityCheckFailed : SecurityException(
        "QR code integrity verification failed.",
        "The QR code may have been tampered with. Generate a new one."
    )
} 