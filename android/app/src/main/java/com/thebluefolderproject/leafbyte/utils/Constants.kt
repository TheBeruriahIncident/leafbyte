/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.os.Build
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.tooling.preview.PreviewParameterProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import net.openid.appauth.AuthState
import java.time.Instant
import java.util.concurrent.TimeUnit

/**
 * Useful in suppressing warnings for unused parameters.
 */
const val UNUSED = "UNUSED_PARAMETER"
const val LOG_TAG = "BlueFolder"

fun log(logData: Any) {
    logAnyType(Log.INFO, logData)
}

fun logError(logData: Any) {
    logAnyType(Log.ERROR, logData)
}

private fun logAnyType(
    priority: Int,
    logData: Any,
) {
    if (logData is Throwable) {
        // if logData is an exception, we override priority, both for ease, as println doesn't directly take a throwable, and because an
        //   exception seems like an error
        Log.e(LOG_TAG, "An undescribed error occurred", logData)
    } else {
        Log.println(priority, LOG_TAG, logData.toString())
    }
}

fun logError(
    message: String,
    exception: Exception,
) {
    Log.e(LOG_TAG, message, exception)
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
fun <T> Flow<T>.valueForCompose(): T {
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

// this is a provider so that the "const" here can't be changed
val DEFAULT_AUTH_STATE = { AuthState() }

fun<T> PreviewParameterProvider<T>.value(): T {
    return values.first()
}
