package com.example.sampleapp.components

import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.text.style.TextAlign

@Composable
fun ErrorDialog(
    error: String?,
    onDismiss: () -> Unit,
    onRetry: (() -> Unit)? = null
) {
    if (error != null) {
        AlertDialog(
            onDismissRequest = onDismiss,
            title = {
                Text(
                    text = "Error",
                    style = MaterialTheme.typography.headlineSmall
                )
            },
            text = {
                Text(
                    text = error,
                    style = MaterialTheme.typography.bodyMedium,
                    textAlign = TextAlign.Start
                )
            },
            confirmButton = {
                TextButton(onClick = onDismiss) {
                    Text("OK")
                }
            },
            dismissButton = if (onRetry != null) {
                {
                    TextButton(onClick = onRetry) {
                        Text("Retry")
                    }
                }
            } else null
        )
    }
} 