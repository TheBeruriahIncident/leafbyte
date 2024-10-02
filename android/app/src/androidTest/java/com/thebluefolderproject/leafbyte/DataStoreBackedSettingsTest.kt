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
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension

/**
 * This class intentionally uses some literals and avoids using some constants to be sure everything is working exactly as expected.
 */
class DataStoreBackedSettingsTest {
    @JvmField
    @RegisterExtension
    val activityScenarioExtension = ActivityScenarioExtension.launch<LeafByteActivity>()

    val clock = TestClock()

    private fun runTest(test: Settings.() -> Unit) {
        activityScenarioExtension.scenario.onActivity { activity ->
            val settings = DataStoreBackedSettings(activity, clock)
            test(settings)
        }
    }

    private fun waitASecond() {
        clock.waitASecond()
    }

    @AfterEach
    fun cleanup() {
        activityScenarioExtension.scenario.onActivity { activity ->
            clearSettingsStore(activity)
        }
    }

    @Test
    fun testDefaultValues() {
        runTest {
            assertEquals(SaveLocation.LOCAL, getDataSaveLocation())
            assertEquals(SaveLocation.LOCAL, getImageSaveLocation())
            assertEquals("Herbivory Data", getDatasetName())
            assertEquals(10f, getScaleMarkLength())
            assertEquals("cm", getScaleLengthUnit())
            assertEquals(1, getNextSampleNumber())
            assertFalse(getUseBarcode())
            assertFalse(getSaveGpsData())
            assertFalse(getUseBlackBackground())
        }
    }

    @Test
    fun testDataSaveLocation() {
        runTest {
            setDataSaveLocation(SaveLocation.GOOGLE_DRIVE)
            assertEquals(SaveLocation.GOOGLE_DRIVE, getDataSaveLocation())

            setDataSaveLocation(SaveLocation.LOCAL)
            assertEquals(SaveLocation.LOCAL, getDataSaveLocation())

            setDataSaveLocation(SaveLocation.NONE)
            assertEquals(SaveLocation.NONE, getDataSaveLocation())
        }
    }

    @Test
    fun testImageSaveLocation() {
        runTest {
            setImageSaveLocation(SaveLocation.GOOGLE_DRIVE)
            assertEquals(SaveLocation.GOOGLE_DRIVE, getImageSaveLocation())

            setImageSaveLocation(SaveLocation.LOCAL)
            assertEquals(SaveLocation.LOCAL, getImageSaveLocation())

            setImageSaveLocation(SaveLocation.NONE)
            assertEquals(SaveLocation.NONE, getImageSaveLocation())
        }
    }

    @Test
    fun testDatasetName() {
        runTest {
            setDatasetName("Potato")
            assertEquals("Potato", getDatasetName())

            setDatasetName("Salad")
            assertEquals("Salad", getDatasetName())

            setDatasetName("")
            assertEquals("Herbivory Data", getDatasetName())

            setDatasetName("    \n   ")
            assertEquals("Herbivory Data", getDatasetName())
        }
    }

    /**
     * We sleep before calling noteDatasetUsed, because epoch time is in seconds, and we want to record a different second.
     */
    @Test
    fun testPreviousDatasetNames() {
        runTest {
            assertEquals(listOf("Herbivory Data"), getPreviousDatasetNames())

            setDatasetName("Potato")
            assertEquals(listOf("Potato"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertEquals(listOf("Salad"), getPreviousDatasetNames())

            waitASecond()
            noteDatasetUsed()
            assertEquals(listOf("Salad"), getPreviousDatasetNames())

            setDatasetName("Dill")
            assertEquals(listOf("Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertEquals(listOf("Salad"), getPreviousDatasetNames())

            setDatasetName("Dill")
            waitASecond()
            noteDatasetUsed()
            assertEquals(listOf("Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertEquals(listOf("Salad", "Dill"), getPreviousDatasetNames())

            setDatasetName("Potato")
            assertEquals(listOf("Potato", "Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Vinegar")
            waitASecond()
            noteDatasetUsed()
            setDatasetName("Dill")
            waitASecond()
            noteDatasetUsed()
            setDatasetName("Potato")
            assertEquals(listOf("Potato", "Dill", "Vinegar", "Salad"), getPreviousDatasetNames())
        }
    }

    @Test
    fun testScaleMarkLength() {
        runTest {
            setScaleMarkLength(5.3f)
            assertEquals(5.3f, getScaleMarkLength())

            setScaleMarkLength(241.234f)
            assertEquals(241.234f, getScaleMarkLength())

            setScaleMarkLength(0f)
            assertEquals(10f, getScaleMarkLength())

            setScaleMarkLength(-5f)
            assertEquals(10f, getScaleMarkLength())
        }
    }

    @Test
    fun testScaleLengthUnit() {
        runTest {
            setScaleLengthUnit("mm")
            assertEquals("mm", getScaleLengthUnit())

            setScaleLengthUnit("ft")
            assertEquals("ft", getScaleLengthUnit())

            setScaleLengthUnit(" \n ")
            assertEquals("cm", getScaleLengthUnit())
        }
    }

    @Test
    fun testNextSampleNumber() {
        runTest {
            setNextSampleNumber(12)
            assertEquals(12, getNextSampleNumber())

            setNextSampleNumber(0)
            assertEquals(1, getNextSampleNumber())

            setNextSampleNumber(-5)
            assertEquals(1, getNextSampleNumber())

            incrementSampleNumber()
            assertEquals(2, getNextSampleNumber())

            setNextSampleNumber(25)
            assertEquals(25, getNextSampleNumber())

            setDatasetName("Potato")
            assertEquals(1, getNextSampleNumber())

            setNextSampleNumber(12)
            assertEquals(12, getNextSampleNumber())

            setDatasetName("Herbivory Data")
            assertEquals(25, getNextSampleNumber())

            setDatasetName("Potato")
            assertEquals(12, getNextSampleNumber())
        }
    }

    @Test
    fun testScanBarcodes() {
        runTest {
            setUseBarcode(true)
            assertTrue(getUseBarcode())

            setUseBarcode(false)
            assertFalse(getUseBarcode())
        }
    }

    @Test
    fun testGpsLocation() {
        runTest {
            setSaveGpsData(true)
            assertTrue(getSaveGpsData())

            setSaveGpsData(false)
            assertFalse(getSaveGpsData())
        }
    }

    @Test
    fun testUseBlackBackground() {
        runTest {
            setUseBlackBackground(true)
            assertTrue(getUseBlackBackground())

            setUseBlackBackground(false)
            assertFalse(getUseBlackBackground())
        }
    }
}
