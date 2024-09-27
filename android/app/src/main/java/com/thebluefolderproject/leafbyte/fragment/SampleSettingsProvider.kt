package com.thebluefolderproject.leafbyte.fragment

import androidx.compose.ui.tooling.preview.PreviewParameterProvider

@Suppress("MagicNumber")
class SampleSettingsProvider : PreviewParameterProvider<Settings> {
    override val values: Sequence<Settings>
        get() {
            val sampleSettings: Settings =
                object : Settings {
                    override var dataSaveLocation: SaveLocation
                        get() = SaveLocation.GOOGLE_DRIVE
                        set(_) {}
                    override var imageSaveLocation: SaveLocation
                        get() = SaveLocation.LOCAL
                        set(_) {}
                    override var datasetName: String
                        get() = "Test data"
                        set(_) {}

                    override fun noteDatasetUsed() {
                        throw NotImplementedError()
                    }

                    override val previousDatasetNames: List<String>
                        get() = listOf("Test data", "Old test", "Herbivory Data")
                    override var scaleMarkLength: Float
                        get() = 20f
                        set(_) {}
                    override var scaleLengthUnit: String
                        get() = "cm"
                        set(_) {}
                    override var nextSampleNumber: Int
                        get() = 4
                        set(_) {}

                    override fun incrementSampleNumber() {
                        throw NotImplementedError()
                    }

                    override var useBarcode: Boolean
                        get() = false
                        set(_) {}
                    override var saveGpsData: Boolean
                        get() = true
                        set(_) {}
                    override var useBlackBackground: Boolean
                        get() = false
                        set(_) {}
                }

            return sequenceOf(sampleSettings)
        }
}
