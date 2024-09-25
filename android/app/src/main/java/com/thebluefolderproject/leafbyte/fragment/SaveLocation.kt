package com.thebluefolderproject.leafbyte.fragment

import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSaveLocation

enum class SaveLocation(val serialized: SerializedSaveLocation) {
    NONE(SerializedSaveLocation.NONE),
    LOCAL(SerializedSaveLocation.LOCAL),
    GOOGLE_DRIVE(SerializedSaveLocation.GOOGLE_DRIVE);

    companion object {
        private val DEFAULT_SAVE_LOCATION = LOCAL

        fun fromSerialized(serialized: SerializedSaveLocation): SaveLocation {
            return when(serialized) {
                SerializedSaveLocation.UNRECOGNIZED -> DEFAULT_SAVE_LOCATION
                SerializedSaveLocation.UNSPECIFIED -> DEFAULT_SAVE_LOCATION
                SerializedSaveLocation.NONE -> NONE
                SerializedSaveLocation.LOCAL -> LOCAL
                SerializedSaveLocation.GOOGLE_DRIVE -> GOOGLE_DRIVE
            }
        }
    }
}