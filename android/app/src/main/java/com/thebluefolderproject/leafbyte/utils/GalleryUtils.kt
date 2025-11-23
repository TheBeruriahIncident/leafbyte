/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.Composable
import androidx.compose.runtime.snapshots.SnapshotStateList
import com.thebluefolderproject.leafbyte.activity.LeafByteNavKey
import com.thebluefolderproject.leafbyte.compose.MainMenuAlertType

@Composable
fun getGalleryLauncher(
    backStack: SnapshotStateList<Any>,
    setAlert: (MainMenuAlertType) -> Unit,
    releaseIntentLock: () -> Unit,
): ManagedActivityResultLauncher<Unit, Pair<Int, Uri?>> =
    rememberLauncherForActivityResult(
        contract = GetGalleryImageContract(),
        onResult = { (resultCode, imageUri) ->
            when (resultCode) {
                Activity.RESULT_OK -> {
                    log("Successfully chose image: $imageUri")
                    if (imageUri != null) {
                        backStack.add(LeafByteNavKey.BackgroundRemovalScreen(originalImageUri = imageUri))
                    } else {
                        // This case is currently only theoretical
                        logError("Despite an OK result code, no image uri was returned from gallery")
                        setAlert(MainMenuAlertType.FAILED_TO_CHOOSE_IMAGE_FROM_GALLERY)
                    }
                }
                Activity.RESULT_CANCELED -> {
                    log("Choosing an image was canceled")
                    // This is not an error, we just return to where we were
                }
                // We should make more specific errors as we learn what error codes are possible
                else -> {
                    logError("Failed to choose image: $resultCode")
                    setAlert(MainMenuAlertType.FAILED_TO_CHOOSE_IMAGE_FROM_GALLERY)
                }
            }
            releaseIntentLock()
        },
    )

private const val IMAGE_MIME_TYPE = "image/*"

/**
 * Adapted from {@link androidx.activity.result.contract.ActivityResultContracts.GetContent}, but tweaked to be image specific and allow
 * error handling
 */
private class GetGalleryImageContract : ActivityResultContract<Unit, Pair<Int, Uri?>>() {
    override fun createIntent(
        context: Context,
        input: Unit,
    ): Intent =
        Intent(Intent.ACTION_GET_CONTENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(IMAGE_MIME_TYPE)

    override fun getSynchronousResult(
        context: Context,
        input: Unit,
    ): SynchronousResult<Pair<Int, Uri?>>? = null

    override fun parseResult(
        resultCode: Int,
        intent: Intent?,
    ): Pair<Int, Uri?> = Pair(resultCode, intent?.data)
}
