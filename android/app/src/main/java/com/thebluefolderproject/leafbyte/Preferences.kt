package com.thebluefolderproject.leafbyte

import android.app.Activity
import android.content.Context
import androidx.core.util.Preconditions
import java.lang.IllegalArgumentException

class Preferences(val activity: Activity) {
    val sharedPreferences = activity.getPreferences(Context.MODE_PRIVATE)

    // technically these aren't constants, but they fundamentally are, so they're cased as such
    val DATA_SAVE_LOCATION_KEY = activity.getString(R.string.preferences_data_save_location_key)
    val IMAGE_SAVE_LOCATION_KEY = activity.getString(R.string.preferences_image_save_location_key)
    val DATASET_NAME_KEY = activity.getString(R.string.preferences_dataset_name_key)
    val USE_PREVIOUS_DATASET_KEY = activity.getString(R.string.preferences_use_previous_dataset_key)
    val SCALE_LENGTH_KEY = activity.getString(R.string.preferences_scale_length_key)
    val SCALE_LENGTH_UNITS_KEY = activity.getString(R.string.preferences_scale_length_units_key)
    val NEXT_SAMPLE_NUMBER_KEY = activity.getString(R.string.preference_next_sample_number_key)
    val SCAN_BARCODES_KEY = activity.getString(R.string.preference_scan_barcodes_key)
    val SAVE_GPS_LOCATION_KEY = activity.getString(R.string.preference_save_gps_location_key)
    val BLACK_BACKGROUND_KEY = activity.getString(R.string.preference_use_black_background_key)
    val SIGN_OUT_OF_GOOGLE_KEY = activity.getString(R.string.preference_sign_out_of_google_key)
    val WEBSITE_KEY = activity.getString(R.string.preference_website_key)
    val TEAM_KEY = activity.getString(R.string.preference_team_key)
    val CITATION_KEY = activity.getString(R.string.preference_citation_key)
    val VERSION_KEY = activity.getString(R.string.preference_version_key)
    // it feels like there should be a better way to get all preferences, and
    //   preferenceScreen.sharedPreferences.all does exist, but it skips any pseudo-preferences
    //   that are classed as plain Preference
    val ALL_KEYS = listOf(
        DATA_SAVE_LOCATION_KEY,
        IMAGE_SAVE_LOCATION_KEY,
        DATASET_NAME_KEY,
        USE_PREVIOUS_DATASET_KEY,
        SCALE_LENGTH_KEY,
        SCALE_LENGTH_UNITS_KEY,
        NEXT_SAMPLE_NUMBER_KEY,
        SCAN_BARCODES_KEY,
        SAVE_GPS_LOCATION_KEY,
        BLACK_BACKGROUND_KEY,
        SIGN_OUT_OF_GOOGLE_KEY,
        WEBSITE_KEY,
        TEAM_KEY,
        CITATION_KEY,
        VERSION_KEY)

    enum class SaveLocation(val keyId: Int) {
        NONE(R.string.preferences_save_location_none_array_key),
        LOCAL(R.string.preferences_save_location_local_array_key),
        GOOGLE_DRIVE(R.string.preferences_save_location_google_drive_array_key),
        ;

        companion object {
            fun fromKey(key: String, activity: Activity): SaveLocation {
                SaveLocation.values().forEach { saveLocation ->
                    if (activity.getString(saveLocation.keyId) == key) {
                        return saveLocation
                    }
                }

                throw IllegalArgumentException("Unknown save location key: $key")
            }
        }
    }

    enum class ScaleLengthUnits(val keyId: Int) {
        MM(R.string.preferences_scale_length_units_mm_array_key),
        CM(R.string.preferences_scale_length_units_cm_array_key),
        M(R.string.preferences_scale_length_units_m_array_key),
        IN(R.string.preferences_scale_length_units_in_array_key),
        FT(R.string.preferences_scale_length_units_ft_array_key),
        ;

        companion object {
            fun fromKey(key: String, activity: Activity): ScaleLengthUnits {
                ScaleLengthUnits.values().forEach { scaleLengthUnits ->
                    if (activity.getString(scaleLengthUnits.keyId) == key) {
                        return scaleLengthUnits
                    }
                }

                throw IllegalArgumentException("Unknown scale length units key: $key")
            }
        }
    }

    fun dataSaveLocation(): SaveLocation {
        return SaveLocation.fromKey(
            sharedPreferences.getString(DATA_SAVE_LOCATION_KEY, null)!!,
            activity)
    }

    fun imageSaveLocation(): SaveLocation {
        return SaveLocation.fromKey(
            sharedPreferences.getString(IMAGE_SAVE_LOCATION_KEY, null)!!,
            activity)
    }

    fun datasetName(): String {
        return sharedPreferences.getString(DATASET_NAME_KEY, null)!!
    }

    fun scaleLength(): Int {
        checkState(sharedPreferences.contains(SCALE_LENGTH_KEY), "Scale length key is unknown")
        return sharedPreferences.getInt(SCALE_LENGTH_KEY, -1)
    }

    fun scaleLengthUnits(): ScaleLengthUnits {
        return ScaleLengthUnits.fromKey(
            sharedPreferences.getString(SCALE_LENGTH_UNITS_KEY, null)!!,
            activity)
    }

    fun nextSampleNumber(): Int {
        checkState(sharedPreferences.contains(NEXT_SAMPLE_NUMBER_KEY), "Next sample number key is unknown")
        return sharedPreferences.getInt(NEXT_SAMPLE_NUMBER_KEY, -1)
    }

    fun scanBarcodes(): Boolean {
        checkState(sharedPreferences.contains(SCAN_BARCODES_KEY), "Scan barcodes key is unknown")
        return sharedPreferences.getBoolean(SCAN_BARCODES_KEY, false)
    }

    fun saveGpsLocation(): Boolean {
        checkState(sharedPreferences.contains(SAVE_GPS_LOCATION_KEY), "Save GPS location key is unknown")
        return sharedPreferences.getBoolean(SAVE_GPS_LOCATION_KEY, false)
    }

    fun blackBackground(): Boolean {
        checkState(sharedPreferences.contains(BLACK_BACKGROUND_KEY), "Black background key is unknown")
        return sharedPreferences.getBoolean(BLACK_BACKGROUND_KEY, false)
    }
}