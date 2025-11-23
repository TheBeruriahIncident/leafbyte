/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.FileProvider
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.LeafByteNavKey
import com.thebluefolderproject.leafbyte.compose.MainMenuAlertType
import java.io.File

@Composable
fun hasCamera(): Boolean {
    val packageManager = LocalContext.current.packageManager
    return remember { packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) }
}

@Composable
fun getCameraLauncher(
    cameraPhotoUri: Uri,
    backStack: SnapshotStateList<Any>,
    setAlert: (MainMenuAlertType) -> Unit,
    releaseIntentLock: () -> Unit,
): ManagedActivityResultLauncher<Uri, Int> =
    rememberLauncherForActivityResult(
        contract = TakePhotoContract(),
        onResult = { resultCode ->
            when (resultCode) {
                Activity.RESULT_OK -> {
                    log("Successfully took photo: $cameraPhotoUri")
                    backStack.add(LeafByteNavKey.BackgroundRemovalScreen(originalImageUri = cameraPhotoUri))
                }
                Activity.RESULT_CANCELED -> {
                    log("Taking a photo was canceled")
                    // This is not an error, we just return to the main menu
                }
                // We should make more specific errors as we learn what error codes are possible
                else -> {
                    logError("Failed to take photo: $resultCode")
                    setAlert(MainMenuAlertType.FAILED_TO_TAKE_PHOTO)
                }
            }
            releaseIntentLock()
        },
    )

private val ALTERNATE_CAMERA_CANDIDATES =
    listOf(
        "net.sourceforge.opencamera",
    )

/**
 * Adapted from {@link androidx.activity.result.contract.ActivityResultContracts.TakePicture}, but tweaked to allow error handling
 *
 * Note that ACTION_IMAGE_CAPTURE is considered generally janky and bad. However, the only reasonable option is writing our own whole screen
 * that runs the camera using camera APIs directly. We're avoiding that until we have strong reason to invest that effort.
 * (see https://commonsware.com/blog/2015/06/08/action-image-capture-fallacy.html for some of the issues)
 *
 * Note also that if we ever request the camera permission, then the following would counterintuitively start requiring the camera
 * permission: https://www.egorand.dev/taking-photos-not-so-simply-how-i-got-bitten-by-action-image-capture/
 */
private class TakePhotoContract : ActivityResultContract<Uri, Int>() {
    override fun createIntent(
        context: Context,
        input: Uri,
    ): Intent {
        val baseIntent =
            Intent(MediaStore.ACTION_IMAGE_CAPTURE)
                .putExtra(MediaStore.EXTRA_OUTPUT, input)

        // Per https://commonsware.com/blog/2020/08/16/action-image-capture-android-r.html , we try to make this a little more likely to
        //   succeed if the user has a non-default camera
        val additionalCameraIntents = getAdditionalCameraIntent(context = context, baseIntent = baseIntent)
        if (additionalCameraIntents.isEmpty()) {
            return baseIntent
        } else {
            return Intent
                .createChooser(baseIntent, null)
                .putExtra(Intent.EXTRA_INITIAL_INTENTS, additionalCameraIntents)
        }
    }

    private fun getAdditionalCameraIntent(
        context: Context,
        baseIntent: Intent,
    ): Array<Intent> =
        ALTERNATE_CAMERA_CANDIDATES
            .map { Intent(baseIntent).setPackage(it) }
            .filter { context.packageManager.queryIntentActivities(it, 0).isNotEmpty() }
            .toTypedArray()

    override fun getSynchronousResult(
        context: Context,
        input: Uri,
    ): SynchronousResult<Int>? = null

    override fun parseResult(
        resultCode: Int,
        intent: Intent?,
    ): Int = resultCode
}

private const val CAMERA_PHOTO_PATH = "most_recent_photo_taken_by_user.jpg"
fun getCameraPhotoUri(context: Context): Uri {
    val externalFilesDir = context.getExternalFilesDir(null)
    checkNotNull(externalFilesDir) { "External files directory is null; shared storage is not currently available" }

    val cameraPhotoFile = File(externalFilesDir, CAMERA_PHOTO_PATH)
    cameraPhotoFile.createNewFile() // ensures it's created, without crashing if it already exists

    return FileProvider.getUriForFile(
        context,
        context.getString(R.string.file_provider_authority),
        cameraPhotoFile,
    )
}
