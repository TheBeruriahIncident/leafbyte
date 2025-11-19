@file:Suppress("all")
/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.activity

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import com.thebluefolderproject.leafbyte.activity.ui.theme.AndroidTheme
import com.thebluefolderproject.leafbyte.utils.isGoogleSignInConfigured
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.logError
import org.opencv.android.OpenCVLoader

class LeafByteActivity2 : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        log("onCreate")

        if (!OpenCVLoader.initDebug()) {
            throw RuntimeException("Failed to initialize OpenCV")
        }

        if (isGoogleSignInConfigured()) {
            log("Google Sign-In is configured")
        } else {
            logError(
                "************************************************************\n" +
                    "STOP! Please fill in the secrets.properties file! Google Sign-In is not configured and WILL NOT WORK!\n" +
                    "************************************************************",
            )
        }

        enableEdgeToEdge()
        setContent {
            AndroidTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    NavigationRoot(
                        modifier =
                            Modifier
                                .fillMaxSize()
                                .padding(innerPadding),
                    )
                }
            }
        }
    }
}
