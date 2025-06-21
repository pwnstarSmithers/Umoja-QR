package com.qrcodesdk.generator

import android.graphics.Bitmap
import android.graphics.Color
import org.junit.Test
import org.junit.Assert.*
import org.junit.Before
import org.junit.runner.RunWith
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class QRBrandingEngineTest {

    private lateinit var brandingEngine: QRBrandingEngine
    private lateinit var testQRBitmap: Bitmap

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        brandingEngine = QRBrandingEngine()
        
        // Create a test QR bitmap (8x8 black and white pattern)
        testQRBitmap = Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888)
        for (x in 0 until 8) {
            for (y in 0 until 8) {
                val color = if ((x + y) % 2 == 0) Color.BLACK else Color.WHITE
                testQRBitmap.setPixel(x, y, color)
            }
        }
    }

    @Test
    fun `test applyBranding with default branding`() {
        val branding = QRBranding()
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 512)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 512, result.width)
        assertEquals("Should scale to target size", 512, result.height)
    }

    @Test
    fun `test applyBranding with custom color scheme`() {
        val customScheme = QRColorScheme(
            foregroundColor = Color.RED,
            backgroundColor = Color.BLUE
        )
        val branding = QRBranding(colorScheme = customScheme)
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 256)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 256, result.width)
        assertEquals("Should scale to target size", 256, result.height)
        
        // Check that colors were applied (sample pixels)
        val centerPixel = result.getPixel(128, 128)
        assertTrue("Should have applied custom colors", 
            centerPixel == Color.RED || centerPixel == Color.BLUE)
    }

    @Test
    fun `test applyBranding with logo`() {
        val logoBitmap = Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888)
        val logo = QRLogo(
            bitmap = logoBitmap,
            size = QRLogo.LogoSize.MEDIUM,
            position = QRLogo.LogoPosition.CENTER,
            style = QRLogo.LogoStyle.CIRCULAR
        )
        val branding = QRBranding(logo = logo)
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 400)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 400, result.width)
        assertEquals("Should scale to target size", 400, result.height)
    }

    @Test
    fun `test applyBranding with bank template`() {
        val branding = QRBranding(
            template = QRTemplate.Banking(BankTemplate.EQUITY)
        )
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 350)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 350, result.width)
        assertEquals("Should scale to target size", 350, result.height)
    }

    @Test
    fun `test QRColorScheme default values`() {
        val defaultScheme = QRColorScheme.default
        
        assertEquals("Default foreground should be black", Color.BLACK, defaultScheme.foregroundColor)
        assertEquals("Default background should be white", Color.WHITE, defaultScheme.backgroundColor)
        assertNull("Default finder pattern should be null", defaultScheme.finderPatternColor)
        assertNull("Default logo background should be null", defaultScheme.logoBackgroundColor)
    }

    @Test
    fun `test QRColorScheme equity bank preset`() {
        val equityScheme = QRColorScheme.equityBank
        
        assertEquals("Equity foreground should be black", Color.BLACK, equityScheme.foregroundColor)
        assertEquals("Equity background should be white", Color.WHITE, equityScheme.backgroundColor)
        assertEquals("Equity finder pattern should be red", Color.rgb(204, 0, 0), equityScheme.finderPatternColor)
        assertEquals("Equity logo background should be white", Color.WHITE, equityScheme.logoBackgroundColor)
    }

    @Test
    fun `test QRColorScheme kcb bank preset`() {
        val kcbScheme = QRColorScheme.kcbBank
        
        assertEquals("KCB foreground should be black", Color.BLACK, kcbScheme.foregroundColor)
        assertEquals("KCB background should be white", Color.WHITE, kcbScheme.backgroundColor)
        assertEquals("KCB finder pattern should be blue", Color.rgb(0, 102, 204), kcbScheme.finderPatternColor)
        assertEquals("KCB logo background should be white", Color.WHITE, kcbScheme.logoBackgroundColor)
    }

    @Test
    fun `test QRColorScheme standard chartered preset`() {
        val scScheme = QRColorScheme.standardChartered
        
        assertEquals("SC foreground should be black", Color.BLACK, scScheme.foregroundColor)
        assertEquals("SC background should be white", Color.WHITE, scScheme.backgroundColor)
        assertEquals("SC finder pattern should be blue", Color.rgb(0, 76, 153), scScheme.finderPatternColor)
        assertEquals("SC logo background should be white", Color.WHITE, scScheme.logoBackgroundColor)
    }

    @Test
    fun `test QRColorScheme cooperative bank preset`() {
        val coopScheme = QRColorScheme.cooperativeBank
        
        assertEquals("Coop foreground should be black", Color.BLACK, coopScheme.foregroundColor)
        assertEquals("Coop background should be white", Color.WHITE, coopScheme.backgroundColor)
        assertEquals("Coop finder pattern should be green", Color.rgb(0, 153, 76), coopScheme.finderPatternColor)
        assertEquals("Coop logo background should be white", Color.WHITE, coopScheme.logoBackgroundColor)
    }

    @Test
    fun `test BankTemplate enum values`() {
        assertEquals("EQUITY identifier", "EQ", BankTemplate.EQUITY.identifier)
        assertEquals("KCB identifier", "KCB", BankTemplate.KCB.identifier)
        assertEquals("STANDARD_CHARTERED identifier", "SC", BankTemplate.STANDARD_CHARTERED.identifier)
        assertEquals("COOPERATIVE identifier", "COOP", BankTemplate.COOPERATIVE.identifier)
    }

    @Test
    fun `test BankTemplate color schemes`() {
        assertEquals("EQUITY color scheme", QRColorScheme.equityBank, BankTemplate.EQUITY.colorScheme)
        assertEquals("KCB color scheme", QRColorScheme.kcbBank, BankTemplate.KCB.colorScheme)
        assertEquals("STANDARD_CHARTERED color scheme", QRColorScheme.standardChartered, BankTemplate.STANDARD_CHARTERED.colorScheme)
        assertEquals("COOPERATIVE color scheme", QRColorScheme.cooperativeBank, BankTemplate.COOPERATIVE.colorScheme)
    }

    @Test
    fun `test QRLogo size percentages`() {
        assertEquals("SMALL size percentage", 0.12f, QRLogo.LogoSize.SMALL.percentage, 0.001f)
        assertEquals("MEDIUM size percentage", 0.18f, QRLogo.LogoSize.MEDIUM.percentage, 0.001f)
        assertEquals("LARGE size percentage", 0.25f, QRLogo.LogoSize.LARGE.percentage, 0.001f)
    }

    @Test
    fun `test QRErrorCorrectionLevel values`() {
        assertEquals("LOW qr level", "L", QRErrorCorrectionLevel.LOW.qrLevel)
        assertEquals("MEDIUM qr level", "M", QRErrorCorrectionLevel.MEDIUM.qrLevel)
        assertEquals("QUARTILE qr level", "Q", QRErrorCorrectionLevel.QUARTILE.qrLevel)
        assertEquals("HIGH qr level", "H", QRErrorCorrectionLevel.HIGH.qrLevel)
    }

    @Test
    fun `test QRCodeStyle default values`() {
        val defaultStyle = QRCodeStyle()
        
        assertEquals("Default size", 512, defaultStyle.size)
        assertEquals("Default foreground color", Color.BLACK, defaultStyle.foregroundColor)
        assertEquals("Default background color", Color.WHITE, defaultStyle.backgroundColor)
        assertEquals("Default margin", 10, defaultStyle.margin)
        assertEquals("Default quiet zone", 4, defaultStyle.quietZone)
        assertEquals("Default corner radius", 0f, defaultStyle.cornerRadius, 0.001f)
        assertEquals("Default border width", 0, defaultStyle.borderWidth)
        assertNull("Default border color should be null", defaultStyle.borderColor)
    }

    @Test
    fun `test QRCodeStyle presets`() {
        val small = QRCodeStyle.small
        assertEquals("Small size", 200, small.size)
        assertEquals("Small margin", 8, small.margin)
        assertEquals("Small quiet zone", 3, small.quietZone)

        val medium = QRCodeStyle.medium
        assertEquals("Medium size", 400, medium.size)
        assertEquals("Medium margin", 15, medium.margin)
        assertEquals("Medium quiet zone", 6, medium.quietZone)

        val large = QRCodeStyle.large
        assertEquals("Large size", 600, large.size)
        assertEquals("Large margin", 20, large.margin)
        assertEquals("Large quiet zone", 8, large.quietZone)

        val print = QRCodeStyle.print
        assertEquals("Print size", 1200, print.size)
        assertEquals("Print margin", 40, print.margin)
        assertEquals("Print quiet zone", 16, print.quietZone)
    }

    @Test
    fun `test QRCodeStyle branded presets`() {
        val equityBrand = QRCodeStyle.equityBrand
        assertEquals("Equity brand size", 350, equityBrand.size)
        assertEquals("Equity brand corner radius", 12f, equityBrand.cornerRadius, 0.001f)
        assertEquals("Equity brand border width", 2, equityBrand.borderWidth)
        assertEquals("Equity brand border color", Color.rgb(204, 0, 0), equityBrand.borderColor)

        val banking = QRCodeStyle.banking
        assertEquals("Banking size", 380, banking.size)
        assertEquals("Banking corner radius", 8f, banking.cornerRadius, 0.001f)
        assertEquals("Banking border width", 1, banking.borderWidth)
        assertEquals("Banking border color", Color.BLUE, banking.borderColor)

        val retail = QRCodeStyle.retail
        assertEquals("Retail size", 320, retail.size)
        assertEquals("Retail corner radius", 6f, retail.cornerRadius, 0.001f)
        assertEquals("Retail border width", 2, retail.borderWidth)
        assertEquals("Retail border color", Color.rgb(255, 165, 0), retail.borderColor)
    }

    @Test
    fun `test QRBrandingError messages`() {
        val imageProcessingError = QRBrandingError.ImageProcessingFailed
        assertEquals("Image processing error message", "Failed to process QR image", imageProcessingError.message)

        val filterError = QRBrandingError.FilterNotAvailable
        assertEquals("Filter error message", "Required image filter not available", filterError.message)

        val colorError = QRBrandingError.ColorProcessingFailed
        assertEquals("Color processing error message", "Failed to apply color scheme", colorError.message)
    }

    @Test
    fun `test applyBranding with different target sizes`() {
        val branding = QRBranding()
        
        val size256 = brandingEngine.applyBranding(testQRBitmap, branding, 256)
        assertEquals("256x256 size", 256, size256.width)
        assertEquals("256x256 size", 256, size256.height)

        val size1024 = brandingEngine.applyBranding(testQRBitmap, branding, 1024)
        assertEquals("1024x1024 size", 1024, size1024.width)
        assertEquals("1024x1024 size", 1024, size1024.height)
    }

    @Test
    fun `test applyBranding with custom error correction level`() {
        val branding = QRBranding(
            errorCorrectionLevel = QRErrorCorrectionLevel.HIGH
        )
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 512)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 512, result.width)
        assertEquals("Should scale to target size", 512, result.height)
    }

    @Test
    fun `test applyBranding with brand identifier`() {
        val branding = QRBranding(
            brandIdentifier = "TEST_BRAND"
        )
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 512)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 512, result.width)
        assertEquals("Should scale to target size", 512, result.height)
    }

    @Test
    fun `test applyBranding with circular logo style`() {
        val logoBitmap = Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888)
        val logo = QRLogo(
            bitmap = logoBitmap,
            size = QRLogo.LogoSize.SMALL,
            style = QRLogo.LogoStyle.CIRCULAR
        )
        val branding = QRBranding(logo = logo)
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 400)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 400, result.width)
        assertEquals("Should scale to target size", 400, result.height)
    }

    @Test
    fun `test applyBranding with square logo style`() {
        val logoBitmap = Bitmap.createBitmap(32, 32, Bitmap.Config.ARGB_8888)
        val logo = QRLogo(
            bitmap = logoBitmap,
            size = QRLogo.LogoSize.LARGE,
            style = QRLogo.LogoStyle.SQUARE
        )
        val branding = QRBranding(logo = logo)
        val result = brandingEngine.applyBranding(testQRBitmap, branding, 400)
        
        assertNotNull("Result should not be null", result)
        assertEquals("Should scale to target size", 400, result.width)
        assertEquals("Should scale to target size", 400, result.height)
    }
} 