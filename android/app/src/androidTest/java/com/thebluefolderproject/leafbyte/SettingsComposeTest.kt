package com.thebluefolderproject.leafbyte

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextReplacement
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import kotlinx.collections.immutable.persistentListOf
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test
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

    @Test
    fun testScaleLength() {
        runTest { settings ->
            val scaleLengthEntry = onNodeWithContentDescription("Scale length entry")

            scaleLengthEntry.performTextReplacement("15")
            assertEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15"))

            scaleLengthEntry.performTextClearance()
            assertEquals(10f, settings.getScaleMarkLength())
            // the placeholder is included
            scaleLengthEntry.assert(hasText("Your scale length"))

            scaleLengthEntry.performTextReplacement("hello")
            assertEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText(""))

            scaleLengthEntry.performTextReplacement("15.0000")
            assertEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0000"))

            scaleLengthEntry.performTextReplacement("15.0.1")
            assertEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0.1"))

            scaleLengthEntry.performTextReplacement("-2")
            assertEquals(2f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("2"))
        }
    }

    @Test
    fun testScaleLengthUnit() {
        runTest { settings ->
            assertEquals("cm", settings.getScaleLengthUnit())

            onNodeWithText("cm").performClick()
            onNodeWithText("in").performClick()
            assertEquals("in", settings.getScaleLengthUnit())

            onNodeWithText("in").performClick()
            onNodeWithText("ft").performClick()
            assertEquals("ft", settings.getScaleLengthUnit())
        }
    }

    @Test
    fun testNextSampleNumber() {
        runTest { settings ->
            val nextSampleNumberEntry = onNodeWithContentDescription("Next sample number entry")

            nextSampleNumberEntry.performTextReplacement("15")
            assertEquals(15, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("15"))

            nextSampleNumberEntry.performTextClearance()
            assertEquals(1, settings.getNextSampleNumber())

            nextSampleNumberEntry.performTextReplacement("hello")
            assertEquals(1, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText(""))

            nextSampleNumberEntry.performTextReplacement("15.00")
            assertEquals(1500, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1500"))

            nextSampleNumberEntry.performTextReplacement("15.0.1")
            assertEquals(1501, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1501"))

            nextSampleNumberEntry.performTextReplacement("-2")
            assertEquals(2, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("2"))
        }
    }

    @Test
    fun testChangingDatasetChangesOtherSettings() {
        runTest { settings ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")
            val scaleLengthField = onNodeWithContentDescription("Scale length entry")
            val scaleUnitButton = onNodeWithContentDescription("Scale length unit selector")
            val nextSampleNumberField = onNodeWithContentDescription("Next sample number entry")

            datasetNameField.performTextReplacement("test1")
            settings.noteDatasetUsed()
            scaleLengthField.performTextReplacement("100")
            scaleUnitButton.performClick()
            onNodeWithText("ft").performClick()
            nextSampleNumberField.performTextReplacement("100")

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            scaleLengthField.performTextReplacement("200")
            scaleUnitButton.performClick()
            onNodeWithText("m").performClick()
            nextSampleNumberField.performTextReplacement("200")

            assertEquals("test2", settings.getDatasetName())
            datasetNameField.assert(hasText("test2"))
            assertEquals(200f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("200"))
            assertEquals("m", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("m"))
            assertEquals(200, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("200"))

            onNodeWithText("Use previous dataset").performClick()
            onNodeWithText("test1").performClick()

            assertEquals("test1", settings.getDatasetName())
            datasetNameField.assert(hasText("test1"))
            assertEquals(100f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("100.0"))
            assertEquals("ft", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("ft"))
            assertEquals(100, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("100"))
        }
    }

    @Test
    fun testToggles() {
        runTest { settings ->
            assertEquals(false, settings.getUseBarcode())
            onNodeWithContentDescription("Scan Barcodes? toggle").performClick()
            assertEquals(true, settings.getUseBarcode())
            onNodeWithContentDescription("Scan Barcodes? toggle").performClick()
            assertEquals(false, settings.getUseBarcode())

            assertEquals(false, settings.getSaveGpsData())
            onNodeWithContentDescription("Save GPS Location? toggle").performClick()
            assertEquals(true, settings.getSaveGpsData())
            onNodeWithContentDescription("Save GPS Location? toggle").performClick()
            assertEquals(false, settings.getSaveGpsData())

            assertEquals(false, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle").performClick()
            assertEquals(true, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle").performClick()
            assertEquals(false, settings.getUseBlackBackground())
        }
    }
}
