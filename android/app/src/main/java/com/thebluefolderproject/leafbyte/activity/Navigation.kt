/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

@file:Suppress("all")

package com.thebluefolderproject.leafbyte.activity

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.net.toUri
import androidx.navigation3.runtime.NavEntry
import androidx.navigation3.runtime.NavKey
import androidx.navigation3.ui.NavDisplay
import com.thebluefolderproject.leafbyte.compose.NavigationAwareTutorialScreen
import com.thebluefolderproject.leafbyte.fragment.BackgroundRemovalScreen
import com.thebluefolderproject.leafbyte.compose.MainMenuScreen
import com.thebluefolderproject.leafbyte.fragment.ResultsScreen
import com.thebluefolderproject.leafbyte.fragment.ScaleIdentificationScreen
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen2
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.log
import kotlinx.serialization.Serializable

sealed interface LeafByteNavKey : NavKey {
    @Serializable
    data object MainScreen : LeafByteNavKey
    @Serializable
    data object SettingsScreen : LeafByteNavKey
    @Serializable
    data object Tutorial : LeafByteNavKey
    @Serializable
    data class BackgroundRemovalScreen(
        val originalImageUri: Uri,
    ) : LeafByteNavKey
    @Serializable
    data class ScaleIdentificationScreen(
        val thresholdedImageUri: Uri,
    ) : LeafByteNavKey
    @Serializable
    data class ResultsScreen(
        val thresholdedImageUri: Uri,
        val scaleMarks: List<Point>,
    ) : LeafByteNavKey
}

@Composable
fun LeafByteNavigation(
    modifier: Modifier = Modifier,
    injectedSettings: Settings? = null,
    injectedGoogleSignInManager: GoogleSignInManager? = null,
) {
    val backStack = remember { mutableStateListOf<Any>(LeafByteNavKey.MainScreen) }
    val context = LocalContext.current

    NavDisplay(
        modifier = modifier,
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = { key ->
            when (key) {
                is LeafByteNavKey.MainScreen ->
                    NavEntry(key) {
                        MainMenuScreen(
                            openSettings = { backStack.add(LeafByteNavKey.SettingsScreen) },
                            startTutorial = { backStack.add(LeafByteNavKey.Tutorial) },
                        )
                    }

                is LeafByteNavKey.SettingsScreen ->
                    NavEntry(key) {
                        SettingsScreen2(injectedSettings = injectedSettings, injectedGoogleSignInManager = injectedGoogleSignInManager)
                    }

                is LeafByteNavKey.Tutorial -> NavEntry(key) { NavigationAwareTutorialScreen(backStack = backStack) }
                is LeafByteNavKey.BackgroundRemovalScreen ->
                    NavEntry(key) {
                        BackgroundRemovalScreen(
                            originalImage = loadUri(key.originalImageUri, context = context),
                            onPressingNext = { thresholdedImage ->
                                val uri = saveCurrentThresholdedImage(context = context, bitmap = thresholdedImage)
                                backStack.add(LeafByteNavKey.ScaleIdentificationScreen(uri))
                            },
                        )
                    }
                is LeafByteNavKey.ScaleIdentificationScreen ->
                    NavEntry(key) {
                        ScaleIdentificationScreen(
                            loadUri(context = context, uri = key.thresholdedImageUri),
                            { scaleMarks ->
                                backStack.add(
                                    LeafByteNavKey.ResultsScreen(thresholdedImageUri = key.thresholdedImageUri, scaleMarks = scaleMarks),
                                )
                            },
                        )
                    }
                is LeafByteNavKey.ResultsScreen ->
                    NavEntry(key) {
                        ResultsScreen(loadUri(context = context, uri = key.thresholdedImageUri), { })
                    }

                else ->
                    NavEntry(Unit) {
                        log("Unknown route $key")
                        Text("Unknown route")
                    }
            }
        },
    )
}

// from https://stackoverflow.com/questions/3879992/how-to-get-bitmap-from-an-uri , TODO, worker thread?
fun loadUri(
    uri: Uri,
    context: Context,
): Bitmap =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        // ImageDecoder.decodeBitmap(ImageDecoder.createSource(context.contentResolver, uri))
// TODO https://stackoverflow.com/questions/60462841/java-lang-illegalstateexception-unable-to-getpixels-pixel-access-is-not-supp
        ImageDecoder.decodeBitmap(
            ImageDecoder.createSource(context.contentResolver, uri),
            ImageDecoder.OnHeaderDecodedListener { decoder, info, source ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                decoder.isMutableRequired = true
            },
        )
    } else {
        MediaStore.Images.Media.getBitmap(context.contentResolver, uri)
    }

// TODO: see if this is slow and if we need an in-memory version of the image that falls back to the file
private const val ORIGINAL_IMAGE_PATH = "current_image.bmp"
fun getCurrentOriginalImage(context: Context): Bitmap = getImage(context, ORIGINAL_IMAGE_PATH)

private const val THRESHOLDED_IMAGE_PATH = "current_image.bmp"
fun getCurrentThresholdedImage(context: Context): Bitmap = getImage(context, THRESHOLDED_IMAGE_PATH)

fun saveCurrentOriginalImage(
    context: Context,
    bitmap: Bitmap,
): Uri = saveImage(context, ORIGINAL_IMAGE_PATH, bitmap)

fun saveCurrentThresholdedImage(
    context: Context,
    bitmap: Bitmap,
): Uri = saveImage(context, THRESHOLDED_IMAGE_PATH, bitmap)

private fun saveImage(
    context: Context,
    path: String,
    bitmap: Bitmap,
): Uri {
    // TODO: resize here and elsewhere

    val file = context.filesDir.resolve(path)
    file.outputStream().use {
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
    }

    return file.toUri()
}

private fun getImage(
    context: Context,
    path: String,
): Bitmap {
    val file = context.filesDir.resolve(path)
    return BitmapFactory.decodeFile(file.canonicalPath)
}
