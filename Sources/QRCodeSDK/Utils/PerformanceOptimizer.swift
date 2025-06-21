import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Performance optimization utilities for QR code operations
public class PerformanceOptimizer {
    
    // MARK: - CRC16 Optimization
    
    /// Pre-computed CRC16 lookup table for faster calculation
    private static let crc16Table: [UInt16] = {
        var table = Array<UInt16>(repeating: 0, count: 256)
        let polynomial: UInt16 = 0x1021
        
        for i in 0..<256 {
            var crc: UInt16 = UInt16(i) << 8
            for _ in 0..<8 {
                if (crc & 0x8000) != 0 {
                    crc = (crc << 1) ^ polynomial
                } else {
                    crc = crc << 1
                }
            }
            table[i] = crc
        }
        return table
    }()
    
    /// Optimized CRC16 calculation using lookup table
    public static func calculateCRC16Optimized(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        
        for byte in data {
            let tableIndex = Int(((crc >> 8) ^ UInt16(byte)) & 0xFF)
            crc = (crc << 8) ^ crc16Table[tableIndex]
        }
        
        return crc
    }
    
    /// Optimized CRC16 calculation for string data
    public static func calculateCRC16Optimized(_ string: String) -> UInt16 {
        return calculateCRC16Optimized(Data(string.utf8))
    }
    
    // MARK: - Caching System
    
    /// Cache for parsed QR codes (using NSString as value since ParsedQRCode is a struct)
    private static var qrCache = NSCache<NSString, NSString>()
    
    /// Cache for generated QR code images
    private static var imageCache = NSCache<NSString, UIImage>()
    
    /// Cache for TLV parsing results
    private static var tlvCache = NSCache<NSString, NSArray>()
    
    private static let initializeOnce: Void = {
        // Configure cache limits
        qrCache.countLimit = 100
        qrCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
        
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        tlvCache.countLimit = 200
        tlvCache.totalCostLimit = 5 * 1024 * 1024 // 5MB
    }()
    
    /// Get cached parsed QR code (disabled for struct types)
    public static func getCachedQRCode(for data: String) -> ParsedQRCode? {
        // Caching disabled for struct types - would need to implement archiving
        return nil
    }
    
    /// Cache parsed QR code (disabled for struct types)
    public static func cacheQRCode(_ qrCode: ParsedQRCode, for data: String) {
        // Caching disabled for struct types - would need to implement archiving
    }
    
    /// Get cached QR code image
    public static func getCachedImage(for key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    /// Cache QR code image
    public static func cacheImage(_ image: UIImage, for key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    /// Get cached TLV parsing result
    public static func getCachedTLVFields(for data: String) -> [TLVField]? {
        guard let cachedArray = tlvCache.object(forKey: data as NSString) else { return nil }
        return cachedArray as? [TLVField]
    }
    
    /// Cache TLV parsing result
    public static func cacheTLVFields(_ fields: [TLVField], for data: String) {
        tlvCache.setObject(fields as NSArray, forKey: data as NSString)
    }
    
    /// Clear all caches
    public static func clearAllCaches() {
        qrCache.removeAllObjects()
        imageCache.removeAllObjects()
        tlvCache.removeAllObjects()
    }
    
    /// Clear cache for specific type
    public static func clearCache(type: CacheType) {
        switch type {
        case .qrCode:
            qrCache.removeAllObjects()
        case .image:
            imageCache.removeAllObjects()
        case .tlv:
            tlvCache.removeAllObjects()
        }
    }
    
    // MARK: - Memory Pool Management
    
    /// Memory pool for frequently used byte arrays
    private static var byteArrayPool: [Data] = []
    private static let poolLock = NSLock()
    private static let maxPoolSize = 20
    
    /// Get a reusable byte array from pool
    public static func getPooledByteArray(size: Int) -> Data {
        poolLock.lock()
        defer { poolLock.unlock() }
        
        if let pooledArray = byteArrayPool.first(where: { $0.count >= size }) {
            if let index = byteArrayPool.firstIndex(where: { $0.count >= size }) {
                byteArrayPool.remove(at: index)
            }
            return Data(pooledArray.prefix(size))
        }
        
        return Data(count: size)
    }
    
    /// Return byte array to pool for reuse
    public static func returnToPool(_ data: Data) {
        poolLock.lock()
        defer { poolLock.unlock() }
        
        guard byteArrayPool.count < maxPoolSize else { return }
        byteArrayPool.append(data)
    }
    
    // MARK: - Async Processing
    
    /// Process QR code parsing asynchronously
    @available(iOS 13.0, macOS 10.15, *)
    public static func parseQRCodeAsync(_ qrData: String) async throws -> ParsedQRCode {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let parser = KenyaP2PQRParser()
                    let result = try parser.parseKenyaP2PQR(qrData)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Generate QR code asynchronously
    @available(iOS 13.0, macOS 10.15, *)
    public static func generateQRCodeAsync(_ request: QRCodeGenerationRequest) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let generator = KenyaP2PQRGenerator()
                    let result = try generator.generateQR(from: request)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Batch Processing
    
    /// Process multiple QR codes in batch
    @available(iOS 13.0, macOS 10.15, *)
    public static func parseQRCodesBatch(_ qrDataArray: [String]) async throws -> [ParsedQRCode] {
        return try await withThrowingTaskGroup(of: ParsedQRCode.self) { group in
            var results: [ParsedQRCode] = []
            
            for qrData in qrDataArray {
                group.addTask {
                    try await parseQRCodeAsync(qrData)
                }
            }
            
            for try await result in group {
                results.append(result)
            }
            
            return results
        }
    }
    
    /// Generate multiple QR codes in batch
    @available(iOS 13.0, macOS 10.15, *)
    public static func generateQRCodesBatch(_ requests: [QRCodeGenerationRequest]) async throws -> [UIImage] {
        return try await withThrowingTaskGroup(of: UIImage.self) { group in
            var results: [UIImage] = []
            
            for request in requests {
                group.addTask { [request] in
                    try await generateQRCodeAsync(request)
                }
            }
            
            for try await result in group {
                results.append(result)
            }
            
            return results
        }
    }
    
    // MARK: - Performance Monitoring
    
    /// Performance metrics tracking
    public struct PerformanceMetrics {
        public let operationType: String
        public let duration: TimeInterval
        public let memoryUsage: Int64
        public let cacheHitRate: Double
        public let timestamp: Date
    }
    
    private static var performanceMetrics: [PerformanceMetrics] = []
    private static let metricsLock = NSLock()
    
    /// Measure performance of an operation
    public static func measurePerformance<T>(
        operation: String,
        block: () throws -> T
    ) rethrows -> (result: T, metrics: PerformanceMetrics) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()
        
        let result = try block()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getMemoryUsage()
        let duration = endTime - startTime
        let memoryDelta = endMemory - startMemory
        
        let metrics = PerformanceMetrics(
            operationType: operation,
            duration: duration,
            memoryUsage: memoryDelta,
            cacheHitRate: calculateCacheHitRate(),
            timestamp: Date()
        )
        
        recordMetrics(metrics)
        
        return (result, metrics)
    }
    
    /// Get current memory usage
    private static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    /// Calculate cache hit rate
    private static func calculateCacheHitRate() -> Double {
        // Simplified cache hit rate calculation
        // In a real implementation, you'd track hits and misses
        return 0.85 // Placeholder
    }
    
    /// Record performance metrics
    private static func recordMetrics(_ metrics: PerformanceMetrics) {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        performanceMetrics.append(metrics)
        
        // Keep only recent metrics (last 1000)
        if performanceMetrics.count > 1000 {
            performanceMetrics.removeFirst(performanceMetrics.count - 1000)
        }
    }
    
    /// Get performance metrics
    public static func getPerformanceMetrics() -> [PerformanceMetrics] {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        return performanceMetrics
    }
}

// MARK: - Supporting Types

public enum CacheType {
    case qrCode
    case image
    case tlv
}

// MARK: - Extensions for mach task info

import Darwin

private struct mach_task_basic_info {
    var virtual_size: mach_vm_size_t = 0
    var resident_size: mach_vm_size_t = 0
    var resident_size_max: mach_vm_size_t = 0
    var user_time: time_value_t = time_value_t()
    var system_time: time_value_t = time_value_t()
    var policy: policy_t = 0
    var suspend_count: integer_t = 0
} 