/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContract.SynchronousResult
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.FileProvider
import com.thebluefolderproject.leafbyte.R
import java.io.File

@Composable
fun hasCamera(): Boolean {
    val packageManager = LocalContext.current.packageManager
    return remember { packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) }
}

/**
 * Adapted from {@link androidx.activity.result.contract.ActivityResultContracts.TakePicture}, but tweaked to allow error handling
 */
class TakePhoto : ActivityResultContract<Uri, Int>() {
    override fun createIntent(context: Context, input: Uri): Intent {
        return Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, input)
    }

    override fun getSynchronousResult(
        context: Context,
        input: Uri,
    ): SynchronousResult<Int>? = null

    override fun parseResult(resultCode: Int, intent: Intent?): Int {
        return resultCode
    }
}

private const val CAMERA_PHOTO_PATH = "most_recent_photo_taken_by_user.jpg"
fun getCameraPhotoUri(context: Context): Uri {
    val externalFilesDir = context.getExternalFilesDir(null)
    check(externalFilesDir != null, { "External files directory is null; shared storage is not currently available" })

    val cameraPhotoFile = File(externalFilesDir, CAMERA_PHOTO_PATH)
    cameraPhotoFile.createNewFile() // ensures it's created, without crashing if it already exists

    return FileProvider.getUriForFile(
        context,
        context.getString(R.string.file_provider_authority),
        cameraPhotoFile,
    )
}
