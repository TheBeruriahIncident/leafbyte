package com.thebluefolderproject.leafbyte

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertTextContains
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onChildAt
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.printToLog
import androidx.test.core.app.takeScreenshot
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import com.thebluefolderproject.leafbyte.utils.SystemClock
import com.thebluefolderproject.leafbyte.utils.log
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.extension.RegisterExtension

@OptIn(ExperimentalTestApi::class)
class SettingsComposeTest {
    @JvmField
    @RegisterExtension
    val extension = createComposeExtension()

    val clock = TestClock()

    private fun runTest(test: ComposeContext.(settings: Settings) -> Unit) {
        extension.use {
            var settings: Settings? = null
            setContent {
                settings = DataStoreBackedSettings(LocalContext.current, clock)
                SettingsScreen(settings!!)
            }

            test(this, settings!!)
        }
    }

    private fun waitASecond() {
        clock.waitASecond()
    }

    @Test
    fun testSaveLocations() {
        runTest { settings ->
            onNodeWithContentDescription("Set Data Save Location to None").performClick()
            assertEquals(SaveLocation.NONE, settings.getDataSaveLocation())

            onNodeWithContentDescription("Set Data Save Location to Your Phone").performClick()
            assertEquals(SaveLocation.LOCAL, settings.getDataSaveLocation())

            onNodeWithContentDescription("Set Data Save Location to Google Drive").performClick()
            assertEquals(SaveLocation.GOOGLE_DRIVE, settings.getDataSaveLocation())

            onNodeWithContentDescription("Set Image Save Location to None").performClick()
            assertEquals(SaveLocation.NONE, settings.getImageSaveLocation())

            onNodeWithContentDescription("Set Image Save Location to Your Phone").performClick()
            assertEquals(SaveLocation.LOCAL, settings.getImageSaveLocation())

            onNodeWithContentDescription("Set Image Save Location to Google Drive").performClick()
            assertEquals(SaveLocation.GOOGLE_DRIVE, settings.getImageSaveLocation())
        }
    }

    @Test
    fun testDatasetName() {
        runTest { settings ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")

            datasetNameField.performTextReplacement("test dataset 123")
            assertEquals("test dataset 123", settings.getDatasetName())
            datasetNameField.assert(hasText("test dataset 123"))

            datasetNameField.performTextClearance()
            assertEquals("Herbivory Data", settings.getDatasetName())
            // the placeholder and explanation are included
            datasetNameField.assert(hasText("Your dataset name"))
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("    \n ")
            assertEquals("Herbivory Data", settings.getDatasetName())
            // it's trimmed before comparison
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("valid")
            assertEquals("valid", settings.getDatasetName())
            datasetNameField.assert(hasText("valid"))
        }
    }

    @Test
    fun testUsePreviousDataset() {
        runTest { settings ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")

            datasetNameField.performTextReplacement("test1")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("test3")
            settings.noteDatasetUsed()
            waitASecond()

            assertEquals(persistentListOf("test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("ephemeral")
            assertEquals(persistentListOf("ephemeral", "test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("ephemeral2")
            assertEquals(persistentListOf("ephemeral2", "test2", "test3", "test1"), settings.getPreviousDatasetNames())

            onNodeWithText("test2").assertDoesNotExist()
            onNodeWithText("Use previous dataset").performClick()

            val ephemeral2 = onAllNodesWithText("ephemeral2")[1]
            val test2 = onNodeWithText("test2")
            val test3 = onNodeWithText("test3")
            val test1 = onNodeWithText("test1")

            assertTrue(yPositionOf(ephemeral2) < yPositionOf(test2))
            assertTrue(yPositionOf(test2) < yPositionOf(test3))
            assertTrue(yPositionOf(test3) < yPositionOf(test1))

            test3.performClick()
            assertEquals("test3", settings.getDatasetName())
            datasetNameField.assert(hasText("test3"))
        }
    }

    private fun yPositionOf(node: SemanticsNodeInteraction): Float {
        return node.fetchSemanticsNode().boundsInRoot.top
    }
}