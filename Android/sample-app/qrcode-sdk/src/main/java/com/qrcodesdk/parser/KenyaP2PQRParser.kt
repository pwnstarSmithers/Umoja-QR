package com.qrcodesdk.parser

import com.qrcodesdk.models.*
import java.math.BigDecimal
import android.util.Log

/**
 * Parser for Kenya P2P QR codes according to the official specification
 */
class KenyaP2PQRParser {
    
    private fun safeLog(tag: String, message: String) {
        try {
            android.util.Log.d(tag, message)
        } catch (e: Exception) {
            // Log not available in tests
            println("$tag: $message")
        }
    }
    
    private fun safeLogError(tag: String, message: String) {
        try {
            Log.e(tag, message)
        } catch (e: Exception) {
            // Log not available in tests
            println("ERROR $tag: $message")
        }
    }
    
    private fun safeLogWarning(tag: String, message: String) {
        try {
            android.util.Log.w(tag, message)
        } catch (e: Exception) {
            // Log not available in tests
            println("WARN $tag: $message")
        }
    }
    
    companion object {
        
        // Complete Bank PSP Directory from specification
        private val BANK_PSPS = mapOf(
            "01" to "KCB Bank Kenya Limited",
            "02" to "Standard Chartered Bank Kenya Ltd",
            "03" to "ABSA Bank Kenya PLC",
            "05" to "Bank of India",
            "06" to "Bank of Baroda (Kenya) Ltd",
            "07" to "NCBA Kenya PLC",
            "10" to "Prime Bank Ltd",
            "11" to "Co-operative Bank of Kenya Ltd",
            "12" to "National Bank of Kenya Ltd",
            "14" to "M-Oriental Bank Limited",
            "16" to "Citibank N.A. Kenya",
            "17" to "Habib Bank AG Zurich",
            "18" to "Middle East Bank Kenya Ltd",
            "19" to "Bank of Africa Kenya Ltd",
            "23" to "Consolidated Bank of Kenya Ltd",
            "25" to "Credit Bank Ltd",
            "26" to "Access Bank (Kenya) Ltd",
            "30" to "Chase Bank (K) Ltd",
            "31" to "Stanbic Bank Kenya Ltd",
            "35" to "African Banking Corporation Ltd",
            "39" to "Imperial Bank Ltd",
            "43" to "Ecobank Kenya Ltd",
            "49" to "Spire Bank Ltd",
            "50" to "Paramount Bank Ltd",
            "51" to "Kingdom Bank Ltd",
            "53" to "Guaranty Trust Bank (Kenya) Ltd",
            "54" to "Victoria Commercial Bank Ltd",
            "55" to "Guardian Bank Ltd",
            "57" to "I&M Bank Ltd",
            "59" to "Development Bank of Kenya Ltd",
            "60" to "SBM Bank (Kenya) Ltd",
            "63" to "Diamond Trust Bank (K) Ltd",
            "64" to "Charterhouse Bank Ltd",
            "65" to "Mayfair CIB Bank Ltd",
            "66" to "Sidian Bank Ltd",
            "68" to "Equity Bank Kenya Ltd",
            "70" to "Family Bank Ltd",
            "72" to "Gulf African Bank Ltd",
            "74" to "First Community Bank Ltd",
            "75" to "DIB Bank Kenya Ltd",
            "76" to "UBA Kenya Bank Ltd",
            "83" to "HFC Limited"
        )
        
        // Telecom PSP Directory
        private val TELECOM_PSPS = mapOf(
            "01" to "Safaricom (M-PESA)",
            "02" to "Airtel Money",
            "12" to "PesaPal"
        )
    }
    
    /**
     * Parse a Kenya P2P QR code string
     * @param data The QR code data string
     * @return Parsed QR code information
     * @throws TLVParsingException for various parsing failures
     */
    @Throws(TLVParsingException::class)
    fun parseKenyaP2PQR(data: String): ParsedQRCode {
        safeLog("KenyaP2PQRParser", "Parsing QR: $data")
        try {
            val fields = parseTLV(data)
            safeLog("KenyaP2PQRParser", "Parsed TLV fields: $fields")
            
            // Validate required fields are present
            validateRequiredFields(fields)
            
            // Validate CRC16 checksum
            validateChecksum(data, fields)
            
            // Extract other relevant information
            val countryCode = fields.find { it.tag == "58" }?.value ?: "KE"
            val country = Country.fromCode(countryCode) ?: Country.KENYA
            // Extract account templates (Tags 26–51) with deep nested TLV, multi-country
            val accountTemplates = fields.filter { it.tag.toIntOrNull() in 26..51 }
                .mapNotNull { field ->
                    try {
                        // Try nested TLV (CBK/EMVCo) first
                        val nestedFields = parseTLV(field.value)
                        
                        // Standard CBK format: sub-tag 00 = GUID, sub-tag 07 = participant ID
                        val guid = nestedFields.find { it.tag == "00" }?.value
                        val participantId = nestedFields.find { it.tag == "07" }?.value
                        val accountId = nestedFields.find { it.tag == "01" }?.value
                        
                        if (guid != null) {
                            val pspInfo = PSPDirectory.getInstance().getPSP(guid, country)
                            if (pspInfo != null) {
                                return@mapNotNull AccountTemplate(
                                    tag = field.tag,
                                    guid = guid,
                                    participantId = participantId,
                                    accountId = accountId,
                                    pspInfo = pspInfo
                                )
                            }
                        }
                        null
                    } catch (e: Exception) {
                        // Fall back to legacy flat format parsing
                        try {
                            safeLogWarning("KenyaP2PQRParser", "Nested TLV parsing failed for tag ${field.tag}, trying legacy format")
                            
                            // Legacy CBK format: "0008ke.go.qr" + participant_id (remaining chars)
                            if (field.value.startsWith("0008ke.go.qr")) {
                                val guid = "ke.go.qr"
                                val participantId = field.value.substring(12) // After "0008ke.go.qr"
                                val pspInfo = PSPDirectory.getInstance().getPSP(guid, country)
                                if (pspInfo != null) {
                                    safeLogWarning("KenyaP2PQRParser", "Using legacy CBK format for tag ${field.tag}: guid=$guid, participantId=$participantId")
                                    return@mapNotNull AccountTemplate(
                                        tag = field.tag,
                                        guid = guid,
                                        participantId = participantId,
                                        accountId = null,
                                        pspInfo = pspInfo
                                    )
                                }
                            }
                            
                            // Generic legacy format fallback
                            if (field.value.length >= 12) {
                                val guidEnd = field.value.indexOf("ke.go.qr") + 8
                                if (guidEnd > 8) {
                                    val guid = field.value.substring(4, guidEnd) // Skip length prefix "0008"
                                    val participantId = field.value.substring(guidEnd)
                                    val pspInfo = PSPDirectory.getInstance().getPSP(guid, country)
                                    if (pspInfo != null) {
                                        safeLogWarning("KenyaP2PQRParser", "Using generic legacy format for tag ${field.tag}: guid=$guid, participantId=$participantId")
                                        return@mapNotNull AccountTemplate(
                                            tag = field.tag,
                                            guid = guid,
                                            participantId = participantId,
                                            accountId = null,
                                            pspInfo = pspInfo
                                        )
                                    }
                                }
                            }
                            null
                        } catch (ex: Exception) {
                            safeLogError("KenyaP2PQRParser", "All parsing attempts failed for tag ${field.tag}: ${ex.message}")
                            null
                        }
                    }
                }
            
            // Extract other relevant information
            val initiationMethod = fields.find { it.tag == "01" }?.value?.let { QRInitiationMethod.fromValue(it) } ?: QRInitiationMethod.STATIC
            val merchantCategoryCode = fields.find { it.tag == "52" }?.value ?: "6011"
            val amount = parseAmount(fields)
            val recipientName = fields.find { it.tag == "59" }?.value
            val recipientIdentifier = fields.find { it.tag == "60" }?.value
            val currency = fields.find { it.tag == "53" }?.value ?: "KES"
            // Enhanced: Parse all additional data fields (tag 62) including merchant/healthcare/transport
            val additionalData = fields.find { it.tag == "62" }?.let { field ->
                try {
                    val nestedFields = parseTLV(field.value)
                    AdditionalData(
                        billNumber = nestedFields.find { it.tag == "01" }?.value,
                        mobileNumber = nestedFields.find { it.tag == "02" }?.value,
                        storeLabel = nestedFields.find { it.tag == "03" }?.value,
                        loyaltyNumber = nestedFields.find { it.tag == "04" }?.value,
                        referenceLabel = nestedFields.find { it.tag == "05" }?.value,
                        customerLabel = nestedFields.find { it.tag == "06" }?.value,
                        terminalLabel = nestedFields.find { it.tag == "07" }?.value,
                        purposeOfTransaction = nestedFields.find { it.tag == "08" }?.value,
                        additionalConsumerDataRequest = nestedFields.find { it.tag == "09" }?.value,
                        merchantCategory = nestedFields.find { it.tag == "20" }?.value,
                        merchantSubCategory = nestedFields.find { it.tag == "21" }?.value,
                        tipIndicator = nestedFields.find { it.tag == "22" }?.value,
                        tipAmount = nestedFields.find { it.tag == "23" }?.value,
                        convenienceFeeIndicator = nestedFields.find { it.tag == "24" }?.value,
                        convenienceFee = nestedFields.find { it.tag == "25" }?.value,
                        multiScheme = nestedFields.find { it.tag == "26" }?.value,
                        supportedCountries = nestedFields.find { it.tag == "27" }?.value,
                        patientId = nestedFields.find { it.tag == "30" }?.value,
                        appointmentReference = nestedFields.find { it.tag == "31" }?.value,
                        referenceNumber = nestedFields.find { it.tag == "32" }?.value,
                        serviceType = nestedFields.find { it.tag == "33" }?.value,
                        route = nestedFields.find { it.tag == "34" }?.value,
                        ticketType = nestedFields.find { it.tag == "35" }?.value,
                        accountNumber = nestedFields.find { it.tag == "36" }?.value,
                        billingPeriod = nestedFields.find { it.tag == "37" }?.value,
                        customFields = nestedFields.filter { it.tag.toIntOrNull() in 50..99 }.associate { it.tag to it.value }
                    )
                } catch (e: Exception) {
                    safeLogWarning("KenyaP2PQRParser", "Failed to parse additional data (tag 62) as nested TLV: ${e.message}")
                    // Return minimal additional data with raw value as bill number fallback
                    AdditionalData(billNumber = field.value)
                }
            }
            val formatVersion = fields.find { it.tag == "64" }?.value
            val qrType = QRType.fromMCC(merchantCategoryCode)
            
            return ParsedQRCode(
                fields = fields,
                payloadFormat = fields.find { it.tag == "00" }?.value ?: "",
                initiationMethod = initiationMethod,
                accountTemplates = accountTemplates,
                merchantCategoryCode = merchantCategoryCode,
                amount = amount,
                recipientName = recipientName,
                recipientIdentifier = recipientIdentifier,
                currency = currency,
                countryCode = countryCode,
                additionalData = additionalData,
                formatVersion = formatVersion,
                qrType = qrType
            )
        } catch (e: Exception) {
            safeLogError("KenyaP2PQRParser", "Parse error: ${e::class.simpleName}: ${e.message}")
            throw TLVParsingException.InvalidValue
        }
    }
    
    /**
     * Parse TLV structure from QR data
     */
    @Throws(TLVParsingException::class)
    private fun parseTLV(data: String): List<TLVField> {
        safeLog("KenyaP2PQRParser", "Parsing TLV: $data")
        if (data.isEmpty()) {
            safeLogError("KenyaP2PQRParser", "Empty QR data")
            throw TLVParsingException.InvalidDataLength
        }
        
        val result = mutableListOf<TLVField>()
        var cursor = 0
        
        while (cursor < data.length) {
            // Parse tag (2 characters)
            if (data.length - cursor < 2) {
                Log.e("KenyaP2PQRParser", "Corrupted data at tag parse")
                throw TLVParsingException.CorruptedData
            }
            
            val tag = data.substring(cursor, cursor + 2)
            cursor += 2
            
            // Validate tag format (should be numeric)
            if (!tag.all { it.isDigit() }) {
                Log.e("KenyaP2PQRParser", "Invalid tag: $tag")
                throw TLVParsingException.InvalidTag
            }
            
            // Parse length (2 characters)
            if (data.length - cursor < 2) {
                Log.e("KenyaP2PQRParser", "Corrupted data at length parse")
                throw TLVParsingException.CorruptedData
            }
            
            val lengthStr = data.substring(cursor, cursor + 2)
            cursor += 2
            
            val length = lengthStr.toIntOrNull()
                ?: run {
                    Log.e("KenyaP2PQRParser", "Invalid length: $lengthStr")
                    throw TLVParsingException.InvalidLength
                }
            
            if (length < 0) {
                Log.e("KenyaP2PQRParser", "Negative length: $length")
                throw TLVParsingException.InvalidLength
            }
            
            // Validate length constraints from specification
            validateTagLength(tag, length)
            
            // Check if we have enough data for the value
            if (data.length - cursor < length) {
                Log.e("KenyaP2PQRParser", "Corrupted data at value parse")
                throw TLVParsingException.CorruptedData
            }
            
            // Parse value
            val value = data.substring(cursor, cursor + length)
            cursor += length
            
            // Validate specific field constraints from specification
            try {
                validateField(tag, value)
            } catch (e: TLVParsingException) {
                Log.e("KenyaP2PQRParser", "Validation failed for tag $tag, value '$value': ${e.message}")
                throw e
            }
            
            safeLog("KenyaP2PQRParser", "Parsed field: tag=$tag, length=$length, value='$value'")
            result.add(TLVField(tag, length, value))
        }
        
        return result
    }
    
    /**
     * Validate tag length constraints
     */
    @Throws(TLVParsingException::class)
    private fun validateTagLength(tag: String, length: Int) {
        val maxLength = QRCodeConstants.TAG_MAX_LENGTHS[tag]
        if (maxLength != null && length > maxLength.toInt()) {
            throw TLVParsingException.InvalidLength
        }
    }
    
    /**
     * Validate field content according to specification
     */
    @Throws(TLVParsingException::class)
    private fun validateField(tag: String, value: String) {
        when (tag) {
            "00" -> { // Payload Format Indicator
                if (value != QRCodeConstants.PAYLOAD_FORMAT_INDICATOR) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "01" -> { // Point of Initiation
                if (value != QRCodeConstants.STATIC_QR_INITIATION && 
                    value != QRCodeConstants.DYNAMIC_QR_INITIATION) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "52" -> { // Merchant Category Code
                // Validate MCC is 4 digits (more flexible than requiring exact value)
                if (value.length != 4 || !value.all { it.isDigit() }) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "53" -> { // Currency Code
                // Validate currency code is 3 digits (more flexible)
                if (value.length != 3 || !value.all { it.isDigit() }) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "54" -> { // Transaction Amount (optional, dynamic QR only)
                if (value.isNotEmpty()) {
                    try {
                        val amount = BigDecimal(value)
                        if (amount <= BigDecimal.ZERO) {
                            throw TLVParsingException.InvalidValue
                        }
                    } catch (e: NumberFormatException) {
                        throw TLVParsingException.InvalidValue
                    }
                }
            }
            "58" -> { // Country Code
                if (value != QRCodeConstants.COUNTRY_CODE_KENYA) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "59" -> { // Recipient Name (optional but recommended)
                // UTF-8 validation and length already handled in validateTagLength
            }
            "60" -> { // Recipient Identifier
                if (value.isEmpty()) {
                    throw TLVParsingException.InvalidValue
                }
            }
            "63" -> { // CRC16 Checksum
                if (value.length != 4 || !value.all { it.isDigit() || it.toUpperCase() in 'A'..'F' }) {
                    throw TLVParsingException.InvalidChecksum
                }
            }
            "64" -> { // Format Version
                if (value.isNotEmpty() && !value.matches(Regex("^(P2P|P2M)-KE-\\d+"))) {
                    throw TLVParsingException.UnsupportedQRVersion
                }
            }
        }
    }
    
    /**
     * Validate that all required fields are present
     */
    @Throws(TLVParsingException::class)
    private fun validateRequiredFields(fields: List<TLVField>) {
        val presentTags = fields.map { it.tag }.toSet()
        
        // Check required tags
        for (requiredTag in QRCodeConstants.REQUIRED_TAGS) {
            if (!presentTags.contains(requiredTag)) {
                throw TLVParsingException.MissingRequiredField(requiredTag)
            }
        }
        
        // Check that at least one PSP tag is present
        val hasPSPTag = QRCodeConstants.PSP_TAGS.any { presentTags.contains(it) }
        if (!hasPSPTag) {
            throw TLVParsingException.MissingRequiredField("28 or 29")
        }
    }
    
    /**
     * Validate CRC16 checksum
     */
    @Throws(TLVParsingException::class)
    private fun validateChecksum(data: String, fields: List<TLVField>) {
        val crcField = fields.find { it.tag == "63" }
            ?: throw TLVParsingException.MissingRequiredField("63")
        
        // Calculate CRC16 according to CBK standard section 7.11 (same as iOS implementation)
        // Data includes all data objects with ID, Length, and Value
        // PLUS the CRC tag's ID and Length (but NOT its Value)
        val crcIdAndLength = "6304" // Tag 63 + Length 04
        val crcValue = crcField.value
        
        // Find the position of the CRC tag in the data
        val crcTagString = "63%02d%s".format(crcField.length, crcValue)
        val crcIndex = data.indexOf(crcTagString)
        if (crcIndex == -1) {
            throw TLVParsingException.InvalidChecksum
        }
        
        // Build data for CRC calculation: everything up to CRC + CRC ID and Length
        val dataBeforeCRC = data.substring(0, crcIndex)
        val dataForCRC = dataBeforeCRC + crcIdAndLength
        val calculatedCRC = calculateCRC16(dataForCRC)
        
        safeLog("KenyaP2PQRParser", "CRC Validation:")
        safeLog("KenyaP2PQRParser", "  Original data: $data")
        safeLog("KenyaP2PQRParser", "  CRC tag string: $crcTagString")
        safeLog("KenyaP2PQRParser", "  Data before CRC: $dataBeforeCRC")
        safeLog("KenyaP2PQRParser", "  Data for CRC calc: $dataForCRC")
        safeLog("KenyaP2PQRParser", "  Calculated CRC: $calculatedCRC")
        safeLog("KenyaP2PQRParser", "  Expected CRC: ${crcField.value}")
        
        if (calculatedCRC.uppercase() != crcField.value.uppercase()) {
            safeLogError("KenyaP2PQRParser", "CRC mismatch: calculated=$calculatedCRC, expected=${crcField.value}")
            throw TLVParsingException.InvalidChecksum
        }
    }
    
    /**
     * Calculate CRC16 checksum - exact match to iOS implementation
     * CRC-CCITT (False) implementation as per specification
     * Polynomial: 0x1021, Initial: 0xFFFF
     */
    fun calculateCRC16(data: String): String {
        var crc = 0xFFFF // Initial value  
        val polynomial = 0x1021 // CRC-16-CCITT polynomial
        
        for (byte in data.toByteArray(Charsets.UTF_8)) {
            crc = crc xor ((byte.toInt() and 0xFF) shl 8)
            repeat(8) {
                if ((crc and 0x8000) != 0) {
                    crc = ((crc shl 1) xor polynomial) and 0xFFFF
                } else {
                    crc = (crc shl 1) and 0xFFFF
                }
            }
        }
        return "%04X".format(crc)
    }
    
    /**
     * Parse amount from fields
     */
    @Throws(TLVParsingException::class)
    private fun parseAmount(fields: List<TLVField>): BigDecimal? {
        val amountField = fields.find { it.tag == "54" } ?: return null
        
        return try {
            BigDecimal(amountField.value)
        } catch (e: NumberFormatException) {
            throw TLVParsingException.InvalidValue
        }
    }
    
    /**
     * Generate valid CRC16 for QR code data
     * @param qrData QR code data without CRC
     * @return 4-character uppercase hexadecimal CRC16
     */
    fun generateCRC16(qrData: String): String {
        // Remove existing CRC if present
        val dataWithoutCRC = qrData.replace(Regex("6304[A-F0-9]{4}"), "")
        return calculateCRC16(dataWithoutCRC)
    }
    
    /**
     * Validate QR code without throwing errors
     * @param data QR code data string
     * @return Validation result with errors and warnings
     */
    fun validateQRCode(data: String): QRValidationResult {
        return try {
            parseKenyaP2PQR(data)
            QRValidationResult(isValid = true)
        } catch (e: TLVParsingException) {
            val validationError = ValidationError("general", e.userMessage, "MALFORMED_DATA")
            QRValidationResult(isValid = false, errors = listOf(validationError))
        } catch (e: Exception) {
            val validationError = ValidationError("general", e.message ?: "Unknown error", "MALFORMED_DATA")
            QRValidationResult(isValid = false, errors = listOf(validationError))
        }
    }
    
    /**
     * Get bank name by identifier
     */
    fun getBankName(identifier: String): String? = BANK_PSPS[identifier]
    
    /**
     * Get telecom name by identifier  
     */
    fun getTelecomName(identifier: String): String? = TELECOM_PSPS[identifier]
    
    /**
     * Get all supported banks
     */
    fun getAllBanks(): List<PSPInfo> {
        return BANK_PSPS.map { (id, name) ->
            PSPInfo(PSPInfo.PSPType.BANK, id, name)
        }.sortedBy { it.name }
    }
    
    /**
     * Get all supported telecoms
     */
    fun getAllTelecoms(): List<PSPInfo> {
        return TELECOM_PSPS.map { (id, name) ->
            PSPInfo(PSPInfo.PSPType.TELECOM, id, name)
        }.sortedBy { it.name }
    }
} 