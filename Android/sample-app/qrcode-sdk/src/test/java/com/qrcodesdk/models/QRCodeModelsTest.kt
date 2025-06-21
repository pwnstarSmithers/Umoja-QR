package com.qrcodesdk.models

import org.junit.Assert.*
import org.junit.Test
import java.math.BigDecimal

/**
 * Comprehensive tests for QRCodeModels functionality
 */
class QRCodeModelsTest {
    
    @Test
    fun testQRTypeEnum() {
        assertEquals("P2P", QRType.P2P.name)
        assertEquals("P2M", QRType.P2M.name)
        
        assertEquals(QRType.P2P, QRType.valueOf("P2P"))
        assertEquals(QRType.P2M, QRType.valueOf("P2M"))
    }
    
    @Test
    fun testQRInitiationMethodEnum() {
        assertEquals("STATIC", QRInitiationMethod.STATIC.name)
        assertEquals("DYNAMIC", QRInitiationMethod.DYNAMIC.name)
        
        assertEquals(QRInitiationMethod.STATIC, QRInitiationMethod.valueOf("STATIC"))
        assertEquals(QRInitiationMethod.DYNAMIC, QRInitiationMethod.valueOf("DYNAMIC"))
    }
    
    @Test
    fun testQRInitiationMethodFromValue() {
        assertEquals(QRInitiationMethod.STATIC, QRInitiationMethod.fromValue("11"))
        assertEquals(QRInitiationMethod.DYNAMIC, QRInitiationMethod.fromValue("12"))
        assertNull(QRInitiationMethod.fromValue("99"))
    }
    
    @Test
    fun testCountryEnum() {
        assertEquals("KENYA", Country.KENYA.name)
        assertEquals("TANZANIA", Country.TANZANIA.name)
        
        assertEquals(Country.KENYA, Country.valueOf("KENYA"))
        assertEquals(Country.TANZANIA, Country.valueOf("TANZANIA"))
    }
    
    @Test
    fun testCountryFromCode() {
        assertEquals(Country.KENYA, Country.fromCode("KE"))
        assertEquals(Country.TANZANIA, Country.fromCode("TZ"))
        assertNull(Country.fromCode("XX"))
    }
    
    @Test
    fun testCountryGetCode() {
        assertEquals("KE", Country.KENYA.code)
        assertEquals("TZ", Country.TANZANIA.code)
    }
    
    @Test
    fun testTLVField() {
        val field = TLVField("00", 2, "01")
        
        assertEquals("00", field.tag)
        assertEquals(2, field.length)
        assertEquals("01", field.value)
    }
    
    @Test
    fun testTLVFieldToString() {
        val field = TLVField("00", 2, "01")
        val expected = "TLVField(tag=00, length=2, value=01, nestedFields=null)"
        assertEquals("Should have correct string representation", expected, field.toString())
    }
    
    @Test
    fun testAccountTemplate() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val template = AccountTemplate(
            tag = "29",
            guid = "test.guid",
            participantId = "123456789",
            accountId = "ACC001",
            pspInfo = pspInfo
        )
        
        assertEquals("29", template.tag)
        assertEquals("test.guid", template.guid)
        assertEquals("123456789", template.participantId)
        assertEquals("ACC001", template.accountId)
        assertEquals(pspInfo, template.pspInfo)
    }
    
    @Test
    fun testAccountTemplateWithNullAccountId() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val template = AccountTemplate(
            tag = "29",
            guid = "test.guid",
            participantId = "123456789",
            accountId = null,
            pspInfo = pspInfo
        )
        
        assertNull("Should have null accountId", template.accountId)
    }
    
    @Test
    fun testPSPInfo() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        assertEquals(PSPInfo.PSPType.BANK, pspInfo.type)
        assertEquals("test.bank", pspInfo.identifier)
        assertEquals("Test Bank", pspInfo.name)
        assertEquals(Country.KENYA, pspInfo.country)
    }
    
    @Test
    fun testPSPInfoPSPType() {
        assertEquals("BANK", PSPInfo.PSPType.BANK.name)
        assertEquals("TELECOM", PSPInfo.PSPType.TELECOM.name)
        assertEquals("PAYMENT_GATEWAY", PSPInfo.PSPType.PAYMENT_GATEWAY.name)
        assertEquals("UNIFIED", PSPInfo.PSPType.UNIFIED.name)
    }
    
    @Test
    fun testQRCodeGenerationRequest() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "test.guid",
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
        
        assertEquals(QRType.P2M, request.qrType)
        assertEquals(QRInitiationMethod.STATIC, request.initiationMethod)
        assertEquals(listOf(accountTemplate), request.accountTemplates)
        assertEquals("5411", request.merchantCategoryCode)
        assertEquals(BigDecimal("100.00"), request.amount)
        assertEquals("Test Store", request.recipientName)
        assertEquals("123456789", request.recipientIdentifier)
        assertEquals("404", request.currency)
        assertEquals("KE", request.countryCode)
    }
    
    @Test
    fun testQRCodeGenerationRequestWithNullValues() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "test.guid",
            participantId = "123456789",
            pspInfo = pspInfo
        )
        
        val request = QRCodeGenerationRequest(
            qrType = QRType.P2P,
            initiationMethod = QRInitiationMethod.STATIC,
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "0000",
            amount = null,
            recipientName = null,
            recipientIdentifier = "123456789",
            currency = "404",
            countryCode = "KE"
        )
        
        assertNull("Should have null amount", request.amount)
        assertNull("Should have null recipient name", request.recipientName)
    }
    
    @Test
    fun testParsedQRCode() {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test.bank",
            name = "Test Bank",
            country = Country.KENYA
        )
        
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "test.guid",
            participantId = "123456789",
            pspInfo = pspInfo
        )
        
        val tlvField = TLVField("00", 2, "01")
        
        val parsedQR = ParsedQRCode(
            fields = listOf(tlvField),
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "5411",
            amount = BigDecimal("100.00"),
            recipientName = "Test Store",
            recipientIdentifier = "123456789",
            currency = "404",
            countryCode = "KE",
            qrType = QRType.P2M
        )
        
        assertEquals(QRType.P2M, parsedQR.qrType)
        assertEquals(listOf(accountTemplate), parsedQR.accountTemplates)
        assertEquals("5411", parsedQR.merchantCategoryCode)
        assertEquals(BigDecimal("100.00"), parsedQR.amount)
        assertEquals("Test Store", parsedQR.recipientName)
        assertEquals("123456789", parsedQR.recipientIdentifier)
        assertEquals("404", parsedQR.currency)
        assertEquals("KE", parsedQR.countryCode)
        assertEquals(listOf(tlvField), parsedQR.fields)
    }
    
    @Test
    fun testQRCodeStyle() {
        val style = QRCodeStyle(
            size = 400,
            margin = 20,
            quietZone = 8,
            cornerRadius = 12,
            borderWidth = 2,
            borderColor = android.graphics.Color.RED
        )
        
        assertEquals("Should have correct size", 400, style.size)
        assertEquals("Should have correct margin", 20, style.margin)
        assertEquals("Should have correct quiet zone", 8, style.quietZone)
        assertEquals("Should have correct corner radius", 12, style.cornerRadius)
        assertEquals("Should have correct border width", 2, style.borderWidth)
        assertEquals("Should have correct border color", android.graphics.Color.RED, style.borderColor)
    }
    
    @Test
    fun testQRCodeStyleDefaults() {
        val style = QRCodeStyle()
        
        assertEquals("Should have default size", 512, style.size)
        assertEquals("Should have default margin", 20, style.margin)
        assertEquals("Should have default quiet zone", 8, style.quietZone)
        assertEquals("Should have default corner radius", 12, style.cornerRadius)
        assertEquals("Should have default border width", 2, style.borderWidth)
        assertEquals("Should have default border color", android.graphics.Color.BLACK, style.borderColor)
    }
    
    @Test
    fun testQRValidationResult() {
        val errors = listOf(
            ValidationError(field = "format", message = "Invalid format", errorCode = "E001"),
            ValidationError(field = "field", message = "Missing required field", errorCode = "E002")
        )
        val result = QRValidationResult(
            isValid = false,
            errors = errors
        )
        
        assertFalse("Should be invalid", result.isValid)
        assertEquals("Should have correct errors", errors, result.errors)
    }
    
    @Test
    fun testQRValidationResultValid() {
        val result = QRValidationResult(
            isValid = true,
            errors = emptyList()
        )
        
        assertTrue("Should be valid", result.isValid)
        assertTrue("Should have no errors", result.errors.isEmpty())
    }
} 