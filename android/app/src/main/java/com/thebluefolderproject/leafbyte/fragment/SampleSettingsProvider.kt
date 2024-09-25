package com.thebluefolderproject.leafbyte.fragment

import androidx.compose.ui.tooling.preview.PreviewParameterProvider

class SampleSettingsProvider : PreviewParameterProvider<Settings> {
    override val values: Sequence<Settings>
        get() {
            val sampleSettings: Settings =
                object : Settings {
                    override var dataSaveLocation: SaveLocation
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override var imageSaveLocation: SaveLocation
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override var datasetName: String
                        get() = TODO("Not yet implemented")
                        set(value) {}

                    override fun noteDatasetUsed() {
                        TODO("Not yet implemented")
                    }

                    override val previousDatasetNames: List<String>
                        get() = TODO("Not yet implemented")
                    override var scaleMarkLength: Float
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override var unit: String
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override val nextSampleNumber: Int
                        get() = TODO("Not yet implemented")

                    override fun incrementSampleNumber() {
                        TODO("Not yet implemented")
                    }

                    override var useBarcode: Boolean
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override var saveGpsData: Boolean
                        get() = TODO("Not yet implemented")
                        set(value) {}
                    override var useBlackBackground: Boolean
                        get() = TODO("Not yet implemented")
                        set(value) {}
                }

            return sequenceOf(sampleSettings)
        }
}
