/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.content.ContentResolver
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalResources
import java.util.Locale

@Composable
fun resourceToUri(resourceId: Int): Uri {
    val resources = LocalResources.current
    val packageName = resources.getResourcePackageName(resourceId)
    val typeName = resources.getResourceTypeName(resourceId)
    val entryName = resources.getResourceEntryName(resourceId)

    return Uri
        .Builder()
        .scheme(ContentResolver.SCHEME_ANDROID_RESOURCE)
        .authority(packageName)
        .appendPath(typeName)
        .appendPath(entryName)
        .build()
}

@Composable
fun getRememberedLocale(): Locale {
    val locale =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            LocalConfiguration.current.locales[0]
        } else {
            @Suppress("DEPRECATION")
            LocalConfiguration.current.locale
        }

    log("Using locale $locale")
    return remember { locale }
}
