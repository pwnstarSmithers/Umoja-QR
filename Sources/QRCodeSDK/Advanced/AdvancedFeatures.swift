import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(CoreML)
import CoreML
#endif

/// Advanced features for QR code processing
public class AdvancedFeatures {
    
    // MARK: - QR Code Analytics
    
    /// Analyze QR code usage patterns and provide insights
    public static func analyzeQRCodeUsage(_ qrCodes: [ParsedQRCode]) -> QRAnalytics {
        var analytics = QRAnalytics()
        
        // Basic statistics
        analytics.totalQRCodes = qrCodes.count
        analytics.uniqueRecipients = Set(qrCodes.map { $0.recipientName }).count
        
        // Transaction analysis
        let amounts = qrCodes.compactMap { $0.amount }
        if !amounts.isEmpty {
            analytics.totalAmount = amounts.reduce(0, +)
            analytics.averageAmount = analytics.totalAmount / Decimal(amounts.count)
            analytics.largestTransaction = amounts.max() ?? 0
            analytics.smallestTransaction = amounts.min() ?? 0
        }
        
        // PSP analysis
        let pspCounts = Dictionary(grouping: qrCodes, by: { $0.pspInfo?.name ?? "Unknown" })
            .mapValues { $0.count }
        analytics.pspDistribution = pspCounts
        
        // Time-based analysis (metadata not available in current ParsedQRCode)
        analytics.last24HourCount = 0 // Placeholder - metadata not implemented
        
        // Error analysis (simplified without metadata)
        let errorTypes: [String] = [] // Placeholder - metadata not implemented
        analytics.commonErrors = Dictionary(grouping: errorTypes, by: { $0 })
            .mapValues { $0.count }
        
        return analytics
    }
    
    /// Generate fraud detection insights
    public static func detectFraudPatterns(_ qrCodes: [ParsedQRCode]) -> FraudAnalysis {
        var analysis = FraudAnalysis()
        
        // Duplicate QR code detection (rawData not available, using fields as identifier)
        let qrDataCounts = Dictionary(grouping: qrCodes, by: { $0.fields.description })
            .mapValues { $0.count }
        analysis.duplicateQRCodes = qrDataCounts.filter { $1 > 1 }
        
        // Unusual amount patterns
        let amounts = qrCodes.compactMap { $0.amount }
        if !amounts.isEmpty {
            let average = amounts.reduce(0, +) / Decimal(amounts.count)
            let threshold = average * 5 // 5x average is suspicious
            analysis.unusualAmounts = qrCodes.filter { 
                ($0.amount ?? 0) > threshold 
            }.map { $0.fields.description }
        }
        
        // Rapid generation patterns (metadata not available, skipping this analysis)
        analysis.rapidGenerationPatterns = [] // Placeholder - metadata not implemented
        
        // Calculate risk score
        var riskScore = 0.0
        riskScore += Double(analysis.duplicateQRCodes.count) * 0.3
        riskScore += Double(analysis.unusualAmounts.count) * 0.4
        riskScore += Double(analysis.rapidGenerationPatterns.count) * 0.3
        analysis.overallRiskScore = min(riskScore, 10.0) // Cap at 10
        
        return analysis
    }
    
    // MARK: - Smart Validation
    
    /// Perform intelligent validation with contextual suggestions
    public static func smartValidate(_ qrData: String, context: ValidationContext = ValidationContext()) -> SmartValidationResult {
        var result = SmartValidationResult()
        result.originalData = qrData
        
        // Basic validation
        do {
            let parser = KenyaP2PQRParser()
            let parsedQR = try parser.parseKenyaP2PQR(qrData)
            result.isValid = true
            result.parsedQRCode = parsedQR
        } catch {
            result.isValid = false
            result.errors.append(ValidationError.malformedData)
        }
        
        // Contextual validation
        if let parsedQR = result.parsedQRCode {
            validateInContext(parsedQR, context: context, result: &result)
        }
        
        // Generate improvement suggestions
        result.suggestions = generateImprovementSuggestions(for: qrData, context: context)
        
        return result
    }
    
    /// Validate QR code in specific context
    private static func validateInContext(_ qrCode: ParsedQRCode, context: ValidationContext, result: inout SmartValidationResult) {
        // Amount validation
        if let amount = qrCode.amount, let limits = context.amountLimits {
            if amount < limits.minimum {
                result.warnings.append(ValidationWarning.missingOptionalField("amount below minimum"))
            }
            
            if amount > limits.maximum {
                result.errors.append(ValidationError.invalidFieldValue("amount", "exceeds maximum"))
            }
        }
        
        // PSP validation
        if let psp = qrCode.pspInfo, let allowedPSPs = context.allowedPSPs {
            if !allowedPSPs.contains(psp.identifier) {
                result.warnings.append(ValidationWarning.suboptimalConfiguration("PSP not in allowed list"))
            }
        }
        
        // Time-based validation
        if let expiry = context.expiryTime {
            let now = Date()
            if now > expiry {
                result.errors.append(ValidationError.malformedData)
            }
        }
    }
    
    /// Generate smart suggestions based on error
    private static func generateSmartSuggestion(for error: Error, context: ValidationContext) -> String {
        if let tlvError = error as? TLVParsingError {
            switch tlvError {
            case .invalidDataLength:
                return "Check that the QR code follows the Kenya P2P standard format"
            case .invalidChecksum:
                return "Recalculate the CRC16 checksum - the current value appears incorrect"
            case .missingRequiredField:
                return "Ensure all mandatory fields (00, 01, 52, 53, 58, 63) are present"
            case .invalidLength:
                return "Verify that field lengths match the actual data length"
            default:
                return "Review the QR code structure against the Kenya P2P specification"
            }
        }
        
        return "Validate the QR code format and try again"
    }
    
    /// Generate improvement suggestions
    private static func generateImprovementSuggestions(for qrData: String, context: ValidationContext) -> [String] {
        var suggestions: [String] = []
        
        // Length optimization
        if qrData.count > 200 {
            suggestions.append("Consider shortening recipient name or additional data to reduce QR code complexity")
        }
        
        // Security suggestions
        if !qrData.contains("63") { // No CRC field
            suggestions.append("Always include CRC16 checksum for data integrity")
        }
        
        // Performance suggestions
        if qrData.contains(String(repeating: "0", count: 10)) {
            suggestions.append("Avoid excessive padding - it increases scanning time")
        }
        
        return suggestions
    }
    
    // MARK: - Enhanced Error Recovery
    
    /// Attempt to recover from QR code errors
    public static func recoverFromError(_ qrData: String, error: Error) -> ErrorRecoveryResult {
        var result = ErrorRecoveryResult()
        result.originalError = error
        result.originalData = qrData
        
        if let tlvError = error as? TLVParsingError {
            switch tlvError {
            case .invalidChecksum:
                result = attemptCRCRecovery(qrData)
            case .invalidLength:
                result = attemptLengthRecovery(qrData)
            case .missingRequiredField:
                result = attemptFieldRecovery(qrData)
            default:
                result.recoveryAttempted = false
                result.suggestions.append("Manual review required for this error type")
            }
        }
        
        return result
    }
    
    /// Attempt to recover from CRC errors
    private static func attemptCRCRecovery(_ qrData: String) -> ErrorRecoveryResult {
        var result = ErrorRecoveryResult()
        result.recoveryAttempted = true
        
        // Try to recalculate CRC
        if qrData.count >= 8 {
            let dataWithoutCRC = String(qrData.dropLast(8))
            let calculatedCRC = PerformanceOptimizer.calculateCRC16Optimized(dataWithoutCRC)
            let newCRC = String(format: "%04X", calculatedCRC)
            let recoveredData = dataWithoutCRC + "63" + String(format: "%02d", newCRC.count) + newCRC
            
            // Test if recovered data parses correctly
            do {
                let parser = KenyaP2PQRParser()
                let _ = try parser.parseKenyaP2PQR(recoveredData)
                result.wasSuccessful = true
                result.recoveredData = recoveredData
                result.suggestions.append("CRC was recalculated and corrected")
            } catch {
                result.wasSuccessful = false
                result.suggestions.append("CRC recalculation failed - data may be corrupted")
            }
        }
        
        return result
    }
    
    /// Attempt to recover from length errors
    private static func attemptLengthRecovery(_ qrData: String) -> ErrorRecoveryResult {
        var result = ErrorRecoveryResult()
        result.recoveryAttempted = true
        result.suggestions.append("Length recovery attempted")
        return result
    }
    
    /// Attempt to recover missing fields
    private static func attemptFieldRecovery(_ qrData: String) -> ErrorRecoveryResult {
        var result = ErrorRecoveryResult()
        result.recoveryAttempted = true
        result.suggestions.append("Field recovery attempted")
        return result
    }
    
    // MARK: - Machine Learning Integration
    
    /// Use ML to predict QR code quality and suggest improvements
    @available(iOS 13.0, *)
    public static func predictQRQuality(_ qrData: String) -> QRQualityPrediction {
        var prediction = QRQualityPrediction()
        prediction.inputData = qrData
        
        // Feature extraction
        let features = extractMLFeatures(from: qrData)
        prediction.features = features
        
        // Simple rule-based prediction (placeholder for actual ML model)
        var qualityScore = 100.0
        
        // Penalize for length
        if qrData.count > 300 {
            qualityScore -= Double(qrData.count - 300) * 0.1
        }
        
        // Penalize for missing fields
        let requiredFields = ["00", "01", "52", "53", "58", "63"]
        let missingFields = requiredFields.filter { !qrData.contains($0) }
        qualityScore -= Double(missingFields.count) * 15.0
        
        // Bonus for good structure
        if qrData.hasPrefix("0002") {
            qualityScore += 5.0
        }
        
        prediction.qualityScore = max(0, min(100, qualityScore))
        prediction.recommendations = generateQualityRecommendations(features: features, score: prediction.qualityScore)
        
        return prediction
    }
    
    /// Extract features for ML processing
    private static func extractMLFeatures(from qrData: String) -> [String: Double] {
        var features: [String: Double] = [:]
        
        features["length"] = Double(qrData.count)
        features["numeric_ratio"] = Double(qrData.filter { $0.isNumber }.count) / Double(qrData.count)
        features["field_count"] = Double(qrData.components(separatedBy: CharacterSet.decimalDigits.inverted).count)
        features["has_crc"] = qrData.contains("63") ? 1.0 : 0.0
        features["complexity"] = Double(Set(qrData).count) / Double(qrData.count)
        
        return features
    }
    
    /// Generate quality recommendations
    private static func generateQualityRecommendations(features: [String: Double], score: Double) -> [String] {
        var recommendations: [String] = []
        
        if score < 50 {
            recommendations.append("QR code quality is poor - consider regenerating")
        } else if score < 75 {
            recommendations.append("QR code quality is fair - some improvements possible")
        }
        
        if let length = features["length"], length > 250 {
            recommendations.append("Consider shortening the data to improve scanning speed")
        }
        
        if let hasCRC = features["has_crc"], hasCRC == 0 {
            recommendations.append("Add CRC checksum for data integrity")
        }
        
        if let complexity = features["complexity"], complexity < 0.3 {
            recommendations.append("Data appears repetitive - verify correctness")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct QRAnalytics {
    public var totalQRCodes: Int = 0
    public var uniqueRecipients: Int = 0
    public var totalAmount: Decimal = 0
    public var averageAmount: Decimal = 0
    public var largestTransaction: Decimal = 0
    public var smallestTransaction: Decimal = 0
    public var pspDistribution: [String: Int] = [:]
    public var last24HourCount: Int = 0
    public var commonErrors: [String: Int] = [:]
}

public struct FraudAnalysis {
    public var duplicateQRCodes: [String: Int] = [:]
    public var unusualAmounts: [String] = []
    public var rapidGenerationPatterns: [String] = []
    public var overallRiskScore: Double = 0.0
}

public struct ValidationContext {
    public var amountLimits: AmountLimits?
    public var allowedPSPs: [String]?
    public var expiryTime: Date?
    public var requiredFields: [String]?
    
    public init() {}
}

public struct AmountLimits {
    public let minimum: Decimal
    public let maximum: Decimal
    
    public init(minimum: Decimal, maximum: Decimal) {
        self.minimum = minimum
        self.maximum = maximum
    }
}

public struct SmartValidationResult {
    public var originalData: String = ""
    public var isValid: Bool = false
    public var parsedQRCode: ParsedQRCode?
    public var errors: [ValidationError] = []
    public var warnings: [ValidationWarning] = []
    public var suggestions: [String] = []
    
    public init() {}
}

// ValidationError and ValidationWarning are defined in QRCodeModels.swift

public struct ErrorRecoveryResult {
    public var originalError: Error?
    public var originalData: String = ""
    public var recoveryAttempted: Bool = false
    public var wasSuccessful: Bool = false
    public var recoveredData: String?
    public var suggestions: [String] = []
}

public struct QRQualityPrediction {
    public var inputData: String = ""
    public var qualityScore: Double = 0.0
    public var features: [String: Double] = [:]
    public var recommendations: [String] = []
} 