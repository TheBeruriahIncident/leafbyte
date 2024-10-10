package com.thebluefolderproject.leafbyte

import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.isRoot
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.printToLog
import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.LOG_TAG
import com.thebluefolderproject.leafbyte.utils.load
import de.mannodermaus.junit5.compose.ComposeContext
import io.mockk.clearAllMocks
import io.mockk.clearMocks
import kotlinx.coroutines.flow.Flow
import org.junit.jupiter.api.Assertions

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

fun clearMockedMethodCallCounts(mock: Any) {
    clearMocks(
        mock,
        answers = false,
        recordedCalls = true,
        childMocks = false,
        verificationMarks = true,  // set this to true to have verifyAll be reset as well
        exclusionRules = false
    )
}
