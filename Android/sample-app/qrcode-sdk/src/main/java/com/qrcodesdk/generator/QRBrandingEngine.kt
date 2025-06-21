package com.qrcodesdk.generator

import android.graphics.*
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.core.graphics.ColorUtils

// MARK: - QR Branding Core Models

/**
 * Comprehensive QR branding configuration
 */
data class QRBranding(
    val logo: QRLogo? = null,
    val colorScheme: QRColorScheme = QRColorScheme.default,
    val template: QRTemplate = QRTemplate.Standard,
    val errorCorrectionLevel: QRErrorCorrectionLevel = QRErrorCorrectionLevel.HIGH,
    val brandIdentifier: String? = null
)

/**
 * QR color scheme with support for finder pattern coloring (like Equity Bank example)
 */
data class QRColorScheme(
    val foregroundColor: Int = Color.BLACK,      // Data modules color
    val backgroundColor: Int = Color.WHITE,      // Background color
    val finderPatternColor: Int? = null,         // Corner finder patterns (like Equity red)
    val logoBackgroundColor: Int? = null         // Background color behind logo
) {
    companion object {
        /** Default black and white QR */
        val default = QRColorScheme()
        
        /** Equity Bank red branding (based on provided example) */
        val equityBank = QRColorScheme(
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            finderPatternColor = Color.rgb(204, 0, 0), // Equity Red
            logoBackgroundColor = Color.WHITE
        )
        
        /** KCB Bank blue branding */
        val kcbBank = QRColorScheme(
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            finderPatternColor = Color.rgb(0, 102, 204), // KCB Blue
            logoBackgroundColor = Color.WHITE
        )
        
        /** Standard Chartered blue branding */
        val standardChartered = QRColorScheme(
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            finderPatternColor = Color.rgb(0, 76, 153), // SC Blue
            logoBackgroundColor = Color.WHITE
        )
        
        /** Co-operative Bank green branding */
        val cooperativeBank = QRColorScheme(
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            finderPatternColor = Color.rgb(0, 153, 76), // Coop Green
            logoBackgroundColor = Color.WHITE
        )
    }
}

/**
 * QR template styles
 */
sealed class QRTemplate {
    object Standard : QRTemplate()
    data class Banking(val bank: BankTemplate) : QRTemplate()
}

/**
 * Bank-specific templates
 */
enum class BankTemplate(val identifier: String) {
    EQUITY("EQ"),
    KCB("KCB"),
    STANDARD_CHARTERED("SC"),
    COOPERATIVE("COOP");
    
    val colorScheme: QRColorScheme
        get() = when (this) {
            EQUITY -> QRColorScheme.equityBank
            KCB -> QRColorScheme.kcbBank
            STANDARD_CHARTERED -> QRColorScheme.standardChartered
            COOPERATIVE -> QRColorScheme.cooperativeBank
        }
}

/**
 * Logo configuration for QR codes
 */
data class QRLogo(
    val bitmap: Bitmap,
    val size: LogoSize = LogoSize.MEDIUM,
    val position: LogoPosition = LogoPosition.CENTER,
    val style: LogoStyle = LogoStyle.CIRCULAR
) {
    enum class LogoSize(val percentage: Float) {
        SMALL(0.12f),    // 12% of QR area
        MEDIUM(0.18f),   // 18% of QR area
        LARGE(0.25f)     // 25% of QR area
    }
    
    enum class LogoPosition {
        CENTER
    }
    
    enum class LogoStyle {
        CIRCULAR, SQUARE
    }
}

/**
 * Error correction levels
 */
enum class QRErrorCorrectionLevel(val qrLevel: String) {
    LOW("L"),        // ~7% damage recoverable
    MEDIUM("M"),     // ~15% damage recoverable
    QUARTILE("Q"),   // ~25% damage recoverable
    HIGH("H")        // ~30% damage recoverable
}

// MARK: - QR Branding Engine

/**
 * Main QR branding engine for Android
 */
class QRBrandingEngine {
    
    /**
     * Apply branding to a QR code bitmap
     */
    fun applyBranding(
        qrBitmap: Bitmap,
        branding: QRBranding,
        targetSize: Int = 512
    ): Bitmap {
        
        // 1. Scale QR to target size
        val scaledQR = scaleQRBitmap(qrBitmap, targetSize)
        
        // 2. Apply color scheme
        val coloredQR = if (branding.colorScheme != QRColorScheme.default) {
            applyColorScheme(scaledQR, branding.colorScheme)
        } else {
            scaledQR
        }
        
        // 3. Add logo if specified
        val finalQR = branding.logo?.let { logo ->
            addLogoToQR(coloredQR, logo, branding)
        } ?: coloredQR
        
        return finalQR
    }
    
    private fun scaleQRBitmap(bitmap: Bitmap, targetSize: Int): Bitmap {
        return Bitmap.createScaledBitmap(bitmap, targetSize, targetSize, false)
    }
    
    private fun applyColorScheme(bitmap: Bitmap, scheme: QRColorScheme): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        
        // Replace colors
        for (i in pixels.indices) {
            when (pixels[i]) {
                Color.BLACK -> pixels[i] = scheme.foregroundColor
                Color.WHITE -> pixels[i] = scheme.backgroundColor
            }
        }
        
        return Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
    }
    
    private fun addLogoToQR(
        qrBitmap: Bitmap,
        logo: QRLogo,
        branding: QRBranding
    ): Bitmap {
        
        val qrSize = qrBitmap.width
        val logoSizePercentage = logo.size.percentage
        val logoSize = (qrSize * logoSizePercentage).toInt()
        
        val result = qrBitmap.copy(Bitmap.Config.ARGB_8888, true)
        val canvas = Canvas(result)
        
        // Create clearance area behind logo
        val clearanceSize = (logoSize * 1.2f).toInt()
        val centerX = qrSize / 2f
        val centerY = qrSize / 2f
        
        val clearanceRect = RectF(
            centerX - clearanceSize / 2f,
            centerY - clearanceSize / 2f,
            centerX + clearanceSize / 2f,
            centerY + clearanceSize / 2f
        )
        
        // Draw clearance background
        val clearancePaint = Paint().apply {
            color = branding.colorScheme.logoBackgroundColor ?: Color.WHITE
            isAntiAlias = true
        }
        
        when (logo.style) {
            QRLogo.LogoStyle.CIRCULAR -> {
                canvas.drawOval(clearanceRect, clearancePaint)
            }
            QRLogo.LogoStyle.SQUARE -> {
                canvas.drawRect(clearanceRect, clearancePaint)
            }
        }
        
        // Draw logo
        val scaledLogo = Bitmap.createScaledBitmap(logo.bitmap, logoSize, logoSize, true)
        val logoRect = RectF(
            centerX - logoSize / 2f,
            centerY - logoSize / 2f,
            centerX + logoSize / 2f,
            centerY + logoSize / 2f
        )
        
        canvas.drawBitmap(scaledLogo, null, logoRect, null)
        
        return result
    }
}

// MARK: - Enhanced QR Style

/**
 * Enhanced QR code styling configuration
 */
data class QRCodeStyle(
    val size: Int = 512,
    val foregroundColor: Int = Color.BLACK,
    val backgroundColor: Int = Color.WHITE,
    val margin: Int = 10,
    val quietZone: Int = 4,
    val cornerRadius: Float = 0f,
    val borderWidth: Int = 0,
    val borderColor: Int? = null
) {
    companion object {
        val small = QRCodeStyle(
            size = 200,
            margin = 8,
            quietZone = 3
        )
        
        val medium = QRCodeStyle(
            size = 400,
            margin = 15,
            quietZone = 6
        )
        
        val large = QRCodeStyle(
            size = 600,
            margin = 20,
            quietZone = 8
        )
        
        val print = QRCodeStyle(
            size = 1200,
            margin = 40,
            quietZone = 16
        )
        
        /** Equity Bank branded style (matches provided example) */
        val equityBrand = QRCodeStyle(
            size = 350,
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            margin = 15,
            quietZone = 8,
            cornerRadius = 12f,
            borderWidth = 2,
            borderColor = Color.rgb(204, 0, 0)
        )
        
        /** Professional banking style */
        val banking = QRCodeStyle(
            size = 380,
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            margin = 20,
            quietZone = 10,
            cornerRadius = 8f,
            borderWidth = 1,
            borderColor = Color.BLUE
        )
        
        /** Retail point-of-sale style */
        val retail = QRCodeStyle(
            size = 320,
            foregroundColor = Color.BLACK,
            backgroundColor = Color.WHITE,
            margin = 12,
            quietZone = 6,
            cornerRadius = 6f,
            borderWidth = 2,
            borderColor = Color.rgb(255, 165, 0)
        )
    }
}

// MARK: - Errors

sealed class QRBrandingError : Exception() {
    object ImageProcessingFailed : QRBrandingError()
    object FilterNotAvailable : QRBrandingError()
    object ColorProcessingFailed : QRBrandingError()
    
    override val message: String?
        get() = when (this) {
            is ImageProcessingFailed -> "Failed to process QR image"
            is FilterNotAvailable -> "Required image filter not available"
            is ColorProcessingFailed -> "Failed to apply color scheme"
        }
} 