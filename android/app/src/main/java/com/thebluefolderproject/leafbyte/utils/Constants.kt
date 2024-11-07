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
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

/**
 * Useful in suppressing warnings for unused parameters.
 */
const val UNUSED = "UNUSED_PARAMETER"
const val LOG_TAG = "BlueFolder"

/**
 * The intended use is to capture test logs to make CI failures easier to debug.
 */
private var logInterceptor: ((String) -> Unit)? = null
fun registerLogInterceptor(newLogInterceptor: (String) -> Unit) {
    logInterceptor = newLogInterceptor
}

fun log(logData: Any) {
    logAnyType(Log.INFO, logData)
}

fun logError(logData: Any) {
    logAnyType(Log.ERROR, logData)
}

fun logError(
    message: String,
    throwable: Throwable,
) {
    logThrowable(Log.ERROR, message, throwable)
}

private fun logAnyType(
    priority: Int,
    logData: Any,
) {
    if (logData is Throwable) {
        logThrowable(priority, "An undescribed error occurred", logData)
    } else {
        logCoreImplementation(priority, logData.toString())
    }
}

private fun logThrowable(
    priority: Int,
    description: String,
    throwable: Throwable,
) {
    logCoreImplementation(priority, "${description}\n${throwable.stackTraceToString()}")
}

/**
 * All log calls must use this method.
 */
private fun logCoreImplementation(
    priority: Int,
    log: String,
) {
    if (logInterceptor != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val timestamp = DateTimeFormatter.ISO_INSTANT.format(Instant.now())
        val priorityDescription = priorityToDescription(priority)
        logInterceptor?.invoke("$timestamp $priorityDescription $log")
    }

    @Suppress("detekt:style:ForbiddenMethodCall")
    Log.println(priority, LOG_TAG, log)
}

private fun priorityToDescription(priority: Int): String {
    return when (priority) {
        Log.VERBOSE -> "VERBOSE"
        Log.DEBUG -> "DEBUG  "
        Log.INFO -> "INFO   "
        Log.WARN -> "WARN   "
        Log.ERROR -> "ERROR  "
        Log.ASSERT -> "ASSERT "
        else -> "UNKNOWN"
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

fun <T> PreviewParameterProvider<T>.value(): T {
    return values.first()
}
