/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.activity.LeafByteActivity
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import de.mannodermaus.junit5.ActivityScenarioExtension
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension
import java.util.concurrent.TimeUnit

/**
 * This class intentionally uses some literals and avoids using some constants to be sure everything is working exactly as expected.
 */
class SettingsTest {
    @JvmField
    @RegisterExtension
    val activityScenarioExtension = ActivityScenarioExtension.launch<LeafByteActivity>()

    private fun helper(test: Settings.() -> Unit) {
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
        helper {
            assertEquals(SaveLocation.LOCAL, dataSaveLocation)
            assertEquals(SaveLocation.LOCAL, imageSaveLocation)
            assertEquals("Herbivory Data", datasetName)
            assertEquals(10f, scaleMarkLength)
            assertEquals("cm", scaleLengthUnit)
            assertEquals(1, nextSampleNumber)
            assertFalse(useBarcode)
            assertFalse(saveGpsData)
            assertFalse(useBlackBackground)
        }
    }

    @Test
    fun testDataSaveLocation() {
        helper {
            dataSaveLocation = SaveLocation.GOOGLE_DRIVE
            assertEquals(SaveLocation.GOOGLE_DRIVE, dataSaveLocation)

            dataSaveLocation = SaveLocation.LOCAL
            assertEquals(SaveLocation.LOCAL, dataSaveLocation)

            dataSaveLocation = SaveLocation.NONE
            assertEquals(SaveLocation.NONE, dataSaveLocation)
        }
    }

    @Test
    fun testImageSaveLocation() {
        helper {
            imageSaveLocation = SaveLocation.GOOGLE_DRIVE
            assertEquals(SaveLocation.GOOGLE_DRIVE, imageSaveLocation)

            imageSaveLocation = SaveLocation.LOCAL
            assertEquals(SaveLocation.LOCAL, imageSaveLocation)

            imageSaveLocation = SaveLocation.NONE
            assertEquals(SaveLocation.NONE, imageSaveLocation)
        }
    }

    @Test
    fun testDatasetName() {
        helper {
            datasetName = "Potato"
            assertEquals("Potato", datasetName)

            datasetName = "Salad"
            assertEquals("Salad", datasetName)

            datasetName = ""
            assertEquals("Herbivory Data", datasetName)

            datasetName = "    \n   "
            assertEquals("Herbivory Data", datasetName)
        }
    }

    /**
     * We sleep before calling noteDatasetUsed, because epoch time is in seconds, and we want to record a different second.
     */
    @Test
    fun testPreviousDatasetNames() {
        helper {
            assertEquals(listOf("Herbivory Data"), previousDatasetNames)

            datasetName = "Potato"
            assertEquals(listOf("Potato"), previousDatasetNames)

            datasetName = "Salad"
            assertEquals(listOf("Salad"), previousDatasetNames)

            TimeUnit.SECONDS.sleep(1)
            noteDatasetUsed()
            assertEquals(listOf("Salad"), previousDatasetNames)

            datasetName = "Dill"
            assertEquals(listOf("Dill", "Salad"), previousDatasetNames)

            datasetName = "Salad"
            assertEquals(listOf("Salad"), previousDatasetNames)

            datasetName = "Dill"
            TimeUnit.SECONDS.sleep(1)
            noteDatasetUsed()
            assertEquals(listOf("Dill", "Salad"), previousDatasetNames)

            datasetName = "Salad"
            assertEquals(listOf("Salad", "Dill"), previousDatasetNames)

            datasetName = "Potato"
            assertEquals(listOf("Potato", "Dill", "Salad"), previousDatasetNames)

            datasetName = "Vinegar"
            TimeUnit.SECONDS.sleep(1)
            noteDatasetUsed()
            datasetName = "Dill"
            TimeUnit.SECONDS.sleep(1)
            noteDatasetUsed()
            datasetName = "Potato"
            assertEquals(listOf("Potato", "Dill", "Vinegar", "Salad"), previousDatasetNames)
        }
    }

    @Test
    fun testScaleMarkLength() {
        helper {
            scaleMarkLength = 5.3f
            assertEquals(5.3f, scaleMarkLength)

            scaleMarkLength = 241.234f
            assertEquals(241.234f, scaleMarkLength)

            scaleMarkLength = 0f
            assertEquals(10f, scaleMarkLength)

            scaleMarkLength = -5f
            assertEquals(10f, scaleMarkLength)
        }
    }

    @Test
    fun testScaleLengthUnit() {
        helper {
            scaleLengthUnit = "mm"
            assertEquals("mm", scaleLengthUnit)

            scaleLengthUnit = "ft"
            assertEquals("ft", scaleLengthUnit)

            scaleLengthUnit = " \n "
            assertEquals("cm", scaleLengthUnit)
        }
    }

    @Test
    fun testNextSampleNumber() {
        helper {
            nextSampleNumber = 12
            assertEquals(12, nextSampleNumber)

            nextSampleNumber = 0
            assertEquals(1, nextSampleNumber)

            nextSampleNumber = -5
            assertEquals(1, nextSampleNumber)

            incrementSampleNumber()
            assertEquals(2, nextSampleNumber)

            nextSampleNumber = 25
            assertEquals(25, nextSampleNumber)

            datasetName = "Potato"
            assertEquals(1, nextSampleNumber)

            nextSampleNumber = 12
            assertEquals(12, nextSampleNumber)

            datasetName = "Herbivory Data"
            assertEquals(25, nextSampleNumber)

            datasetName = "Potato"
            assertEquals(12, nextSampleNumber)
        }
    }

    @Test
    fun testScanBarcodes() {
        helper {
            useBarcode = true
            assertEquals(true, useBarcode)

            useBarcode = false
            assertEquals(false, useBarcode)
        }
    }

    @Test
    fun testGpsLocation() {
        helper {
            saveGpsData = true
            assertEquals(true, saveGpsData)

            saveGpsData = false
            assertEquals(false, saveGpsData)
        }
    }

    @Test
    fun testUseBlackBackground() {
        helper {
            useBlackBackground = true
            assertEquals(true, useBlackBackground)

            useBlackBackground = false
            assertEquals(false, useBlackBackground)
        }
    }
}
