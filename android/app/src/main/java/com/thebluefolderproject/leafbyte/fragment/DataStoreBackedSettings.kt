package com.thebluefolderproject.leafbyte.fragment

import android.content.Context
import android.os.Build
import androidx.annotation.OpenForTesting
import androidx.annotation.RequiresApi
import androidx.annotation.VisibleForTesting
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings
import com.thebluefolderproject.leafbyte.utils.log
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.nio.file.Files
import java.time.Instant
import java.util.concurrent.TimeUnit

private const val DATA_STORE_FILE_NAME = "settings.pb"

/**
 * This is declared outside the class so that only one DataStore can exist, per
 * https://developer.android.com/topic/libraries/architecture/datastore#correct_usage
 */
private val Context.settingsStore: DataStore<SerializedSettings> by dataStore(
    fileName = DATA_STORE_FILE_NAME,
    serializer = SerializedSettingsSerializer,
)
@VisibleForTesting
@RequiresApi(Build.VERSION_CODES.O)
fun clearSettingsStore(context: Context) {
    runBlocking { context.settingsStore.updateData { current -> current.toBuilder().clear().build() } }

    val preexistingSettings = context.dataDir.resolve("files/datastore/settings.pb")
    if (preexistingSettings.exists()) {
        Files.delete(preexistingSettings.toPath())
        log("Deleted preexisting settings file")
    }
}

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

    private fun edit(editAction: (SerializedSettings.Builder) -> SerializedSettings.Builder) {
        runBlocking {
            settingsStore.updateData { currentSerializedSettings ->
                val settingsBuilder = currentSerializedSettings.toBuilder()
                editAction(settingsBuilder).build()
            }
        }

        // We clear the cache after editing rather than before, because the editAction may itself call a getter and indirectly restore the
        //   cache, which leads to very cryptic inconsistent data.
        cachedSerializedSettings = null // invalidate the cache
    }

    override var dataSaveLocation: SaveLocation
        get() = SaveLocation.fromSerialized(serializedSettings.dataSaveLocation)
        set(newDataSaveLocation) {
            edit { builder -> builder.setDataSaveLocation(newDataSaveLocation.serialized) }
        }

    override var imageSaveLocation: SaveLocation
        get() = SaveLocation.fromSerialized(serializedSettings.imageSaveLocation)
        set(newImageSaveLocation) {
            edit { builder -> builder.setImageSaveLocation(newImageSaveLocation.serialized) }
        }

    override var datasetName: String
        get() = normalizeDatasetName(serializedSettings.datasetName)
        set(unnormalizedNewDatasetName) {
            val newDatasetName = normalizeDatasetName(unnormalizedNewDatasetName)
            edit { builder -> builder.setDatasetName(newDatasetName) }
        }
    private fun normalizeDatasetName(datasetName: String) = datasetName.ifBlank { DEFAULT_DATASET_NAME }

    override fun noteDatasetUsed() {
        val epochTimeInSeconds: Long
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            epochTimeInSeconds = Instant.now().epochSecond
        } else {
            epochTimeInSeconds = TimeUnit.MILLISECONDS.toMinutes(System.currentTimeMillis())
        }

        edit { builder -> builder.putDatasetNameToEpochTimeOfLastUse(datasetName, epochTimeInSeconds) }
    }
    override val previousDatasetNames: List<String>
        get() {
            // Sort the dataset names by last use, excluding the current dataset
            val otherDatasetNames =
                serializedSettings.datasetNameToEpochTimeOfLastUseMap.toList()
                    .sortedBy { nameToTime -> nameToTime.second }
                    .reversed()
                    .map { it.first }
                    .filter { it != datasetName }
            // The current dataset is always listed first
            return listOf(datasetName) + otherDatasetNames
        }

    override var scaleMarkLength: Float
        get() = normalizeScaleMarkLength(serializedSettings.scaleMarkLength)
        set(unnormalizedNewScaleMarkLength) {
            val newScaleMarkLength = normalizeScaleMarkLength(unnormalizedNewScaleMarkLength)
            edit { builder -> builder.setScaleMarkLength(newScaleMarkLength) }
        }
    private fun normalizeScaleMarkLength(scaleMarkLength: Float) = if (scaleMarkLength <= 0) DEFAULT_SCALE_MARK_LENGTH else scaleMarkLength

    override var scaleLengthUnit: String
        get() = normalizeScaleLengthUnit(serializedSettings.getDatasetNameToUnitOrDefault(datasetName, DEFAULT_UNIT))
        set(unnormalizedNewScaleLengthUnit) {
            val newScaleLengthUnit = normalizeScaleLengthUnit(unnormalizedNewScaleLengthUnit)
            edit { builder -> builder.putDatasetNameToUnit(datasetName, newScaleLengthUnit) }
        }
    private fun normalizeScaleLengthUnit(unit: String) = unit.ifBlank { DEFAULT_UNIT }

    override var nextSampleNumber: Int
        get() = serializedSettings.getDatasetNameToNextSampleNumberOrDefault(datasetName, DEFAULT_NEXT_SAMPLE_NUMBER)
        set(unnormalizedNewNextSampleNumber) {
            val newNextSampleNumber = normalizeNextSampleNumber(unnormalizedNewNextSampleNumber)
            edit { builder -> builder.putDatasetNameToNextSampleNumber(datasetName, newNextSampleNumber) }
        }
    private fun normalizeNextSampleNumber(nextSampleNumber: Int) = if (nextSampleNumber <= 0) DEFAULT_NEXT_SAMPLE_NUMBER else nextSampleNumber
    override fun incrementSampleNumber() {
        nextSampleNumber += 1
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
