package com.thebluefolderproject.leafbyte

import android.app.Activity
import android.content.Context
import java.lang.IllegalArgumentException

class Preferences(val activity: Activity) {
    val sharedPreferences = activity.getPreferences(Context.MODE_PRIVATE)

    // technically these aren't constants, but they fundamentally are, so they're cased as such
    val dataSaveLocationKey = activity.getString(R.string.preferences_data_save_location_key)
    val imageSaveLocationKey = activity.getString(R.string.preferences_image_save_location_key)
    val datasetNameKey = activity.getString(R.string.preferences_dataset_name_key)
    val usePreviousDatasetKey = activity.getString(R.string.preferences_use_previous_dataset_key)
    val scaleLengthKey = activity.getString(R.string.preferences_scale_length_key)
    val scaleLengthUnitsKey = activity.getString(R.string.preferences_scale_length_units_key)
    val nextSampleNumberKey = activity.getString(R.string.preference_next_sample_number_key)
    val scanBarcodesKey = activity.getString(R.string.preference_scan_barcodes_key)
    val saveGpsLocationKey = activity.getString(R.string.preference_save_gps_location_key)
    val useBlackBackgroundKey = activity.getString(R.string.preference_use_black_background_key)
    val signOutOfGoogleKey = activity.getString(R.string.preference_sign_out_of_google_key)
    val websiteKeys = activity.getString(R.string.preference_website_key)
    val teamKey = activity.getString(R.string.preference_team_key)
    val citationKey = activity.getString(R.string.preference_citation_key)
    val versionKey = activity.getString(R.string.preference_version_key)
    // it feels like there should be a better way to get all preferences, and
    //   preferenceScreen.sharedPreferences.all does exist, but it skips any pseudo-preferences
    //   that are classed as plain Preference
    val allKeys = listOf(
        dataSaveLocationKey,
        imageSaveLocationKey,
        datasetNameKey,
        usePreviousDatasetKey,
        scaleLengthKey,
        scaleLengthUnitsKey,
        nextSampleNumberKey,
        scanBarcodesKey,
        saveGpsLocationKey,
        useBlackBackgroundKey,
        signOutOfGoogleKey,
        websiteKeys,
        teamKey,
        citationKey,
        versionKey)

    val saveLocationDefault = SaveLocation.fromKey(
        activity.getString(R.string.preferences_save_location_default_array_key),
        activity)
    val datasetNameDefault = activity.getString(R.string.preferences_dataset_name_default)
    val scaleLengthDefault = activity.getString(R.string.preferences_scale_length_default).toFloat()
    val scaleLengthUnitsDefault = ScaleLengthUnits.fromKey(
        activity.getString(R.string.preferences_scale_length_units_default_array_key),
        activity)
    val nextSampleNumberDefault = activity.resources.getInteger(R.integer.preference_next_sample_number_default)
    val scanBarcodesDefault = activity.resources.getBoolean(R.bool.preference_scan_barcodes_default)
    val saveGpsLocationDefault = activity.resources.getBoolean(R.bool.preference_save_gps_location_default)
    val useBlackBackgroundDefault = activity.resources.getBoolean(R.bool.preference_use_black_background_default)

    enum class SaveLocation(val keyId: Int) {
        NONE(R.string.preferences_save_location_none_array_key),
        LOCAL(R.string.preferences_save_location_local_array_key),
        GOOGLE_DRIVE(R.string.preferences_save_location_google_drive_array_key),
        ;

        companion object {
            fun fromKey(key: String, activity: Activity): SaveLocation {
                values().forEach { saveLocation ->
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
                values().forEach { scaleLengthUnits ->
                    if (activity.getString(scaleLengthUnits.keyId) == key) {
                        return scaleLengthUnits
                    }
                }

                throw IllegalArgumentException("Unknown scale length units key: $key")
            }
        }
    }

    fun dataSaveLocation(): SaveLocation {
        val dataSaveLocation = sharedPreferences.getString(dataSaveLocationKey, null)
        return dataSaveLocation
            ?.let { SaveLocation.fromKey(it, activity) }
            ?: saveLocationDefault
    }

    fun imageSaveLocation(): SaveLocation {
        val imageSaveLocation = sharedPreferences.getString(imageSaveLocationKey, null)
        return imageSaveLocation
            ?.let { SaveLocation.fromKey(it, activity) }
            ?: saveLocationDefault
    }

    fun datasetName(): String {
        return sharedPreferences.getString(datasetNameKey, datasetNameDefault)!!
    }

    fun scaleLength(): Float {
        return sharedPreferences.getString(scaleLengthKey, null)?.toFloatOrNull()
            ?: scaleLengthDefault
    }

    fun scaleLengthUnits(): ScaleLengthUnits {
        val scaleLengthUnits = sharedPreferences.getString(scaleLengthUnitsKey, null)
        return scaleLengthUnits
            ?.let { ScaleLengthUnits.fromKey(it, activity) }
            ?: scaleLengthUnitsDefault
    }

    fun nextSampleNumber(): Int {
        return sharedPreferences.getInt(nextSampleNumberKey, nextSampleNumberDefault)
    }

    fun scanBarcodes(): Boolean {
        return sharedPreferences.getBoolean(scanBarcodesKey, scanBarcodesDefault)
    }

    fun saveGpsLocation(): Boolean {
        return sharedPreferences.getBoolean(saveGpsLocationKey, saveGpsLocationDefault)
    }

    fun useBlackBackground(): Boolean {
        return sharedPreferences.getBoolean(useBlackBackgroundKey, useBlackBackgroundDefault)
    }
}