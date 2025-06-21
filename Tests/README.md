# QRCode SDK Test Suite

## Overview

Comprehensive unit tests for the QRCode SDK focusing on Kenya CBK (Central Bank of Kenya) standards compliance and real-world QR code compatibility.

## Test Structure

### 🇰🇪 **Kenya P2P Generation Tests** (`KenyaP2PGenerationTests.swift`)
Tests for Person-to-Person payment QR code generation:

- **Bank P2P Generation**: Equity Bank, KCB, Co-operative Bank CBK-compliant P2P QRs
- **Telecom P2P Generation**: M-PESA, Airtel Money CBK-compliant P2P QRs  
- **Dynamic P2P**: QR codes with pre-filled amounts
- **Multi-PSP P2P**: Single QR supporting multiple payment methods
- **Legacy Format**: Backward compatibility with PSP-specific GUIDs
- **Error Handling**: Invalid PSP IDs, missing data validation
- **Performance**: Generation speed under 500ms requirement
- **CRC Validation**: CBK Section 7.11 compliance

**Key Test Methods:**
- `testEquityBankP2PGenerationCBKFormat()`
- `testMPesaP2PGenerationCBKFormat()`
- `testDynamicP2PWithAmount()`
- `testMultiPSPP2PGeneration()`
- `testLegacyEquityP2PGeneration()`

### 🔍 **Kenya P2P Parsing Tests** (`KenyaP2PParsingTests.swift`)
Tests for Person-to-Person payment QR code parsing with real-world examples:

- **Real-World QR Codes**: Actual Safaricom M-PESA and Equity Bank QRs
- **CBK Format Parsing**: "ke.go.qr" domestic identifier handling
- **Legacy Format Parsing**: PSP-specific GUID backward compatibility
- **Multi-PSP Parsing**: QRs with multiple payment options
- **Extension Fields**: Tag 80-99 parsing (m-pesa.com domains)
- **Phone Number Formats**: International/local/zero-prefixed formats
- **PSP Identification**: Automatic PSP detection from phone patterns
- **Error Handling**: Malformed QRs, invalid CRC, missing fields
- **Regression Protection**: Critical QRs that must always work

**Key Test Methods:**
- `testSafaricomMPesaCBKFormatParsing()` - Real M-PESA QR that was failing
- `testEquityBankP2MQRParsing()` - Real merchant QR example
- `testMultiPSPQRParsing()`
- `testExtensionFieldParsing()`
- `testCriticalQRCodes()` - Regression protection

### 🏪 **Kenya P2M Generation Tests** (`KenyaP2MGenerationTests.swift`)
Tests for Person-to-Merchant payment QR code generation:

- **Bank P2M Generation**: Merchant account QRs for banks
- **Telecom P2M Generation**: Till numbers, paybill shortcodes
- **Merchant Categories**: 80+ MCC codes (grocery, restaurants, utilities)
- **Dynamic P2M**: QRs with pre-filled amounts for bills
- **Till Numbers**: Kenya-specific merchant till number format
- **Paybill Numbers**: Utility payment shortcode format
- **Multi-PSP Merchants**: Merchants accepting multiple payment methods
- **Merchant Information**: Name, city, postal code validation

**Key Test Methods:**
- `testEquityBankMerchantQRGeneration()`
- `testMPesaMerchantQRGeneration()`
- `testDynamicP2MWithAmount()`
- `testTillNumberGeneration()`
- `testPaybillNumberGeneration()`

### ✅ **CBK Compliance Tests** (`CBKComplianceTests.swift`)
Comprehensive Central Bank of Kenya standards compliance:

- **CBK Section 7.11**: CRC16 calculation including tag ID+Length
- **Domestic Identifier**: "ke.go.qr" mandatory for all Kenya QRs
- **PSP Directory**: Official PSP code mappings and progressive prefix matching
- **EMVCo Compliance**: Tag ordering, payload format requirements
- **Field Validation**: Mandatory fields, length limits, format validation
- **P2P vs P2M Classification**: MCC-based QR type determination
- **Phone Number Formats**: Kenya-specific phone number validation
- **Cross-PSP Interoperability**: CBK format enables universal compatibility
- **Extension Fields**: Tags 80-99 parsing compliance
- **Performance Requirements**: <100ms parsing, <500ms generation
- **Error Recovery**: Graceful handling of compliance issues

**Key Test Methods:**
- `testCRC16CalculationCBKSection7_11()` - Official CRC standard
- `testCBKDomesticIdentifierCompliance()` - Universal "ke.go.qr" usage
- `testPSPDirectoryMappingCompliance()` - Official PSP mappings
- `testCrossPSPInteroperability()` - Universal QR compatibility
- `testPerformanceCompliance()` - Speed requirements

## Real-World Test Cases

### Critical QR Codes (Regression Protection)
These QR codes **must always work** to prevent regressions:

1. **Safaricom M-PESA P2P** (was failing, now fixed):
   ```
   00020101021128280008ke.go.qr0112254769300743520406015802KE5919JANE WANJIRU KAMAU6007NAIROBI6205000016304FB5D
   ```

2. **Equity Bank P2M Merchant**:
   ```
   00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94
   ```

### Phone Number Format Support
- **International**: `254712345678`
- **Local 9-digit**: `712345678`  
- **Local with zero**: `0712345678`

### PSP Detection Patterns
- **71X/72X**: Safaricom M-PESA (PSP ID "01")
- **78X**: Airtel Money (PSP ID "02")
- **76X**: Telkom T-Kash (PSP ID "03")

## Test Categories

### 🎯 **Primary Tests**
Real-world QR codes that must always work:
- Safaricom M-PESA QRs
- Equity Bank merchant QRs  
- Multi-PSP QRs with both bank and telecom options

### 📋 **Standards Compliance**
Official standard validation:
- CBK Kenya QR Code Standard compliance
- EMVCo payment QR specification compliance
- TLV parsing and validation rules

### 🚨 **Error Handling**
Robustness and security:
- Malformed QR code rejection
- Invalid CRC detection
- Missing required field validation
- Input sanitization and rate limiting

### ⚡ **Performance**
Speed and efficiency requirements:
- QR parsing: <100ms for complex QRs
- QR generation: <500ms with branding
- Memory usage optimization
- Scan success rate: >95%

### 🔄 **Backward Compatibility**
Legacy format support:
- PSP-specific GUID formats (EQLT, KCBL, etc.)
- Legacy method availability
- Migration path validation

## Running Tests

### Command Line
```bash
# Run all tests
xcodebuild test -scheme QRCodeSDK -destination 'platform=iOS Simulator,name=iPhone 14'

# Run specific test class
xcodebuild test -scheme QRCodeSDK -destination 'platform=iOS Simulator,name=iPhone 14' -only-testing:QRCodeSDKTests/KenyaP2PParsingTests

# Run critical regression tests only
xcodebuild test -scheme QRCodeSDK -destination 'platform=iOS Simulator,name=iPhone 14' -only-testing:QRCodeSDKTests/KenyaP2PParsingTests/testCriticalQRCodes
```

### Xcode
1. Open `QRCodeTest.xcodeproj`
2. Select **Product** → **Test** (⌘U)
3. Or use Test Navigator to run specific test classes

### Performance Testing
Performance tests use XCTest's `measure` blocks:
- `testP2PGenerationPerformance()` - Generation speed
- `testParsingPerformance()` - Parsing speed  
- `testPerformanceCompliance()` - CBK speed requirements

## Test Data Sources

### Official Standards
- **CBK Kenya QR Code Standard**: CRC calculation, domestic identifier requirements
- **EMVCo QR Code Specification**: Tag ordering, payload format
- **PSP Directory**: Official bank and telecom PSP codes

### Real-World QRs
- **Safaricom M-PESA**: Actual customer QR codes
- **Equity Bank**: Merchant payment QR codes
- **Multi-PSP**: QRs supporting multiple payment methods

## Coverage Goals

- **Functionality**: 95%+ code coverage across all SDK modules
- **Standards**: Full CBK and EMVCo compliance verification
- **Real-World**: All major Kenya PSPs supported
- **Error Cases**: Comprehensive malformed input handling
- **Performance**: Sub-100ms parsing, sub-500ms generation

## Continuous Integration

Tests run automatically on:
- Every commit to main branch
- Pull request validation
- Nightly performance regression checks
- Weekly standards compliance verification

## Contributing Tests

When adding new test cases:

1. **Follow naming convention**: `test[Component][Scenario][ExpectedResult]()`
2. **Add performance tests** for new generation/parsing features
3. **Include real-world examples** when possible
4. **Document CBK/EMVCo compliance** aspects
5. **Add regression protection** for critical fixes

### Example Test Method
```swift
func testEquityBankMerchantTillParsing() throws {
    // Test specific real-world Equity Bank till QR
    let qrString = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE63041234"
    
    let result = try parser.parseQR(qrString)
    
    // Verify parsing results
    XCTAssertEqual(result.qrType, .p2m, "Should be classified as merchant payment")
    XCTAssertEqual(result.merchantCategoryCode, "5411", "Should be grocery store MCC")
    
    // Verify CBK compliance
    let template = result.accountTemplates.first!
    XCTAssertEqual(template.guid, "ke.go.qr", "Must use CBK domestic identifier")
    XCTAssertEqual(template.participantId, "68", "Must use Equity PSP ID")
    
    print("✅ Equity Bank merchant till parsing successful")
}
```

---

**Last Updated**: 2024-06-20
**SDK Version**: Phase 4 Complete (Professional Branding & Visual Customization)
**Test Coverage**: 350+ test methods across 4 comprehensive test classes 