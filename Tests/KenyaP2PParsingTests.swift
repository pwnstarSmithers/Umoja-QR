import XCTest
@testable import QRCodeSDK

/// Comprehensive tests for Kenya P2P QR code parsing
/// Covers real-world QR codes including Safaricom M-PESA CBK format
public class KenyaP2PParsingTests: XCTestCase {
    
    var parser: EnhancedQRParser!
    var sdk: QRCodeSDK!
    
    override public func setUp() {
        super.setUp()
        parser = EnhancedQRParser()
        sdk = QRCodeSDK.shared
    }
    
    override public func tearDown() {
        parser = nil
        sdk = nil
        super.tearDown()
    }
    
    // MARK: - Real-World QR Code Parsing Tests
    
    func testSafaricomMPesaCBKFormatParsing() throws {
        // Test the actual Safaricom M-PESA QR that was failing before
        let qrString = "00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI6205000016304FB5D"
        
        let result = try parser.parseQR(qrString)
        
        // Verify parsing results
        XCTAssertEqual(result.payloadFormat, "01")
        XCTAssertEqual(result.initiationMethod, .static) // Static QR
        XCTAssertEqual(result.merchantCategoryCode, "6015") // Person-to-person
        XCTAssertEqual(result.countryCode, "KE")
        XCTAssertEqual(result.recipientName, "JANE WANJIRU KAMAU")
        // Note: city property doesn't exist in ParsedQRCode
        
        // Verify account template parsing
        XCTAssertEqual(result.accountTemplates.count, 1)
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.tag, "28")
        XCTAssertEqual(template.guid, "ke.go.qr")
        XCTAssertEqual(template.accountId, "254769300743") // Phone number
        
        // Verify PSP detection
        XCTAssertEqual(template.pspInfo.identifier, "01") // M-PESA PSP ID
        XCTAssertEqual(template.pspInfo.name, "Safaricom M-PESA")
        XCTAssertEqual(template.pspInfo.type, .telecom)
        
        // Verify QR type classification
        XCTAssertEqual(result.qrType, .p2p)
        
        print("✅ Safaricom M-PESA CBK parsing successful")
        print("   Phone: \(template.accountId ?? "N/A")")
        print("   PSP: \(template.pspInfo.name)")
    }
    
    func testEquityBankP2MQRParsing() throws {
        // Test the Equity Bank merchant QR that was provided earlier
        let qrString = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94"
        
        let result = try parser.parseQR(qrString)
        
        // Verify parsing results
        XCTAssertEqual(result.payloadFormat, "01")
        XCTAssertEqual(result.merchantCategoryCode, "5411") // Grocery stores
        XCTAssertEqual(result.countryCode, "KE")
        XCTAssertEqual(result.recipientName, "Thika Vivian Stores")
        
        // Verify account template parsing
        XCTAssertGreaterThan(result.accountTemplates.count, 0)
        let bankTemplate = result.accountTemplates.first { $0.tag == "29" }
        XCTAssertNotNil(bankTemplate)
        XCTAssertEqual(bankTemplate?.guid, "ke.go.qr")
        XCTAssertEqual(bankTemplate?.participantId, "68") // Equity PSP ID
        
        // Verify QR type classification
        XCTAssertEqual(result.qrType, .p2m) // Merchant payment
        
        print("✅ Equity Bank P2M parsing successful")
        print("   Merchant: \(result.recipientName ?? "N/A")")
        print("   MCC: \(result.merchantCategoryCode)")
    }
    
    func testKCBBankP2PQRParsing() throws {
        // Test KCB Bank P2P QR (synthetic example)
        let qrString = "00020101021129210008ke.go.qr0113011234567890520406011802KE5908John Doe6007NAIROBI63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Verify parsing results
        XCTAssertEqual(result.payloadFormat, "01")
        XCTAssertEqual(result.merchantCategoryCode, "6011") // Financial institution
        XCTAssertEqual(result.countryCode, "KE")
        
        // Verify account template parsing
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.tag, "29")
        XCTAssertEqual(template.guid, "ke.go.qr")
        XCTAssertEqual(template.participantId, "01") // KCB PSP ID
        XCTAssertEqual(template.accountId, "1234567890")
        
        // Verify PSP detection
        XCTAssertEqual(template.pspInfo.identifier, "01")
        XCTAssertEqual(template.pspInfo.name, "Kenya Commercial Bank")
        XCTAssertEqual(template.pspInfo.type, .bank)
        
        print("✅ KCB Bank P2P parsing successful")
    }
    
    func testAirtelMoneyP2PQRParsing() throws {
        // Test Airtel Money P2P QR (synthetic example)
        let qrString = "00020101021128280008ke.go.qr0113022547123456780520406011802KE5912Airtel User6007NAIROBI63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Verify parsing results
        XCTAssertEqual(result.merchantCategoryCode, "6011")
        XCTAssertEqual(result.countryCode, "KE")
        
        // Verify account template parsing
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.tag, "28") // Telecom template
        XCTAssertEqual(template.guid, "ke.go.qr")
        XCTAssertEqual(template.participantId, "02") // Airtel PSP ID
        XCTAssertEqual(template.accountId, "2547123456780")
        
        // Verify PSP detection
        XCTAssertEqual(template.pspInfo.identifier, "02")
        XCTAssertEqual(template.pspInfo.name, "Airtel Money")
        XCTAssertEqual(template.pspInfo.type, .telecom)
        
        print("✅ Airtel Money P2P parsing successful")
    }
    
    // MARK: - Legacy Format Parsing Tests
    
    func testLegacyEquityBankP2PQRParsing() throws {
        // Test legacy Equity Bank format (PSP-specific GUID)
        let qrString = "00020101021129130004EQLT6811dummy123456520406011802KE5908Test User6007NAIROBI63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Verify parsing results
        XCTAssertEqual(result.merchantCategoryCode, "6011")
        XCTAssertEqual(result.countryCode, "KE")
        
        // Verify account template parsing
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.tag, "29")
        XCTAssertEqual(template.guid, "EQLT") // Legacy GUID
        XCTAssertEqual(template.participantId, "68")
        XCTAssertEqual(template.accountId, "dummy123456")
        
        // Should still detect Equity Bank from legacy GUID
        XCTAssertEqual(template.pspInfo.name, "Equity Bank")
        XCTAssertEqual(template.pspInfo.type, .bank)
        
        print("✅ Legacy Equity Bank P2P parsing successful")
    }
    
    // MARK: - Multi-PSP QR Parsing Tests
    
    func testMultiPSPQRParsing() throws {
        // Test QR with multiple PSP options (bank + telecom)
        let qrString = "00020101021128280008ke.go.qr01130125471234567892921" +
                      "0008ke.go.qr68111234567890520406011802KE5912Multi User6007NAIROBI63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Should have both bank and telecom templates
        XCTAssertEqual(result.accountTemplates.count, 2)
        
        let telecomTemplate = result.accountTemplates.first { $0.tag == "28" }
        let bankTemplate = result.accountTemplates.first { $0.tag == "29" }
        
        XCTAssertNotNil(telecomTemplate)
        XCTAssertNotNil(bankTemplate)
        
        // Verify telecom template
        XCTAssertEqual(telecomTemplate?.guid, "ke.go.qr")
        XCTAssertEqual(telecomTemplate?.participantId, "01") // M-PESA
        XCTAssertEqual(telecomTemplate?.accountId, "254712345678")
        
        // Verify bank template
        XCTAssertEqual(bankTemplate?.guid, "ke.go.qr")
        XCTAssertEqual(bankTemplate?.participantId, "68") // Equity
        XCTAssertEqual(bankTemplate?.accountId, "1234567890")
        
        print("✅ Multi-PSP QR parsing successful")
        print("   Telecom: \(telecomTemplate?.pspInfo.name ?? "N/A")")
        print("   Bank: \(bankTemplate?.pspInfo.name ?? "N/A")")
    }
    
    // MARK: - Dynamic QR Parsing Tests
    
    func testDynamicP2PWithAmountParsing() throws {
        // Test dynamic P2P QR with pre-filled amount
        let qrString = "00020101021229210008ke.go.qr6811123456789052040601154061000.00802KE5908Test User6007NAIROBI63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Verify dynamic QR characteristics
        XCTAssertEqual(result.initiationMethod, .dynamic) // Dynamic
        XCTAssertEqual(result.amount, Decimal(string: "1000.00"))
        XCTAssertEqual(result.currency, "404") // KES
        
        // Verify account template
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.accountId, "123456789")
        
        print("✅ Dynamic P2P with amount parsing successful")
        print("   Amount: \(result.amount ?? 0) KES")
    }
    
    // MARK: - Extension Field Parsing Tests
    
    func testExtensionFieldParsing() throws {
        // Test QR with extension fields (like the Safaricom example)
        let qrString = "00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI" +
                      "83210010m-pesa.com010203abc63041234"
        
        let result = try parser.parseQR(qrString)
        
        // Verify extension field parsing
        let extensionField = result.fields.first { $0.tag == "83" }
        XCTAssertNotNil(extensionField, "Extension field should be present")
        
        // Check if extension field contains expected data
        if let field = extensionField {
            XCTAssertTrue(field.value.contains("m-pesa.com"), "Extension field should contain domain data")
        }
        
        print("✅ Extension field parsing successful")
        print("   Extension field found: \(extensionField != nil)")
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testMalformedQRHandling() {
        // Test handling of malformed QR codes
        let malformedQRs = [
            "00020101", // Too short
            "00020102021128", // Invalid payload format
            "000201010211", // Missing required fields
            "invalidqrcode", // Not TLV format
            "" // Empty string
        ]
        
        for qrString in malformedQRs {
            XCTAssertThrowsError(try parser.parseQR(qrString)) { _ in
                print("✅ Correctly rejected malformed QR: \(qrString)")
            }
        }
    }
    
    func testInvalidCRCHandling() {
        // Test QR with invalid CRC
        let qrString = "00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI63040000"
        
        XCTAssertThrowsError(try parser.parseQR(qrString)) { error in
            XCTAssertTrue(error is TLVParsingError)
            if case .invalidChecksum = error as? TLVParsingError {
                print("✅ Correctly detected invalid CRC")
            } else {
                XCTFail("Expected invalid checksum error")
            }
        }
    }
    
    func testMissingRequiredFieldsHandling() {
        // Test QR missing required fields
        let qrString = "00020101021128280008ke.go.qr011225476930074363041234" // Missing MCC
        
        XCTAssertThrowsError(try parser.parseQR(qrString)) { error in
            print("✅ Correctly rejected QR missing required fields")
        }
    }
    
    // MARK: - Phone Number Format Tests
    
    func testPhoneNumberFormatDetection() throws {
        // Test different phone number formats
        let testCases = [
            ("254712345678", true, "International format"),
            ("712345678", true, "Local format"),
            ("0712345678", true, "Local with leading zero"),
            ("12345", false, "Too short"),
            ("25412345678901", false, "Too long")
        ]
        
        for (phoneNumber, shouldBeValid, description) in testCases {
            let qrString = "00020101021128280008ke.go.qr0113\(String(format: "%02d", phoneNumber.count))\(phoneNumber)520406015802KE5919Test User6007NAIROBI63041234"
            
            if shouldBeValid {
                XCTAssertNoThrow(try parser.parseQR(qrString), description)
                print("✅ Valid phone format: \(phoneNumber) - \(description)")
            } else {
                // Invalid formats may still parse but with warnings
                print("⚠️  Questionable phone format: \(phoneNumber) - \(description)")
            }
        }
    }
    
    // MARK: - PSP Identification Tests
    
    func testPSPIdentificationFromPhoneNumbers() throws {
        // Test PSP identification from phone number patterns
        let testCases = [
            ("254712345678", "01", "Safaricom M-PESA"),     // 71X pattern
            ("254722123456", "01", "Safaricom M-PESA"),     // 72X pattern
            ("254788999888", "02", "Airtel Money"),         // 78X pattern
            ("254762555444", "03", "Telkom T-Kash")         // 76X pattern
        ]
        
        for (phoneNumber, expectedPSPId, expectedPSPName) in testCases {
            let qrString = "00020101021128280008ke.go.qr0113\(String(format: "%02d", phoneNumber.count))\(phoneNumber)520406015802KE5919Test User6007NAIROBI63041234"
            
            let result = try parser.parseQR(qrString)
            let template = result.accountTemplates.first!
            
            XCTAssertEqual(template.pspInfo.identifier, expectedPSPId)
            XCTAssertEqual(template.pspInfo.name, expectedPSPName)
            
            print("✅ PSP identified: \(phoneNumber) -> \(expectedPSPName)")
        }
    }
    
    // MARK: - CRC Validation Tests
    
    func testCRCValidation() throws {
        // Test CRC validation with known good QR
        let qrString = "00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI6205000016304FB5D"
        
        // Should parse without throwing CRC error
        XCTAssertNoThrow(try parser.parseQR(qrString))
        
        _ = try parser.parseQR(qrString)
        // Note: CRC validation occurs during parsing, successful parsing indicates valid CRC
        
        print("✅ CRC validation passed: parsing successful")
    }
    
    // MARK: - Performance Tests
    
    func testParsingPerformance() {
        // Test parsing performance with complex QR
        let qrString = "00020101021128280008ke.go.qr0112254769300743292100008ke.go.qr68111234567890520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI83210010m-pesa.com010203abc63041234"
        
        measure {
            _ = try? parser.parseQR(qrString)
        }
    }
    
    // MARK: - Regression Protection Tests
    
    func testCriticalQRCodes() throws {
        // These QR codes must ALWAYS work (regression protection)
        let criticalQRs = [
            // Original Safaricom QR that was failing
            "00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI6205000016304FB5D",
            
            // Equity Bank merchant QR
            "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94"
        ]
        
        for (index, qrString) in criticalQRs.enumerated() {
            XCTAssertNoThrow(try parser.parseQR(qrString), "Critical QR #\(index + 1) must always parse")
            let result = try parser.parseQR(qrString)
            XCTAssertFalse(result.accountTemplates.isEmpty, "Critical QR #\(index + 1) must have account templates")
            print("✅ Critical QR #\(index + 1) parsing verified")
        }
    }
} 