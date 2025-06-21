import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Enhanced QR Generator

public class EnhancedQRGenerator {
    
    private let parser = EnhancedQRParser()
    private let pspDirectory = PSPDirectory.shared
    
    public init() {}
    
    // MARK: - QR Generation
    
    /// Generate a QR code with enhanced EMVCo compliance and multi-country support
    /// - Parameters:
    ///   - request: QR code generation request with all necessary data
    ///   - style: Visual styling options for the QR code
    /// - Returns: Generated UIImage of the QR code
    /// - Throws: QRGenerationError for various generation failures
    public func generateQR(from request: QRCodeGenerationRequest, 
                          style: QRCodeStyle = QRCodeStyle()) throws -> UIImage {
        
        // Build TLV string with EMVCo compliance
        let tlvString = try buildEMVCoCompliantTLV(from: request)
        
        // Generate QR code image
        let qrImage = try generateQRImage(from: tlvString, style: style)
        
        return qrImage
    }
    
    /// Generate QR code and return as data string (for validation/testing)
    /// - Parameter request: QR code generation request
    /// - Returns: Complete TLV string with proper EMVCo ordering
    /// - Throws: QRGenerationError for various generation failures
    public func generateQRString(from request: QRCodeGenerationRequest) throws -> String {
        return try buildEMVCoCompliantTLV(from: request)
    }
    
    // MARK: - EMVCo Compliant TLV Building
    
    private func buildEMVCoCompliantTLV(from request: QRCodeGenerationRequest) throws -> String {
        var tlvComponents: [String] = []
        
        // Validate multi-PSP configuration per country
        try validateMultiPSPConfiguration(request)
        
        // Tag 00: Payload Format Indicator (always "01")
        tlvComponents.append(formatTLV(tag: "00", value: "01"))
        
        // Tag 01: Point of Initiation Method
        tlvComponents.append(formatTLV(tag: "01", value: request.initiationMethod.rawValue))
        
        // Tags 26-51: Account Templates (ordered by tag number)
        let sortedTemplates = request.accountTemplates.sorted { $0.tag < $1.tag }
        for template in sortedTemplates {
            let templateTLV = try buildAccountTemplateTLV(template)
            tlvComponents.append(templateTLV)
        }
        
        // Tag 52: Merchant Category Code
        tlvComponents.append(formatTLV(tag: "52", value: request.merchantCategoryCode))
        
        // Tag 53: Transaction Currency
        tlvComponents.append(formatTLV(tag: "53", value: request.currency))
        
        // Tag 54: Transaction Amount (only for dynamic QR)
        if request.initiationMethod == .dynamic, let amount = request.amount {
            let amountString = formatAmount(amount)
            tlvComponents.append(formatTLV(tag: "54", value: amountString))
        }
        
        // Tag 58: Country Code
        tlvComponents.append(formatTLV(tag: "58", value: request.countryCode))
        
        // Tag 59: Merchant/Recipient Name (optional but recommended)
        if let recipientName = request.recipientName {
            let sanitizedName = sanitizeName(recipientName, maxLength: 25)
            tlvComponents.append(formatTLV(tag: "59", value: sanitizedName))
        }
        
        // Tag 60: Merchant City/Recipient Identifier
        if let recipientCity = request.recipientCity {
            let sanitizedCity = sanitizeName(recipientCity, maxLength: 15)
            tlvComponents.append(formatTLV(tag: "60", value: sanitizedCity))
        } else if let recipientId = request.recipientIdentifier {
            // For P2P, use recipient identifier in Tag 60
            tlvComponents.append(formatTLV(tag: "60", value: recipientId))
        }
        
        // Tag 61: Postal Code (optional)
        if let postalCode = request.postalCode {
            tlvComponents.append(formatTLV(tag: "61", value: postalCode))
        }
        
        // Tag 62: Additional Data (optional)
        if let additionalData = request.additionalData {
            let additionalDataTLV = buildAdditionalDataTLV(additionalData)
            if !additionalDataTLV.isEmpty {
                tlvComponents.append(formatTLV(tag: "62", value: additionalDataTLV))
            }
        }
        
        // Tag 64: Format Version (EMVCo compliance - BEFORE Tag 63)
        if let formatVersion = request.formatVersion {
            tlvComponents.append(formatTLV(tag: "64", value: formatVersion))
        }
        
        // Join all components
        let dataWithoutCRC = tlvComponents.joined()
        
        // Tag 63: CRC16 Checksum (MUST be last for EMVCo compliance)
        // Calculate CRC for data + CRC tag ID and length according to CBK standard
        let dataForCRC = dataWithoutCRC + "6304"
        let crc16 = calculateCRC16(dataForCRC)
        let finalTLVString = dataWithoutCRC + formatTLV(tag: "63", value: crc16)
        
        return finalTLVString
    }
    
    // MARK: - Multi-PSP Configuration Validation
    
    private func validateMultiPSPConfiguration(_ request: QRCodeGenerationRequest) throws {
        guard !request.accountTemplates.isEmpty else {
            throw QRGenerationError.missingRequiredField("accountTemplates")
        }
        
        // Determine country from first template
        let country = request.accountTemplates.first?.pspInfo.country ?? .kenya
        
        switch country {
        case .tanzania:
            // Tanzania MUST use only Tag 26 (unified TIPS template)
            for template in request.accountTemplates {
                guard template.tag == "26" else {
                    throw QRGenerationError.invalidConfiguration("Tanzania must use Tag 26")
                }
                
                guard template.guid == "tz.go.bot.tips" else {
                    throw QRGenerationError.invalidConfiguration("Tanzania must use TIPS GUID")
                }
            }
            
            // Tanzania should have exactly one template
            if request.accountTemplates.count > 1 {
                throw QRGenerationError.invalidConfiguration("Tanzania supports single unified template only")
            }
            
        case .kenya:
            // Kenya can use multiple templates but with restrictions
            let tags = Set(request.accountTemplates.map { $0.tag })
            
            // Validate tag usage
            for template in request.accountTemplates {
                switch template.tag {
                case "28": // Telecom template
                    guard template.pspInfo.type == .telecom else {
                        throw QRGenerationError.invalidConfiguration("Tag 28 requires telecom PSP")
                    }
                case "29": // Bank template
                    guard template.pspInfo.type == .bank else {
                        throw QRGenerationError.invalidConfiguration("Tag 29 requires bank PSP")
                    }
                case "26":
                    // Tag 26 not typically used for Kenya
                    break
                default:
                    // Other tags are allowed
                    break
                }
            }
            
            // Validate CBK domestic format usage
            for template in request.accountTemplates {
                if template.guid == "ke.go.qr" {
                    // CBK domestic format - ensure proper PSP ID
                    if template.participantId == nil {
                        throw QRGenerationError.missingRequiredField("participantId for CBK domestic format")
                    }
                }
            }
        }
    }
    
    // MARK: - Account Template Building
    
    private func buildAccountTemplateTLV(_ template: AccountTemplate) throws -> String {
        let country = Country(rawValue: template.pspInfo.country.rawValue) ?? .kenya
        
        switch country {
        case .kenya:
            return try buildKenyaAccountTemplate(template)
        case .tanzania:
            return try buildTanzaniaAccountTemplate(template)
        }
    }
    
    private func buildKenyaAccountTemplate(_ template: AccountTemplate) throws -> String {
        var nestedComponents: [String] = []
        
        // Sub-tag 00: CBK domestic identifier
        nestedComponents.append(formatTLV(tag: "00", value: template.guid))
        
        // CBK Standard Format: Following CBK document structure
        if template.guid == "ke.go.qr" {
            // CBK domestic format - PSP ID concatenated with account data
            if let participantId = template.participantId, let accountId = template.accountId {
                // Format: PSP_ID + ACCOUNT_DATA (following CBK standard example)
                // Example from CBK doc: "01888880" = PSP ID "01" + account "888880"
                let pspAccountData = participantId + accountId
                nestedComponents.append(formatTLV(tag: "68", value: pspAccountData))
            } else if let participantId = template.participantId {
                // Fallback: just PSP ID
                nestedComponents.append(formatTLV(tag: "68", value: participantId))
            }
        } else {
            // Legacy format for backward compatibility
            if let accountId = template.accountId {
                nestedComponents.append(formatTLV(tag: "68", value: accountId))
            } else if let participantId = template.participantId {
                nestedComponents.append(formatTLV(tag: "68", value: participantId))
            }
        }
        
        let nestedValue = nestedComponents.joined()
        return formatTLV(tag: template.tag, value: nestedValue)
    }
    
    private func buildTanzaniaAccountTemplate(_ template: AccountTemplate) throws -> String {
        guard template.tag == "26" else {
            throw QRGenerationError.invalidConfiguration("Tanzania must use Tag 26")
        }
        
        var nestedComponents: [String] = []
        
        // Sub-tag 00: TIPS GUID
        nestedComponents.append(formatTLV(tag: "00", value: "tz.go.bot.tips"))
        
        // Sub-tag 01: Acquirer ID
        if let participantId = template.participantId {
            nestedComponents.append(formatTLV(tag: "01", value: participantId))
        } else {
            throw QRGenerationError.missingRequiredField("participantId for Tanzania")
        }
        
        // Sub-tag 02: Merchant ID
        if let accountId = template.accountId {
            nestedComponents.append(formatTLV(tag: "02", value: accountId))
        }
        
        let nestedValue = nestedComponents.joined()
        return formatTLV(tag: template.tag, value: nestedValue)
    }
    
    // MARK: - Additional Data Building (Tag 62)
    
    private func buildAdditionalDataTLV(_ additionalData: AdditionalData) -> String {
        var nestedComponents: [String] = []
        
        // Standard sub-tags (01-09)
        if let billNumber = additionalData.billNumber {
            nestedComponents.append(formatTLV(tag: "01", value: billNumber))
        }
        
        if let mobileNumber = additionalData.mobileNumber {
            nestedComponents.append(formatTLV(tag: "02", value: mobileNumber))
        }
        
        if let storeLabel = additionalData.storeLabel {
            nestedComponents.append(formatTLV(tag: "03", value: storeLabel))
        }
        
        if let loyaltyNumber = additionalData.loyaltyNumber {
            nestedComponents.append(formatTLV(tag: "04", value: loyaltyNumber))
        }
        
        if let referenceLabel = additionalData.referenceLabel {
            nestedComponents.append(formatTLV(tag: "05", value: referenceLabel))
        }
        
        if let customerLabel = additionalData.customerLabel {
            nestedComponents.append(formatTLV(tag: "06", value: customerLabel))
        }
        
        if let terminalLabel = additionalData.terminalLabel {
            nestedComponents.append(formatTLV(tag: "07", value: terminalLabel))
        }
        
        if let purposeOfTransaction = additionalData.purposeOfTransaction {
            nestedComponents.append(formatTLV(tag: "08", value: purposeOfTransaction))
        }
        
        if let additionalConsumerDataRequest = additionalData.additionalConsumerDataRequest {
            nestedComponents.append(formatTLV(tag: "09", value: additionalConsumerDataRequest))
        }
        
        // Custom fields (50-99)
        let sortedCustomFields = additionalData.customFields.sorted { $0.key < $1.key }
        for (tag, value) in sortedCustomFields {
            if let tagNumber = Int(tag), tagNumber >= 50 && tagNumber <= 99 {
                nestedComponents.append(formatTLV(tag: tag, value: value))
            }
        }
        
        return nestedComponents.joined()
    }
    
    // MARK: - Helper Functions
    
    private func formatTLV(tag: String, value: String) -> String {
        let length = String(format: "%02d", value.count)
        return tag + length + value
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
    
    private func sanitizeName(_ name: String, maxLength: Int) -> String {
        // Remove special characters and trim to max length
        let sanitized = name
            .replacingOccurrences(of: #"[^\w\s-.]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return String(sanitized.prefix(maxLength))
    }
    
    // MARK: - CRC16 Calculation
    
    private func calculateCRC16(_ data: String) -> String {
        // CRC-CCITT (False) implementation as per CBK specification
        // Polynomial: 0x1021, Initial: 0xFFFF
        var crc: UInt16 = 0xFFFF
        let polynomial: UInt16 = 0x1021
        
        for byte in data.utf8 {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if crc & 0x8000 != 0 {
                    crc = (crc << 1) ^ polynomial
                } else {
                    crc <<= 1
                }
                crc &= 0xFFFF
            }
        }
        
        return String(format: "%04X", crc)
    }
    
    // MARK: - QR Image Generation
    
    private func generateQRImage(from string: String, style: QRCodeStyle) throws -> UIImage {
        guard let data = string.data(using: .utf8) else {
            throw QRGenerationError.invalidInputData
        }
        
        // Create QR code using Core Image
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(style.errorCorrectionLevel.qrLevel, forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        // Scale and style the image
        let scaledImage = scaleQRImage(outputImage, to: style.size)
        let styledImage = try applyStyle(to: scaledImage, style: style)
        
        return styledImage
    }
    
    private func scaleQRImage(_ image: CIImage, to size: CGSize) -> CIImage {
        let extent = image.extent
        let scale = min(size.width / extent.width, size.height / extent.height)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return image.transformed(by: transform)
    }
    
    private func applyStyle(to image: CIImage, style: QRCodeStyle) throws -> UIImage {
        var styledImage = image
        
        // Apply colors if different from default
        if style.foregroundColor != .black || style.backgroundColor != .white {
            guard let colorFilter = CIFilter(name: "CIFalseColor") else {
                throw QRGenerationError.qrGenerationFailed
            }
            
            colorFilter.setValue(styledImage, forKey: "inputImage")
            colorFilter.setValue(CIColor(color: style.foregroundColor), forKey: "inputColor0")
            colorFilter.setValue(CIColor(color: style.backgroundColor), forKey: "inputColor1")
            
            if let coloredImage = colorFilter.outputImage {
                styledImage = coloredImage
            }
        }
        
        // Convert to UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(styledImage, from: styledImage.extent) else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        var finalImage = UIImage(cgImage: cgImage)
        
        // Add logo if specified
        if let logo = style.logo {
            finalImage = try addLogo(logo, to: finalImage, logoSize: style.logoSize)
        }
        
        return finalImage
    }
    
    private func addLogo(_ logo: UIImage, to qrImage: UIImage, logoSize: CGSize?) throws -> UIImage {
        let size = qrImage.size
        let logoTargetSize = logoSize ?? CGSize(width: size.width * 0.2, height: size.height * 0.2)
        
        UIGraphicsBeginImageContextWithOptions(size, false, qrImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        qrImage.draw(in: CGRect(origin: .zero, size: size))
        
        let logoRect = CGRect(
            x: (size.width - logoTargetSize.width) / 2,
            y: (size.height - logoTargetSize.height) / 2,
            width: logoTargetSize.width,
            height: logoTargetSize.height
        )
        
        logo.draw(in: logoRect)
        
        guard let combinedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        return combinedImage
    }
}

// MARK: - QR Generation Errors

public enum QRGenerationError: Error, LocalizedError {
    case invalidInputData
    case invalidConfiguration(String)
    case missingRequiredField(String)
    case qrGenerationFailed
    case unsupportedCountry
    case unsupportedPSPType
    case imageRenderingFailed
    case logoProcessingFailed
    case unsupportedCurrency
    case invalidPSPConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .invalidInputData:
            return "Invalid input data for QR generation"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .qrGenerationFailed:
            return "QR code generation failed"
        case .unsupportedCountry:
            return "Unsupported country for QR generation"
        case .unsupportedPSPType:
            return "Unsupported PSP type for QR generation"
        case .imageRenderingFailed:
            return "Failed to render QR code image"
        case .logoProcessingFailed:
            return "Failed to process logo image"
        case .unsupportedCurrency:
            return "Currency not supported"
        case .invalidPSPConfiguration:
            return "PSP configuration is invalid"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .invalidInputData:
            return "Check the input data format and try again"
        case .invalidConfiguration:
            return "Review the QR code configuration parameters"
        case .missingRequiredField:
            return "Provide all required fields for QR generation"
        case .qrGenerationFailed:
            return "Try generating the QR code again"
        case .unsupportedCountry:
            return "Use a supported country code (KE or TZ)"
        case .unsupportedPSPType:
            return "Use a supported PSP type for the selected country"
        case .imageRenderingFailed:
            return "Try generating the QR code again"
        case .logoProcessingFailed:
            return "Check the logo image format and try again"
        case .unsupportedCurrency:
            return "Use a supported currency code"
        case .invalidPSPConfiguration:
            return "Review the PSP configuration parameters"
        }
    }
}

// MARK: - Convenience Generators

extension EnhancedQRGenerator {
    
    /// Generate Kenya P2P QR code (legacy compatibility)
    public func generateKenyaP2PQR(recipientName: String?, recipientIdentifier: String, 
                                  pspInfo: PSPInfo, amount: Decimal? = nil, 
                                  purpose: String? = nil, isStatic: Bool = true) throws -> String {
        
        let accountTemplate = AccountTemplate(
            tag: pspInfo.templateTag,
            guid: pspInfo.identifier,
            participantId: pspInfo.identifier,
            accountId: recipientIdentifier,
            pspInfo: pspInfo
        )
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: isStatic ? .static : .dynamic,
            accountTemplates: [accountTemplate],
            merchantCategoryCode: "6011",
            amount: amount,
            recipientName: recipientName,
            recipientIdentifier: recipientIdentifier,
            currency: Country.kenya.currencyCode,
            countryCode: Country.kenya.rawValue,
            additionalData: purpose != nil ? AdditionalData(purposeOfTransaction: purpose) : nil,
            formatVersion: "P2P-KE-01"
        )
        
        return try generateQRString(from: request)
    }
    
    /// Generate multi-PSP QR code (Kenya banks + mobile money)
    public func generateMultiPSPQR(recipientName: String, recipientIdentifier: String,
                                  bankPSP: PSPInfo, telecomPSP: PSPInfo, 
                                  amount: Decimal? = nil, isStatic: Bool = true) throws -> String {
        
        let bankTemplate = AccountTemplate(
            tag: "29",
            guid: bankPSP.identifier,
            participantId: bankPSP.identifier,
            accountId: recipientIdentifier,
            pspInfo: bankPSP
        )
        
        let telecomTemplate = AccountTemplate(
            tag: "28",
            guid: telecomPSP.identifier,
            participantId: telecomPSP.identifier,
            accountId: recipientIdentifier,
            pspInfo: telecomPSP
        )
        
        let request = QRCodeGenerationRequest(
            qrType: .p2p,
            initiationMethod: isStatic ? .static : .dynamic,
            accountTemplates: [bankTemplate, telecomTemplate],
            merchantCategoryCode: "6011",
            amount: amount,
            recipientName: recipientName,
            recipientIdentifier: recipientIdentifier,
            currency: Country.kenya.currencyCode,
            countryCode: Country.kenya.rawValue,
            formatVersion: "P2P-KE-01"
        )
        
        return try generateQRString(from: request)
    }
    
    // MARK: - Phase 2: Kenya P2M Merchant QR Generation
    
    /// Generate static merchant QR code for Kenya
    public func generateKenyaStaticMerchantQR(
        merchantName: String,
        merchantCity: String,
        mcc: String,
        merchantId: String,
        accountTemplates: [AccountTemplate],
        additionalData: AdditionalData? = nil
    ) throws -> UIImage {
        
        // Validate MCC
        guard MerchantCategories.shared.isValidMCC(mcc) else {
            throw QRGenerationError.invalidConfiguration("Invalid MCC: \(mcc)")
        }
        
        let validationRules = MerchantCategories.shared.getValidationRules(for: mcc)
        
        // Apply validation rules
        if validationRules.requiresMerchantName && merchantName.isEmpty {
            throw QRGenerationError.missingRequiredField("merchantName")
        }
        
        if validationRules.requiresCity && merchantCity.isEmpty {
            throw QRGenerationError.missingRequiredField("merchantCity")
        }
        
        if !validationRules.allowsStaticQR {
            throw QRGenerationError.invalidConfiguration("Static QR not allowed for MCC \(mcc)")
        }
        
        // Build enhanced additional data for merchant
        var merchantAdditionalData = additionalData ?? AdditionalData()
        merchantAdditionalData.merchantCategory = MerchantCategories.shared.getCategoryType(mcc: mcc).rawValue
        merchantAdditionalData.merchantSubCategory = MerchantCategories.shared.getDisplayName(mcc: mcc)
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .static,
            accountTemplates: accountTemplates,
            merchantCategoryCode: mcc,
            amount: nil,
            recipientName: merchantName,
            recipientIdentifier: merchantId, recipientCity: merchantCity,
            currency: Country.kenya.currencyCode,
            countryCode: Country.kenya.rawValue,
            additionalData: merchantAdditionalData,
            formatVersion: "P2M-KE-01"
        )
        
        return try generateQR(from: request)
    }
    
    /// Generate dynamic merchant QR code for Kenya
    public func generateKenyaDynamicMerchantQR(
        merchantName: String,
        merchantCity: String,
        mcc: String,
        merchantId: String,
        amount: Decimal,
        accountTemplates: [AccountTemplate],
        additionalData: AdditionalData? = nil,
        tipIndicator: String? = nil,
        convenienceFeeIndicator: String? = nil
    ) throws -> UIImage {
        
        // Validate MCC and amount
        guard MerchantCategories.shared.isValidMCC(mcc) else {
            throw QRGenerationError.invalidConfiguration("Invalid MCC: \(mcc)")
        }
        
        guard amount > 0 else {
            throw QRGenerationError.invalidConfiguration("Amount must be greater than 0")
        }
        
        let validationRules = MerchantCategories.shared.getValidationRules(for: mcc)
        
        // Check amount limits
        if let maxLimit = validationRules.maxAmountLimit, amount > maxLimit {
            throw QRGenerationError.invalidConfiguration("Amount exceeds limit for MCC \(mcc)")
        }
        
        // Build enhanced additional data
        var merchantAdditionalData = additionalData ?? AdditionalData()
        merchantAdditionalData.merchantCategory = MerchantCategories.shared.getCategoryType(mcc: mcc).rawValue
        merchantAdditionalData.merchantSubCategory = MerchantCategories.shared.getDisplayName(mcc: mcc)
        
        if let tip = tipIndicator {
            merchantAdditionalData.tipIndicator = tip
        }
        if let fee = convenienceFeeIndicator {
            merchantAdditionalData.convenienceFeeIndicator = fee
        }
        
        let request = QRCodeGenerationRequest(
            qrType: .p2m,
            initiationMethod: .dynamic,
            accountTemplates: accountTemplates,
            merchantCategoryCode: mcc,
            amount: amount,
            recipientName: merchantName,
            recipientIdentifier: merchantId, recipientCity: merchantCity,
            currency: Country.kenya.currencyCode,
            countryCode: Country.kenya.rawValue,
            additionalData: merchantAdditionalData,
            formatVersion: "P2M-KE-01"
        )
        
        return try generateQR(from: request)
    }
    
    // MARK: - Phase 3: Tanzania TANQR Generation
    
    /// Generate Tanzania TAN-QR QR code
    public func generateTanzaniaQR(
        merchantName: String,
        merchantCity: String,
        mcc: String,
        pspCode: String,
        merchantId: String,
        amount: Decimal? = nil,
        additionalData: AdditionalData? = nil
    ) throws -> UIImage {
        
        // Create Tanzania account template using Tag 26
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: pspCode, country: .tanzania) else {
            throw QRGenerationError.invalidConfiguration("Invalid Tanzania PSP code: \(pspCode)")
        }
        
        let accountTemplate = AccountTemplate(
            tag: "26", // Tanzania unified template
            guid: "tz.go.bot.tips", // TAN-QR system identifier
            participantId: pspCode,
            accountId: merchantId,
            pspInfo: pspInfo
        )
        
        // Build Tanzania-specific additional data
        var tanzaniaAdditionalData = additionalData ?? AdditionalData()
        tanzaniaAdditionalData.tipsAcquirerId = pspCode // Keep field name for backward compatibility
        tanzaniaAdditionalData.tipsVersion = "1.0"
        tanzaniaAdditionalData.countrySpecific = "TANQR"
        
        let request = QRCodeGenerationRequest(
            qrType: amount != nil ? .p2m : .p2p,
            initiationMethod: amount != nil ? .dynamic : .static,
            accountTemplates: [accountTemplate],
            merchantCategoryCode: mcc,
            amount: amount,
            recipientName: merchantName,
            recipientIdentifier: merchantId, recipientCity: merchantCity,
            currency: Country.tanzania.currencyCode, // TZS (834)
            countryCode: Country.tanzania.rawValue,
            additionalData: tanzaniaAdditionalData,
            formatVersion: "TANQR-01"
        )
        
        return try generateQR(from: request)
    }
    
    /// Generate multi-scheme QR code (Kenya + Tanzania)
    public func generateMultiSchemeQR(
        merchantName: String,
        merchantCity: String,
        mcc: String,
        kenyaTemplates: [AccountTemplate]? = nil,
        tanzaniaPspCode: String? = nil,
        tanzaniaMerchantId: String? = nil,
        amount: Decimal? = nil,
        additionalData: AdditionalData? = nil
    ) throws -> UIImage {
        
        var allTemplates: [AccountTemplate] = []
        
        // Add Kenya templates
        if let kenyaTemplates = kenyaTemplates {
            try validateKenyaTemplates(kenyaTemplates)
            allTemplates.append(contentsOf: kenyaTemplates)
        }
        
        // Add Tanzania template if provided
        if let pspCode = tanzaniaPspCode, let merchantId = tanzaniaMerchantId {
            guard let pspInfo = PSPDirectory.shared.getPSP(guid: pspCode, country: .tanzania) else {
                throw QRGenerationError.invalidConfiguration("Invalid Tanzania PSP code: \(pspCode)")
            }
            
            let tanzaniaTemplate = AccountTemplate(
                tag: "26",
                guid: "tz.go.bot.tips",
                participantId: pspCode,
                accountId: merchantId,
                pspInfo: pspInfo
            )
            
            allTemplates.append(tanzaniaTemplate)
        }
        
        guard !allTemplates.isEmpty else {
            throw QRGenerationError.missingRequiredField("accountTemplates")
        }
        
        // Use primary country from first template
        let primaryTemplate = allTemplates.first!
        let primaryCountry = primaryTemplate.pspInfo.country
        
        // Build multi-scheme additional data
        var multiSchemeData = additionalData ?? AdditionalData()
        multiSchemeData.multiScheme = "true"
        multiSchemeData.supportedCountries = Array(Set(allTemplates.map { $0.pspInfo.country.rawValue })).joined(separator: ",")
        
        let request = QRCodeGenerationRequest(
            qrType: amount != nil ? .p2m : .p2p,
            initiationMethod: amount != nil ? .dynamic : .static,
            accountTemplates: allTemplates,
            merchantCategoryCode: mcc,
            amount: amount,
            recipientName: merchantName,
            recipientIdentifier: "\(merchantName.prefix(10))", recipientCity: merchantCity, // Generate merchant ID from name
            currency: primaryCountry.currencyCode,
            countryCode: primaryCountry.rawValue,
            additionalData: multiSchemeData,
            formatVersion: "MULTI-01"
        )
        
        return try generateQR(from: request)
    }
    
    // MARK: - Validation Helpers
    
    private func validateKenyaTemplates(_ templates: [AccountTemplate]) throws {
        for template in templates {
            guard template.pspInfo.country == .kenya else {
                throw QRGenerationError.invalidConfiguration("All Kenya templates must be from Kenya PSPs")
            }
            
            guard ["28", "29"].contains(template.tag) else {
                throw QRGenerationError.invalidConfiguration("Kenya templates must use Tag 28 or 29")
            }
        }
    }
    
    private func validateRequiredAdditionalFields(_ additionalData: AdditionalData?, for rules: MerchantValidationRules) throws {
        guard let additionalData = additionalData else {
            if !rules.requiredAdditionalFields.isEmpty {
                throw QRGenerationError.missingRequiredField("additionalData with required fields: \(rules.requiredAdditionalFields.joined(separator: ", "))")
            }
            return
        }
        
        // Check if required fields are present
        for requiredField in rules.requiredAdditionalFields {
            switch requiredField {
            case "patient_id":
                if additionalData.patientId == nil {
                    throw QRGenerationError.missingRequiredField("patientId")
                }
            case "appointment_reference":
                if additionalData.appointmentReference == nil {
                    throw QRGenerationError.missingRequiredField("appointmentReference")
                }
            case "reference_number":
                if additionalData.referenceNumber == nil {
                    throw QRGenerationError.missingRequiredField("referenceNumber")
                }
            case "service_type":
                if additionalData.serviceType == nil {
                    throw QRGenerationError.missingRequiredField("serviceType")
                }
            case "route":
                if additionalData.route == nil {
                    throw QRGenerationError.missingRequiredField("route")
                }
            case "ticket_type":
                if additionalData.ticketType == nil {
                    throw QRGenerationError.missingRequiredField("ticketType")
                }
            case "account_number":
                if additionalData.accountNumber == nil {
                    throw QRGenerationError.missingRequiredField("accountNumber")
                }
            case "billing_period":
                if additionalData.billingPeriod == nil {
                    throw QRGenerationError.missingRequiredField("billingPeriod")
                }
            default:
                break
            }
        }
    }
    
    private func getCurrencyCode(for countryCode: String) -> String {
        switch countryCode {
        case "KE": return "404" // KES
        case "TZ": return "834" // TZS
        default: return "404"   // Default to KES
        }
    }
    
    // MARK: - QR Branding & Visual Customization (Phase 4)
    
    /// Generate branded QR code with custom styling
    public func generateBrandedQR(
        from request: QRCodeGenerationRequest,
        branding: QRBranding,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        // Generate base QR with appropriate error correction level
        let baseQR = try generateQRWithOptimalErrorCorrection(request, branding: branding)
        
        // Apply branding
        let brandingEngine = QRBrandingEngine.shared
        return try brandingEngine.applyBranding(to: baseQR, branding: branding, size: style.size)
    }
    
    /// Generate Equity Bank QR with red branding (based on provided example)
    public func generateEquityBankQR(
        from request: QRCodeGenerationRequest,
        includeLogo: Bool = false,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        let logo: QRLogo? = nil // Logo support can be added later
        
        let equityBranding = QRBranding(
            logo: logo,
            colorScheme: .equityBank,
            template: .banking(BankTemplate.equity),
            errorCorrectionLevel: .high,
            brandIdentifier: "EQ"
        )
        
        return try generateBrandedQR(from: request, branding: equityBranding, style: style)
    }
    
    /// Generate QR with bank-specific branding
    public func generateBankQR(
        from request: QRCodeGenerationRequest,
        bank: BankTemplate,
        includeLogo: Bool = false,
        logoImage: UIImage? = nil,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        let logo: QRLogo? = if includeLogo, let logoImage = logoImage {
            QRLogo(image: logoImage, position: .center, size: .medium, style: .circular)
        } else {
            nil
        }
        
        let bankBranding = QRBranding(
            logo: logo,
            colorScheme: bank.colorScheme,
            template: .banking(bank),
            errorCorrectionLevel: .high,
            brandIdentifier: bank.brandIdentifier
        )
        
        return try generateBrandedQR(from: request, branding: bankBranding, style: style)
    }
    
    /// Generate QR with custom color scheme
    public func generateColoredQR(
        from request: QRCodeGenerationRequest,
        colorScheme: QRColorScheme,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        let branding = QRBranding(
            colorScheme: colorScheme,
            errorCorrectionLevel: .medium
        )
        
        return try generateBrandedQR(from: request, branding: branding, style: style)
    }
    
    private func generateQRWithOptimalErrorCorrection(
        _ request: QRCodeGenerationRequest,
        branding: QRBranding
    ) throws -> CIImage {
        
        // Use high error correction for logo placement, medium for color-only
        let requiredLevel = branding.logo != nil ? "H" : "M"
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        let qrString = try buildEMVCoCompliantTLV(from: request)
        let data = qrString.data(using: .utf8)!
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(requiredLevel, forKey: "inputCorrectionLevel")
        
        guard let outputImage = filter.outputImage else {
            throw QRGenerationError.qrGenerationFailed
        }
        
        return outputImage
    }
} 
