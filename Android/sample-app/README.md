# QR Code SDK for Android

A comprehensive Android SDK for QR code generation and parsing with CBK (Central Bank of Kenya) and TANQR (Tanzania QR) compliance.

## Features

- ✅ **QR Code Generation**: Support for P2P (Person-to-Person) and P2M (Person-to-Merchant) QR codes
- ✅ **QR Code Parsing**: Auto-detection of country and QR type with deep TLV parsing
- ✅ **CBK Compliance**: Full compliance with Central Bank of Kenya 2023 standards
- ✅ **TANQR Support**: Tanzania QR code format support
- ✅ **EMVCo v1.1**: Compliant with EMVCo specification
- ✅ **Camera Integration**: Built-in camera scanning with ML Kit
- ✅ **Custom Branding**: Support for custom colors, logos, and styling
- ✅ **Performance Optimized**: Fast generation (<500ms) and parsing (<100ms)
- ✅ **Comprehensive Testing**: >90% test coverage with real-world scenarios

## Quick Start

### Installation

Add the SDK to your `build.gradle`:

```gradle
dependencies {
    implementation 'com.qrcodesdk:qrcode-sdk:2.0.0'
}
```

### Basic Usage

#### Generate QR Code

```kotlin
import com.qrcodesdk.generator.QRBrandingEngine
import com.qrcodesdk.models.*

val engine = QRBrandingEngine()

val request = QRCodeGenerationRequest(
    qrType = QRType.P2M,
    amount = BigDecimal("1000.00"),
    merchantName = "Sample Merchant",
    merchantId = "MERCH001",
    style = QRCodeStyle(
        size = 400,
        margin = 20,
        cornerRadius = 12,
        borderColor = Color.Red
    )
)

val qrData = engine.generateQRCode(request)
```

#### Parse QR Code

```kotlin
import com.qrcodesdk.parser.KenyaP2PQRParser

val parser = KenyaP2PQRParser()
val result = parser.parseKenyaP2PQR(qrData)

println("Amount: ${result.amount}")
println("Merchant: ${result.merchantName}")
println("QR Type: ${result.qrType}")
```

#### Scan QR Code

```kotlin
import com.qrcodesdk.QRCodeSDK

val sdk = QRCodeSDK()
sdk.startScanning(
    context = this,
    onResult = { qrData ->
        // Handle scanned QR data
        val parsed = parser.parseKenyaP2PQR(qrData)
    },
    onError = { error ->
        // Handle scan errors
    }
)
```

## Architecture

The SDK follows clean architecture principles with clear separation of concerns:

```
qrcode-sdk/
├── models/          # Data models and entities
├── generator/       # QR code generation logic
├── parser/          # QR code parsing logic
├── security/        # Security and validation
├── utils/           # Utility functions
└── QRCodeSDK.kt     # Main SDK entry point
```

## Supported Formats

### Kenya (CBK)
- **P2P-KE-01**: Person-to-Person format
- **P2M-KE-01**: Person-to-Merchant format
- **P2M-KE-02**: Enhanced merchant format

### Tanzania (TANQR)
- **P2P-TZ-01**: Person-to-Person format
- **P2M-TZ-01**: Person-to-Merchant format

## Compliance

- ✅ **CBK 2023**: Central Bank of Kenya standards
- ✅ **TANQR 2022**: Tanzania QR code standards
- ✅ **EMVCo v1.1**: EMVCo QR code specification
- ✅ **Android 7+**: Minimum API level 24

## Performance

- **QR Generation**: <500ms average
- **QR Parsing**: <100ms average
- **Memory Usage**: <10MB
- **Scan Success Rate**: >95%

## Testing

Run the test suite:

```bash
./gradlew :qrcode-sdk:testDebugUnitTest
./gradlew :app:testDebugUnitTest
```

## Sample App

The included sample app demonstrates:

- QR code generation with custom branding
- Camera-based QR scanning
- QR code parsing and display
- Error handling and validation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Email: support@your-org.com
- Documentation: [docs/](docs/)

## Changelog

### v2.0.0
- Added comprehensive ViewModels
- Improved error handling
- Enhanced UI components
- Updated to Java 17
- Added ProGuard rules
- Improved test coverage

### v1.0.0
- Initial release
- Basic QR generation and parsing
- Camera integration
- CBK compliance 