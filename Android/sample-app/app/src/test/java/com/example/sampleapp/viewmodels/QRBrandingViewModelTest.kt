package com.example.sampleapp.viewmodels

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Before
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import com.qrcodesdk.models.QRType

@OptIn(ExperimentalCoroutinesApi::class)
class QRBrandingViewModelTest {
    
    private lateinit var viewModel: QRBrandingViewModel
    private val testDispatcher = StandardTestDispatcher()
    
    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        viewModel = QRBrandingViewModel()
    }
    
    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
    
    @Test
    fun `initial state should be correct`() = runTest {
        val initialState = viewModel.uiState.value
        
        assertEquals("", initialState.amount)
        assertEquals("", initialState.merchantName)
        assertEquals("", initialState.merchantId)
        assertEquals(QRType.P2M, initialState.qrType)
        assertFalse(initialState.isGenerating)
        assertNull(initialState.generatedQRData)
        assertNull(initialState.error)
        assertFalse(initialState.showPreview)
    }
    
    @Test
    fun `updateAmount should update state`() = runTest {
        viewModel.updateAmount("100.50")
        
        assertEquals("100.50", viewModel.uiState.value.amount)
    }
    
    @Test
    fun `updateMerchantName should update state`() = runTest {
        viewModel.updateMerchantName("Test Merchant")
        
        assertEquals("Test Merchant", viewModel.uiState.value.merchantName)
    }
    
    @Test
    fun `updateMerchantId should update state`() = runTest {
        viewModel.updateMerchantId("MERCH001")
        
        assertEquals("MERCH001", viewModel.uiState.value.merchantId)
    }
    
    @Test
    fun `updateQRType should update state`() = runTest {
        viewModel.updateQRType(QRType.P2P)
        
        assertEquals(QRType.P2P, viewModel.uiState.value.qrType)
    }
    
    @Test
    fun `generateQR with empty amount should show error`() = runTest {
        viewModel.updateMerchantName("Test Merchant")
        viewModel.generateQR()
        
        testDispatcher.scheduler.advanceUntilIdle()
        
        assertTrue(viewModel.uiState.value.error?.contains("Amount is required") == true)
        assertFalse(viewModel.uiState.value.isGenerating)
    }
    
    @Test
    fun `generateQR with empty merchant name should show error`() = runTest {
        viewModel.updateAmount("100.00")
        viewModel.generateQR()
        
        testDispatcher.scheduler.advanceUntilIdle()
        
        assertTrue(viewModel.uiState.value.error?.contains("Merchant name is required") == true)
        assertFalse(viewModel.uiState.value.isGenerating)
    }
    
    @Test
    fun `generateQR with zero amount should show error`() = runTest {
        viewModel.updateAmount("0")
        viewModel.updateMerchantName("Test Merchant")
        viewModel.generateQR()
        
        testDispatcher.scheduler.advanceUntilIdle()
        
        assertTrue(viewModel.uiState.value.error?.contains("Amount must be greater than 0") == true)
        assertFalse(viewModel.uiState.value.isGenerating)
    }
    
    @Test
    fun `generateQR with negative amount should show error`() = runTest {
        viewModel.updateAmount("-50.00")
        viewModel.updateMerchantName("Test Merchant")
        viewModel.generateQR()
        
        testDispatcher.scheduler.advanceUntilIdle()
        
        assertTrue(viewModel.uiState.value.error?.contains("Amount must be greater than 0") == true)
        assertFalse(viewModel.uiState.value.isGenerating)
    }
    
    @Test
    fun `hidePreview should hide preview`() = runTest {
        viewModel.hidePreview()
        
        assertFalse(viewModel.uiState.value.showPreview)
    }
    
    @Test
    fun `clearError should clear error`() = runTest {
        viewModel.clearError()
        
        assertNull(viewModel.uiState.value.error)
    }
    
    @Test
    fun `reset should reset to initial state`() = runTest {
        // Set some values first
        viewModel.updateAmount("100.00")
        viewModel.updateMerchantName("Test Merchant")
        viewModel.updateQRType(QRType.P2P)
        
        viewModel.reset()
        
        val state = viewModel.uiState.value
        assertEquals("", state.amount)
        assertEquals("", state.merchantName)
        assertEquals("", state.merchantId)
        assertEquals(QRType.P2M, state.qrType)
        assertFalse(state.isGenerating)
        assertNull(state.generatedQRData)
        assertNull(state.error)
        assertFalse(state.showPreview)
    }
} 