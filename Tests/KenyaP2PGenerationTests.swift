import XCTest
@testable import QRCodeSDK

/// Comprehensive tests for Kenya P2P QR code generation
/// Covers CBK-compliant format for banks and telecoms
public class KenyaP2PGenerationTests: XCTestCase {
    
    var generator: EnhancedQRGenerator!
    var sdk: QRCodeSDK!
    
    override public func setUp() {
        super.setUp()
        generator = EnhancedQRGenerator()
        sdk = QRCodeSDK.shared
    }
    
    override public func tearDown() {
        generator = nil
        sdk = nil
        super.tearDown()
    }
    
    // MARK: - Bank P2P Generation Tests (CBK Format)
    
    func testEquityBankP2PGenerationCBKFormat() throws {
        // Test Equity Bank P2P QR generation using CBK domestic format
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011", // Financial institution
            recipientName: "John Doe",
            recipientIdentifier: "1234567890",
            currency: "404", // KES
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify CBK domestic format structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("681234567890"), "Should contain PSP ID 68 + account number")
        XCTAssertTrue(qrString.contains("6011"), "Should contain P2P MCC")
        XCTAssertTrue(qrString.contains("404"), "Should contain KES currency code")
        
        // Verify EMVCo compliance
        XCTAssertTrue(qrString.hasPrefix("000201"), "Should start with payload format 01")
        XCTAssertTrue(qrString.contains("010211"), "Should be static QR")
        XCTAssertTrue(qrString.hasSuffix("6304"), "Should end with CRC tag and length")
        
        print("✅ Equity Bank CBK P2P QR: \(qrString)")
    }
    
    func testKCBBankP2PGenerationCBKFormat() throws {
        // Test KCB Bank P2P QR generation using CBK domestic format
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "KCBK", accountNumber: "9876543210") else {
            XCTFail("Failed to create KCB account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Jane Smith",
            recipientIdentifier: "9876543210",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify CBK domestic format structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("019876543210"), "Should contain PSP ID 01 + account number")
        
        print("✅ KCB Bank CBK P2P QR: \(qrString)")
    }
    
    func testCooperativeBankP2PGenerationCBKFormat() throws {
        // Test Co-operative Bank P2P QR generation
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "COOP", accountNumber: "5555666677") else {
            XCTFail("Failed to create Co-operative Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Coop Member",
            recipientIdentifier: "5555666677",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify CBK domestic format structure  
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("115555666677"), "Should contain PSP ID 11 + account number")
        
        print("✅ Co-operative Bank CBK P2P QR: \(qrString)")
    }
    
    // MARK: - Telecom P2P Generation Tests (CBK Format)
    
    func testMPesaP2PGenerationCBKFormat() throws {
        // Test M-PESA P2P QR generation using CBK domestic format
        guard let template = AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254712345678") else {
            XCTFail("Failed to create M-PESA account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "M-PESA User",
            recipientIdentifier: "254712345678",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify CBK domestic format structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("01254712345678"), "Should contain PSP ID 01 + phone number")
        XCTAssertTrue(qrString.contains("2828"), "Should use Tag 28 for telecom")
        
        print("✅ M-PESA CBK P2P QR: \(qrString)")
    }
    
    func testAirtelMoneyP2PGenerationCBKFormat() throws {
        // Test Airtel Money P2P QR generation
        guard let template = AccountTemplateBuilder.kenyaTelecom(guid: "AMNY", phoneNumber: "254788999888") else {
            XCTFail("Failed to create Airtel Money account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Airtel User",
            recipientIdentifier: "254788999888",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify CBK domestic format structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("02254788999888"), "Should contain PSP ID 02 + phone number")
        
        print("✅ Airtel Money CBK P2P QR: \(qrString)")
    }
    
    // MARK: - Dynamic P2P Generation Tests
    
    func testDynamicP2PWithAmount() throws {
        // Test dynamic P2P QR with pre-filled amount
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1111222233") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .dynamic,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            amount: Decimal(string: "500.00"),
            recipientName: "Amount Test",
            recipientIdentifier: "1111222233",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify dynamic QR structure
        XCTAssertTrue(qrString.contains("010212"), "Should be dynamic QR (12)")
        XCTAssertTrue(qrString.contains("5406500.00"), "Should contain amount Tag 54")
        
        print("✅ Dynamic P2P with amount: \(qrString)")
    }
    
    // MARK: - Multi-PSP Generation Tests
    
    func testMultiPSPP2PGeneration() throws {
        // Test P2P QR with multiple PSP options
        guard let equityTemplate = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890"),
              let mpesaTemplate = AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254712345678") else {
            XCTFail("Failed to create account templates")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [equityTemplate, mpesaTemplate],
            merchantCategoryCode: "6011",
            recipientName: "Multi PSP User",
            recipientIdentifier: "1234567890",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Should contain both bank and telecom templates
        XCTAssertTrue(qrString.contains("2828"), "Should contain Tag 28 for telecom")
        XCTAssertTrue(qrString.contains("2929"), "Should contain Tag 29 for bank")
        
        print("✅ Multi-PSP P2P QR: \(qrString)")
    }
    
    // MARK: - Legacy Format Generation Tests
    
    func testLegacyEquityP2PGeneration() throws {
        // Test legacy Equity Bank format for backward compatibility
        guard let template = AccountTemplateBuilder.kenyaBankLegacy(guid: "EQLT", accountNumber: "legacy123") else {
            XCTFail("Failed to create legacy Equity Bank template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Legacy User",
            recipientIdentifier: "legacy123",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2P-KE-LEGACY"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Should use PSP-specific GUID instead of CBK format
        XCTAssertTrue(qrString.contains("EQLT"), "Should use legacy EQLT GUID")
        XCTAssertFalse(qrString.contains("ke.go.qr"), "Should not use CBK domestic identifier")
        
        print("✅ Legacy Equity P2P QR: \(qrString)")
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidBankGUIDError() {
        // Test error handling for invalid bank GUID
        XCTAssertNil(AccountTemplateBuilder.kenyaBank(guid: "INVALID", accountNumber: "123456"))
    }
    
    func testInvalidTelecomGUIDError() {
        // Test error handling for invalid telecom GUID
        XCTAssertNil(AccountTemplateBuilder.kenyaTelecom(guid: "INVALID", phoneNumber: "254712345678"))
    }
    
    func testMissingAccountNumberError() {
        // Test error handling for missing account number
        let template = AccountTemplate(
            tag: "29",
            guid: "ke.go.qr",
            participantId: "68",
            accountId: nil,
            pspInfo: PSPInfo(type: .bank, identifier: "68", name: "Equity Bank", country: .kenya)
        )
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Test User",
            recipientIdentifier: "",
            currency: "404",
            countryCode: "KE"
        )
        
        // Should handle gracefully - PSP ID should still be included
        XCTAssertNoThrow(try generator.generateQRString(from: request))
    }
    
    // MARK: - CRC Validation Tests
    
    func testCRCValidationP2PGeneration() throws {
        // Test that generated QR codes have valid CRC
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "9999888877") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "CRC Test",
            recipientIdentifier: "9999888877",
            currency: "404",
            countryCode: "KE"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Parse the QR to validate CRC
        let parser = EnhancedQRParser()
        XCTAssertNoThrow(try parser.parseQR(qrString), "Generated QR should have valid CRC")
        
        print("✅ CRC validation passed for: \(qrString)")
    }
    
    // MARK: - Performance Tests
    
    func testP2PGenerationPerformance() {
        // Test P2P generation performance
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "performance123") else {
            XCTFail("Failed to create account template for performance test")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Performance Test",
            recipientIdentifier: "performance123",
            currency: "404",
            countryCode: "KE"
        )
        
        measure {
            _ = try? generator.generateQRString(from: request)
        }
    }
} 