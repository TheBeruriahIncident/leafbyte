/*
 * Copyright © 2026 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import java.text.NumberFormat
import java.text.ParseException
import java.text.ParsePosition
import java.util.Locale

fun strictlyParseFloatInLocale(
    floatString: String,
    locale: Locale,
): Float? = strictlyParseInLocale(floatString, getFloatFormatter(locale), Number::toFloat)

fun strictlyParseIntInLocale(
    intString: String,
    locale: Locale,
): Int? = strictlyParseInLocale(intString, getIntFormatter(locale), Number::toInt)

private val floatFormatterCache = mutableMapOf<Locale, NumberFormat>()
private val intFormatterCache = mutableMapOf<Locale, NumberFormat>()

private fun getFloatFormatter(locale: Locale): NumberFormat =
    floatFormatterCache.getOrPut(locale, {
        NumberFormat.getNumberInstance(locale)
    })

private fun getIntFormatter(locale: Locale): NumberFormat = intFormatterCache.getOrPut(locale, { NumberFormat.getIntegerInstance(locale) })

// Inspired by https://stackoverflow.com/a/9317073/1092672
private fun <ReturnType> strictlyParseInLocale(
    numberString: String,
    localeBasedFormatter: NumberFormat,
    reifyType: (Number) -> ReturnType,
): ReturnType? {
    val parsePosition = ParsePosition(0)

    val parsedNumber =
        try {
            localeBasedFormatter.parse(numberString, parsePosition)
        } catch (_: ParseException) {
            return null
        }
    // if the parse returned a number but actually failed or did not use the whole string, treat it as a failure
    if (parsePosition.errorIndex != -1 || parsePosition.index != numberString.length) {
        return null
    }

    return reifyType(parsedNumber)
}
