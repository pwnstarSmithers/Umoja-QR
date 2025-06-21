import Foundation
import CoreImage
import CoreGraphics
#if canImport(UIKit)
import UIKit
import QuartzCore
#elseif canImport(AppKit)
import AppKit
import QuartzCore
// macOS aliases for iOS APIs
public typealias UIImage = NSImage
public typealias UIColor = NSColor
#endif

// MARK: - Error Types

public enum QRBrandingError: Error {
    case imageProcessingFailed
    case filterNotAvailable
    case colorProcessingFailed
    case unsupportedPlatform
    case invalidConfiguration
    case logoTooLarge
    case corruptedData
}

// MARK: - Core Branding Types

/// QR Code branding configuration
public struct QRBranding {
    public let logo: QRLogo?
    public let colorScheme: QRColorScheme
    public let template: QRTemplate
    public let errorCorrectionLevel: QRErrorCorrectionLevel
    public let brandIdentifier: String?
    
    public init(logo: QRLogo? = nil, 
                colorScheme: QRColorScheme = .default,
                template: QRTemplate = .modern,
                errorCorrectionLevel: QRErrorCorrectionLevel = .medium,
                brandIdentifier: String? = nil) {
        self.logo = logo
        self.colorScheme = colorScheme
        self.template = template
        self.errorCorrectionLevel = errorCorrectionLevel
        self.brandIdentifier = brandIdentifier
    }
    
    public static let `default` = QRBranding()
}

/// QR Code logo configuration
public struct QRLogo {
    public let image: UIImage
    public let position: LogoPosition
    public let size: LogoSize
    public let style: LogoStyle
    public let effects: LogoEffects?
    
    public init(image: UIImage, position: LogoPosition = .center, size: LogoSize = .medium, style: LogoStyle = .overlay, effects: LogoEffects? = nil) {
        self.image = image
        self.position = position
        self.size = size
        self.style = style
        self.effects = effects
    }
    
    public enum LogoPosition {
        case center, topLeft, topRight, bottomLeft, bottomRight, custom(CGPoint)
        
        public func calculatePosition(in rect: CGRect) -> CGPoint {
            switch self {
            case .center: return CGPoint(x: rect.midX, y: rect.midY)
            case .topLeft: return CGPoint(x: rect.minX + 20, y: rect.minY + 20)
            case .topRight: return CGPoint(x: rect.maxX - 20, y: rect.minY + 20)
            case .bottomLeft: return CGPoint(x: rect.minX + 20, y: rect.maxY - 20)
            case .bottomRight: return CGPoint(x: rect.maxX - 20, y: rect.maxY - 20)
            case .custom(let point): return CGPoint(x: rect.width * point.x, y: rect.height * point.y)
            }
        }
    }
    
    public enum LogoSize {
        case small, medium, large, extraLarge, adaptive
        
        public var scale: CGFloat {
            switch self {
            case .small: return 0.1
            case .medium: return 0.15
            case .large: return 0.2
            case .extraLarge: return 0.25
            case .adaptive: return 0.15 // Default adaptive size
            }
        }
    }
    
    public enum LogoStyle {
        case overlay, embedded, watermark, badge, neon(UIColor), glass, shadow(ShadowConfig), circular
    }
}

/// Logo visual effects
public struct LogoEffects {
    public let shadow: ShadowConfig?
    public let border: BorderConfig?
    public let glow: GlowConfig?
    
    public init(shadow: ShadowConfig? = nil, border: BorderConfig? = nil, glow: GlowConfig? = nil) {
        self.shadow = shadow
        self.border = border
        self.glow = glow
    }
}

public struct ShadowConfig {
    public let color: UIColor
    public let opacity: Float
    public let radius: CGFloat
    public let offset: CGSize
    
    public init(color: UIColor = .black, opacity: Float = 0.3, radius: CGFloat = 4, offset: CGSize = CGSize(width: 2, height: 2)) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.offset = offset
    }
}

public struct BorderConfig {
    public let color: UIColor
    public let width: CGFloat
    
    public init(color: UIColor, width: CGFloat) {
        self.color = color
        self.width = width
    }
}

public struct GlowConfig {
    public let color: UIColor
    public let intensity: Float
    public let radius: CGFloat
    
    public init(color: UIColor, intensity: Float, radius: CGFloat = 8) {
        self.color = color
        self.intensity = intensity
        self.radius = radius
    }
}

/// QR Code color scheme
public struct QRColorScheme {
    public let dataPattern: PatternStyle
    public let background: BackgroundStyle
    public let finderPatterns: FinderPatternStyle
    public let logoBackgroundColor: UIColor?
    
    public init(dataPattern: PatternStyle = .solid(.black),
                background: BackgroundStyle = .solid(.white),
                finderPatterns: FinderPatternStyle = .solid(.black),
                logoBackgroundColor: UIColor? = nil) {
        self.dataPattern = dataPattern
        self.background = background
        self.finderPatterns = finderPatterns
        self.logoBackgroundColor = logoBackgroundColor
    }
    
    public static let `default` = QRColorScheme()
    public static let equityBank = QRColorScheme(
        dataPattern: .solid(.black),
        background: .solid(.white),
        finderPatterns: .solid(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)),
        logoBackgroundColor: .white
    )
    
    public enum PatternStyle {
        case solid(UIColor)
        case gradient(GradientConfig)
        case pattern(PatternConfig)
    }
    
    public enum BackgroundStyle {
        case solid(UIColor)
        case gradient(GradientConfig)
        case image(UIImage, BlendMode)
        case transparent
    }
    
    public enum FinderPatternStyle {
        case solid(UIColor)
        case gradient(GradientConfig)
        case individual(IndividualFinderConfig)
    }
    
    public struct GradientConfig {
        public let colors: [UIColor]
        public let direction: GradientDirection
        public let stops: [Float]?
        
        public init(colors: [UIColor], direction: GradientDirection = .linear(angle: 0), stops: [Float]? = nil) {
            self.colors = colors
            self.direction = direction
            self.stops = stops
        }
        
        public enum GradientDirection {
            case linear(angle: Float)
            case radial(center: CGPoint, radius: Float)
        }
    }
    
    public struct PatternConfig {
        public let primaryColor: UIColor
        public let secondaryColor: UIColor
        public let pattern: PatternType
        public let scale: Float
        
        public init(primaryColor: UIColor, secondaryColor: UIColor, pattern: PatternType, scale: Float = 1.0) {
            self.primaryColor = primaryColor
            self.secondaryColor = secondaryColor
            self.pattern = pattern
            self.scale = scale
        }
        
        public enum PatternType {
            case dots, stripes, checkerboard, custom(UIImage)
        }
    }
    
    public struct IndividualFinderConfig {
        public let topLeft: UIColor
        public let topRight: UIColor
        public let bottomLeft: UIColor
        
        public init(topLeft: UIColor, topRight: UIColor, bottomLeft: UIColor) {
            self.topLeft = topLeft
            self.topRight = topRight
            self.bottomLeft = bottomLeft
        }
    }
    
    public enum BlendMode {
        case normal, multiply, screen, overlay
        
        #if canImport(UIKit)
        public var cgBlendMode: CGBlendMode {
            switch self {
            case .normal: return .normal
            case .multiply: return .multiply
            case .screen: return .screen
            case .overlay: return .overlay
            }
        }
        #endif
    }
}

public enum QRTemplate {
    case classic, modern, minimal, premium, custom(String), banking(BankTemplate)
    
    public var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .modern: return "Modern"
        case .minimal: return "Minimal"
        case .premium: return "Premium"
        case .custom(let name): return name
        case .banking(let bank): return bank.displayName
        }
    }
}

public enum QRErrorCorrectionLevel {
    case low, medium, high, max, quartile
    
    public var displayName: String {
        switch self {
        case .low: return "Low (7%)"
        case .medium: return "Medium (15%)"
        case .high: return "High (25%)"
        case .max: return "Maximum (30%)"
        case .quartile: return "Quartile (15%)"
        }
    }
}

// MARK: - Branding Context for Contextual Optimization

public struct BrandingContext {
    public let displayType: DisplayType
    public let viewingDistance: ViewingDistance
    public let lightingConditions: LightingConditions
    public let targetAudience: TargetAudience
    
    public init(displayType: DisplayType, viewingDistance: ViewingDistance, lightingConditions: LightingConditions, targetAudience: TargetAudience) {
        self.displayType = displayType
        self.viewingDistance = viewingDistance
        self.lightingConditions = lightingConditions
        self.targetAudience = targetAudience
    }
    
    public enum DisplayType {
        case mobile, print, billboard
    }
    
    public enum ViewingDistance {
        case close(meters: Float), normal(meters: Float), far(meters: Float)
    }
    
    public enum LightingConditions {
        case indoor, outdoor, bright
    }
    
    public enum TargetAudience {
        case general, elderly, techSavvy
    }
}

// MARK: - Custom Colors Extension

extension UIColor {
    /// Cross-platform blue color (equivalent to systemBlue)
    public static var customBlue: UIColor {
        return UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    }
    
    /// Cross-platform purple color (equivalent to systemPurple)  
    public static var customPurple: UIColor {
        return UIColor(red: 0.686, green: 0.322, blue: 0.871, alpha: 1.0)
    }
    
    /// Cross-platform orange color (equivalent to systemOrange)
    public static var customOrange: UIColor {
        return UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)
    }
}

// MARK: - Bank Templates

public struct BankTemplate {
    public let name: String
    public let brandIdentifier: String
    public let colorScheme: QRColorScheme
    public let displayName: String
    
    public init(name: String, brandIdentifier: String, colorScheme: QRColorScheme, displayName: String) {
        self.name = name
        self.brandIdentifier = brandIdentifier
        self.colorScheme = colorScheme
        self.displayName = displayName
    }
    
    public static let equity = BankTemplate(
        name: "Equity Bank",
        brandIdentifier: "EQ",
        colorScheme: .equityBank,
        displayName: "Equity Bank"
    )
}

// MARK: - QR Branding Engine

/// Simplified QR Branding Engine - Core functionality
public class QRBrandingEngine {
    public static let shared = QRBrandingEngine()
    private init() {}
    
    /// Generate a branded QR code with basic branding support
    public func generateBrandedQR(
        from request: QRCodeGenerationRequest,
        branding: QRBranding = .default
    ) throws -> UIImage {
        #if canImport(UIKit)
        // Generate basic QR code
        let generator = EnhancedQRGenerator()
        let qrString = try generator.generateQRString(from: request)
        
        // Create QR code image using Core Image
        guard let data = qrString.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRBrandingError.imageProcessingFailed
        }
        
        filter.setValue(data, forKey: "inputMessage")
        
        // Set error correction level
        let correctionLevel: String
        switch branding.errorCorrectionLevel {
        case .low: correctionLevel = "L"
        case .medium: correctionLevel = "M"
        case .high: correctionLevel = "Q"
        case .max: correctionLevel = "H"
        case .quartile: correctionLevel = "M"
        }
        filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            throw QRBrandingError.imageProcessingFailed
        }
        
        // Scale the image
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        
        // Apply basic color scheme
        let coloredImage = try applyColorScheme(scaledImage, scheme: branding.colorScheme)
        
        // Add logo if provided
        var finalImage = try convertToUIImage(coloredImage)
        if let logo = branding.logo {
            finalImage = try addLogoToQR(finalImage, logo: logo)
        }
        
        return finalImage
        #else
        throw QRBrandingError.unsupportedPlatform
        #endif
    }
    
    // MARK: - Private Helper Methods
    
    private func applyColorScheme(_ image: CIImage, scheme: QRColorScheme) throws -> CIImage {
        guard let colorFilter = CIFilter(name: "CIFalseColor") else {
            throw QRBrandingError.filterNotAvailable
        }
        
        colorFilter.setValue(image, forKey: "inputImage")
        
        // Extract colors from pattern style
        let foregroundColor: UIColor
        let backgroundColor: UIColor
        
        switch scheme.dataPattern {
        case .solid(let color):
            foregroundColor = color
        case .gradient(let config):
            foregroundColor = config.colors.first ?? .black
        case .pattern(let config):
            foregroundColor = config.primaryColor
        }
        
        switch scheme.background {
        case .solid(let color):
            backgroundColor = color
        case .gradient(let config):
            backgroundColor = config.colors.first ?? .white
        case .image(_, _):
            backgroundColor = .white // Fallback for complex backgrounds
        case .transparent:
            backgroundColor = .clear
        }
        
        colorFilter.setValue(CIColor(cgColor: foregroundColor.cgColor), forKey: "inputColor0")
        colorFilter.setValue(CIColor(cgColor: backgroundColor.cgColor), forKey: "inputColor1")
        
        guard let outputImage = colorFilter.outputImage else {
            throw QRBrandingError.colorProcessingFailed
        }
        
        return outputImage
    }
    
    private func addLogoToQR(_ qrImage: UIImage, logo: QRLogo) throws -> UIImage {
        #if canImport(UIKit)
        let qrSize = qrImage.size
        let logoSize = CGSize(
            width: qrSize.width * logo.size.scale,
            height: qrSize.height * logo.size.scale
        )
        
        let renderer = UIGraphicsImageRenderer(size: qrSize)
        return renderer.image { context in
            // Draw QR code
            qrImage.draw(at: .zero)
            
            // Calculate logo position
            let logoPosition = logo.position.calculatePosition(in: CGRect(origin: .zero, size: qrSize))
            let logoRect = CGRect(
                x: logoPosition.x - logoSize.width / 2,
                y: logoPosition.y - logoSize.height / 2,
                width: logoSize.width,
                height: logoSize.height
            )
            
            // Draw logo background if needed
            if case .badge = logo.style {
                context.cgContext.setFillColor(UIColor.white.cgColor)
                context.cgContext.fillEllipse(in: logoRect.insetBy(dx: -5, dy: -5))
            }
            
            // Draw logo
            logo.image.draw(in: logoRect)
        }
        #else
        throw QRBrandingError.unsupportedPlatform
        #endif
    }
    
    private func convertToUIImage(_ ciImage: CIImage) throws -> UIImage {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            throw QRBrandingError.imageProcessingFailed
        }
        return UIImage(cgImage: cgImage)
    }
    
    /// Apply branding to an existing QR code image
    public func applyBranding(to qrImage: CIImage, branding: QRBranding, size: CGSize = CGSize(width: 512, height: 512)) throws -> UIImage {
        // Apply color scheme
        let coloredImage = try applyColorScheme(qrImage, scheme: branding.colorScheme)
        
        // Scale to requested size
        let scale = min(size.width / coloredImage.extent.width, size.height / coloredImage.extent.height)
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = coloredImage.transformed(by: transform)
        
        // Convert to UIImage and add logo if needed
        var finalImage = try convertToUIImage(scaledImage)
        if let logo = branding.logo {
            finalImage = try addLogoToQR(finalImage, logo: logo)
        }
        
        return finalImage
    }
    
    /// Apply contextual branding optimization based on usage context
    public func applyContextualBranding(
        to qrImage: CIImage, 
        branding: QRBranding, 
        size: CGSize = CGSize(width: 400, height: 400), 
        context: BrandingContext
    ) throws -> UIImage {
        // Apply basic branding first
        var optimizedBranding = branding
        
        // Optimize based on context
        switch context.displayType {
        case .mobile:
            // Mobile optimization - smaller logos, higher contrast
            if let logo = branding.logo {
                let optimizedLogo = QRLogo(
                    image: logo.image,
                    position: logo.position,
                    size: .small, // Smaller for mobile
                    style: logo.style,
                    effects: logo.effects
                )
                optimizedBranding = QRBranding(
                    logo: optimizedLogo,
                    colorScheme: branding.colorScheme,
                    template: branding.template,
                    errorCorrectionLevel: .high, // High for mobile scanning
                    brandIdentifier: branding.brandIdentifier
                )
            }
            
        case .print:
            // Print optimization - medium logos, print-safe colors
            if let logo = branding.logo {
                let optimizedLogo = QRLogo(
                    image: logo.image,
                    position: logo.position,
                    size: .medium,
                    style: logo.style,
                    effects: logo.effects
                )
                optimizedBranding = QRBranding(
                    logo: optimizedLogo,
                    colorScheme: branding.colorScheme,
                    template: branding.template,
                    errorCorrectionLevel: .medium,
                    brandIdentifier: branding.brandIdentifier
                )
            }
            
        case .billboard:
            // Billboard optimization - larger logos, high contrast
            if let logo = branding.logo {
                let optimizedLogo = QRLogo(
                    image: logo.image,
                    position: logo.position,
                    size: .large, // Larger for distance viewing
                    style: logo.style,
                    effects: logo.effects
                )
                optimizedBranding = QRBranding(
                    logo: optimizedLogo,
                    colorScheme: branding.colorScheme,
                    template: branding.template,
                    errorCorrectionLevel: .high,
                    brandIdentifier: branding.brandIdentifier
                )
            }
        }
        
        // Apply the optimized branding
        return try applyBranding(to: qrImage, branding: optimizedBranding, size: size)
    }
}

// MARK: - Pre-configured Brand Templates

// MARK: - QR Branding Presets

public struct QRBrandingPresets {
    public static func equityBank(logo: UIImage) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .solid(.black),
            background: .solid(.white),
            finderPatterns: .solid(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)),
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .medium,
            style: .badge,
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.2),
                border: BorderConfig(color: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0), width: 2)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .premium,
            errorCorrectionLevel: .high,
            brandIdentifier: "equity"
        )
    }
    
    public static func safaricomMPesa(logo: UIImage) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .solid(.black),
            background: .solid(.white),
            finderPatterns: .gradient(QRColorScheme.GradientConfig(
                colors: [
                    UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0),
                    UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
                ],
                direction: .radial(center: CGPoint(x: 0.5, y: 0.5), radius: 1.0)
            )),
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .medium,
            style: .badge,
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.2),
                border: BorderConfig(color: UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), width: 2)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .modern,
            errorCorrectionLevel: .high,
            brandIdentifier: "mpesa"
        )
    }
    
    public static func techStartup(logo: UIImage, primaryColor: UIColor, secondaryColor: UIColor) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .gradient(QRColorScheme.GradientConfig(
                colors: [primaryColor, secondaryColor],
                direction: .linear(angle: Float.pi / 4)
            )),
            background: .solid(.white),
            finderPatterns: .individual(QRColorScheme.IndividualFinderConfig(
                topLeft: primaryColor,
                topRight: secondaryColor,
                bottomLeft: UIColor.blend(primaryColor, secondaryColor, ratio: 0.5)
            )),
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .large,
            style: .neon(primaryColor),
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.1), 
                glow: GlowConfig(color: primaryColor, intensity: 0.8, radius: 12)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .premium,
            errorCorrectionLevel: .high,
            brandIdentifier: "tech"
        )
    }
}

extension QRBranding {
    /// Equity Bank brand template
    public static func equityBank(logo: UIImage) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .solid(.black),
            background: .solid(.white),
            finderPatterns: .solid(UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)), // Equity red
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .medium,
            style: .badge,
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.2),
                border: BorderConfig(color: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0), width: 2)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .premium,
            errorCorrectionLevel: .high,
            brandIdentifier: "equity"
        )
    }
    
    /// Safaricom M-PESA brand template
    public static func safaricomMPesa(logo: UIImage) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .solid(.black),
            background: .solid(.white),
            finderPatterns: .gradient(QRColorScheme.GradientConfig(
                colors: [
                    UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0),
                    UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
                ],
                direction: .radial(center: CGPoint(x: 0.5, y: 0.5), radius: 1.0)
            )),
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .medium,
            style: .badge,
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.2),
                border: BorderConfig(color: UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 1.0), width: 2)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .modern,
            errorCorrectionLevel: .high,
            brandIdentifier: "mpesa"
        )
    }
    
    /// Tech startup brand template
    public static func techStartup(logo: UIImage, primaryColor: UIColor, secondaryColor: UIColor) -> QRBranding {
        let colorScheme = QRColorScheme(
            dataPattern: .gradient(QRColorScheme.GradientConfig(
                colors: [primaryColor, secondaryColor],
                direction: .linear(angle: Float.pi / 4)
            )),
            background: .solid(.white),
            finderPatterns: .individual(QRColorScheme.IndividualFinderConfig(
                topLeft: primaryColor,
                topRight: secondaryColor,
                bottomLeft: UIColor.blend(primaryColor, secondaryColor, ratio: 0.5)
            )),
            logoBackgroundColor: .white
        )
        
        let logoConfig = QRLogo(
            image: logo,
            position: .center,
            size: .large,
            style: .neon(primaryColor),
            effects: LogoEffects(
                shadow: ShadowConfig(color: .black, opacity: 0.1), glow: GlowConfig(color: primaryColor, intensity: 0.8, radius: 12)
            )
        )
        
        return QRBranding(
            logo: logoConfig,
            colorScheme: colorScheme,
            template: .premium,
            errorCorrectionLevel: .high,
            brandIdentifier: "tech"
        )
    }
}

// MARK: - UIColor Extension

extension UIColor {
    /// Blend two colors with a given ratio
    static func blend(_ color1: UIColor, _ color2: UIColor, ratio: Float) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 * (1 - CGFloat(ratio)) + r2 * CGFloat(ratio)
        let g = g1 * (1 - CGFloat(ratio)) + g2 * CGFloat(ratio)
        let b = b1 * (1 - CGFloat(ratio)) + b2 * CGFloat(ratio)
        let a = a1 * (1 - CGFloat(ratio)) + a2 * CGFloat(ratio)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
} 
