/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.getSaveLocationsDescription
import org.junit.jupiter.api.Test
import kotlin.test.assertContains

class SaveLocationsDescriptionTests {
    @Test
    fun testSameSaveLocations() {
        checkDescription(SaveLocation.NONE, SaveLocation.NONE, "Data and images are not being saved. Go to Settings to change.")
        checkDescription(SaveLocation.LOCAL, SaveLocation.LOCAL, "Saving data and images to My Files under the name Test dataset name.")
        checkDescription(
            SaveLocation.GOOGLE_DRIVE,
            SaveLocation.GOOGLE_DRIVE,
            "Saving data and images to Google Drive under the name Test dataset name.",
        )
    }

    @Test
    fun testNotSavingDataOnly() {
        checkDescription(
            SaveLocation.NONE,
            SaveLocation.LOCAL,
            "Data is not being saved. Go to Settings to change.\nSaving images to My Files under the name Test dataset name.",
        )
        checkDescription(
            SaveLocation.NONE,
            SaveLocation.GOOGLE_DRIVE,
            "Data is not being saved. Go to Settings to change.\nSaving images to Google Drive under the name Test dataset name.",
        )
    }

    @Test
    fun testNotSavingImagesOnly() {
        checkDescription(
            SaveLocation.LOCAL,
            SaveLocation.NONE,
            "Saving data to My Files under the name Test dataset name.\nImages are not being saved. Go to Settings to change.",
        )
        checkDescription(
            SaveLocation.GOOGLE_DRIVE,
            SaveLocation.NONE,
            "Saving data to Google Drive under the name Test dataset name.\nImages are not being saved. Go to Settings to change.",
        )
    }

    @Test
    fun testSavingToDifferentLocations() {
        checkDescription(
            SaveLocation.LOCAL,
            SaveLocation.GOOGLE_DRIVE,
            "Saving data to My Files and images to Google Drive under the name Test dataset name.",
        )
        checkDescription(
            SaveLocation.GOOGLE_DRIVE,
            SaveLocation.LOCAL,
            "Saving data to Google Drive and images to My Files under the name Test dataset name.",
        )
    }

    fun checkDescription(
        dataSaveLocation: SaveLocation,
        imageSaveLocation: SaveLocation,
        expectedDescription: String,
    ) {
        val description =
            getSaveLocationsDescription(
                dataSaveLocation = dataSaveLocation,
                imageSaveLocation = imageSaveLocation,
                datasetName = "Test dataset name",
            ).text
        assertContains(description, expectedDescription)
    }
}
