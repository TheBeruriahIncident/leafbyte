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
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension
import java.io.File
import java.nio.file.Files


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
        }
    }

    @Test
    fun testScaleLength() {
        helper { settings ->
            settings.scaleMarkLength = 5.3f
            assertEquals(5.3f, settings.scaleMarkLength)

            settings.scaleMarkLength = 241.234f
            assertEquals(241.234f, settings.scaleMarkLength)
        }
    }

    @Test
    fun testScaleLengthUnits() {
        helper { settings ->
            settings.scaleLengthUnit = "mm"
            assertEquals("mm", settings.scaleLengthUnit)

            settings.scaleLengthUnit = "ft"
            assertEquals("ft", settings.scaleLengthUnit)
        }
    }

    @Test
    fun testNextSampleNumber() {
        helper { settings ->
            settings.nextSampleNumber = 12
            assertEquals(12, settings.nextSampleNumber)

            settings.nextSampleNumber = 25
            assertEquals(25, settings.nextSampleNumber)
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
