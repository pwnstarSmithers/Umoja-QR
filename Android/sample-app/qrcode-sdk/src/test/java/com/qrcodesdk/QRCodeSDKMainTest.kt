package com.qrcodesdk

import com.qrcodesdk.models.*
import org.junit.Assert.*
import org.junit.Test
import java.math.BigDecimal

/**
 * Tests for the main QRCodeSDK entry point
 */
class QRCodeSDKMainTest {
    
    private val validP2MQR = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94"
    
    @Test
    fun testParseQRSuccess() {
        val parsed = QRCodeSDK.parseQR(validP2MQR)
        
        assertNotNull("Should parse QR successfully", parsed)
        assertEquals("Should have correct recipient name", "Thika Vivian Stores", parsed.recipientName)
        assertEquals("Should have correct country", "KE", parsed.countryCode)
        assertEquals("Should have correct currency", "404", parsed.currency)
        assertEquals("Should have correct QR type", QRType.P2M, parsed.qrType)
    }
    
    @Test
    fun testParseQREmptyInput() {
        try {
            QRCodeSDK.parseQR("")
            fail("Should throw exception for empty input")
        } catch (e: TLVParsingException) {
            assertTrue("Should handle empty input", e is TLVParsingException)
        }
    }
    
    @Test
    fun testParseQRInvalidInput() {
        val invalidInputs = listOf(
            "invalid",
            "123",
            "00020101021163048888" // Missing required fields
        )
        
        invalidInputs.forEach { invalid ->
            try {
                QRCodeSDK.parseQR(invalid)
                fail("Should throw exception for invalid input: '$invalid'")
            } catch (e: TLVParsingException) {
                assertTrue("Should handle invalid input", e is TLVParsingException)
            }
        }
    }
    
    @Test
    fun testGenerateQRString() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "ke.go.qr",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "123456789",
            pspInfo = pspInfo
        )
        
        val request = QRCodeGenerationRequest(
            qrType = QRType.P2M,
            initiationMethod = QRInitiationMethod.STATIC,
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "5411",
            amount = BigDecimal("100.00"),
            recipientName = "Test Store",
            recipientIdentifier = "123456789",
            currency = "404",
            countryCode = "KE"
        )
        
        val generated = QRCodeSDK.generateQRString(request)
        
        assertNotNull("Should generate QR string", generated)
        assertTrue("Should be non-empty", generated.isNotEmpty())
        assertTrue("Should start with EMVCo format", generated.startsWith("00"))
        assertTrue("Should end with CRC", generated.length >= 4)
    }
    
    @Test
    fun testGenerateQRStringWithNullValues() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "ke.go.qr",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "123456789",
            pspInfo = pspInfo
        )
        
        val request = QRCodeGenerationRequest(
            qrType = QRType.P2M,
            initiationMethod = QRInitiationMethod.STATIC,
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "5411",
            amount = null,
            recipientName = "Test Store",
            recipientIdentifier = "123456789",
            currency = "404",
            countryCode = "KE"
        )
        
        val generated = QRCodeSDK.generateQRString(request)
        
        assertNotNull("Should generate QR string with null amount", generated)
        assertTrue("Should be non-empty", generated.isNotEmpty())
    }
    
    @Test
    fun testGenerateQRStringP2P() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "ke.go.qr",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "987654321",
            pspInfo = pspInfo
        )
        
        val request = QRCodeGenerationRequest(
            qrType = QRType.P2P,
            initiationMethod = QRInitiationMethod.STATIC,
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "0000", // P2P MCC
            amount = BigDecimal("50.00"),
            recipientName = null,
            recipientIdentifier = "987654321",
            currency = "404",
            countryCode = "KE"
        )
        
        val generated = QRCodeSDK.generateQRString(request)
        
        assertNotNull("Should generate P2P QR string", generated)
        assertTrue("Should be non-empty", generated.isNotEmpty())
    }
} 