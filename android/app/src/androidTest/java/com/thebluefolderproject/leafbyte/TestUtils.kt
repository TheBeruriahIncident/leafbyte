package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.load
import kotlinx.coroutines.flow.Flow
import org.junit.jupiter.api.Assertions

fun <T> assertEquals(
    expected: T,
    actual: Flow<T>,
) {
    Assertions.assertEquals(expected, actual.load())
}

fun assertTrue(actual: Flow<Boolean>) {
    Assertions.assertTrue(actual.load())
}

fun assertFalse(actual: Flow<Boolean>) {
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
