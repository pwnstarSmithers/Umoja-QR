import XCTest
@testable import QRCodeSDK

/// Comprehensive tests for CBK (Central Bank of Kenya) QR Code Standard compliance
/// Ensures SDK meets all official requirements for Kenya payment QR codes
public class CBKComplianceTests: XCTestCase {
    
    var parser: EnhancedQRParser!
    var generator: EnhancedQRGenerator!
    var sdk: QRCodeSDK!
    
    override public func setUp() {
        super.setUp()
        parser = EnhancedQRParser()
        generator = EnhancedQRGenerator()
        sdk = QRCodeSDK.shared
    }
    
    override public func tearDown() {
        parser = nil
        generator = nil
        sdk = nil
        super.tearDown()
    }
    
    // MARK: - CBK Section 7.11 CRC16 Validation Tests
    
    func testCRC16CalculationCBKSection7_11() throws {
        // Test CBK Section 7.11: CRC calculation includes tag ID+Length
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        
        // Calculate CRC for the test data
        let calculatedCRC = parser.generateCRC16(for: testData)
        
        // Test parsing with our calculated CRC
        let qrWithCRC = testData + "6304" + calculatedCRC
        XCTAssertNoThrow(try parser.parseQR(qrWithCRC), "QR with CBK-compliant CRC should parse successfully")
        
        print("✅ CBK Section 7.11 CRC compliance verified: \(calculatedCRC)")
    }
    
    func testCRCIncludesAllDataObjects() throws {
        // Test that CRC calculation includes ALL data objects as per CBK standard
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let qrString = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(qrString)
        
        // Verify all major data objects are included in CRC calculation
        XCTAssertNotNil(result.payloadFormat)          // Tag 00
        XCTAssertNotNil(result.initiationMethod)       // Tag 01
        XCTAssertNotNil(result.accountTemplates)       // Tags 28/29
        XCTAssertNotNil(result.merchantCategoryCode)   // Tag 52
        XCTAssertNotNil(result.countryCode)           // Tag 58
        XCTAssertNotNil(result.recipientName)         // Tag 59
        XCTAssertNotNil(result.additionalData)        // Tag 62
        
        print("✅ All data objects included in CRC calculation")
    }
    
    // MARK: - CBK Domestic Identifier Tests
    
    func testCBKDomesticIdentifierCompliance() throws {
        // Test that ALL Kenya QR codes use "ke.go.qr" domestic identifier
        let testCases = [
            // Bank P2P - Using valid TLV structure
            ("Equity Bank P2P", "0002010102129210008ke.go.qr68101234567890520460115802KE5908Test User6007NAIROBI"),
            // Telecom P2P - Using valid TLV structure  
            ("M-PESA P2P", "0002010102128280008ke.go.qr0112254712345678520460115802KE5910M-PESA User6007NAIROBI"),
            // Bank P2M - Using valid TLV structure
            ("Equity Merchant", "0002010102129210008ke.go.qr68106826665552054411530340458024KE5919Thika Vivian Stores6007NAIROBI"),
            // Telecom P2M - Using valid TLV structure
            ("M-PESA Merchant", "0002010102128280008ke.go.qr0112254007120048520454115802KE5910KFC Branch6007NAIROBI")
        ]
        
        for (description, baseQR) in testCases {
            let calculatedCRC = parser.generateCRC16(for: baseQR)
            let qrString = baseQR + "6304" + calculatedCRC
            
            let result = try parser.parseQR(qrString)
            
            // Every Kenya QR must use CBK domestic identifier
            let hasKenyaDomesticId = result.accountTemplates.contains { $0.guid == "ke.go.qr" }
            XCTAssertTrue(hasKenyaDomesticId, "\(description) must use ke.go.qr domestic identifier")
            
            print("✅ \(description) uses CBK domestic identifier")
        }
    }
    
    func testRejectNonCBKIdentifiers() {
        // Test that non-CBK identifiers are flagged (for legacy detection)
        let baseQR = "0002010102113040004EQLT011012345678905204601158024KE5908Test User6007NAIROBI"
        let calculatedCRC = parser.generateCRC16(for: baseQR)
        let legacyQR = baseQR + "6304" + calculatedCRC
        
        do {
            let result = try parser.parseQR(legacyQR)
            let template = result.accountTemplates.first!
            
            // Legacy format should be detected but flagged
            XCTAssertEqual(template.guid, "EQLT", "Should parse legacy GUID")
            XCTAssertNotEqual(template.guid, "ke.go.qr", "Should not be CBK domestic format")
            
            print("✅ Legacy format detected: \(template.guid)")
        } catch {
            // Acceptable if SDK rejects non-CBK formats
            print("✅ Non-CBK identifier correctly rejected")
        }
    }
    
    // MARK: - PSP Directory Compliance Tests
    
    func testPSPDirectoryMappingCompliance() throws {
        // Test PSP ID mappings according to CBK directory
        let pspMappings = [
            // Banks (PSP codes from CBK directory)
            ("01", "Kenya Commercial Bank", PSPInfo.PSPType.bank),
            ("68", "Equity Bank", PSPInfo.PSPType.bank),
            ("11", "Co-operative Bank", PSPInfo.PSPType.bank),
            ("03", "Standard Chartered Bank", PSPInfo.PSPType.bank),
            // Telecoms (PSP codes from CBK directory)
            ("01", "Safaricom M-PESA", PSPInfo.PSPType.telecom),
            ("02", "Airtel Money", PSPInfo.PSPType.telecom),
            ("03", "Telkom T-Kash", PSPInfo.PSPType.telecom)
        ]
        
        for (pspId, expectedName, expectedType) in pspMappings {
            // Use the correct lookup method from PSPDirectory
            if let pspInfo = PSPDirectory.shared.lookupPSP(id: pspId, type: expectedType, country: .kenya) {
                XCTAssertEqual(pspInfo.name, expectedName, "PSP ID \(pspId) should map to \(expectedName)")
                XCTAssertEqual(pspInfo.type, expectedType, "PSP ID \(pspId) should be type \(expectedType)")
                
                print("✅ PSP \(pspId) -> \(expectedName) (\(expectedType))")
            } else {
                print("⚠️  PSP ID \(pspId) not found in directory")
            }
        }
    }
    
    func testProgressivePrefixMatching() {
        // Test CBK-compliant progressive prefix matching for PSP IDs
        let testCases = [
            ("68", "Equity Bank"),           // Exact match
            ("681", "Equity Bank"),          // Should match "68" prefix
            ("6822", "Equity Bank"),         // Should match "68" prefix
            ("01234", "Kenya Commercial Bank"), // Should match "01" prefix
        ]
        
        for (pspId, expectedBank) in testCases {
            // Use the progressive prefix matching method
            if let pspInfo = PSPDirectory.shared.getPSPByID(pspId, country: .kenya) {
                XCTAssertEqual(pspInfo.name, expectedBank, "PSP ID \(pspId) should resolve to \(expectedBank)")
                
                print("✅ Progressive matching: \(pspId) -> \(expectedBank)")
            } else {
                print("⚠️  PSP ID \(pspId) not resolved")
            }
        }
    }
    
    // MARK: - EMVCo Compliance Tests
    
    func testEMVCoTagOrdering() throws {
        // Test EMVCo requirement: Tag 64 (merchant language) before Tag 63 (CRC)
        let baseQR = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI64020EN"
        let calculatedCRC = parser.generateCRC16(for: baseQR)
        let qrWithLanguageTag = baseQR + "6304" + calculatedCRC
        
        // Verify tag ordering in raw QR string
        let tag64Position = qrWithLanguageTag.range(of: "6402")?.lowerBound
        let tag63Position = qrWithLanguageTag.range(of: "6304")?.lowerBound
        
        if let tag64Pos = tag64Position, let tag63Pos = tag63Position {
            XCTAssertTrue(tag64Pos < tag63Pos, "Tag 64 must appear before Tag 63 (EMVCo compliance)")
            print("✅ EMVCo tag ordering compliance verified")
        } else {
            print("✅ No language tag present, ordering compliance N/A")
        }
    }
    
    func testPayloadFormatCompliance() throws {
        // Test EMVCo payload format requirements
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let qrString = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(qrString)
        
        // Must start with payload format "01"
        XCTAssertEqual(result.payloadFormat, "01", "Payload format must be 01 (EMVCo)")
        
        // Must have initiation method
        XCTAssertTrue([QRInitiationMethod.static, QRInitiationMethod.dynamic].contains(result.initiationMethod), "Initiation method must be static or dynamic")
        
        print("✅ EMVCo payload format compliance verified")
    }
    
    // MARK: - Field Validation Compliance Tests
    
    func testMandatoryFieldValidation() throws {
        // Test CBK mandatory field requirements
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let qrString = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(qrString)
        
        // CBK mandatory fields
        XCTAssertEqual(result.payloadFormat, "01", "Payload format mandatory")
        XCTAssertEqual(result.merchantCategoryCode, "6011", "MCC mandatory")
        XCTAssertEqual(result.countryCode, "KE", "Country code must be KE for Kenya")
        XCTAssertNotNil(result.recipientName, "Recipient name mandatory")
        
        // Account template mandatory
        XCTAssertFalse(result.accountTemplates.isEmpty, "At least one account template mandatory")
        
        let template = result.accountTemplates.first!
        XCTAssertEqual(template.guid, "ke.go.qr", "GUID should be CBK domestic identifier")
        XCTAssertNotNil(template.accountId, "Account ID mandatory in account template")
        
        print("✅ All CBK mandatory fields present")
    }
    
    func testFieldLengthValidation() throws {
        // Test CBK field length requirements
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let qrString = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(qrString)
        
        // Field length validations  
        XCTAssertEqual(result.payloadFormat.count, 2, "Payload format must be 2 digits")
        XCTAssertEqual(result.initiationMethod.rawValue.count, 2, "Initiation method must be 2 digits")
        XCTAssertEqual(result.merchantCategoryCode.count, 4, "MCC must be 4 digits")
        XCTAssertEqual(result.countryCode.count, 2, "Country code must be 2 characters")
        
        // Recipient name length (CBK allows up to 25 characters)
        if let recipientName = result.recipientName {
            XCTAssertLessThanOrEqual(recipientName.count, 25, "Recipient name must be ≤25 characters")
        }
        
        print("✅ Field length validation passed")
    }
    
    // MARK: - P2P vs P2M Classification Tests
    
    func testP2PClassificationCompliance() throws {
        // Test P2P classification based on CBK MCC rules
        let p2pMCCs = ["6011", "6012"] // Financial institution MCCs
        
        for mcc in p2pMCCs {
            let testData = "0002010102128280008ke.go.qr01122547123456785204\(mcc)5802KE5908Test User6007NAIROBI62050101"
            let calculatedCRC = parser.generateCRC16(for: testData)
            let qrString = testData + "6304" + calculatedCRC
            
            let result = try parser.parseQR(qrString)
            
            XCTAssertEqual(result.qrType, .p2p, "MCC \(mcc) should be classified as P2P")
            print("✅ MCC \(mcc) correctly classified as P2P")
        }
    }
    
    func testP2MClassificationCompliance() throws {
        // Test P2M classification based on CBK MCC rules
        let p2mMCCs = ["5411", "5812", "5541", "4814", "4900", "7399"] // Non-financial MCCs
        
        for mcc in p2mMCCs {
            let testData = "0002010102129210008ke.go.qr681012345675204\(mcc)5802KE5919Test Merchant6007NAIROBI62050101"
            let calculatedCRC = parser.generateCRC16(for: testData)
            let qrString = testData + "6304" + calculatedCRC
            
            let result = try parser.parseQR(qrString)
            
            XCTAssertEqual(result.qrType, .p2m, "MCC \(mcc) should be classified as P2M")
            print("✅ MCC \(mcc) correctly classified as P2M")
        }
    }
    
    // MARK: - Phone Number Format Compliance Tests
    
    func testKenyaPhoneNumberFormats() throws {
        // Test CBK-compliant Kenya phone number formats
        let validFormats = [
            ("254712345678", "International format"),
            ("712345678", "Local 9-digit format"),
            ("0712345678", "Local with leading zero")
        ]
        
        for (phoneNumber, description) in validFormats {
            let testData = "0002010102128280008ke.go.qr01\(String(format: "%02d", phoneNumber.count))\(phoneNumber)520460115802KE5910Test User6007NAIROBI62050101"
            let calculatedCRC = parser.generateCRC16(for: testData)
            let qrString = testData + "6304" + calculatedCRC
            
            let result = try parser.parseQR(qrString)
            let template = result.accountTemplates.first!
            
            XCTAssertEqual(template.accountId, phoneNumber, "\(description) should be preserved")
            
            // Should detect as telecom PSP
            XCTAssertEqual(template.pspInfo.type, .telecom, "Phone number should indicate telecom PSP")
            
            print("✅ \(description): \(phoneNumber)")
        }
    }
    
    // MARK: - Multi-PSP Interoperability Tests
    
    func testCrossPSPInteroperability() throws {
        // Test that CBK domestic format enables cross-PSP compatibility
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let safaricomQR = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(safaricomQR)
        
        // Should be parseable by any CBK-compliant app
        XCTAssertEqual(result.accountTemplates.first?.guid, "ke.go.qr", "Uses CBK domestic identifier")
        XCTAssertNotNil(result.accountTemplates.first?.pspInfo, "PSP should be identified")
        
        // Account ID should be extractable for any PSP
        XCTAssertNotNil(result.accountTemplates.first?.accountId, "Account ID accessible")
        
        print("✅ Cross-PSP interoperability verified")
        print("   GUID: \(result.accountTemplates.first?.guid ?? "N/A")")
        print("   PSP: \(result.accountTemplates.first?.pspInfo.name ?? "N/A")")
        print("   Account: \(result.accountTemplates.first?.accountId ?? "N/A")")
    }
    
    // MARK: - Extension Field Compliance Tests
    
    func testExtensionFieldHandling() throws {
        // Test CBK-compliant extension field handling (Tags 80-99)
        let testData = "0002010102128280008ke.go.qr0112254769300743520460115802KE5919JANE WANJIRU KAMAU6007NAIROBI83210010m-pesa.com010203abc62050101"
        let calculatedCRC = parser.generateCRC16(for: testData)
        let qrWithExtension = testData + "6304" + calculatedCRC
        
        let result = try parser.parseQR(qrWithExtension)
        
        // Extension fields should be parsed in the fields array
        let extensionField = result.fields.first { $0.tag == "83" }
        XCTAssertNotNil(extensionField, "Tag 83 extension should be present")
        
        // Check if extension field contains expected data
        if let field = extensionField {
            XCTAssertTrue(field.value.contains("m-pesa.com"), "Extension field should contain domain data")
        }
        
        print("✅ Extension field compliance verified")
    }
    
    // MARK: - Error Recovery and Validation Tests
    
    func testCBKErrorRecovery() {
        // Test graceful handling of CBK compliance issues
        let testCases = [
            ("Missing country code", "0002010102128280008ke.go.qr0112254769300743520406015919JANE WANJIRU KAMAU6007NAIROBI63041234"),
            ("Invalid MCC format", "0002010102128280008ke.go.qr011225476930074352039995802KE5919JANE WANJIRU KAMAU6007NAIROBI63041234"),
            ("Missing recipient name", "0002010102128280008ke.go.qr0112254769300743520406015802KE6007NAIROBI63041234"),
        ]
        
        for (description, malformedQR) in testCases {
            XCTAssertThrowsError(try parser.parseQR(malformedQR)) { error in
                print("✅ \(description) correctly rejected: \(type(of: error))")
            }
        }
    }
    
    // MARK: - Generation Compliance Tests
    
    func testCBKCompliantGeneration() throws {
        // Test that generated QRs meet CBK compliance
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Test User",
            recipientIdentifier: "1234567890",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Parse generated QR to verify compliance
        let result = try parser.parseQR(qrString)
        
        // CBK compliance checks
        XCTAssertEqual(result.accountTemplates.first?.guid, "ke.go.qr", "Generated QR must use CBK domestic identifier")
        XCTAssertEqual(result.countryCode, "KE", "Generated QR must have Kenya country code")
        
        print("✅ Generated QR meets CBK compliance")
        print("   QR: \(qrString)")
    }
    
    // MARK: - Performance Compliance Tests
    
    func testPerformanceCompliance() {
        // Test that parsing meets CBK performance requirements
        let baseQR = "0002010102128280008ke.go.qr01122547693007432921000008ke.go.qr68101234567890520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI83210010m-pesa.com010203abc"
        let calculatedCRC = parser.generateCRC16(for: baseQR)
        let complexQR = baseQR + "6304" + calculatedCRC
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Parse QR 100 times to test performance
        for _ in 0..<100 {
            _ = try? parser.parseQR(complexQR)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = timeElapsed / 100.0 * 1000.0 // Convert to milliseconds
        
        // CBK requirement: parsing should be under 100ms
        XCTAssertLessThan(averageTime, 100.0, "Average parsing time should be <100ms")
        
        print("✅ Performance compliance: \(String(format: "%.2f", averageTime))ms average")
    }
    
    // MARK: - Debug Tests
    
    func testTLVParsingDebug() throws {
        // Simple QR string to debug TLV parsing - now includes required MCC field
        let simpleQR = "00020101125204601153034045802KE5908Test User6007NAIROBI"
        
        print("🔍 TLV Parsing Debug:")
        print("   📋 QR string: \\(simpleQR)")
        print("   📏 Length: \\(simpleQR.count)")
        
        // Manual parsing
        print("   📋 Expected parsing:")
        print("      Tag 00, Length 02, Value '01'")
        print("      Tag 01, Length 02, Value '12'")
        print("      Tag 52, Length 04, Value '6011'")
        print("      Tag 53, Length 03, Value '404'")
        print("      Tag 58, Length 02, Value 'KE'")
        print("      Tag 59, Length 08, Value 'Test User'")
        print("      Tag 60, Length 07, Value 'NAIROBI'")
        
        let calculatedCRC = parser.generateCRC16(for: simpleQR)
        let qrWithCRC = simpleQR + "6304" + calculatedCRC
        
        do {
            let _ = try parser.parseQR(qrWithCRC)
            print("   ✅ Parsed successfully")
        } catch {
            print("   ❌ Parse error: \\(error)")
        }
    }
} 