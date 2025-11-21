/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import android.app.Instrumentation
import android.content.Intent
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performFirstLinkClick
import androidx.test.espresso.intent.Intents
import androidx.test.espresso.intent.matcher.IntentMatchers
import org.hamcrest.core.AllOf
import org.junit.jupiter.api.Test

class TutorialScreenTest : AbstractComposeTest {
    constructor() : super(navigateToCorrectScreen = {
        onNodeWithText("Tutorial").performClick()
    })

    @Test
    fun testTutorialAppears() {
        runTest { _, _ ->
            onNodeWithText("We use images", substring = true).assertExists()
        }
    }

    @Test
    fun testBack() {
        runTest { _, _ ->
            onNodeWithText("Back").performClick()
            onNodeWithText("Settings").assertExists()
        }
    }

    @Test
    fun testHome() {
        runTest { _, _ ->
            onNodeWithContentDescription("Home button").performClick()
            onNodeWithText("Settings").assertExists()
        }
    }

    @Test
    fun testNext() {
        runTest { _, _ ->
            onNodeWithText("Next").performClick()
            onNodeWithText("Background Removal").assertExists()
        }
    }

    @Test
    fun testWebsiteLink() {
        runTest { _, _ ->
            Intents.init()
            val expectedIntent =
                AllOf.allOf(
                    IntentMatchers.hasAction(Intent.ACTION_VIEW),
                    IntentMatchers.hasData("https://zoegp.science/leafbyte-faqs"),
                )
            Intents.intending(expectedIntent).respondWith(Instrumentation.ActivityResult(0, null))

            onNodeWithText("the website", substring = true).performFirstLinkClick()

            Intents.intended(expectedIntent)
            Intents.release()
        }
    }
}
