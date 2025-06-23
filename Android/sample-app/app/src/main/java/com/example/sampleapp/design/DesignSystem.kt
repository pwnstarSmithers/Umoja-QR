package com.example.sampleapp.design

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

// MARK: - Main Design System (iOS-style Dark Theme)
object AppDesignSystem {
    object Colors {
        // Primary colors (iOS Dark Theme)
        val background = Color(0xFF000000)           // True black background
        val surface = Color(0xFF1C1C1E)              // Dark gray cards
        val surfaceVariant = Color(0xFF2C2C2E)       // Lighter gray for inputs
        val primary = Color(0xFF007AFF)              // iOS Blue
        val success = Color(0xFF30D158)              // iOS Green
        val warning = Color(0xFFFF9F0A)              // iOS Orange
        val error = Color(0xFFFF453A)                // iOS Red
        val onBackground = Color(0xFFFFFFFF)         // White text
        val onSurface = Color(0xFFFFFFFF)            // White text on cards
        val secondary = Color(0xFF8E8E93)            // Gray text
        
        // Bank brand colors
        val equity = Color(0xFFDC143C)               // Equity red
        val kcb = Color(0xFF0066CC)                  // KCB blue  
        val coop = Color(0xFF228B22)                 // Co-op green
        val tanzania = Color(0xFFFF8C00)             // Tanzania orange
        
        // Additional semantic colors
        val info = Color(0xFF5AC8FA)                 // iOS Light Blue
        val disabled = Color(0xFF3A3A3C)             // Disabled state
        val separator = Color(0xFF38383A)            // Separator lines
    }
    
    object Typography {
        val largeTitle = TextStyle(
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Colors.onBackground
        )
        val title = TextStyle(
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            color = Colors.onBackground
        )
        val headline = TextStyle(
            fontSize = 17.sp,
            fontWeight = FontWeight.Medium,
            color = Colors.onBackground
        )
        val body = TextStyle(
            fontSize = 15.sp,
            fontWeight = FontWeight.Normal,
            color = Colors.onBackground
        )
        val caption = TextStyle(
            fontSize = 13.sp,
            fontWeight = FontWeight.Normal,
            color = Colors.secondary
        )
        val footnote = TextStyle(
            fontSize = 12.sp,
            fontWeight = FontWeight.Normal,
            color = Colors.secondary
        )
    }
    
    object Spacing {
        val xs: Dp = 2.dp
        val sm: Dp = 4.dp
        val md: Dp = 8.dp
        val lg: Dp = 12.dp
        val xl: Dp = 16.dp
        val xxl: Dp = 20.dp
        val xxxl: Dp = 24.dp
    }
    
    object CornerRadius {
        val xs: Dp = 4.dp
        val sm: Dp = 8.dp
        val md: Dp = 12.dp
        val lg: Dp = 16.dp
        val xl: Dp = 20.dp
    }
}

// MARK: - Reusable UI Components

@Composable
fun AppCard(
    modifier: Modifier = Modifier,
    backgroundColor: Color = AppDesignSystem.Colors.surface,
    cornerRadius: Dp = AppDesignSystem.CornerRadius.lg,
    content: @Composable ColumnScope.() -> Unit
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        shape = RoundedCornerShape(cornerRadius),
        content = content
    )
}

@Composable
fun SelectionChip(
    text: String,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    selectedColor: Color = AppDesignSystem.Colors.primary,
    unselectedColor: Color = AppDesignSystem.Colors.surfaceVariant
) {
    Surface(
        modifier = modifier.clickable { onClick() },
        color = if (isSelected) selectedColor.copy(alpha = 0.2f) else unselectedColor,
        shape = RoundedCornerShape(AppDesignSystem.CornerRadius.sm),
        border = if (isSelected) BorderStroke(1.dp, selectedColor) else null
    ) {
        Text(
            text = text,
            style = AppDesignSystem.Typography.body.copy(
                color = if (isSelected) selectedColor else AppDesignSystem.Colors.onSurface,
                fontWeight = if (isSelected) FontWeight.Medium else FontWeight.Normal
            ),
            modifier = Modifier.padding(
                horizontal = AppDesignSystem.Spacing.lg,
                vertical = AppDesignSystem.Spacing.md
            ),
            textAlign = TextAlign.Center
        )
    }
}

@Composable
fun DetailChip(
    text: String,
    color: Color,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        color = color.copy(alpha = 0.2f),
        shape = RoundedCornerShape(AppDesignSystem.CornerRadius.sm)
    ) {
        Text(
            text = text,
            style = AppDesignSystem.Typography.caption.copy(
                color = color,
                fontWeight = FontWeight.Medium
            ),
            modifier = Modifier.padding(
                horizontal = AppDesignSystem.Spacing.md,
                vertical = AppDesignSystem.Spacing.sm
            )
        )
    }
}

@Composable
fun AppInputField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    leadingIcon: ImageVector,
    modifier: Modifier = Modifier
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        placeholder = {
            Text(
                text = placeholder,
                style = AppDesignSystem.Typography.body.copy(color = AppDesignSystem.Colors.secondary)
            )
        },
        leadingIcon = {
            Icon(
                imageVector = leadingIcon,
                contentDescription = null,
                tint = AppDesignSystem.Colors.secondary,
                modifier = Modifier.size(20.dp)
            )
        },
        modifier = modifier.fillMaxWidth(),
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = AppDesignSystem.Colors.primary,
            unfocusedBorderColor = AppDesignSystem.Colors.separator,
            focusedTextColor = AppDesignSystem.Colors.onSurface,
            unfocusedTextColor = AppDesignSystem.Colors.onSurface,
            cursorColor = AppDesignSystem.Colors.primary
        ),
        shape = RoundedCornerShape(AppDesignSystem.CornerRadius.md),
        textStyle = AppDesignSystem.Typography.body
    )
}

@Composable
fun AppPrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    backgroundColor: Color = AppDesignSystem.Colors.primary,
    contentColor: Color = Color.White
) {
    Button(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.buttonColors(
            containerColor = backgroundColor,
            contentColor = contentColor
        ),
        shape = RoundedCornerShape(AppDesignSystem.CornerRadius.md)
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(AppDesignSystem.Spacing.md))
        }
        Text(
            text = text,
            style = AppDesignSystem.Typography.body.copy(fontWeight = FontWeight.Medium)
        )
    }
}

@Composable
fun AppOutlinedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    icon: ImageVector? = null,
    borderColor: Color = AppDesignSystem.Colors.primary,
    contentColor: Color = AppDesignSystem.Colors.primary
) {
    OutlinedButton(
        onClick = onClick,
        modifier = modifier,
        colors = ButtonDefaults.outlinedButtonColors(
            contentColor = contentColor
        ),
        border = BorderStroke(1.dp, borderColor.copy(alpha = 0.5f)),
        shape = RoundedCornerShape(AppDesignSystem.CornerRadius.md)
    ) {
        if (icon != null) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(16.dp)
            )
            Spacer(modifier = Modifier.width(AppDesignSystem.Spacing.md))
        }
        Text(
            text = text,
            style = AppDesignSystem.Typography.body.copy(fontWeight = FontWeight.Medium)
        )
    }
}

@Composable
fun DetailRow(
    label: String,
    value: String,
    icon: ImageVector,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(AppDesignSystem.Spacing.md)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = AppDesignSystem.Colors.secondary,
                modifier = Modifier.size(16.dp)
            )
            Text(
                text = label,
                style = AppDesignSystem.Typography.body.copy(color = AppDesignSystem.Colors.secondary)
            )
        }
        Text(
            text = value,
            style = AppDesignSystem.Typography.body.copy(fontWeight = FontWeight.Medium)
        )
    }
}

@Composable
fun SectionLabel(
    text: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = text,
        style = AppDesignSystem.Typography.body.copy(color = AppDesignSystem.Colors.secondary),
        modifier = modifier.padding(bottom = AppDesignSystem.Spacing.sm)
    )
}

// MARK: - Detail Design System (iOS-style Light Theme)
object DetailDesignSystem {
    object Colors {
        val primary = Color(0xFF007AFF)
        val secondary = Color(0xFF8E8E93)
        val success = Color(0xFF34C759)
        val warning = Color(0xFFFF9500)
        val error = Color(0xFFFF3B30)
        val info = Color(0xFF5AC8FA)
        
        // Bank colors
        val equity = Color(0xFFCC0000)
        val kcb = Color(0xFF007AFF)
        val coop = Color(0xFF34C759)
        val tanzania = Color(0xFFFF9500)
        
        // UI colors (Light Theme)
        val background = Color(0xFFF2F2F7)
        val surface = Color(0xFFFFFFFF)
        val surfaceVariant = Color(0xFFF2F2F7)
        val onSurface = Color(0xFF000000)
        val onSurfaceVariant = Color(0xFF8E8E93)
    }
    
    object Typography {
        val largeTitle = TextStyle(
            fontSize = 34.sp,
            fontWeight = FontWeight.Bold
        )
        val title = TextStyle(
            fontSize = 22.sp,
            fontWeight = FontWeight.SemiBold
        )
        val headline = TextStyle(
            fontSize = 17.sp,
            fontWeight = FontWeight.Medium
        )
        val body = TextStyle(
            fontSize = 17.sp
        )
        val callout = TextStyle(
            fontSize = 16.sp
        )
        val caption = TextStyle(
            fontSize = 12.sp
        )
        val footnote = TextStyle(
            fontSize = 13.sp
        )
    }
    
    object Spacing {
        val xs: Dp = 4.dp
        val sm: Dp = 8.dp
        val md: Dp = 16.dp
        val lg: Dp = 24.dp
        val xl: Dp = 32.dp
        val xxl: Dp = 48.dp
    }
    
    object CornerRadius {
        val sm: Dp = 8.dp
        val md: Dp = 12.dp
        val lg: Dp = 16.dp
        val xl: Dp = 20.dp
    }
}

// MARK: - Theme Color Schemes

/**
 * Creates a dark color scheme using AppDesignSystem colors
 */
fun createDarkColorScheme(): androidx.compose.material3.ColorScheme {
    return androidx.compose.material3.darkColorScheme(
        primary = AppDesignSystem.Colors.primary,
        background = AppDesignSystem.Colors.background,
        surface = AppDesignSystem.Colors.surface,
        onBackground = AppDesignSystem.Colors.onBackground,
        onSurface = AppDesignSystem.Colors.onSurface,
        secondary = AppDesignSystem.Colors.secondary,
        error = AppDesignSystem.Colors.error,
        onPrimary = Color.White,
        onSecondary = AppDesignSystem.Colors.onSurface,
        onError = Color.White,
        surfaceVariant = AppDesignSystem.Colors.surfaceVariant,
        onSurfaceVariant = AppDesignSystem.Colors.onSurface
    )
}

/**
 * Creates a light color scheme using DetailDesignSystem colors
 */
fun createLightColorScheme(): androidx.compose.material3.ColorScheme {
    return androidx.compose.material3.lightColorScheme(
        primary = DetailDesignSystem.Colors.primary,
        background = DetailDesignSystem.Colors.background,
        surface = DetailDesignSystem.Colors.surface,
        onBackground = DetailDesignSystem.Colors.onSurface,
        onSurface = DetailDesignSystem.Colors.onSurface,
        secondary = DetailDesignSystem.Colors.secondary,
        error = DetailDesignSystem.Colors.error,
        onPrimary = Color.White,
        onSecondary = DetailDesignSystem.Colors.onSurface,
        onError = Color.White,
        surfaceVariant = DetailDesignSystem.Colors.surfaceVariant,
        onSurfaceVariant = DetailDesignSystem.Colors.onSurfaceVariant
    )
}

// Legacy compatibility object
@Deprecated("Use AppDesignSystem instead", ReplaceWith("AppDesignSystem"))
object DesignSystem {
    object Colors {
        val primary = Color(0xFF007AFF) // SF Blue
        val secondary = Color(0xFF8F8F99) // SF Gray
        val success = Color(0xFF33C759) // SF Green
        val warning = Color(0xFFFF9500) // SF Orange
        val error = Color(0xFFFF3B30) // SF Red

        // Semantic colors
        val background = Color(0xFFFFFFFF)
        val secondaryBackground = Color(0xFFF2F2F7)
        val tertiaryBackground = Color(0xFFE5E5EA)
        val label = Color(0xFF000000)
        val secondaryLabel = Color(0xFF3C3C43)
        val separator = Color(0xFFC6C6C8)

        // Bank colors
        val equity = Color(0xFFCC0000)
        val kcb = Color(0xFF007AFF)
        val coop = Color(0xFF33C759)
        val tanzania = Color(0xFFFF9500)
    }

    object Typography {
        val largeTitle = TextStyle(fontSize = 34.sp, fontWeight = FontWeight.Bold)
        val title = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.SemiBold)
        val headline = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.Medium)
        val body = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.Normal)
        val caption = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Normal)
        val footnote = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Normal)
    }

    object Spacing {
        val xs: Dp = 4.dp
        val sm: Dp = 8.dp
        val md: Dp = 16.dp
        val lg: Dp = 24.dp
        val xl: Dp = 32.dp
        val xxl: Dp = 48.dp
    }

    object CornerRadius {
        val sm: Dp = 8.dp
        val md: Dp = 12.dp
        val lg: Dp = 16.dp
        val xl: Dp = 20.dp
    }
} 