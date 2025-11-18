/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.activity

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModelProviders
import androidx.navigation.NavOptions
import androidx.navigation.findNavController
import androidx.preference.PreferenceManager
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.ui.theme.AndroidTheme
import com.thebluefolderproject.leafbyte.fragment.BackgroundRemovalFragment
import com.thebluefolderproject.leafbyte.fragment.MainMenuFragment
import com.thebluefolderproject.leafbyte.fragment.ResultsFragment
import com.thebluefolderproject.leafbyte.fragment.ScaleIdentificationFragment
import com.thebluefolderproject.leafbyte.fragment.TutorialFragment
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.utils.log
import org.opencv.android.OpenCVLoader

class LeafByteActivity2 : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        log("onCreate")

        if (!OpenCVLoader.initDebug()) {
            throw RuntimeException("Failed to initialize OpenCV")
        }

        enableEdgeToEdge()
        setContent {
            AndroidTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    NavigationRoot(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(innerPadding)
                    )
                }
            }
        }
    }
}