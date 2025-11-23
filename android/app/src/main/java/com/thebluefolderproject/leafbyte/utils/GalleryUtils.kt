/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContract.SynchronousResult
import androidx.annotation.CallSuper

private const val IMAGE_MIME_TYPE = "image/*"

/**
 * Adapted from {@link androidx.activity.result.contract.ActivityResultContracts.GetContent}, but tweaked to be image specific and allow
 * error handling
 */
class GetGalleryImage : ActivityResultContract<Unit, Pair<Int, Uri?>>() {
    override fun createIntent(context: Context, input: Unit): Intent {
        return Intent(Intent.ACTION_GET_CONTENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType(IMAGE_MIME_TYPE)
    }

    override fun getSynchronousResult(
        context: Context,
        input: Unit,
    ): SynchronousResult<Pair<Int, Uri?>>? = null

    override fun parseResult(resultCode: Int, intent: Intent?): Pair<Int, Uri?> {
        return Pair(resultCode, intent?.data)
    }
}