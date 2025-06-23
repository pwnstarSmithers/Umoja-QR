package com.qrcodesdk.models

import org.junit.Assert.*
import org.junit.Test

/**
 * Comprehensive tests for PSPDirectory functionality
 */
class PSPDirectoryTest {
    
    @Test
    fun testGetInstance() {
        val instance1 = PSPDirectory.getInstance()
        val instance2 = PSPDirectory.getInstance()
        
        assertNotNull("Should return instance", instance1)
        assertSame("Should return same instance", instance1, instance2)
    }
    
    @Test
    fun testGetPSPWithValidGUID() {
        val directory = PSPDirectory.getInstance()
        
        // Test CBK standard GUID
        val cbkPSP = directory.getPSP("ke.go.qr", Country.KENYA)
        assertNotNull("Should find CBK PSP", cbkPSP)
        assertEquals("Should be bank type", PSPInfo.PSPType.BANK, cbkPSP?.type)
        assertEquals("Should be Kenya", Country.KENYA, cbkPSP?.country)
        assertEquals("CBK", cbkPSP?.identifier)
        
        // Test Tanzania GUID
        val tanzaniaPSP = directory.getPSP("01001", Country.TANZANIA)
        assertNotNull("Should find Tanzania PSP", tanzaniaPSP)
        assertEquals("Should be Tanzania", Country.TANZANIA, tanzaniaPSP?.country)
    }
    
    @Test
    fun testGetPSPWithInvalidGUID() {
        val directory = PSPDirectory.getInstance()
        
        val invalidPSP = directory.getPSP("invalid.guid", Country.KENYA)
        assertNull("Should return null for invalid GUID", invalidPSP)
        
        val nullPSP = directory.getPSP("", Country.KENYA)
        assertNull("Should return null for empty GUID", nullPSP)
    }
    
    @Test
    fun testGetPSPWithDifferentCountries() {
        val directory = PSPDirectory.getInstance()
        
        // Test Kenya PSPs
        val kenyaPSP = directory.getPSP("ke.go.qr", Country.KENYA)
        assertNotNull("Should find Kenya PSP", kenyaPSP)
        assertEquals("Should be Kenya", Country.KENYA, kenyaPSP?.country)
        
        // Test Tanzania PSPs
        val tanzaniaPSP = directory.getPSP("01001", Country.TANZANIA)
        assertNotNull("Should find Tanzania PSP", tanzaniaPSP)
        assertEquals("Should be Tanzania", Country.TANZANIA, tanzaniaPSP?.country)
    }
    
    @Test
    fun testGetAllPSPs() {
        val directory = PSPDirectory.getInstance()
        
        val kenyaPSPs = directory.getAllPSPs(Country.KENYA)
        assertNotNull("Should return list for Kenya", kenyaPSPs)
        assertTrue("Should have multiple PSPs", kenyaPSPs.isNotEmpty())
        
        val tanzaniaPSPs = directory.getAllPSPs(Country.TANZANIA)
        assertNotNull("Should return list for Tanzania", tanzaniaPSPs)
        assertTrue("Should have multiple PSPs", tanzaniaPSPs.isNotEmpty())
    }
    
    @Test
    fun testPSPInfoProperties() {
        val directory = PSPDirectory.getInstance()
        val psp = directory.getPSP("ke.go.qr", Country.KENYA)
        
        assertNotNull("Should find PSP", psp)
        assertNotNull("Should have name", psp?.name)
        assertNotNull("Should have identifier", psp?.identifier)
        assertNotNull("Should have country", psp?.country)
        assertNotNull("Should have type", psp?.type)
    }
    
    @Test
    fun testPSPDirectoryConsistency() {
        val directory = PSPDirectory.getInstance()
        
        // Test that all PSPs have valid properties
        listOf(Country.KENYA, Country.TANZANIA).forEach { country ->
            val psps = directory.getAllPSPs(country)
            psps.forEach { psp ->
                assertNotNull("PSP name should not be null", psp.name)
                assertNotNull("PSP identifier should not be null", psp.identifier)
                assertNotNull("PSP country should not be null", psp.country)
                assertNotNull("PSP type should not be null", psp.type)
                assertEquals("PSP country should match", country, psp.country)
            }
        }
    }
} 