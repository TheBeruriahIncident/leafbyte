package com.thebluefolderproject.leafbyte.fragment

interface Settings {
    var dataSaveLocation: SaveLocation
    var imageSaveLocation: SaveLocation

    var datasetName: String
    fun noteDatasetUsed()
    val previousDatasetNames: List<String>

    var scaleMarkLength: Float
    var scaleLengthUnit: String

    var nextSampleNumber: Int
    fun incrementSampleNumber()

    var useBarcode: Boolean
    var saveGpsData: Boolean
    var useBlackBackground: Boolean
}