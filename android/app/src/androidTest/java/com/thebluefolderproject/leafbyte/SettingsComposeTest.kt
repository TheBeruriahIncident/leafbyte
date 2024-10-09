package com.thebluefolderproject.leafbyte

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isNotSelected
import androidx.compose.ui.test.isOff
import androidx.compose.ui.test.isOn
import androidx.compose.ui.test.isSelected
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextReplacement
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import kotlinx.collections.immutable.persistentListOf
import org.junit.jupiter.api.Assertions.assertTrue
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
                SettingsScreen(settings)
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
            val dataNone = onNodeWithContentDescription("Set Data Save Location to None")
            val dataLocal = onNodeWithContentDescription("Set Data Save Location to Your Phone")
            val dataGoogle = onNodeWithContentDescription("Set Data Save Location to Google Drive")
            fun dataSelectionIs(node: SemanticsNodeInteraction) {
                node.assert(isSelected())

                if (node != dataNone) {
                    dataNone.assert(isNotSelected())
                }
                if (node != dataLocal) {
                    dataLocal.assert(isNotSelected())
                }
                if (node != dataGoogle) {
                    dataGoogle.assert(isNotSelected())
                }
            }

            val imageNone = onNodeWithContentDescription("Set Image Save Location to None")
            val imageLocal = onNodeWithContentDescription("Set Image Save Location to Your Phone")
            val imageGoogle = onNodeWithContentDescription("Set Image Save Location to Google Drive")
            fun imageSelectionIs(node: SemanticsNodeInteraction) {
                node.assert(isSelected())

                if (node != imageNone) {
                    imageNone.assert(isNotSelected())
                }
                if (node != imageLocal) {
                    imageLocal.assert(isNotSelected())
                }
                if (node != imageGoogle) {
                    imageGoogle.assert(isNotSelected())
                }
            }

            dataNone.performClick()
            dataSelectionIs(dataNone)
            assertFlowEquals(SaveLocation.NONE, settings.getDataSaveLocation())

            dataLocal.performClick()
            dataSelectionIs(dataLocal)
            assertFlowEquals(SaveLocation.LOCAL, settings.getDataSaveLocation())

            imageNone.performClick()
            imageSelectionIs(imageNone)
            assertFlowEquals(SaveLocation.NONE, settings.getImageSaveLocation())

            imageLocal.performClick()
            imageSelectionIs(imageLocal)
            assertFlowEquals(SaveLocation.LOCAL, settings.getImageSaveLocation())

            // we do not select Google Drive here, as testing Google Drive is complex and done elsewhere
        }
    }

    @Test
    fun testDatasetName() {
        runTest { settings ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")

            datasetNameField.performTextReplacement("test dataset 123")
            assertFlowEquals("test dataset 123", settings.getDatasetName())
            datasetNameField.assert(hasText("test dataset 123"))

            datasetNameField.performTextClearance()
            assertFlowEquals("Herbivory Data", settings.getDatasetName())
            // the placeholder and explanation are included
            datasetNameField.assert(hasText("Your dataset name"))
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("    \n ")
            assertFlowEquals("Herbivory Data", settings.getDatasetName())
            // it's trimmed before comparison
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("valid")
            assertFlowEquals("valid", settings.getDatasetName())
            datasetNameField.assert(hasText("valid"))
        }
    }

    // TODO test the dataset name alert once we have multiple screens
//    @Test
//    fun testBlankDatasetNameAlert() {
//        runTest { settings ->
//            // first we test that normally, you can press back to leave the screen
//            assertThrows<NoActivityResumedException>("Pressed back and killed the app") {
//                Espresso.pressBack()
//            }
//        }
//    }
//    @Test
//    fun testBlankDatasetNameAlert2() {
//        runTest { settings ->
//            val datasetNameField = onNodeWithContentDescription("Dataset name entry")
//            datasetNameField.performTextClearance()
//            val mDevice = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation());
//            mDevice.pressBack(); Espresso.pressBack()
//
//            println(onRoot().printToString())
//
//            val errorMessage = onNodeWithText("A dataset name is required. Please enter a dataset name.")
//            errorMessage.assertExists()
//            onNodeWithText("OK").performClick()
////            errorMessage.assertDoesNotExist()
//
//            Espresso.pressBack()
////            errorMessage.assertExists()
//            onNodeWithText("OK").performClick()
////            errorMessage.assertDoesNotExist()
//
//            datasetNameField.performTextReplacement("non-empty")
//            // first we test that normally, you can press back to leave the screen
//            assertThrows<NoActivityResumedException>("Pressed back and killed the app") {
//                Espresso.pressBack()
//            }
//        }
//    }

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

            assertFlowEquals(persistentListOf("test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("ephemeral")
            assertFlowEquals(persistentListOf("ephemeral", "test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("ephemeral2")
            assertFlowEquals(persistentListOf("ephemeral2", "test2", "test3", "test1"), settings.getPreviousDatasetNames())

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
            assertFlowEquals("test3", settings.getDatasetName())
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
            assertFlowEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15"))

            scaleLengthEntry.performTextClearance()
            assertFlowEquals(10f, settings.getScaleMarkLength())
            // the placeholder is included
            scaleLengthEntry.assert(hasText("Your scale length"))

            scaleLengthEntry.performTextReplacement("hello")
            assertFlowEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText(""))

            scaleLengthEntry.performTextReplacement("15.0000")
            assertFlowEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0000"))

            scaleLengthEntry.performTextReplacement("15.0.1")
            assertFlowEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0.1"))

            scaleLengthEntry.performTextReplacement("-2")
            assertFlowEquals(2f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("2"))
        }
    }

    @Test
    fun testScaleLengthUnit() {
        runTest { settings ->
            assertFlowEquals("cm", settings.getScaleLengthUnit())

            onNodeWithText("cm").performClick()
            onNodeWithText("in").performClick()
            assertFlowEquals("in", settings.getScaleLengthUnit())

            onNodeWithText("in").performClick()
            onNodeWithText("ft").performClick()
            assertFlowEquals("ft", settings.getScaleLengthUnit())
        }
    }

    @Test
    fun testNextSampleNumber() {
        runTest { settings ->
            val nextSampleNumberEntry = onNodeWithContentDescription("Next sample number entry")

            nextSampleNumberEntry.performTextReplacement("15")
            assertFlowEquals(15, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("15"))

            nextSampleNumberEntry.performTextClearance()
            assertFlowEquals(1, settings.getNextSampleNumber())

            nextSampleNumberEntry.performTextReplacement("hello")
            assertFlowEquals(1, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText(""))

            nextSampleNumberEntry.performTextReplacement("15.00")
            assertFlowEquals(1500, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1500"))

            nextSampleNumberEntry.performTextReplacement("15.0.1")
            assertFlowEquals(1501, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1501"))

            nextSampleNumberEntry.performTextReplacement("-2")
            assertFlowEquals(2, settings.getNextSampleNumber())
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

            assertFlowEquals("test2", settings.getDatasetName())
            datasetNameField.assert(hasText("test2"))
            assertFlowEquals(200f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("200"))
            assertFlowEquals("m", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("m"))
            assertFlowEquals(200, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("200"))

            onNodeWithText("Use previous dataset").performClick()
            onNodeWithText("test1").performClick()

            assertFlowEquals("test1", settings.getDatasetName())
            datasetNameField.assert(hasText("test1"))
            assertFlowEquals(100f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("100.0"))
            assertFlowEquals("ft", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("ft"))
            assertFlowEquals(100, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("100"))
        }
    }

    @Test
    fun testScanBarcodes() {
        runTest { settings ->
            assertFlowEquals(false, settings.getUseBarcode())
            onNodeWithContentDescription("Scan Barcodes? toggle")
                .assert(isOff())
                .performScrollTo()
                .performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getUseBarcode())
            onNodeWithContentDescription("Scan Barcodes? toggle")
                .performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getUseBarcode())
        }
    }

    @Test
    fun testSaveGps() {
        runTest { settings ->
            assertFlowEquals(false, settings.getSaveGpsData())
            onNodeWithContentDescription("Save GPS Location? toggle")
                .assert(isOff())
                .performScrollTo()
                .performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getSaveGpsData())
            onNodeWithContentDescription("Save GPS Location? toggle")
                .performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getSaveGpsData())
        }
    }

    @Test
    fun testUseBlackBackground() {
        runTest { settings ->
            assertFlowEquals(false, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle")
                .assert(isOff())
                .performScrollTo()
                .performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle")
                .performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getUseBlackBackground())
        }
    }
}
