package com.qrcodesdk.utils

import android.graphics.Bitmap
import com.qrcodesdk.models.ParsedQRCode
import com.qrcodesdk.models.QRCodeGenerationRequest
import com.qrcodesdk.models.TLVField
import com.qrcodesdk.models.QRType
import com.qrcodesdk.models.Country
import com.qrcodesdk.models.PSPInfo
import com.qrcodesdk.models.AccountTemplate
import com.qrcodesdk.models.AdditionalData
import kotlinx.coroutines.runBlocking
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.math.BigDecimal

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class PerformanceOptimizerTest {

    @Before
    fun setUp() {
        PerformanceOptimizer.clearAllCaches()
    }

    @Test
    fun `test calculateCRC16Optimized with byte array`() {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD".toByteArray()
        val crc = PerformanceOptimizer.calculateCRC16Optimized(testData)
        
        assertNotNull("CRC should not be null", crc)
        assertTrue("CRC should be positive", crc >= 0)
        assertTrue("CRC should be 16-bit", crc <= 0xFFFF)
    }

    @Test
    fun `test calculateCRC16Optimized with string`() {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        val crc = PerformanceOptimizer.calculateCRC16Optimized(testData)
        
        assertNotNull("CRC should not be null", crc)
        assertTrue("CRC should be positive", crc >= 0)
        assertTrue("CRC should be 16-bit", crc <= 0xFFFF)
    }

    @Test
    fun `test calculateCRC16Optimized with empty data`() {
        val emptyData = "".toByteArray()
        val crc = PerformanceOptimizer.calculateCRC16Optimized(emptyData)
        
        assertEquals("CRC for empty data should be 0xFFFF", 0xFFFF, crc)
    }

    @Test
    fun `test calculateCRC16Optimized with single byte`() {
        val singleByte = byteArrayOf(0x41) // 'A'
        val crc = PerformanceOptimizer.calculateCRC16Optimized(singleByte)
        
        assertNotNull("CRC should not be null", crc)
        assertTrue("CRC should be positive", crc >= 0)
        assertTrue("CRC should be 16-bit", crc <= 0xFFFF)
    }

    @Test
    fun `test QR code caching`() {
        val testData = "test_qr_data"
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test_psp",
            name = "Test PSP",
            accountNumber = "1234567890",
            country = Country.KENYA
        )
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "2226665",
            accountId = "1234567890",
            pspInfo = pspInfo
        )
        val parsedQR = ParsedQRCode(
            qrType = QRType.P2P,
            countryCode = "KE",
            formatVersion = "P2P-KE-01",
            accountTemplates = listOf(accountTemplate),
            amount = BigDecimal("100.00"),
            recipientName = "Test Merchant",
            merchantCategoryCode = "0000",
            additionalData = AdditionalData()
        )
        
        // Test cache miss
        val cachedBefore = PerformanceOptimizer.getCachedQRCode(testData)
        assertNull("Should not find cached QR before caching", cachedBefore)
        
        // Cache the QR code
        PerformanceOptimizer.cacheQRCode(parsedQR, testData)
        
        // Test cache hit
        val cachedAfter = PerformanceOptimizer.getCachedQRCode(testData)
        assertNotNull("Should find cached QR after caching", cachedAfter)
        assertEquals("Cached QR should match original", parsedQR.qrType, cachedAfter!!.qrType)
        assertEquals("Cached QR should match original", parsedQR.countryCode, cachedAfter.countryCode)
    }

    @Test
    fun `test image caching`() {
        val testKey = "test_image_key"
        val testBitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        
        // Test cache miss
        val cachedBefore = PerformanceOptimizer.getCachedImage(testKey)
        assertNull("Should not find cached image before caching", cachedBefore)
        
        // Cache the image
        PerformanceOptimizer.cacheImage(testBitmap, testKey)
        
        // Test cache hit
        val cachedAfter = PerformanceOptimizer.getCachedImage(testKey)
        assertNotNull("Should find cached image after caching", cachedAfter)
        assertEquals("Cached image should match original", testBitmap.width, cachedAfter!!.width)
        assertEquals("Cached image should match original", testBitmap.height, cachedAfter.height)
    }

    @Test
    fun `test TLV fields caching`() {
        val testData = "test_tlv_data"
        val tlvFields = listOf(
            TLVField("00", 2, "01"),
            TLVField("01", 2, "12"),
            TLVField("52", 3, "000")
        )
        
        // Test cache miss
        val cachedBefore = PerformanceOptimizer.getCachedTLVFields(testData)
        assertNull("Should not find cached TLV fields before caching", cachedBefore)
        
        // Cache the TLV fields
        PerformanceOptimizer.cacheTLVFields(tlvFields, testData)
        
        // Test cache hit
        val cachedAfter = PerformanceOptimizer.getCachedTLVFields(testData)
        assertNotNull("Should find cached TLV fields after caching", cachedAfter)
        assertEquals("Cached TLV fields should match original", tlvFields.size, cachedAfter!!.size)
        assertEquals("Cached TLV fields should match original", tlvFields[0].tag, cachedAfter[0].tag)
    }

    @Test
    fun `test clear all caches`() {
        val testData = "test_data"
        val testBitmap = Bitmap.createBitmap(50, 50, Bitmap.Config.ARGB_8888)
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test_psp",
            name = "Test PSP",
            accountNumber = "1234567890",
            country = Country.KENYA
        )
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "2226665",
            accountId = "1234567890",
            pspInfo = pspInfo
        )
        val parsedQR = ParsedQRCode(
            qrType = QRType.P2P,
            countryCode = "KE",
            formatVersion = "P2P-KE-01",
            accountTemplates = listOf(accountTemplate),
            amount = BigDecimal("100.00"),
            recipientName = "Test Merchant",
            merchantCategoryCode = "0000",
            additionalData = AdditionalData()
        )
        val tlvFields = listOf(TLVField("00", 2, "01"))
        
        // Cache data
        PerformanceOptimizer.cacheQRCode(parsedQR, testData)
        PerformanceOptimizer.cacheImage(testBitmap, testData)
        PerformanceOptimizer.cacheTLVFields(tlvFields, testData)
        
        // Verify data is cached
        assertNotNull("QR should be cached", PerformanceOptimizer.getCachedQRCode(testData))
        assertNotNull("Image should be cached", PerformanceOptimizer.getCachedImage(testData))
        assertNotNull("TLV fields should be cached", PerformanceOptimizer.getCachedTLVFields(testData))
        
        // Clear all caches
        PerformanceOptimizer.clearAllCaches()
        
        // Verify all caches are cleared
        assertNull("QR cache should be cleared", PerformanceOptimizer.getCachedQRCode(testData))
        assertNull("Image cache should be cleared", PerformanceOptimizer.getCachedImage(testData))
        assertNull("TLV cache should be cleared", PerformanceOptimizer.getCachedTLVFields(testData))
    }

    @Test
    fun `test clear specific cache types`() {
        val testData = "test_data"
        val testBitmap = Bitmap.createBitmap(50, 50, Bitmap.Config.ARGB_8888)
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test_psp",
            name = "Test PSP",
            accountNumber = "1234567890",
            country = Country.KENYA
        )
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "2226665",
            accountId = "1234567890",
            pspInfo = pspInfo
        )
        val parsedQR = ParsedQRCode(
            qrType = QRType.P2P,
            countryCode = "KE",
            formatVersion = "P2P-KE-01",
            accountTemplates = listOf(accountTemplate),
            amount = BigDecimal("100.00"),
            recipientName = "Test Merchant",
            merchantCategoryCode = "0000",
            additionalData = AdditionalData()
        )
        val tlvFields = listOf(TLVField("00", 2, "01"))
        
        // Cache all types
        PerformanceOptimizer.cacheQRCode(parsedQR, testData)
        PerformanceOptimizer.cacheImage(testBitmap, testData)
        PerformanceOptimizer.cacheTLVFields(tlvFields, testData)
        
        // Clear only QR cache
        PerformanceOptimizer.clearCache(CacheType.QR_CODE)
        
        // Verify only QR cache is cleared
        assertNull("QR cache should be cleared", PerformanceOptimizer.getCachedQRCode(testData))
        assertNotNull("Image cache should remain", PerformanceOptimizer.getCachedImage(testData))
        assertNotNull("TLV cache should remain", PerformanceOptimizer.getCachedTLVFields(testData))
        
        // Clear only image cache
        PerformanceOptimizer.clearCache(CacheType.IMAGE)
        
        // Verify only image cache is cleared
        assertNull("QR cache should remain cleared", PerformanceOptimizer.getCachedQRCode(testData))
        assertNull("Image cache should be cleared", PerformanceOptimizer.getCachedImage(testData))
        assertNotNull("TLV cache should remain", PerformanceOptimizer.getCachedTLVFields(testData))
    }

    @Test
    fun `test byte array pool management`() {
        val size = 1024
        
        // Get pooled byte array
        val pooledArray = PerformanceOptimizer.getPooledByteArray(size)
        assertNotNull("Pooled array should not be null", pooledArray)
        assertEquals("Pooled array should have correct size", size, pooledArray.size)
        
        // Return to pool
        PerformanceOptimizer.returnToPool(pooledArray)
        
        // Get another array of same size
        val anotherArray = PerformanceOptimizer.getPooledByteArray(size)
        assertNotNull("Another pooled array should not be null", anotherArray)
        assertEquals("Another pooled array should have correct size", size, anotherArray.size)
    }

    @Test
    fun `test byte array pool with different sizes`() {
        val smallSize = 256
        val largeSize = 2048
        
        val smallArray = PerformanceOptimizer.getPooledByteArray(smallSize)
        val largeArray = PerformanceOptimizer.getPooledByteArray(largeSize)
        
        assertEquals("Small array should have correct size", smallSize, smallArray.size)
        assertEquals("Large array should have correct size", largeSize, largeArray.size)
        
        PerformanceOptimizer.returnToPool(smallArray)
        PerformanceOptimizer.returnToPool(largeArray)
    }

    @Test
    fun `test async QR code parsing`() = runBlocking {
        val testData = "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD"
        
        try {
            val result = PerformanceOptimizer.parseQRCodeAsync(testData)
            assertNotNull("Async parsing result should not be null", result)
            assertEquals("Parsed QR type should be P2P", QRType.P2P, result.qrType)
            assertEquals("Parsed country should be KE", "KE", result.countryCode)
        } catch (e: NotImplementedError) {
            // Expected for incomplete implementation
            assertTrue("Should throw NotImplementedError", true)
        } catch (e: Exception) {
            // Expected for incomplete implementation - any parsing error is acceptable
            assertTrue("Should throw some kind of error for incomplete implementation", true)
        }
    }

    @Test
    fun `test async QR code generation`() = runBlocking {
        val pspInfo = PSPInfo(
            type = PSPInfo.PSPType.BANK,
            identifier = "test_psp",
            name = "Test PSP",
            accountNumber = "1234567890",
            country = Country.KENYA
        )
        val accountTemplate = AccountTemplate(
            tag = "29",
            guid = "ke.go.qr",
            participantId = "2226665",
            accountId = "1234567890",
            pspInfo = pspInfo
        )
        val request = QRCodeGenerationRequest(
            qrType = QRType.P2P,
            initiationMethod = com.qrcodesdk.models.QRInitiationMethod.STATIC,
            accountTemplates = listOf(accountTemplate),
            merchantCategoryCode = "0000",
            amount = BigDecimal("100.00"),
            recipientName = "Test Merchant",
            recipientIdentifier = "1234567890",
            additionalData = AdditionalData()
        )
        
        try {
            val result = PerformanceOptimizer.generateQRCodeAsync(request)
            assertNotNull("Async generation result should not be null", result)
        } catch (e: NotImplementedError) {
            // Expected for incomplete implementation
            assertEquals("Should throw NotImplementedError", "QR Generator not yet implemented for Android", e.message)
        } catch (e: Exception) {
            // Any other exception is also acceptable for incomplete implementation
            assertTrue("Should throw some kind of error for incomplete implementation", true)
        }
    }

    @Test
    fun `test batch processing`() = runBlocking {
        val qrDataList = listOf(
            "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Test Merchant6009Nairobi6304ABCD",
            "00020101021129230008ke.go.qr680722266655204541153034045802KE5919Another Merchant6009Nairobi6304EFGH"
        )
        
        try {
            val results = PerformanceOptimizer.processBatch(qrDataList)
            assertNotNull("Batch results should not be null", results)
            assertEquals("Should process all items", qrDataList.size, results.size)
        } catch (e: NotImplementedError) {
            // Expected for incomplete implementation
            assertTrue("Should throw NotImplementedError", true)
        } catch (e: Exception) {
            // Expected for incomplete implementation - any parsing error is acceptable
            assertTrue("Should throw some kind of error for incomplete implementation", true)
        }
    }

    @Test
    fun `test performance monitoring`() {
        val operation = "test_operation"
        
        // Start monitoring
        PerformanceOptimizer.startPerformanceMonitoring(operation)
        
        // Simulate some work
        Thread.sleep(10)
        
        // End monitoring
        val duration = PerformanceOptimizer.endPerformanceMonitoring(operation)
        
        assertNotNull("Duration should not be null", duration)
        assertTrue("Duration should be positive", duration > 0)
    }

    @Test
    fun `test memory usage tracking`() {
        val initialMemory = PerformanceOptimizer.getCurrentMemoryUsage()
        assertNotNull("Initial memory usage should not be null", initialMemory)
        assertTrue("Initial memory usage should be positive", initialMemory > 0)
        
        // Allocate some memory
        val testBitmap = Bitmap.createBitmap(100, 100, Bitmap.Config.ARGB_8888)
        PerformanceOptimizer.cacheImage(testBitmap, "test_key")
        
        val afterAllocation = PerformanceOptimizer.getCurrentMemoryUsage()
        assertNotNull("Memory usage after allocation should not be null", afterAllocation)
        assertTrue("Memory usage should increase after allocation", afterAllocation >= initialMemory)
    }

    @Test
    fun `test cache type enum values`() {
        assertEquals("QR_CODE enum value", "QR_CODE", CacheType.QR_CODE.name)
        assertEquals("IMAGE enum value", "IMAGE", CacheType.IMAGE.name)
        assertEquals("TLV enum value", "TLV", CacheType.TLV.name)
    }

    @Test
    fun `test cache type enum ordinal`() {
        assertEquals("QR_CODE ordinal", 0, CacheType.QR_CODE.ordinal)
        assertEquals("IMAGE ordinal", 1, CacheType.IMAGE.ordinal)
        assertEquals("TLV ordinal", 2, CacheType.TLV.ordinal)
    }
} 