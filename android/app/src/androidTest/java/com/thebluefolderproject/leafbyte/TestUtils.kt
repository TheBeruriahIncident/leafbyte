package com.thebluefolderproject.leafbyte

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

    override fun getEpochTimeInSeconds(): Long {
        return time
    }

    fun waitASecond() {
        time++
    }
}

/**
 * This both prints to the log and returns as a string to be more versatile
 */
fun ComposeContext.printScreen(): String {
    onAllNodes(isRoot()).printToLog(tag = LOG_TAG, maxDepth = 100)

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

class ComposeTestFailureException(context: ComposeContext, cause: Throwable):
    Exception("Current UI nodes at time of failure:\n" + context.printScreen(), cause)
