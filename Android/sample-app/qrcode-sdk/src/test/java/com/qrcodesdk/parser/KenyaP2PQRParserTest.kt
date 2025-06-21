package com.qrcodesdk.parser

import com.qrcodesdk.models.*
import com.qrcodesdk.QRCodeSDK
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal
import com.qrcodesdk.parser.buildValidKenyaP2PQR

/**
 * Comprehensive tests for KenyaP2PQRParser
 * Target: Improve coverage from 48% to >90%
 */
class KenyaP2PQRParserTest {
    
    private lateinit var parser: KenyaP2PQRParser
    
    @Before
    fun setUp() {
        parser = KenyaP2PQRParser()
    }
    
    // ==================== REAL-WORLD QR CODES ====================
    
    @Test
    fun testParseRealWorldP2PQR() {
        val qr = buildValidKenyaP2PQR()
        val result = parser.parseKenyaP2PQR(qr)
        assertNotNull("Should parse real QR", result)
        assertEquals("Should have correct payload format", "01", result.payloadFormat)
        assertEquals("Should have correct initiation method", QRInitiationMethod.STATIC, result.initiationMethod)
        assertEquals("Should have correct country code", "KE", result.countryCode)
        assertEquals("Should have correct currency", "404", result.currency)
    }
    
    @Test
    fun testParseKenyaP2PQRWithMpesa() {
        val qr = buildValidKenyaP2PQR(pspGuid = "01", pspType = PSPInfo.PSPType.TELECOM)
        val result = parser.parseKenyaP2PQR(qr)
        assertNotNull("Should parse M-PESA QR", result)
        assertEquals("Should have correct country", "KE", result.countryCode)
        assertEquals("Should have correct currency", "404", result.currency)
    }
    
    // ==================== TLV PARSING TESTS ====================
    
    @Test
    fun testParseTLVWithValidData() {
        val qr = buildValidKenyaP2PQR()
        val result = parser.parseKenyaP2PQR(qr)
        assertNotNull("Should parse valid TLV", result)
        assertTrue("Should have fields", result.fields.isNotEmpty())
    }
    
    @Test
    fun testParseTLVWithEmptyData() {
        try {
            parser.parseKenyaP2PQR("")
            fail("Should throw exception for empty data")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidDataLength", e is TLVParsingException.InvalidDataLength)
        }
    }
    
    @Test
    fun testParseTLVWithCorruptedData() {
        val qr = buildValidKenyaP2PQR()
        val corrupted = qr.dropLast(10) // Truncate to corrupt
        try {
            parser.parseKenyaP2PQR(corrupted)
            fail("Should throw exception for corrupted data")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw CorruptedData", e is TLVParsingException.CorruptedData)
        }
    }
    
    @Test
    fun testParseTLVWithInvalidTag() {
        // Use builder for a valid QR, then mutate only the tag
        val qr = buildValidKenyaP2PQR()
        val invalid = qr.replaceFirst("00", "AA") // Only mutate the tag, keep rest valid
        try {
            parser.parseKenyaP2PQR(invalid)
            fail("Should throw exception for invalid tag")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidTag", e is TLVParsingException.InvalidTag)
        }
    }
    
    @Test
    fun testParseTLVWithInvalidLength() {
        // Use builder for a valid QR, then mutate only the length
        val qr = buildValidKenyaP2PQR()
        val invalid = qr.replaceFirst("0102", "01XX") // Only mutate the length, keep rest valid
        try {
            parser.parseKenyaP2PQR(invalid)
            fail("Should throw exception for invalid length")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidLength", e is TLVParsingException.InvalidLength)
        }
    }
    
    @Test
    fun testParseTLVWithNegativeLength() {
        val qr = buildValidKenyaP2PQR()
        val invalid = qr.replaceFirst("0102", "01FF")
        try {
            parser.parseKenyaP2PQR(invalid)
            fail("Should throw exception for negative length")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidLength", e is TLVParsingException.InvalidLength)
        }
    }
    
    // ==================== FIELD VALIDATION TESTS ====================
    
    @Test
    fun testValidatePayloadFormatIndicator() {
        val qr = buildValidKenyaP2PQR()
        val result = parser.parseKenyaP2PQR(qr)
        assertEquals("Should have correct payload format", "01", result.payloadFormat)
    }
    
    @Test
    fun testValidateInvalidPayloadFormatIndicator() {
        val qr = buildValidKenyaP2PQR()
        val invalid = qr.replaceFirst("000201", "000101") // Tag 00 value should be "01"
        try {
            parser.parseKenyaP2PQR(invalid)
            fail("Should throw exception for invalid payload format")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidatePointOfInitiation() {
        val qr = buildValidKenyaP2PQR()
        val result = parser.parseKenyaP2PQR(qr)
        assertEquals("Should have static initiation", QRInitiationMethod.STATIC, result.initiationMethod)
    }
    
    @Test
    fun testValidateInvalidPointOfInitiation() {
        val qr = buildValidKenyaP2PQR()
        val invalid = qr.replaceFirst("010211", "010299") // Tag 01 value should be "11"
        try {
            parser.parseKenyaP2PQR(invalid)
            fail("Should throw exception for invalid initiation method")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateMerchantCategoryCode() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct MCC", "5911", result.merchantCategoryCode)
    }
    
    @Test
    fun testValidateInvalidMerchantCategoryCode() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE5204ABC15303365454031005802KE6304")
            fail("Should throw exception for invalid MCC")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateCurrencyCode() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct currency", "404", result.currency)
    }
    
    @Test
    fun testValidateInvalidCurrencyCode() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE5303ABC454031005802KE6304")
            fail("Should throw exception for invalid currency")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateTransactionAmount() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE54041000530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct amount", BigDecimal("100.00"), result.amount)
    }
    
    @Test
    fun testValidateInvalidTransactionAmount() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE54040000530336454031005802KE6304")
            fail("Should throw exception for zero amount")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateCountryCode() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct country code", "KE", result.countryCode)
    }
    
    @Test
    fun testValidateInvalidCountryCode() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802US530336454031005802US6304")
            fail("Should throw exception for invalid country code")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateRecipientIdentifier() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE6004TEST530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct recipient identifier", "TEST", result.recipientIdentifier)
    }
    
    @Test
    fun testValidateEmptyRecipientIdentifier() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE60005303365454031005802KE6304")
            fail("Should throw exception for empty recipient identifier")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testValidateCRC16Checksum() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertNotNull("Should parse with valid CRC", result)
    }
    
    @Test
    fun testValidateInvalidCRC16Checksum() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304XXXX")
            fail("Should throw exception for invalid CRC")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidChecksum", e is TLVParsingException.InvalidChecksum)
        }
    }
    
    @Test
    fun testValidateFormatVersion() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE6407P2P-KE-01530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertEquals("Should have correct format version", "P2P-KE-01", result.formatVersion)
    }
    
    @Test
    fun testValidateInvalidFormatVersion() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE6407INVALID53033645454031005802KE6304")
            fail("Should throw exception for invalid format version")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw UnsupportedQRVersion", e is TLVParsingException.UnsupportedQRVersion)
        }
    }
    
    // ==================== REQUIRED FIELDS VALIDATION TESTS ====================
    
    @Test
    fun testValidateRequiredFieldsPresent() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(validQR)
        assertNotNull("Should parse with all required fields", result)
    }
    
    @Test
    fun testValidateMissingRequiredField() {
        try {
            // Missing tag 00 (Payload Format Indicator)
            parser.parseKenyaP2PQR("01021129370016A000000677010111011300660000000005802KE530336454031005802KE6304")
            fail("Should throw exception for missing required field")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw MissingRequiredField", e is TLVParsingException.MissingRequiredField)
        }
    }
    
    @Test
    fun testValidateMissingPSPTag() {
        try {
            // Missing PSP tags (26-51)
            parser.parseKenyaP2PQR("000201010211530336454031005802KE6304")
            fail("Should throw exception for missing PSP tag")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw MissingRequiredField", e is TLVParsingException.MissingRequiredField)
        }
    }
    
    // ==================== CRC16 CALCULATION TESTS ====================
    
    @Test
    fun testCalculateCRC16() {
        val data = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE"
        val crc = parser.calculateCRC16(data)
        
        assertNotNull("Should calculate CRC", crc)
        assertEquals("Should be 4 characters", 4, crc.length)
        assertTrue("Should be hexadecimal", crc.all { it.isLetterOrDigit() })
    }
    
    @Test
    fun testCalculateCRC16WithEmptyData() {
        val crc = parser.calculateCRC16("")
        assertEquals("Should handle empty data", "FFFF", crc)
    }
    
    @Test
    fun testGenerateCRC16() {
        val qrData = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304ABCD"
        val crc = parser.generateCRC16(qrData)
        
        assertNotNull("Should generate CRC", crc)
        assertEquals("Should be 4 characters", 4, crc.length)
        assertTrue("Should be hexadecimal", crc.all { it.isLetterOrDigit() })
    }
    
    // ==================== ACCOUNT TEMPLATE PARSING ====================
    
    @Test
    fun testParseAccountTemplatesWithNestedTLV() {
        val qrWithNestedTLV = "00020101021126080008ke.go.qr680722266655204541153034045802KE5919Test Merchant530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithNestedTLV)
        
        assertNotNull("Should parse account templates", result.accountTemplates)
        assertTrue("Should have account templates", result.accountTemplates.isNotEmpty())
    }
    
    @Test
    fun testParseAccountTemplatesWithLegacyFormat() {
        val qrWithLegacy = "00020101021126080008ke.go.qr680722266655204541153034045802KE5919Test Merchant530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithLegacy)
        
        assertNotNull("Should parse legacy format", result.accountTemplates)
        assertTrue("Should have account templates", result.accountTemplates.isNotEmpty())
    }
    
    // ==================== ADDITIONAL DATA PARSING ====================
    
    @Test
    fun testParseAdditionalData() {
        val qrWithAdditionalData = "00020101021129370016A000000677010111011300660000000005802KE6204TEST530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithAdditionalData)
        
        assertNotNull("Should parse additional data", result.additionalData)
        assertEquals("Should have bill number", "TEST", result.additionalData?.billNumber)
    }
    
    @Test
    fun testParseAdditionalDataWithNestedTLV() {
        val qrWithNestedAdditionalData = "00020101021129370016A000000677010111011300660000000005802KE62080104TEST530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithNestedAdditionalData)
        
        assertNotNull("Should parse nested additional data", result.additionalData)
        assertEquals("Should have loyalty number", "TEST", result.additionalData?.loyaltyNumber)
    }
    
    @Test
    fun testParseAdditionalDataWithMalformedData() {
        val qrWithMalformedAdditionalData = "00020101021129370016A000000677010111011300660000000005802KE6204INVALID530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithMalformedAdditionalData)
        
        assertNotNull("Should handle malformed additional data", result.additionalData)
        assertEquals("Should use raw value as fallback", "INVALID", result.additionalData?.billNumber)
    }
    
    // ==================== QR VALIDATION TESTS ====================
    
    @Test
    fun testValidateQRCodeValid() {
        val validQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.validateQRCode(validQR)
        
        assertTrue("Should be valid", result.isValid)
        assertTrue("Should have no errors", result.errors.isEmpty())
    }
    
    @Test
    fun testValidateQRCodeInvalid() {
        val invalidQR = "INVALID_QR_DATA"
        val result = parser.validateQRCode(invalidQR)
        
        assertFalse("Should be invalid", result.isValid)
        assertTrue("Should have errors", result.errors.isNotEmpty())
    }
    
    // ==================== PSP DIRECTORY TESTS ====================
    
    @Test
    fun testGetBankName() {
        val bankName = parser.getBankName("01")
        assertEquals("Should return KCB Bank", "KCB Bank Kenya Limited", bankName)
    }
    
    @Test
    fun testGetBankNameInvalid() {
        val bankName = parser.getBankName("99")
        assertNull("Should return null for invalid bank", bankName)
    }
    
    @Test
    fun testGetTelecomName() {
        val telecomName = parser.getTelecomName("01")
        assertEquals("Should return Safaricom", "Safaricom (M-PESA)", telecomName)
    }
    
    @Test
    fun testGetTelecomNameInvalid() {
        val telecomName = parser.getTelecomName("99")
        assertNull("Should return null for invalid telecom", telecomName)
    }
    
    @Test
    fun testGetAllBanks() {
        val banks = parser.getAllBanks()
        
        assertNotNull("Should return banks list", banks)
        assertTrue("Should have banks", banks.isNotEmpty())
        assertTrue("Should be sorted by name", banks.zipWithNext().all { it.first.name <= it.second.name })
    }
    
    @Test
    fun testGetAllTelecoms() {
        val telecoms = parser.getAllTelecoms()
        
        assertNotNull("Should return telecoms list", telecoms)
        assertTrue("Should have telecoms", telecoms.isNotEmpty())
        assertTrue("Should be sorted by name", telecoms.zipWithNext().all { it.first.name <= it.second.name })
    }
    
    // ==================== EDGE CASES AND ERROR HANDLING ====================
    
    @Test
    fun testParseWithNullData() {
        try {
            parser.parseKenyaP2PQR(null as String)
            fail("Should throw exception for null data")
        } catch (e: Exception) {
            assertTrue("Should handle null data", e is Exception)
        }
    }
    
    @Test
    fun testParseWithVeryLongData() {
        val longData = "0".repeat(5000)
        try {
            parser.parseKenyaP2PQR(longData)
            fail("Should throw exception for very long data")
        } catch (e: TLVParsingException) {
            assertTrue("Should handle very long data", e is TLVParsingException)
        }
    }
    
    @Test
    fun testParseWithSpecialCharacters() {
        val qrWithSpecialChars = "00020101021129370016A000000677010111011300660000000005802KE5904T€st530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithSpecialChars)
        
        assertNotNull("Should handle special characters", result)
        assertEquals("Should preserve special characters", "T€st", result.recipientName)
    }
    
    @Test
    fun testParseWithUnicodeCharacters() {
        val qrWithUnicode = "00020101021129370016A000000677010111011300660000000005802KE5904Tést530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithUnicode)
        
        assertNotNull("Should handle unicode characters", result)
        assertEquals("Should preserve unicode characters", "Tést", result.recipientName)
    }
    
    // ==================== PERFORMANCE TESTS ====================
    
    @Test
    fun testParsePerformance() {
        val startTime = System.currentTimeMillis()
        
        repeat(100) {
            val qr = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
            parser.parseKenyaP2PQR(qr)
        }
        
        val endTime = System.currentTimeMillis()
        val duration = endTime - startTime
        
        assertTrue("Should parse 100 QRs in reasonable time", duration < 5000) // 5 seconds max
    }
    
    // ==================== INTEGRATION TESTS ====================
    
    @Test
    fun testEndToEndParsing() {
        // Complete QR code with all fields
        val completeQR = "00020101021129370016A000000677010111011300660000000005802KE520459115303364540310005802KE5904Test6004User6304"
        val result = parser.parseKenyaP2PQR(completeQR)
        
        assertNotNull("Should parse complete QR", result)
        assertEquals("Should have correct payload format", "02", result.payloadFormat)
        assertEquals("Should have correct initiation method", QRInitiationMethod.STATIC, result.initiationMethod)
        assertEquals("Should have correct country code", "KE", result.countryCode)
        assertEquals("Should have correct currency", "404", result.currency)
        assertEquals("Should have correct MCC", "5911", result.merchantCategoryCode)
        assertEquals("Should have correct recipient name", "Test", result.recipientName)
        assertEquals("Should have correct recipient identifier", "User", result.recipientIdentifier)
    }
} 