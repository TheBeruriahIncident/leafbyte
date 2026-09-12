/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.settings

import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RestrictTo
import androidx.annotation.VisibleForTesting
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import com.thebluefolderproject.leafbyte.serializedsettings.DatasetSpecificSettings
import com.thebluefolderproject.leafbyte.serializedsettings.SerializedSettings
import com.thebluefolderproject.leafbyte.utils.Clock
import com.thebluefolderproject.leafbyte.utils.DEFAULT_AUTH_STATE
import com.thebluefolderproject.leafbyte.utils.SystemClock
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

/**
 * This class wraps the data store logic (https://developer.android.com/topic/libraries/architecture/datastore) and ensures that all writes
 * are immediately persisted, and all reads are fresh.
 *
 * We store data in normalized form, but because the protobuf format doesn't allow us to specify a default value, we must also normalize on
 * read, just in case we're reading a value that has never been written.
 */
@Suppress("ktlint:standard:function-signature")
class DataStoreBackedSettings(
    context: Context,
    private val clock: Clock = SystemClock(),
) : Settings {
    private val settingsStore = context.settingsStore

    private fun <T> fromTopLevelSettings(from: SerializedSettings.() -> T): Flow<T> =
        settingsStore.data.map { from(it) }

    private fun <T> fromSettings(from: DatasetSpecificSettings.() -> T): Flow<T> =
        settingsStore.data.map { from(it.currentSettings()) }

    /**
     * Note that the scope is SerializedSettings.Builder. This makes everything much cleaner, but be aware that this shadows some local
     * functions.
     */
    private fun editTopLevel(editAction: SerializedSettings.Builder.() -> SerializedSettings.Builder) {
        runBlocking {
            settingsStore.updateData { currentSerializedSettings ->
                val settingsBuilder = currentSerializedSettings.toBuilder()
                val settings = editAction(settingsBuilder).build()

                log("Writing new settings via top-level edit: $settings")
                settings
            }
        }
    }
    private fun edit(editAction: DatasetSpecificSettings.Builder.() -> DatasetSpecificSettings.Builder) {
        runBlocking {
            settingsStore.updateData { currentSerializedSettings ->
                val settingsBuilder = currentSerializedSettings.toBuilder()
                val datasetSpecificSettings = editAction(currentSerializedSettings.currentSettings().toBuilder()).build()

                val settings =
                    settingsBuilder
                        .putDatasetNameToSettings(
                            currentSerializedSettings.currentDatasetNameNormalized(),
                            datasetSpecificSettings,
                        ).build()

                log("Writing new settings via dataset-specific edit: $settings")
                settings
            }
        }
    }

    override fun getDatasetName(): Flow<String> =
        fromTopLevelSettings { currentDatasetNameNormalized() }

    // TODO can I nest other setters somehow under this? so we always set for the right dataset
    override fun setDatasetName(newDatasetName: String) {
        val normalizedNewDatasetName = normalizeDatasetName(newDatasetName)
        editTopLevel { setCurrentDatasetName(normalizedNewDatasetName) }
    }

    override fun noteDatasetUsed() {
        val epochTimeInSeconds = clock.getEpochTimeInSeconds()
        edit { setEpochTimeOfLastUse(epochTimeInSeconds) }
    }
    override fun getPreviousDatasetNames(): Flow<ImmutableList<String>> =
        fromTopLevelSettings {
            val currentDatasetName = currentDatasetNameNormalized()
            // Sort the dataset names by last use, excluding the current dataset
            val otherDatasetNames =
                datasetNameToSettingsMap
                    .toList()
                    .filter { datasetNameToSettings -> datasetNameToSettings.second.epochTimeOfLastUse > 0 }
                    .sortedBy { datasetNameToSettings -> datasetNameToSettings.second.epochTimeOfLastUse }
                    .reversed()
                    .map { it.first }
                    .filter { it != currentDatasetName }
            // The current dataset is always listed first
            val previousDatasetNames = listOf(currentDatasetName) + otherDatasetNames

            previousDatasetNames.toImmutableList()
        }

    override fun getDataSaveLocation(): Flow<SaveLocation> =
        fromSettings { dataSaveLocation.deserialize() }
    override fun setDataSaveLocation(newDataSaveLocation: SaveLocation) =
        edit { setDataSaveLocation(newDataSaveLocation.serialized) }

    override fun getImageSaveLocation(): Flow<SaveLocation> =
        fromSettings { imageSaveLocation.deserialize() }
    override fun setImageSaveLocation(newImageSaveLocation: SaveLocation) =
        edit { setImageSaveLocation(newImageSaveLocation.serialized) }

    override fun getScaleLength(): Flow<Float> =
        fromSettings { scaleLengthNormalized() }
    override fun setScaleLength(newScaleLength: Float) {
        val normalizedNewScaleLength = normalizeScaleLength(newScaleLength)
        edit { setScaleLength(normalizedNewScaleLength) }
    }

    override fun getScaleUnit(): Flow<String> =
        fromSettings { scaleUnitNormalized() }
    override fun setScaleUnit(newScaleUnit: String) {
        val normalizedNewScaleUnit = normalizeScaleUnit(newScaleUnit)
        edit { setScaleUnit(normalizedNewScaleUnit) }
    }

    override fun getNextSampleNumber(): Flow<Int> =
        fromSettings { nextSampleNumberNormalized() }
    override fun setNextSampleNumber(newNextSampleNumber: Int) {
        val normalizedNewNextSampleNumber = normalizeNextSampleNumber(newNextSampleNumber)
        edit { setNextSampleNumber(normalizedNewNextSampleNumber) }
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
        val rawAuthState = fromTopLevelSettings { googleAuthState }
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

        editTopLevel { setGoogleAuthState(newAuthStateString) }
    }
}
