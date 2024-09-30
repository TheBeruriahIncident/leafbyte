/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

/**
 * Useful in suppressing warnings for unused parameters.
 */
const val UNUSED = "UNUSED_PARAMETER"
private const val LOG_TAG = "BlueFolder"

fun log(o: Any) {
    Log.i(LOG_TAG, o.toString())
}

fun log(o: Exception) {
    Log.e(LOG_TAG, Log.getStackTraceString(o))
}

fun checkState(
    condition: Boolean,
    message: String,
) {
    if (!condition) {
        throw IllegalStateException(message)
    }
}

fun <T> Flow<T>.load(): T {
    val flow = this
    return runBlocking { flow.first() }
}

@Composable
fun <T> Flow<T>.compose(): T {
    val initialValue = remember { load() }
    val state = collectAsStateWithLifecycle(initialValue)
    // It may seem silly that we bother to make a state and immediately unwrap the state, but that's actually critical for the Compose
    //   compiler to recognize that this value can change and recompose appropriately
    return state.value
}
