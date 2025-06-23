package com.qrcodesdk.models

import android.graphics.Bitmap
import java.math.BigDecimal

// MARK: - Core Data Structures

/**
 * TLV Field with support for nested templates
 */
data class TLVField(
    val tag: String,
    val length: Int,
    val value: String,
    val nestedFields: List<TLVField>? = null
) {
    /** Returns true if this is a template field containing nested TLV data */
    val isTemplate: Boolean get() = nestedFields != null
}

// MARK: - Enhanced QR Code Models

/**
 * Represents a parsed QR code with enhanced EMVCo compliance and multi-country support
 */
data class ParsedQRCode(
    val fields: List<TLVField> = emptyList(),
    val payloadFormat: String = "",
    val initiationMethod: QRInitiationMethod = QRInitiationMethod.STATIC,
    val accountTemplates: List<AccountTemplate> = emptyList(),
    val merchantCategoryCode: String = "6011",
    val amount: BigDecimal? = null,
    val recipientName: String? = null,
    val recipientIdentifier: String? = null,
    val purpose: String? = null,
    val currency: String = "404",
    val countryCode: String = "KE",
    val additionalData: AdditionalData? = null,
    val formatVersion: String? = null,
    val qrType: QRType = QRType.P2P
) {
    /** Legacy compatibility - maintains backward compatibility */
    val isStatic: Boolean get() = initiationMethod == QRInitiationMethod.STATIC
    
    /** Legacy compatibility - returns first PSP info */
    val pspInfo: PSPInfo? get() = accountTemplates.firstOrNull()?.pspInfo
}

// MARK: - QR Type Classification

enum class QRType(val displayName: String) {
    P2P("Person-to-Person"),
    P2M("Merchant Payment");
    
    companion object {
        fun fromMCC(mcc: String): QRType {
            // P2P MCCs (Financial institutions, funds transfer)
            return if (mcc in listOf("6011", "6012")) P2P else P2M
        }
    }
}

// MARK: - Initiation Method

enum class QRInitiationMethod(val value: String) {
    STATIC("11"),
    DYNAMIC("12");
    
    val isStatic: Boolean get() = this == STATIC
    val isDynamic: Boolean get() = this == DYNAMIC
    
    companion object {
        fun fromValue(value: String): QRInitiationMethod? {
            return values().find { it.value == value }
        }
    }
}

// MARK: - Account Templates (Tags 26-51)

/**
 * Account template for different payment schemes
 */
data class AccountTemplate(
    val tag: String,
    val guid: String,
    val participantId: String? = null,
    val accountId: String? = null,
    val pspInfo: PSPInfo
) {
    /** Template type based on tag */
    val templateType: TemplateType
        get() = when (tag) {
            "26" -> TemplateType.UNIFIED    // Tanzania TIPS
            "28" -> TemplateType.TELECOM    // Kenya Mobile Money
            "29" -> TemplateType.BANK       // Kenya Banks
            else -> TemplateType.OTHER
        }
    
    enum class TemplateType {
        UNIFIED,    // Single unified template (Tanzania)
        TELECOM,    // Telecom/Mobile money
        BANK,       // Bank accounts
        OTHER       // Other payment schemes
    }
}

// MARK: - Enhanced PSP Information

/**
 * Payment Service Provider information with enhanced features
 */
data class PSPInfo(
    val type: PSPType,
    val identifier: String,
    val name: String,
    val accountNumber: String? = null,
    val country: Country = Country.KENYA
) {
    enum class PSPType(val displayName: String) {
        BANK("Bank"),
        TELECOM("Mobile Money"),
        PAYMENT_GATEWAY("Payment Gateway"),
        UNIFIED("TIPS")        // For Tanzania TIPS
    }
    
    /** Check if this PSP supports multi-currency */
    val supportsMultiCurrency: Boolean
        get() = when (country to type) {
            Country.KENYA to PSPType.BANK -> true
            Country.TANZANIA to PSPType.BANK -> true
            else -> false  // Mobile money typically single currency
        }
    
    /** Get the appropriate template tag for this PSP */
    val templateTag: String
        get() = when (country to type) {
            Country.KENYA to PSPType.BANK -> "29"
            Country.KENYA to PSPType.TELECOM,
            Country.KENYA to PSPType.PAYMENT_GATEWAY -> "28"
            Country.TANZANIA to PSPType.BANK,
            Country.TANZANIA to PSPType.TELECOM,
            Country.TANZANIA to PSPType.UNIFIED -> "26"
            else -> "29"
        }
    
    companion object {
        /** Create a PSP info from GUID lookup */
        fun fromGUID(guid: String, country: Country): PSPInfo? {
            return PSPDirectory.getInstance().getPSP(guid, country)
        }
    }
}

// MARK: - Country Support

enum class Country(val code: String, val currencyCode: String, val currencyName: String, val displayName: String) {
    KENYA("KE", "404", "KES", "Kenya"),
    TANZANIA("TZ", "834", "TZS", "Tanzania");
    
    companion object {
        fun fromCode(code: String): Country? {
            return values().find { it.code == code }
        }
    }
}

// MARK: - Additional Data (Tag 62) - Enhanced with Phase 2 & 3 Support

/**
 * Enhanced additional data structure for Tag 62 with comprehensive field support
 */
data class AdditionalData(
    // Standard EMVCo fields (01-09)
    val billNumber: String? = null,
    val mobileNumber: String? = null,
    val storeLabel: String? = null,
    val loyaltyNumber: String? = null,
    val referenceLabel: String? = null,
    val customerLabel: String? = null,
    val terminalLabel: String? = null,
    val purposeOfTransaction: String? = null,
    val additionalConsumerDataRequest: String? = null,
    
    // Phase 2: Merchant-specific fields
    val merchantCategory: String? = null,        // Merchant category type
    val merchantSubCategory: String? = null,     // Detailed merchant description
    val tipIndicator: String? = null,            // Tip handling indicator
    val tipAmount: String? = null,               // Fixed tip amount
    val convenienceFeeIndicator: String? = null, // Convenience fee indicator
    val convenienceFee: String? = null,          // Fixed convenience fee
    val multiScheme: String? = null,             // Multi-scheme support indicator
    val supportedCountries: String? = null,      // Comma-separated country codes
    
    // Healthcare-specific fields
    val patientId: String? = null,
    val appointmentReference: String? = null,
    val medicalRecordNumber: String? = null,
    val doctorId: String? = null,
    val treatmentCode: String? = null,
    
    // Transportation fields
    val route: String? = null,
    val ticketType: String? = null,
    val departureTime: String? = null,
    val vehicleId: String? = null,
    val arrivalTime: String? = null,
    val seatNumber: String? = null,
    
    // Government/Utility fields
    val referenceNumber: String? = null,
    val serviceType: String? = null,
    val accountNumber: String? = null,
    val billingPeriod: String? = null,
    val meterNumber: String? = null,
    val taxYear: String? = null,
    val licenseNumber: String? = null,
    
    // Phase 3: Tanzania TANQR fields
    val tipsAcquirerId: String? = null,
    val tipsVersion: String? = null,
    val tipsTransactionId: String? = null,
    val tipsTerminalId: String? = null,
    val countrySpecific: String? = null,
    
    // Cross-border and multi-currency
    val exchangeRate: String? = null,
    val originalCurrency: String? = null,
    val originalAmount: String? = null,
    val fxProvider: String? = null,
    
    // Digital receipt and analytics
    val receiptUrl: String? = null,
    val receiptFormat: String? = null,
    val analyticsId: String? = null,
    val sessionId: String? = null,
    
    // Legacy custom fields support
    val customFields: Map<String, String> = emptyMap()
)

// MARK: - Enhanced QR Generation Models

/**
 * Enhanced QR code generation request with multi-country support
 */
data class QRCodeGenerationRequest(
    val qrType: QRType,
    val initiationMethod: QRInitiationMethod,
    val accountTemplates: List<AccountTemplate>,
    val merchantCategoryCode: String,
    val amount: BigDecimal? = null,
    val recipientName: String? = null,
    val recipientIdentifier: String? = null,
    val recipientCity: String? = null,
    val postalCode: String? = null,
    val currency: String = "404",
    val countryCode: String = "KE",
    val additionalData: AdditionalData? = null,
    val formatVersion: String? = null
) {
    // Legacy compatibility constructor
    constructor(
        recipientName: String? = null,
        recipientIdentifier: String,
        pspInfo: PSPInfo,
        amount: BigDecimal? = null,
        purpose: String? = null,
        currency: String = "KES",
        countryCode: String = "KE",
        isStatic: Boolean = true
    ) : this(
        qrType = QRType.P2P,
        initiationMethod = if (isStatic) QRInitiationMethod.STATIC else QRInitiationMethod.DYNAMIC,
        accountTemplates = listOf(
            AccountTemplate(
                tag = if (pspInfo.type == PSPInfo.PSPType.BANK) "29" else "28",
                guid = pspInfo.identifier,
                accountId = recipientIdentifier,
                pspInfo = pspInfo
            )
        ),
        merchantCategoryCode = "6011",
        amount = amount,
        recipientName = recipientName,
        recipientIdentifier = recipientIdentifier,
        currency = Country.fromCode(countryCode)?.currencyCode ?: "404",
        countryCode = countryCode,
        additionalData = if (purpose != null) AdditionalData(purposeOfTransaction = purpose) else null
    )
    
    /**
     * Converts the request to EMVCo-compliant TLV string (matches iOS implementation)
     */
    fun toEMVCoString(): String {
        val tlvComponents = mutableListOf<String>()
        
        // Tag 00: Payload Format Indicator (always "01")
        tlvComponents.add(formatTLV("00", "01"))
        
        // Tag 01: Point of Initiation Method
        tlvComponents.add(formatTLV("01", initiationMethod.value))
        
        // Tags 26-51: Account Templates (ordered by tag number like iOS)
        val sortedTemplates = accountTemplates.sortedBy { it.tag }
        for (template in sortedTemplates) {
            val templateTLV = buildAccountTemplateTLV(template)
            tlvComponents.add(templateTLV)
        }
        
        // Tag 52: Merchant Category Code
        tlvComponents.add(formatTLV("52", merchantCategoryCode))
        
        // Tag 53: Transaction Currency
        tlvComponents.add(formatTLV("53", currency))
        
        // Tag 54: Transaction Amount (only for dynamic QR like iOS)
        if (initiationMethod == QRInitiationMethod.DYNAMIC) {
            amount?.let { amt ->
                val amountStr = formatAmount(amt)
                tlvComponents.add(formatTLV("54", amountStr))
            }
        }
        
        // Tag 58: Country Code
        tlvComponents.add(formatTLV("58", countryCode))
        
        // Tag 59: Merchant/Recipient Name (optional but recommended)
        recipientName?.let { name ->
            val sanitizedName = sanitizeName(name, 25)
            tlvComponents.add(formatTLV("59", sanitizedName))
        }
        
        // Tag 60: Merchant City/Recipient Identifier
        recipientCity?.let { city ->
            val sanitizedCity = sanitizeName(city, 15)
            tlvComponents.add(formatTLV("60", sanitizedCity))
        }
        
        // Tag 61: Postal Code (optional)
        postalCode?.let { postal ->
            tlvComponents.add(formatTLV("61", postal))
        }
        
        // Tag 62: Additional Data (optional)
        additionalData?.let { additional ->
            val additionalDataTLV = buildAdditionalDataTLV(additional)
            if (additionalDataTLV.isNotEmpty()) {
                tlvComponents.add(formatTLV("62", additionalDataTLV))
            }
        }
        
        // Tag 64: Format Version (EMVCo compliance - BEFORE Tag 63)
        formatVersion?.let { version ->
            tlvComponents.add(formatTLV("64", version))
        }
        
        // Join all components
        val dataWithoutCRC = tlvComponents.joinToString("")
        
        // Tag 63: CRC16 Checksum (MUST be last for EMVCo compliance)
        // Calculate CRC for data + CRC tag ID and length according to CBK standard
        val dataForCRC = dataWithoutCRC + "6304"
        val crc16 = calculateCRC16(dataForCRC)
        val finalTLVString = dataWithoutCRC + formatTLV("63", crc16)
        
        return finalTLVString
    }
    
    /**
     * Format TLV field (Tag-Length-Value)
     */
    private fun formatTLV(tag: String, value: String): String {
        return tag + String.format("%02d", value.length) + value
    }
    
    /**
     * Build account template TLV for different countries
     */
    private fun buildAccountTemplateTLV(template: AccountTemplate): String {
        val accountData = StringBuilder()
        
        // Sub-tag 00: GUID
        accountData.append(formatTLV("00", template.guid))
        
        // Sub-tag 07: Participant ID (if present)
        template.participantId?.let { participantId ->
            accountData.append(formatTLV("07", participantId))
        }
        
        return formatTLV(template.tag, accountData.toString())
    }
    
    /**
     * Build additional data TLV structure
     */
    private fun buildAdditionalDataTLV(additionalData: AdditionalData): String {
        val nestedComponents = mutableListOf<String>()
        
        // Standard sub-tags (01-09)
        additionalData.billNumber?.let { nestedComponents.add(formatTLV("01", it)) }
        additionalData.mobileNumber?.let { nestedComponents.add(formatTLV("02", it)) }
        additionalData.storeLabel?.let { nestedComponents.add(formatTLV("03", it)) }
        additionalData.loyaltyNumber?.let { nestedComponents.add(formatTLV("04", it)) }
        additionalData.referenceLabel?.let { nestedComponents.add(formatTLV("05", it)) }
        additionalData.customerLabel?.let { nestedComponents.add(formatTLV("06", it)) }
        additionalData.terminalLabel?.let { nestedComponents.add(formatTLV("07", it)) }
        additionalData.purposeOfTransaction?.let { nestedComponents.add(formatTLV("08", it)) }
        additionalData.additionalConsumerDataRequest?.let { nestedComponents.add(formatTLV("09", it)) }
        
        // Custom fields (50-99) - sorted by tag
        val sortedCustomFields = additionalData.customFields.toSortedMap()
        for ((tag, value) in sortedCustomFields) {
            nestedComponents.add(formatTLV(tag, value))
        }
        
        return nestedComponents.joinToString("")
    }
    
    /**
     * Format amount like iOS implementation
     */
    private fun formatAmount(amount: BigDecimal): String {
        return amount.setScale(2, java.math.RoundingMode.HALF_UP).toPlainString()
    }
    
    /**
     * Sanitize name fields like iOS implementation
     */
    private fun sanitizeName(name: String, maxLength: Int): String {
        return name.take(maxLength).trim()
    }
    
    /**
     * Calculate CRC16-CCITT for EMVCo compliance
     */
    private fun calculateCRC16(data: String): String {
        var crc = 0xFFFF
        val polynomial = 0x1021
        
        for (byte in data.toByteArray()) {
            crc = crc xor (byte.toInt() and 0xFF shl 8)
            for (i in 0 until 8) {
                if (crc and 0x8000 != 0) {
                    crc = (crc shl 1) xor polynomial
                } else {
                    crc = crc shl 1
                }
                crc = crc and 0xFFFF
            }
        }
        
        return String.format("%04X", crc)
    }
}

// MARK: - QR Code Styling

/**
 * QR code visual styling options to match iOS capabilities
 */
data class QRCodeStyle(
    val size: Int = 512,
    val margin: Int = 20,
    val quietZone: Int = 8,
    val cornerRadius: Int = 12,
    val borderWidth: Int = 2,
    val borderColor: Int = 0xFF000000.toInt(),  // Black
    val foregroundColor: Int = 0xFF000000.toInt(),  // Black
    val backgroundColor: Int = 0xFFFFFFFF.toInt(),   // White
    val finderPatternColor: Int? = null,  // For custom corner coloring like Equity Bank
    val logoBackgroundColor: Int? = null
) {
    companion object {
        /** Equity Bank red branding style */
        val equityBank = QRCodeStyle(
            finderPatternColor = 0xFFCC0000.toInt(),  // Equity Red
            borderColor = 0xFFCC0000.toInt()
        )
        
        /** KCB blue branding style */
        val kcbBank = QRCodeStyle(
            borderColor = 0xFF007AFF.toInt()  // KCB Blue
        )
        
        /** Co-op green branding style */
        val coopBank = QRCodeStyle(
            borderColor = 0xFF34C759.toInt()  // Co-op Green
        )
    }
}

// MARK: - Validation and Error Models

/**
 * QR code validation result
 */
data class QRValidationResult(
    val isValid: Boolean,
    val errors: List<ValidationError> = emptyList(),
    val warnings: List<ValidationWarning> = emptyList()
)

/**
 * Validation error
 */
data class ValidationError(
    val field: String,
    val message: String,
    val errorCode: String
)

/**
 * Validation warning
 */
data class ValidationWarning(
    val field: String,
    val message: String,
    val warningCode: String
)

// MARK: - Exception Classes (Required by Parser)

/**
 * Exceptions that can occur during TLV parsing
 */
sealed class TLVParsingException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    
    object InvalidDataLength : TLVParsingException("QR data length is invalid or insufficient")
    object InvalidTag : TLVParsingException("Invalid TLV tag format")
    object InvalidLength : TLVParsingException("Invalid TLV length value")
    object InvalidValue : TLVParsingException("Invalid TLV value content")
    object CorruptedData : TLVParsingException("QR data appears to be corrupted")
    object MalformedData : TLVParsingException("QR data is malformed")
    data class MissingRequiredField(val field: String) : TLVParsingException("Required field missing: $field")
    object InvalidChecksum : TLVParsingException("CRC16 checksum validation failed")
    object UnknownPSP : TLVParsingException("PSP identifier not found in directory")
    object ExpiredQR : TLVParsingException("QR code has expired")
    object InvalidPSPFormat : TLVParsingException("PSP data format is invalid")
    object InvalidNestedTLV : TLVParsingException("Nested TLV structure is malformed")
    object UnsupportedQRVersion : TLVParsingException("QR code version is not supported")
    
    /**
     * Get user-friendly error message
     */
    val userMessage: String
        get() = when (this) {
            InvalidChecksum -> "Invalid QR Code – corrupted or altered."
            UnknownPSP -> "PSP not supported."
            ExpiredQR -> "QR expired. Please request a new one."
            is MissingRequiredField -> "Incomplete QR – check code and try again."
            InvalidDataLength, InvalidTag, InvalidLength, InvalidValue,
            CorruptedData, InvalidPSPFormat, InvalidNestedTLV, MalformedData -> "Malformed QR – invalid data structure."
            UnsupportedQRVersion -> "QR version not supported."
        }
    
    /**
     * Get technical description for debugging
     */
    val technicalDescription: String = message ?: ""
    
    /**
     * Get error category for handling
     */
    val category: ErrorCategory
        get() = when (this) {
            InvalidChecksum, CorruptedData -> ErrorCategory.DATA_INTEGRITY
            UnknownPSP -> ErrorCategory.UNSUPPORTED_PROVIDER
            ExpiredQR -> ErrorCategory.EXPIRED
            is MissingRequiredField, InvalidDataLength, InvalidTag,
            InvalidLength, InvalidValue, InvalidPSPFormat, InvalidNestedTLV, MalformedData -> ErrorCategory.MALFORMED_DATA
            UnsupportedQRVersion -> ErrorCategory.UNSUPPORTED_VERSION
        }
    
    enum class ErrorCategory {
        DATA_INTEGRITY,
        UNSUPPORTED_PROVIDER,
        EXPIRED,
        MALFORMED_DATA,
        UNSUPPORTED_VERSION
    }
    
    /**
     * Get recovery suggestion for user
     */
    val recoverySuggestion: String
        get() = when (this) {
            InvalidChecksum, CorruptedData -> "Ask the sender to generate a new QR code"
            UnknownPSP -> "This payment provider is not supported. Check with your service provider"
            ExpiredQR -> "Request a new QR code from the recipient"
            is MissingRequiredField, InvalidDataLength, InvalidTag,
            InvalidLength, InvalidValue, InvalidPSPFormat, InvalidNestedTLV, MalformedData -> 
                "The QR code format is invalid. Ask for a new QR code"
            UnsupportedQRVersion -> "Update your app to support this QR code version"
        }
}

/**
 * Exceptions that can occur during QR generation
 */
sealed class QRGenerationException(message: String, cause: Throwable? = null) : Exception(message, cause) {
    
    object InvalidInputData : QRGenerationException("Invalid input data for QR generation")
    object InvalidPSPConfiguration : QRGenerationException("PSP configuration is invalid")
    object QRGenerationFailed : QRGenerationException("Failed to generate QR code")
    object ImageRenderingFailed : QRGenerationException("Failed to render QR code image")
    object LogoProcessingFailed : QRGenerationException("Failed to process logo image")
    object UnsupportedCurrency : QRGenerationException("Currency not supported")
    
    val userMessage: String
        get() = when (this) {
            InvalidInputData -> "Invalid input data for QR generation"
            InvalidPSPConfiguration -> "PSP configuration is invalid"
            QRGenerationFailed -> "Failed to generate QR code"
            ImageRenderingFailed -> "Failed to render QR code image"
            LogoProcessingFailed -> "Failed to process logo image"
            UnsupportedCurrency -> "Currency not supported"
        }
}

// MARK: - Constants

object QRCodeConstants {
    // Standard values
    const val PAYLOAD_FORMAT = "01"
    const val PAYLOAD_FORMAT_INDICATOR = "01"  // Legacy compatibility
    const val STATIC_QR_INITIATION = "11"
    const val DYNAMIC_QR_INITIATION = "12"
    const val MERCHANT_CATEGORY_CODE = "6011"
    const val CURRENCY_CODE_KES = "404"
    const val CURRENCY_CODE_TZS = "834"
    const val COUNTRY_CODE_KENYA = "KE"
    const val COUNTRY_CODE_TANZANIA = "TZ"
    
    // Required tags per Kenya P2P QR specification
    val REQUIRED_TAGS = listOf("00", "01", "52", "53", "58", "60", "63")
    
    // PSP tags (either Tag 28 or Tag 29 is required)
    val PSP_TAGS = listOf("28", "29")
    
    // Tag length constraints
    val TAG_MAX_LENGTHS = mapOf(
        "00" to 2,   // Payload Format Indicator
        "01" to 2,   // Initiation Method
        "28" to 99,  // Telecom PSP Data
        "29" to 99,  // Bank PSP Data
        "52" to 4,   // MCC
        "53" to 3,   // Currency Code
        "54" to 12,  // Amount
        "58" to 2,   // Country Code
        "59" to 25,  // Recipient Name
        "60" to 15,  // Recipient Identifier
        "62" to 99,  // Additional Data
        "63" to 4,   // CRC16 Checksum
        "64" to 12   // Format Version
    )
    
    // Merchant Category Codes
    const val MCC_FINANCIAL_P2P = "6011"
    const val MCC_FINANCIAL_P2M = "6012"
    const val MCC_GROCERY = "5411"
    const val MCC_RESTAURANT = "5812"
    const val MCC_TELECOMMUNICATIONS = "4814"
    
    // Kenya PSP GUIDs
    const val EQUITY_BANK_GUID = "ke.go.qr"
    const val KCB_BANK_GUID = "01"
    const val COOP_BANK_GUID = "11"
    
    // Tanzania PSP GUIDs
    const val TANZANIA_TIPS_GUID = "tz.go.bot.tips"
    
    // CRC16 calculation constants
    const val CRC16_POLYNOMIAL: UShort = 0x1021u
    const val CRC16_INITIAL_VALUE: UShort = 0xFFFFu
    
    // Standard version
    const val SUPPORTED_STANDARD_VERSION = "P2P-KE-01"
    const val SDK_VERSION = "2.0.0"
} 