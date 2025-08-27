package com.thebluefolderproject.leafbyte.fragment

import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.runtime.Composable
import com.thebluefolderproject.leafbyte.utils.GoogleSignInContract
import com.thebluefolderproject.leafbyte.utils.GoogleSignInContractInput
import com.thebluefolderproject.leafbyte.utils.GoogleSignInFailureType
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import kotlinx.collections.immutable.ImmutableList
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flowOf
import net.openid.appauth.AuthState
import net.openid.appauth.AuthorizationResponse

@Suppress("detekt:style:MagicNumber")
open class SampleSettings : Settings {
    override fun getDataSaveLocation(): Flow<SaveLocation> = flowOf(SaveLocation.LOCAL)

    override fun setDataSaveLocation(newDataSaveLocation: SaveLocation) {
        TODO("Not yet implemented")
    }

    override fun getImageSaveLocation(): Flow<SaveLocation> = flowOf(SaveLocation.GOOGLE_DRIVE)

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

    override fun getUseBarcode(): Flow<Boolean> = flowOf(true)

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

class SampleGoogleSignInManager : GoogleSignInManager {
    override fun signIn(
        launcher: ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ) {}

    override fun signOut() {}

    @Composable
    override fun getLauncher(
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?> =
        rememberLauncherForActivityResult(GoogleSignInContract()) {
        }
}
