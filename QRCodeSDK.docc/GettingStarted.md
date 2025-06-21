# Getting Started with QRCode SDK

Learn how to integrate and use the QRCode SDK in your iOS application for payment QR code generation and parsing.

## Overview

QRCode SDK is a comprehensive payment QR code solution designed specifically for Kenya (KE-QR) and Tanzania (TAN-QR) payment standards. The SDK provides full EMVCo compliance, advanced branding capabilities, and enterprise-grade security.

## Installation

### Swift Package Manager (Recommended)

Add QRCode SDK to your project using Xcode:

1. Open your project in Xcode
2. Go to `File` → `Add Package Dependencies`
3. Enter the repository URL: `https://github.com/yourusername/QRCodeSDK.git`
4. Select the version and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/QRCodeSDK.git", from: "1.0.0")
]
```

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'QRCodeSDK', '~> 1.0'
```

Then run:
```bash
pod install
```

## Quick Start

### Import the SDK

```swift
import QRCodeSDK
```

### Initialize the SDK

The SDK uses a shared instance for easy access:

```swift
let sdk = QRCodeSDK.shared
```

### Generate Your First QR Code

#### Kenya P2P QR Code

```swift
do {
    let qrImage = try sdk.generateKenyaP2PQR(
        phoneNumber: "254712345678",
        amount: 1000.00,
        recipientName: "John Doe"
    )
    
    // Display the QR code in your UI
    imageView.image = qrImage
} catch {
    print("Error generating QR: \(error)")
}
```

#### Kenya P2M (Merchant) QR Code

```swift
do {
    let qrImage = try sdk.generateKenyaMerchantQR(
        merchantId: "12345",
        merchantName: "Coffee Shop",
        amount: 250.00,
        merchantCategoryCode: "5814" // Restaurants
    )
    
    imageView.image = qrImage
} catch {
    print("Error generating merchant QR: \(error)")
}
```

### Parse an Existing QR Code

```swift
let qrString = "00020101021126580014ke.go.qr0105688880252545410005303404540710.005802KE5913Alice Wanjiku6007Nairobi6304A1B2"

do {
    let parsedQR = try sdk.parseQRCode(qrString)
    
    print("Recipient: \(parsedQR.recipientName ?? "Unknown")")
    print("Amount: \(parsedQR.amount?.description ?? "Not specified")")
    print("Currency: \(parsedQR.currency)")
    print("Country: \(parsedQR.countryCode)")
    print("PSP: \(parsedQR.pspInfo?.name ?? "Unknown")")
} catch {
    print("Error parsing QR: \(error)")
}
```

## Advanced Usage

### Custom QR Generation

For more control over QR generation, use the advanced API:

```swift
// Create account template
let template = AccountTemplateBuilder.kenyaTelecom(
    guid: "MPESA", 
    phoneNumber: "254712345678"
)!

// Create generation request
let request = QRCodeGenerationRequest(
    qrType: .p2p,
    initiationMethod: .static,
    accountTemplates: [template],
    merchantCategoryCode: "6011",
    recipientName: "Alice Wanjiku",
    currency: "404", // KES
    countryCode: "KE"
)

// Generate QR code
do {
    let qrImage = try sdk.generateQRCode(from: request)
    imageView.image = qrImage
} catch {
    print("Error: \(error)")
}
```

### Branded QR Codes

Create professional branded QR codes:

```swift
// Create logo configuration
let logo = QRLogo(
    image: UIImage(named: "company_logo")!,
    position: .center,
    size: .medium,
    style: .overlay
)

// Create branding configuration
let branding = QRBranding(
    logo: logo,
    colorScheme: .equityBank, // Pre-defined bank scheme
    errorCorrectionLevel: .high
)

// Generate branded QR
do {
    let brandedQR = try sdk.generateBrandedQRCode(
        from: request,
        branding: branding
    )
    imageView.image = brandedQR
} catch {
    print("Error: \(error)")
}
```

### Using Bank Templates

Use pre-configured bank templates:

```swift
// Equity Bank style
let equityStyle = QRCodeStyle.equityBrand
let equityQR = try sdk.generateQRCode(from: request, style: equityStyle)

// Banking style
let bankingStyle = QRCodeStyle.banking
let bankQR = try sdk.generateQRCode(from: request, style: bankingStyle)

// Custom style
let customStyle = QRCodeStyle(
    size: CGSize(width: 400, height: 400),
    foregroundColor: .black,
    backgroundColor: .white,
    errorCorrectionLevel: .high,
    cornerRadius: 12,
    borderWidth: 2,
    borderColor: .systemBlue
)
```

## Supported Banks and PSPs

### Kenya (40+ Banks, 4+ Mobile Money)

#### Banks
- Equity Bank (EQLT)
- Kenya Commercial Bank (KCBL)
- Co-operative Bank (COOP)
- Standard Chartered (SCBK)
- ABSA Bank (ABSA)
- And 35+ more...

#### Mobile Money
- Safaricom M-PESA (MPESA)
- Airtel Money (AIRTL)
- Telkom T-Kash (TKOM)
- PesaPal (PEPL)

### Tanzania (30+ PSPs)

All major Tanzanian banks and mobile money operators with official PSP codes.

## Error Handling

The SDK provides comprehensive error handling:

```swift
do {
    let qrImage = try sdk.generateKenyaP2PQR(
        phoneNumber: "invalid",
        amount: 1000.00,
        recipientName: "Test"
    )
} catch QRGenerationError.invalidInputData {
    // Handle invalid input
    showAlert("Please check your input data")
} catch QRGenerationError.invalidConfiguration(let message) {
    // Handle configuration issues
    showAlert("Configuration error: \(message)")  
} catch ValidationError.invalidFieldValue(let field, let value) {
    // Handle validation errors
    showAlert("Invalid \(field): \(value)")
} catch {
    // Handle other errors
    showAlert("Unexpected error: \(error.localizedDescription)")
}
```

## Validation

Validate QR codes before using them:

```swift
let result = sdk.validateQRCode(qrString)

if result.isValid {
    // QR is valid, proceed with parsing
    let parsedQR = try sdk.parseQRCode(qrString)
} else {
    // Handle validation errors
    for error in result.errors {
        print("Error: \(error)")
    }
    
    for warning in result.warnings {
        print("Warning: \(warning)")
    }
}
```

## Production Considerations

### Performance

The SDK is optimized for production use:

- QR Generation: <500ms (including branding)
- QR Parsing: <100ms (complex structures)
- Memory efficient with automatic cleanup
- Thread-safe operations

### Security

Built-in security features:

- Rate limiting (60 operations/minute)
- Input sanitization
- Secure memory management
- Timing attack protection

### Monitoring

Enable production monitoring:

```swift
// Configure production settings
var config = ProductionManager.Configuration()
config.environment = .production
config.enableTelemetry = true
config.enableHealthChecks = true

ProductionManager.shared.configuration = config

// Monitor system health
let health = ProductionManager.shared.getSystemHealth()
print("Memory usage: \(health.memoryUsage.usagePercentage)%")
```

## Next Steps

- [Advanced Features](AdvancedFeatures.md): Explore branding, multi-PSP QRs, and analytics
- [API Reference](APIReference.md): Complete API documentation
- [Banking Integration](BankingIntegration.md): Bank-specific integration guides
- [Security Guide](Security.md): Security best practices
- [Troubleshooting](Troubleshooting.md): Common issues and solutions 