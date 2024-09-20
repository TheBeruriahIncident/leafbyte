/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.activity.LeafByteActivity
import com.thebluefolderproject.leafbyte.activity.Preferences
import de.mannodermaus.junit5.ActivityScenarioExtension
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension

/**
 * This class intentionally uses some literals and avoids using some constants from Preferences
 * to be sure everything is working exactly as expected.
 */
class PreferencesTest {
    @JvmField
    @RegisterExtension
    val activityScenarioExtension = ActivityScenarioExtension.launch<LeafByteActivity>()

    private fun helper(test: (preferences: Preferences, set: (key: Int, value: Any) -> Unit) -> Unit) {
        activityScenarioExtension.scenario.onActivity { activity ->
            val preferences = Preferences(activity)
            val sharedPreferences = preferences.sharedPreferences

            test(preferences) { unresolvedKey, value ->
                val key = activity.getString(unresolvedKey)
                val editor = sharedPreferences.edit()

                when (value) {
                    is String -> editor.putString(key, value)
                    is Int -> editor.putInt(key, value)
                    is Boolean -> editor.putBoolean(key, value)
                    is Float -> editor.putFloat(key, value)
                    else -> throw UnsupportedOperationException()
                }.apply()
            }

            // wipe any existing preferences to be simple and predictable
            sharedPreferences.edit().clear().apply()
        }
    }

    @Test
    fun testDefaultValues() {
        helper { preferences, _ ->
            assertEquals(Preferences.SaveLocation.NONE, preferences.dataSaveLocation())
            assertEquals(Preferences.SaveLocation.NONE, preferences.imageSaveLocation())
            assertEquals("Herbivory Data", preferences.datasetName())
            assertEquals(10f, preferences.scaleLength())
            assertEquals(Preferences.ScaleLengthUnits.CM, preferences.scaleLengthUnits())
            assertEquals(1, preferences.nextSampleNumber())
            assertFalse(preferences.scanBarcodes())
            assertFalse(preferences.saveGpsLocation())
            assertFalse(preferences.useBlackBackground())
        }
    }

    @Test
    fun testDataSaveLocation() {
        helper { preferences, set ->
            set(R.string.preferences_data_save_location_key, "google_drive")
            assertEquals(Preferences.SaveLocation.GOOGLE_DRIVE, preferences.dataSaveLocation())

            set(R.string.preferences_data_save_location_key, "local")
            assertEquals(Preferences.SaveLocation.LOCAL, preferences.dataSaveLocation())

            set(R.string.preferences_data_save_location_key, "none")
            assertEquals(Preferences.SaveLocation.NONE, preferences.dataSaveLocation())
        }
    }

    @Test
    fun testImageSaveLocation() {
        helper { preferences, set ->
            set(R.string.preferences_image_save_location_key, "google_drive")
            assertEquals(Preferences.SaveLocation.GOOGLE_DRIVE, preferences.imageSaveLocation())

            set(R.string.preferences_image_save_location_key, "local")
            assertEquals(Preferences.SaveLocation.LOCAL, preferences.imageSaveLocation())

            set(R.string.preferences_image_save_location_key, "none")
            assertEquals(Preferences.SaveLocation.NONE, preferences.imageSaveLocation())
        }
    }

    @Test
    fun testDatasetName() {
        helper { preferences, set ->
            set(R.string.preferences_dataset_name_key, "Potato")
            assertEquals("Potato", preferences.datasetName())

            set(R.string.preferences_dataset_name_key, "Salad")
            assertEquals("Salad", preferences.datasetName())
        }
    }

    @Test
    fun testScaleLength() {
        helper { preferences, set ->
            set(R.string.preferences_scale_length_key, 5.3f)
            assertEquals(5.3f, preferences.scaleLength())

            set(R.string.preferences_scale_length_key, 241.234f)
            assertEquals(241.234f, preferences.scaleLength())
        }
    }

    @Test
    fun testScaleLengthUnits() {
        helper { preferences, set ->
            set(R.string.preferences_scale_length_units_key, "mm")
            assertEquals(Preferences.ScaleLengthUnits.MM, preferences.scaleLengthUnits())

            set(R.string.preferences_scale_length_units_key, "ft")
            assertEquals(Preferences.ScaleLengthUnits.FT, preferences.scaleLengthUnits())
        }
    }

    @Test
    fun testNextSampleNumber() {
        helper { preferences, set ->
            set(R.string.preference_next_sample_number_key, 12)
            assertEquals(12, preferences.nextSampleNumber())

            set(R.string.preference_next_sample_number_key, 25)
            assertEquals(25, preferences.nextSampleNumber())
        }
    }

    @Test
    fun testScanBarcodes() {
        helper { preferences, set ->
            set(R.string.preference_scan_barcodes_key, true)
            assertEquals(true, preferences.scanBarcodes())

            set(R.string.preference_scan_barcodes_key, false)
            assertEquals(false, preferences.scanBarcodes())
        }
    }

    @Test
    fun testGpsLocation() {
        helper { preferences, set ->
            set(R.string.preference_save_gps_location_key, true)
            assertEquals(true, preferences.saveGpsLocation())

            set(R.string.preference_save_gps_location_key, false)
            assertEquals(false, preferences.saveGpsLocation())
        }
    }

    @Test
    fun testUseBlackBackground() {
        helper { preferences, set ->
            set(R.string.preference_use_black_background_key, true)
            assertEquals(true, preferences.useBlackBackground())

            set(R.string.preference_use_black_background_key, false)
            assertEquals(false, preferences.useBlackBackground())
        }
    }
}
