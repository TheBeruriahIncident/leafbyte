/*
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import de.mannodermaus.junit5.compose.createAndroidComposeExtension
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension

class LeafByteActivityTests {
    @OptIn(ExperimentalTestApi::class)
    @RegisterExtension
    val extension = createAndroidComposeExtension<LeafByteActivity>()

    @Test
    fun testFullWorkflow() {
        extension.use {
            onNodeWithText("LeafByte").assertExists()
            onNodeWithText("Tutorial").performClick()

            onNodeWithText("For the tutorial,", substring = true).assertExists()
            onNodeWithText("Next").performClick()
        }
    }
}
