/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.activity.LeafByteActivity
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import com.thebluefolderproject.leafbyte.utils.log
import de.mannodermaus.junit5.ActivityScenarioExtension
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertIterableEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension
import java.io.File
import java.nio.file.Files
import java.util.concurrent.TimeUnit


/**
 * This class intentionally uses some literals and avoids using some constants to be sure everything is working exactly as expected.
 */
class SettingsTest {
    @JvmField
    @RegisterExtension
    val activityScenarioExtension = ActivityScenarioExtension.launch<LeafByteActivity>()

    private fun helper(test: (settings: Settings) -> Unit) {
        activityScenarioExtension.scenario.onActivity { activity ->
            val settings = DataStoreBackedSettings(activity)
            test(settings)
        }
    }

    @AfterEach
    fun cleanup() {
        activityScenarioExtension.scenario.onActivity { activity ->
            clearSettingsStore(activity)
        }
    }

    @Test
    fun testDefaultValues() {
        helper { settings ->
            assertEquals(SaveLocation.LOCAL, settings.dataSaveLocation)
            assertEquals(SaveLocation.LOCAL, settings.imageSaveLocation)
            assertEquals("Herbivory Data", settings.datasetName)
            assertEquals(10f, settings.scaleMarkLength)
            assertEquals("cm", settings.scaleLengthUnit)
            assertEquals(1, settings.nextSampleNumber)
            assertFalse(settings.useBarcode)
            assertFalse(settings.saveGpsData)
            assertFalse(settings.useBlackBackground)
        }
    }

    @Test
    fun testDataSaveLocation() {
        helper { settings ->
            settings.dataSaveLocation = SaveLocation.GOOGLE_DRIVE
            assertEquals(SaveLocation.GOOGLE_DRIVE, settings.dataSaveLocation)

            settings.dataSaveLocation = SaveLocation.LOCAL
            assertEquals(SaveLocation.LOCAL, settings.dataSaveLocation)

            settings.dataSaveLocation = SaveLocation.NONE
            assertEquals(SaveLocation.NONE, settings.dataSaveLocation)
        }
    }

    @Test
    fun testImageSaveLocation() {
        helper { settings ->
            settings.imageSaveLocation = SaveLocation.GOOGLE_DRIVE
            assertEquals(SaveLocation.GOOGLE_DRIVE, settings.imageSaveLocation)

            settings.imageSaveLocation = SaveLocation.LOCAL
            assertEquals(SaveLocation.LOCAL, settings.imageSaveLocation)

            settings.imageSaveLocation = SaveLocation.NONE
            assertEquals(SaveLocation.NONE, settings.imageSaveLocation)
        }
    }

    @Test
    fun testDatasetName() {
        helper { settings ->
            settings.datasetName = "Potato"
            assertEquals("Potato", settings.datasetName)

            settings.datasetName = "Salad"
            assertEquals("Salad", settings.datasetName)

            settings.datasetName = ""
            assertEquals("Herbivory Data", settings.datasetName)

            settings.datasetName = "    \n   "
            assertEquals("Herbivory Data", settings.datasetName)
        }
    }

    /**
     * We sleep before calling noteDatasetUsed, because epoch time is in seconds, and we want to record a different second.
     */
    @Test
    fun testPreviousDatasetNames() {
        helper { settings ->
            assertEquals(listOf("Herbivory Data"), settings.previousDatasetNames)

            settings.datasetName = "Potato"
            assertEquals(listOf("Potato"), settings.previousDatasetNames)

            settings.datasetName = "Salad"
            assertEquals(listOf("Salad"), settings.previousDatasetNames)

            TimeUnit.SECONDS.sleep(1)
            settings.noteDatasetUsed()
            assertEquals(listOf("Salad"), settings.previousDatasetNames)

            settings.datasetName = "Dill"
            assertEquals(listOf("Dill", "Salad"), settings.previousDatasetNames)

            settings.datasetName = "Salad"
            assertEquals(listOf("Salad"), settings.previousDatasetNames)

            settings.datasetName = "Dill"
            TimeUnit.SECONDS.sleep(1)
            settings.noteDatasetUsed()
            assertEquals(listOf("Dill", "Salad"), settings.previousDatasetNames)

            settings.datasetName = "Salad"
            assertEquals(listOf("Salad", "Dill"), settings.previousDatasetNames)

            settings.datasetName = "Potato"
            assertEquals(listOf("Potato", "Dill", "Salad"), settings.previousDatasetNames)

            settings.datasetName = "Vinegar"
            TimeUnit.SECONDS.sleep(1)
            settings.noteDatasetUsed()
            settings.datasetName = "Dill"
            TimeUnit.SECONDS.sleep(1)
            settings.noteDatasetUsed()
            settings.datasetName = "Potato"
            assertEquals(listOf("Potato", "Dill", "Vinegar", "Salad"), settings.previousDatasetNames)
        }
    }

    @Test
    fun testScaleMarkLength() {
        helper { settings ->
            settings.scaleMarkLength = 5.3f
            assertEquals(5.3f, settings.scaleMarkLength)

            settings.scaleMarkLength = 241.234f
            assertEquals(241.234f, settings.scaleMarkLength)

            settings.scaleMarkLength = 0f
            assertEquals(10f, settings.scaleMarkLength)

            settings.scaleMarkLength = -5f
            assertEquals(10f, settings.scaleMarkLength)
        }
    }

    @Test
    fun testScaleLengthUnit() {
        helper { settings ->
            settings.scaleLengthUnit = "mm"
            assertEquals("mm", settings.scaleLengthUnit)

            settings.scaleLengthUnit = "ft"
            assertEquals("ft", settings.scaleLengthUnit)

            settings.scaleLengthUnit = " \n "
            assertEquals("cm", settings.scaleLengthUnit)
        }
    }

    @Test
    fun testNextSampleNumber() {
        helper { settings ->
            settings.nextSampleNumber = 12
            assertEquals(12, settings.nextSampleNumber)

            settings.nextSampleNumber = 0
            assertEquals(1, settings.nextSampleNumber)

            settings.nextSampleNumber = -5
            assertEquals(1, settings.nextSampleNumber)

            settings.incrementSampleNumber()
            assertEquals(2, settings.nextSampleNumber)

            settings.nextSampleNumber = 25
            assertEquals(25, settings.nextSampleNumber)

            settings.datasetName = "Potato"
            assertEquals(1, settings.nextSampleNumber)

            settings.nextSampleNumber = 12
            assertEquals(12, settings.nextSampleNumber)

            settings.datasetName = "Herbivory Data"
            assertEquals(25, settings.nextSampleNumber)

            settings.datasetName = "Potato"
            assertEquals(12, settings.nextSampleNumber)
        }
    }

    @Test
    fun testScanBarcodes() {
        helper { settings ->
            settings.useBarcode = true
            assertEquals(true, settings.useBarcode)

            settings.useBarcode = false
            assertEquals(false, settings.useBarcode)
        }
    }

    @Test
    fun testGpsLocation() {
        helper { settings ->
            settings.saveGpsData = true
            assertEquals(true, settings.saveGpsData)

            settings.saveGpsData = false
            assertEquals(false, settings.saveGpsData)
        }
    }

    @Test
    fun testUseBlackBackground() {
        helper { settings ->
            settings.useBlackBackground = true
            assertEquals(true, settings.useBlackBackground)

            settings.useBlackBackground = false
            assertEquals(false, settings.useBlackBackground)
        }
    }
}
