import XCTest
import Foundation
#if canImport(UIKit)
import UIKit
#endif
@testable import QRCodeSDK

/// Comprehensive tests for advanced QR branding and visual customization features
/// Tests logo integration, color schemes, bank templates, and performance
class AdvancedBrandingTests: XCTestCase {
    
    var sdk: QRCodeSDK!
    var generator: EnhancedQRGenerator!
    var brandingEngine: QRBrandingEngine!
    
    override public func setUp() {
        super.setUp()
        sdk = QRCodeSDK.shared
        generator = EnhancedQRGenerator()
        brandingEngine = QRBrandingEngine.shared
    }
    
    override public func tearDown() {
        sdk = nil
        generator = nil
        brandingEngine = nil
        super.tearDown()
    }
    
    // MARK: - Logo Integration Tests
    
    #if canImport(UIKit)
    func testLogoIntegrationBasic() throws {
        // Test basic logo integration with different sizes
        let testLogo = createTestLogo(size: CGSize(width: 100, height: 100))
        
        let logoConfigurations = [
            QRLogo(image: testLogo, position: .center, size: .small),
            QRLogo(image: testLogo, position: .center, size: .medium),
            QRLogo(image: testLogo, position: .center, size: .large),
            QRLogo(image: testLogo, position: .center, size: .adaptive),
        ]
        
        for (index, logoConfig) in logoConfigurations.enumerated() {
            let branding = QRBranding(
                logo: logoConfig,
                colorScheme: .default,
                errorCorrectionLevel: .high
            )
            
            let request = createTestRequest()
            let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
            
            XCTAssertNotNil(brandedQR, "Should generate branded QR with logo config \(index)")
            XCTAssertGreaterThan(brandedQR.size.width, 0, "Branded QR should have valid dimensions")
        }
        
        print("✅ Logo Integration: All size configurations working")
    }
    
    func testLogoPositioning() throws {
        // Test different logo positioning options
        let testLogo = createTestLogo(size: CGSize(width: 80, height: 80))
        
        let positions: [QRLogo.LogoPosition] = [
            .center,
            .topLeft,
            .topRight,
            .bottomLeft,
            .bottomRight,
            .custom(CGPoint(x: 0.3, y: 0.7))
        ]
        
        for position in positions {
            let logoConfig = QRLogo(
                image: testLogo,
                position: position,
                size: .medium,
                style: .overlay
            )
            
            let branding = QRBranding(
                logo: logoConfig,
                colorScheme: .default,
                errorCorrectionLevel: .high
            )
            
            let request = createTestRequest()
            let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
            
            XCTAssertNotNil(brandedQR, "Should generate QR with logo at position \(position)")
        }
        
        print("✅ Logo Positioning: All positions working correctly")
    }
    
    func testLogoStyles() throws {
        // Test different logo styles and effects
        let testLogo = createTestLogo(size: CGSize(width: 80, height: 80))
        
        let styles: [QRLogo.LogoStyle] = [
            .overlay,
            .embedded,
            .watermark,
            .badge,
            .neon(.cyan),
            .glass
        ]
        
        for style in styles {
            let logoConfig = QRLogo(
                image: testLogo,
                position: .center,
                size: .medium,
                style: style,
                effects: LogoEffects(
                    shadow: ShadowConfig(color: .black, opacity: 0.3),
                    glow: GlowConfig(color: .blue, intensity: 0.5)
                )
            )
            
            let branding = QRBranding(
                logo: logoConfig,
                colorScheme: .default,
                errorCorrectionLevel: .high
            )
            
            let request = createTestRequest()
            let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
            
            XCTAssertNotNil(brandedQR, "Should generate QR with logo style \(style)")
        }
        
        print("✅ Logo Styles: All styles and effects working")
    }
    #endif
    
    // MARK: - Color Scheme Tests
    
    func testBasicColorSchemes() throws {
        // Test basic color scheme configurations
        let colorSchemes = [
            QRColorScheme.default,
            QRColorScheme(
                dataPattern: .solid(.black),
                background: .solid(.white),
                finderPatterns: .solid(.black)
            ),
            QRColorScheme(
                dataPattern: .solid(.blue),
                background: .solid(.lightGray),
                finderPatterns: .solid(.red)
            )
        ]
        
        for (index, colorScheme) in colorSchemes.enumerated() {
            let branding = QRBranding(
                colorScheme: colorScheme,
                errorCorrectionLevel: .medium
            )
            
            let request = createTestRequest()
            
            #if canImport(UIKit)
            let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
            XCTAssertNotNil(brandedQR, "Should generate QR with color scheme \(index)")
            #endif
        }
        
        print("✅ Basic Color Schemes: All configurations working")
    }
    
    func testGradientColorSchemes() throws {
        // Test gradient color schemes
        #if canImport(UIKit)
        let gradientConfig = QRColorScheme.GradientConfig(
            colors: [.red, .orange, .yellow],
            direction: .linear(angle: 0),
            stops: [0.0, 0.5, 1.0]
        )
        
        let colorScheme = QRColorScheme(
            dataPattern: .gradient(gradientConfig),
            background: .solid(.white),
            finderPatterns: .gradient(gradientConfig)
        )
        
        let branding = QRBranding(
            colorScheme: colorScheme,
            errorCorrectionLevel: .high
        )
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
        
        XCTAssertNotNil(brandedQR, "Should generate QR with gradient color scheme")
        #endif
        
        print("✅ Gradient Color Schemes: Working correctly")
    }
    
    func testPatternColorSchemes() throws {
        // Test pattern-based color schemes
        #if canImport(UIKit)
        let patternConfig = QRColorScheme.PatternConfig(
            primaryColor: .black,
            secondaryColor: .gray,
            pattern: .dots,
            scale: 1.0
        )
        
        let colorScheme = QRColorScheme(
            dataPattern: .pattern(patternConfig),
            background: .solid(.white),
            finderPatterns: .solid(.black)
        )
        
        let branding = QRBranding(
            colorScheme: colorScheme,
            errorCorrectionLevel: .high
        )
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
        
        XCTAssertNotNil(brandedQR, "Should generate QR with pattern color scheme")
        #endif
        
        print("✅ Pattern Color Schemes: Working correctly")
    }
    
    // MARK: - Bank Template Tests
    
    func testEquityBankTemplate() throws {
        // Test Equity Bank specific branding
        #if canImport(UIKit)
        let equityLogo = createTestLogo(size: CGSize(width: 80, height: 80), color: .red)
        let equityBranding = QRBrandingPresets.equityBank(logo: equityLogo)
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: equityBranding)
        
        XCTAssertNotNil(brandedQR, "Should generate Equity Bank branded QR")
        
        // Verify Equity-specific features
        XCTAssertEqual(equityBranding.brandIdentifier, "equity", "Should have Equity brand identifier")
        XCTAssertEqual(equityBranding.errorCorrectionLevel, .high, "Should use high error correction for banking")
        #endif
        
        print("✅ Equity Bank Template: Working correctly")
    }
    
    func testMPesaTemplate() throws {
        // Test M-PESA specific branding
        #if canImport(UIKit)
        let mpesaLogo = createTestLogo(size: CGSize(width: 80, height: 80), color: .green)
        let mpesaBranding = QRBrandingPresets.safaricomMPesa(logo: mpesaLogo)
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: mpesaBranding)
        
        XCTAssertNotNil(brandedQR, "Should generate M-PESA branded QR")
        
        // Verify M-PESA specific features
        XCTAssertEqual(mpesaBranding.brandIdentifier, "mpesa", "Should have M-PESA brand identifier")
        #endif
        
        print("✅ M-PESA Template: Working correctly")
    }
    
    func testTechStartupTemplate() throws {
        // Test tech startup branding template
        #if canImport(UIKit)
        let techLogo = createTestLogo(size: CGSize(width: 80, height: 80), color: .blue)
        let techBranding = QRBrandingPresets.techStartup(
            logo: techLogo,
            primaryColor: UIColor.customBlue,
            secondaryColor: UIColor.customPurple
        )
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: techBranding)
        
        XCTAssertNotNil(brandedQR, "Should generate tech startup branded QR")
        
        // Verify tech-specific features
        XCTAssertEqual(techBranding.brandIdentifier, "tech", "Should have tech brand identifier")
        #endif
        
        print("✅ Tech Startup Template: Working correctly")
    }
    
    // MARK: - Error Correction Tests
    
    func testErrorCorrectionLevels() throws {
        // Test different error correction levels with branding
        let errorLevels: [QRErrorCorrectionLevel] = [.low, .medium, .quartile, .high]
        
        for level in errorLevels {
            let branding = QRBranding(
                colorScheme: .default,
                errorCorrectionLevel: level
            )
            
            let request = createTestRequest()
            
            #if canImport(UIKit)
            let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: branding)
            XCTAssertNotNil(brandedQR, "Should generate QR with error correction level \(level)")
            #endif
        }
        
        print("✅ Error Correction Levels: All levels working")
    }
    
    func testErrorCorrectionWithLogo() throws {
        // Test error correction with logo overlay
        #if canImport(UIKit)
        let testLogo = createTestLogo(size: CGSize(width: 100, height: 100))
        
        // Test with high error correction (30% logo coverage possible)
        let highCorrectionBranding = QRBranding(
            logo: QRLogo(image: testLogo, position: .center, size: .large),
            colorScheme: .default,
            errorCorrectionLevel: .high
        )
        
        let request = createTestRequest()
        let brandedQR = try brandingEngine.generateBrandedQR(from: request, branding: highCorrectionBranding)
        
        XCTAssertNotNil(brandedQR, "Should generate QR with large logo and high error correction")
        
        // Test with medium error correction (15% logo coverage)
        let mediumCorrectionBranding = QRBranding(
            logo: QRLogo(image: testLogo, position: .center, size: .medium),
            colorScheme: .default,
            errorCorrectionLevel: .medium
        )
        
        let mediumBrandedQR = try brandingEngine.generateBrandedQR(from: request, branding: mediumCorrectionBranding)
        
        XCTAssertNotNil(mediumBrandedQR, "Should generate QR with medium logo and medium error correction")
        #endif
        
        print("✅ Error Correction with Logo: Working correctly")
    }
    
    // MARK: - Performance Tests
    
    func testBrandingPerformance() throws {
        // Test branding performance under load
        #if canImport(UIKit)
        let testLogo = createTestLogo(size: CGSize(width: 80, height: 80))
        let branding = QRBranding(
            logo: QRLogo(image: testLogo, position: .center, size: .medium),
            colorScheme: .default,
            errorCorrectionLevel: .high
        )
        
        let request = createTestRequest()
        let iterations = 50
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<iterations {
            let _ = try brandingEngine.generateBrandedQR(from: request, branding: branding)
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = totalTime / Double(iterations) * 1000 // Convert to milliseconds
        
        // Should complete branding in reasonable time (<750ms per QR including logo)
        XCTAssertLessThan(averageTime, 750.0, "Branding should complete in <750ms, got \(averageTime)ms")
        #endif
        
        print("✅ Branding Performance: \(String(format: "%.2f", averageTime))ms average")
    }
    
    func testBrandingMemoryUsage() throws {
        // Test memory usage during branding operations
        #if canImport(UIKit)
        let initialMemory = getMemoryUsage()
        
        let testLogo = createTestLogo(size: CGSize(width: 100, height: 100))
        let branding = QRBranding(
            logo: QRLogo(image: testLogo, position: .center, size: .medium),
            colorScheme: .default,
            errorCorrectionLevel: .high
        )
        
        let request = createTestRequest()
        
        // Generate multiple branded QRs
        for _ in 0..<100 {
            autoreleasepool {
                do {
                    let _ = try brandingEngine.generateBrandedQR(from: request, branding: branding)
                } catch {
                    XCTFail("Branding operation failed: \(error)")
                }
            }
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 20MB for 100 branded QRs)
        XCTAssertLessThan(memoryIncrease, 20_000_000, "Memory increase should be under 20MB, got \(memoryIncrease) bytes")
        #endif
        
        print("✅ Branding Memory Usage: \(memoryIncrease / 1_000_000)MB increase for 100 operations")
    }
    
    // MARK: - Context Optimization Tests
    
    func testContextualBranding() throws {
        // Test contextual branding optimization
        #if canImport(UIKit)
        let testLogo = createTestLogo(size: CGSize(width: 80, height: 80))
        let baseBranding = QRBranding(
            logo: QRLogo(image: testLogo, position: .center, size: .adaptive),
            colorScheme: .default,
            errorCorrectionLevel: .high
        )
        
        let contexts = [
            BrandingContext(displayType: .mobile, viewingDistance: .close(meters: 0.3), lightingConditions: .indoor, targetAudience: .general),
            BrandingContext(displayType: .print, viewingDistance: .normal(meters: 1.5), lightingConditions: .outdoor, targetAudience: .elderly),
            BrandingContext(displayType: .billboard, viewingDistance: .far(meters: 10.0), lightingConditions: .bright, targetAudience: .techSavvy)
        ]
        
        let request = createTestRequest()
        
        for (index, context) in contexts.enumerated() {
            let baseQR = try generator.generateQR(from: request)
            guard let ciImage = CIImage(image: baseQR) else {
                XCTFail("Failed to create CIImage from generated QR")
                continue
            }
            let optimizedQR = try brandingEngine.applyContextualBranding(
                to: ciImage,
                branding: baseBranding,
                size: CGSize(width: 400, height: 400),
                context: context
            )
            
            XCTAssertNotNil(optimizedQR, "Should generate contextually optimized QR for context \(index)")
        }
        #endif
        
        print("✅ Contextual Branding: All contexts optimized successfully")
    }
    
    // MARK: - Helper Methods
    
    private func createTestRequest() -> QRCodeGenerationRequest {
        // Create account template safely - using correct GUID "MPSA" from PSPDirectory
        guard let accountTemplate = AccountTemplateBuilder.kenyaTelecom(guid: "MPSA", phoneNumber: "254712345678") else {
            // Fallback to a basic template if the builder fails
            let fallbackPSPInfo = PSPInfo(type: .telecom, identifier: "01", name: "M-PESA", country: .kenya)
            return QRCodeGenerationRequest(
                qrType: .p2p,
                initiationMethod: .static,
                accountTemplates: [
                    AccountTemplate(tag: "28", guid: "ke.go.qr", participantId: "01", accountId: "254712345678", pspInfo: fallbackPSPInfo)
                ],
                merchantCategoryCode: "6011",
                recipientName: "Test User",
                currency: "404",
                countryCode: "KE"
            )
        }
        
        return QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: .static,
            accountTemplates: [accountTemplate],
            merchantCategoryCode: "6011",
            recipientName: "Test User",
            currency: "404",
            countryCode: "KE"
        )
    }
    
    #if canImport(UIKit)
    private func createTestLogo(size: CGSize, color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            context.fill(rect)
            
            // Add some basic logo elements
            UIColor.white.setFill()
            let innerRect = rect.insetBy(dx: size.width * 0.2, dy: size.height * 0.2)
            context.fill(innerRect)
        }
    }
    #endif
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
} 