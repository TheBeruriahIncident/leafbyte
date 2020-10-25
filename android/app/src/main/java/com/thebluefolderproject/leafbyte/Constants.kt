package com.thebluefolderproject.leafbyte

import android.util.Log

/**
 * Useful in suppressing warnings for unused parameters.
 */
const val UNUSED = "UNUSED_PARAMETER"

fun debug(o: Any) {
    Log.e("ABIGAIL", o.toString())
}

fun checkState(condition: Boolean, message: String) {
    if (!condition) {
        throw IllegalStateException(message)
    }
}