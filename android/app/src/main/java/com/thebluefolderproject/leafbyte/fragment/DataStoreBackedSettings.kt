package com.thebluefolderproject.leafbyte.fragment

import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RestrictTo
import androidx.annotation.VisibleForTesting
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings
import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.DEFAULT_AUTH_STATE
import com.thebluefolderproject.leafbyte.utils.SystemClock
import com.thebluefolderproject.leafbyte.utils.load
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.logError
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.toImmutableList
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.runBlocking
import net.openid.appauth.AuthState
import java.nio.file.Files

private const val DATA_STORE_FILE_NAME = "settings.pb"

/**
 * This is declared outside the class so that only one DataStore can exist, per
 * https://developer.android.com/topic/libraries/architecture/datastore#correct_usage
 */
private val Context.settingsStore: DataStore<SerializedSettings> by dataStore(
    fileName = DATA_STORE_FILE_NAME,
    serializer = SerializedSettingsSerializer,
)

@VisibleForTesting(VisibleForTesting.NONE)
@RestrictTo(RestrictTo.Scope.TESTS)
@RequiresApi(Build.VERSION_CODES.O)
fun clearSettingsStore(context: Context) {
    runBlocking {
        context.settingsStore.updateData { current ->
            current.toBuilder().clear().build()
        }
    }

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
 *
 * We store data in normalized form, but because the protobuf format doesn't allow us to specify a default value, we must also normalized on
 * read, just in case we're reading a value that has never been written.
 */
@Suppress("ktlint:standard:function-signature")
class DataStoreBackedSettings(
    context: Context,
    private val clock: Clock = SystemClock(),
) : Settings {
    private val settingsStore = context.settingsStore

    private fun <T> fromSettings(from: SerializedSettings.() -> T): Flow<T> =
        settingsStore.data.map { from(it) }

    /**
     * Note that the scope is SerializedSettings.Builder. This makes everything much cleaner, but be aware that this shadows some local
     * functions.
     */
    private fun edit(editAction: SerializedSettings.Builder.() -> SerializedSettings.Builder) {
        runBlocking {
            settingsStore.updateData { currentSerializedSettings ->
                val settingsBuilder = currentSerializedSettings.toBuilder()
                val settings = editAction(settingsBuilder).build()

                log("Writing new settings: $settings")
                settings
            }
        }
    }

    override fun getDataSaveLocation(): Flow<SaveLocation> =
        fromSettings { SaveLocation.fromSerialized(dataSaveLocation) }
    override fun setDataSaveLocation(newDataSaveLocation: SaveLocation) =
        edit { setDataSaveLocation(newDataSaveLocation.serialized) }

    override fun getImageSaveLocation(): Flow<SaveLocation> =
        fromSettings { SaveLocation.fromSerialized(imageSaveLocation) }
    override fun setImageSaveLocation(newImageSaveLocation: SaveLocation) =
        edit { setImageSaveLocation(newImageSaveLocation.serialized) }

    override fun getDatasetName(): Flow<String> =
        fromSettings { normalizeDatasetName(datasetName) }
    private val currentDatasetName: String
        get() = getDatasetName().load()
    override fun setDatasetName(newDatasetName: String) {
        val normalizedNewDatasetName = normalizeDatasetName(newDatasetName)
        edit { setDatasetName(normalizedNewDatasetName) }
    }
    private fun normalizeDatasetName(datasetName: String) =
        datasetName.ifBlank { DEFAULT_DATASET_NAME }

    override fun noteDatasetUsed() {
        val epochTimeInSeconds = clock.getEpochTimeInSeconds()
        edit { putDatasetNameToEpochTimeOfLastUse(currentDatasetName, epochTimeInSeconds) }
    }
    override fun getPreviousDatasetNames(): Flow<ImmutableList<String>> =
        fromSettings {
            // Sort the dataset names by last use, excluding the current dataset
            val otherDatasetNames =
                datasetNameToEpochTimeOfLastUseMap
                    .toList()
                    .sortedBy { nameToTime -> nameToTime.second }
                    .reversed()
                    .map { it.first }
                    .filter { it != currentDatasetName }
            // The current dataset is always listed first
            val previousDatasetNames = listOf(currentDatasetName) + otherDatasetNames

            previousDatasetNames.toImmutableList()
        }

    override fun getScaleMarkLength(): Flow<Float> =
        fromSettings {
            val unnormalizedScaleMarkLength = getDatasetNameToScaleMarkLengthOrDefault(currentDatasetName, DEFAULT_SCALE_MARK_LENGTH)
            normalizeScaleMarkLength(unnormalizedScaleMarkLength)
        }
    override fun setScaleMarkLength(newScaleMarkLength: Float) {
        val normalizedNewScaleMarkLength = normalizeScaleMarkLength(newScaleMarkLength)
        edit { putDatasetNameToScaleMarkLength(currentDatasetName, normalizedNewScaleMarkLength) }
    }
    private fun normalizeScaleMarkLength(scaleMarkLength: Float) = if (scaleMarkLength <= 0) DEFAULT_SCALE_MARK_LENGTH else scaleMarkLength

    override fun getScaleLengthUnit(): Flow<String> =
        fromSettings {
            val unnormalizedScaleLengthUnit = getDatasetNameToUnitOrDefault(currentDatasetName, DEFAULT_UNIT)
            normalizeScaleLengthUnit(unnormalizedScaleLengthUnit)
        }
    override fun setScaleLengthUnit(newScaleLengthUnit: String) {
        val normalizedNewScaleLengthUnit = normalizeScaleLengthUnit(newScaleLengthUnit)
        edit { putDatasetNameToUnit(currentDatasetName, normalizedNewScaleLengthUnit) }
    }
    private fun normalizeScaleLengthUnit(unit: String) = unit.ifBlank { DEFAULT_UNIT }

    override fun getNextSampleNumber(): Flow<Int> =
        fromSettings {
            val unnormalizedNextSampleNumber = getDatasetNameToNextSampleNumberOrDefault(currentDatasetName, DEFAULT_NEXT_SAMPLE_NUMBER)
            normalizeNextSampleNumber(unnormalizedNextSampleNumber)
        }
    override fun setNextSampleNumber(newNextSampleNumber: Int) {
        val normalizedNewNextSampleNumber = normalizeNextSampleNumber(newNextSampleNumber)
        edit { putDatasetNameToNextSampleNumber(currentDatasetName, normalizedNewNextSampleNumber) }
    }
    private fun normalizeNextSampleNumber(nextSampleNumber: Int) =
        if (nextSampleNumber <= 0) DEFAULT_NEXT_SAMPLE_NUMBER else nextSampleNumber
    override fun incrementSampleNumber() {
        setNextSampleNumber(getNextSampleNumber().load() + 1)
    }

    override fun getUseBarcode(): Flow<Boolean> =
        fromSettings { useBarcode }
    override fun setUseBarcode(newUseBarcode: Boolean) {
        edit { setUseBarcode(newUseBarcode) }
    }

    override fun getSaveGpsData(): Flow<Boolean> =
        fromSettings { saveGpsData }
    override fun setSaveGpsData(newSaveGpsData: Boolean) {
        edit { setSaveGpsData(newSaveGpsData) }
    }

    override fun getUseBlackBackground(): Flow<Boolean> =
        fromSettings { useBlackBackground }
    override fun setUseBlackBackground(newUseBlackBackground: Boolean) {
        edit { setUseBlackBackground(newUseBlackBackground) }
    }

    @Suppress("detekt:exceptions:TooGenericExceptionCaught") // being defensive about the exceptions AppAuth might throw
    override fun getAuthState(): Flow<AuthState> {
        val rawAuthState = fromSettings { googleAuthState }
        return rawAuthState.map { authStateString ->
            if (authStateString.isBlank()) {
                return@map DEFAULT_AUTH_STATE()
            }

            try {
                return@map AuthState.jsonDeserialize(authStateString)
            } catch (exception: Exception) {
                logError("Failed to deserialize auth state $authStateString", exception)
                return@map DEFAULT_AUTH_STATE()
            }
        }
    }
    @Suppress("detekt:exceptions:TooGenericExceptionCaught") // being defensive about the exceptions AppAuth might throw
    override fun setAuthState(newAuthState: AuthState) {
        val newAuthStateString: String
        try {
            newAuthStateString = newAuthState.jsonSerializeString()
        } catch (exception: Exception) {
            logError("Failed to serialize new auth state $newAuthState", exception)
            return
        }

        edit { setGoogleAuthState(newAuthStateString) }
    }
}
