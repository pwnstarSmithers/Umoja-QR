import Foundation

public class KenyaP2PQRParser {
    
    // MARK: - Configuration
    
    /// Required tags per Kenya P2P QR specification
    private let requiredTags = ["00", "01", "52", "53", "58", "60", "63"]
    
    /// Either Tag 28 (Telecom) or Tag 29 (Bank) is required
    private let pspTags = ["28", "29"]
    
    // MARK: - PSP Directory
    
    /// Complete Bank PSP Directory from specification
    private let bankPSPs: [String: String] = [
        "01": "KCB Bank Kenya Limited",
        "02": "Standard Chartered Bank Kenya Ltd",
        "03": "ABSA Bank Kenya PLC",
        "05": "Bank of India",
        "06": "Bank of Baroda (Kenya) Ltd",
        "07": "NCBA Kenya PLC",
        "10": "Prime Bank Ltd",
        "11": "Co-operative Bank of Kenya Ltd",
        "12": "National Bank of Kenya Ltd",
        "14": "M-Oriental Bank Limited",
        "16": "Citibank N.A. Kenya",
        "17": "Habib Bank AG Zurich",
        "18": "Middle East Bank Kenya Ltd",
        "19": "Bank of Africa Kenya Ltd",
        "23": "Consolidated Bank of Kenya Ltd",
        "25": "Credit Bank Ltd",
        "26": "Access Bank (Kenya) Ltd",
        "30": "Chase Bank (K) Ltd",
        "31": "Stanbic Bank Kenya Ltd",
        "35": "African Banking Corporation Ltd",
        "39": "Imperial Bank Ltd",
        "43": "Ecobank Kenya Ltd",
        "49": "Spire Bank Ltd",
        "50": "Paramount Bank Ltd",
        "51": "Kingdom Bank Ltd",
        "53": "Guaranty Trust Bank (Kenya) Ltd",
        "54": "Victoria Commercial Bank Ltd",
        "55": "Guardian Bank Ltd",
        "57": "I&M Bank Ltd",
        "59": "Development Bank of Kenya Ltd",
        "60": "SBM Bank (Kenya) Ltd",
        "63": "Diamond Trust Bank (K) Ltd",
        "64": "Charterhouse Bank Ltd",
        "65": "Mayfair CIB Bank Ltd",
        "66": "Sidian Bank Ltd",
        "68": "Equity Bank Kenya Ltd",
        "70": "Family Bank Ltd",
        "72": "Gulf African Bank Ltd",
        "74": "First Community Bank Ltd",
        "75": "DIB Bank Kenya Ltd",
        "76": "UBA Kenya Bank Ltd",
        "83": "HFC Limited"
    ]
    
    /// Telecom PSP Directory
    private let telecomPSPs: [String: String] = [
        "01": "Safaricom (M-PESA)",
        "02": "Airtel Money",
        "12": "PesaPal"
    ]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Main Parsing Function
    
    /// Parse a Kenya P2P QR code string
    /// - Parameter data: The QR code data string
    /// - Returns: Parsed QR code information
    /// - Throws: TLVParsingError for various parsing failures
    public func parseKenyaP2PQR(_ data: String) throws -> ParsedQRCode {
        let fields = try parseTLV(data)
        
        // Validate required fields are present
        try validateRequiredFields(fields)
        
        // Validate CRC16 checksum
        try validateChecksum(data: data, fields: fields)
        
        // Parse PSP information
        let pspInfo = try parsePSPInfo(from: fields)
        
        // Extract other relevant information
        let isStatic = try determineQRType(from: fields)
        let amount = try parseAmount(from: fields)
        let recipientName = fields.first { $0.tag == "59" }?.value
        let recipientIdentifier = try parseRecipientIdentifier(from: fields)
        let purpose = try parsePurpose(from: fields)
        
        // Create account template from PSP info
        guard let pspInfo = pspInfo else {
            throw TLVParsingError.missingRequiredField("28 or 29")
        }
        
        let accountTemplate = AccountTemplate(
            tag: pspInfo.type == .bank ? "29" : "28",
            guid: pspInfo.identifier,
            accountId: recipientIdentifier,
            pspInfo: pspInfo
        )
        
        return ParsedQRCode(
            fields: fields,
            payloadFormat: "01",
            initiationMethod: isStatic ? .static : .dynamic,
            accountTemplates: [accountTemplate],
            merchantCategoryCode: "6011",
            amount: amount,
            recipientName: recipientName,
            recipientIdentifier: recipientIdentifier,
            purpose: purpose,
            currency: "404",
            countryCode: "KE",
            additionalData: purpose != nil ? AdditionalData(purposeOfTransaction: purpose) : nil,
            formatVersion: "P2P-KE-01"
        )
    }
    
    // MARK: - TLV Parsing
    
    private func parseTLV(_ data: String) throws -> [TLVField] {
        guard !data.isEmpty else {
            throw TLVParsingError.invalidDataLength
        }
        
        var result: [TLVField] = []
        var cursor = data.startIndex
        
        while cursor < data.endIndex {
            // Parse tag (2 characters)
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                throw TLVParsingError.corruptedData
            }
            
            let tag = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            // Validate tag format (should be numeric)
            guard tag.allSatisfy({ $0.isNumber }) else {
                throw TLVParsingError.invalidTag
            }
            
            // Parse length (2 characters)
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                throw TLVParsingError.corruptedData
            }
            
            let lengthStr = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            guard let length = Int(lengthStr), length >= 0 else {
                throw TLVParsingError.invalidLength
            }
            
            // Validate length constraints from specification
            try validateTagLength(tag: tag, length: length)
            
            // Check if we have enough data for the value
            guard data.distance(from: cursor, to: data.endIndex) >= length else {
                throw TLVParsingError.corruptedData
            }
            
            // Parse value
            let value = String(data[cursor..<data.index(cursor, offsetBy: length)])
            cursor = data.index(cursor, offsetBy: length)
            
            // Validate specific field constraints from specification
            try validateField(tag: tag, value: value)
            
            result.append(TLVField(tag: tag, length: length, value: value))
        }
        
        return result
    }
    
    // MARK: - Validation Functions
    
    private func validateTagLength(tag: String, length: Int) throws {
        let maxLengths: [String: Int] = [
            "00": 2,   // Payload Format Indicator
            "01": 2,   // Initiation Method
            "28": 99,  // Telecom PSP Data
            "29": 99,  // Bank PSP Data
            "52": 4,   // MCC
            "53": 3,   // Currency Code
            "54": 12,  // Amount
            "58": 2,   // Country Code
            "59": 25,  // Recipient Name
            "60": 15,  // Recipient Identifier
            "62": 99,  // Additional Data
            "63": 4,   // CRC16 Checksum
            "64": 12   // Format Version
        ]
        
        if let maxLength = maxLengths[tag], length > maxLength {
            throw TLVParsingError.invalidLength
        }
    }
    
    private func validateField(tag: String, value: String) throws {
        switch tag {
        case "00": // Payload Format Indicator
            guard value == "01" else {
                throw TLVParsingError.invalidValue
            }
            
        case "01": // Point of Initiation
            guard value == "11" || value == "12" else {
                throw TLVParsingError.invalidValue
            }
            
        case "52": // Merchant Category Code
            guard value == "6011" else {
                throw TLVParsingError.invalidValue
            }
            
        case "53": // Currency Code
            guard value == "404" else { // KES currency code
                throw TLVParsingError.invalidValue
            }
            
        case "54": // Transaction Amount (optional, dynamic QR only)
            if !value.isEmpty {
                guard let amount = Decimal(string: value), amount > 0 else {
                    throw TLVParsingError.invalidValue
                }
            }
            
        case "58": // Country Code
            guard value == "KE" else {
                throw TLVParsingError.invalidValue
            }
            
        case "59": // Recipient Name (optional but recommended)
            // UTF-8 validation and length already handled in validateTagLength
            break
            
        case "60": // Recipient Identifier
            guard !value.isEmpty else {
                throw TLVParsingError.invalidValue
            }
            
        case "63": // CRC16 Checksum
            guard value.count == 4, value.allSatisfy({ $0.isHexDigit }) else {
                throw TLVParsingError.invalidChecksum
            }
            
        case "64": // Format Version
            // Should be something like "P2P-KE-01"
            if !value.isEmpty && !value.hasPrefix("P2P-KE-") {
                throw TLVParsingError.unsupportedQRVersion
            }
            
        default:
            break // Other tags have flexible validation
        }
    }
    
    private func validateRequiredFields(_ fields: [TLVField]) throws {
        let presentTags = Set(fields.map { $0.tag })
        
        // Check required tags
        for requiredTag in requiredTags {
            if !presentTags.contains(requiredTag) {
                throw TLVParsingError.missingRequiredField(requiredTag)
            }
        }
        
        // Check that at least one PSP tag is present
        let hasPSPTag = pspTags.contains { presentTags.contains($0) }
        if !hasPSPTag {
            throw TLVParsingError.missingRequiredField("28 or 29")
        }
    }
    
    private func validateChecksum(data: String, fields: [TLVField]) throws {
        guard let crcField = fields.first(where: { $0.tag == "63" }) else {
            throw TLVParsingError.missingRequiredField("63")
        }
        
        // Calculate CRC16 according to CBK standard section 7.11
        // Data includes all data objects with ID, Length, and Value
        // PLUS the CRC tag's ID and Length (but NOT its Value)
        let crcIdAndLength = "6304" // Tag 63 + Length 04
        let crcValue = crcField.value
        
        // Find the position of the CRC tag in the data
        let crcTagString = "63\(String(format: "%02d", crcField.length))\(crcValue)"
        guard let crcRange = data.range(of: crcTagString) else {
            throw TLVParsingError.invalidChecksum
        }
        
        // Build data for CRC calculation: everything up to CRC + CRC ID and Length
        let dataBeforeCRC = String(data[..<crcRange.lowerBound])
        let dataForCRC = dataBeforeCRC + crcIdAndLength
        
        let calculatedCRC = calculateCRC16(dataForCRC)
        
        guard calculatedCRC.uppercased() == crcField.value.uppercased() else {
            throw TLVParsingError.invalidChecksum
        }
    }
    
    // MARK: - CRC16 Calculation
    
    private func calculateCRC16(_ data: String) -> String {
        // CRC-CCITT (False) implementation as per specification
        // Polynomial: 0x1021, Initial: 0xFFFF
        var crc: UInt16 = 0xFFFF
        let polynomial: UInt16 = 0x1021
        
        for byte in data.utf8 {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ polynomial
                } else {
                    crc <<= 1
                }
                crc &= 0xFFFF
            }
        }
        
        return String(format: "%04X", crc)
    }
    
    // MARK: - PSP Parsing
    
    private func parsePSPInfo(from fields: [TLVField]) throws -> PSPInfo? {
        // Check for Bank PSP (Tag 29)
        if let bankPSPField = fields.first(where: { $0.tag == "29" }) {
            return try parseBankPSP(bankPSPField.value)
        }
        
        // Check for Telecom PSP (Tag 28)
        if let telecomPSPField = fields.first(where: { $0.tag == "28" }) {
            return try parseTelecomPSP(telecomPSPField.value)
        }
        
        return nil
    }
    
    private func parseBankPSP(_ value: String) throws -> PSPInfo {
        // Expected format: 0002EQLT010D2040881022296
        // 0002 = subtag, EQLT = bank identifier, 010D = nested tag, account number follows
        
        guard value.count >= 8 else {
            throw TLVParsingError.invalidPSPFormat
        }
        
        let subtag = String(value.prefix(4))
        guard subtag == "0002" else {
            throw TLVParsingError.invalidPSPFormat
        }
        
        let bankIdentifier = String(value.dropFirst(4).prefix(2))
        guard let bankName = bankPSPs[bankIdentifier] else {
            throw TLVParsingError.unknownPSP
        }
        
        // Parse nested account information
        let remainingData = String(value.dropFirst(6))
        let accountNumber = try parseAccountFromNestedTLV(remainingData)
        
        return PSPInfo(
            type: .bank,
            identifier: bankIdentifier,
            name: bankName,
            accountNumber: accountNumber
        )
    }
    
    private func parseTelecomPSP(_ value: String) throws -> PSPInfo {
        // Parse telecom PSP format (implementation depends on specific format)
        // This is a simplified version - actual format may vary
        
        guard value.count >= 4 else {
            throw TLVParsingError.invalidPSPFormat
        }
        
        _ = String(value.prefix(4)) // subtag - not used in validation for telecoms
        let telecomIdentifier = String(value.dropFirst(4).prefix(2))
        
        guard let telecomName = telecomPSPs[telecomIdentifier] else {
            throw TLVParsingError.unknownPSP
        }
        
        return PSPInfo(
            type: .telecom,
            identifier: telecomIdentifier,
            name: telecomName,
            accountNumber: nil
        )
    }
    
    private func parseAccountFromNestedTLV(_ data: String) throws -> String {
        // Parse nested TLV structure within PSP data
        // Example: 010D2040881022296 -> tag: 01, length: 0D (13), value: 2040881022296
        
        guard data.count >= 4 else {
            throw TLVParsingError.invalidNestedTLV
        }
        
        _ = String(data.prefix(2)) // nestedTag - not used in current implementation
        let lengthHex = String(data.dropFirst(2).prefix(2))
        
        guard let length = Int(lengthHex, radix: 16) else {
            throw TLVParsingError.invalidNestedTLV
        }
        
        guard data.count >= 4 + length else {
            throw TLVParsingError.invalidNestedTLV
        }
        
        return String(data.dropFirst(4).prefix(length))
    }
    
    // MARK: - Data Extraction
    
    private func determineQRType(from fields: [TLVField]) throws -> Bool {
        guard let initiationField = fields.first(where: { $0.tag == "01" }) else {
            throw TLVParsingError.missingRequiredField("01")
        }
        
        return initiationField.value == "11" // true for static, false for dynamic
    }
    
    private func parseAmount(from fields: [TLVField]) throws -> Decimal? {
        guard let amountField = fields.first(where: { $0.tag == "54" }) else {
            return nil
        }
        
        return Decimal(string: amountField.value)
    }
    
    private func parseRecipientIdentifier(from fields: [TLVField]) throws -> String {
        guard let recipientField = fields.first(where: { $0.tag == "60" }) else {
            throw TLVParsingError.missingRequiredField("60")
        }
        
        return recipientField.value
    }
    
    private func parsePurpose(from fields: [TLVField]) throws -> String? {
        guard let additionalDataField = fields.first(where: { $0.tag == "62" }) else {
            return nil
        }
        
        // Parse nested TLV in Tag 62 for purpose
        // Example: 010DPersonal Transfer
        let nestedFields = try parseTLV(additionalDataField.value)
        return nestedFields.first(where: { $0.tag == "01" })?.value
    }
    
    // MARK: - Utility Functions
    
    /// Generate valid CRC16 for QR code data (CBK compliant)
    /// - Parameter qrData: QR code data without CRC
    /// - Returns: 4-character uppercase hexadecimal CRC16
    public func generateCRC16(for qrData: String) -> String {
        // Remove existing CRC if present
        let dataWithoutCRC = qrData.replacingOccurrences(
            of: #"6304[A-F0-9]{4}"#, 
            with: "", 
            options: .regularExpression
        )
        
        // Calculate CRC according to CBK standard section 7.11
        // Include CRC tag ID and Length (but not Value) in calculation
        let crcIdAndLength = "6304" // Tag 63 + Length 04
        let dataForCRC = dataWithoutCRC + crcIdAndLength
        
        return calculateCRC16(dataForCRC)
    }
    
    /// Validate QR code without throwing errors
    /// - Parameter data: QR code data string
    /// - Returns: Validation result with errors and warnings
    public func validateQRCode(_ data: String) -> QRValidationResult {
        do {
            _ = try parseKenyaP2PQR(data)
            return QRValidationResult(isValid: true)
        } catch _ as TLVParsingError {
            let validationError = ValidationError.malformedData
            return QRValidationResult(isValid: false, errors: [validationError])
        } catch {
            let validationError = ValidationError.malformedData
            return QRValidationResult(isValid: false, errors: [validationError])
        }
    }
} 
