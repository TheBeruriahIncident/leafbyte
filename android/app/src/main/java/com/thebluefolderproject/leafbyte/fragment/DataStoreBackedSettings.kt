package com.thebluefolderproject.leafbyte.fragment

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking

private const val DATA_STORE_FILE_NAME = "settings.pb"

/**
 * This is declared outside the class so that only one DataStore can exist, per
 * https://developer.android.com/topic/libraries/architecture/datastore#correct_usage
 */
private val Context.settingsStore: DataStore<SerializedSettings> by dataStore(
    fileName = DATA_STORE_FILE_NAME,
    serializer = SerializedSettingsSerializer,
)

private const val DEFAULT_DATASET_NAME = "Herbivory Data"
private const val DEFAULT_NEXT_SAMPLE_NUMBER = 1
private const val DEFAULT_SCALE_MARK_LENGTH = 10.0f
private const val DEFAULT_UNIT = "cm"

/**
 * This class wraps the data store logic (https://developer.android.com/topic/libraries/architecture/datastore) and ensures that all writes
 * are immediately persisted, and all reads are fresh.
 */
class DataStoreBackedSettings(context: Context) : Settings {
    private val settingsStore = context.settingsStore
    private var cachedSerializedSettings: SerializedSettings? = null

    private val serializedSettings: SerializedSettings
        get() {
            if (cachedSerializedSettings == null) {
                cachedSerializedSettings = runBlocking { settingsStore.data.first() }
            }
            return cachedSerializedSettings!!
        }
    private fun edit(edit: (SerializedSettings.Builder) -> SerializedSettings.Builder) {
        cachedSerializedSettings = null // invalidate the cache

        runBlocking {
            settingsStore.updateData { currentSerializedSettings ->
                val settingsBuilder = currentSerializedSettings.toBuilder()
                edit(settingsBuilder).build() }
        }
    }

    override var dataSaveLocation: SaveLocation
        get() = SaveLocation.fromSerialized(serializedSettings.dataSaveLocation)
        set(newDataSaveLocation) {
            edit { builder -> builder.setDataSaveLocation(newDataSaveLocation.serialized)}
        }

    override var imageSaveLocation: SaveLocation
        get() = SaveLocation.fromSerialized(serializedSettings.imageSaveLocation)
        set(newImageSaveLocation) {
            edit { builder -> builder.setImageSaveLocation(newImageSaveLocation.serialized)}
        }

    override var datasetName: String
        get() = normalizeDatasetName(serializedSettings.datasetName)
        set(unnormalizedNewDatasetName) {
            val newDatasetName = normalizeDatasetName(unnormalizedNewDatasetName)
            edit { builder -> builder.setDatasetName(newDatasetName)}
        }
    fun normalizeDatasetName(datasetName: String) =
        datasetName.ifBlank { DEFAULT_DATASET_NAME }

    override fun noteDatasetUsed() {
        val epochTimeInSeconds = System.currentTimeMillis() / 1000
        edit { builder -> builder.putDatasetNameToEpochTimeOfLastUse(datasetName, epochTimeInSeconds)}
    }
    override val previousDatasetNames: List<String>
        get() {
            // Sort the dataset names by last use, excluding the current dataset
            val otherDatasetNames = serializedSettings.datasetNameToEpochTimeOfLastUseMap.toList()
                .sortedBy { nameToTime -> nameToTime.second }
                .map { it.first }
                .filter { it != datasetName }
            // The current dataset is always listed first
            return listOf(datasetName) + otherDatasetNames
        }

    override var scaleMarkLength: Float
        get() = normalizeScaleMarkLength(serializedSettings.scaleMarkLength)
        set(unnormalizedNewScaleMarkLength) {
            val newScaleMarkLength = normalizeScaleMarkLength(unnormalizedNewScaleMarkLength)
            edit { builder -> builder.setScaleMarkLength(newScaleMarkLength)}
        }
    fun normalizeScaleMarkLength(scaleMarkLength: Float) =
        if(scaleMarkLength <= 0) DEFAULT_SCALE_MARK_LENGTH else scaleMarkLength

    override var unit: String
        get() = normalizeUnit(serializedSettings.getDatasetNameToUnitOrDefault(datasetName, DEFAULT_UNIT))
        set(unnormalizedNewUnit) {
            val newUnit = normalizeUnit(unnormalizedNewUnit)
            edit { builder -> builder.putDatasetNameToUnit(datasetName, newUnit)}
        }
    fun normalizeUnit(unit: String) =
        unit.ifBlank { DEFAULT_UNIT }

    override val nextSampleNumber: Int
        get() = serializedSettings.getDatasetNameToNextSampleNumberOrDefault(datasetName, DEFAULT_NEXT_SAMPLE_NUMBER)
    override fun incrementSampleNumber() {
        edit { builder ->  builder.putDatasetNameToNextSampleNumber(datasetName, nextSampleNumber + 1)}
    }

    override var useBarcode: Boolean
        get() = serializedSettings.useBarcode
        set(newUseBarcode) {
            edit { builder -> builder.setUseBarcode(newUseBarcode) }
        }

    override var saveGpsData: Boolean
        get() = serializedSettings.saveGpsData
        set(newSaveGpsData) {
            edit { builder -> builder.setSaveGpsData(newSaveGpsData) }
        }

    override var useBlackBackground: Boolean
        get() = serializedSettings.useBlackBackground
        set(newUseBlackBackground) {
            edit { builder -> builder.setUseBlackBackground(newUseBlackBackground) }
        }
}