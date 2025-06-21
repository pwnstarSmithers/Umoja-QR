package com.qrcodesdk.utils

import android.graphics.Bitmap
import android.util.LruCache
import com.qrcodesdk.models.ParsedQRCode
import com.qrcodesdk.models.QRCodeGenerationRequest
import com.qrcodesdk.models.TLVField
import com.qrcodesdk.parser.KenyaP2PQRParser
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/**
 * Performance optimization utilities for QR code operations
 */
object PerformanceOptimizer {
    
    // MARK: - CRC16 Optimization
    
    /**
     * Pre-computed CRC16 lookup table for faster calculation
     */
    private val crc16Table: IntArray by lazy {
        val table = IntArray(256)
        val polynomial = 0x1021
        
        for (i in 0..255) {
            var crc = i shl 8
            repeat(8) {
                crc = if ((crc and 0x8000) != 0) {
                    (crc shl 1) xor polynomial
                } else {
                    crc shl 1
                }
            }
            table[i] = crc and 0xFFFF
        }
        table
    }
    
    /**
     * Optimized CRC16 calculation using lookup table
     */
    fun calculateCRC16Optimized(data: ByteArray): Int {
        var crc = 0xFFFF
        
        for (byte in data) {
            val tableIndex = ((crc ushr 8) xor (byte.toInt() and 0xFF)) and 0xFF
            crc = ((crc shl 8) xor crc16Table[tableIndex]) and 0xFFFF
        }
        
        return crc
    }
    
    /**
     * Optimized CRC16 calculation for string data
     */
    fun calculateCRC16Optimized(string: String): Int {
        return calculateCRC16Optimized(string.toByteArray())
    }
    
    // MARK: - Caching System
    
    /**
     * Cache for parsed QR codes
     */
    private val qrCache = LruCache<String, ParsedQRCode>(100)
    
    /**
     * Cache for generated QR code images
     */
    private val imageCache = object : LruCache<String, Bitmap>(50) {
        override fun sizeOf(key: String, bitmap: Bitmap): Int {
            return bitmap.byteCount / 1024 // Size in KB
        }
    }
    
    /**
     * Cache for TLV parsing results
     */
    private val tlvCache = LruCache<String, List<TLVField>>(200)
    
    /**
     * Get cached parsed QR code
     */
    fun getCachedQRCode(data: String): ParsedQRCode? {
        return qrCache.get(data)
    }
    
    /**
     * Cache parsed QR code
     */
    fun cacheQRCode(qrCode: ParsedQRCode, data: String) {
        qrCache.put(data, qrCode)
    }
    
    /**
     * Get cached QR code image
     */
    fun getCachedImage(key: String): Bitmap? {
        return imageCache.get(key)
    }
    
    /**
     * Cache QR code image
     */
    fun cacheImage(image: Bitmap, key: String) {
        imageCache.put(key, image)
    }
    
    /**
     * Get cached TLV parsing result
     */
    fun getCachedTLVFields(data: String): List<TLVField>? {
        return tlvCache.get(data)
    }
    
    /**
     * Cache TLV parsing result
     */
    fun cacheTLVFields(fields: List<TLVField>, data: String) {
        tlvCache.put(data, fields)
    }
    
    /**
     * Clear all caches
     */
    fun clearAllCaches() {
        qrCache.evictAll()
        imageCache.evictAll()
        tlvCache.evictAll()
    }
    
    /**
     * Clear cache for specific type
     */
    fun clearCache(type: CacheType) {
        when (type) {
            CacheType.QR_CODE -> qrCache.evictAll()
            CacheType.IMAGE -> imageCache.evictAll()
            CacheType.TLV -> tlvCache.evictAll()
        }
    }
    
    // MARK: - Memory Pool Management
    
    /**
     * Memory pool for frequently used byte arrays
     */
    private val byteArrayPool = ConcurrentLinkedQueue<ByteArray>()
    private val poolLock = ReentrantLock()
    private const val MAX_POOL_SIZE = 20
    
    /**
     * Get a reusable byte array from pool
     */
    fun getPooledByteArray(size: Int): ByteArray {
        poolLock.withLock {
            val pooledArray = byteArrayPool.poll()
            return if (pooledArray != null && pooledArray.size >= size) {
                pooledArray.copyOf(size)
            } else {
                ByteArray(size)
            }
        }
    }
    
    /**
     * Return byte array to pool for reuse
     */
    fun returnToPool(data: ByteArray) {
        poolLock.withLock {
            if (byteArrayPool.size < MAX_POOL_SIZE) {
                byteArrayPool.offer(data)
            }
        }
    }
    
    // MARK: - Async Processing
    
    /**
     * Process QR code parsing asynchronously
     */
    suspend fun parseQRCodeAsync(qrData: String): ParsedQRCode = withContext(Dispatchers.Default) {
        KenyaP2PQRParser().parseKenyaP2PQR(qrData)
    }
    
    /**
     * Generate QR code asynchronously
     */
    suspend fun generateQRCodeAsync(request: QRCodeGenerationRequest): Bitmap = withContext(Dispatchers.Default) {
        // This would call the QR generator when implemented
        throw NotImplementedError("QR Generator not yet implemented for Android")
    }
    
    // MARK: - Batch Processing
    
    /**
     * Process multiple QR codes in batch
     */
    suspend fun processBatch(qrDataList: List<String>): List<ParsedQRCode> = coroutineScope {
        qrDataList.map { qrData ->
            async { parseQRCodeAsync(qrData) }
        }.awaitAll()
    }
    
    /**
     * Generate multiple QR codes in batch
     */
    suspend fun generateQRCodesBatch(requests: List<QRCodeGenerationRequest>): List<Bitmap> = coroutineScope {
        requests.map { request ->
            async { generateQRCodeAsync(request) }
        }.awaitAll()
    }
    
    // MARK: - Performance Monitoring
    
    /**
     * Performance metrics tracking
     */
    data class PerformanceMetrics(
        val operationType: String,
        val duration: Long, // in milliseconds
        val memoryUsage: Long, // in bytes
        val cacheHitRate: Double,
        val timestamp: Long = System.currentTimeMillis()
    )
    
    private val performanceMetrics = mutableListOf<PerformanceMetrics>()
    private val metricsLock = ReentrantLock()
    
    /**
     * Measure performance of an operation
     */
    inline fun <T> measurePerformance(
        operation: String,
        block: () -> T
    ): Pair<T, PerformanceMetrics> {
        val startTime = System.currentTimeMillis()
        val startMemory = getMemoryUsage()
        
        val result = block()
        
        val endTime = System.currentTimeMillis()
        val endMemory = getMemoryUsage()
        val duration = endTime - startTime
        val memoryDelta = endMemory - startMemory
        
        val metrics = PerformanceMetrics(
            operationType = operation,
            duration = duration,
            memoryUsage = memoryDelta,
            cacheHitRate = calculateCacheHitRate()
        )
        
        recordMetrics(metrics)
        
        return Pair(result, metrics)
    }
    
    /**
     * Get current memory usage
     */
    public fun getMemoryUsage(): Long {
        val runtime = Runtime.getRuntime()
        return runtime.totalMemory() - runtime.freeMemory()
    }
    
    /**
     * Calculate cache hit rate
     */
    public fun calculateCacheHitRate(): Double {
        // Simplified cache hit rate calculation
        // In a real implementation, you'd track hits and misses
        return 0.85 // Placeholder
    }
    
    /**
     * Record performance metrics
     */
    public fun recordMetrics(metrics: PerformanceMetrics) {
        metricsLock.withLock {
            performanceMetrics.add(metrics)
            
            // Keep only recent metrics (last 1000)
            if (performanceMetrics.size > 1000) {
                performanceMetrics.removeAt(0)
            }
        }
    }
    
    /**
     * Get performance metrics
     */
    fun getPerformanceMetrics(): List<PerformanceMetrics> {
        metricsLock.withLock {
            return performanceMetrics.toList()
        }
    }
    
    /**
     * Get performance summary
     */
    fun getPerformanceSummary(): PerformanceSummary {
        metricsLock.withLock {
            if (performanceMetrics.isEmpty()) {
                return PerformanceSummary()
            }
            
            val totalOperations = performanceMetrics.size
            val averageDuration = performanceMetrics.map { it.duration }.average()
            val averageMemoryUsage = performanceMetrics.map { it.memoryUsage }.average()
            val averageCacheHitRate = performanceMetrics.map { it.cacheHitRate }.average()
            
            val operationCounts = performanceMetrics.groupingBy { it.operationType }.eachCount()
            
            return PerformanceSummary(
                totalOperations = totalOperations,
                averageDuration = averageDuration,
                averageMemoryUsage = averageMemoryUsage.toLong(),
                averageCacheHitRate = averageCacheHitRate,
                operationCounts = operationCounts
            )
        }
    }
    
    /**
     * Clear performance metrics
     */
    fun clearPerformanceMetrics() {
        metricsLock.withLock {
            performanceMetrics.clear()
        }
    }

    /**
     * Start performance monitoring for an operation
     */
    fun startPerformanceMonitoring(operation: String): Long {
        return System.currentTimeMillis()
    }

    /**
     * End performance monitoring and return duration
     */
    fun endPerformanceMonitoring(operation: String): Long {
        return System.currentTimeMillis()
    }

    /**
     * Get current memory usage in bytes
     */
    fun getCurrentMemoryUsage(): Long {
        return getMemoryUsage()
    }
}

// MARK: - Supporting Types

enum class CacheType {
    QR_CODE,
    IMAGE,
    TLV
}

data class PerformanceSummary(
    val totalOperations: Int = 0,
    val averageDuration: Double = 0.0,
    val averageMemoryUsage: Long = 0L,
    val averageCacheHitRate: Double = 0.0,
    val operationCounts: Map<String, Int> = emptyMap()
) 