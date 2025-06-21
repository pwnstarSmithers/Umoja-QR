package com.example.sampleapp.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.qrcodesdk.QRCodeSDK
import com.qrcodesdk.models.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.math.BigDecimal

// Dummy PSPInfo for demo purposes (should be replaced with real PSP info in production)
private val defaultPSPInfo = PSPInfo(
    type = PSPInfo.PSPType.BANK,
    identifier = "ke.go.qr",
    name = "CBK Standard"
)

private const val DEFAULT_MCC = "6011" // Financial institutions (P2P)

// UI State for QR Branding

data class QRBrandingUiState(
    val amount: String = "",
    val merchantName: String = "",
    val merchantId: String = "",
    val qrType: QRType = QRType.P2M,
    val isGenerating: Boolean = false,
    val generatedQRData: String? = null,
    val error: String? = null,
    val showPreview: Boolean = false
)

class QRBrandingViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(QRBrandingUiState())
    val uiState: StateFlow<QRBrandingUiState> = _uiState.asStateFlow()

    fun updateAmount(amount: String) {
        _uiState.value = _uiState.value.copy(amount = amount)
    }

    fun updateMerchantName(name: String) {
        _uiState.value = _uiState.value.copy(merchantName = name)
    }

    fun updateMerchantId(id: String) {
        _uiState.value = _uiState.value.copy(merchantId = id)
    }

    fun updateQRType(type: QRType) {
        _uiState.value = _uiState.value.copy(qrType = type)
    }

    fun generateQR() {
        viewModelScope.launch {
            try {
                _uiState.value = _uiState.value.copy(isGenerating = true, error = null)
                val currentState = _uiState.value

                // Validate inputs
                if (currentState.amount.isBlank()) {
                    throw IllegalArgumentException("Amount is required")
                }
                if (currentState.merchantName.isBlank()) {
                    throw IllegalArgumentException("Merchant name is required")
                }
                val amount = BigDecimal(currentState.amount)
                if (amount <= BigDecimal.ZERO) {
                    throw IllegalArgumentException("Amount must be greater than 0")
                }

                // Build AccountTemplate (for demo, use BANK/ke.go.qr)
                val accountTemplate = AccountTemplate(
                    tag = "29", // Bank
                    guid = defaultPSPInfo.identifier,
                    participantId = currentState.merchantId.ifBlank { "DEMO001" },
                    pspInfo = defaultPSPInfo
                )

                // Build QRCodeGenerationRequest
                val request = QRCodeGenerationRequest(
                    qrType = currentState.qrType,
                    initiationMethod = QRInitiationMethod.DYNAMIC,
                    accountTemplates = listOf(accountTemplate),
                    merchantCategoryCode = DEFAULT_MCC,
                    amount = amount,
                    recipientName = currentState.merchantName,
                    recipientIdentifier = currentState.merchantId.ifBlank { "DEMO001" },
                    countryCode = "KE"
                )

                // Generate QR string
                val qrData = QRCodeSDK.generateQRString(request)

                _uiState.value = _uiState.value.copy(
                    isGenerating = false,
                    generatedQRData = qrData,
                    showPreview = true
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isGenerating = false,
                    error = e.message ?: "Failed to generate QR code"
                )
            }
        }
    }

    fun hidePreview() {
        _uiState.value = _uiState.value.copy(showPreview = false)
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun reset() {
        _uiState.value = QRBrandingUiState()
    }
} 