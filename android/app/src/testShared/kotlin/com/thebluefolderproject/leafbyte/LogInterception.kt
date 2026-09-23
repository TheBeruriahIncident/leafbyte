/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.utils.registerLogInterceptor

/**
 * Ideally we would have done something like https://www.braze.com/resources/articles/logcat-junit-android-tests and drawn logs directly
 *   from logcat, but I've had no success execing logcat from here. That approach may no longer be possible with Android's security model.
 */
val interceptedLogs = mutableListOf<String>()
fun initializeLogInterception() {
    interceptedLogs.clear()
    registerLogInterceptor { interceptedLogs.add(it) }
}

fun gatherInterceptedLogs(): String {
    if (interceptedLogs.isEmpty()) {
        return "No logs\n"
    }

    val builder = StringBuilder()

    interceptedLogs.forEach { log ->
        var firstLineWithinLog = true
        log.split('\n').forEach { lineWithinLog ->
            if (firstLineWithinLog) {
                builder.append("$lineWithinLog\n")

                firstLineWithinLog = false
            } else {
                // this line is prepended with a braille blank character that is not recognized as whitespace so that the indenting is not
                //   pruned by Junit reporting
                builder.append("\u2800                                     $lineWithinLog\n")
            }
        }
    }

    return builder.toString()
}
