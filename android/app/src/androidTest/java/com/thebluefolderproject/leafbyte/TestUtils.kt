package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.load
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
