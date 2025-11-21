package com.thebluefolderproject.leafbyte.utils

import android.content.ContentResolver
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalResources

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
