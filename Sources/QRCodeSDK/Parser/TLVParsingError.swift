import Foundation

public enum TLVParsingError: Error {
    case invalidDataLength
    case invalidTag
    case invalidLength
    case invalidValue
    case corruptedData
    case missingRequiredField(String)
    case invalidChecksum
    case unknownPSP
    case expiredQR
    case invalidPSPFormat
    case invalidNestedTLV
    case unsupportedQRVersion
    
    public var userMessage: String {
        switch self {
        case .invalidChecksum:
            return "Invalid QR Code – corrupted or altered."
        case .unknownPSP:
            return "PSP not supported."
        case .expiredQR:
            return "QR expired. Please request a new one."
        case .missingRequiredField:
            return "Incomplete QR – check code and try again."
        case .invalidDataLength, .invalidTag, .invalidLength, .invalidValue, 
             .corruptedData, .invalidPSPFormat, .invalidNestedTLV:
            return "Malformed QR – invalid data structure."
        case .unsupportedQRVersion:
            return "QR version not supported."
        }
    }
    
    public var technicalDescription: String {
        switch self {
        case .invalidDataLength:
            return "QR data length is invalid or insufficient"
        case .invalidTag:
            return "Invalid TLV tag format"
        case .invalidLength:
            return "Invalid TLV length value"
        case .invalidValue:
            return "Invalid TLV value content"
        case .corruptedData:
            return "QR data appears to be corrupted"
        case .missingRequiredField(let field):
            return "Required field missing: \(field)"
        case .invalidChecksum:
            return "CRC16 checksum validation failed"
        case .unknownPSP:
            return "PSP identifier not found in directory"
        case .expiredQR:
            return "QR code has expired"
        case .invalidPSPFormat:
            return "PSP data format is invalid"
        case .invalidNestedTLV:
            return "Nested TLV structure is malformed"
        case .unsupportedQRVersion:
            return "QR code version is not supported"
        }
    }
}

// MARK: - Error Categories

extension TLVParsingError {
    public var category: ErrorCategory {
        switch self {
        case .invalidChecksum, .corruptedData:
            return .dataIntegrity
        case .unknownPSP:
            return .unsupportedProvider
        case .expiredQR:
            return .expired
        case .missingRequiredField, .invalidDataLength, .invalidTag, 
             .invalidLength, .invalidValue, .invalidPSPFormat, .invalidNestedTLV:
            return .malformedData
        case .unsupportedQRVersion:
            return .unsupportedVersion
        }
    }
    
    public enum ErrorCategory {
        case dataIntegrity
        case unsupportedProvider
        case expired
        case malformedData
        case unsupportedVersion
    }
}

// MARK: - Recovery Suggestions

extension TLVParsingError {
    public var recoverySuggestion: String {
        switch self {
        case .invalidChecksum, .corruptedData:
            return "Ask the sender to generate a new QR code"
        case .unknownPSP:
            return "This payment provider is not supported. Check with your service provider"
        case .expiredQR:
            return "Request a new QR code from the recipient"
        case .missingRequiredField, .invalidDataLength, .invalidTag, 
             .invalidLength, .invalidValue, .invalidPSPFormat, .invalidNestedTLV:
            return "The QR code format is invalid. Ask for a new QR code"
        case .unsupportedQRVersion:
            return "Update your app to support this QR code version"
        }
    }
} 