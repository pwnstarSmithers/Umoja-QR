import XCTest
@testable import QRCodeSDK

/// Comprehensive tests for Kenya P2M (Person-to-Merchant) QR code generation
/// Covers merchant payments across different categories and PSPs
public class KenyaP2MGenerationTests: XCTestCase {
    
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
    
    // MARK: - Bank P2M Generation Tests
    
    func testEquityBankMerchantQRGeneration() throws {
        // Test Equity Bank merchant QR generation
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "2266655") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "5411", // Grocery stores
            recipientName: "Thika Vivian Stores",
            recipientIdentifier: "2266655",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2M-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify P2M merchant structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("682266655"), "Should contain PSP ID 68 + merchant account")
        XCTAssertTrue(qrString.contains("5411"), "Should contain grocery store MCC")
        XCTAssertTrue(qrString.contains("Thika Vivian Stores"), "Should contain merchant name")
        
        // Verify EMVCo compliance
        XCTAssertTrue(qrString.hasPrefix("000201"), "Should start with payload format 01")
        XCTAssertTrue(qrString.contains("010211"), "Should be static QR")
        
        print("✅ Equity Bank merchant QR: \(qrString)")
    }
    
    func testKCBBankRestaurantQRGeneration() throws {
        // Test KCB Bank restaurant merchant QR
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "KCBK", accountNumber: "REST123456") else {
            XCTFail("Failed to create KCB account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "5812", // Eating places & restaurants
            recipientName: "Java House Westlands",
            recipientIdentifier: "REST123456",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2M-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify restaurant merchant structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("01REST123456"), "Should contain PSP ID 01 + merchant account")
        XCTAssertTrue(qrString.contains("5812"), "Should contain restaurant MCC")
        XCTAssertTrue(qrString.contains("Java House"), "Should contain merchant name")
        
        print("✅ KCB Bank restaurant QR: \(qrString)")
    }
    
    // MARK: - Telecom P2M Generation Tests
    
    func testMPesaMerchantQRGeneration() throws {
        // Test M-PESA merchant QR generation
        guard let template = AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254712000000") else {
            XCTFail("Failed to create M-PESA account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "4814", // Fast food restaurants
            recipientName: "KFC Junction",
            recipientIdentifier: "254712000000",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2M-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify M-PESA merchant structure
        XCTAssertTrue(qrString.contains("ke.go.qr"), "Should use CBK domestic identifier")
        XCTAssertTrue(qrString.contains("01254712000000"), "Should contain PSP ID 01 + merchant phone")
        XCTAssertTrue(qrString.contains("4814"), "Should contain fast food MCC")
        XCTAssertTrue(qrString.contains("2830"), "Should use Tag 28 with length 30 for telecom")
        
        print("✅ M-PESA merchant QR: \(qrString)")
    }
    
    // MARK: - Dynamic P2M Generation Tests
    
    func testDynamicP2MWithAmount() throws {
        // Test dynamic P2M QR with pre-filled amount
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "BILL123") else {
            XCTFail("Failed to create Equity Bank account template")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .dynamic,
            accountTemplates: [template],
            merchantCategoryCode: "4900", // Utilities
            amount: Decimal(string: "2500.00"),
            recipientName: "Kenya Power",
            recipientIdentifier: "BILL123",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2M-KE-01"
        )
        
        let qrString = try generator.generateQRString(from: request)
        
        // Verify dynamic P2M structure
        XCTAssertTrue(qrString.contains("010212"), "Should be dynamic QR (12)")
        XCTAssertTrue(qrString.contains("54072500.00"), "Should contain amount Tag 54")
        XCTAssertTrue(qrString.contains("4900"), "Should contain utilities MCC")
        
        print("✅ Dynamic P2M with amount: \(qrString)")
    }
    
    // MARK: - Performance Tests
    
    func testP2MGenerationPerformance() {
        // Test P2M generation performance
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "PERF123") else {
            XCTFail("Failed to create account template for performance test")
            return
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "5812",
            recipientName: "Performance Test Merchant",
            recipientIdentifier: "PERF123",
            currency: "404",
            countryCode: "KE",
            formatVersion: "P2M-KE-01"
        )
        
        measure {
            _ = try? generator.generateQRString(from: request)
        }
    }
} 
