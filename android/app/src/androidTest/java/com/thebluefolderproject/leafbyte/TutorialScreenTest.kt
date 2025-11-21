package com.thebluefolderproject.leafbyte

import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import org.junit.jupiter.api.Test

class TutorialScreenTest : AbstractComposeTest {
    constructor() : super(navigateToCorrectScreen = {
        onNodeWithText("Tutorial").performClick()
        onNodeWithText("We use images", substring = true).assertExists()
    })

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
            onNodeWithContentDescription("Home Button").performClick()
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
}
