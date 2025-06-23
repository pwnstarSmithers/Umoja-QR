//
//  QRCodeSDK.swift
//  QRCodeSDK
//
//  Created by Mugalu on 20/06/2025.
//

import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Main SDK Interface

/// QRCodeSDK - Comprehensive QR Code SDK for Kenya and Tanzania payment standards
/// Supports EMVCo compliance, CBK Kenya QR standards, and Tanzania TAN-QR
public final class QRCodeSDK {
    
    // MARK: - Shared Instance
    
    /// Shared SDK instance for convenience
    public static let shared = QRCodeSDK()
    
    // MARK: - Core Components
    
    private let parser: EnhancedQRParser
    private let generator: EnhancedQRGenerator
    private let brandingEngine: QRBrandingEngine
    
    // MARK: - Initialization
    
    /// Initialize a new SDK instance
    public init() {
        self.parser = EnhancedQRParser()
        self.generator = EnhancedQRGenerator()
        self.brandingEngine = QRBrandingEngine.shared
    }
    
    // MARK: - QR Code Parsing
    
    /// Parse a QR code string with enhanced multi-country support
    /// - Parameter qrString: The QR code data string
    /// - Returns: Parsed QR code information with all fields
    /// - Throws: ValidationError for parsing failures
    public func parseQRCode(_ qrString: String) throws -> ParsedQRCode {
        return try parser.parseQR(qrString)
    }
    
    // MARK: - QR Code Generation
    
    /// Generate a QR code image from request data
    /// - Parameters:
    ///   - request: QR code generation request with payment details
    ///   - style: Visual styling options (optional)
    /// - Returns: Generated QR code as UIImage
    /// - Throws: QRGenerationError for generation failures
    public func generateQRCode(from request: QRCodeGenerationRequest, 
                              style: QRCodeStyle = QRCodeStyle()) throws -> UIImage {
        return try generator.generateQR(from: request, style: style)
    }
    
    /// Generate QR code as string (for validation/testing)
    /// - Parameter request: QR code generation request
    /// - Returns: Complete TLV string with EMVCo compliance
    /// - Throws: QRGenerationError for generation failures
    public func generateQRString(from request: QRCodeGenerationRequest) throws -> String {
        return try generator.generateQRString(from: request)
    }
    
    // MARK: - Branded QR Code Generation
    
    /// Generate a branded QR code with custom styling and logo
    /// - Parameters:
    ///   - request: QR code generation request
    ///   - branding: Branding configuration with logo and colors
    /// - Returns: Branded QR code as UIImage
    /// - Throws: QRGenerationError for generation failures
    public func generateBrandedQRCode(from request: QRCodeGenerationRequest,
                                     branding: QRBranding) throws -> UIImage {
        return try brandingEngine.generateBrandedQR(from: request, branding: branding)
    }
    
    // MARK: - Convenience Methods
    
    /// Quick Kenya P2P QR generation
    /// - Parameters:
    ///   - phoneNumber: Mobile money phone number
    ///   - amount: Transaction amount (optional for static QR)
    ///   - recipientName: Recipient name
    /// - Returns: Generated QR code image
    /// - Throws: QRGenerationError for generation failures
    public func generateKenyaP2PQR(phoneNumber: String, 
                                  amount: Decimal? = nil,
                                  recipientName: String) throws -> UIImage {
        guard let template = AccountTemplateBuilder.kenyaTelecom(guid: "MPESA", phoneNumber: phoneNumber) else {
            throw QRGenerationError.invalidConfiguration("Invalid phone number format")
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: amount != nil ? .dynamic : .static,
            accountTemplates: [template],
            merchantCategoryCode: "6012", // P2P MCC
            amount: amount,
            recipientName: recipientName,
            currency: "404", // KES
            countryCode: "KE"
        )
        
        return try generateQRCode(from: request)
    }
    
    /// Quick Kenya merchant QR generation
    /// - Parameters:
    ///   - merchantId: Merchant identifier
    ///   - amount: Transaction amount (optional for static QR)
    ///   - merchantName: Merchant name
    ///   - mcc: Merchant category code
    /// - Returns: Generated QR code image
    /// - Throws: QRGenerationError for generation failures
    public func generateKenyaMerchantQR(merchantId: String,
                                       amount: Decimal? = nil,
                                       merchantName: String,
                                       mcc: String = "5411") throws -> UIImage {
        guard let template = AccountTemplateBuilder.kenyaBank(guid: "EQLT", accountNumber: merchantId) else {
            throw QRGenerationError.invalidConfiguration("Invalid merchant ID")
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: amount != nil ? .dynamic : .static,
            accountTemplates: [template],
            merchantCategoryCode: mcc,
            amount: amount,
            recipientName: merchantName,
            currency: "404", // KES
            countryCode: "KE"
        )
        
        return try generateQRCode(from: request)
    }
    
    // MARK: - Validation
    
    /// Validate a QR code string without full parsing
    /// - Parameter qrString: QR code data string
    /// - Returns: True if valid, false otherwise
    public func isValidQRCode(_ qrString: String) -> Bool {
        do {
            _ = try parseQRCode(qrString)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - SDK Information
    
    /// Current SDK version
    public static let version = "1.0.0"
    
    /// Supported countries
    public static let supportedCountries: [Country] = [.kenya, .tanzania]
    
    /// Supported QR types
    public static let supportedQRTypes: [QRType] = [.p2p, .p2m]
    
    /// Debug a QR code to identify parsing issues
    /// - Parameter qrString: The QR code string to debug
    /// - Returns: Debug analysis of the QR structure
    public func debugQRCode(_ qrString: String) -> String {
        return DebugTools.debugTLVStructure(qrString)
    }
    
    /// Attempt to parse a QR code with enhanced error reporting
    /// - Parameter qrString: The QR code string to parse
    /// - Returns: Either a successfully parsed QR code or detailed error information
    public func parseQRWithDiagnostics(_ qrString: String) -> QRParseResult {
        do {
            let parsed = try parser.parseQR(qrString)
            return .success(parsed)
        } catch let error as ValidationError {
            let diagnostics = generateDiagnostics(for: qrString, error: error)
            return .failure(error, diagnostics)
        } catch {
            let diagnostics = "Unexpected error: \(error.localizedDescription)"
            return .failure(ValidationError.malformedData, diagnostics)
        }
    }
    
    /// Generate detailed diagnostics for parsing failures
    private func generateDiagnostics(for qrString: String, error: ValidationError) -> String {
        var diagnostics = "🔍 QR Code Diagnostics\n"
        diagnostics += "======================\n\n"
        
        diagnostics += "❌ Parsing Error: \(error.localizedDescription)\n"
        diagnostics += "💡 Recovery Suggestion: \(error.recoverySuggestion)\n\n"
        
        diagnostics += "📊 TLV Structure Analysis:\n"
        diagnostics += DebugTools.debugTLVStructure(qrString)
        
        // Add specific suggestions based on error type
        switch error {
        case .invalidFieldLength(let tag, let actual, let expected):
            diagnostics += "\n🔧 Specific Issue Analysis:\n"
            diagnostics += "Tag \(tag) has incorrect length:\n"
            diagnostics += "- Found: \(actual) characters\n"
            if let expected = expected {
                diagnostics += "- Expected: \(expected) characters\n"
            }
            diagnostics += "- This usually indicates malformed QR data\n"
            
        case .malformedData:
            diagnostics += "\n🔧 Possible Causes:\n"
            diagnostics += "- QR code was truncated or corrupted\n"
            diagnostics += "- Invalid TLV structure (Tag-Length-Value format)\n"
            diagnostics += "- Missing or extra characters\n"
            
        case .invalidChecksum:
            diagnostics += "\n🔧 Checksum Issue:\n"
            diagnostics += "- CRC16 validation failed\n"
            diagnostics += "- QR code may have been modified or corrupted\n"
            
        default:
            break
        }
        
        return diagnostics
    }
}

// MARK: - Quick Access Extensions

public extension QRCodeSDK {
    
    /// Quick access to parser
    var qrParser: EnhancedQRParser {
        return parser
    }
    
    /// Quick access to generator
    var qrGenerator: EnhancedQRGenerator {
        return generator
    }
    
    /// Quick access to branding engine
    var qrBrandingEngine: QRBrandingEngine {
        return brandingEngine
    }
}

