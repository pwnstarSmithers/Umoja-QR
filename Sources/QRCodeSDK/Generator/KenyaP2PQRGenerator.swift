import Foundation
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

public class KenyaP2PQRGenerator {
    
    private let parser = KenyaP2PQRParser()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - QR Generation
    
    /// Generate a Kenya P2P QR code
    /// - Parameters:
    ///   - request: QR code generation request with all necessary data
    ///   - style: Visual styling options for the QR code
    /// - Returns: Generated UIImage of the QR code
    /// - Throws: QRGenerationError for various generation failures
    public func generateQR(from request: QRCodeGenerationRequest, 
                          style: QRCodeStyle = QRCodeStyle()) throws -> UIImage {
        
        // Determine QR type based on request
        let qrType = determineQRType(from: request)
        
        // Build TLV string according to detected type
        let tlvString = try buildTLVString(from: request, qrType: qrType)
        
        // Generate and append CRC16 checksum
        let dataForCRC = tlvString + "6304"
        let crc16 = calculateCRC16(dataForCRC)
        let finalTLVString = tlvString + "6304" + crc16
        
        // Generate QR code image
        let qrImage = try generateQRImage(from: finalTLVString, style: style)
        
        return qrImage
    }
    
    /// Determine QR type based on request characteristics
    private func determineQRType(from request: QRCodeGenerationRequest) -> QRType {
        // Check for merchant category code to distinguish P2M from P2P
        if request.merchantCategoryCode != "6011" {
            return .p2m  // Has specific MCC, it's merchant payment
        }
        
        // Check for merchant-specific fields
        if request.recipientCity != nil {
            return .p2m  // Has merchant info, it's P2M
        }
        
        // Default to P2P for person-to-person transfers
        return .p2p
    }
    
    /// Generate QR code and return as data string (for validation/testing)
    /// - Parameter request: QR code generation request
    /// - Returns: Complete TLV string with CRC16
    /// - Throws: QRGenerationError for various generation failures
    public func generateQRString(from request: QRCodeGenerationRequest) throws -> String {
        let qrType = determineQRType(from: request)
        let tlvString = try buildTLVString(from: request, qrType: qrType)
        
        // Calculate CRC for data + CRC tag ID and length
        let dataForCRC = tlvString + "6304"
        let crc16 = calculateCRC16(dataForCRC)
        
        // Return complete QR string
        return tlvString + "6304" + crc16
    }
    
    // MARK: - TLV Building
    
    private func buildTLVString(from request: QRCodeGenerationRequest, qrType: QRType) throws -> String {
        var tlvComponents: [String] = []
        
        // Tag 00: Payload Format Indicator (always "01")
        tlvComponents.append(formatTLV(tag: "00", value: "01"))
        
        // Tag 01: Point of Initiation Method
        let initiationValue = request.initiationMethod.rawValue
        tlvComponents.append(formatTLV(tag: "01", value: initiationValue))
        
        // Build based on QR type
        switch qrType {
        case .p2p:
            try buildP2PTLV(from: request, into: &tlvComponents)
        case .p2m:
            try buildP2MTLV(from: request, into: &tlvComponents)
        }
        
        return tlvComponents.joined()
    }
    
    /// Build P2P (Person-to-Person) TLV structure
    private func buildP2PTLV(from request: QRCodeGenerationRequest, into components: inout [String]) throws {
        // Tag 28/29: PSP Information (proprietary format)
        guard let firstTemplate = request.accountTemplates.first else {
            throw QRGenerationError.invalidInputData
        }
        let pspTLV = try buildPSPTLV(from: firstTemplate.pspInfo, accountNumber: request.recipientIdentifier ?? "")
        components.append(pspTLV)
        
        // Tag 52: Merchant Category Code (6011 for financial institutions)
        components.append(formatTLV(tag: "52", value: "6011"))
        
        // Tag 53: Transaction Currency (KES = "404")
        let currencyCode = getCurrencyCode(for: request.currency)
        components.append(formatTLV(tag: "53", value: currencyCode))
        
        // Tag 54: Transaction Amount (only for dynamic QR)
        if request.initiationMethod == .dynamic, let amount = request.amount {
            let amountString = formatAmount(amount)
            components.append(formatTLV(tag: "54", value: amountString))
        }
        
        // Tag 58: Country Code
        components.append(formatTLV(tag: "58", value: request.countryCode))
        
        // Tag 59: Recipient Name (for P2P)
        if let recipientName = request.recipientName {
            components.append(formatTLV(tag: "59", value: recipientName))
        }
        
        // Tag 60: Recipient Account/Phone (for P2P)
        components.append(formatTLV(tag: "60", value: request.recipientIdentifier ?? ""))
        
        // Tag 62: Additional Data (purpose)
        if let additionalData = request.additionalData,
           let purpose = additionalData.purposeOfTransaction {
            let purposeTLV = buildPurposeTLV(purpose: purpose)
            components.append(formatTLV(tag: "62", value: purposeTLV))
        }
        
        // Tag 64: Format Version
        components.append(formatTLV(tag: "64", value: "P2P-KE-01"))
    }
    
    /// Build P2M (Person-to-Merchant) TLV structure using CBK standard
    private func buildP2MTLV(from request: QRCodeGenerationRequest, into components: inout [String]) throws {
        // Tag 29: CBK domestic format with ke.go.qr
        let cbkTemplate = try buildCBKTemplate(from: request)
        components.append(formatTLV(tag: "29", value: cbkTemplate))
        
        // Tag 52: Merchant Category Code (from request or default)
        let mcc = request.merchantCategoryCode == "6011" ? "5411" : request.merchantCategoryCode // Default to grocery stores if financial
        components.append(formatTLV(tag: "52", value: mcc))
        
        // Tag 53: Transaction Currency (KES = "404")
        let currencyCode = getCurrencyCode(for: request.currency)
        components.append(formatTLV(tag: "53", value: currencyCode))
        
        // Tag 54: Transaction Amount (only for dynamic QR)
        if request.initiationMethod == .dynamic, let amount = request.amount {
            let amountString = formatAmount(amount)
            components.append(formatTLV(tag: "54", value: amountString))
        }
        
        // Tag 58: Country Code
        components.append(formatTLV(tag: "58", value: request.countryCode))
        
        // Tag 59: Merchant Name
        let merchantName = request.recipientName ?? "Unknown Merchant"
        components.append(formatTLV(tag: "59", value: merchantName))
        
        // Tag 60: Merchant City
        let merchantCity = request.recipientCity ?? "KE" // Default to country code
        components.append(formatTLV(tag: "60", value: merchantCity))
        
        // Tag 62: Additional Data (if any)
        if let additionalData = request.additionalData {
            let additionalTLV = try buildAdditionalDataTLV(from: additionalData)
            components.append(formatTLV(tag: "62", value: additionalTLV))
        }
        
        // Tag 64: Format Version
        components.append(formatTLV(tag: "64", value: "P2M-KE-01"))
    }
    
    /// Build CBK domestic template (ke.go.qr format)
    private func buildCBKTemplate(from request: QRCodeGenerationRequest) throws -> String {
        guard let firstTemplate = request.accountTemplates.first else {
            throw QRGenerationError.invalidInputData
        }
        
        // Tag 00: CBK domestic identifier
        let guidTLV = formatTLV(tag: "00", value: "ke.go.qr")
        
        // Tag 68: PSP identifier (numeric)
        let pspId = firstTemplate.pspInfo.identifier
        let pspTLV = formatTLV(tag: "68", value: pspId)
        
        return guidTLV + pspTLV
    }
    
    /// Build additional data TLV structure
    private func buildAdditionalDataTLV(from additionalData: AdditionalData) throws -> String {
        var additionalComponents: [String] = []
        
        // Tag 01: Bill Number
        if let billNumber = additionalData.billNumber {
            additionalComponents.append(formatTLV(tag: "01", value: billNumber))
        }
        
        // Tag 02: Mobile Number
        if let mobileNumber = additionalData.mobileNumber {
            additionalComponents.append(formatTLV(tag: "02", value: mobileNumber))
        }
        
        // Tag 03: Store Label
        if let storeLabel = additionalData.storeLabel {
            additionalComponents.append(formatTLV(tag: "03", value: storeLabel))
        }
        
        // Tag 05: Reference Label
        if let referenceLabel = additionalData.referenceLabel {
            additionalComponents.append(formatTLV(tag: "05", value: referenceLabel))
        }
        
        // Tag 07: Terminal Label
        if let terminalLabel = additionalData.terminalLabel {
            additionalComponents.append(formatTLV(tag: "07", value: terminalLabel))
        }
        
        // Tag 08: Purpose of Transaction
        if let purpose = additionalData.purposeOfTransaction {
            additionalComponents.append(formatTLV(tag: "08", value: purpose))
        }
        
        return additionalComponents.joined()
    }
    
    private func buildPSPTLV(from pspInfo: PSPInfo, accountNumber: String) throws -> String {
        switch pspInfo.type {
        case .bank:
            return try buildBankPSPTLV(pspInfo: pspInfo, accountNumber: accountNumber)
        case .telecom:
            return try buildTelecomPSPTLV(pspInfo: pspInfo, accountNumber: accountNumber)
        case .paymentGateway:
            return try buildPaymentGatewayPSPTLV(pspInfo: pspInfo, accountNumber: accountNumber)
        case .unified:
            // For Tanzania TIPS - use telecom structure
            return try buildTelecomPSPTLV(pspInfo: pspInfo, accountNumber: accountNumber)
        }
    }
    
    private func buildBankPSPTLV(pspInfo: PSPInfo, accountNumber: String) throws -> String {
        // Format: Tag 29 with proprietary P2P structure
        // Example: 0002EQLT010D2040881022296
        
        let subtag = "0002"  // Standard subtag for banks
        
        // Map bank identifier to 4-character bank code
        let bankCode = mapBankIdentifierToCode(pspInfo.identifier)
        
        // Build nested TLV for account number
        let accountHexLength = String(format: "%02X", accountNumber.count)
        let nestedTLV = "01" + accountHexLength + accountNumber
        
        let pspValue = subtag + bankCode + nestedTLV
        return formatTLV(tag: "29", value: pspValue)
    }
    
    /// Map bank identifier to 4-character proprietary bank code for P2P
    private func mapBankIdentifierToCode(_ identifier: String) -> String {
        // Map from our PSP directory identifiers to proprietary P2P codes
        let bankCodeMap: [String: String] = [
            "01": "KCBL",    // KCB Bank
            "02": "SCBK",    // Standard Chartered
            "03": "ABSA",    // ABSA Bank
            "68": "EQLT",    // Equity Bank
            "11": "COOP",    // Co-operative Bank
            "31": "STAN",    // Stanbic Bank
            "63": "DIAM",    // Diamond Trust Bank
            "57": "IMBA",    // I&M Bank
            "70": "FAMI",    // Family Bank
            "25": "CRED",    // Credit Bank
            // Add more mappings as needed
        ]
        
        return bankCodeMap[identifier] ?? "UNKN"
    }
    
    private func buildTelecomPSPTLV(pspInfo: PSPInfo, accountNumber: String) throws -> String {
        // Format: Tag 28 with telecom-specific structure
        let subtag = "0001"  // Standard subtag for telecoms
        let telecomId = String(format: "%02d", Int(pspInfo.identifier) ?? 0)
        
        // Build nested TLV for phone number/account
        let accountHexLength = String(format: "%02X", accountNumber.count)
        let nestedTLV = "01" + accountHexLength + accountNumber
        
        let pspValue = subtag + telecomId + nestedTLV
        return formatTLV(tag: "28", value: pspValue)
    }
    
    private func buildPaymentGatewayPSPTLV(pspInfo: PSPInfo, accountNumber: String) throws -> String {
        // Payment gateways typically use telecom tag structure
        return try buildTelecomPSPTLV(pspInfo: pspInfo, accountNumber: accountNumber)
    }
    
    private func buildPurposeTLV(purpose: String) -> String {
        // Nested TLV structure for purpose
        // Format: 01[length][purpose]
        let purposeHexLength = String(format: "%02X", purpose.count)
        return "01" + purposeHexLength + purpose
    }
    
    // MARK: - Helper Functions
    
    private func formatTLV(tag: String, value: String) -> String {
        let length = String(format: "%02d", value.count)
        return tag + length + value
    }
    
    private func getCurrencyCode(for currency: String) -> String {
        switch currency.uppercased() {
        case "KES", "KENYA SHILLING":
            return "404"
        default:
            return "404" // Default to KES
        }
    }
    
    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        
        return formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
    }
    
    /// Calculate CRC16 checksum according to CBK standard
    private func calculateCRC16(_ data: String) -> String {
        // CRC-CCITT (False) implementation as per specification
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
    
    private func scaleQRImage(_ ciImage: CIImage, to size: CGSize) -> CIImage {
        let extent = ciImage.extent
        let scaleX = size.width / extent.width
        let scaleY = size.height / extent.height
        let scale = min(scaleX, scaleY)
        
        return ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }
    
    private func applyStyle(to ciImage: CIImage, style: QRCodeStyle) throws -> UIImage {
        let context = CIContext()
        
        // Apply color filters
        var styledImage = ciImage
        
        // Set foreground and background colors
        if let colorFilter = CIFilter(name: "CIFalseColor") {
            colorFilter.setValue(styledImage, forKey: "inputImage")
            colorFilter.setValue(CIColor(color: style.backgroundColor), forKey: "inputColor0")
            colorFilter.setValue(CIColor(color: style.foregroundColor), forKey: "inputColor1")
            
            if let output = colorFilter.outputImage {
                styledImage = output
            }
        }
        
        // Generate final image
        guard let cgImage = context.createCGImage(styledImage, from: styledImage.extent) else {
            throw QRGenerationError.imageRenderingFailed
        }
        
        var finalImage = UIImage(cgImage: cgImage)
        
        // Add logo if specified
        if let logo = style.logo {
            finalImage = try addLogo(to: finalImage, logo: logo, logoSize: style.logoSize)
        }
        
        return finalImage
    }
    
    private func addLogo(to qrImage: UIImage, logo: UIImage, logoSize: CGSize?) throws -> UIImage {
        let qrSize = qrImage.size
        let defaultLogoSize = CGSize(
            width: qrSize.width * 0.2,
            height: qrSize.height * 0.2
        )
        let finalLogoSize = logoSize ?? defaultLogoSize
        
        UIGraphicsBeginImageContextWithOptions(qrSize, false, qrImage.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Draw QR code
        qrImage.draw(in: CGRect(origin: .zero, size: qrSize))
        
        // Draw logo in center
        let logoRect = CGRect(
            x: (qrSize.width - finalLogoSize.width) / 2,
            y: (qrSize.height - finalLogoSize.height) / 2,
            width: finalLogoSize.width,
            height: finalLogoSize.height
        )
        
        // Add white background for logo
        UIColor.white.setFill()
        let backgroundRect = logoRect.insetBy(dx: -5, dy: -5)
        UIBezierPath(roundedRect: backgroundRect, cornerRadius: 5).fill()
        
        logo.draw(in: logoRect)
        
        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else {
            throw QRGenerationError.imageRenderingFailed
        }
        
        return finalImage
    }
}

// Note: QRGenerationError is defined in EnhancedQRGenerator.swift

// MARK: - Convenience Extensions

extension KenyaP2PQRGenerator {
    
    /// Quick generate static QR for Equity Bank account
    public func generateEquityBankQR(
        recipientName: String,
        accountNumber: String,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        let pspInfo = PSPInfo(
            type: .bank,
            identifier: "68", // Equity Bank
            name: "Equity Bank Kenya Ltd"
        )
        
        let request = QRCodeGenerationRequest(
            recipientName: recipientName,
            recipientIdentifier: accountNumber,
            pspInfo: pspInfo,
            isStatic: true
        )
        
        return try generateQR(from: request, style: style)
    }
    
    /// Quick generate dynamic QR with amount
    public func generateDynamicQR(
        recipientName: String,
        accountNumber: String,
        pspInfo: PSPInfo,
        amount: Decimal,
        purpose: String? = nil,
        style: QRCodeStyle = QRCodeStyle()
    ) throws -> UIImage {
        
        let request = QRCodeGenerationRequest(
            recipientName: recipientName,
            recipientIdentifier: accountNumber,
            pspInfo: pspInfo,
            amount: amount,
            purpose: purpose,
            isStatic: false
        )
        
        return try generateQR(from: request, style: style)
    }
}

#if canImport(UIKit)
extension CIColor {
    convenience init(color: UIColor) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif 