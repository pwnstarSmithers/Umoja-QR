package com.qrcodesdk.models

import org.junit.Assert.*
import org.junit.Test

/**
 * Comprehensive tests for MerchantCategories functionality
 */
class MerchantCategoriesTest {
    
    @Test
    fun testIsP2PWithValidCodes() {
        assertTrue(MerchantCategories.isP2P("6011"))
        assertTrue(MerchantCategories.isP2P("6012"))
        assertTrue(MerchantCategories.isP2P("6051"))
    }
    
    @Test
    fun testIsP2PWithInvalidCodes() {
        assertFalse(MerchantCategories.isP2P("5411"))
        assertFalse(MerchantCategories.isP2P("5812"))
        assertFalse(MerchantCategories.isP2P("0000"))
    }
    
    @Test
    fun testGetMerchantCategory() {
        val cat = MerchantCategories.getMerchantCategory("5411")
        assertNotNull(cat)
        assertEquals("Grocery Stores, Supermarkets", cat?.description)
        assertEquals(CategoryType.RETAIL, cat?.type)
    }
    
    @Test
    fun testGetMerchantCategoryInvalid() {
        val cat = MerchantCategories.getMerchantCategory("9999")
        assertNull(cat)
    }
    
    @Test
    fun testIsValidMCC() {
        assertTrue(MerchantCategories.isValidMCC("5411"))
        assertFalse(MerchantCategories.isValidMCC("541"))
        assertFalse(MerchantCategories.isValidMCC("abcd"))
        assertFalse(MerchantCategories.isValidMCC(""))
    }
    
    @Test
    fun testGetCategoryType() {
        assertEquals(CategoryType.FINANCIAL, MerchantCategories.getCategoryType("6011"))
        assertEquals(CategoryType.RETAIL, MerchantCategories.getCategoryType("5411"))
        assertEquals(CategoryType.OTHER, MerchantCategories.getCategoryType("9999"))
    }
    
    @Test
    fun testGetDisplayName() {
        assertEquals("Financial Services", MerchantCategories.getDisplayName("6011"))
        assertEquals("Grocery Stores, Supermarkets", MerchantCategories.getDisplayName("5411"))
        assertTrue(MerchantCategories.getDisplayName("9999").startsWith("Unknown Merchant"))
    }
    
    @Test
    fun testSuggestMCCs() {
        val mccs = MerchantCategories.suggestMCCs("grocery")
        assertTrue(mccs.contains("5411"))
    }
    
    @Test
    fun testGetMCCs() {
        val retailMCCs = MerchantCategories.getMCCs(CategoryType.RETAIL)
        assertTrue(retailMCCs.contains("5411"))
        val financialMCCs = MerchantCategories.getMCCs(CategoryType.FINANCIAL)
        assertTrue(financialMCCs.contains("6011"))
    }
    
    @Test
    fun testGetValidationRules() {
        val rules = MerchantCategories.getValidationRules("5411")
        assertTrue(rules.requiresAmount)
        assertTrue(rules.requiresCity)
        assertTrue(rules.requiresMerchantName)
        assertTrue(rules.allowsStaticQR)
        assertNotNull(rules.maxAmountLimit)
    }
} 