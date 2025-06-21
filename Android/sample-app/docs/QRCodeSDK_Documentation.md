# QRCodeSDK - Complete Documentation

## Overview

The QRCodeSDK is a comprehensive cross-platform library for generating and parsing EMVCo-compliant QR codes for Kenya and Tanzania payment systems. It supports both Person-to-Person (P2P) and Person-to-Merchant (P2M) transactions with full compliance to local standards.

### Key Features

- **Multi-Country Support**: Kenya (CBK Standard) and Tanzania (TANQR Standard)
- **EMVCo Compliance**: Full EMVCo QR Code specification compliance
- **Dual QR Types**: P2P (Person-to-Person) and P2M (Person-to-Merchant)
- **Multi-PSP Support**: Single QR code supporting multiple payment providers
- **Enhanced Validation**: Comprehensive validation with error recovery suggestions
- **Visual Customization**: Professional QR branding with logo integration
- **Legacy Compatibility**: Backward compatibility with existing implementations

## Architecture

### Core Components

1. **QRCodeSDK** - Main entry point and API facade
2. **EnhancedQRGenerator** - EMVCo-compliant QR generation
3. **EnhancedQRParser** - Multi-format QR parsing with validation
4. **PSPDirectory** - Payment Service Provider information
5. **QRBrandingEngine** - Visual customization and branding

### Data Models

```swift
// Main QR generation request
public struct QRCodeGenerationRequest {
    public let qrType: QRType                    // .p2p or .p2m
    public let initiationMethod: QRInitiationMethod  // .static or .dynamic
    public let accountTemplates: [AccountTemplate]  // Payment providers
    public let merchantCategoryCode: String      // MCC code
    public let amount: Decimal?                  // Transaction amount
    public let recipientName: String?            // Recipient/merchant name
    public let recipientIdentifier: String?      // Account/phone number
    public let recipientCity: String?            // Merchant city
    public let currency: String                  // Currency code
    public let countryCode: String               // Country code
    public let additionalData: AdditionalData?   // Additional fields
    public let formatVersion: String?            // Format version
}

// Parsed QR code result
public struct ParsedQRCode {
    public let qrType: QRType
    public let fields: [TLVField]
    public let accountTemplates: [AccountTemplate]
    public let amount: Decimal?
    public let recipientName: String?
    // ... other fields
}
```

## Kenya Implementation

### CBK Standard Support

The SDK supports the Central Bank of Kenya (CBK) QR Code Standard 2023 with full compliance.

#### P2P (Person-to-Person) Format

**Proprietary Bank Format** - Used for internal bank transfers:
```
Tag 29: 0002EQLT010D2040881022296
        ↳ 0002: Bank identifier prefix
        ↳ EQLT: 4-character bank code
        ↳ 01: Sub-tag for account
        ↳ 0D: Length (13 characters)
        ↳ 2040881022296: Account number
```

**Example P2P Generation:**
```swift
let sdk = QRCodeSDK.shared

// Generate Equity Bank P2P QR
let qrImage = try sdk.generateKenyaBankQR(
    bankGUID: "EQLT",
    recipientName: "John Doe",
    accountNumber: "2040881022296",
    amount: 1000.00,
    isStatic: false
)

// Generate M-PESA P2P QR
let mpesaQR = try sdk.generateKenyaTelecomQR(
    telecomGUID: "MPESA",
    recipientName: "Jane Smith",
    phoneNumber: "254712345678",
    amount: 500.00
)
```

#### P2M (Person-to-Merchant) Format

**CBK Domestic Format** - Used for merchant payments:
```
Tag 29: 0008ke.go.qr680722266655
        ↳ 00: GUID sub-tag
        ↳ 08: Length
        ↳ ke.go.qr: CBK domestic identifier
        ↳ 68: PSP identifier sub-tag
        ↳ 07: Length
        ↳ 2226665: Numeric PSP identifier
```

**Example P2M Generation:**
```swift
// Create merchant account template
let template = AccountTemplate(
    tag: "29",
    guid: "ke.go.qr",
    participantId: "2226665", // Equity Bank PSP ID
    accountId: nil,
    pspInfo: PSPInfo(type: .bank, identifier: "2226665", name: "Equity Bank", country: .kenya)
)

let request = QRCodeGenerationRequest(
    qrType: .p2m,
    initiationMethod: .static,
    accountTemplates: [template],
    merchantCategoryCode: "5411", // Grocery store
    amount: nil, // Static QR
    recipientName: "Thika Vivian Stores",
    recipientCity: "Thika",
    currency: "404", // KES
    countryCode: "KE"
)

let merchantQR = try sdk.generateQR(from: request)
```

### Kenya PSP Directory

#### Banks (Tag 29)
```swift
let kenyaBanks = [
    "KCBL": "KCB Bank Kenya Limited",
    "EQLT": "Equity Bank Kenya Limited", 
    "SCBK": "Standard Chartered Bank Kenya Limited",
    "ABSA": "ABSA Bank Kenya PLC",
    "COOP": "Co-operative Bank of Kenya Limited",
    "STAN": "Stanbic Bank Kenya Limited",
    "DIAM": "Diamond Trust Bank Kenya Limited",
    "IMBA": "I&M Bank Limited",
    "FAMI": "Family Bank Limited",
    "NCBA": "NCBA Bank Kenya PLC"
    // ... 40+ total banks
]
```

#### Mobile Money (Tag 28) 
```swift
let kenyaTelecoms = [
    "MPESA": "Safaricom M-PESA",
    "AIRTL": "Airtel Money Kenya",
    "TKOM": "Telkom T-Kash",
    "PESP": "PesaPal"
]
```

### Multi-PSP QR Generation

```swift
// Generate QR supporting both bank and mobile money
let multiQR = try sdk.generateMultiPSPQR(
    recipientName: "John Doe",
    recipientIdentifier: "254712345678",
    bankGUID: "EQLT",        // Equity Bank option
    telecomGUID: "MPESA",    // M-PESA option
    amount: 1500.00,
    purpose: "Payment for goods"
)
```

## Tanzania Implementation

### TANQR Standard Support

The SDK supports the Bank of Tanzania TANQR Standard 2022 with TIPS (Tanzania Instant Payment System) integration.

#### Unified Format (Tag 26)

All Tanzania QR codes use Tag 26 with TIPS routing:
```
Tag 26: 0012tz.go.bot.tips010501032021512345
        ↳ 00: GUID sub-tag
        ↳ 12: Length
        ↳ tz.go.bot.tips: TIPS identifier
        ↳ 01: Acquirer ID sub-tag
        ↳ 05: Length
        ↳ 01032: Acquirer ID (01=bank, 032=ABSA)
        ↳ 02: Merchant ID sub-tag
        ↳ 15: Length
        ↳ 12345: Merchant identifier
```

**Example Tanzania Generation:**
```swift
let tanzaniaQR = try sdk.generateTanzaniaQR(
    recipientName: "Duka la Mama",
    merchantId: "12345",
    pspCode: "01032", // ABSA Bank Tanzania
    amount: 50000.00, // TZS
    isStatic: false
)
```

### Tanzania PSP Directory

#### Banks (01xxx format)
```swift
let tanzaniaBanks = [
    "01001": "National Microfinance Bank PLC",
    "01002": "CRDB Bank PLC", 
    "01003": "Stanbic Bank Tanzania Limited",
    "01010": "Akiba Commercial Bank PLC",
    "01032": "ABSA Bank Tanzania Limited",
    "01040": "Exim Bank Tanzania Limited",
    "01050": "Bank of Africa Tanzania Limited",
    "01055": "Equity Bank Tanzania Limited",
    "01060": "Standard Chartered Bank Tanzania Limited"
    // ... 29 total banks
]
```

#### Mobile Money (02xxx format)
```swift
let tanzaniaMobileMoney = [
    "02001": "Vodacom M-PESA Tanzania",
    "02002": "Airtel Money Tanzania", 
    "02003": "Tigo Pesa",
    "02004": "Halotel Pesa",
    "02005": "TTCL Pesa"
]
```

## QR Code Parsing

### Enhanced Parser Usage

```swift
let sdk = QRCodeSDK.shared

// Parse any QR code (auto-detects format)
let parsedQR = try sdk.parseQR(qrString)

// Get detailed validation
let validation = sdk.validateQR(qrString)
if !validation.isValid {
    for error in validation.errors {
        print("Error: \(error.localizedDescription)")
        print("Suggestion: \(error.recoverySuggestion)")
    }
}

// Access parsed data
print("QR Type: \(parsedQR.qrType.displayName)")
print("Country: \(parsedQR.countryCode)")
print("Amount: \(parsedQR.amount ?? 0)")
print("Recipient: \(parsedQR.recipientName ?? "Unknown")")

// Access PSP information
for template in parsedQR.accountTemplates {
    print("PSP: \(template.pspInfo.name)")
    print("Type: \(template.pspInfo.type.displayName)")
}
```

### Validation Features

The parser provides comprehensive validation with recovery suggestions:

```swift
public enum ValidationError: Error {
    case missingRequiredField(String)
    case invalidFieldValue(String, String)
    case invalidChecksum
    case unknownPSP(String)
    case malformedData
    case unsupportedVersion
    case invalidCountry(String)
    case currencyMismatch(String, String)
    case emvCoComplianceError(String)
    
    // Each error provides recovery suggestions
    public var recoverySuggestion: String { ... }
}
```

## Merchant Category Codes (MCC)

### P2P vs P2M Classification

```swift
// P2P MCCs (Financial Services)
let p2pMCCs = ["6011", "6012", "6051", "6211", "6540"]

// Common P2M MCCs
let merchantMCCs = [
    "5411": "Grocery Stores, Supermarkets",
    "5812": "Eating Places, Restaurants", 
    "5814": "Fast Food Restaurants",
    "5912": "Drug Stores and Pharmacies",
    "5541": "Service Stations",
    "4111": "Local/Suburban Transportation",
    "8011": "Doctors",
    "8062": "Hospitals"
    // ... 80+ categories
]
```

### MCC Validation

```swift
let categories = MerchantCategories.shared

// Validate MCC
if categories.isValidMCC("5411") {
    let category = categories.getMerchantCategory(mcc: "5411")
    print(category?.description) // "Grocery Stores, Supermarkets"
}

// Determine transaction type
let isP2P = categories.isP2P(mcc: "6011") // true
let isP2M = categories.isP2P(mcc: "5411") // false
```

## Visual Customization & Branding

### QR Code Styling

```swift
// Create custom style
let style = QRCodeStyle(
    size: CGSize(width: 300, height: 300),
    foregroundColor: .red,           // Equity Bank red
    backgroundColor: .white,
    errorCorrectionLevel: .high,
    logo: equityLogo,               // Bank logo
    logoSize: CGSize(width: 60, height: 60),
    cornerRadius: 8,
    borderWidth: 2,
    borderColor: .red
)

// Generate branded QR
let brandedQR = try sdk.generateQR(from: request, style: style)
```

### Pre-configured Bank Themes

```swift
// Equity Bank theme
let equityStyle = QRCodeStyle.equityBank()

// KCB theme  
let kcbStyle = QRCodeStyle.kcbBank()

// Standard Chartered theme
let scStyle = QRCodeStyle.standardChartered()
```

## Error Handling

### Generation Errors

```swift
public enum QRGenerationError: Error {
    case invalidInputData
    case qrGenerationFailed
    case imageRenderingFailed
    case invalidConfiguration(String)
    case missingRequiredField(String)
    
    public var localizedDescription: String { ... }
}
```

### Usage Example with Error Handling

```swift
do {
    let qrImage = try sdk.generateKenyaBankQR(
        bankGUID: "EQLT",
        recipientName: "John Doe", 
        accountNumber: "1234567890"
    )
    // Use qrImage
} catch QRGenerationError.invalidConfiguration(let message) {
    print("Configuration error: \(message)")
} catch QRGenerationError.missingRequiredField(let field) {
    print("Missing required field: \(field)")
} catch {
    print("Generation failed: \(error)")
}
```

## Advanced Features

### CRC16 Validation

The SDK implements CBK-compliant CRC16 validation:

```swift
// Generate CRC16 for QR data
let crc = sdk.generateCRC16(for: qrDataWithoutCRC)

// Validate existing QR
let validation = sdk.validateQR(qrString)
if validation.errors.contains(where: { 
    if case .invalidChecksum = $0 { return true }
    return false
}) {
    print("CRC validation failed")
}
```

### Debug and Testing

```swift
// Generate QR as string (for testing)
let qrString = try sdk.generateQRString(from: request)
print("Generated QR: \(qrString)")

// Parse with detailed field information
let (parsedQR, validation) = try sdk.parseQRWithDetails(qrString)
for field in parsedQR.fields {
    print("Tag \(field.tag): \(field.value)")
}
```

## Integration Guide

### iOS Integration

```swift
import QRCodeSDK

class PaymentViewController: UIViewController {
    @IBOutlet weak var qrImageView: UIImageView!
    
    func generatePaymentQR() {
        let sdk = QRCodeSDK.shared
        
        do {
            let qrImage = try sdk.generateKenyaBankQR(
                bankGUID: "EQLT",
                recipientName: "Merchant Name",
                accountNumber: "1234567890",
                amount: 1000.00
            )
            
            DispatchQueue.main.async {
                self.qrImageView.image = qrImage
            }
        } catch {
            // Handle error
            showError(error.localizedDescription)
        }
    }
}
```

### Android Equivalent Structure

For Android implementation, the equivalent structure would be:

```kotlin
// Main SDK class
class QRCodeSDK {
    companion object {
        val shared = QRCodeSDK()
    }
    
    // Generate Kenya bank QR
    fun generateKenyaBankQR(
        bankGUID: String,
        recipientName: String,
        accountNumber: String,
        amount: BigDecimal? = null,
        isStatic: Boolean = true
    ): Bitmap
    
    // Generate Tanzania QR
    fun generateTanzaniaQR(
        recipientName: String,
        merchantId: String,
        pspCode: String,
        amount: BigDecimal? = null,
        isStatic: Boolean = true
    ): Bitmap
    
    // Parse QR code
    fun parseQR(qrString: String): ParsedQRCode
    
    // Validate QR code
    fun validateQR(qrString: String): QRValidationResult
}
```

## Testing and Validation

### Test QR Codes

**Kenya P2M (CBK Standard):**
```
00020101021129230008ke.go.qr680722266655204541153034045802KE5919Thika Vivian Stores6002KE61020082310008ke.go.qr011511062025T1259066304AA94
```

**Kenya P2P (Proprietary):**
```
000201010211292900020002EQLT010D20408810222965204601153034045802KE5908John Doe6012254712345678622708Payment6304XXXX
```

**Tanzania (TANQR):**
```
00020101021126360012tz.go.bot.tips010501032021512345520459995303834580254135914Duka la Mama6006Dodoma6304XXXX
```

### Validation Checklist

- [ ] CRC16 validation passes
- [ ] EMVCo tag ordering (Tag 64 before Tag 63)
- [ ] Country-specific PSP validation
- [ ] MCC classification (P2P vs P2M)
- [ ] Currency code validation
- [ ] Template structure validation
- [ ] Character encoding (UTF-8)
- [ ] Field length limits

## Performance Specifications

- **Generation Speed**: < 500ms average
- **Parsing Speed**: < 100ms average  
- **Memory Usage**: < 10MB peak
- **QR Scan Success Rate**: > 95%
- **Error Correction**: Up to 30% damage recovery
- **Supported QR Sizes**: 150x150 to 1000x1000 pixels

## Version Information

- **SDK Version**: 2.0.0
- **CBK Standard**: 2023 Compliance
- **TANQR Standard**: 2022 Compliance
- **EMVCo Version**: QR Code Specification v1.1
- **Platform Support**: iOS 13+, Android 7+ (API 24+)

## Support and Troubleshooting

### Common Issues

1. **"Unknown PSP" Error**: Update PSP directory or verify GUID
2. **CRC Validation Failed**: Check data integrity and encoding
3. **Invalid MCC**: Use 4-digit numeric MCC codes
4. **Template Structure Error**: Verify tag usage for country
5. **Amount Format Error**: Use decimal format with 2 decimal places

### Debug Logging

Enable debug logging for troubleshooting:

```swift
// Enable debug mode
QRCodeSDK.shared.debugMode = true

// Check SDK features
let features = QRCodeSDK.shared.features
print("Supported features: \(features)")

// Get SDK version
print("SDK Version: \(QRCodeSDK.shared.version)")
```

This documentation provides comprehensive coverage of both Kenya and Tanzania QR code generation and parsing capabilities, including all the technical details needed for Android implementation. 