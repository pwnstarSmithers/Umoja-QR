package com.example.sampleapp

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QRDetailsScreen(
    qrData: String,
    onBack: () -> Unit
) {
    // Parse QR data here - for now we'll show basic info
    var parsedInfo by remember { mutableStateOf<QRInfo?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    
    LaunchedEffect(qrData) {
        try {
            // Simulate parsing - you can integrate actual QR parsing logic here
            kotlinx.coroutines.delay(500)
            parsedInfo = parseQRData(qrData)
            isLoading = false
        } catch (e: Exception) {
            errorMessage = "Failed to parse QR code: ${e.message}"
            isLoading = false
        }
    }
    
    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        // Back Button - Top Left
        IconButton(
            onClick = onBack,
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(20.dp)
        ) {
            Icon(
                imageVector = Icons.Default.ArrowBack,
                contentDescription = "Back",
                tint = MaterialTheme.colorScheme.onBackground
            )
        }
        
        // Title - Top Center
        Text(
            text = "QR Code Details",
            style = MaterialTheme.typography.headlineSmall,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(top = 20.dp)
        )
        
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 80.dp) // Space for title and back button
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item { Spacer(modifier = Modifier.height(8.dp)) }
            
            when {
                isLoading -> {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(16.dp)
                            ) {
                                CircularProgressIndicator(
                                    color = MaterialTheme.colorScheme.primary
                                )
                                Text(
                                    text = "Parsing QR Code...",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                        }
                    }
                }
                
                errorMessage != null -> {
                    item {
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer
                            ),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                verticalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Error,
                                        contentDescription = null,
                                        tint = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                    Text(
                                        text = "Parse Error",
                                        style = MaterialTheme.typography.titleMedium,
                                        color = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                }
                                Text(
                                    text = errorMessage!!,
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                            }
                        }
                    }
                }
                
                parsedInfo != null -> {
                    // QR Type and Format
                    item {
                        InfoCard(
                            title = "QR Information",
                            icon = Icons.Default.QrCode
                        ) {
                            DetailRowMaterial("Type", parsedInfo!!.type, Icons.Default.Category)
                            DetailRowMaterial("Format", parsedInfo!!.format, Icons.Default.FormatListBulleted)
                            DetailRowMaterial("Country", parsedInfo!!.country, Icons.Default.Flag)
                        }
                    }
                    
                    // Payment Details
                    if (parsedInfo!!.paymentDetails.isNotEmpty()) {
                        item {
                            InfoCard(
                                title = "Payment Details",
                                icon = Icons.Default.Payment
                            ) {
                                parsedInfo!!.paymentDetails.forEach { (label, value) ->
                                    DetailRowMaterial(label, value, getIconForLabel(label))
                                }
                            }
                        }
                    }
                    
                    // Technical Details
                    item {
                        InfoCard(
                            title = "Technical Details",
                            icon = Icons.Default.Settings
                        ) {
                            DetailRowMaterial("Length", "${qrData.length} characters", Icons.Default.Straighten)
                            DetailRowMaterial("Encoding", "UTF-8", Icons.Default.Code)
                        }
                    }
                }
            }
            
            // Raw QR Data (always show)
            item {
                InfoCard(
                    title = "Raw QR Data",
                    icon = Icons.Default.DataObject
                ) {
                    Text(
                        text = qrData,
                        style = MaterialTheme.typography.bodySmall.copy(
                            fontFamily = FontFamily.Monospace,
                            fontSize = 11.sp
                        ),
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp)
                    )
                }
            }
            
            // Action Buttons
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    OutlinedButton(
                        onClick = { /* TODO: Share functionality */ },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Share")
                    }
                    
                    Button(
                        onClick = { /* TODO: Save functionality */ },
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Save,
                            contentDescription = null,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save")
                    }
                }
            }
            
            item { Spacer(modifier = Modifier.height(16.dp)) }
        }
    }
}

@Composable
private fun InfoCard(
    title: String,
    icon: ImageVector,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
            
            content()
        }
    }
}

@Composable
private fun DetailRowMaterial(
    label: String,
    value: String,
    icon: ImageVector
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(16.dp)
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = label,
                style = MaterialTheme.typography.bodySmall.copy(
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            )
            Text(
                text = value,
                style = MaterialTheme.typography.bodyMedium.copy(
                    fontWeight = FontWeight.Medium
                )
            )
        }
    }
}

private fun getIconForLabel(label: String): ImageVector {
    return when (label.lowercase()) {
        "amount" -> Icons.Default.AttachMoney
        "merchant" -> Icons.Default.Store
        "account" -> Icons.Default.AccountBox
        "reference" -> Icons.Default.Numbers
        "currency" -> Icons.Default.CurrencyExchange
        else -> Icons.Default.Info
    }
}

// Data class for parsed QR information
data class QRInfo(
    val type: String,
    val format: String,
    val country: String,
    val paymentDetails: List<Pair<String, String>>
)

// Simple QR parsing function - replace with actual SDK parsing
private fun parseQRData(qrData: String): QRInfo {
    // Basic parsing logic - you can integrate your actual QR parsing here
    return when {
        qrData.startsWith("00") -> {
            // EMVCo QR Code
            QRInfo(
                type = "EMVCo Payment QR",
                format = "EMVCo Merchant Presented Mode",
                country = if (qrData.contains("KE")) "Kenya" else "Unknown",
                paymentDetails = listOf(
                    "Merchant Category" to "Payment Service",
                    "Transaction Currency" to "KES",
                    "QR ID" to qrData.take(20) + "..."
                )
            )
        }
        qrData.startsWith("http") -> {
            QRInfo(
                type = "URL QR Code",
                format = "Website Link",
                country = "N/A",
                paymentDetails = listOf(
                    "URL" to qrData
                )
            )
        }
        else -> {
            QRInfo(
                type = "Text QR Code",
                format = "Plain Text",
                country = "N/A",
                paymentDetails = listOf(
                    "Content" to if (qrData.length > 50) "${qrData.take(50)}..." else qrData
                )
            )
        }
    }
} 