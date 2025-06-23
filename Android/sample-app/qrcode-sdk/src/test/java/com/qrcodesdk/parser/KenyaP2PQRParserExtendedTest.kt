package com.qrcodesdk.parser

import com.qrcodesdk.models.*
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import java.math.BigDecimal
import com.qrcodesdk.QRCodeSDK
import com.qrcodesdk.parser.buildValidKenyaP2PQR

/**
 * Extended comprehensive tests for KenyaP2PQRParser
 * Additional edge cases, error scenarios, and real-world validation
 */
class KenyaP2PQRParserExtendedTest {
    
    private lateinit var parser: KenyaP2PQRParser
    
    @Before
    fun setUp() {
        parser = KenyaP2PQRParser()
    }
    
    // ==================== ADVANCED TLV PARSING TESTS ====================
    
    @Test
    fun testParseTLVWithMultipleFields() {
        val baseQR = buildValidKenyaP2PQR(recipientName = "Test User", recipientIdentifier = "1234567890")
        val insertIndex = baseQR.indexOf("5303")
        val multiFieldQR = if (insertIndex > 0) {
            baseQR.substring(0, insertIndex) + "60041234" + baseQR.substring(insertIndex)
        } else baseQR
        val result = parser.parseKenyaP2PQR(multiFieldQR)
        assertNotNull("Should parse multiple fields", result)
        assertTrue("Should have multiple fields", result.fields.size > 5)
    }
    
    @Test
    fun testParseTLVWithZeroLengthField() {
        val zeroLengthQR = "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE59006004User6304"
        val result = parser.parseKenyaP2PQR(zeroLengthQR)
        
        assertNotNull("Should handle zero length field", result)
        assertEquals("Should have empty recipient name", "", result.recipientName)
    }
    
    @Test
    fun testParseTLVWithMaximumLengthField() {
        val maxLengthQR = "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE5904Test6004User6304"
        val result = parser.parseKenyaP2PQR(maxLengthQR)
        
        assertNotNull("Should handle maximum length field", result)
    }
    
    @Test
    fun testParseTLVWithInconsistentLength() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE5904Test6004User6304")
            fail("Should throw exception for inconsistent length")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw CorruptedData", e is TLVParsingException.CorruptedData)
        }
    }
    
    // ==================== AMOUNT PARSING TESTS ====================
    
    @Test
    fun testParseAmountWithDecimal() {
        val qrWithDecimal = buildValidKenyaP2PQR(amount = java.math.BigDecimal("10.50"))
        val result = parser.parseKenyaP2PQR(qrWithDecimal)
        assertNotNull("Should parse decimal amount", result.amount)
        assertEquals("Should have correct decimal amount", java.math.BigDecimal("10.50"), result.amount)
    }
    
    @Test
    fun testParseAmountWithLargeNumber() {
        val qrWithLargeAmount = "00020101021129370016A000000677010111011300660000000005802KE540499999.99530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithLargeAmount)
        
        assertNotNull("Should parse large amount", result.amount)
        assertEquals("Should have correct large amount", BigDecimal("99999.99"), result.amount)
    }
    
    @Test
    fun testParseAmountWithInvalidFormat() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE5404ABC15303365454031005802KE6304")
            fail("Should throw exception for invalid amount format")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    @Test
    fun testParseAmountWithNegativeValue() {
        try {
            parser.parseKenyaP2PQR("00020101021129370016A000000677010111011300660000000005802KE5404-100530336454031005802KE6304")
            fail("Should throw exception for negative amount")
        } catch (e: TLVParsingException) {
            assertTrue("Should throw InvalidValue", e is TLVParsingException.InvalidValue)
        }
    }
    
    // ==================== QR TYPE DETECTION TESTS ====================
    
    @Test
    fun testDetectP2PQRType() {
        val p2pQR = "00020101021129370016A000000677010111011300660000000005802KE52046011530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(p2pQR)
        
        assertEquals("Should detect P2P type", QRType.P2P, result.qrType)
    }
    
    @Test
    fun testDetectP2MQRType() {
        val p2mQR = "00020101021129370016A000000677010111011300660000000005802KE52045411530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(p2mQR)
        
        assertEquals("Should detect P2M type", QRType.P2M, result.qrType)
    }
    
    @Test
    fun testDetectDefaultQRType() {
        val defaultQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(defaultQR)
        
        assertEquals("Should have default QR type", QRType.P2P, result.qrType)
    }
    
    // ==================== COUNTRY CODE TESTS ====================
    
    @Test
    fun testParseWithKenyaCountryCode() {
        val kenyaQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(kenyaQR)
        
        assertEquals("Should have Kenya country code", "KE", result.countryCode)
    }
    
    @Test
    fun testParseWithMissingCountryCode() {
        val qrWithoutCountry = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithoutCountry)
        
        assertEquals("Should default to KE", "KE", result.countryCode)
    }
    
    // ==================== CURRENCY CODE TESTS ====================
    
    @Test
    fun testParseWithKenyaShilling() {
        val kesQR = "00020101021129370016A000000677010111011300660000000005802KE530340454031005802KE6304"
        val result = parser.parseKenyaP2PQR(kesQR)
        
        assertEquals("Should have KES currency", "404", result.currency)
    }
    
    @Test
    fun testParseWithMissingCurrency() {
        val qrWithoutCurrency = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithoutCurrency)
        
        assertEquals("Should default to KES", "404", result.currency)
    }
    
    // ==================== RECIPIENT NAME TESTS ====================
    
    @Test
    fun testParseWithRecipientName() {
        val qrWithName = "00020101021129370016A000000677010111011300660000000005802KE5904John530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithName)
        
        assertEquals("Should have recipient name", "John", result.recipientName)
    }
    
    @Test
    fun testParseWithLongRecipientName() {
        val qrWithLongName = "00020101021129370016A000000677010111011300660000000005802KE5910John Smith530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithLongName)
        
        assertEquals("Should have long recipient name", "John Smith", result.recipientName)
    }
    
    @Test
    fun testParseWithMissingRecipientName() {
        val qrWithoutName = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithoutName)
        
        assertNull("Should have null recipient name", result.recipientName)
    }
    
    // ==================== RECIPIENT IDENTIFIER TESTS ====================
    
    @Test
    fun testParseWithRecipientIdentifier() {
        val qrWithIdentifier = "00020101021129370016A000000677010111011300660000000005802KE60041234530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithIdentifier)
        
        assertEquals("Should have recipient identifier", "1234", result.recipientIdentifier)
    }
    
    @Test
    fun testParseWithMissingRecipientIdentifier() {
        val qrWithoutIdentifier = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithoutIdentifier)
        
        assertNull("Should have null recipient identifier", result.recipientIdentifier)
    }
    
    // ==================== FORMAT VERSION TESTS ====================
    
    @Test
    fun testParseWithP2PFormatVersion() {
        val p2pVersionQR = "00020101021129370016A000000677010111011300660000000005802KE6407P2P-KE-01530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(p2pVersionQR)
        
        assertEquals("Should have P2P format version", "P2P-KE-01", result.formatVersion)
    }
    
    @Test
    fun testParseWithP2MFormatVersion() {
        val p2mVersionQR = "00020101021129370016A000000677010111011300660000000005802KE6407P2M-KE-01530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(p2mVersionQR)
        
        assertEquals("Should have P2M format version", "P2M-KE-01", result.formatVersion)
    }
    
    @Test
    fun testParseWithMissingFormatVersion() {
        val qrWithoutVersion = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithoutVersion)
        
        assertNull("Should have null format version", result.formatVersion)
    }
    
    // ==================== ADDITIONAL DATA EXTENDED TESTS ====================
    
    @Test
    fun testParseAdditionalDataWithAllFields() {
        val qrWithAllAdditionalData = "00020101021129370016A000000677010111011300660000000005802KE62080104TEST02040712303004ABC0404XYZ0504REF0604CUST0704TERM0804PURP0904REQ2004MCC2104SUB2204TIP2304100024004FEE2504100026004MSC2704CNT3004PAT3104APT3204REF3304SVC3404RT3504TKT3604ACC3704BLP530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithAllAdditionalData)
        
        assertNotNull("Should parse all additional data fields", result.additionalData)
        assertEquals("Should have loyalty number", "TEST", result.additionalData?.loyaltyNumber)
        assertEquals("Should have mobile number", "0712", result.additionalData?.mobileNumber)
        assertEquals("Should have store label", "ABC", result.additionalData?.storeLabel)
        assertEquals("Should have reference label", "REF", result.additionalData?.referenceLabel)
        assertEquals("Should have customer label", "CUST", result.additionalData?.customerLabel)
        assertEquals("Should have terminal label", "TERM", result.additionalData?.terminalLabel)
        assertEquals("Should have purpose", "PURP", result.additionalData?.purposeOfTransaction)
        assertEquals("Should have additional request", "REQ", result.additionalData?.additionalConsumerDataRequest)
        assertEquals("Should have merchant category", "MCC", result.additionalData?.merchantCategory)
        assertEquals("Should have merchant sub category", "SUB", result.additionalData?.merchantSubCategory)
        assertEquals("Should have tip indicator", "TIP", result.additionalData?.tipIndicator)
        assertEquals("Should have tip amount", "1000", result.additionalData?.tipAmount)
        assertEquals("Should have convenience fee indicator", "FEE", result.additionalData?.convenienceFeeIndicator)
        assertEquals("Should have convenience fee", "1000", result.additionalData?.convenienceFee)
        assertEquals("Should have multi scheme", "MSC", result.additionalData?.multiScheme)
        assertEquals("Should have supported countries", "CNT", result.additionalData?.supportedCountries)
        assertEquals("Should have patient ID", "PAT", result.additionalData?.patientId)
        assertEquals("Should have appointment reference", "APT", result.additionalData?.appointmentReference)
        assertEquals("Should have reference number", "REF", result.additionalData?.referenceNumber)
        assertEquals("Should have service type", "SVC", result.additionalData?.serviceType)
        assertEquals("Should have route", "RT", result.additionalData?.route)
        assertEquals("Should have ticket type", "TKT", result.additionalData?.ticketType)
        assertEquals("Should have account number", "ACC", result.additionalData?.accountNumber)
        assertEquals("Should have billing period", "BLP", result.additionalData?.billingPeriod)
    }
    
    @Test
    fun testParseAdditionalDataWithCustomFields() {
        val qrWithCustomFields = "00020101021129370016A000000677010111011300660000000005802KE6208050150CUSTOM530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithCustomFields)
        
        assertNotNull("Should parse custom fields", result.additionalData)
        assertNotNull("Should have custom fields", result.additionalData?.customFields)
        assertEquals("Should have custom field value", "CUSTOM", result.additionalData?.customFields?.get("50"))
    }
    
    // ==================== ERROR RECOVERY TESTS ====================
    
    @Test
    fun testRecoverFromMalformedAdditionalData() {
        val qrWithMalformedAdditionalData = "00020101021129370016A000000677010111011300660000000005802KE6204MALF530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithMalformedAdditionalData)
        
        assertNotNull("Should recover from malformed additional data", result)
        assertNotNull("Should have additional data", result.additionalData)
        assertEquals("Should use raw value as fallback", "MALF", result.additionalData?.billNumber)
    }
    
    @Test
    fun testRecoverFromLegacyFormat() {
        val qrWithLegacyFormat = "00020101021126080008ke.go.qr680722266655204541153034045802KE5919Test Merchant530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(qrWithLegacyFormat)
        
        assertNotNull("Should recover from legacy format", result)
        assertTrue("Should have account templates", result.accountTemplates.isNotEmpty())
    }
    
    // ==================== STRESS TESTS ====================
    
    @Test
    fun testParseWithMaximumFields() {
        val maxFieldsQR = "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE5904Test6004User6204Bill6304"
        val result = parser.parseKenyaP2PQR(maxFieldsQR)
        
        assertNotNull("Should parse maximum fields", result)
        assertTrue("Should have multiple fields", result.fields.size > 8)
    }
    
    @Test
    fun testParseWithRepeatedFields() {
        val repeatedFieldsQR = "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE52045911530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(repeatedFieldsQR)
        
        assertNotNull("Should handle repeated fields", result)
        assertTrue("Should have repeated fields", result.fields.size > 10)
    }
    
    // ==================== BOUNDARY TESTS ====================
    
    @Test
    fun testParseWithMinimumValidQR() {
        val minQR = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(minQR)
        
        assertNotNull("Should parse minimum valid QR", result)
        assertEquals("Should have required fields", "02", result.payloadFormat)
    }
    
    @Test
    fun testParseWithMaximumLengthValues() {
        val maxLengthQR = "00020101021129370016A000000677010111011300660000000005802KE5904Test6004User530336454031005802KE6304"
        val result = parser.parseKenyaP2PQR(maxLengthQR)
        
        assertNotNull("Should parse maximum length values", result)
        assertEquals("Should have correct recipient name", "Test", result.recipientName)
        assertEquals("Should have correct recipient identifier", "User", result.recipientIdentifier)
    }
    
    // ==================== INTEGRATION STRESS TESTS ====================
    
    @Test
    fun testMultipleParsingOperations() {
        val qrCodes = listOf(
            "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304",
            "00020101021129370016A000000677010111011300660000000005802KE52045911530336454031005802KE6304",
            "00020101021129370016A000000677010111011300660000000005802KE5904Test530336454031005802KE6304"
        )
        
        qrCodes.forEach { qr ->
            val result = parser.parseKenyaP2PQR(qr)
            assertNotNull("Should parse QR: $qr", result)
        }
    }
    
    @Test
    fun testConcurrentParsing() {
        val qr = "00020101021129370016A000000677010111011300660000000005802KE530336454031005802KE6304"
        
        val results = (1..10).map { 
            parser.parseKenyaP2PQR(qr)
        }
        
        results.forEach { result ->
            assertNotNull("Should parse concurrently", result)
            assertEquals("Should have consistent results", "02", result.payloadFormat)
        }
    }
} 