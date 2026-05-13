/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.net.Uri
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.snapshots.SnapshotStateList
import com.thebluefolderproject.leafbyte.LeafByteNavKey

/**
 * This uses the new photo picker rather than the classic Intent.ACTION_GET_CONTENT so that we don't require any permissions. The tradeoff
 * is that the newer model doesn't expose any mechanism for error handling.
 */
@Composable
fun getGalleryLauncher(
    backStack: SnapshotStateList<Any>,
    releaseIntentLock: () -> Unit,
): ManagedActivityResultLauncher<PickVisualMediaRequest, Uri?> =
    rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { imageUri ->
        if (imageUri != null) {
            log("Successfully chose image: $imageUri")
            backStack.add(LeafByteNavKey.BackgroundRemovalScreen(originalImageUri = imageUri))
        } else {
            // PickVisualMedia ignores the specific result code, so we can't do proper error handling without forking it. As such, we have
            //   to assume that this is not an error
            log("Choosing an image did not succeed (presumably, it was canceled)")
        }
        releaseIntentLock()
    }

fun getGalleryLauncherInput() = PickVisualMediaRequest(mediaType = ActivityResultContracts.PickVisualMedia.ImageOnly)
