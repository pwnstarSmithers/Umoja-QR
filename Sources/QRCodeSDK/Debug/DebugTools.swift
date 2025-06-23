import Foundation
#if canImport(UIKit)
import UIKit
#endif
import os.log
#if canImport(os)
import os
#endif

/// Debug tools and utilities for QR code development
public class DebugTools {
    
    // MARK: - Logging
    
    @available(iOS 14.0, macOS 11.0, *)
    private static let logger = Logger(subsystem: "com.qrcodesdk", category: "DebugTools")
    
    public enum LogLevel: Int, CaseIterable {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
        
        var prefix: String {
            switch self {
            case .verbose: return "🔍 VERBOSE"
            case .debug: return "🐛 DEBUG"
            case .info: return "ℹ️ INFO"
            case .warning: return "⚠️ WARNING"
            case .error: return "❌ ERROR"
            }
        }
        
        var osLogType: OSLogType {
            switch self {
            case .verbose: return .debug
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }
    
    public static var logLevel: LogLevel = .info
    public static var enableConsoleLogging = true
    public static var enableFileLogging = false
    
    /// Log a message with specified level
    public static func log(_ message: String, level: LogLevel = .info, 
                          file: String = #file, function: String = #function, line: Int = #line) {
        guard level.rawValue >= logLevel.rawValue else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(level.prefix) [\(fileName):\(line)] \(function): \(message)"
        
        if enableConsoleLogging {
            print(logMessage)
        }
        
        if #available(iOS 14.0, macOS 11.0, *) {
            logger.log(level: level.osLogType, "\(logMessage)")
        }
        
        if enableFileLogging {
            writeToLogFile(logMessage)
        }
    }
    
    /// Write log message to file
    private static func writeToLogFile(_ message: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                           in: .userDomainMask).first else { return }
        
        let logFileURL = documentsPath.appendingPathComponent("qrcode_debug.log")
        let timestampedMessage = "\(Date().iso8601String): \(message)\n"
        
        if let data = timestampedMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL)
            }
        }
    }
    
    // MARK: - QR Code Analysis
    
    /// Analyze QR code structure and provide detailed breakdown
    public static func analyzeQRCode(_ qrData: String) -> QRAnalysisResult {
        log("Starting QR code analysis for data: \(qrData.prefix(50))...", level: .debug)
        
        var result = QRAnalysisResult()
        result.originalData = qrData
        result.dataLength = qrData.count
        
        // Basic validation
        if qrData.isEmpty {
            result.issues.append("QR code data is empty")
            return result
        }
        
        // Check for non-printable characters
        let nonPrintableCount = qrData.unicodeScalars.filter { !$0.isASCII || $0.value < 32 }.count
        if nonPrintableCount > 0 {
            result.issues.append("Contains \(nonPrintableCount) non-printable characters")
        }
        
        // Try to parse TLV structure
        do {
            let tlvFields = try parseTLVForDebug(qrData)
            result.tlvFields = tlvFields
            result.isValidTLV = true
            
            // Analyze each field
            for field in tlvFields {
                analyzeField(field, result: &result)
            }
            
        } catch {
            result.issues.append("TLV parsing failed: \(error.localizedDescription)")
            result.isValidTLV = false
        }
        
        // Try to parse as Kenya P2P QR
        do {
            let parser = KenyaP2PQRParser()
            let parsedQR = try parser.parseKenyaP2PQR(qrData)
            result.isValidKenyaP2P = true
            result.parsedQRCode = parsedQR
            log("Successfully parsed as Kenya P2P QR code", level: .debug)
        } catch {
            result.issues.append("Kenya P2P parsing failed: \(error.localizedDescription)")
            result.isValidKenyaP2P = false
        }
        
        // Performance analysis
        let (_, metrics) = PerformanceOptimizer.measurePerformance(operation: "QR_ANALYSIS") {
            return result
        }
        result.performanceMetrics = metrics
        
        log("QR code analysis completed with \(result.issues.count) issues", level: .debug)
        return result
    }
    
    /// Parse TLV for debugging purposes
    private static func parseTLVForDebug(_ data: String) throws -> [DebugTLVField] {
        var fields: [DebugTLVField] = []
        var index = data.startIndex
        
        while index < data.endIndex {
            guard index < data.index(data.endIndex, offsetBy: -3) else {
                throw DebugError.insufficientData
            }
            
            let tagEnd = data.index(index, offsetBy: 2)
            let tag = String(data[index..<tagEnd])
            
            let lengthEnd = data.index(tagEnd, offsetBy: 2)
            let lengthStr = String(data[tagEnd..<lengthEnd])
            
            guard let length = Int(lengthStr) else {
                throw DebugError.invalidLength(lengthStr)
            }
            
            guard data.distance(from: lengthEnd, to: data.endIndex) >= length else {
                throw DebugError.insufficientDataForField(tag, length)
            }
            
            let valueEnd = data.index(lengthEnd, offsetBy: length)
            let value = String(data[lengthEnd..<valueEnd])
            
            let debugField = DebugTLVField(
                tag: tag,
                length: length,
                value: value,
                rawData: String(data[index..<valueEnd]),
                position: data.distance(from: data.startIndex, to: index)
            )
            
            fields.append(debugField)
            index = valueEnd
        }
        
        return fields
    }
    
    /// Analyze individual TLV field
    private static func analyzeField(_ field: DebugTLVField, result: inout QRAnalysisResult) {
        // Check for known tags
        let knownTags = ["00", "01", "28", "29", "52", "53", "54", "58", "59", "60", "62", "63", "64"]
        if !knownTags.contains(field.tag) {
            result.issues.append("Unknown tag: \(field.tag)")
        }
        
        // Validate field-specific constraints
        switch field.tag {
        case "00":
            if field.value != "01" {
                result.issues.append("Invalid payload format indicator: \(field.value)")
            }
        case "01":
            if !["11", "12"].contains(field.value) {
                result.issues.append("Invalid point of initiation: \(field.value)")
            }
        case "52":
            if field.value != "6011" {
                result.issues.append("Invalid MCC: \(field.value)")
            }
        case "53":
            if field.value != "404" {
                result.issues.append("Invalid currency code: \(field.value)")
            }
        case "58":
            if field.value != "KE" {
                result.issues.append("Invalid country code: \(field.value)")
            }
        case "63":
            // Validate CRC16
            let dataWithoutCRC = result.originalData.dropLast(8) // Remove last 8 characters (6363 + 4 digit CRC)
            let calculatedCRC = PerformanceOptimizer.calculateCRC16Optimized(String(dataWithoutCRC))
            let expectedCRC = String(format: "%04X", calculatedCRC)
            if field.value.uppercased() != expectedCRC {
                result.issues.append("CRC mismatch: expected \(expectedCRC), got \(field.value)")
            }
        default:
            break
        }
    }
    
    // MARK: - Visualization
    
    /// Generate visual representation of QR code structure
    public static func generateQRVisualization(_ analysis: QRAnalysisResult) -> String {
        var visualization = """
        
        ╔══════════════════════════════════════╗
        ║           QR CODE ANALYSIS           ║
        ╠══════════════════════════════════════╣
        ║ Data Length: \(String(format: "%4d", analysis.dataLength)) bytes                ║
        ║ Valid TLV: \(analysis.isValidTLV ? "✅ Yes" : "❌ No")                     ║
        ║ Valid Kenya P2P: \(analysis.isValidKenyaP2P ? "✅ Yes" : "❌ No")           ║
        ║ Issues: \(String(format: "%2d", analysis.issues.count))                         ║
        ╚══════════════════════════════════════╝
        
        """
        
        if !analysis.tlvFields.isEmpty {
            visualization += "\n📋 TLV STRUCTURE:\n"
            visualization += "┌─────┬────────┬──────────────────────────────────────┐\n"
            visualization += "│ Tag │ Length │ Value                                │\n"
            visualization += "├─────┼────────┼──────────────────────────────────────┤\n"
            
            for field in analysis.tlvFields {
                let truncatedValue = field.value.count > 32 ? 
                    String(field.value.prefix(29)) + "..." : field.value
                visualization += String(format: "│ %2s  │   %2d   │ %-36s │\n", 
                                      field.tag, field.length, truncatedValue)
            }
            
            visualization += "└─────┴────────┴──────────────────────────────────────┘\n"
        }
        
        if !analysis.issues.isEmpty {
            visualization += "\n⚠️ ISSUES FOUND:\n"
            for (index, issue) in analysis.issues.enumerated() {
                visualization += "\(index + 1). \(issue)\n"
            }
        }
        
        if let metrics = analysis.performanceMetrics {
            visualization += "\n📊 PERFORMANCE:\n"
            visualization += "Duration: \(String(format: "%.2f", metrics.duration * 1000))ms\n"
            visualization += "Memory: \(formatBytes(metrics.memoryUsage))\n"
        }
        
        return visualization
    }
    
    /// Format bytes for human readable display
    private static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Test Data Generation
    
    /// Generate test QR codes for various scenarios
    public static func generateTestQRCodes() -> [TestQRCode] {
        return [
            TestQRCode(
                name: "Valid Static QR",
                data: "000201010211296800010A0123456789520460115303404580258025901234567890123456789601234567890123456789622705251234567890123456789640163046B2A",
                expectedResult: .valid,
                description: "A valid static QR code with all required fields"
            ),
            TestQRCode(
                name: "Invalid CRC",
                data: "000201010211296800010A0123456789520460115303404580258025901234567890123456789601234567890123456789622705251234567890123456789640163040000",
                expectedResult: .invalidCRC,
                description: "QR code with incorrect CRC checksum"
            ),
            TestQRCode(
                name: "Missing Required Field",
                data: "00020101021129680001640163046B2A",
                expectedResult: .missingFields,
                description: "QR code missing required fields"
            ),
            TestQRCode(
                name: "Invalid Tag",
                data: "000201010211996800010A0123456789520460115303404580258025901234567890123456789601234567890123456789622705251234567890123456789640163046B2A",
                expectedResult: .unknownTag,
                description: "QR code with unknown tag"
            )
        ]
    }
    
    // MARK: - Utilities
    
    /// Pretty print any object for debugging
    public static func prettyPrint<T>(_ object: T, title: String = "") {
        let mirror = Mirror(reflecting: object)
        var output = title.isEmpty ? "Object Debug Info:\n" : "\(title):\n"
        
        if mirror.children.isEmpty {
            output += "  Value: \(object)\n"
        } else {
            for (label, value) in mirror.children {
                let propertyName = label ?? "unknown"
                output += "  \(propertyName): \(value)\n"
            }
        }
        
        log(output, level: .debug)
    }
    
    /// Get SDK version and build info
    public static func getSDKInfo() -> SDKInfo {
        return SDKInfo(
            version: "1.0.0",
            buildDate: Date(),
            platform: "iOS",
            swiftVersion: "5.9",
            supportedStandards: ["Kenya P2P QR Code Standard v0.3"]
        )
    }
    
    /// Manually parse QR code TLV structure for debugging
    /// - Parameter qrData: The QR code data string
    /// - Returns: Debug information about the TLV structure
    public static func debugTLVStructure(_ qrData: String) -> String {
        var result = "🔍 TLV Structure Analysis\n"
        result += "========================\n"
        result += "QR Data: \(qrData)\n"
        result += "Length: \(qrData.count) characters\n\n"
        
        var cursor = qrData.startIndex
        var fieldIndex = 0
        
        while cursor < qrData.endIndex {
            fieldIndex += 1
            result += "Field \(fieldIndex):\n"
            
            // Check if we have enough characters for tag
            guard qrData.distance(from: cursor, to: qrData.endIndex) >= 2 else {
                result += "❌ ERROR: Not enough data for tag (need 2 chars, have \(qrData.distance(from: cursor, to: qrData.endIndex)))\n"
                break
            }
            
            // Parse tag
            let tag = String(qrData[cursor..<qrData.index(cursor, offsetBy: 2)])
            cursor = qrData.index(cursor, offsetBy: 2)
            result += "  Tag: \(tag)\n"
            
            // Check if we have enough characters for length
            guard qrData.distance(from: cursor, to: qrData.endIndex) >= 2 else {
                result += "❌ ERROR: Not enough data for length (need 2 chars, have \(qrData.distance(from: cursor, to: qrData.endIndex)))\n"
                break
            }
            
            // Parse length
            let lengthStr = String(qrData[cursor..<qrData.index(cursor, offsetBy: 2)])
            cursor = qrData.index(cursor, offsetBy: 2)
            
            guard let length = Int(lengthStr) else {
                result += "❌ ERROR: Invalid length value: \(lengthStr)\n"
                break
            }
            
            result += "  Length: \(length) (from string '\(lengthStr)')\n"
            
            // Check if we have enough characters for value
            let remainingChars = qrData.distance(from: cursor, to: qrData.endIndex)
            if remainingChars < length {
                result += "❌ ERROR: Not enough data for value (need \(length) chars, have \(remainingChars))\n"
                result += "  Remaining data: '\(String(qrData[cursor...]))'\n"
                break
            }
            
            // Parse value
            let value = String(qrData[cursor..<qrData.index(cursor, offsetBy: length)])
            cursor = qrData.index(cursor, offsetBy: length)
            result += "  Value: '\(value)' (actual length: \(value.count))\n"
            
            // Check for common issues
            if value.count != length {
                result += "⚠️  WARNING: Value length mismatch! Expected \(length), got \(value.count)\n"
            }
            
            // Show nested structure for known template tags
            if ["26", "27", "28", "29", "62"].contains(tag) && !value.isEmpty {
                result += "  🔍 Nested TLV structure:\n"
                result += debugNestedTLV(value, indent: "    ")
            }
            
            result += "\n"
        }
        
        result += "✅ Analysis complete. Parsed \(fieldIndex) fields.\n"
        return result
    }
    
    /// Debug nested TLV structure
    private static func debugNestedTLV(_ data: String, indent: String) -> String {
        var result = ""
        var cursor = data.startIndex
        var nestedIndex = 0
        
        while cursor < data.endIndex {
            nestedIndex += 1
            
            // Check if we have enough characters for tag
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                result += "\(indent)❌ ERROR: Not enough data for nested tag\n"
                break
            }
            
            // Parse tag
            let tag = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            // Check if we have enough characters for length
            guard data.distance(from: cursor, to: data.endIndex) >= 2 else {
                result += "\(indent)❌ ERROR: Not enough data for nested length\n"
                break
            }
            
            // Parse length
            let lengthStr = String(data[cursor..<data.index(cursor, offsetBy: 2)])
            cursor = data.index(cursor, offsetBy: 2)
            
            guard let length = Int(lengthStr) else {
                result += "\(indent)❌ ERROR: Invalid nested length: \(lengthStr)\n"
                break
            }
            
            // Check if we have enough characters for value
            let remainingChars = data.distance(from: cursor, to: data.endIndex)
            if remainingChars < length {
                result += "\(indent)❌ ERROR: Not enough data for nested value (need \(length), have \(remainingChars))\n"
                break
            }
            
            // Parse value
            let value = String(data[cursor..<data.index(cursor, offsetBy: length)])
            cursor = data.index(cursor, offsetBy: length)
            
            result += "\(indent)[\(nestedIndex)] Tag: \(tag), Length: \(length), Value: '\(value)'\n"
            
            if value.count != length {
                result += "\(indent)⚠️  WARNING: Nested value length mismatch!\n"
            }
        }
        
        return result
    }
}

// MARK: - Supporting Types

public struct QRAnalysisResult {
    public var originalData: String = ""
    public var dataLength: Int = 0
    public var isValidTLV: Bool = false
    public var isValidKenyaP2P: Bool = false
    public var tlvFields: [DebugTLVField] = []
    public var issues: [String] = []
    public var parsedQRCode: ParsedQRCode?
    public var performanceMetrics: PerformanceOptimizer.PerformanceMetrics?
}

public struct DebugTLVField {
    public let tag: String
    public let length: Int
    public let value: String
    public let rawData: String
    public let position: Int
}

public struct TestQRCode {
    public let name: String
    public let data: String
    public let expectedResult: TestResult
    public let description: String
}

public enum TestResult {
    case valid
    case invalidCRC
    case missingFields
    case unknownTag
    case invalidFormat
}

public struct SDKInfo {
    public let version: String
    public let buildDate: Date
    public let platform: String
    public let swiftVersion: String
    public let supportedStandards: [String]
}

public enum DebugError: Error, LocalizedError {
    case insufficientData
    case invalidLength(String)
    case insufficientDataForField(String, Int)
    
    public var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Insufficient data for TLV parsing"
        case .invalidLength(let lengthStr):
            return "Invalid length value: \(lengthStr)"
        case .insufficientDataForField(let tag, let length):
            return "Insufficient data for field \(tag) (expected \(length) characters)"
        }
    }
}

// MARK: - Extensions

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
} 