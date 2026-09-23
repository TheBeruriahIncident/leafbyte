/*
 * Copyright © 2026 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import android.util.Log
import io.mockk.every
import io.mockk.mockkStatic
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach

@Suppress("detekt:style:UnnecessaryAbstractClass")
abstract class AbstractUnitTests {
    @BeforeEach
    fun beforeEach() {
        initializeLogInterception()
        mockAndroidLogging()
    }

    @AfterEach
    fun afterEach() {
        println(gatherInterceptedLogs())
    }

    /**
     * Android dev doesn't have the same logging interface/implementation split that Java server dev uses, which means that anything that
     * logs without having the Android library on the classpath causes a crash. As such, for unit tests we'll statically mock logging and
     * catch the logs otherwise.
     */
    private fun mockAndroidLogging() {
        mockkStatic(Log::class)
        @Suppress("detekt:style:ForbiddenMethodCall")
        every { Log.println(any(), any(), any()) } returns 0
    }
}
