package com.thebluefolderproject.leafbyte

import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.printToLog
import androidx.compose.ui.test.printToString
import androidx.test.espresso.NoActivityResumedException
import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.LOG_TAG
import com.thebluefolderproject.leafbyte.utils.load
import com.thebluefolderproject.leafbyte.utils.registerLogInterceptor
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

    override fun getEpochTimeInSeconds(): Long {
        return time
    }

    fun waitASecond() {
        time++
    }
}

fun ComposeContext.printScreen() {
    onAllNodes(isRoot()).printToLog(tag = LOG_TAG, maxDepth = 100)
}

fun ComposeContext.getScreenState(): String {
    return onAllNodes(isRoot()).printToString(maxDepth = 100)
}

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

/**
 * Ideally we would have done something like https://www.braze.com/resources/articles/logcat-junit-android-tests and drawn logs directly
 *   from logcat, but I've had no success execing logcat from here. That approach may no longer be possible with Android's security model
 */
@Suppress("detekt:potential-bugs:DoubleMutabilityForCollection")
var interceptedLogs = mutableListOf<String>()
fun initializeLogInterception() {
    interceptedLogs = mutableListOf()
    registerLogInterceptor { interceptedLogs.add(it) }
}

private fun gatherInterceptedLogs(): String {
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

// inspired by https://www.braze.com/resources/articles/logcat-junit-android-tests
class ComposeTestFailureException(context: ComposeContext, cause: Throwable) : Exception(createMessage(context, cause)) {
    init {
        // We replace the stacktrace to seamlessly swap this exception for the original and not add another wrapping layer of indirection
        this.stackTrace = cause.stackTrace
    }

    companion object {
        private fun createMessage(
            context: ComposeContext,
            cause: Throwable,
        ): String {
            return "\nMessage: ${cause.message}" +
                "\nOriginal class: ${cause.javaClass.name}\n\n" +
                "================================ Logcat Output ================================\n${gatherInterceptedLogs()}\n" +
                "================================ Current UI Nodes ================================\n${context.getScreenState()}\n\n" +
                "================================ Stacktrace ================================"
        }
    }
}
