/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.settings

import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import net.openid.appauth.AuthState

@Suppress("detekt:style:MagicNumber")
open class MockSettings(
    val dataSaveLocation: SaveLocation = SaveLocation.LOCAL,
    val imageSaveLocation: SaveLocation = SaveLocation.GOOGLE_DRIVE,
    val useBarcode: Boolean = true,
) : Settings {
    override fun getDataSaveLocation(): Flow<SaveLocation> = flowOf(dataSaveLocation)

    override fun setDataSaveLocation(newDataSaveLocation: SaveLocation) {
        TODO("Not yet implemented")
    }

    override fun getImageSaveLocation(): Flow<SaveLocation> = flowOf(imageSaveLocation)

    override fun setImageSaveLocation(newImageSaveLocation: SaveLocation) {
        TODO("Not yet implemented")
    }

    override fun getDatasetName(): Flow<String> = flowOf("Herbvar collection")

    override fun setDatasetName(newDatasetName: String) {
        TODO("Not yet implemented")
    }

    override fun noteDatasetUsed() {
        TODO("Not yet implemented")
    }

    override fun getPreviousDatasetNames(): Flow<ImmutableList<String>> = flowOf(persistentListOf("Herbivory data", "Herbvar"))

    override fun getScaleMarkLength(): Flow<Float> = flowOf(15f)

    override fun setScaleMarkLength(newScaleMarkLength: Float) {
        TODO("Not yet implemented")
    }

    override fun getScaleLengthUnit(): Flow<String> = flowOf("in")

    override fun setScaleLengthUnit(newScaleLengthUnit: String) {
        TODO("Not yet implemented")
    }

    override fun getNextSampleNumber(): Flow<Int> = flowOf(12)

    override fun setNextSampleNumber(newNextSampleNumber: Int) {
        TODO("Not yet implemented")
    }

    override fun incrementSampleNumber() {
        TODO("Not yet implemented")
    }

    override fun getUseBarcode(): Flow<Boolean> = flowOf(useBarcode)

    override fun setUseBarcode(newUseBarcode: Boolean) {
        TODO("Not yet implemented")
    }

    override fun getSaveGpsData(): Flow<Boolean> = flowOf(false)

    override fun setSaveGpsData(newSaveGpsData: Boolean) {
        TODO("Not yet implemented")
    }

    override fun getUseBlackBackground(): Flow<Boolean> = flowOf(true)

    override fun setUseBlackBackground(newUseBlackBackground: Boolean) {
        TODO("Not yet implemented")
    }

    override fun getAuthState(): Flow<AuthState> = flowOf(AuthState())

    override fun setAuthState(newAuthState: AuthState) {
        TODO("Not yet implemented")
    }
}
