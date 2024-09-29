package com.thebluefolderproject.leafbyte.fragment

import androidx.compose.ui.tooling.preview.PreviewParameterProvider
import kotlinx.collections.immutable.ImmutableList
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf

@Suppress("MagicNumber")
class SampleSettingsProvider : PreviewParameterProvider<Settings> {
    override val values: Sequence<Settings>
        get() {
            val sampleSettings: Settings =
                object : Settings {
                    override fun getDataSaveLocation(): Flow<SaveLocation> {
                        return flowOf(SaveLocation.LOCAL)
                    }

                    override fun setDataSaveLocation(newDataSaveLocation: SaveLocation) {
                        TODO("Not yet implemented")
                    }

                    override fun getImageSaveLocation(): Flow<SaveLocation> {
                        return flowOf(SaveLocation.GOOGLE_DRIVE)
                    }

                    override fun setImageSaveLocation(newImageSaveLocation: SaveLocation) {
                        TODO("Not yet implemented")
                    }

                    override fun getDatasetName(): Flow<String> {
                        return flowOf("Herbvar collection")
                    }

                    override fun setDatasetName(newDatasetName: String) {
                        TODO("Not yet implemented")
                    }

                    override fun noteDatasetUsed() {
                        TODO("Not yet implemented")
                    }

                    override fun getPreviousDatasetNames(): Flow<ImmutableList<String>> {
                        TODO("Not yet implemented")
                    }

                    override fun getScaleMarkLength(): Flow<Float> {
                        return flowOf(15f)
                    }

                    override fun setScaleMarkLength(newScaleMarkLength: Float) {
                        TODO("Not yet implemented")
                    }

                    override fun getScaleLengthUnit(): Flow<String> {
                        return flowOf("in")
                    }

                    override fun setScaleLengthUnit(newScaleLengthUnit: String) {
                        TODO("Not yet implemented")
                    }

                    override fun getNextSampleNumber(): Flow<Int> {
                        return flowOf(12)
                    }

                    override fun setNextSampleNumber(newNextSampleNumber: Int) {
                        TODO("Not yet implemented")
                    }

                    override fun incrementSampleNumber() {
                        TODO("Not yet implemented")
                    }

                    override fun getUseBarcode(): Flow<Boolean> {
                        return flowOf(true)
                    }

                    override fun setUseBarcode(newUseBarcode: Boolean) {
                        TODO("Not yet implemented")
                    }

                    override fun getSaveGpsData(): Flow<Boolean> {
                        return flowOf(false)
                    }

                    override fun setSaveGpsData(newSaveGpsData: Boolean) {
                        TODO("Not yet implemented")
                    }

                    override fun getUseBlackBackground(): Flow<Boolean> {
                        return flowOf(true)
                    }

                    override fun setUseBlackBackground(newUseBlackBackground: Boolean) {
                        TODO("Not yet implemented")
                    }

                }

            return sequenceOf(sampleSettings)
        }
}
