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
import com.thebluefolderproject.leafbyte.compose.AlertType
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
    setAlert: (AlertType) -> Unit,
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
                    setAlert(AlertType.FAILED_TO_TAKE_PHOTO)
                }
            }
        },
    )

/**
 * Adapted from {@link androidx.activity.result.contract.ActivityResultContracts.TakePicture}, but tweaked to allow error handling
 */
private class TakePhotoContract : ActivityResultContract<Uri, Int>() {
    override fun createIntent(
        context: Context,
        input: Uri,
    ): Intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, input)

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
    checkNotNull(externalFilesDir != null) { "External files directory is null; shared storage is not currently available" }

    val cameraPhotoFile = File(externalFilesDir, CAMERA_PHOTO_PATH)
    cameraPhotoFile.createNewFile() // ensures it's created, without crashing if it already exists

    return FileProvider.getUriForFile(
        context,
        context.getString(R.string.file_provider_authority),
        cameraPhotoFile,
    )
}
