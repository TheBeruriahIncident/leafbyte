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
            assertFlowEquals(SaveLocation.LOCAL, getDataSaveLocation())
            assertFlowEquals(SaveLocation.LOCAL, getImageSaveLocation())
            assertFlowEquals("Herbivory Data", getDatasetName())
            assertFlowEquals(10f, getScaleMarkLength())
            assertFlowEquals("cm", getScaleLengthUnit())
            assertFlowEquals(1, getNextSampleNumber())
            assertFlowFalse(getUseBarcode())
            assertFlowFalse(getSaveGpsData())
            assertFlowFalse(getUseBlackBackground())
        }
    }

    @Test
    fun testDataSaveLocation() {
        runTest {
            setDataSaveLocation(SaveLocation.GOOGLE_DRIVE)
            assertFlowEquals(SaveLocation.GOOGLE_DRIVE, getDataSaveLocation())

            setDataSaveLocation(SaveLocation.LOCAL)
            assertFlowEquals(SaveLocation.LOCAL, getDataSaveLocation())

            setDataSaveLocation(SaveLocation.NONE)
            assertFlowEquals(SaveLocation.NONE, getDataSaveLocation())
        }
    }

    @Test
    fun testImageSaveLocation() {
        runTest {
            setImageSaveLocation(SaveLocation.GOOGLE_DRIVE)
            assertFlowEquals(SaveLocation.GOOGLE_DRIVE, getImageSaveLocation())

            setImageSaveLocation(SaveLocation.LOCAL)
            assertFlowEquals(SaveLocation.LOCAL, getImageSaveLocation())

            setImageSaveLocation(SaveLocation.NONE)
            assertFlowEquals(SaveLocation.NONE, getImageSaveLocation())
        }
    }

    @Test
    fun testDatasetName() {
        runTest {
            setDatasetName("Potato")
            assertFlowEquals("Potato", getDatasetName())

            setDatasetName("Salad")
            assertFlowEquals("Salad", getDatasetName())

            setDatasetName("")
            assertFlowEquals("Herbivory Data", getDatasetName())

            setDatasetName("    \n   ")
            assertFlowEquals("Herbivory Data", getDatasetName())

            // confirm unicode roundtrips properly
            setDatasetName("שלום jalapeño 你好 ")
            assertFlowEquals("שלום jalapeño 你好 ", getDatasetName())
        }
    }

    /**
     * We sleep before calling noteDatasetUsed, because epoch time is in seconds, and we want to record a different second.
     */
    @Test
    fun testPreviousDatasetNames() {
        runTest {
            assertFlowEquals(listOf("Herbivory Data"), getPreviousDatasetNames())

            setDatasetName("Potato")
            assertFlowEquals(listOf("Potato"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertFlowEquals(listOf("Salad"), getPreviousDatasetNames())

            waitASecond()
            noteDatasetUsed()
            assertFlowEquals(listOf("Salad"), getPreviousDatasetNames())

            setDatasetName("Dill")
            assertFlowEquals(listOf("Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertFlowEquals(listOf("Salad"), getPreviousDatasetNames())

            setDatasetName("Dill")
            waitASecond()
            noteDatasetUsed()
            assertFlowEquals(listOf("Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Salad")
            assertFlowEquals(listOf("Salad", "Dill"), getPreviousDatasetNames())

            setDatasetName("Potato")
            assertFlowEquals(listOf("Potato", "Dill", "Salad"), getPreviousDatasetNames())

            setDatasetName("Vinegar")
            waitASecond()
            noteDatasetUsed()
            setDatasetName("Dill")
            waitASecond()
            noteDatasetUsed()
            setDatasetName("Potato")
            assertFlowEquals(listOf("Potato", "Dill", "Vinegar", "Salad"), getPreviousDatasetNames())
        }
    }

    @Test
    fun testScaleMarkLength() {
        runTest {
            setScaleMarkLength(5.3f)
            assertFlowEquals(5.3f, getScaleMarkLength())

            setScaleMarkLength(241.234f)
            assertFlowEquals(241.234f, getScaleMarkLength())

            setScaleMarkLength(0f)
            assertFlowEquals(10f, getScaleMarkLength())

            setScaleMarkLength(-5f)
            assertFlowEquals(10f, getScaleMarkLength())
        }
    }

    @Test
    fun testScaleLengthUnit() {
        runTest {
            setScaleLengthUnit("mm")
            assertFlowEquals("mm", getScaleLengthUnit())

            setScaleLengthUnit("ft")
            assertFlowEquals("ft", getScaleLengthUnit())

            setScaleLengthUnit(" \n ")
            assertFlowEquals("cm", getScaleLengthUnit())
        }
    }

    @Test
    fun testNextSampleNumber() {
        runTest {
            setNextSampleNumber(12)
            assertFlowEquals(12, getNextSampleNumber())

            setNextSampleNumber(0)
            assertFlowEquals(1, getNextSampleNumber())

            setNextSampleNumber(-5)
            assertFlowEquals(1, getNextSampleNumber())

            incrementSampleNumber()
            assertFlowEquals(2, getNextSampleNumber())

            setNextSampleNumber(25)
            assertFlowEquals(25, getNextSampleNumber())

            setDatasetName("Potato")
            assertFlowEquals(1, getNextSampleNumber())

            setNextSampleNumber(12)
            assertFlowEquals(12, getNextSampleNumber())

            setDatasetName("Herbivory Data")
            assertFlowEquals(25, getNextSampleNumber())

            setDatasetName("Potato")
            assertFlowEquals(12, getNextSampleNumber())
        }
    }

    @Test
    fun testScanBarcodes() {
        runTest {
            setUseBarcode(true)
            assertFlowTrue(getUseBarcode())

            setUseBarcode(false)
            assertFlowFalse(getUseBarcode())
        }
    }

    @Test
    fun testGpsLocation() {
        runTest {
            setSaveGpsData(true)
            assertFlowTrue(getSaveGpsData())

            setSaveGpsData(false)
            assertFlowFalse(getSaveGpsData())
        }
    }

    @Test
    fun testUseBlackBackground() {
        runTest {
            setUseBlackBackground(true)
            assertFlowTrue(getUseBlackBackground())

            setUseBlackBackground(false)
            assertFlowFalse(getUseBlackBackground())
        }
    }
}
