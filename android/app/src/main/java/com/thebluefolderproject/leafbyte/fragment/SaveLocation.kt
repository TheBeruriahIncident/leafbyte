/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSaveLocation

enum class SaveLocation(
    val serialized: SerializedSaveLocation,
    val userFacingName: String,
) {
    NONE(SerializedSaveLocation.NONE, "None"),
    LOCAL(SerializedSaveLocation.LOCAL, "My Files"),
    GOOGLE_DRIVE(SerializedSaveLocation.GOOGLE_DRIVE, "Google Drive"),
    ;

    companion object {
        private val DEFAULT_SAVE_LOCATION = LOCAL

        fun fromSerialized(serialized: SerializedSaveLocation): SaveLocation =
            when (serialized) {
                SerializedSaveLocation.UNRECOGNIZED -> DEFAULT_SAVE_LOCATION
                SerializedSaveLocation.UNSPECIFIED -> DEFAULT_SAVE_LOCATION
                SerializedSaveLocation.NONE -> NONE
                SerializedSaveLocation.LOCAL -> LOCAL
                SerializedSaveLocation.GOOGLE_DRIVE -> GOOGLE_DRIVE
            }
    }
}
