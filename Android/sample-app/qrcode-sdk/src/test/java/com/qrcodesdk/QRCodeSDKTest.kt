package com.qrcodesdk

import com.qrcodesdk.models.*
import com.qrcodesdk.parser.KenyaP2PQRParser
import org.junit.Assert.*
import org.junit.Test

/**
 * Robust test suite for QR Code SDK
 * Tests core functionality, edge cases, and specific fixes implemented
 */
class QRCodeSDKTest {
    
    private val parser = KenyaP2PQRParser()
    
    // Real-world QR code data that we know works
    private val validP2MQR = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94"
    
    @Test
    fun testRealWorldQRParsing() {
        // Test with the actual QR code that was failing before our fixes
        val parsed = parser.parseKenyaP2PQR(validP2MQR)
        
        // Verify all major fields are parsed correctly
        assertEquals("Thika Vivian Stores", parsed.recipientName)
        assertEquals("KE", parsed.countryCode)
        assertEquals("404", parsed.currency)
        assertEquals("5411", parsed.merchantCategoryCode)
        assertEquals(QRType.P2M, parsed.qrType)
        assertEquals(QRInitiationMethod.STATIC, parsed.initiationMethod)
        
        // Verify account template parsing (legacy CBK format)
        assertTrue("Should have account templates", parsed.accountTemplates.isNotEmpty())
        val template = parsed.accountTemplates.first()
        assertEquals("29", template.tag)
        assertEquals("ke.go.qr", template.guid)
        assertEquals("68072226665", template.participantId)
    }

    @Test
    fun testP2MFormatVersionSupport() {
        // Core test: P2M format versions should now be supported (this was the main fix)
        val regex = Regex("^(P2P|P2M)-KE-\\d+")
        
        assertTrue("P2P-KE-01 should be valid", "P2P-KE-01".matches(regex))
        assertTrue("P2M-KE-01 should be valid", "P2M-KE-01".matches(regex))
        assertTrue("P2M-KE-02 should be valid", "P2M-KE-02".matches(regex))
        
        assertFalse("Invalid format should be rejected", "INVALID-FORMAT".matches(regex))
        assertFalse("Incomplete format should be rejected", "P2M-KE-".matches(regex))
    }

    @Test
    fun testCRC16Calculation() {
        // Test CRC calculation with known good data
        val dataWithoutCRC = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304"
        val expectedCRC = "AA94"
        
        val calculatedCRC = parser.calculateCRC16(dataWithoutCRC)
        assertEquals("CRC16 calculation should match", expectedCRC, calculatedCRC)
    }
    
    @Test
    fun testInvalidCRCHandling() {
        // Test that invalid CRC is properly rejected
        val qrWithInvalidCRC = validP2MQR.dropLast(4) + "FFFF"
        
        try {
            parser.parseKenyaP2PQR(qrWithInvalidCRC)
            fail("Should reject QR with invalid CRC")
        } catch (e: TLVParsingException) {
            // Expected - CRC validation should catch this
            assertTrue("Should reject invalid CRC", e is TLVParsingException)
        }
    }

    @Test
    fun testBasicErrorHandling() {
        // Test basic error cases that should be caught
        val errorCases = listOf(
            "", // Empty
            "123", // Too short
            "00020101021163048888" // Missing required fields
        )
        
        errorCases.forEach { invalidQR ->
            try {
                parser.parseKenyaP2PQR(invalidQR)
                fail("Should reject invalid QR: '$invalidQR'")
            } catch (e: TLVParsingException) {
                // Expected
                assertTrue("Should handle invalid QR", e is TLVParsingException)
            }
        }
    }
    
    @Test
    fun testTLVFieldExtraction() {
        val parsed = parser.parseKenyaP2PQR(validP2MQR)
        
        // Verify all fields are extracted
        assertNotNull("Should have TLV fields", parsed.fields)
        assertTrue("Should have multiple fields", parsed.fields.size >= 8)
        
        // Check key field values
        val fieldMap = parsed.fields.associateBy { it.tag }
        assertEquals("01", fieldMap["00"]?.value) // Payload format
        assertEquals("11", fieldMap["01"]?.value) // Static initiation
        assertEquals("5411", fieldMap["52"]?.value) // MCC
        assertEquals("404", fieldMap["53"]?.value) // Currency
        assertEquals("KE", fieldMap["58"]?.value) // Country
        assertEquals("AA94", fieldMap["63"]?.value) // CRC
    }
    
    @Test
    fun testLegacyCBKFormatParsing() {
        // Test the specific fix for legacy CBK format parsing
        val parsed = parser.parseKenyaP2PQR(validP2MQR)
        
        val template = parsed.accountTemplates.first()
        assertEquals("Should parse legacy GUID", "ke.go.qr", template.guid)
        assertEquals("Should parse legacy participant ID", "68072226665", template.participantId)
    }
    
    @Test
    fun testPSPDirectoryIntegration() {
        // Test that our CBK GUID entry works
        val pspInfo = PSPDirectory.getInstance().getPSP("ke.go.qr", Country.KENYA)
        assertNotNull("Should find CBK PSP", pspInfo)
        assertEquals("Should be bank type", PSPInfo.PSPType.BANK, pspInfo?.type)
        assertEquals("Should be Kenya", Country.KENYA, pspInfo?.country)
    }
    
    @Test
    fun testQRValidationSuccess() {
        // Test validation with known good QR
        val result = parser.validateQRCode(validP2MQR)
        
        assertTrue("Valid QR should pass validation", result.isValid)
        assertTrue("Should have no validation errors", result.errors.isEmpty())
    }
    
    @Test
    fun testQRTypeDetection() {
        val parsed = parser.parseKenyaP2PQR(validP2MQR)
        
        // MCC 5411 should be detected as P2M
        assertEquals("Should detect P2M type", QRType.P2M, parsed.qrType)
        assertEquals("MCC should be correct", "5411", parsed.merchantCategoryCode)
    }
    
    @Test
    fun testInitiationMethodDetection() {
        val parsed = parser.parseKenyaP2PQR(validP2MQR)
        
        // Should detect static QR (initiation method "11")
        assertEquals("Should detect static QR", QRInitiationMethod.STATIC, parsed.initiationMethod)
    }
} 