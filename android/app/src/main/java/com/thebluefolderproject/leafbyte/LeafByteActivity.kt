/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import com.thebluefolderproject.leafbyte.activity.LeafByteNavigation
import com.thebluefolderproject.leafbyte.activity.ui.theme.LeafByteTheme
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.getCameraPhotoUri
import com.thebluefolderproject.leafbyte.utils.isGoogleSignInConfigured
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.logError
import org.opencv.android.OpenCVLoader

class LeafByteActivity : ComponentActivity() {
    @Suppress("detekt:exceptions:TooGenericExceptionCaught") // being defensive for all ways startup could fail
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        log("Initializing LeafByteActivity")

        if (!OpenCVLoader.initDebug()) {
            logError("Failed to initialize OpenCV")
            return setContent {
                Text(
                    modifier = Modifier.fillMaxSize(),
                    textAlign = TextAlign.Center,
                    text =
                        "\n\n\n" +
                            "LeafByte failed to initialize OpenCV. Please report this crash to leafbyte@zoegp.science so we can fix it.",
                )
            }
        }
        log("Initialized OpenCV")

        try {
            getCameraPhotoUri(context = applicationContext)
        } catch (exception: RuntimeException) {
            logError("Failed to initialize uri for taking photos", exception)
            return setContent {
                Text(
                    modifier = Modifier.fillMaxSize(),
                    textAlign = TextAlign.Center,
                    text =
                        "\n\n\n" +
                            "LeafByte failed to access storage. Is your storage full, or is there some other explanation? Please report " +
                            "this crash to leafbyte@zoegp.science so we can fix it.",
                )
            }
        }
        log("Initialized uri for taking photos")

        if (isGoogleSignInConfigured()) {
            log("Google Sign-In is configured")
        } else {
            logError(
                "************************************************************\n" +
                    "STOP! Please fill in the secrets.properties file! Google Sign-In is not configured and WILL NOT WORK!\n" +
                    "************************************************************",
            )
        }

        setContent {
            LeafByteTheme {
                LeafByteNavigation()
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Changing the theme doesn't recreate the activity, so set the edge-to-edge values again
        enableEdgeToEdge()
    }
}
