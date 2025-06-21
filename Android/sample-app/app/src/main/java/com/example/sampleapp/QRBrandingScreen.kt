package com.example.sampleapp

import android.graphics.Bitmap
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.qrcodesdk.models.*
import com.qrcodesdk.QRCodeSDK
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.math.BigDecimal

// Use the enhanced Country enum from the SDK
import com.qrcodesdk.models.Country as SDKCountry

// Import the centralized design system
import com.example.sampleapp.design.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QRBrandingScreen(
    onNavigateToScanner: () -> Unit
) {
    var selectedQRType by remember { mutableStateOf(QRType.P2M) }
    var selectedCountry by remember { mutableStateOf(SDKCountry.KENYA) }
    var isStaticQR by remember { mutableStateOf(false) }
    var amount by remember { mutableStateOf("") }
    var merchantName by remember { mutableStateOf("") }
    var merchantTill by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var qrBitmap by remember { mutableStateOf<android.graphics.Bitmap?>(null) }
    var showFloatingActions by remember { mutableStateOf(false) }
    var generatedQRData by remember { mutableStateOf<String?>(null) }
    
    // Removed bottom sheet state - now using navigation to QR details screen

    // Helper function to handle QR generation and parsing
    fun handleQRGeneration(
        qrType: QRType,
        country: SDKCountry,
        isStatic: Boolean,
        amount: String,
        merchantName: String,
        merchantTill: String,
        bank: String
    ) {
        generateQRCode(qrType, country, isStatic, amount, merchantName, merchantTill, bank) { bitmap, error, qrData ->
            qrBitmap = bitmap
            errorMessage = error
            generatedQRData = qrData
            isLoading = false
            
            // Don't automatically navigate - let user tap QR to see details
            // The bottom sheet will be shown when they tap the QR code image
        }
        isLoading = true
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            // Header with title and quick actions
            item {
                HeaderSection(
                    onSendMoney = { selectedQRType = QRType.P2P },
                    onPayMerchant = { selectedQRType = QRType.P2M },
                    onScan = { onNavigateToScanner() },
                    selectedType = selectedQRType
                )
            }
            
            // QR Code Display Area
            item {
                QRDisplaySection(
                    qrBitmap = qrBitmap,
                    isLoading = isLoading,
                    selectedCountry = selectedCountry,
                    selectedQRType = selectedQRType,
                    isStaticQR = isStaticQR,
                    amount = amount,
                    merchantName = merchantName,
                    onShowDetails = { 
                        // TODO: Future enhancement - could navigate to QR details here
                        // For now, the QR details are only shown after scanning
                    }
                )
            }
            
            // Configuration Section
            item {
                ConfigurationSection(
                    selectedCountry = selectedCountry,
                    onCountryChange = { selectedCountry = it },
                    isStaticQR = isStaticQR,
                    onModeChange = { isStaticQR = it },
                    onGenerateEquity = {
                        handleQRGeneration(selectedQRType, selectedCountry, isStaticQR, amount, merchantName, merchantTill, "EQUITY")
                    },
                    onGenerateKCB = {
                        handleQRGeneration(selectedQRType, selectedCountry, isStaticQR, amount, merchantName, merchantTill, "KCB")
                    },
                    onGenerateCoop = {
                        handleQRGeneration(selectedQRType, selectedCountry, isStaticQR, amount, merchantName, merchantTill, "COOP")
                    },
                    merchantName = merchantName,
                    onMerchantNameChange = { merchantName = it },
                    merchantTill = merchantTill,
                    onMerchantTillChange = { merchantTill = it },
                    amount = amount,
                    onAmountChange = { amount = it }
                )
            }
            
            // Scan & Parse Section
            item {
                ScanParseSection(
                    onScanQR = { onNavigateToScanner() }
                )
            }
        }
        
        // Floating Action Button
        FloatingActionButton(
            onClick = { showFloatingActions = !showFloatingActions },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp),
            containerColor = MaterialTheme.colorScheme.primary
        ) {
            Icon(
                imageVector = if (showFloatingActions) Icons.Default.Close else Icons.Default.Add,
                contentDescription = "Quick Actions",
                tint = MaterialTheme.colorScheme.onPrimary
            )
        }
    }
    
    // Bottom sheet removed - QR details now shown via navigation after scanning
}

@Composable
private fun HeaderSection(
    onSendMoney: () -> Unit,
    onPayMerchant: () -> Unit,
    onScan: () -> Unit,
    selectedType: QRType
) {
    Column(
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "QR Code Generator",
            style = MaterialTheme.typography.headlineLarge,
            color = MaterialTheme.colorScheme.onBackground,
            modifier = Modifier.padding(bottom = 8.dp)
        )
        
        Text(
            text = "Create secure payment QR codes",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(bottom = 20.dp)
        )
        
        // Quick Action Buttons
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            item {
                QuickActionButton(
                    text = "Send Money",
                    icon = Icons.Default.Send,
                    color = MaterialTheme.colorScheme.error,
                    isSelected = selectedType == QRType.P2P,
                    onClick = onSendMoney
                )
            }
            item {
                QuickActionButton(
                    text = "Pay Merchant",
                    icon = Icons.Default.Store,
                    color = MaterialTheme.colorScheme.primary,
                    isSelected = selectedType == QRType.P2M,
                    onClick = onPayMerchant
                )
            }
            item {
                QuickActionButton(
                    text = "Scan",
                    icon = Icons.Default.QrCodeScanner,
                    color = MaterialTheme.colorScheme.secondary,
                    isSelected = false,
                    onClick = onScan
                )
            }
        }
    }
}

@Composable
private fun QuickActionButton(
    text: String,
    icon: ImageVector,
    color: Color,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        colors = ButtonDefaults.buttonColors(
            containerColor = if (isSelected) color else MaterialTheme.colorScheme.surface,
            contentColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.height(44.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp, fontWeight = FontWeight.Medium)
        )
    }
}

@Composable
private fun QRDisplaySection(
    qrBitmap: Bitmap?,
    isLoading: Boolean,
    selectedCountry: SDKCountry,
    selectedQRType: QRType,
    isStaticQR: Boolean,
    amount: String,
    merchantName: String,
    onShowDetails: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .aspectRatio(1f),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        shape = RoundedCornerShape(16.dp)
    ) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            when {
                isLoading -> {
                    CircularProgressIndicator(
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier.size(50.dp)
                    )
                }
                qrBitmap != null -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.padding(20.dp)
                    ) {
                        Image(
                            bitmap = qrBitmap.asImageBitmap(),
                            contentDescription = "Generated QR Code",
                            modifier = Modifier
                                .fillMaxWidth(0.8f)
                                .aspectRatio(1f)
                                .clickable { onShowDetails() }
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Success indicator
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .background(
                                    AppDesignSystem.Colors.success.copy(alpha = 0.2f),
                                    RoundedCornerShape(8.dp)
                                )
                                .padding(horizontal = 12.dp, vertical = 6.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = AppDesignSystem.Colors.success,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "QR Generated Successfully",
                                style = AppDesignSystem.Typography.caption.copy(color = AppDesignSystem.Colors.success)
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        // QR Details
                        QRDetailsRow(selectedCountry, selectedQRType, isStaticQR, amount, merchantName)
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // View Details Button
                        AppOutlinedButton(
                            text = "View Details",
                            onClick = onShowDetails,
                            modifier = Modifier.fillMaxWidth(),
                            icon = Icons.Default.Visibility
                        )
                    }
                }
                else -> {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(
                            imageVector = Icons.Default.QrCode,
                            contentDescription = null,
                            tint = AppDesignSystem.Colors.secondary,
                            modifier = Modifier.size(100.dp)
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Generate a QR code to display here",
                            style = AppDesignSystem.Typography.body.copy(color = AppDesignSystem.Colors.secondary),
                            textAlign = TextAlign.Center
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun QRDetailsRow(
    selectedCountry: SDKCountry,
    selectedQRType: QRType,
    isStaticQR: Boolean,
    amount: String,
    merchantName: String
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        item {
            DetailChip(
                text = selectedCountry.name.take(2),
                color = AppDesignSystem.Colors.primary
            )
        }
        item {
            DetailChip(
                text = selectedQRType.name,
                color = if (selectedQRType == QRType.P2M) AppDesignSystem.Colors.success else AppDesignSystem.Colors.error
            )
        }
        item {
            DetailChip(
                text = if (isStaticQR) "Static" else "Dynamic",
                color = AppDesignSystem.Colors.warning
            )
        }
        if (selectedQRType == QRType.P2M) {
            item {
                DetailChip(
                    text = "KES $amount",
                    color = AppDesignSystem.Colors.secondary
                )
            }
            item {
                DetailChip(
                    text = merchantName,
                    color = AppDesignSystem.Colors.secondary
                )
            }
        }
    }
}

// DetailChip is now imported from the design system

@Composable
private fun ConfigurationSection(
    selectedCountry: SDKCountry,
    onCountryChange: (SDKCountry) -> Unit,
    isStaticQR: Boolean,
    onModeChange: (Boolean) -> Unit,
    onGenerateEquity: () -> Unit,
    onGenerateKCB: () -> Unit,
    onGenerateCoop: () -> Unit,
    merchantName: String,
    onMerchantNameChange: (String) -> Unit,
    merchantTill: String,
    onMerchantTillChange: (String) -> Unit,
    amount: String,
    onAmountChange: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = AppDesignSystem.Colors.surface),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Configuration",
                    style = AppDesignSystem.Typography.title
                )
                Text(
                    text = "Advanced",
                    style = AppDesignSystem.Typography.body.copy(color = AppDesignSystem.Colors.primary),
                    modifier = Modifier.clickable { /* TODO: Advanced settings */ }
                )
            }
            
            // Country Selection
            SectionLabel("Country")
            CountrySelector(selectedCountry, onCountryChange)
            
            Spacer(modifier = Modifier.height(AppDesignSystem.Spacing.xs))
            
            // Mode Selection
            SectionLabel("Mode")
            ModeSelector(isStaticQR, onModeChange)
            
            Spacer(modifier = Modifier.height(AppDesignSystem.Spacing.xs))
            
            // Bank Selection
            SectionLabel("Bank")
            BankSelector(onGenerateEquity, onGenerateKCB, onGenerateCoop)
            
            Spacer(modifier = Modifier.height(2.dp))
            
            // Input Fields
            SectionLabel("Merchant Name")
            AppInputField(
                value = merchantName,
                onValueChange = onMerchantNameChange,
                placeholder = "Enter merchant name",
                leadingIcon = Icons.Default.Store
            )
            
            Spacer(modifier = Modifier.height(AppDesignSystem.Spacing.xs))
            
            SectionLabel("Merchant Till")
            AppInputField(
                value = merchantTill,
                onValueChange = onMerchantTillChange,
                placeholder = "Enter till number",
                leadingIcon = Icons.Default.Numbers
            )
            
            Spacer(modifier = Modifier.height(AppDesignSystem.Spacing.xs))
            
            SectionLabel("Amount (KES)")
            AppInputField(
                value = amount,
                onValueChange = onAmountChange,
                placeholder = "Enter amount",
                leadingIcon = Icons.Default.AttachMoney
            )
        }
    }
}

@Composable
private fun CountrySelector(
    selectedCountry: SDKCountry,
    onCountryChange: (SDKCountry) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            SelectionChip(
                text = "🇰🇪 Kenya",
                isSelected = selectedCountry == SDKCountry.KENYA,
                onClick = { onCountryChange(SDKCountry.KENYA) }
            )
        }
        item {
            SelectionChip(
                text = "🇹🇿 Tanza...",
                isSelected = selectedCountry == SDKCountry.TANZANIA,
                onClick = { onCountryChange(SDKCountry.TANZANIA) }
            )
        }
    }
}

@Composable
private fun ModeSelector(
    isStaticQR: Boolean,
    onModeChange: (Boolean) -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            SelectionChip(
                text = "Static",
                isSelected = isStaticQR,
                onClick = { onModeChange(true) }
            )
        }
        item {
            SelectionChip(
                text = "Dynamic",
                isSelected = !isStaticQR,
                onClick = { onModeChange(false) }
            )
        }
    }
}

// SelectionChip is now imported from the design system

@Composable
private fun BankSelector(
    onGenerateEquity: () -> Unit,
    onGenerateKCB: () -> Unit,
    onGenerateCoop: () -> Unit
) {
    LazyRow(
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item {
            BankButton(
                name = "🏦 Equity Bank",
                color = AppDesignSystem.Colors.equity,
                onClick = onGenerateEquity
            )
        }
        item {
            BankButton(
                name = "🏦 KCB Bank",
                color = AppDesignSystem.Colors.kcb,
                onClick = onGenerateKCB
            )
        }
        item {
            BankButton(
                name = "🏦 Co-operati...",
                color = AppDesignSystem.Colors.coop,
                onClick = onGenerateCoop
            )
        }
    }
}

@Composable
private fun BankButton(
    name: String,
    color: Color,
    onClick: () -> Unit
) {
    Surface(
        color = color.copy(alpha = 0.2f),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.clickable { onClick() }
    ) {
        Text(
            text = name,
            style = AppDesignSystem.Typography.body.copy(
                color = color,
                fontWeight = FontWeight.Medium
            ),
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        )
    }
}

// InputField is now replaced with AppInputField from the design system

@Composable
private fun ScanParseSection(
    onScanQR: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = AppDesignSystem.Colors.surface),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(20.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(bottom = 12.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.QrCodeScanner,
                    contentDescription = null,
                    tint = AppDesignSystem.Colors.success,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = "Scan & Parse",
                    style = AppDesignSystem.Typography.title
                )
            }
            
            Text(
                text = "Scan existing QR codes to analyze",
                style = AppDesignSystem.Typography.caption,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            
            AppPrimaryButton(
                text = "Scan QR Code",
                onClick = onScanQR,
                modifier = Modifier.fillMaxWidth(),
                icon = Icons.Default.QrCodeScanner,
                backgroundColor = AppDesignSystem.Colors.success
            )
        }
    }
}

// Bottom sheet content removed - using dedicated QR details screen now

// QR code generation using SDK
private fun generateQRCode(
    qrType: QRType,
    country: SDKCountry,
    isStatic: Boolean,
    amount: String,
    merchantName: String,
    merchantTill: String,
    bank: String,
    callback: (Bitmap?, String?, String?) -> Unit
) {
    CoroutineScope(Dispatchers.IO).launch {
        delay(500) // Brief delay for UI feedback
        
        try {
            // Create QR generation request using SDK models
            val request = createQRGenerationRequest(
                qrType = qrType,
                country = country,
                isStatic = isStatic,
                amount = amount,
                merchantName = merchantName,
                merchantTill = merchantTill,
                bank = bank
            )
            
            // Generate QR data string using SDK
            val qrDataString = QRCodeSDK.generateQRString(request)
            
            // Create QR code bitmap using ZXing
            val writer = com.google.zxing.qrcode.QRCodeWriter()
            val bitMatrix = writer.encode(qrDataString, com.google.zxing.BarcodeFormat.QR_CODE, 400, 400)
            
            val bitmap = Bitmap.createBitmap(400, 400, Bitmap.Config.RGB_565)
            for (x in 0 until 400) {
                for (y in 0 until 400) {
                    bitmap.setPixel(x, y, if (bitMatrix[x, y]) android.graphics.Color.BLACK else android.graphics.Color.WHITE)
                }
            }
            
            callback(bitmap, null, qrDataString)
        } catch (e: Exception) {
            callback(null, "Failed to generate QR code: ${e.message}", null)
        }
    }
}

// Create QR generation request using SDK models
private fun createQRGenerationRequest(
    qrType: QRType,
    country: SDKCountry,
    isStatic: Boolean,
    amount: String,
    merchantName: String,
    merchantTill: String,
    bank: String
): QRCodeGenerationRequest {
    
    // Create PSP info and participant ID based on bank
    val (pspInfo, participantId) = when (bank.uppercase()) {
        "EQUITY" -> PSPInfo(
            identifier = "ke.go.qr",
            name = "Equity Bank",
            type = PSPInfo.PSPType.BANK
        ) to "22266655"
        "KCB" -> PSPInfo(
            identifier = "ke.go.qr", 
            name = "KCB Bank",
            type = PSPInfo.PSPType.BANK
        ) to "21234567"
        "COOP" -> PSPInfo(
            identifier = "ke.go.qr",
            name = "Co-op Bank",
            type = PSPInfo.PSPType.BANK
        ) to "33445566"
        else -> PSPInfo(
            identifier = "ke.go.qr",
            name = "Equity Bank",
            type = PSPInfo.PSPType.BANK
        ) to "22266655"
    }
    
    // Create account template
    val accountTemplate = AccountTemplate(
        tag = "29", // Kenya QR tag
        guid = pspInfo.identifier,
        participantId = participantId,
        accountId = merchantTill,
        pspInfo = pspInfo
    )
    
    // Convert amount to BigDecimal if provided
    val amountDecimal = if (amount.isNotBlank() && amount != "0") {
        try {
            BigDecimal(amount.replace(",", "").trim())
        } catch (e: NumberFormatException) {
            null
        }
    } else {
        null
    }
    
    // Create additional data if till number provided
    val additionalData = if (merchantTill.isNotBlank()) {
        AdditionalData(billNumber = merchantTill)
    } else {
        null
    }
    
    // Create the request
    return QRCodeGenerationRequest(
        qrType = qrType,
        initiationMethod = if (isStatic) QRInitiationMethod.STATIC else QRInitiationMethod.DYNAMIC,
        accountTemplates = listOf(accountTemplate),
        merchantCategoryCode = if (qrType == QRType.P2M) "5411" else "4829", // Grocery vs P2P
        amount = amountDecimal,
        recipientName = merchantName.ifBlank { null },
        recipientIdentifier = merchantTill.ifBlank { null },
        recipientCity = when (country) {
            SDKCountry.KENYA -> "Nairobi"
            SDKCountry.TANZANIA -> "Dar es Salaam"
        },
        currency = when (country) {
            SDKCountry.KENYA -> "404" // KES
            SDKCountry.TANZANIA -> "834" // TZS
        },
        countryCode = when (country) {
            SDKCountry.KENYA -> "KE"
            SDKCountry.TANZANIA -> "TZ"
        },
        additionalData = additionalData,
        formatVersion = "P2M-KE-01"
    )
} 