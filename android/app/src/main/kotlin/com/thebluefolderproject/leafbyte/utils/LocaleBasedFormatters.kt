/*
 * Copyright © 2026 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import java.text.DecimalFormat
import java.text.NumberFormat
import java.text.ParseException
import java.text.ParsePosition
import java.util.Locale

fun formatFloatInLocale(
    float: Float,
    locale: Locale,
): String = getFloatFormatter(locale).format(float)

fun formatIntInLocale(
    int: Int,
    locale: Locale,
): String = getIntFormatter(locale).format(int)

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
        val formatter = NumberFormat.getNumberInstance(locale)
        if (formatter is DecimalFormat) {
            // always show at least one digit after the decimal (even e.g., 5.0) to let users know that they can use decimals
            formatter.minimumFractionDigits = 1
        } else {
            logError("NOT DECIMAL??")
        }

        return formatter
    })

private fun getIntFormatter(locale: Locale): NumberFormat = intFormatterCache.getOrPut(locale, { NumberFormat.getIntegerInstance(locale) })

// Inspired by https://stackoverflow.com/a/9317073/1092672
@Suppress("detekt:style:ReturnCount")
private fun <ReturnType> strictlyParseInLocale(
    numberString: String,
    localeBasedFormatter: NumberFormat,
    reifyType: (Number) -> ReturnType,
): ReturnType? {
    val parsePosition = ParsePosition(0)

    val parsedNumber =
        try {
            localeBasedFormatter.parse(numberString, parsePosition)
        } catch (exception: ParseException) {
            logUserIssue("Failed to parse $numberString as a number", exception)
            return null
        }
    // if the parse returned a number but actually failed or did not use the whole string, treat it as a failure
    if (parsePosition.errorIndex != -1 || parsePosition.index != numberString.length) {
        logUserIssue(
            "Failed to parse $numberString as a number; errorIndex=${parsePosition.errorIndex}, parsePosition=${parsePosition.index}",
        )
        return null
    }
    // this is expected at least in the case that the string is empty
    if (parsedNumber == null) {
        logUserIssue("Number string was parsed as null: $numberString")
        return null
    }

    return reifyType(parsedNumber)
}
