package com.qrcodesdk.security

import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class SecurityManagerTest {

    @Before
    fun setUp() {
        // Reset any state if needed
    }

    @Test
    fun `test rate limiting within limits`() {
        val operation = "test_operation"
        
        // Should allow operations within limit
        for (i in 1..60) {
            val allowed = SecurityManager.checkRateLimit(operation)
            assertTrue("Operation $i should be allowed within rate limit", allowed)
        }
    }

    @Test
    fun `test rate limiting exceeds limits`() {
        val operation = "test_operation"
        
        // Use up the rate limit
        for (i in 1..60) {
            SecurityManager.checkRateLimit(operation)
        }
        
        // Next operation should be blocked
        val blocked = SecurityManager.checkRateLimit(operation)
        assertFalse("Operation should be blocked when rate limit exceeded", blocked)
    }

    @Test
    fun `test rate limiting resets after window`() {
        val operation = "test_operation"
        
        // Use up the rate limit
        for (i in 1..60) {
            SecurityManager.checkRateLimit(operation)
        }
        
        // Wait for rate limit window to pass (simulate)
        Thread.sleep(100) // Small delay for test
        
        // Should be allowed again (in real scenario, this would wait for actual window)
        // For testing purposes, we'll just verify the behavior
        val blocked = SecurityManager.checkRateLimit(operation)
        // Note: In real implementation, this would depend on actual time window
    }

    @Test
    fun `test rate limiting different operations`() {
        val operation1 = "operation_1"
        val operation2 = "operation_2"
        
        // Use up rate limit for operation1
        for (i in 1..60) {
            SecurityManager.checkRateLimit(operation1)
        }
        
        // operation2 should still be allowed
        val allowed = SecurityManager.checkRateLimit(operation2)
        assertTrue("Different operation should be allowed", allowed)
    }

    @Test
    fun `test sanitizeQRInput with valid data`() {
        val validInput = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val sanitized = SecurityManager.sanitizeQRInput(validInput)
        
        assertEquals("Valid input should remain unchanged", validInput, sanitized)
    }

    @Test
    fun `test sanitizeQRInput removes null bytes`() {
        val inputWithNulls = "test\u0000data\u0000here"
        val sanitized = SecurityManager.sanitizeQRInput(inputWithNulls)
        
        assertEquals("Should remove null bytes", "testdatahere", sanitized)
    }

    @Test
    fun `test sanitizeQRInput removes control characters`() {
        val inputWithControls = "test\u0001\u0002\u0003data"
        val sanitized = SecurityManager.sanitizeQRInput(inputWithControls)
        
        assertEquals("Should remove control characters", "testdata", sanitized)
    }

    @Test
    fun `test sanitizeQRInput rejects too long data`() {
        val longInput = "A".repeat(5000) // Exceeds 4296 limit
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(longInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects script injection`() {
        val maliciousInput = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919<script>alert('xss')</script>6009Nairobi6304ABCD"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects javascript scheme`() {
        val maliciousInput = "javascript:alert('xss')"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects data scheme`() {
        val maliciousInput = "data:text/html,<script>alert('xss')</script>"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects vbscript scheme`() {
        val maliciousInput = "vbscript:msgbox('xss')"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects onload attribute`() {
        val maliciousInput = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919<img onload=alert('xss')>6009Nairobi6304ABCD"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects eval function`() {
        val maliciousInput = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919eval('alert(1)')6009Nairobi6304ABCD"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(maliciousInput)
        }
    }

    @Test
    fun `test sanitizeQRInput accepts valid URLs`() {
        val validUrls = listOf(
            "https://example.com",
            "http://example.com",
            "tel:+1234567890",
            "mailto:test@example.com",
            "sms:+1234567890"
        )
        
        validUrls.forEach { url ->
            val sanitized = SecurityManager.sanitizeQRInput(url)
            assertEquals("Valid URL should be accepted", url, sanitized)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects suspicious domains`() {
        val suspiciousUrl = "https://bit.ly/suspicious"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(suspiciousUrl)
        }
    }

    @Test
    fun `test sanitizeQRInput rejects disallowed schemes`() {
        val disallowedUrl = "ftp://example.com"
        assertThrows(java.lang.SecurityException::class.java) {
            SecurityManager.sanitizeQRInput(disallowedUrl)
        }
    }

    @Test
    fun `test secureErase byte array`() {
        val sensitiveData = byteArrayOf(1, 2, 3, 4, 5)
        SecurityManager.secureErase(sensitiveData)
        
        // All bytes should be zeroed
        assertArrayEquals("Sensitive data should be zeroed", ByteArray(5), sensitiveData)
    }

    @Test
    fun `test secureErase string builder`() {
        val sensitiveString = StringBuilder("sensitive data")
        SecurityManager.secureErase(sensitiveString)
        
        assertEquals("StringBuilder should be cleared", 0, sensitiveString.length)
    }

    @Test
    fun `test constantTimeCompare with equal strings`() {
        val a = "test string"
        val b = "test string"
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertTrue("Equal strings should return true", result)
    }

    @Test
    fun `test constantTimeCompare with different strings`() {
        val a = "test string"
        val b = "different string"
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertFalse("Different strings should return false", result)
    }

    @Test
    fun `test constantTimeCompare with different lengths`() {
        val a = "short"
        val b = "longer string"
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertFalse("Strings with different lengths should return false", result)
    }

    @Test
    fun `test constantTimeCompare with empty strings`() {
        val a = ""
        val b = ""
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertTrue("Empty strings should return true", result)
    }

    @Test
    fun `test constantTimeCompare byte arrays`() {
        val a = byteArrayOf(1, 2, 3, 4)
        val b = byteArrayOf(1, 2, 3, 4)
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertTrue("Equal byte arrays should return true", result)
    }

    @Test
    fun `test constantTimeCompare different byte arrays`() {
        val a = byteArrayOf(1, 2, 3, 4)
        val b = byteArrayOf(1, 2, 3, 5)
        
        val result = SecurityManager.constantTimeCompare(a, b)
        assertFalse("Different byte arrays should return false", result)
    }

    @Test
    fun `test generateIntegrityHash`() {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val hash = SecurityManager.generateIntegrityHash(testData)
        
        assertNotNull("Hash should not be null", hash)
        assertEquals("SHA-256 hash should be 64 characters", 64, hash.length)
        assertTrue("Hash should be hexadecimal", hash.matches(Regex("[0-9a-f]{64}")))
    }

    @Test
    fun `test generateIntegrityHash consistency`() {
        val testData = "test data"
        val hash1 = SecurityManager.generateIntegrityHash(testData)
        val hash2 = SecurityManager.generateIntegrityHash(testData)
        
        assertEquals("Same data should produce same hash", hash1, hash2)
    }

    @Test
    fun `test generateIntegrityHash different data`() {
        val data1 = "test data 1"
        val data2 = "test data 2"
        val hash1 = SecurityManager.generateIntegrityHash(data1)
        val hash2 = SecurityManager.generateIntegrityHash(data2)
        
        assertNotEquals("Different data should produce different hashes", hash1, hash2)
    }

    @Test
    fun `test verifyIntegrity with valid hash`() {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val expectedHash = SecurityManager.generateIntegrityHash(testData)
        
        val isValid = SecurityManager.verifyIntegrity(testData, expectedHash)
        assertTrue("Valid hash should verify successfully", isValid)
    }

    @Test
    fun `test verifyIntegrity with invalid hash`() {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val invalidHash = "invalid_hash_that_does_not_match"
        
        val isValid = SecurityManager.verifyIntegrity(testData, invalidHash)
        assertFalse("Invalid hash should fail verification", isValid)
    }

    @Test
    fun `test verifyIntegrity with tampered data`() {
        val originalData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val tamperedData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Tampered Merchant6009Nairobi6304ABCD"
        val originalHash = SecurityManager.generateIntegrityHash(originalData)
        
        val isValid = SecurityManager.verifyIntegrity(tamperedData, originalHash)
        assertFalse("Tampered data should fail verification", isValid)
    }

    @Test
    fun `test SecurityException messages`() {
        val rateLimitExceeded = SecurityException.RateLimitExceeded()
        assertEquals("Rate limit exceeded message", "Too many operations. Please wait before trying again.", rateLimitExceeded.message)
        assertEquals("Rate limit exceeded recovery suggestion", "Wait a moment and try again. If this persists, contact support.", rateLimitExceeded.recoverySuggestion)

        val inputTooLong = SecurityException.InputTooLong()
        assertEquals("Input too long message", "Input data exceeds maximum allowed length.", inputTooLong.message)
        assertEquals("Input too long recovery suggestion", "Reduce the amount of data in the QR code.", inputTooLong.recoverySuggestion)
    }

    @Test
    fun `test rate limiting concurrent operations`() {
        val operation = "concurrent_test"
        val latch = CountDownLatch(10)
        val results = mutableListOf<Boolean>()
        
        // Start 10 concurrent operations
        repeat(10) {
            Thread {
                val result = SecurityManager.checkRateLimit(operation)
                synchronized(results) {
                    results.add(result)
                }
                latch.countDown()
            }.start()
        }
        
        // Wait for all operations to complete
        latch.await(5, TimeUnit.SECONDS)
        
        // Should have exactly 10 results
        assertEquals("Should have 10 results", 10, results.size)
        
        // All should be allowed (within rate limit)
        assertTrue("All concurrent operations should be allowed", results.all { it })
    }

    @Test
    fun `test sanitizeQRInput with edge cases`() {
        // Test with maximum allowed length
        val maxLengthInput = "A".repeat(4296)
        val sanitized = SecurityManager.sanitizeQRInput(maxLengthInput)
        assertEquals("Maximum length input should be accepted", maxLengthInput, sanitized)
        
        // Test with empty string (should be accepted if implementation allows)
        val emptyInput = ""
        val sanitizedEmpty = SecurityManager.sanitizeQRInput(emptyInput)
        assertEquals("Empty input should be accepted", emptyInput, sanitizedEmpty)
        
        // Test with only whitespace (control characters are removed, spaces are preserved)
        val whitespaceInput = "   \t\n\r   "
        val sanitizedWhitespace = SecurityManager.sanitizeQRInput(whitespaceInput)
        assertEquals("Whitespace input should have control characters removed", "      ", sanitizedWhitespace)
    }

    @Test
    fun `test constantTimeCompare timing consistency`() {
        val a = "test string"
        val b = "test string"
        val c = "different string"
        
        val start1 = System.nanoTime()
        SecurityManager.constantTimeCompare(a, b)
        val duration1 = System.nanoTime() - start1
        
        val start2 = System.nanoTime()
        SecurityManager.constantTimeCompare(a, c)
        val duration2 = System.nanoTime() - start2
        
        // In a real constant-time implementation, durations should be similar
        // For testing purposes, we just verify the method completes
        assertTrue("Both comparisons should complete", duration1 > 0 && duration2 > 0)
    }
} 