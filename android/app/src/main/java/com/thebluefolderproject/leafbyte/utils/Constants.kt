/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.os.Build
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.time.Instant
import java.util.concurrent.TimeUnit

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

interface Clock {
    fun getEpochTimeInSeconds(): Long
}

class SystemClock : Clock {
    override fun getEpochTimeInSeconds(): Long {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            return Instant.now().epochSecond
        } else {
            return TimeUnit.MILLISECONDS.toMinutes(System.currentTimeMillis())
        }
    }
}
