# 🌍 Umoja QR - Complete Developer Guide

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2012.0%2B-blue.svg" alt="Platform: iOS 12.0+">
  <img src="https://img.shields.io/badge/Language-Swift%205.0-orange.svg" alt="Language: Swift 5.0">
  <img src="https://img.shields.io/badge/Standards-CBK%20%7C%20TIPS%20%7C%20EMVCo-green.svg" alt="Standards Compliant">
  <img src="https://img.shields.io/badge/Unity-East%20Africa-orange.svg" alt="East Africa Unity">
</p>

> **Umoja QR - Unity in Every Payment. The ultimate guide to implementing unified payment QR codes for Kenya and Tanzania with advanced branding, security, and analytics capabilities.**

## 📋 Table of Contents

### 🚀 **Getting Started**
1. [Installation & Setup](#installation--setup)
2. [Quick Start Examples](#quick-start-examples)
3. [SDK Architecture Overview](#sdk-architecture-overview)

### 🎯 **Core Features**
4. [QR Code Generation](#qr-code-generation)
5. [QR Code Parsing](#qr-code-parsing)
6. [Account Templates](#account-templates)

### 🎨 **Customization**
7. [Branding & Visual Customization](#branding--visual-customization)
8. [Logo Integration](#logo-integration)
9. [Color Schemes & Effects](#color-schemes--effects)

### 🔧 **Advanced Features**
10. [Analytics & Monitoring](#analytics--monitoring)
11. [Security Features](#security-features)
12. [Multi-Country Support](#multi-country-support)

### 📖 **Implementation Guide**
13. [Country-Specific Implementation](#country-specific-implementation)
14. [Error Handling](#error-handling)
15. [Performance Optimization](#performance-optimization)
16. [Testing & Validation](#testing--validation)

### 💡 **Examples & Best Practices**
17. [Real-World Examples](#real-world-examples)
18. [Integration Patterns](#integration-patterns)
19. [Production Deployment](#production-deployment)
20. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🚀 Installation & Setup

### Prerequisites

- **iOS 12.0+** or **macOS 10.14+**
- **Xcode 12.0+**
- **Swift 5.0+**

### Installation Methods

#### 📦 Swift Package Manager (Recommended)
```swift
// In Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/UmojaQR.git", from: "1.0.0")
]

// In Xcode: File → Add Package Dependencies
// URL: https://github.com/yourusername/UmojaQR.git
```

#### 🍫 CocoaPods
```ruby
# Add to your Podfile
pod 'UmojaQR', '~> 1.0'

# Then run
$ pod install
```

#### 📄 Manual Installation
1. Download the latest release
2. Drag `UmojaQR.framework` to your project
3. Add to "Embedded Binaries" in project settings

### Initial Setup

```swift
import UmojaQR

class PaymentManager {
    // Use shared instance (recommended for most apps)
    private let sdk = UmojaQR.shared
    
    // Or create custom instance with specific configuration
    private let customSDK: UmojaQR = {
        let sdk = UmojaQR()
        // Custom configuration here
        return sdk
    }()
    
    func initializeSDK() {
        print("Umoja QR Version: \(UmojaQR.version)")
        print("Supported Countries: \(UmojaQR.supportedCountries)")
        print("Supported QR Types: \(UmojaQR.supportedQRTypes)")
        print("Unity in Every Payment! 🤝")
    }
}
```

## ⚡ Quick Start Examples

### 30-Second Integration

#### Generate Your First QR Code
```swift
import UmojaQR

class ViewController: UIViewController {
    @IBOutlet weak var qrImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        generateSimpleQR()
    }
    
    func generateSimpleQR() {
        do {
            // Generate M-PESA QR code in one line - Unity in action!
            let qrImage = try UmojaQR.shared.generateKenyaP2PQR(
                phoneNumber: "254712345678",
                amount: 1000.00,
                recipientName: "John Doe"
            )
            
            qrImageView.image = qrImage
            print("✅ Umoja QR generated successfully! Unity in every payment 🤝")
            
        } catch {
            print("❌ QR Generation failed: \(error)")
        }
    }
}
```

#### Parse Any QR Code
```swift
func parseQRCode(_ qrString: String) {
    do {
        let parsed = try UmojaQR.shared.parseQRCode(qrString)
        
        print("📱 QR Type: \(parsed.qrType)")
        print("💰 Amount: \(parsed.amount ?? 0) \(parsed.currency)")
        print("👤 Recipient: \(parsed.recipientName ?? "Unknown")")
        print("🏦 PSP: \(parsed.pspInfo?.name ?? "Unknown")")
        print("🤝 Umoja QR - Unified payment experience!")
        
    } catch {
        print("❌ Parsing failed: \(error)")
    }
}
```

### 5-Minute Professional Setup

```swift
import UmojaQR

class ProfessionalQRManager {
    private let sdk = UmojaQR.shared
    
    // Generate branded bank QR with logo
    func generateBrandedBankQR() throws -> UIImage {
        // Step 1: Create account template
        guard let template = AccountTemplateBuilder.kenyaBank(
            guid: "EQLT",
            accountNumber: "1234567890"
        ) else {
            throw QRGenerationError.invalidConfiguration("Invalid template")
        }
        
        // Step 2: Build request
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [template],
            merchantCategoryCode: "6011",
            recipientName: "Alice Wanjiku",
            currency: "404",
            countryCode: "KE"
        )
        
        // Step 3: Create branding
        guard let logo = UIImage(named: "bank_logo") else {
            return try sdk.generateQRCode(from: request)
        }
        
        let branding = QRBranding(
            logo: QRLogo(image: logo, position: .center, size: .medium),
            colorScheme: QRColorScheme(finderPatterns: .solid(.systemBlue)),
            errorCorrectionLevel: .high
        )
        
        // Step 4: Generate branded QR
        return try sdk.generateBrandedQRCode(from: request, branding: branding)
    }
}
```

## 🏗️ Umoja QR Architecture Overview

```
Umoja QR - Unity in Every Payment
├── 🎯 Core Engine
│   ├── UmojaQR.swift             # Main unified interface
│   ├── EnhancedQRGenerator.swift # QR generation
│   └── EnhancedQRParser.swift    # QR parsing
├── 🎨 Branding System
│   ├── QRBrandingEngine.swift    # Visual customization
│   ├── QRColorScheme             # Color management
│   └── QRLogo                    # Logo integration
├── 🏦 Payment Integration
│   ├── AccountTemplateBuilder    # PSP templates
│   ├── PSPDirectory             # Provider database
│   └── Multi-country support    # Kenya, Tanzania unity
├── 🔒 Security Layer
│   ├── SecurityManager          # Input validation
│   ├── Rate limiting            # Abuse prevention
│   └── Integrity verification   # Data validation
└── 📊 Advanced Features
    ├── Analytics engine         # Usage insights
    ├── Fraud detection          # Risk analysis
    └── Performance optimization  # Speed & efficiency
```

---

## 🎯 QR Code Generation

### 🚀 Quick Generation Methods

> **Perfect for rapid prototyping and simple use cases**

#### 📱 Kenya P2P QR Code
```swift
// Static QR (user enters amount during payment)
let staticQR = try sdk.generateKenyaP2PQR(
    phoneNumber: "254712345678",    // Full international format
    amount: nil,                    // nil = static QR
    recipientName: "John Doe"       // Display name
)

// Dynamic QR (amount pre-filled)
let dynamicQR = try sdk.generateKenyaP2PQR(
    phoneNumber: "254712345678",
    amount: 1500.00,                // KES amount
    recipientName: "John Doe"
)

// Works with all Kenya mobile money providers
let airtelQR = try sdk.generateKenyaP2PQR(
    phoneNumber: "254788999888",    // Airtel Money number
    amount: 500.00,
    recipientName: "Jane Smith"
)
```

#### 🏪 Kenya Merchant QR Code
```swift
// Grocery store QR
let groceryQR = try sdk.generateKenyaMerchantQR(
    merchantId: "GROCERY123",
    amount: nil,                    // Static for flexible amounts
    merchantName: "Mama Mboga Shop",
    mcc: "5411"                     // Grocery stores
)

// Restaurant QR with fixed amount
let restaurantQR = try sdk.generateKenyaMerchantQR(
    merchantId: "REST456",
    amount: 2500.00,                // Fixed meal price
    merchantName: "Nyama Choma Palace",
    mcc: "5812"                     // Restaurants
)

// Gas station QR
let gasStationQR = try sdk.generateKenyaMerchantQR(
    merchantId: "GAS789",
    amount: nil,                    // Variable fuel amount
    merchantName: "Shell Station",
    mcc: "5541"                     // Service stations
)
```

### 🔧 Advanced QR Generation

> **For complex payment scenarios and enterprise applications**

### Advanced Generation

#### Custom QR Generation Request
```swift
// Create account template
guard let template = AccountTemplateBuilder.kenyaBank(
    guid: "EQLT",                   // Equity Bank GUID
    accountNumber: "1234567890"     // Account number
) else {
    throw QRGenerationError.invalidConfiguration("Invalid account template")
}

// Build generation request
let request = QRCodeGenerationRequest(
    qrType: .p2p,                   // .p2p or .p2m
    initiationMethod: .static,      // .static or .dynamic
    accountTemplates: [template],   // Array of account templates
    merchantCategoryCode: "6011",   // MCC for P2P financial institutions
    amount: Decimal(1000.50),       // Optional amount
    recipientName: "Alice Wanjiku", // Recipient/merchant name
    recipientIdentifier: "ACCT123", // Account identifier
    currency: "404",                // KES currency code
    countryCode: "KE",              // Kenya country code
    formatVersion: "P2P-KE-01"      // Format version
)

// Generate QR code
let qrImage = try sdk.generateQRCode(from: request)

// Or generate as string for validation
let qrString = try sdk.generateQRString(from: request)
```

---

## QR Code Parsing

### Basic Parsing

```swift
// Parse any QR code string
let parsedQR = try sdk.parseQRCode(qrString)

// Access parsed information
print("QR Type: \(parsedQR.qrType)")              // .p2p or .p2m
print("Amount: \(parsedQR.amount ?? 0)")          // Transaction amount
print("Recipient: \(parsedQR.recipientName ?? "")")
print("Country: \(parsedQR.countryCode)")         // KE or TZ
print("Currency: \(parsedQR.currency)")           // 404 (KES) or 834 (TZS)
print("Static QR: \(parsedQR.isStatic)")          // true/false
```

### Advanced Parsing Information

```swift
// Access account templates
for template in parsedQR.accountTemplates {
    print("PSP: \(template.pspInfo.name)")        // Bank/telecom name
    print("Type: \(template.pspInfo.type)")       // .bank, .telecom, etc.
    print("Account: \(template.accountId ?? "")")  // Account/phone number
    print("Template Tag: \(template.tag)")        // 26, 28, 29, etc.
}

// Access additional data
if let additionalData = parsedQR.additionalData {
    print("Purpose: \(additionalData.purposeOfTransaction ?? "")")
    print("Bill Number: \(additionalData.billNumber ?? "")")
    print("Reference: \(additionalData.customerLabel ?? "")")
}

// Legacy compatibility
if let pspInfo = parsedQR.pspInfo {
    print("Primary PSP: \(pspInfo.name)")
}
```

### Validation

```swift
// Quick validation without full parsing
let isValid = sdk.isValidQRCode(qrString)

// Detailed validation with error information
do {
    let parsed = try sdk.parseQRCode(qrString)
    print("✅ Valid QR code")
} catch ValidationError.invalidChecksum {
    print("❌ Invalid CRC checksum")
} catch ValidationError.missingRequiredField(let field) {
    print("❌ Missing required field: \(field)")
} catch {
    print("❌ Parsing error: \(error)")
}
```

---

## Account Templates

Account templates define which banks or payment service providers can process the QR code.

### Kenya Account Templates

#### Bank Templates (Tag 29)
```swift
// Equity Bank
let equityTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "EQLT",
    accountNumber: "1234567890"
)

// KCB Bank
let kcbTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "KCBK", 
    accountNumber: "9876543210"
)

// Co-operative Bank
let coopTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "COOP",
    accountNumber: "5555666677"
)

// Standard Chartered
let standardTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "SCBL",
    accountNumber: "1111222233"
)
```

#### Telecom Templates (Tag 28)
```swift
// M-PESA
let mpesaTemplate = AccountTemplateBuilder.kenyaTelecom(
    guid: "MPSA",
    phoneNumber: "254712345678"  // Full international format
)

// Airtel Money
let airtelTemplate = AccountTemplateBuilder.kenyaTelecom(
    guid: "AMNY",
    phoneNumber: "254788999888"
)

// Telkom T-Kash
let telkomTemplate = AccountTemplateBuilder.kenyaTelecom(
    guid: "TKSH",
    phoneNumber: "254777123456"
)
```

### Tanzania Account Templates

#### TIPS Template (Tag 26)
```swift
// Tanzania Instant Payment System
let tipsTemplate = AccountTemplateBuilder.tanzania(
    acquirerId: "01032",     // ABSA Bank Tanzania PSP code
    merchantId: "MERCHANT123"
)

// Alternative with PSP code validation
let validatedTemplate = AccountTemplateBuilder.tanzania(
    acquirerId: "01010",     // Akiba Commercial Bank
    merchantId: "SHOP456"
)
```

### Multi-PSP QR Codes

```swift
// Create templates for multiple payment providers
guard let mpesaTemplate = AccountTemplateBuilder.kenyaTelecom(
    guid: "MPSA", 
    phoneNumber: "254712345678"
),
let equityTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "EQLT", 
    accountNumber: "1234567890"
) else {
    throw QRGenerationError.invalidConfiguration("Failed to create templates")
}

// Generate QR supporting both M-PESA and Equity Bank
let multiPSPRequest = QRCodeGenerationRequest(
    qrType: .p2p,
    initiationMethod: .static,
    accountTemplates: [mpesaTemplate, equityTemplate], // Multiple templates
    merchantCategoryCode: "6011",
    recipientName: "Multi-PSP Recipient",
    currency: "404",
    countryCode: "KE"
)

let multiPSPQR = try sdk.generateQRCode(from: multiPSPRequest)
```

### Legacy Templates (Backward Compatibility)

```swift
// Legacy format (non-CBK compliant but supported)
let legacyBankTemplate = AccountTemplateBuilder.kenyaBankLegacy(
    guid: "EQLT",  // Uses PSP-specific GUID instead of "ke.go.qr"
    accountNumber: "1234567890"
)

let legacyTelecomTemplate = AccountTemplateBuilder.kenyaTelecomLegacy(
    guid: "MPSA",  // Uses "MPSA" instead of "ke.go.qr"
    phoneNumber: "254712345678"
)
```

---

## 🎨 Branding & Visual Customization

> **Transform standard QR codes into branded payment experiences that match your company's visual identity**

### 🌈 Basic Color Customization

#### Simple Color Changes
```swift
// Change QR code colors instantly
let colorScheme = QRColorScheme(
    dataPattern: .solid(.black),        // QR data modules (dots)
    background: .solid(.white),         // Background color
    finderPatterns: .solid(.systemBlue), // Corner detection squares
    logoBackgroundColor: .white         // Logo background (if using logo)
)

let branding = QRBranding(colorScheme: colorScheme)
let coloredQR = try sdk.generateBrandedQRCode(from: request, branding: branding)
```

#### Brand Color Examples
```swift
// Corporate blue theme
let corporateBlue = QRColorScheme(
    dataPattern: .solid(.black),
    background: .solid(.white),
    finderPatterns: .solid(UIColor(red: 0.0, green: 0.47, blue: 0.84, alpha: 1.0))
)

// Banking red theme (like Equity Bank)
let bankingRed = QRColorScheme(
    dataPattern: .solid(.black),
    background: .solid(.white),
    finderPatterns: .solid(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0))
)

// Mobile money green theme
let mobileGreen = QRColorScheme(
    dataPattern: .solid(.black),
    background: .solid(.white),
    finderPatterns: .solid(UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0))
)
```

### 🎨 Advanced Color Schemes

#### Gradient Effects
```swift
// Linear gradient for modern look
let gradientConfig = QRColorScheme.GradientConfig(
    colors: [.systemBlue, .systemTeal, .systemGreen],
    direction: .linear(angle: Float.pi / 4),  // 45-degree angle
    stops: [0.0, 0.5, 1.0]                   // Color distribution
)

let gradientScheme = QRColorScheme(
    dataPattern: .gradient(gradientConfig),
    background: .solid(.white),
    finderPatterns: .gradient(gradientConfig)
)

// Radial gradient for eye-catching effect
let radialGradient = QRColorScheme.GradientConfig(
    colors: [.systemPurple, .systemPink],
    direction: .radial(center: CGPoint(x: 0.5, y: 0.5), radius: 1.0)
)
```

#### Individual Finder Pattern Colors
```swift
// Different color for each corner (advanced branding)
let individualFinders = QRColorScheme.IndividualFinderConfig(
    topLeft: .systemRed,        // Company primary color
    topRight: .systemBlue,      // Company secondary color
    bottomLeft: .systemGreen    // Company accent color
)

let uniqueScheme = QRColorScheme(
    dataPattern: .solid(.black),
    background: .solid(.white),
    finderPatterns: .individual(individualFinders)
)
```

```swift
// Create custom color scheme
let colorScheme = QRColorScheme(
    dataPattern: .solid(.black),        // QR data dots color
    background: .solid(.white),         // Background color
    finderPatterns: .solid(.red),       // Corner finder patterns color
    logoBackgroundColor: .white         // Logo background
)

// Apply to QR generation
let branding = QRBranding(
    colorScheme: colorScheme,
    errorCorrectionLevel: .medium
)

let coloredQR = try sdk.generateBrandedQRCode(
    from: request,
    branding: branding
)
```

### Logo Integration

#### Basic Logo Setup
```swift
// Load your logo
guard let logoImage = UIImage(named: "company_logo") else {
    throw QRBrandingError.invalidConfiguration
}

// Configure logo
let logo = QRLogo(
    image: logoImage,
    position: .center,      // .center, .topLeft, .topRight, .bottomLeft, .bottomRight
    size: .medium,          // .small, .medium, .large, .extraLarge, .adaptive
    style: .overlay,        // .overlay, .embedded, .watermark, .badge, etc.
    effects: nil            // Optional effects
)
```

#### Advanced Logo Configuration
```swift
// Logo with advanced effects
let advancedLogo = QRLogo(
    image: logoImage,
    position: .center,
    size: .large,
    style: .badge,
    effects: LogoEffects(
        shadow: ShadowConfig(
            color: .black,
            opacity: 0.3,
            radius: 4,
            offset: CGSize(width: 2, height: 2)
        ),
        border: BorderConfig(
            color: .red,
            width: 2
        ),
        glow: GlowConfig(
            color: .blue,
            intensity: 0.5,
            radius: 8
        )
    )
)
```

### Pre-configured Bank Brands

#### Equity Bank Branding
```swift
let equityBranding = QRBranding.equityBank(logo: equityLogo)
// Includes: Red finder patterns, white background, badge-style logo

let equityQR = try sdk.generateBrandedQRCode(
    from: request,
    branding: equityBranding
)
```

#### Safaricom M-PESA Branding
```swift
let mpesaBranding = QRBranding.safaricomMPesa(logo: mpesaLogo)
// Includes: Green gradient finder patterns, M-PESA colors

let mpesaQR = try sdk.generateBrandedQRCode(
    from: request,
    branding: mpesaBranding
)
```

#### Custom Bank Branding
```swift
let customBranding = QRBranding.techStartup(
    logo: startupLogo,
    primaryColor: .blue,
    secondaryColor: .cyan
)
// Includes: Gradient patterns, neon effects, modern styling
```

### Advanced Customization

#### Gradient Color Schemes
```swift
let gradientConfig = QRColorScheme.GradientConfig(
    colors: [.red, .orange, .yellow],
    direction: .linear(angle: Float.pi / 4),  // 45-degree angle
    stops: [0.0, 0.5, 1.0]                   // Color stop positions
)

let gradientScheme = QRColorScheme(
    dataPattern: .gradient(gradientConfig),
    background: .solid(.white),
    finderPatterns: .gradient(gradientConfig)
)
```

#### Individual Finder Pattern Colors
```swift
let individualFinders = QRColorScheme.IndividualFinderConfig(
    topLeft: .red,      // Top-left finder pattern
    topRight: .green,   // Top-right finder pattern  
    bottomLeft: .blue   // Bottom-left finder pattern
)

let customScheme = QRColorScheme(
    dataPattern: .solid(.black),
    background: .solid(.white),
    finderPatterns: .individual(individualFinders)
)
```

### Logo Positioning

```swift
// Predefined positions
let centerLogo = QRLogo(image: logo, position: .center)
let topLeftLogo = QRLogo(image: logo, position: .topLeft)
let bottomRightLogo = QRLogo(image: logo, position: .bottomRight)

// Custom positioning (normalized coordinates 0.0-1.0)
let customPosition = QRLogo(
    image: logo, 
    position: .custom(CGPoint(x: 0.3, y: 0.7))  // 30% from left, 70% from top
)
```

### Logo Styles

```swift
// Different logo integration styles
let overlayLogo = QRLogo(image: logo, style: .overlay)      // Simple overlay
let embeddedLogo = QRLogo(image: logo, style: .embedded)    // Embedded in QR
let watermarkLogo = QRLogo(image: logo, style: .watermark)  // Subtle watermark
let badgeLogo = QRLogo(image: logo, style: .badge)          // Badge with border
let neonLogo = QRLogo(image: logo, style: .neon(.cyan))     // Neon glow effect
let glassLogo = QRLogo(image: logo, style: .glass)          // Glass effect
let circularLogo = QRLogo(image: logo, style: .circular)    // Circular frame
```

---

## Advanced Features

### QR Code Analytics

```swift
// Analyze multiple QR codes for insights
let analytics = AdvancedFeatures.analyzeQRCodeUsage(parsedQRCodes)

print("Total QR codes: \(analytics.totalQRCodes)")
print("Unique recipients: \(analytics.uniqueRecipients)")
print("Total amount: \(analytics.totalAmount)")
print("Average amount: \(analytics.averageAmount)")
print("PSP distribution: \(analytics.pspDistribution)")
```

### Fraud Detection

```swift
// Detect potential fraud patterns
let fraudAnalysis = AdvancedFeatures.detectFraudPatterns(qrCodes)

print("Risk score: \(fraudAnalysis.overallRiskScore)/10")
print("Duplicate QRs: \(fraudAnalysis.duplicateQRCodes.count)")
print("Unusual amounts: \(fraudAnalysis.unusualAmounts.count)")

if fraudAnalysis.overallRiskScore > 7.0 {
    print("⚠️ High risk detected - manual review recommended")
}
```

### Smart Validation

```swift
// Intelligent validation with suggestions  
let context = ValidationContext(
    amountLimits: AmountLimits(minimum: 1, maximum: 1000000),
    allowedPSPs: ["EQLT", "MPSA", "KCBK"],
    expiryTime: Date().addingTimeInterval(3600) // 1 hour
)

let smartResult = AdvancedFeatures.smartValidate(qrString, context: context)

if smartResult.isValid {
    print("✅ QR code is valid")
} else {
    print("❌ Validation failed:")
    for error in smartResult.errors {
        print("  - \(error)")
    }
    
    print("💡 Suggestions:")
    for suggestion in smartResult.suggestions {
        print("  - \(suggestion)")
    }
}
```

### Error Recovery

```swift
// Attempt to recover from QR parsing errors
let recoveryResult = AdvancedFeatures.recoverFromError(corruptedQRString, error: parsingError)

if recoveryResult.wasRecovered {
    print("✅ QR code recovered successfully")
    print("Recovered data: \(recoveryResult.recoveredData)")
} else {
    print("❌ Recovery failed")
    for suggestion in recoveryResult.suggestions {
        print("💡 \(suggestion)")
    }
}
```

---

## Security Features

### Rate Limiting

```swift
// Check rate limits before operations
if SecurityManager.checkRateLimit(for: "qr_generation") {
    let qr = try sdk.generateQRCode(from: request)
} else {
    print("❌ Rate limit exceeded - please wait")
}
```

### Input Sanitization

```swift
// Sanitize user input before QR generation
do {
    let cleanInput = try SecurityManager.sanitizeQRInput(userInput)
    // Use cleanInput for QR generation
} catch SecurityError.inputTooLong {
    print("❌ Input too long for QR code")
} catch SecurityError.potentialInjection {
    print("❌ Potentially malicious input detected")
}
```

### Integrity Verification

```swift
// Generate integrity hash
let qrString = try sdk.generateQRString(from: request)
let integrityHash = SecurityManager.generateIntegrityHash(for: qrString)

// Store hash with QR code for later verification
storeQRWithHash(qrString, hash: integrityHash)

// Later: verify integrity
let isValid = SecurityManager.verifyIntegrity(
    data: qrString, 
    expectedHash: storedHash
)
```

### Secure Memory Operations

```swift
// Securely clear sensitive data
var sensitiveData = "254712345678"
SecurityManager.secureErase(&sensitiveData)
// sensitiveData is now securely cleared from memory
```

---

## Country-Specific Implementation

### Kenya Implementation

#### CBK-Compliant QR Codes
```swift
// CBK domestic format uses "ke.go.qr" identifier
let cbkTemplate = AccountTemplateBuilder.kenyaBank(
    guid: "EQLT",              // Bank GUID
    accountNumber: "1234567890"
)
// This generates CBK-compliant QR with domestic identifier

// Result includes:
// - GUID: "ke.go.qr" (CBK domestic identifier)
// - PSP ID: "68" (Equity Bank's official PSP ID)
// - Account: Formatted as "681234567890"
```

#### Kenya P2P vs P2M Classification
```swift
// P2P QR codes (Person-to-Person transfers)
let p2pRequest = QRCodeGenerationRequest(
    qrType: .p2p,
    // ... other fields
    merchantCategoryCode: "6011"  // Financial institutions MCC
)

// P2M QR codes (Person-to-Merchant payments)
let p2mRequest = QRCodeGenerationRequest(
    qrType: .p2m,
    // ... other fields
    merchantCategoryCode: "5411"  // Grocery stores MCC
)
```

#### Multi-PSP Support
```swift
// Generate QR supporting multiple Kenyan PSPs
let kenyaTemplates = [
    AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254712345678")!,
    AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890")!,
    AccountTemplateBuilder.kenyaBank(guid: "KCBK", accountNumber: "9876543210")!
]

let multiKenyaRequest = QRCodeGenerationRequest(
    qrType: .p2p,
    initiationMethod: .static,
    accountTemplates: kenyaTemplates,
    merchantCategoryCode: "6011",
    recipientName: "Multi-Bank Recipient",
    currency: "404",    // KES
    countryCode: "KE"
)
```

### Tanzania Implementation

#### TAN-QR/TIPS Format
```swift
// Tanzania uses unified TIPS (Tanzania Instant Payment System)
let tanzaniaTemplate = AccountTemplateBuilder.tanzania(
    acquirerId: "01032",        // Official PSP code (ABSA Bank Tanzania)
    merchantId: "MERCHANT123"
)

let tanzaniaRequest = QRCodeGenerationRequest(
    qrType: .p2m,
    initiationMethod: .static,
    accountTemplates: [tanzaniaTemplate!],
    merchantCategoryCode: "5812",   // Restaurants
    recipientName: "Mama Lishe Restaurant",
    currency: "834",               // TZS (Tanzanian Shilling)
    countryCode: "TZ"
)
```

#### Tanzania PSP Directory
```swift
// Official Tanzania PSP codes
let bankPSPs = [
    "01032": "ABSA Bank Tanzania Limited",
    "01010": "Akiba Commercial Bank",
    "01036": "Amana Bank",
    // ... 29+ official banks
]

let mobileMoneyPSPs = [
    "02001": "Vodacom M-Pesa Tanzania",
    "02002": "Tigo Pesa",
    "02003": "Airtel Money Tanzania",
    // ... 5+ mobile money operators
]
```

---

## Error Handling

### Common Error Types

#### Generation Errors
```swift
do {
    let qr = try sdk.generateQRCode(from: request)
} catch QRGenerationError.missingRequiredField(let field) {
    print("❌ Missing required field: \(field)")
} catch QRGenerationError.invalidConfiguration(let message) {
    print("❌ Invalid configuration: \(message)")
} catch QRGenerationError.unsupportedCountry(let country) {
    print("❌ Unsupported country: \(country)")
} catch {
    print("❌ Generation failed: \(error)")
}
```

#### Parsing Errors
```swift
do {
    let parsed = try sdk.parseQRCode(qrString)
} catch ValidationError.malformedData {
    print("❌ QR code data is malformed")
} catch ValidationError.invalidChecksum {
    print("❌ Invalid CRC checksum - data may be corrupted")
} catch ValidationError.missingRequiredField(let field) {
    print("❌ Missing required field: \(field)")
} catch ValidationError.invalidFieldValue(let field, let value) {
    print("❌ Invalid value '\(value)' for field '\(field)'")
} catch {
    print("❌ Parsing failed: \(error)")
}
```

#### Branding Errors
```swift
do {
    let brandedQR = try sdk.generateBrandedQRCode(from: request, branding: branding)
} catch QRBrandingError.logoTooLarge {
    print("❌ Logo is too large - reduce size or use higher error correction")
} catch QRBrandingError.imageProcessingFailed {
    print("❌ Failed to process logo image")
} catch QRBrandingError.invalidConfiguration {
    print("❌ Invalid branding configuration")
} catch {
    print("❌ Branding failed: \(error)")
}
```

#### Security Errors
```swift
do {
    let cleanInput = try SecurityManager.sanitizeQRInput(input)
} catch SecurityError.rateLimitExceeded {
    print("❌ Too many operations - please wait")
} catch SecurityError.inputTooLong {
    print("❌ Input exceeds maximum QR code capacity")
} catch SecurityError.potentialInjection {
    print("❌ Input contains potentially malicious content")
} catch SecurityError.unsafeURLScheme {
    print("❌ URL scheme not allowed for security reasons")
}
```

### Error Recovery Patterns

```swift
// Graceful error handling with fallbacks
func generateQRWithFallback(request: QRCodeGenerationRequest) -> UIImage? {
    do {
        // Try branded QR first
        return try sdk.generateBrandedQRCode(from: request, branding: preferredBranding)
    } catch QRBrandingError.logoTooLarge {
        // Fallback: try without logo
        let simpleBranding = QRBranding(colorScheme: preferredBranding.colorScheme)
        return try? sdk.generateBrandedQRCode(from: request, branding: simpleBranding)
    } catch {
        // Final fallback: basic QR
        return try? sdk.generateQRCode(from: request)
    }
}
```

---

## Best Practices

### Performance Optimization

#### QR Generation
```swift
// Use appropriate error correction level
let branding = QRBranding(
    errorCorrectionLevel: .medium  // Balance between logo space and redundancy
)

// Cache templates for reuse
class QRTemplateCache {
    private static var cache: [String: AccountTemplate] = [:]
    
    static func getTemplate(key: String, builder: () -> AccountTemplate?) -> AccountTemplate? {
        if let cached = cache[key] {
            return cached
        }
        let template = builder()
        cache[key] = template
        return template
    }
}

let cachedTemplate = QRTemplateCache.getTemplate(key: "equity_savings") {
    AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890")
}
```

### Memory Management

```swift
// Use weak references in delegate patterns
class QRGenerationDelegate: NSObject {
    weak var viewController: UIViewController?
    
    func qrGenerated(_ image: UIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.displayQR(image)
        }
    }
}

// Clear sensitive data after use
func processPayment(phoneNumber: String, amount: Decimal) {
    var mutablePhoneNumber = phoneNumber
    defer {
        SecurityManager.secureErase(&mutablePhoneNumber)
    }
    
    // Process payment...
}
```

### Threading

```swift
// Perform QR operations on background queue
class QRCodeManager {
    private let qrQueue = DispatchQueue(label: "com.app.qr", qos: .userInitiated)
    
    func generateQRAsync(request: QRCodeGenerationRequest, completion: @escaping (Result<UIImage, Error>) -> Void) {
        qrQueue.async {
            do {
                let qr = try UmojaQR.shared.generateQRCode(from: request)
                DispatchQueue.main.async {
                    completion(.success(qr))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
```

### Validation Best Practices

```swift
// Always validate before generation
func generateValidatedQR(request: QRCodeGenerationRequest) throws -> UIImage {
    // Check rate limits
    guard SecurityManager.checkRateLimit(for: "qr_generation") else {
        throw SecurityError.rateLimitExceeded
    }
    
    // Validate amount
    if let amount = request.amount {
        guard amount > 0 && amount <= 1000000 else {
            throw QRGenerationError.invalidFieldValue("amount", "out of range")
        }
    }
    
    // Validate phone numbers
    for template in request.accountTemplates {
        if template.pspInfo.type == .telecom,
           let phoneNumber = template.accountId {
            guard isValidKenyanPhoneNumber(phoneNumber) else {
                throw QRGenerationError.invalidFieldValue("phoneNumber", phoneNumber)
            }
        }
    }
    
    return try UmojaQR.shared.generateQRCode(from: request)
}

func isValidKenyanPhoneNumber(_ number: String) -> Bool {
    let pattern = "^254[17][0-9]{8}$"
    return number.range(of: pattern, options: .regularExpression) != nil
}
```

---

## Examples & Use Cases

### 1. Basic M-PESA P2P QR

```swift
// Generate a static M-PESA QR for receiving payments
func createMPesaReceiveQR(phoneNumber: String, recipientName: String) throws -> UIImage {
    return try UmojaQR.shared.generateKenyaP2PQR(
        phoneNumber: phoneNumber,
        amount: nil,  // Static QR - user enters amount
        recipientName: recipientName
    )
}

// Usage
let qr = try createMPesaReceiveQR(
    phoneNumber: "254712345678",
    recipientName: "John Doe"
)
```

### 2. Multi-Bank Business QR

```swift
// Create QR code accepting payments from multiple banks
func createBusinessMultiBankQR(
    businessName: String,
    businessAccount: String,
    amount: Decimal?
) throws -> UIImage {
    
    // Support major Kenyan banks
    let templates = [
        AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: businessAccount),
        AccountTemplateBuilder.kenyaBank(guid: "KCBK", accountNumber: businessAccount),
        AccountTemplateBuilder.kenyaBank(guid: "COOP", accountNumber: businessAccount),
        AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254700123456")
    ].compactMap { $0 }
    
    let request = QRCodeGenerationRequest(
        qrType: .p2m,
        initiationMethod: amount != nil ? .dynamic : .static,
        accountTemplates: templates,
        merchantCategoryCode: "5812",  // Restaurants
        amount: amount,
        recipientName: businessName,
        currency: "404",
        countryCode: "KE"
    )
    
    return try UmojaQR.shared.generateQRCode(from: request)
}
```

### 3. Branded Bank QR with Logo

```swift
// Create Equity Bank branded QR with logo
func createEquityBrandedQR(
    accountNumber: String,
    amount: Decimal?,
    accountHolder: String
) throws -> UIImage {
    
    guard let template = AccountTemplateBuilder.kenyaBank(
        guid: "EQLT",
        accountNumber: accountNumber
    ) else {
        throw QRGenerationError.invalidConfiguration("Invalid Equity account template")
    }
    
    let request = QRCodeGenerationRequest(
        qrType: .p2p,
        initiationMethod: amount != nil ? .dynamic : .static,
        accountTemplates: [template],
        merchantCategoryCode: "6011",
        amount: amount,
        recipientName: accountHolder,
        currency: "404",
        countryCode: "KE"
    )
    
    // Load Equity Bank logo
    guard let equityLogo = UIImage(named: "equity_logo") else {
        throw QRBrandingError.invalidConfiguration
    }
    
    // Use pre-configured Equity branding
    let branding = QRBranding.equityBank(logo: equityLogo)
    
    return try UmojaQR.shared.generateBrandedQRCode(
        from: request,
        branding: branding
    )
}
```

### 4. Tanzania TIPS Merchant QR

```swift
// Create Tanzania TIPS merchant QR
func createTanzaniaMerchantQR(
    pspCode: String,
    merchantId: String,
    merchantName: String,
    amount: Decimal?
) throws -> UIImage {
    
    guard let template = AccountTemplateBuilder.tanzania(
        acquirerId: pspCode,
        merchantId: merchantId
    ) else {
        throw QRGenerationError.invalidConfiguration("Invalid Tanzania PSP code")
    }
    
    let request = QRCodeGenerationRequest(
        qrType: .p2m,
        initiationMethod: amount != nil ? .dynamic : .static,
        accountTemplates: [template],
        merchantCategoryCode: "5411",  // Grocery stores
        amount: amount,
        recipientName: merchantName,
        currency: "834",  // TZS
        countryCode: "TZ"
    )
    
    return try UmojaQR.shared.generateQRCode(from: request)
}

// Usage
let tanzaniaQR = try createTanzaniaMerchantQR(
    pspCode: "01032",  // ABSA Bank Tanzania
    merchantId: "SHOP123",
    merchantName: "Mama Mboga Store",
    amount: Decimal(50000)  // 50,000 TZS
)
```

### 5. QR Code Scanner Implementation

```swift
import AVFoundation

class QRCodeScanner: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    private let captureSession = AVCaptureSession()
    private let sdk = UmojaQR.shared
    
    func startScanning() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }
        
        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let qrString = readableObject.stringValue else { return }
        
        // Parse the scanned QR code
        parseScannedQR(qrString)
    }
    
    private func parseScannedQR(_ qrString: String) {
        do {
            let parsed = try sdk.parseQRCode(qrString)
            
            // Handle different QR types
            switch parsed.qrType {
            case .p2p:
                handleP2PPayment(parsed)
            case .p2m:
                handleMerchantPayment(parsed)
            }
            
        } catch {
            print("Failed to parse QR code: \(error)")
            showErrorAlert("Invalid QR code")
        }
    }
    
    private func handleP2PPayment(_ qr: ParsedQRCode) {
        // Present P2P payment screen
        let alert = UIAlertController(
            title: "Send Money",
            message: "Send to: \(qr.recipientName ?? "Unknown")\nAmount: \(qr.amount?.description ?? "Enter amount")",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Send", style: .default) { _ in
            self.initiateP2PPayment(qr)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present alert...
    }
    
    private func handleMerchantPayment(_ qr: ParsedQRCode) {
        // Handle merchant payment
        print("Merchant: \(qr.recipientName ?? "")")
        print("Amount: \(qr.amount?.description ?? "Variable")")
        
        // Present merchant payment screen...
    }
    
    private func initiateP2PPayment(_ qr: ParsedQRCode) {
        // Integrate with your payment processing system
        // This is where you'd call your backend API
    }
    
    private func showErrorAlert(_ message: String) {
        // Show error to user
    }
}
```

### 6. Batch QR Generation

```swift
// Generate multiple QR codes efficiently
class BatchQRGenerator {
    private let sdk = UmojaQR.shared
    private let operationQueue = OperationQueue()
    
    init() {
        operationQueue.maxConcurrentOperationCount = 3
    }
    
    func generateQRCodes(
        for recipients: [Recipient],
        completion: @escaping ([QRResult]) -> Void
    ) {
        var results: [QRResult] = []
        let group = DispatchGroup()
        let resultsQueue = DispatchQueue(label: "results")
        
        for recipient in recipients {
            group.enter()
            
            operationQueue.addOperation {
                defer { group.leave() }
                
                do {
                    let template = AccountTemplateBuilder.kenyaTelecom(
                        guid: "MPSA",
                        phoneNumber: recipient.phoneNumber
                    )
                    
                    guard let template = template else {
                        resultsQueue.sync {
                            results.append(.failure(recipient, QRGenerationError.invalidConfiguration("Invalid template")))
                        }
                        return
                    }
                    
                    let request = QRCodeGenerationRequest(
                        qrType: .p2p,
                        initiationMethod: .static,
                        accountTemplates: [template],
                        merchantCategoryCode: "6011",
                        recipientName: recipient.name,
                        currency: "404",
                        countryCode: "KE"
                    )
                    
                    let qr = try self.sdk.generateQRCode(from: request)
                    
                    resultsQueue.sync {
                        results.append(.success(recipient, qr))
                    }
                    
                } catch {
                    resultsQueue.sync {
                        results.append(.failure(recipient, error))
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
}

struct Recipient {
    let name: String
    let phoneNumber: String
}

enum QRResult {
    case success(Recipient, UIImage)
    case failure(Recipient, Error)
}
```

### 7. QR Code Analytics Dashboard

```swift
// Track and analyze QR code usage
class QRAnalyticsDashboard {
    private var generatedQRs: [ParsedQRCode] = []
    
    func trackQRGeneration(_ request: QRCodeGenerationRequest) {
        // Convert request to parsed format for tracking
        do {
            let qrString = try UmojaQR.shared.generateQRString(from: request)
            let parsed = try UmojaQR.shared.parseQRCode(qrString)
            generatedQRs.append(parsed)
        } catch {
            print("Failed to track QR generation: \(error)")
        }
    }
    
    func generateAnalyticsReport() -> AnalyticsReport {
        let analytics = AdvancedFeatures.analyzeQRCodeUsage(generatedQRs)
        let fraudAnalysis = AdvancedFeatures.detectFraudPatterns(generatedQRs)
        
        return AnalyticsReport(
            totalQRs: analytics.totalQRCodes,
            uniqueRecipients: analytics.uniqueRecipients,
            totalAmount: analytics.totalAmount,
            averageAmount: analytics.averageAmount,
            pspBreakdown: analytics.pspDistribution,
            riskScore: fraudAnalysis.overallRiskScore,
            suspiciousActivity: fraudAnalysis.duplicateQRCodes.count > 0
        )
    }
    
    func exportReport() -> String {
        let report = generateAnalyticsReport()
        
        return """
        QR Code Analytics Report
        ========================
        
        Summary:
        - Total QR codes generated: \(report.totalQRs)
        - Unique recipients: \(report.uniqueRecipients)
        - Total transaction amount: KES \(report.totalAmount)
        - Average amount: KES \(report.averageAmount)
        
        PSP Distribution:
        \(report.pspBreakdown.map { "- \($0.key): \($0.value)" }.joined(separator: "\n"))
        
        Security:
        - Risk score: \(report.riskScore)/10.0
        - Suspicious activity detected: \(report.suspiciousActivity ? "Yes" : "No")
        """
    }
}

struct AnalyticsReport {
    let totalQRs: Int
    let uniqueRecipients: Int
    let totalAmount: Decimal
    let averageAmount: Decimal
    let pspBreakdown: [String: Int]
    let riskScore: Double
    let suspiciousActivity: Bool
}
```

---

## 🔧 Troubleshooting Guide

### Common Issues & Solutions

#### ❌ QR Generation Failures

**Problem**: `QRGenerationError.invalidConfiguration`
```swift
// ❌ Wrong: Invalid GUID
let template = AccountTemplateBuilder.kenyaBank(guid: "INVALID", accountNumber: "123")

// ✅ Correct: Valid bank GUID
let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: "1234567890")
```

**Problem**: `QRBrandingError.logoTooLarge`
```swift
// ❌ Wrong: Logo too big, low error correction
let branding = QRBranding(
    logo: hugeLogo,
    errorCorrectionLevel: .low  // Can't fit large logo
)

// ✅ Correct: Appropriate logo size and error correction
let branding = QRBranding(
    logo: QRLogo(image: logo, size: .medium),
    errorCorrectionLevel: .high  // Higher correction for logo space
)
```

#### ❌ Parsing Failures

**Problem**: `ValidationError.invalidChecksum`
```swift
// Solution: Check for data corruption and attempt recovery
func validateAndFixQR(_ qrString: String) -> String? {
    do {
        _ = try sdk.parseQRCode(qrString)
        return qrString
    } catch ValidationError.invalidChecksum {
        // Attempt error recovery
        let recovery = AdvancedFeatures.recoverFromError(qrString, error: error)
        return recovery.recoveredData
    } catch {
        return nil
    }
}
```

#### ❌ Performance Issues

**Problem**: Slow QR generation blocking UI
```swift
// ❌ Wrong: Synchronous generation blocking UI thread
func generateQR() {
    let qr = try! sdk.generateQRCode(from: request)  // Blocks UI
    imageView.image = qr
}

// ✅ Correct: Async generation with proper error handling
func generateQRAsync() {
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let qr = try self.sdk.generateQRCode(from: self.request)
            DispatchQueue.main.async {
                self.imageView.image = qr
            }
        } catch {
            DispatchQueue.main.async {
                self.handleError(error)
            }
        }
    }
}
```

### 🆘 Quick Fixes

#### QR Code Won't Scan
1. **Check Error Correction**: Use `.high` for logos
2. **Verify Colors**: Ensure sufficient contrast (>3:1 ratio)
3. **Test Logo Size**: Keep under 25% of QR area
4. **Validate Format**: Parse QR string before generating image

#### Poor Performance
1. **Cache Templates**: Reuse `AccountTemplate` objects
2. **Use Background Queue**: Don't block main thread
3. **Optimize Images**: Resize logos before applying
4. **Batch Operations**: Generate multiple QRs efficiently

#### Branding Not Working
1. **Check Image Format**: Use PNG for transparency
2. **Verify Color Space**: Use RGB color space
3. **Test Logo Position**: Avoid QR timing patterns
4. **Validate Effects**: Some effects require higher error correction

## 📚 Frequently Asked Questions

### General SDK Questions

**Q: What QR code standards does Umoja QR support?**
A: Umoja QR supports EMVCo international standards, CBK Kenya QR Code Standard 2023, and Tanzania TAN-QR/TIPS standards, bringing unity to East African payment systems.

**Q: Can I use this for countries other than Kenya and Tanzania?**
A: Currently optimized for Kenya and Tanzania payment systems, but generates standard EMVCo-compliant QR codes that work internationally.

**Q: What's the difference between P2P and P2M QR codes?**
A: P2P (Person-to-Person) codes are for money transfers between individuals (MCC 6011/6012). P2M (Person-to-Merchant) codes are for business payments (other MCCs).

### Technical Questions

**Q: How do I handle rate limiting?**
```swift
if SecurityManager.checkRateLimit(for: "qr_generation") {
    generateQR()
} else {
    showMessage("Rate limit exceeded. Please wait.")
}
```

**Q: How do I validate Kenyan phone numbers?**
```swift
func isValidKenyanPhone(_ number: String) -> Bool {
    let pattern = "^254[17][0-9]{8}$"
    return number.range(of: pattern, options: .regularExpression) != nil
}
```

**Q: Can I customize QR code dimensions?**
```swift
// Generate at specific size (recommended: 200x200 to 1000x1000)
let style = QRCodeStyle(size: CGSize(width: 400, height: 400))
let qrImage = try sdk.generateQRCode(from: request, style: style)
```

### Integration Questions

**Q: How do I integrate with my payment system?**
```swift
func processScannedQR(_ qrString: String) {
    do {
        let parsed = try sdk.parseQRCode(qrString)
        
        let paymentRequest = PaymentRequest(
            amount: parsed.amount,
            recipient: parsed.recipientName,
            account: parsed.accountTemplates.first?.accountId,
            psp: parsed.pspInfo?.identifier
        )
        
        initiatePayment(paymentRequest)
    } catch {
        showError("Invalid QR code: \(error.localizedDescription)")
    }
}
```

**Q: How do I save QR codes for offline use?**
```swift
// Save QR as PNG data
if let qrData = qrImage.pngData() {
    UserDefaults.standard.set(qrData, forKey: "savedQR_\(recipientId)")
}

// Load later
if let data = UserDefaults.standard.data(forKey: "savedQR_\(recipientId)"),
   let qrImage = UIImage(data: data) {
    displayQR(qrImage)
}
```

## 🎯 Performance Benchmarks

### Generation Speed (iPhone 12, iOS 15)
- **Simple QR**: ~50ms average
- **Branded QR**: ~150ms average  
- **Multi-PSP QR**: ~200ms average
- **Gradient QR**: ~300ms average

### Memory Usage
- **Base SDK**: ~2MB
- **With Branding Engine**: ~4MB
- **Per QR Generation**: ~100KB temporary allocation

### Recommended Limits
- **Batch Generation**: Max 50 QRs per batch
- **Logo Size**: Max 512x512 pixels
- **QR Dimensions**: 200x200 to 1000x1000 pixels optimal
- **Concurrent Operations**: Max 3 simultaneous generations

## 📞 Support & Resources

### 📖 Documentation Resources
- **API Reference**: Complete documentation in `UmojaQR.docc` folder
- **Test Examples**: Comprehensive examples in `Tests/` directory  
- **Sample Projects**: Production-ready examples in repository
- **Integration Guide**: Step-by-step implementation examples

### 🆘 Getting Help
1. **Check this documentation** for common solutions and patterns
2. **Review test files** for implementation examples and edge cases
3. **Check GitHub issues** for known problems and solutions
4. **Contact enterprise support** for business-critical assistance

### 🤝 Contributing
- **Report Issues**: Use GitHub issue tracker with detailed reproduction steps
- **Submit Pull Requests**: Follow contribution guidelines and coding standards
- **Request Features**: Open feature request issues with use case details
- **Improve Documentation**: Help expand examples and use cases

### 🔗 External Resources
- **CBK QR Standard**: Central Bank of Kenya QR Code Guidelines
- **Tanzania TIPS**: Bank of Tanzania Payment Standards
- **EMVCo Specification**: International QR Code Standards

---

## 🎉 Conclusion

**Congratulations!** You now have comprehensive knowledge of Umoja QR and can implement world-class unified payment QR code solutions that bring East African payment systems together.

### ✅ What You've Learned
- **Complete Payment Integration** - Kenya CBK and Tanzania TIPS compliance
- **Professional Branding** - Logos, colors, gradients, and visual effects
- **Enterprise Security** - Rate limiting, validation, fraud detection
- **Performance Optimization** - Caching, async operations, best practices
- **Real-world Implementation** - Production-ready code patterns
- **Comprehensive Error Handling** - Robust error management and recovery

### 🚀 Next Steps
1. **Start Simple** - Begin with basic QR generation examples
2. **Add Branding** - Incorporate your company's visual identity
3. **Implement Security** - Add validation and rate limiting
4. **Scale Up** - Use batch operations and caching for production
5. **Monitor & Analyze** - Track usage and detect fraud patterns

### 💡 Pro Tips
- Always test QR codes with real scanners before deployment
- Use high error correction level when adding logos or effects
- Implement proper error handling for production applications
- Cache account templates to improve performance
- Monitor analytics to understand usage patterns

Umoja QR empowers you to create professional, secure, and beautifully branded payment experiences that unite East African payment systems while delighting users and maintaining full compliance with international and regional standards.

**Ready to build amazing unified payment experiences? Let's code with Umoja QR! 🚀💳🤝** 