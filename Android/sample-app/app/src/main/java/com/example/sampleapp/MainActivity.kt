package com.example.sampleapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.sampleapp.design.createDarkColorScheme

@OptIn(ExperimentalMaterial3Api::class)
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            MaterialTheme(
                colorScheme = createDarkColorScheme()
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    
                    AppNavigation(
                        navController = navController
                    )
                }
            }
        }
    }
}

@Composable
fun AppNavigation(
    navController: NavHostController,
    modifier: Modifier = Modifier
) {
    NavHost(
        navController = navController,
        startDestination = "home",
        modifier = modifier
    ) {
        composable("home") {
            QRBrandingScreen(
                onNavigateToScanner = { navController.navigate("scanner") }
            )
        }
        composable("scanner") {
            QRScannerScreen(
                onResult = { qrData ->
                    // Navigate to QR details screen with the scanned data
                    navController.navigate("qr_details/${java.net.URLEncoder.encode(qrData, "UTF-8")}")
                },
                onBack = { navController.popBackStack() }
            )
        }
        composable("qr_details/{qrData}") { backStackEntry ->
            val qrData = backStackEntry.arguments?.getString("qrData")?.let {
                java.net.URLDecoder.decode(it, "UTF-8")
            } ?: ""
            
            QRDetailsScreen(
                qrData = qrData,
                onBack = { navController.popBackStack() }
            )
        }
    }
}

 