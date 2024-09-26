/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.util.Log

/**
 * Useful in suppressing warnings for unused parameters.
 */
const val UNUSED = "UNUSED_PARAMETER"

fun log(o: Any) {
    Log.i("LeafByte", o.toString())
}

fun log(o: Exception) {
    Log.e("LeafByte", Log.getStackTraceString(o))
}

fun checkState(
    condition: Boolean,
    message: String,
) {
    if (!condition) {
        throw IllegalStateException(message)
    }
}
