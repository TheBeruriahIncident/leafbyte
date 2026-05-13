/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.compose

import android.app.Instrumentation
import android.content.Intent
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performFirstLinkClick
import androidx.test.espresso.Espresso
import androidx.test.espresso.intent.Intents
import androidx.test.espresso.intent.matcher.IntentMatchers
import com.thebluefolderproject.leafbyte.assertClosesApp
import org.hamcrest.core.AllOf
import org.junit.jupiter.api.Test

class MainMenuScreenTests : AbstractComposeTests {
    constructor() : super(navigateToCorrectScreen = {})

    @Test
    fun testBackButtonClosesApp() {
        runTest { _, _ ->
            assertClosesApp {
                Espresso.pressBack()
            }
        }
    }

    @Test
    fun testOpenSettings() {
        runTest { _, _ ->
            onNodeWithText("Settings").performClick()
            onNodeWithText("Scale Length").assertExists()
        }
    }

    @Test
    fun testSaveLocationsDescription() {
        runTest { _, _ ->
            onNodeWithText("Saving data and images to My Files under the name Herbivory Data.").assertExists()

            onNodeWithText("Settings").performClick()
            onNodeWithContentDescription("Set Image Save Location to None").performClick()
            Espresso.pressBack()

            onNodeWithText(
                "Saving data to My Files under the name Herbivory Data.\nImages are not being saved. Go to Settings to change.",
            ).assertExists()
        }
    }

    @Test
    fun testOpenTutorial() {
        runTest { _, _ ->
            onNodeWithText("Tutorial").performClick()
            onNodeWithText("We use images", substring = true).assertExists()
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

            onNodeWithText("FAQs, Help, and Bug Reporting").performFirstLinkClick()

            Intents.intended(expectedIntent)
            Intents.release()
        }
    }
}
