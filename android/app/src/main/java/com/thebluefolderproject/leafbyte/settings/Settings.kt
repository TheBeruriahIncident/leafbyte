/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.settings

import com.thebluefolderproject.leafbyte.settings.SaveLocation
import kotlinx.collections.immutable.ImmutableList
import kotlinx.coroutines.flow.Flow
import net.openid.appauth.AuthState

interface Settings {
    fun getDataSaveLocation(): Flow<SaveLocation>
    fun setDataSaveLocation(newDataSaveLocation: SaveLocation)

    fun getImageSaveLocation(): Flow<SaveLocation>
    fun setImageSaveLocation(newImageSaveLocation: SaveLocation)

    fun getDatasetName(): Flow<String>
    fun setDatasetName(newDatasetName: String)
    fun noteDatasetUsed()
    fun getPreviousDatasetNames(): Flow<ImmutableList<String>>

    fun getScaleMarkLength(): Flow<Float>
    fun setScaleMarkLength(newScaleMarkLength: Float)
    fun getScaleLengthUnit(): Flow<String>
    fun setScaleLengthUnit(newScaleLengthUnit: String)

    fun getNextSampleNumber(): Flow<Int>
    fun setNextSampleNumber(newNextSampleNumber: Int)
    fun incrementSampleNumber()

    fun getUseBarcode(): Flow<Boolean>
    fun setUseBarcode(newUseBarcode: Boolean)
    fun getSaveGpsData(): Flow<Boolean>
    fun setSaveGpsData(newSaveGpsData: Boolean)
    fun getUseBlackBackground(): Flow<Boolean>
    fun setUseBlackBackground(newUseBlackBackground: Boolean)

    fun getAuthState(): Flow<AuthState>
    fun setAuthState(newAuthState: AuthState)
}
