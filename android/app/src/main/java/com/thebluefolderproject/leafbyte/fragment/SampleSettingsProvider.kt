package com.thebluefolderproject.leafbyte.fragment

import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.PreviewParameterProvider
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
                        return flowOf(persistentListOf("Herbivory data", "Herbvar"))
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

                    override fun getAuthState(): Flow<AuthState> {
                        return flowOf(AuthState())
                    }

                    override fun setAuthState(newAuthState: AuthState) {
                        TODO("Not yet implemented")
                    }
                }

            return sequenceOf(sampleSettings)
        }
}

class SampleGoogleSignInManagerProvider : PreviewParameterProvider<GoogleSignInManager> {
    override val values: Sequence<GoogleSignInManager>
        get() {
            val sampleGoogleSignInManager: GoogleSignInManager =
                object : GoogleSignInManager {
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
                    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?> {
                        return rememberLauncherForActivityResult(GoogleSignInContract()) {}
                    }
                }

            return sequenceOf(sampleGoogleSignInManager)
        }
}
