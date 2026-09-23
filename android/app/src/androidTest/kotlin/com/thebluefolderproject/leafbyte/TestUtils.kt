/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.printToLog
import androidx.compose.ui.test.printToString
import androidx.test.espresso.NoActivityResumedException
import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.LOG_TAG
import com.thebluefolderproject.leafbyte.utils.load
import de.mannodermaus.junit5.compose.ComposeContext
import io.mockk.clearMocks
import kotlinx.coroutines.flow.Flow
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.fail
import kotlin.test.assertContains

fun <T> assertFlowEquals(
    expected: T,
    actual: Flow<T>,
) {
    Assertions.assertEquals(expected, actual.load())
}

fun assertFlowTrue(actual: Flow<Boolean>) {
    Assertions.assertTrue(actual.load())
}

fun assertFlowFalse(actual: Flow<Boolean>) {
    Assertions.assertFalse(actual.load())
}

class TestClock : Clock {
    private var time = 1L

    override fun getEpochTimeInSeconds(): Long = time

    fun waitASecond() {
        time++
    }
}

fun ComposeContext.printScreen() {
    onAllNodes(isRoot()).printToLog(tag = LOG_TAG, maxDepth = 100)
}

fun ComposeContext.getScreenState(): String = onAllNodes(isRoot()).printToString(maxDepth = 100)

fun clearMockedMethodCallCounts(mock: Any) {
    clearMocks(
        mock,
        answers = false,
        recordedCalls = true,
        childMocks = false,
        verificationMarks = false,
        exclusionRules = false,
    )
}

fun assertClosesApp(actionThatShouldCloseApp: () -> Unit) {
    try {
        actionThatShouldCloseApp()
        fail("Test did not crash") // This line should not be reached
    } catch (exception: Exception) {
        when (exception) { // Kotlin does not have multi-catch, so this is the workaround
            // This is the exception we see locally
            is NoActivityResumedException -> {
                assertContains(exception.message!!, "Pressed back and killed the app")
            }
            else -> {
                // For unknown reasons, sometimes this exception is what's thrown in CI. However, it's private, so we do this workaround
                if (!exception::class.simpleName!!.contains("RootViewWithoutFocusException", ignoreCase = true)) {
                    throw exception
                }
            }
        }
    }
}

// inspired by https://www.braze.com/resources/articles/logcat-junit-android-tests
class ComposeTestFailureException(
    context: ComposeContext?,
    cause: Throwable,
) : Exception(createMessage(context, cause)) {
    init {
        // We replace the stacktrace to seamlessly swap this exception for the original and not add another wrapping layer of indirection
        this.stackTrace = cause.stackTrace
    }

    companion object {
        private fun createMessage(
            context: ComposeContext?,
            cause: Throwable,
        ): String =
            "\n" +
                "================================ Current UI Nodes ================================\n" +
                "${context?.getScreenState() ?: "Unknown"}\n\n" +
                "================================ Logcat Output ================================\n" +
                "${gatherInterceptedLogs()}\n" +
                "================================ Stacktrace ================================\n" +
                "Message: ${cause.message}\n" +
                "Original class: ${cause.javaClass.name}\n"
    }
}

fun SemanticsNodeInteraction.assertIsInErrorState() {
    this.assert(SemanticsMatcher.expectValue(SemanticsProperties.Error, "Invalid input"))
}
