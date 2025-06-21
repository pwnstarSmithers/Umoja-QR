import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif

// MARK: - Core Data Structures

public struct TLVField: Sendable {
    public let tag: String
    public let length: Int
    public let value: String
    public let nestedFields: [TLVField]?
    
    public init(tag: String, length: Int, value: String, nestedFields: [TLVField]? = nil) {
        self.tag = tag
        self.length = length
        self.value = value
        self.nestedFields = nestedFields
    }
    
    /// Returns true if this is a template field containing nested TLV data
    public var isTemplate: Bool {
        return nestedFields != nil
    }
}

// MARK: - Enhanced QR Code Models

public struct ParsedQRCode: Sendable {
    public let fields: [TLVField]
    public let payloadFormat: String
    public let initiationMethod: QRInitiationMethod
    public let accountTemplates: [AccountTemplate]
    public let merchantCategoryCode: String
    public let amount: Decimal?
    public let recipientName: String?
    public let recipientIdentifier: String?
    public let purpose: String?
    public let currency: String
    public let countryCode: String
    public let additionalData: AdditionalData?
    public let formatVersion: String?
    public let qrType: QRType
    
    public init(fields: [TLVField], payloadFormat: String, initiationMethod: QRInitiationMethod,
                accountTemplates: [AccountTemplate], merchantCategoryCode: String, amount: Decimal?,
                recipientName: String?, recipientIdentifier: String?, purpose: String?,
                currency: String, countryCode: String, additionalData: AdditionalData? = nil,
                formatVersion: String? = nil) {
        self.fields = fields
        self.payloadFormat = payloadFormat
        self.initiationMethod = initiationMethod
        self.accountTemplates = accountTemplates
        self.merchantCategoryCode = merchantCategoryCode
        self.amount = amount
        self.recipientName = recipientName
        self.recipientIdentifier = recipientIdentifier
        self.purpose = purpose
        self.currency = currency
        self.countryCode = countryCode
        self.additionalData = additionalData
        self.formatVersion = formatVersion
        self.qrType = QRType.fromMCC(merchantCategoryCode)
    }
    
    /// Legacy compatibility - maintains backward compatibility
    public var isStatic: Bool {
        return initiationMethod == .static
    }
    
    /// Legacy compatibility - returns first PSP info
    public var pspInfo: PSPInfo? {
        return accountTemplates.first?.pspInfo
    }
}

// MARK: - QR Type Classification

public enum QRType: Sendable {
    case p2p    // Person-to-Person
    case p2m    // Person-to-Merchant
    
    static func fromMCC(_ mcc: String) -> QRType {
        // P2P MCCs (Financial institutions, funds transfer)
        if ["6011", "6012"].contains(mcc) {
            return .p2p
        }
        // All other MCCs are considered P2M
        return .p2m
    }
    
    public var displayName: String {
        switch self {
        case .p2p: return "Person-to-Person"
        case .p2m: return "Merchant Payment"
        }
    }
}

// MARK: - Initiation Method

public enum QRInitiationMethod: String, CaseIterable, Sendable {
    case `static` = "11"
    case dynamic = "12"
    
    public var isStatic: Bool {
        return self == .`static`
    }
    
    public var isDynamic: Bool {
        return self == .dynamic
    }
}

// MARK: - Account Templates (Tags 26-51)

public struct AccountTemplate: Sendable {
    public let tag: String
    public let guid: String
    public let participantId: String?
    public let accountId: String?
    public let pspInfo: PSPInfo
    
    public init(tag: String, guid: String, participantId: String? = nil, 
                accountId: String? = nil, pspInfo: PSPInfo) {
        self.tag = tag
        self.guid = guid
        self.participantId = participantId
        self.accountId = accountId
        self.pspInfo = pspInfo
    }
    
    /// Template type based on tag
    public var templateType: TemplateType {
        switch tag {
        case "26": return .unified         // Tanzania TIPS
        case "28": return .telecom         // Kenya Mobile Money
        case "29": return .bank           // Kenya Banks
        default: return .other
        }
    }
    
    public enum TemplateType: Sendable {
        case unified    // Single unified template (Tanzania)
        case telecom    // Telecom/Mobile money
        case bank       // Bank accounts
        case other      // Other payment schemes
    }
}

// MARK: - Enhanced PSP Information

public struct PSPInfo: Sendable {
    public let type: PSPType
    public let identifier: String
    public let name: String
    public let accountNumber: String?
    public let country: Country
    
    public init(type: PSPType, identifier: String, name: String, 
                accountNumber: String? = nil, country: Country = .kenya) {
        self.type = type
        self.identifier = identifier
        self.name = name
        self.accountNumber = accountNumber
        self.country = country
    }
    
    public enum PSPType: Sendable {
        case bank
        case telecom
        case paymentGateway
        case unified        // For Tanzania TIPS
        
        public var displayName: String {
            switch self {
            case .bank: return "Bank"
            case .telecom: return "Mobile Money"
            case .paymentGateway: return "Payment Gateway"
            case .unified: return "TIPS"
            }
        }
    }
}

// MARK: - Country Support

public enum Country: String, CaseIterable, Sendable {
    case kenya = "KE"
    case tanzania = "TZ"
    
    public var currencyCode: String {
        switch self {
        case .kenya: return "404"      // KES
        case .tanzania: return "834"   // TZS
        }
    }
    
    public var currencyName: String {
        switch self {
        case .kenya: return "KES"
        case .tanzania: return "TZS"
        }
    }
    
    public var displayName: String {
        switch self {
        case .kenya: return "Kenya"
        case .tanzania: return "Tanzania"
        }
    }
}

// MARK: - Additional Data (Tag 62)

public struct AdditionalData: Sendable {
    // Standard EMVCo fields (01-09)
    public var billNumber: String?
    public var mobileNumber: String?
    public var storeLabel: String?
    public var loyaltyNumber: String?
    public var referenceLabel: String?
    public var customerLabel: String?
    public var terminalLabel: String?
    public var purposeOfTransaction: String?
    public var additionalConsumerDataRequest: String?
    
    // Phase 2: Merchant-specific fields
    public var merchantCategory: String?        // Merchant category type
    public var merchantSubCategory: String?     // Detailed merchant description
    public var tipIndicator: String?            // Tip handling indicator
    public var tipAmount: String?               // Fixed tip amount
    public var convenienceFeeIndicator: String? // Convenience fee indicator
    public var convenienceFee: String?          // Fixed convenience fee
    public var multiScheme: String?             // Multi-scheme support indicator
    public var supportedCountries: String?      // Comma-separated country codes
    
    // Healthcare-specific fields
    public var patientId: String?
    public var appointmentReference: String?
    public var medicalRecordNumber: String?
    public var doctorId: String?
    public var treatmentCode: String?
    
    // Transportation fields
    public var route: String?
    public var ticketType: String?
    public var departureTime: String?
    public var vehicleId: String?
    public var arrivalTime: String?
    public var seatNumber: String?
    
    // Government/Utility fields
    public var referenceNumber: String?
    public var serviceType: String?
    public var accountNumber: String?
    public var billingPeriod: String?
    public var meterNumber: String?
    public var taxYear: String?
    public var licenseNumber: String?
    
    // Phase 3: Tanzania TANQR fields
    public var tipsAcquirerId: String?
    public var tipsVersion: String?
    public var tipsTransactionId: String?
    public var tipsTerminalId: String?
    public var countrySpecific: String?
    
    // Cross-border and multi-currency
    public var exchangeRate: String?
    public var originalCurrency: String?
    public var originalAmount: String?
    public var fxProvider: String?
    
    // Digital receipt and analytics
    public var receiptUrl: String?
    public var receiptFormat: String?
    public var analyticsId: String?
    public var sessionId: String?
    
    // Legacy custom fields support
    public let customFields: [String: String]
    
    public init(billNumber: String? = nil, mobileNumber: String? = nil, storeLabel: String? = nil,
                loyaltyNumber: String? = nil, referenceLabel: String? = nil, customerLabel: String? = nil,
                terminalLabel: String? = nil, purposeOfTransaction: String? = nil,
                additionalConsumerDataRequest: String? = nil, customFields: [String: String] = [:],
                merchantCategory: String? = nil, merchantSubCategory: String? = nil,
                tipIndicator: String? = nil, tipAmount: String? = nil,
                convenienceFeeIndicator: String? = nil, convenienceFee: String? = nil,
                multiScheme: String? = nil, supportedCountries: String? = nil,
                patientId: String? = nil, appointmentReference: String? = nil,
                medicalRecordNumber: String? = nil, doctorId: String? = nil,
                treatmentCode: String? = nil, route: String? = nil,
                ticketType: String? = nil, vehicleId: String? = nil,
                arrivalTime: String? = nil, seatNumber: String? = nil,
                referenceNumber: String? = nil, serviceType: String? = nil,
                accountNumber: String? = nil, billingPeriod: String? = nil,
                meterNumber: String? = nil, taxYear: String? = nil,
                licenseNumber: String? = nil, tipsAcquirerId: String? = nil,
                tipsVersion: String? = nil, countrySpecific: String? = nil) {
        self.billNumber = billNumber
        self.mobileNumber = mobileNumber
        self.storeLabel = storeLabel
        self.loyaltyNumber = loyaltyNumber
        self.referenceLabel = referenceLabel
        self.customerLabel = customerLabel
        self.terminalLabel = terminalLabel
        self.purposeOfTransaction = purposeOfTransaction
        self.additionalConsumerDataRequest = additionalConsumerDataRequest
        self.customFields = customFields
        self.merchantCategory = merchantCategory
        self.merchantSubCategory = merchantSubCategory
        self.tipIndicator = tipIndicator
        self.tipAmount = tipAmount
        self.convenienceFeeIndicator = convenienceFeeIndicator
        self.convenienceFee = convenienceFee
        self.multiScheme = multiScheme
        self.supportedCountries = supportedCountries
        self.patientId = patientId
        self.appointmentReference = appointmentReference
        self.medicalRecordNumber = medicalRecordNumber
        self.doctorId = doctorId
        self.treatmentCode = treatmentCode
        self.route = route
        self.ticketType = ticketType
        self.vehicleId = vehicleId
        self.arrivalTime = arrivalTime
        self.seatNumber = seatNumber
        self.referenceNumber = referenceNumber
        self.serviceType = serviceType
        self.accountNumber = accountNumber
        self.billingPeriod = billingPeriod
        self.meterNumber = meterNumber
        self.taxYear = taxYear
        self.licenseNumber = licenseNumber
        self.tipsAcquirerId = tipsAcquirerId
        self.tipsVersion = tipsVersion
        self.countrySpecific = countrySpecific
    }
}

// MARK: - Enhanced QR Generation Models

public struct QRCodeGenerationRequest: Sendable {
    public let qrType: QRType
    public let initiationMethod: QRInitiationMethod
    public let accountTemplates: [AccountTemplate]
    public let merchantCategoryCode: String
    public let amount: Decimal?
    public let recipientName: String?
    public let recipientIdentifier: String?
    public let recipientCity: String?
    public let postalCode: String?
    public let currency: String
    public let countryCode: String
    public let additionalData: AdditionalData?
    public let formatVersion: String?
    
    public init(qrType: QRType, initiationMethod: QRInitiationMethod, 
                accountTemplates: [AccountTemplate], merchantCategoryCode: String,
                amount: Decimal? = nil, recipientName: String? = nil, 
                recipientIdentifier: String? = nil, recipientCity: String? = nil,
                postalCode: String? = nil, currency: String = "404", 
                countryCode: String = "KE", additionalData: AdditionalData? = nil,
                formatVersion: String? = nil) {
        self.qrType = qrType
        self.initiationMethod = initiationMethod
        self.accountTemplates = accountTemplates
        self.merchantCategoryCode = merchantCategoryCode
        self.amount = amount
        self.recipientName = recipientName
        self.recipientIdentifier = recipientIdentifier
        self.recipientCity = recipientCity
        self.postalCode = postalCode
        self.currency = currency
        self.countryCode = countryCode
        self.additionalData = additionalData
        self.formatVersion = formatVersion
    }
    
    // Legacy compatibility constructors
    public init(recipientName: String? = nil, recipientIdentifier: String, pspInfo: PSPInfo,
                amount: Decimal? = nil, purpose: String? = nil, currency: String = "KES",
                countryCode: String = "KE", isStatic: Bool = true) {
        let country = Country(rawValue: countryCode) ?? .kenya
        let accountTemplate = AccountTemplate(
            tag: pspInfo.type == .bank ? "29" : "28",
            guid: pspInfo.identifier,
            accountId: recipientIdentifier,
            pspInfo: pspInfo
        )
        
        self.init(
            qrType: .p2p,
            initiationMethod: isStatic ? .static : .dynamic,
            accountTemplates: [accountTemplate],
            merchantCategoryCode: "6011",
            amount: amount,
            recipientName: recipientName,
            recipientIdentifier: recipientIdentifier,
            currency: country.currencyCode,
            countryCode: countryCode,
            additionalData: purpose != nil ? AdditionalData(purposeOfTransaction: purpose) : nil,
            formatVersion: "P2P-\(countryCode)-01"
        )
    }
}

// MARK: - Enhanced Validation

public struct QRValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [ValidationWarning]
    public let country: Country?
    public let qrType: QRType?
    
    public init(isValid: Bool, errors: [ValidationError] = [], warnings: [ValidationWarning] = [],
                country: Country? = nil, qrType: QRType? = nil) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.country = country
        self.qrType = qrType
    }
}

public enum ValidationError: Error, Sendable {
    case missingRequiredField(String)
    case invalidFieldValue(String, String)
    case invalidFieldLength(String, Int, expected: Int?)
    case invalidChecksum
    case unknownPSP(String)
    case malformedData
    case unsupportedVersion
    case invalidCountry(String)
    case currencyMismatch(String, String)
    case unsupportedQRType
    case invalidTemplateStructure(String)
    case emvCoComplianceError(String)
    
    public var localizedDescription: String {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidFieldValue(let field, let value):
            return "Invalid value '\(value)' for field \(field)"
        case .invalidFieldLength(let field, let actual, let expected):
            if let expected = expected {
                return "Invalid length for field \(field): got \(actual), expected \(expected)"
            } else {
                return "Invalid length for field \(field): \(actual)"
            }
        case .invalidChecksum:
            return "Invalid checksum - data may be corrupted"
        case .unknownPSP(let psp):
            return "Unknown or unsupported PSP: \(psp)"
        case .malformedData:
            return "Malformed QR code data"
        case .unsupportedVersion:
            return "Unsupported QR code version"
        case .invalidCountry(let country):
            return "Invalid or unsupported country: \(country)"
        case .currencyMismatch(let expected, let actual):
            return "Currency mismatch: expected \(expected), got \(actual)"
        case .unsupportedQRType:
            return "Unsupported QR code type"
        case .invalidTemplateStructure(let template):
            return "Invalid template structure: \(template)"
        case .emvCoComplianceError(let error):
            return "EMVCo compliance error: \(error)"
        }
    }
    
    /// Recovery suggestion for the user
    public var recoverySuggestion: String {
        switch self {
        case .invalidChecksum, .malformedData:
            return "Ask the sender to generate a new QR code"
        case .unknownPSP:
            return "This payment provider is not supported. Check with your service provider"
        case .invalidCountry, .currencyMismatch:
            return "This QR code is for a different country or currency"
        case .unsupportedVersion, .unsupportedQRType:
            return "Update your app to support this QR code type"
        case .invalidTemplateStructure, .emvCoComplianceError:
            return "The QR code format is invalid. Contact the issuer"
        case .invalidFieldLength:
            return "The QR code format is invalid. Ask for a new QR code"
        default:
            return "Please try again or contact support"
        }
    }
}

public enum ValidationWarning: Sendable {
    case missingOptionalField(String)
    case suboptimalConfiguration(String)
    case legacyFormat
    case multipleAccountTemplates
    
    public var localizedDescription: String {
        switch self {
        case .missingOptionalField(let field):
            return "Missing optional field: \(field)"
        case .suboptimalConfiguration(let message):
            return "Configuration warning: \(message)"
        case .legacyFormat:
            return "Using legacy QR format - consider upgrading"
        case .multipleAccountTemplates:
            return "Multiple payment options available"
        }
    }
}

// MARK: - Phase 2 & 3: Enhanced Enums and Types

/// Tip handling indicators for merchant QRs
public enum TipIndicator: String, CaseIterable, Sendable {
    case notPrompted = "01"    // Consumer not prompted to enter tip
    case prompted = "02"       // Consumer prompted to enter tip
    case fixedAmount = "03"    // Fixed tip amount included
    
    public var description: String {
        switch self {
        case .notPrompted: return "No tip prompt"
        case .prompted: return "Prompt for tip"
        case .fixedAmount: return "Fixed tip included"
        }
    }
}

/// Convenience fee indicators for merchant QRs
public enum ConvenienceFeeIndicator: String, CaseIterable, Sendable {
    case notCharged = "01"     // No convenience fee
    case fixedAmount = "02"    // Fixed convenience fee
    case percentage = "03"     // Percentage-based fee
    
    public var description: String {
        switch self {
        case .notCharged: return "No convenience fee"
        case .fixedAmount: return "Fixed convenience fee"
        case .percentage: return "Percentage-based fee"
        }
    }
}

/// Enhanced PSP types including Tanzania-specific ones
extension PSPInfo.PSPType {
    public static let paymentSystem: PSPInfo.PSPType = .paymentGateway
    public static let centralBank: PSPInfo.PSPType = .bank
    public static let development: PSPInfo.PSPType = .bank
    public static let financial: PSPInfo.PSPType = .bank
}

/// Enhanced Country support with currency information
extension Country {
    /// Get currency symbol for display
    public var currencySymbol: String {
        switch self {
        case .kenya: return "KSh"
        case .tanzania: return "TSh"
        }
    }
    
    /// Check if country supports multi-currency transactions
    public var supportsMultiCurrency: Bool {
        switch self {
        case .kenya: return true  // Kenya supports USD, EUR, etc.
        case .tanzania: return true // Tanzania supports USD, etc.
        }
    }
    
    /// Get major trading currencies for the country
    public var majorTradingCurrencies: [String] {
        switch self {
        case .kenya: return ["404", "840", "978"] // KES, USD, EUR
        case .tanzania: return ["834", "840"] // TZS, USD
        }
    }
}

/// QR Type enhancement for merchant support
extension QRType {
    /// Get typical use cases for QR type
    public var useCases: [String] {
        switch self {
        case .p2p: return ["Send money to friends", "Split bills", "Personal transfers"]
        case .p2m: return ["Pay at stores", "Online shopping", "Bill payments", "Service payments"]
        }
    }
    
    /// Check if type requires merchant information
    public var requiresMerchantInfo: Bool {
        return self == .p2m
    }
}

/// Enhanced validation for merchant QR codes
public struct MerchantQRValidation: Sendable {
    public let merchantName: String
    public let merchantCity: String
    public let merchantId: String
    public let mcc: String
    public let requiresAmount: Bool
    public let maxAmount: Decimal?
    public let allowsStaticQR: Bool
    public let requiredFields: [String]
    
    public init(merchantName: String, merchantCity: String, merchantId: String, mcc: String,
                requiresAmount: Bool = false, maxAmount: Decimal? = nil, allowsStaticQR: Bool = true,
                requiredFields: [String] = []) {
        self.merchantName = merchantName
        self.merchantCity = merchantCity
        self.merchantId = merchantId
        self.mcc = mcc
        self.requiresAmount = requiresAmount
        self.maxAmount = maxAmount
        self.allowsStaticQR = allowsStaticQR
        self.requiredFields = requiredFields
    }
    
    /// Validate merchant data according to MCC rules
    public func validate() -> QRValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationWarning] = []
        
        // Validate MCC
        if !MerchantCategories.shared.isValidMCC(mcc) {
            errors.append(.invalidFieldValue("mcc", mcc))
        }
        
        // Get validation rules for MCC
        let rules = MerchantCategories.shared.getValidationRules(for: mcc)
        
        // Check required fields
        if rules.requiresMerchantName && merchantName.isEmpty {
            errors.append(.missingRequiredField("merchantName"))
        }
        
        if rules.requiresCity && merchantCity.isEmpty {
            errors.append(.missingRequiredField("merchantCity"))
        }
        
        // Check amount constraints
        if let maxLimit = rules.maxAmountLimit, let max = maxAmount, max > maxLimit {
            errors.append(.invalidFieldValue("amount", "exceeds \(maxLimit)"))
        }
        
        // Check static QR allowance
        if !rules.allowsStaticQR && !requiresAmount {
            warnings.append(.suboptimalConfiguration("Static QR not recommended for MCC \(mcc)"))
        }
        
        return QRValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
}

/// Enhanced TAN-QR (Tanzania) specific models
public struct TIPSTemplate {
    public let pspCode: String
    public let merchantId: String
    public let terminalId: String?
    public let version: String
    
    public init(pspCode: String, merchantId: String, terminalId: String? = nil, version: String = "1.0") {
        self.pspCode = pspCode
        self.merchantId = merchantId
        self.terminalId = terminalId
        self.version = version
    }
    
    /// Convert to AccountTemplate for QR generation
    public func toAccountTemplate() -> AccountTemplate? {
        guard let pspInfo = PSPDirectory.shared.getPSP(guid: pspCode, country: .tanzania) else {
            return nil
        }
        
        return AccountTemplate(
            tag: "26", // Tanzania unified template
            guid: "tz.go.bot.tips",
            participantId: pspCode,
            accountId: merchantId,
            pspInfo: pspInfo
        )
    }
}

// MARK: - Enhanced QR Code Style with Branding Support

public struct QRCodeStyle {
    public let size: CGSize
    public let foregroundColor: UIColor
    public let backgroundColor: UIColor
    public let logo: UIImage?
    public let logoSize: CGSize?
    public let errorCorrectionLevel: ErrorCorrectionLevel
    public let margin: CGFloat
    public let quietZone: CGFloat
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let borderColor: UIColor?
    
    public init(size: CGSize = CGSize(width: 512, height: 512),
                foregroundColor: UIColor = .black,
                backgroundColor: UIColor = .white,
                logo: UIImage? = nil,
                logoSize: CGSize? = nil,
                errorCorrectionLevel: ErrorCorrectionLevel = .medium,
                margin: CGFloat = 10,
                quietZone: CGFloat = 4,
                cornerRadius: CGFloat = 0,
                borderWidth: CGFloat = 0,
                borderColor: UIColor? = nil) {
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.logo = logo
        self.logoSize = logoSize
        self.errorCorrectionLevel = errorCorrectionLevel
        self.margin = margin
        self.quietZone = quietZone
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
    }
    
    public enum ErrorCorrectionLevel {
        case low      // ~7%
        case medium   // ~15%
        case quartile // ~25%
        case high     // ~30%
        
        internal var qrLevel: String {
            switch self {
            case .low: return "L"
            case .medium: return "M"
            case .quartile: return "Q"
            case .high: return "H"
            }
        }
    }
    
    // MARK: - Predefined Styles
    
    public static let small = QRCodeStyle(
        size: CGSize(width: 200, height: 200),
        margin: 8,
        quietZone: 3
    )
    
    public static let medium = QRCodeStyle(
        size: CGSize(width: 400, height: 400),
        margin: 15,
        quietZone: 6
    )
    
    public static let large = QRCodeStyle(
        size: CGSize(width: 600, height: 600),
        margin: 20,
        quietZone: 8
    )
    
    public static let print = QRCodeStyle(
        size: CGSize(width: 1200, height: 1200),
        errorCorrectionLevel: .high,
        margin: 40,
        quietZone: 16
    )
    
    /// Equity Bank branded style (matches provided example)
    public static let equityBrand = QRCodeStyle(
        size: CGSize(width: 350, height: 350),
        foregroundColor: .black,
        backgroundColor: .white,
        errorCorrectionLevel: .high,
        margin: 15,
        quietZone: 8,
        cornerRadius: 12,
        borderWidth: 2,
        borderColor: UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
    )
    
    /// Professional banking style
    public static let banking = QRCodeStyle(
        size: CGSize(width: 380, height: 380),
        foregroundColor: .black,
        backgroundColor: .white,
        errorCorrectionLevel: .high,
        margin: 20,
        quietZone: 10,
        cornerRadius: 8,
        borderWidth: 1,
        borderColor: UIColor.customBlue
    )
    
    /// Retail point-of-sale style
    public static let retail = QRCodeStyle(
        size: CGSize(width: 320, height: 320),
        foregroundColor: .black,
        backgroundColor: .white,
        errorCorrectionLevel: .medium,
        margin: 12,
        quietZone: 6,
        cornerRadius: 6,
        borderWidth: 2,
        borderColor: UIColor.customOrange
    )
}

 