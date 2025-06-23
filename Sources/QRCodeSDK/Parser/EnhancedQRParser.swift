import Foundation

// MARK: - Enhanced QR Parser

public class EnhancedQRParser {
    
    private let pspDirectory = PSPDirectory.shared
    
    // MARK: - Required tags per EMVCo and national standards
    // Removed hard-coded requiredTags - now using flexible validation based on QR type
    private let accountTemplateTags = ["26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51"]
    
    public init() {}
    
    // MARK: - Main Parsing Function
    
    /// Parse a QR code string with enhanced support for multiple countries and use cases
    /// - Parameter data: The QR code data string
    /// - Returns: Enhanced parsed QR code information
    /// - Throws: ValidationError for various parsing failures
    public func parseQR(_ data: String) throws -> ParsedQRCode {
        print("🔍 EnhancedQRParser.parseQR() called")
        print("📏 Data length: \(data.count)")
        
        // Parse all TLV fields (including nested templates)
        print("📊 Parsing TLV fields...")
        let fields = try parseTLVWithTemplates(data)
        print("✅ TLV fields parsed: \(fields.count) fields found")
        
        // Print all parsed fields for debugging
        for field in fields {
            print("   📋 Tag: \(field.tag), Length: \(field.length), Value: \(String(field.value.prefix(30)))...")
        }
        
        // Validate structure and required fields
        print("🔍 Validating structure...")
        try validateStructure(fields)
        print("✅ Structure validation passed")
        
        // Validate CRC16 checksum (EMVCo compliance)
        print("🔍 Validating EMVCo checksum...")
        try validateChecksumEMVCo(data: data, fields: fields)
        print("✅ Checksum validation passed")
        
        // Determine country and QR type
        let country = try determineCountry(from: fields)
        let payloadFormat = try getRequiredField("00", from: fields).value
        let initiationMethod = try parseInitiationMethod(from: fields)
        let merchantCategoryCode = try getRequiredField("52", from: fields).value
        _ = QRType.fromMCC(merchantCategoryCode)
        
        // Parse account templates with extension field context
        let accountTemplates = try parseAccountTemplates(from: fields, country: country, allFields: fields)
        
        // Parse other fields
        let amount = parseAmount(from: fields)
        let recipientName = getOptionalField("59", from: fields)?.value
        let recipientIdentifier = getOptionalField("60", from: fields)?.value
        let currency = try getRequiredField("53", from: fields).value
        let countryCode = try getRequiredField("58", from: fields).value
        
        // Parse additional data (Tag 62)
        let additionalData = try parseAdditionalData(from: fields)
        
        // Parse format version (Tag 64)
        let formatVersion = getOptionalField("64", from: fields)?.value
        
        // Extract purpose from additional data for legacy compatibility
        let purpose = additionalData?.purposeOfTransaction
        
        return ParsedQRCode(
            fields: fields,
            payloadFormat: payloadFormat,
            initiationMethod: initiationMethod,
            accountTemplates: accountTemplates,
            merchantCategoryCode: merchantCategoryCode,
            amount: amount,
            recipientName: recipientName,
            recipientIdentifier: recipientIdentifier,
            purpose: purpose,
            currency: currency,
            countryCode: countryCode,
            additionalData: additionalData,
            formatVersion: formatVersion
        )
    }
    
    // MARK: - Enhanced TLV Parsing with Nested Templates
    
    private func parseTLVWithTemplates(_ data: String, isNested: Bool = false) throws -> [TLVField] {
        guard !data.isEmpty else {
            throw ValidationError.malformedData
        }
        
        var result: [TLVField] = []
        var cursor = data.startIndex
        
        while cursor < data.endIndex {
            // Parse tag (2 characters)
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                throw ValidationError.malformedData
            }
            
            let tag = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            // Enhanced tag validation - handle both numeric and Tanzania format tags
            guard isValidTag(tag, isNested: isNested) else {
                throw ValidationError.invalidFieldValue("tag", tag)
            }
            
            // Parse length (2 characters)
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                throw ValidationError.malformedData
            }
            
            let lengthStr = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            // Enhanced length parsing - handle both decimal and hex formats
            let length: Int
            if let decimalLength = Int(lengthStr) {
                // Standard decimal format (e.g., "12", "28")
                length = decimalLength
            } else if let hexLength = Int(lengthStr, radix: 16) {
                // Hex format for Tanzania TIPS (e.g., "7N" -> hex value)
                length = hexLength
            } else {
                // If neither decimal nor hex works, treat as malformed
                throw ValidationError.invalidFieldValue("length", lengthStr)
            }
            
            guard length >= 0 else {
                throw ValidationError.invalidFieldValue("length", lengthStr)
            }
            
            // Validate field constraints (different rules for nested templates)
            try validateFieldConstraints(tag: tag, length: length, isNested: isNested)
            
            // Check if we have enough data for the value
            guard data.distance(from: cursor, to: data.endIndex) >= length else {
                throw ValidationError.malformedData
            }
            
            // Parse value
            let value = String(data[cursor..<data.index(cursor, offsetBy: length)])
            cursor = data.index(cursor, offsetBy: length)
            
            // Validate field content (different rules for nested templates)
            try validateFieldContent(tag: tag, value: value, isNested: isNested)
            
            // Check if this is a template that needs nested parsing
            let nestedFields = try parseNestedTemplate(tag: tag, value: value)
            
            result.append(TLVField(tag: tag, length: length, value: value, nestedFields: nestedFields))
        }
        
        return result
    }
    
    private func parseNestedTemplate(tag: String, value: String) throws -> [TLVField]? {
        // Check if this tag represents a template that contains nested TLV data
        if accountTemplateTags.contains(tag) || tag == "62" || tag == "82" {
            // Parse nested TLV structure
            return try parseTLVWithTemplates(value, isNested: true)
        }
        return nil
    }
    
    // MARK: - EMVCo Compliance
    
    private func validateChecksumEMVCo(data: String, fields: [TLVField]) throws {
        print("🔍 validateChecksumEMVCo() - checking CRC...")
        
        guard let crcField = fields.first(where: { $0.tag == "63" }) else {
            print("❌ CRC field (Tag 63) not found")
            throw ValidationError.missingRequiredField("63")
        }
        
        print("   📋 Found CRC field - Value: \(crcField.value)")
        
        // Calculate CRC16 according to CBK standard section 7.11
        // Data includes all data objects with ID, Length, and Value
        // PLUS the CRC tag's ID and Length (but NOT its Value)
        let crcIdAndLength = "6304" // Tag 63 + Length 04
        let crcValue = crcField.value
        
        // Find the position of the CRC tag in the data
        let crcTagString = "63\(String(format: "%02d", crcField.length))\(crcValue)"
        guard let crcRange = data.range(of: crcTagString) else {
            print("❌ Could not find CRC tag in data")
            throw ValidationError.invalidChecksum
        }
        
        // Build data for CRC calculation: everything up to CRC + CRC ID and Length
        let dataBeforeCRC = String(data[..<crcRange.lowerBound])
        let dataForCRC = dataBeforeCRC + crcIdAndLength
        
        print("   📋 Data before CRC: \(dataBeforeCRC)")
        print("   📋 CRC ID+Length: \(crcIdAndLength)")
        print("   📋 Data for CRC calculation: \(dataForCRC)")
        print("   📏 CRC data length: \(dataForCRC.count)")
        
        // Calculate CRC16 using optimized method
        let calculatedCRC = PerformanceOptimizer.calculateCRC16Optimized(dataForCRC)
        let calculatedCRCString = String(format: "%04X", calculatedCRC)
        
        print("   📋 Calculated CRC: \(calculatedCRCString)")
        print("   📋 Expected CRC: \(crcValue)")
        
        // Compare CRCs using constant-time comparison for security
        guard SecurityManager.constantTimeCompare(calculatedCRCString, crcValue.uppercased()) else {
            print("❌ CRC validation failed: expected \(crcValue), got \(calculatedCRCString)")
            throw ValidationError.invalidChecksum
        }
        
        print("✅ CRC validation passed (CBK compliant)")
    }
    
    // MARK: - Validation Functions
    
    private func validateStructure(_ fields: [TLVField]) throws {
        print("🔍 validateStructure() - checking required fields...")
        
        // Determine QR type (P2P vs P2M) for flexible validation
        let qrType = determineQRType(from: fields)
        print("🔍 Detected QR Type: \(qrType)")
        
        // Core required fields for all QR types
        let coreRequiredTags = ["00", "01", "52", "53", "58", "63"]
        
        // Additional required fields based on QR type
        var requiredTagsForType = coreRequiredTags
        
        switch qrType {
        case .p2m:
            // P2M requires merchant name (Tag 59)
            requiredTagsForType.append("59")
            // Tag 60 can be city or merchant ID - flexible
        case .p2p:
            // P2P requires recipient identifier (Tag 60)
            requiredTagsForType.append("60")
        }
        
        // Validate required fields are present
        for requiredTag in requiredTagsForType {
            let hasField = fields.contains(where: { $0.tag == requiredTag })
            print("   📋 Tag \(requiredTag): \(hasField ? "✅ Found" : "❌ Missing")")
            guard hasField else {
                print("❌ Missing required field for \(qrType): \(requiredTag)")
                throw ValidationError.missingRequiredField(requiredTag)
            }
        }
        
        // Validate at least one account template is present
        let hasAccountTemplate = fields.contains { accountTemplateTags.contains($0.tag) }
        print("   📋 Account template: \(hasAccountTemplate ? "✅ Found" : "❌ Missing")")
        guard hasAccountTemplate else {
            print("❌ Missing account template field")
            throw ValidationError.missingRequiredField("account_template")
        }
        
        // Validate EMVCo tag ordering (Tag 63 should be near the end)
        guard let crcIndex = fields.firstIndex(where: { $0.tag == "63" }) else {
            throw ValidationError.missingRequiredField("63")
        }
        
        // Check if Tag 64 exists and is positioned correctly relative to CRC
        if let formatVersionIndex = fields.firstIndex(where: { $0.tag == "64" }) {
            // Tag 64 must come before Tag 63 for proper EMVCo compliance
            guard formatVersionIndex < crcIndex else {
                throw ValidationError.emvCoComplianceError("Tag 64 must appear before Tag 63")
            }
        }
        
        print("✅ Structure validation passed for \(qrType)")
    }
    
    // MARK: - QR Type Detection
    // Using public QRType from QRCodeModels.swift
    
    private func determineQRType(from fields: [TLVField]) -> QRType {
        // Use the MCC-based classification from the public QRType
        if let mccField = fields.first(where: { $0.tag == "52" }) {
            return QRType.fromMCC(mccField.value)
        }
        
        // Check for CBK domestic format indicators
        let hasKEQRFormat = fields.contains { field in
            accountTemplateTags.contains(field.tag) && 
            field.nestedFields?.contains { $0.tag == "00" && $0.value == "ke.go.qr" } == true
        }
        
        if hasKEQRFormat {
            return .p2m // CBK ke.go.qr format is primarily for P2M
        }
        
        // Check for proprietary P2P format indicators
        let hasProprietaryFormat = fields.contains { field in
            accountTemplateTags.contains(field.tag) && 
            field.value.hasPrefix("0002") // Equity's P2P format
        }
        
        if hasProprietaryFormat {
            return .p2p
        }
        
        // Default classification based on merchant indicators
        let hasMerchantName = fields.contains { $0.tag == "59" }
        let hasMCC = fields.contains { $0.tag == "52" }
        
        if hasMerchantName && hasMCC {
            return .p2m
        } else {
            return .p2p
        }
    }
    
    // MARK: - Enhanced Validation Methods
    
    private func isValidTag(_ tag: String, isNested: Bool) -> Bool {
        // Standard EMVCo numeric tags (00-99)
        if tag.allSatisfy({ $0.isNumber }) && tag.count == 2 {
            return true
        }
        
        // Tanzania TIPS specific tags (nested templates can have alphanumeric tags)
        if isNested {
            let tanzaniaTags = ["ti", "ps", "ac", "id", "nm", "ct", "cc", "am", "cu", "dt", "rf"]
            if tanzaniaTags.contains(tag.lowercased()) {
                return true
            }
        }
        
        // CBK Kenya specific extension tags (80-99)
        if let tagNumber = Int(tag), tagNumber >= 80 && tagNumber <= 99 {
            return true
        }
        
        // Additional validation for specific use cases
        return false
    }
    
    private func validateFieldConstraints(tag: String, length: Int, isNested: Bool) throws {
        // Maximum field length for EMVCo compliance
        let maxFieldLength = isNested ? 99 : 255
        
        guard length <= maxFieldLength else {
            print("❌ Field length validation failed for tag \(tag): \(length) > \(maxFieldLength)")
            throw ValidationError.invalidFieldValue("length", String(length))
        }
        
        // Specific tag constraints - be more lenient for nested templates
        if !isNested {
            switch tag {
            case "00": // Payload format - only validate at top level
                guard length == 2 else {
                    print("❌ Tag 00 length validation failed: expected 2, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 2)
                }
            case "01": // Initiation method - only validate at top level
                guard length == 2 else {
                    print("❌ Tag 01 length validation failed: expected 2, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 2)
                }
            case "52": // MCC
                guard length == 4 else {
                    print("❌ Tag 52 length validation failed: expected 4, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 4)
                }
            case "53": // Currency
                guard length == 3 else {
                    print("❌ Tag 53 length validation failed: expected 3, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 3)
                }
            case "58": // Country code
                guard length == 2 else {
                    print("❌ Tag 58 length validation failed: expected 2, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 2)
                }
            case "63": // CRC
                guard length == 4 else {
                    print("❌ Tag 63 length validation failed: expected 4, got \(length)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: 4)
                }
            default:
                // For other top-level tags, use general length validation
                guard length >= 0 && length <= maxFieldLength else {
                    print("❌ General length validation failed for tag \(tag): \(length) not in range 0-\(maxFieldLength)")
                    throw ValidationError.invalidFieldLength(tag, length, expected: nil)
                }
            }
        } else {
            // For nested templates, be much more permissive
            // In CBK format, Tag 00 in nested templates can be "ke.go.qr" (8 chars)
            // Tag 01 in nested templates can be phone numbers (variable length)
            guard length >= 0 && length <= maxFieldLength else {
                print("❌ Nested field length validation failed for tag \(tag): \(length) not in range 0-\(maxFieldLength)")
                throw ValidationError.invalidFieldLength(tag, length, expected: nil)
            }
        }
    }
    
    private func validateFieldContent(tag: String, value: String, isNested: Bool) throws {
        // Skip validation for nested templates to be more permissive
        if isNested {
            // For nested templates, only do basic validation
            // Tag 00 in nested templates can be "ke.go.qr" or other GUIDs
            // Tag 01 can be phone numbers, account numbers, etc.
            return
        }
        
        // Specific content validation (only for critical top-level fields)
        switch tag {
        case "00": // Payload format - only validate at top level
            guard value == "01" else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        case "01": // Initiation method - only validate at top level
            guard ["11", "12"].contains(value) else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        case "52": // MCC - validate numeric
            guard value.allSatisfy({ $0.isNumber }) else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        case "53": // Currency - validate numeric
            guard value.allSatisfy({ $0.isNumber }) else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        case "58": // Country code - validate alpha
            guard value.allSatisfy({ $0.isLetter }) else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        case "63": // CRC - validate hex
            guard value.allSatisfy({ $0.isHexDigit }) else {
                throw ValidationError.invalidFieldValue(tag, value)
            }
        default:
            // For other fields, be more permissive
            break
        }
    }
    
    // MARK: - Country and Type Detection
    
    private func determineCountry(from fields: [TLVField]) throws -> Country {
        let countryCode = try getRequiredField("58", from: fields).value
        guard let country = Country(rawValue: countryCode) else {
            throw ValidationError.invalidCountry(countryCode)
        }
        
        // Validate currency matches country
        let currencyCode = try getRequiredField("53", from: fields).value
        guard currencyCode == country.currencyCode else {
            throw ValidationError.currencyMismatch(country.currencyCode, currencyCode)
        }
        
        return country
    }
    
    private func parseInitiationMethod(from fields: [TLVField]) throws -> QRInitiationMethod {
        let initiationValue = try getRequiredField("01", from: fields).value
        guard let method = QRInitiationMethod(rawValue: initiationValue) else {
            throw ValidationError.invalidFieldValue("01", initiationValue)
        }
        return method
    }
    
    // MARK: - Account Template Parsing
    
    private func parseAccountTemplates(from fields: [TLVField], country: Country, allFields: [TLVField]? = nil) throws -> [AccountTemplate] {
        var templates: [AccountTemplate] = []
        var parseErrors: [String] = []
        
        for field in fields {
            if accountTemplateTags.contains(field.tag), let nestedFields = field.nestedFields {
                do {
                    if let template = try parseAccountTemplate(tag: field.tag, nestedFields: nestedFields, country: country, allFields: allFields) {
                        templates.append(template)
                        print("✅ Successfully parsed template for tag \(field.tag): \(template.pspInfo.name)")
                    } else {
                        print("⚠️ Template parsing returned nil for tag \(field.tag)")
                        parseErrors.append("Tag \(field.tag): returned nil")
                    }
                } catch {
                    print("⚠️ Template parsing failed for tag \(field.tag): \(error)")
                    parseErrors.append("Tag \(field.tag): \(error)")
                    // Continue parsing other templates instead of failing immediately
                }
            }
        }
        
        // Succeed if at least one template was parsed successfully
        guard !templates.isEmpty else {
            print("❌ No templates were successfully parsed")
            print("📋 Parse errors: \(parseErrors)")
            throw ValidationError.missingRequiredField("account_template")
        }
        
        print("✅ Successfully parsed \(templates.count) template(s) out of \(parseErrors.count + templates.count) total")
        if !parseErrors.isEmpty {
            print("⚠️ Some templates failed to parse but continuing: \(parseErrors)")
        }
        
        return templates
    }
    
    private func parseAccountTemplate(tag: String, nestedFields: [TLVField], country: Country, allFields: [TLVField]? = nil) throws -> AccountTemplate? {
        switch country {
        case .kenya:
                          return try parseKenyaAccountTemplate(tag: tag, nestedFields: nestedFields, allFields: allFields)
        case .tanzania:
            return try parseTanzaniaAccountTemplate(tag: tag, nestedFields: nestedFields)
        }
    }
    
    private func parseKenyaAccountTemplate(tag: String, nestedFields: [TLVField], allFields: [TLVField]? = nil) throws -> AccountTemplate? {
        print("🔍 parseKenyaAccountTemplate: Processing tag \(tag)")
        
                 // Check for CBK domestic format with extension field detection
         if let guidField = nestedFields.first(where: { $0.tag == "00" }),
            guidField.value == "ke.go.qr" {
             // This is CBK domestic format - try to detect PSP from additional context
             if let detectedPSP = detectPSPFromExtensionFields(tag: tag, nestedFields: nestedFields, allFields: allFields) {
                 print("✅ Detected PSP from extension fields: \(detectedPSP.name)")
                 let accountId = extractAccountIdFromCBKFormat(nestedFields: nestedFields)
                 return AccountTemplate(
                     tag: tag,
                     guid: "ke.go.qr",
                     participantId: detectedPSP.identifier,
                     accountId: accountId,
                     pspInfo: detectedPSP
                 )
             }
         }
        
        // First, try CBK standard format parsing
        if let pspInfo = pspDirectory.parsePSPFromTemplate(tag: tag, nestedFields: nestedFields, country: .kenya) {
            print("✅ CBK format parsing successful: \(pspInfo.name)")
            
            // Parse account ID from nested structure
            // For CBK format, account ID might be in different tags depending on QR type:
            // P2P: Tag 68 (account identifier)
            // P2M: Tag 07 (merchant identifier) 
            // Legacy: Tag 01 (legacy account identifier)
            var accountId: String?
            if let accountField = nestedFields.first(where: { $0.tag == "68" }) {
                // CBK P2P format - account info is in tag 68
                accountId = accountField.value
                print("🔍 parseKenyaAccountTemplate: Found P2P account ID in Tag 68: \(accountId!)")
            } else if let merchantField = nestedFields.first(where: { $0.tag == "07" }) {
                // CBK P2M format - merchant info is in tag 07
                accountId = merchantField.value
                print("🔍 parseKenyaAccountTemplate: Found P2M merchant ID in Tag 07: \(accountId!)")
            } else if let accountField = nestedFields.first(where: { $0.tag == "01" }) {
                // Legacy format - account info is in tag 01
                accountId = accountField.value
                print("🔍 parseKenyaAccountTemplate: Found legacy account ID in Tag 01: \(accountId!)")
            }
            
            let guid = nestedFields.first(where: { $0.tag == "00" })?.value ?? pspInfo.identifier
            
            return AccountTemplate(
                tag: tag,
                guid: guid,
                participantId: pspInfo.identifier,
                accountId: accountId,
                pspInfo: pspInfo
            )
        }
        
        // If CBK parsing fails, try proprietary P2P format parsing
        print("🔍 CBK parsing failed, trying proprietary P2P format...")
        
        // Check if this is a proprietary P2P format (like Equity's format)
        if let proprietaryTemplate = parseProprietaryP2PFormat(tag: tag, nestedFields: nestedFields) {
            print("✅ Proprietary P2P format parsing successful: \(proprietaryTemplate.pspInfo.name)")
            return proprietaryTemplate
        }
        
        // If both parsing methods fail, extract GUID for error reporting
        let guid = nestedFields.first(where: { $0.tag == "00" })?.value ?? 
                  (nestedFields.isEmpty ? "empty_template" : "unknown_format")
        print("🚨 All parsing methods failed for GUID: \(guid)")
        throw ValidationError.unknownPSP(guid)
    }
    
    private func parseProprietaryP2PFormat(tag: String, nestedFields: [TLVField]) -> AccountTemplate? {
        // Handle proprietary P2P formats (like Equity Bank's format)
        // Expected format: 0002EQLT010D2040881022296
        
        print("🔍 parseProprietaryP2PFormat: Checking for proprietary formats")
        
        // Check if the template contains a direct bank identifier
        for field in nestedFields {
            if field.tag == "00" && field.value.count == 4 {
                // Check if this is a 4-character bank identifier
                if let pspInfo = pspDirectory.getPSP(guid: field.value, country: .kenya) {
                    print("✅ Found proprietary bank identifier: \(field.value) -> \(pspInfo.name)")
                    
                    // Extract account ID from remaining nested fields
                    var accountId: String?
                    if let accountField = nestedFields.first(where: { $0.tag == "01" }) {
                        accountId = accountField.value
                    }
                    
                    return AccountTemplate(
                        tag: tag,
                        guid: field.value,
                        participantId: pspInfo.identifier,
                        accountId: accountId,
                        pspInfo: pspInfo
                    )
                }
            }
        }
        
        print("🚨 No proprietary format patterns found")
        return nil
    }
    
    private func parseTanzaniaAccountTemplate(tag: String, nestedFields: [TLVField]) throws -> AccountTemplate? {
        guard tag == "26",
              let guidField = nestedFields.first(where: { $0.tag == "00" }),
              guidField.value == "tz.go.bot.tips",
              let pspField = nestedFields.first(where: { $0.tag == "01" }) else {
            return nil
        }
        
        let pspCode = pspField.value
        guard let pspInfo = pspDirectory.getPSP(guid: pspCode, country: .tanzania) else {
            throw ValidationError.unknownPSP(pspCode)
        }
        
        let merchantId = nestedFields.first(where: { $0.tag == "02" })?.value
        
        return AccountTemplate(
            tag: tag,
            guid: guidField.value,
            participantId: pspCode,
            accountId: merchantId,
            pspInfo: pspInfo
        )
    }
    
    // MARK: - Additional Data Parsing (Tag 62) - Enhanced for Phase 2 & 3
    
    private func parseAdditionalData(from fields: [TLVField]) throws -> AdditionalData? {
        guard let additionalDataField = fields.first(where: { $0.tag == "62" }),
              let nestedFields = additionalDataField.nestedFields else {
            return nil
        }
        
        // Create AdditionalData with available initializer parameters
        var additionalData = AdditionalData(
            // Standard EMVCo fields (01-09)
            billNumber: nestedFields.first(where: { $0.tag == "01" })?.value,
            mobileNumber: nestedFields.first(where: { $0.tag == "02" })?.value,
            storeLabel: nestedFields.first(where: { $0.tag == "03" })?.value,
            loyaltyNumber: nestedFields.first(where: { $0.tag == "04" })?.value,
            referenceLabel: nestedFields.first(where: { $0.tag == "05" })?.value,
            customerLabel: nestedFields.first(where: { $0.tag == "06" })?.value,
            terminalLabel: nestedFields.first(where: { $0.tag == "07" })?.value,
            purposeOfTransaction: nestedFields.first(where: { $0.tag == "08" })?.value,
            additionalConsumerDataRequest: nestedFields.first(where: { $0.tag == "09" })?.value,
            customFields: parseCustomFields(from: nestedFields),
            
            // Phase 2: Merchant-specific fields (20-39)
            merchantCategory: nestedFields.first(where: { $0.tag == "20" })?.value,
            merchantSubCategory: nestedFields.first(where: { $0.tag == "21" })?.value,
            tipIndicator: nestedFields.first(where: { $0.tag == "22" })?.value,
            tipAmount: nestedFields.first(where: { $0.tag == "23" })?.value,
            convenienceFeeIndicator: nestedFields.first(where: { $0.tag == "24" })?.value,
            convenienceFee: nestedFields.first(where: { $0.tag == "25" })?.value,
            multiScheme: nestedFields.first(where: { $0.tag == "26" })?.value,
            supportedCountries: nestedFields.first(where: { $0.tag == "27" })?.value,
            
            // Healthcare-specific fields (40-49)
            patientId: nestedFields.first(where: { $0.tag == "40" })?.value,
            appointmentReference: nestedFields.first(where: { $0.tag == "41" })?.value,
            medicalRecordNumber: nestedFields.first(where: { $0.tag == "42" })?.value,
            
            // Transportation-specific fields (50-59)
            route: nestedFields.first(where: { $0.tag == "50" })?.value,
            ticketType: nestedFields.first(where: { $0.tag == "51" })?.value,
            
            // Utility-specific fields (60-69)
            serviceType: nestedFields.first(where: { $0.tag == "80" })?.value, accountNumber: nestedFields.first(where: { $0.tag == "60" })?.value,
            billingPeriod: nestedFields.first(where: { $0.tag == "61" })?.value,
            meterNumber: nestedFields.first(where: { $0.tag == "62" })?.value,
            
            // Legacy TIPS fields (Tanzania compatibility)
            tipsAcquirerId: nestedFields.first(where: { $0.tag == "70" })?.value,
            tipsVersion: nestedFields.first(where: { $0.tag == "71" })?.value,
            countrySpecific: nestedFields.first(where: { $0.tag == "90" })?.value
        )
        
        // Manually set fields not available in initializer
        additionalData.departureTime = nestedFields.first(where: { $0.tag == "52" })?.value
        additionalData.doctorId = nestedFields.first(where: { $0.tag == "43" })?.value
        additionalData.treatmentCode = nestedFields.first(where: { $0.tag == "44" })?.value
        additionalData.vehicleId = nestedFields.first(where: { $0.tag == "53" })?.value
        additionalData.arrivalTime = nestedFields.first(where: { $0.tag == "54" })?.value
        additionalData.seatNumber = nestedFields.first(where: { $0.tag == "55" })?.value
        additionalData.referenceNumber = nestedFields.first(where: { $0.tag == "63" })?.value
        additionalData.taxYear = nestedFields.first(where: { $0.tag == "66" })?.value
        additionalData.licenseNumber = nestedFields.first(where: { $0.tag == "67" })?.value
        additionalData.tipsTransactionId = nestedFields.first(where: { $0.tag == "72" })?.value
        additionalData.tipsTerminalId = nestedFields.first(where: { $0.tag == "73" })?.value
        additionalData.exchangeRate = nestedFields.first(where: { $0.tag == "81" })?.value
        additionalData.originalCurrency = nestedFields.first(where: { $0.tag == "82" })?.value
        additionalData.originalAmount = nestedFields.first(where: { $0.tag == "83" })?.value
        additionalData.fxProvider = nestedFields.first(where: { $0.tag == "84" })?.value
        additionalData.receiptUrl = nestedFields.first(where: { $0.tag == "91" })?.value
        additionalData.receiptFormat = nestedFields.first(where: { $0.tag == "92" })?.value
        additionalData.analyticsId = nestedFields.first(where: { $0.tag == "93" })?.value
        additionalData.sessionId = nestedFields.first(where: { $0.tag == "94" })?.value
        
        return additionalData
    }
    
    private func parseCustomFields(from nestedFields: [TLVField]) -> [String: String] {
        var customFields: [String: String] = [:]
        
        // Custom fields use tags 50-99
        for field in nestedFields {
            if let tagNumber = Int(field.tag), tagNumber >= 50 && tagNumber <= 99 {
                customFields[field.tag] = field.value
            }
        }
        
        return customFields
    }
    
    // MARK: - CBK Domestic Format Detection
    
    /// Detect PSP from extension fields and context for CBK domestic format
    private func detectPSPFromExtensionFields(tag: String, nestedFields: [TLVField], allFields: [TLVField]? = nil) -> PSPInfo? {
        // For Tag 28 (telecom), check phone number pattern
        if tag == "28", let phoneField = nestedFields.first(where: { $0.tag == "01" }) {
            let phoneNumber = phoneField.value
            print("🔍 detectPSPFromExtensionFields: Analyzing phone number: \(phoneNumber)")
            
            // Check for Kenyan phone patterns (both local and international)
            if phoneNumber.hasPrefix("254") {
                let localPart = String(phoneNumber.dropFirst(3))
                if localPart.first == "7" {
                    print("✅ detectPSPFromExtensionFields: Detected M-PESA from international phone format")
                    return pspDirectory.getPSP(guid: "MPESA", country: .kenya)
                }
            } else if phoneNumber.first == "7" {
                print("✅ detectPSPFromExtensionFields: Detected M-PESA from local phone format")
                return pspDirectory.getPSP(guid: "MPESA", country: .kenya)
            }
                 }
         
         // Check extension fields for M-PESA indicators
         if let topLevelFields = allFields {
             print("🔍 detectPSPFromExtensionFields: Checking top-level extension fields...")
             
             // Check Tag 83 for m-pesa.com domain
             if let extensionField = topLevelFields.first(where: { $0.tag == "83" }) {
                 print("🔍 detectPSPFromExtensionFields: Found Tag 83: \(extensionField.value)")
                 if extensionField.value.contains("m-pesa.com") {
                     print("✅ detectPSPFromExtensionFields: Detected M-PESA from extension field Tag 83")
                     return pspDirectory.getPSP(guid: "MPESA", country: .kenya)
                 }
             }
             
             // Check other extension fields (Tag 82) for M-PESA identifiers
             if let extensionField = topLevelFields.first(where: { $0.tag == "82" }) {
                 print("🔍 detectPSPFromExtensionFields: Found Tag 82: \(extensionField.value)")
                 if extensionField.value.contains("ke.go.qr") {
                     print("✅ detectPSPFromExtensionFields: Detected CBK format in Tag 82 - defaulting to M-PESA")
                     return pspDirectory.getPSP(guid: "MPESA", country: .kenya)
                 }
             }
         }
         
         return nil
    }
    
    /// Extract account ID from CBK domestic format
    private func extractAccountIdFromCBKFormat(nestedFields: [TLVField]) -> String? {
        // Try different tag locations for account ID
        if let accountField = nestedFields.first(where: { $0.tag == "68" }) {
            return accountField.value // P2P account identifier
        } else if let merchantField = nestedFields.first(where: { $0.tag == "07" }) {
            return merchantField.value // P2M merchant identifier  
        } else if let phoneField = nestedFields.first(where: { $0.tag == "01" }) {
            return phoneField.value // Phone number as account identifier
        }
        return nil
    }
    
    // MARK: - Utility Functions
    
    private func getRequiredField(_ tag: String, from fields: [TLVField]) throws -> TLVField {
        guard let field = fields.first(where: { $0.tag == tag }) else {
            throw ValidationError.missingRequiredField(tag)
        }
        return field
    }
    
    private func getOptionalField(_ tag: String, from fields: [TLVField]) -> TLVField? {
        return fields.first(where: { $0.tag == tag })
    }
    
    private func parseAmount(from fields: [TLVField]) -> Decimal? {
        guard let amountField = fields.first(where: { $0.tag == "54" }) else {
            return nil
        }
        
        return Decimal(string: amountField.value)
    }
    
    // MARK: - CRC16 Calculation (Optimized)
    
    private func calculateCRC16(_ data: String) -> String {
        // Use the optimized CRC16 calculation that matches CBK standard
        let crc = PerformanceOptimizer.calculateCRC16Optimized(data)
        return String(format: "%04X", crc)
    }
    
    // MARK: - Public Validation API
    
    /// Validate QR code without throwing errors
    /// - Parameter data: QR code data string
    /// - Returns: Enhanced validation result with country and type information
    public func validateQR(_ data: String) -> QRValidationResult {
        do {
            let parsedQR = try parseQR(data)
            let country = Country(rawValue: parsedQR.countryCode)
            let warnings = generateWarnings(for: parsedQR)
            
            return QRValidationResult(
                isValid: true,
                warnings: warnings,
                country: country,
                qrType: parsedQR.qrType
            )
        } catch let error as ValidationError {
            return QRValidationResult(isValid: false, errors: [error])
        } catch {
            return QRValidationResult(isValid: false, errors: [ValidationError.malformedData])
        }
    }
    
    private func generateWarnings(for qr: ParsedQRCode) -> [ValidationWarning] {
        var warnings: [ValidationWarning] = []
        
        if qr.accountTemplates.count > 1 {
            warnings.append(.multipleAccountTemplates)
        }
        
        if qr.formatVersion == nil {
            warnings.append(.missingOptionalField("64"))
        }
        
        if qr.recipientName == nil {
            warnings.append(.missingOptionalField("59"))
        }
        
        return warnings
    }
    
    /// Generate valid CRC16 for QR code data (CBK compliant)
    /// - Parameter qrData: QR code data without CRC
    /// - Returns: 4-character uppercase hexadecimal CRC16
    public func generateCRC16(for qrData: String) -> String {
        // Remove existing CRC if present
        let dataWithoutCRC = qrData.replacingOccurrences(of: #"6304[A-F0-9]{4}"#, with: "", options: .regularExpression)
        
        // Calculate CRC according to CBK standard section 7.11
        // Include CRC tag ID and Length (but not Value) in calculation
        let crcIdAndLength = "6304" // Tag 63 + Length 04
        let dataForCRC = dataWithoutCRC + crcIdAndLength
        
        return calculateCRC16(dataForCRC)
    }
    
    // MARK: - Phase 2 & 3: Enhanced Parsing Methods
    
    /// Parse and validate merchant QR code with enhanced validation
    /// - Parameter data: QR code data string
    /// - Returns: Parsed QR code with merchant-specific validation
    /// - Throws: ValidationError for merchant-specific validation failures
    public func parseMerchantQR(_ data: String) throws -> ParsedQRCode {
        let parsedQR = try parseQR(data)
        
        // Additional validation for merchant QRs
        try validateMerchantQR(parsedQR)
        
        return parsedQR
    }
    
    private func validateMerchantQR(_ qr: ParsedQRCode) throws {
        // Validate MCC
        guard MerchantCategories.shared.isValidMCC(qr.merchantCategoryCode) else {
            throw ValidationError.invalidFieldValue("52", qr.merchantCategoryCode)
        }
        
        // Check if this is actually a merchant QR (not P2P)
        let isP2P = MerchantCategories.shared.isP2P(mcc: qr.merchantCategoryCode)
        guard !isP2P else {
            // This is a P2P QR, not a merchant QR
            throw ValidationError.unsupportedQRType
        }
        
        // Get validation rules for the MCC
        let validationRules = MerchantCategories.shared.getValidationRules(for: qr.merchantCategoryCode)
        
        // Validate required merchant fields
        if validationRules.requiresMerchantName && (qr.recipientName?.isEmpty ?? true) {
            throw ValidationError.missingRequiredField("59") // Merchant name
        }
        
        if validationRules.requiresCity && (qr.recipientIdentifier?.isEmpty ?? true) {
            throw ValidationError.missingRequiredField("60") // Merchant city
        }
        
        // Validate amount constraints for dynamic QRs
        if let amount = qr.amount {
            if let maxLimit = validationRules.maxAmountLimit, amount > maxLimit {
                throw ValidationError.invalidFieldValue("54", "Amount exceeds limit for MCC \(qr.merchantCategoryCode)")
            }
        }
        
        // Validate static QR allowance
        if qr.initiationMethod == .static && !validationRules.allowsStaticQR {
            throw ValidationError.emvCoComplianceError("Static QR not allowed for MCC \(qr.merchantCategoryCode)")
        }
        
        // Validate required additional data fields
        if let additionalData = qr.additionalData {
            try validateRequiredAdditionalDataFields(additionalData, for: validationRules)
        } else if !validationRules.requiredAdditionalFields.isEmpty {
            throw ValidationError.missingRequiredField("62") // Additional data required
        }
    }
    
    private func validateRequiredAdditionalDataFields(_ additionalData: AdditionalData, for rules: MerchantValidationRules) throws {
        for requiredField in rules.requiredAdditionalFields {
            switch requiredField {
            case "patient_id":
                if additionalData.patientId == nil {
                    throw ValidationError.missingRequiredField("patient_id in additional data")
                }
            case "appointment_reference":
                if additionalData.appointmentReference == nil {
                    throw ValidationError.missingRequiredField("appointment_reference in additional data")
                }
            case "reference_number":
                if additionalData.referenceNumber == nil {
                    throw ValidationError.missingRequiredField("reference_number in additional data")
                }
            case "service_type":
                if additionalData.serviceType == nil {
                    throw ValidationError.missingRequiredField("service_type in additional data")
                }
            case "route":
                if additionalData.route == nil {
                    throw ValidationError.missingRequiredField("route in additional data")
                }
            case "ticket_type":
                if additionalData.ticketType == nil {
                    throw ValidationError.missingRequiredField("ticket_type in additional data")
                }
            case "account_number":
                if additionalData.accountNumber == nil {
                    throw ValidationError.missingRequiredField("account_number in additional data")
                }
            case "billing_period":
                if additionalData.billingPeriod == nil {
                    throw ValidationError.missingRequiredField("billing_period in additional data")
                }
            default:
                break
            }
        }
    }
    
    /// Parse Tanzania TANQR QR code with TIPS-specific validation
    /// - Parameter data: QR code data string
    /// - Returns: Parsed QR code with Tanzania-specific validation
    /// - Throws: ValidationError for Tanzania-specific validation failures
    public func parseTanzaniaQR(_ data: String) throws -> ParsedQRCode {
        let parsedQR = try parseQR(data)
        
        // Validate this is a Tanzania QR
        guard parsedQR.countryCode == "TZ" else {
            throw ValidationError.invalidCountry(parsedQR.countryCode)
        }
        
        // Validate currency is TZS for Tanzania
        guard parsedQR.currency == "834" else {
            throw ValidationError.currencyMismatch("834", parsedQR.currency)
        }
        
        // Validate TIPS template structure
        try validateTIPSStructure(parsedQR)
        
        return parsedQR
    }
    
    private func validateTIPSStructure(_ qr: ParsedQRCode) throws {
        // Find Tag 26 template (Tanzania unified template for TAN-QR)
        guard let tanqrTemplate = qr.accountTemplates.first(where: { $0.tag == "26" }) else {
            throw ValidationError.invalidTemplateStructure("Missing Tag 26 for Tanzania TAN-QR")
        }
        
        // Validate TAN-QR GUID
        guard tanqrTemplate.guid == "tz.go.bot.tips" else {
            throw ValidationError.invalidTemplateStructure("Invalid TAN-QR GUID: \(tanqrTemplate.guid)")
        }
        
        // Validate PSP code format (should be PSPxxx)
        guard let participantId = tanqrTemplate.participantId,
              participantId.hasPrefix("PSP"),
              participantId.count >= 6 else {
            throw ValidationError.invalidFieldValue("psp_code", tanqrTemplate.participantId ?? "")
        }
        
        // Validate merchant ID is present for merchant QRs (P2M)
        if !MerchantCategories.shared.isP2P(mcc: qr.merchantCategoryCode) {
            guard tanqrTemplate.accountId != nil else {
                throw ValidationError.missingRequiredField("merchant_id in TAN-QR template")
            }
        }
    }
    
    /// Enhanced QR type detection with P2M support
    /// - Parameter qr: Parsed QR code
    /// - Returns: Determined QR type (P2P or P2M)
    public func determineQRType(from qr: ParsedQRCode) -> QRType {
        return MerchantCategories.shared.isP2P(mcc: qr.merchantCategoryCode) ? .p2p : .p2m
    }
    
    /// Get merchant information from parsed QR
    /// - Parameter qr: Parsed QR code
    /// - Returns: Merchant information if available
    public func extractMerchantInfo(from qr: ParsedQRCode) -> MerchantInfo? {
        guard determineQRType(from: qr) == .p2m else {
            return nil
        }
        
        let category = MerchantCategories.shared.getMerchantCategory(mcc: qr.merchantCategoryCode)
        
        return MerchantInfo(
            name: qr.recipientName ?? "Unknown Merchant",
            city: qr.recipientIdentifier ?? "Unknown City",
            mcc: qr.merchantCategoryCode,
            category: category?.description ?? "Unknown Category",
            categoryType: MerchantCategories.shared.getCategoryType(mcc: qr.merchantCategoryCode),
            accountTemplates: qr.accountTemplates,
            additionalData: qr.additionalData
        )
    }
    
    /// Validate multi-scheme QR code
    /// - Parameter qr: Parsed QR code
    /// - Returns: Validation result for multi-scheme support
    public func validateMultiScheme(qr: ParsedQRCode) -> QRValidationResult {
        var warnings: [ValidationWarning] = []
        let errors: [ValidationError] = []
        
        // Check if QR supports multiple countries/schemes
        if qr.accountTemplates.count > 1 {
            let countries = Set(qr.accountTemplates.map { $0.pspInfo.country })
            
            // Validate cross-border compatibility
            if countries.count > 1 {
                // Multi-country QR - validate compatibility
                for country in countries {
                    if !country.supportsMultiCurrency {
                        warnings.append(.suboptimalConfiguration("Country \(country.rawValue) has limited multi-currency support"))
                    }
                }
                
                // Check if primary currency matches country
                let primaryCountry = Country(rawValue: qr.countryCode)
                if let primary = primaryCountry, !primary.majorTradingCurrencies.contains(qr.currency) {
                    warnings.append(.suboptimalConfiguration("Currency \(qr.currency) not commonly used in \(qr.countryCode)"))
                }
            }
        }
        
        return QRValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            country: Country(rawValue: qr.countryCode),
            qrType: determineQRType(from: qr)
        )
    }
    
    // MARK: - CBK Standard Extensions (Tags 80-99)
    
    /// Parse CBK domestic localization fields (Tags 80-99)
    private func parseCBKDomesticFields(from fields: [TLVField]) -> [String: String] {
        var domesticFields: [String: String] = [:]
        
        // Tag 80: Merchant Premises Location (CBK Standard section 7.12)
        if let locationField = fields.first(where: { $0.tag == "80" }) {
            domesticFields["merchant_location"] = locationField.value
        }
        
        // Tag 81: USSD Display Code (CBK Standard section 7.3)
        // Contains information for USSD users to initiate payment
        if let ussdField = fields.first(where: { $0.tag == "81" }) {
            domesticFields["ussd_code"] = ussdField.value
        }
        
        // Tag 82: QR Timestamp Information (CBK Standard section 7.13)
        if let timestampField = fields.first(where: { $0.tag == "82" }),
           let nestedFields = timestampField.nestedFields {
            
            // Parse timestamp nested structure
            if let guidField = nestedFields.first(where: { $0.tag == "00" }),
               guidField.value == "ke.go.qr" {
                
                if let generationTime = nestedFields.first(where: { $0.tag == "01" })?.value {
                    domesticFields["generation_time"] = generationTime
                }
                
                if let expirationTime = nestedFields.first(where: { $0.tag == "02" })?.value {
                    domesticFields["expiration_time"] = expirationTime
                }
            }
        }
        
        // Tag 83: Reserved for Safaricom (CBK Standard section 7.14)
        if let safaricomField = fields.first(where: { $0.tag == "83" }) {
            domesticFields["safaricom_data"] = safaricomField.value
        }
        
        return domesticFields
    }
}

// MARK: - Enhanced Data Models

/// Merchant information extracted from QR codes
public struct MerchantInfo {
    public let name: String
    public let city: String
    public let mcc: String
    public let category: String
    public let categoryType: CategoryType
    public let accountTemplates: [AccountTemplate]
    public let additionalData: AdditionalData?
    
    public init(name: String, city: String, mcc: String, category: String, 
                categoryType: CategoryType, accountTemplates: [AccountTemplate], 
                additionalData: AdditionalData? = nil) {
        self.name = name
        self.city = city
        self.mcc = mcc
        self.category = category
        self.categoryType = categoryType
        self.accountTemplates = accountTemplates
        self.additionalData = additionalData
    }
    
    /// Get payment options available at this merchant
    public var paymentOptions: [String] {
        return accountTemplates.compactMap { template in
            let pspName = template.pspInfo.name
            let pspType = template.pspInfo.type.displayName
            return "\(pspName) (\(pspType))"
        }
    }
    
    /// Check if merchant supports specific payment method
    public func supportsPaymentMethod(_ pspType: PSPInfo.PSPType) -> Bool {
        return accountTemplates.contains { $0.pspInfo.type == pspType }
    }
    
    /// Get business hours or operation info if available
    public var operationInfo: String? {
        return additionalData?.customFields["operation_hours"] ?? 
               additionalData?.storeLabel
    }
}

// MARK: - Extensions

extension UInt16 {
    var hexString: String {
        return String(format: "%04X", self)
    }
} 
