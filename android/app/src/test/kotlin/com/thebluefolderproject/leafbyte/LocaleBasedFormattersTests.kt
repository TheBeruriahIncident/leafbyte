/*
 * Copyright © 2026 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.utils.strictlyParseFloatInLocale
import com.thebluefolderproject.leafbyte.utils.strictlyParseIntInLocale
import org.junit.jupiter.api.Test
import java.util.Locale
import kotlin.test.assertEquals

class LocaleBasedFormattersTests {
    val english: Locale = Locale.ENGLISH
    val german: Locale = Locale.GERMAN

    @Test
    fun testAmericanInts() {
        assertEquals(5, strictlyParseIntInLocale("5", english))
        assertEquals(null, strictlyParseIntInLocale("s", english))
        assertEquals(null, strictlyParseIntInLocale("5s", english))
        assertEquals(5123, strictlyParseIntInLocale("5,123", english))
    }

    @Test
    fun testGermanInts() {
        assertEquals(5, strictlyParseIntInLocale("5", german))
        assertEquals(null, strictlyParseIntInLocale("s", german))
        assertEquals(null, strictlyParseIntInLocale("5s", german))
        assertEquals(5123, strictlyParseIntInLocale("5.123", german))
    }

    @Test
    fun testAmericanFloats() {
        assertEquals(5.3f, strictlyParseFloatInLocale("5.3", english))
        assertEquals(null, strictlyParseFloatInLocale("s", english))
        assertEquals(null, strictlyParseFloatInLocale("5.3s", english))
        assertEquals(5123.35f, strictlyParseFloatInLocale("5,123.35", english))
    }

    @Test
    fun testGermanFloats() {
        assertEquals(5.3f, strictlyParseFloatInLocale("5,3", german))
        assertEquals(null, strictlyParseFloatInLocale("s", german))
        assertEquals(null, strictlyParseFloatInLocale("5,3s", german))
        assertEquals(5123.35f, strictlyParseFloatInLocale("5.123,35", german))
    }
}
