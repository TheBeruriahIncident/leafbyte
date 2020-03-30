package com.thebluefolderproject.leafbyte

import android.app.Activity
import android.content.Context
import android.content.SharedPreferences
import androidx.test.internal.runner.junit4.AndroidJUnit4ClassRunner
import androidx.test.rule.ActivityTestRule

import org.junit.Test
import org.junit.runner.RunWith

import org.junit.Assert.*
import org.junit.Before
import org.junit.Rule

/**
 * This class intentionally uses some literals and avoids using some constants from Preferences
 * to be sure everything is working exactly as expected.
 */
@RunWith(AndroidJUnit4ClassRunner::class)
class PreferencesTest {
    @get:Rule var activityTestRule = ActivityTestRule(LeafByteActivity::class.java)

    lateinit var activity: Activity
    lateinit var preferences: Preferences
    lateinit var sharedPreferences: SharedPreferences

    @Before
    fun before() {
        activity = activityTestRule.activity
        preferences = Preferences(activity)
        sharedPreferences = activity.getPreferences(Context.MODE_PRIVATE)

        // wipe any existing preferences to be simple and predictable
        sharedPreferences.edit().clear().apply()
    }

    @Test
    fun testDefaultValues() {
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

    @Test
    fun testDataSaveLocation() {
        set(R.string.preferences_data_save_location_key, "google_drive")
        assertEquals(Preferences.SaveLocation.GOOGLE_DRIVE, preferences.dataSaveLocation())

        set(R.string.preferences_data_save_location_key, "local")
        assertEquals(Preferences.SaveLocation.LOCAL, preferences.dataSaveLocation())

        set(R.string.preferences_data_save_location_key, "none")
        assertEquals(Preferences.SaveLocation.NONE, preferences.dataSaveLocation())
    }

    @Test
    fun testImageSaveLocation() {
        set(R.string.preferences_image_save_location_key, "google_drive")
        assertEquals(Preferences.SaveLocation.GOOGLE_DRIVE, preferences.imageSaveLocation ())

        set(R.string.preferences_image_save_location_key, "local")
        assertEquals(Preferences.SaveLocation.LOCAL, preferences.imageSaveLocation())

        set(R.string.preferences_image_save_location_key, "none")
        assertEquals(Preferences.SaveLocation.NONE, preferences.imageSaveLocation())
    }

    @Test
    fun testDatasetName() {
        set(R.string.preferences_dataset_name_key, "Potato")
        assertEquals("Potato", preferences.datasetName())

        set(R.string.preferences_dataset_name_key, "Salad")
        assertEquals("Salad", preferences.datasetName())
    }

    @Test
    fun testScaleLength() {
        set(R.string.preferences_scale_length_key, 5.3f)
        assertEquals(5.3f, preferences.scaleLength())

        set(R.string.preferences_scale_length_key, 241.234f)
        assertEquals(241.234f, preferences.scaleLength())
    }

    @Test
    fun testScaleLengthUnits() {
        set(R.string.preferences_scale_length_units_key, "mm")
        assertEquals(Preferences.ScaleLengthUnits.MM, preferences.scaleLengthUnits())

        set(R.string.preferences_scale_length_units_key, "ft")
        assertEquals(Preferences.ScaleLengthUnits.FT, preferences.scaleLengthUnits())
    }

    @Test
    fun testNextSampleNumber() {
        set(R.string.preference_next_sample_number_key, 12)
        assertEquals(12, preferences.nextSampleNumber())

        set(R.string.preference_next_sample_number_key, 25)
        assertEquals(25, preferences.nextSampleNumber())
    }

    @Test
    fun testScanBarcodes() {
        set(R.string.preference_scan_barcodes_key, true)
        assertEquals(true, preferences.scanBarcodes())

        set(R.string.preference_scan_barcodes_key, false)
        assertEquals(false, preferences.scanBarcodes())
    }

    @Test
    fun testGpsLocation() {
        set(R.string.preference_save_gps_location_key, true)
        assertEquals(true, preferences.saveGpsLocation())

        set(R.string.preference_save_gps_location_key, false)
        assertEquals(false, preferences.saveGpsLocation())
    }

    @Test
    fun testUseBlackBackground() {
        set(R.string.preference_use_black_background_key, true)
        assertEquals(true, preferences.useBlackBackground())

        set(R.string.preference_use_black_background_key, false)
        assertEquals(false, preferences.useBlackBackground())
    }

    private fun set(key: Int, value: String) {
        sharedPreferences.edit()
            .putString(activity.getString(key), value)
            .apply()
    }

    private fun set(key: Int, value: Int) {
        sharedPreferences.edit()
            .putInt(activity.getString(key), value)
            .apply()
    }

    private fun set(key: Int, value: Boolean) {
        sharedPreferences.edit()
            .putBoolean(activity.getString(key), value)
            .apply()
    }

    private fun set(key: Int, value: Float) {
        sharedPreferences.edit()
            .putString(activity.getString(key), value.toString())
            .apply()
    }
}
