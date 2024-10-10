@file:Suppress("ktlint:standard:no-wildcard-imports", "detekt:style:WildcardImport")

package com.thebluefolderproject.leafbyte.utils

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.Composable
import com.thebluefolderproject.leafbyte.BuildConfig
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.utils.GoogleSignInFailureType.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import net.openid.appauth.AuthorizationException
import net.openid.appauth.AuthorizationRequest
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationService
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.ResponseTypeValues
import kotlin.coroutines.suspendCoroutine

private val GOOGLE_OPENID_CONNECT_ISSUER_URI = Uri.parse("https://accounts.google.com")
private val LEAFBYTE_REDIRECT_URI = Uri.parse("com.thebluefolderproject.leafbyte:/oauth2redirect/google") // TODO what does the path do
private const val GET_USER_ID_SCOPE = "openid"
private const val WRITE_TO_GOOGLE_DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.file"
private val ADDITIONAL_PARAMETERS_TO_ENABLE_GRANULAR_CONSENT = mapOf(Pair("enable_granular_consent", "true"))

class GoogleSignInContractInput(val serviceConfig: AuthorizationServiceConfiguration, val authService: AuthorizationService)

fun isGoogleSignInConfigured(): Boolean {
    return !BuildConfig.GOOGLE_SIGN_IN_CLIENT_ID.contains("FILL_THIS_IN")
}

@Suppress("detekt:exceptions:TooGenericExceptionCaught") // being defensive about the exceptions AppAuth might throw
class GoogleSignInContract : ActivityResultContract<GoogleSignInContractInput, AuthorizationResponse?>() {
    override fun createIntent(
        context: Context,
        input: GoogleSignInContractInput,
    ): Intent {
        val authRequest: AuthorizationRequest =
            AuthorizationRequest.Builder(
                input.serviceConfig,
                // This id is set in secrets.properties
                BuildConfig.GOOGLE_SIGN_IN_CLIENT_ID,
                ResponseTypeValues.CODE,
                LEAFBYTE_REDIRECT_URI,
            )
                .setScopes(GET_USER_ID_SCOPE, WRITE_TO_GOOGLE_DRIVE_SCOPE)
                // we do actually require both scopes we request, but we enable granular consent to get ahead of Google enabling it for us
                //   in the future
                .setAdditionalParameters(ADDITIONAL_PARAMETERS_TO_ENABLE_GRANULAR_CONSENT)
                .build()

        val authService = input.authService
        // this will automatically protect with PKCE if possible (according to https://github.com/openid/AppAuth-Android/issues/506)
        return authService.getAuthorizationRequestIntent(authRequest)
    }

    @Suppress("detekt:style:ReturnCount")
    override fun parseResult(
        resultCode: Int,
        intent: Intent?,
    ): AuthorizationResponse? {
        if (intent == null) {
            logError("Failed to sign in to Google and did not received intent data back. Result code: $resultCode")
            return null
        }

        try {
            val exception = AuthorizationException.fromIntent(intent)

            if (exception != null) {
                logError("Received exception while signing into Google", exception)
                return null
            }
        } catch (exception: Exception) {
            logError("Failed to deserialize exception from returned Google sign-in intent. Result code is $resultCode", exception)
            return null
        }

        val authResponse: AuthorizationResponse?
        try {
            authResponse = AuthorizationResponse.fromIntent(intent)
        } catch (exception: Exception) {
            logError("Failed to deserialize auth response from returned Google sign-in intent. Result code is $resultCode", exception)
            return null
        }

        if (authResponse == null) {
            logError("Did not receive auth response from returned Google sign-in intent. Result code is $resultCode")
            return null
        }

        if (resultCode != Activity.RESULT_OK) {
            logError("Google sign-in was not marked as a success. Auth response was $authResponse")
            return null
        }

        log("Successfully authorized with Google Sign-In: $authResponse")
        return authResponse
    }
}

enum class GoogleSignInFailureType {
    UNCONFIGURED,
    NON_INTERACTIVE_STAGE,
    INTERACTIVE_STAGE,
    NO_GET_USER_ID_SCOPE,
    NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
    NEITHER_SCOPE,
}

interface GoogleSignInManager {
    fun signIn(
        launcher: ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    )

    fun signOut()

    @Composable
    fun getLauncher(
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>
}

// TODO make it possible to inject mock sign in manager for testing, make sure we're testing which field is actually selected
@Suppress("detekt:exceptions:TooGenericExceptionCaught") // being defensive about the exceptions AppAuth might throw
class GoogleSignInManagerImpl(
    private val coroutineScope: CoroutineScope,
    context: Context,
    private val settings: Settings,
) : GoogleSignInManager {
    private var deferredServiceConfig: Deferred<AuthorizationServiceConfiguration?> = getDeferredServiceConfig()
    private val authService = AuthorizationService(context)
    private var authState = settings.authState

    override fun signIn(
        launcher: ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ) {
        if (!isGoogleSignInConfigured()) {
            logError("Attempting to use Google sign-in when it's unconfigured")
            onFailure(UNCONFIGURED)
            return
        }

        if (alreadySignedIn()) {
            log("Accessed to sign in when already signed-in")
            onSuccess()
            return
        }

        coroutineScope.launch(coroutineScope.coroutineContext) {
            val serviceConfig = getServiceConfigWithRetry()
            if (serviceConfig == null) {
                onFailure(NON_INTERACTIVE_STAGE)
                return@launch
            }

            log("Launching Google Sign-In intent")
            launcher.launch(GoogleSignInContractInput(serviceConfig, authService))
        }
    }

    private fun alreadySignedIn(): Boolean {
        return authState.isAuthorized
    }

    override fun signOut() {
        // just forgetting our auth state is enough to effectively log the user out from LeafByte's perspective.
        // we actually likely don't want to go any further, because logging them out properly would affect them across the device.
        settings.authState = DEFAULT_AUTH_STATE()
        authState = DEFAULT_AUTH_STATE()
    }

    @Composable
    override fun getLauncher(
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?> {
        return rememberLauncherForActivityResult(GoogleSignInContract()) { authResponse ->
            processAuthResponse(authResponse, onSuccess, onFailure)
        }
    }

    @Suppress("detekt:style:ReturnCount")
    private fun processAuthResponse(
        authResponse: AuthorizationResponse?,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ) {
        if (authResponse == null) {
            logError("Process auth response received a null response")
            onFailure(INTERACTIVE_STAGE)
            return
        }

        // if we don't have sufficient scope, don't save the auth state so that the sign-in flow can be easily retriggered
        val scope = authResponse.scope
        if (scope != null) {
            if (!scope.contains(GET_USER_ID_SCOPE) && !scope.contains(WRITE_TO_GOOGLE_DRIVE_SCOPE)) {
                onFailure(NEITHER_SCOPE)
                return
            } else if (!scope.contains(GET_USER_ID_SCOPE)) {
                onFailure(NO_GET_USER_ID_SCOPE)
                return
            } else if (!scope.contains(WRITE_TO_GOOGLE_DRIVE_SCOPE)) {
                onFailure(NO_WRITE_TO_GOOGLE_DRIVE_SCOPE)
                return
            }
        }

        authState.update(authResponse, null)
        settings.authState = authState

        val tokenRequest = authResponse.createTokenExchangeRequest()
        authService.performTokenRequest(tokenRequest) { tokenResponse, exception ->
            if (exception != null) {
                logError("Received exception when requesting token from Google", exception)
                onFailure(NON_INTERACTIVE_STAGE)
                return@performTokenRequest
            }
            if (tokenResponse == null) {
                logError("Did not receive either exception or response when requesting token from Google")
                onFailure(NON_INTERACTIVE_STAGE)
                return@performTokenRequest
            }

            log(
                "Successfully requested token from Google Sign-In. " +
                    "Id token: ${tokenResponse.idToken}, access token: ${tokenResponse.accessToken}",
            )
            authState.update(tokenResponse, null)
            settings.authState = authState

            onSuccess()
        }
    }

    @Suppress("detekt:style:ReturnCount")
    private suspend fun getServiceConfigWithRetry(): AuthorizationServiceConfiguration? {
        log("Awaiting deferred service config")
        var serviceConfig = deferredServiceConfig.await()
        log("Received deferred service config: $serviceConfig")
        if (serviceConfig != null) {
            return serviceConfig
        }

        // we need to retry in case e.g. there was no internet when LeafByte opened, but now there is
        // we don't need to worry about slight slowdown, as this is only in the case where we'd have failed anyways
        log("Retrying service config loading")
        deferredServiceConfig = getDeferredServiceConfig()
        serviceConfig = deferredServiceConfig.await()
        log("Received service config on retry: $serviceConfig")
        if (serviceConfig != null) {
            return serviceConfig
        }

        logError("Failed to get service config even with a retry")
        return null
    }

    private fun getDeferredServiceConfig(): Deferred<AuthorizationServiceConfiguration?> {
        return coroutineScope.async { loadServiceConfig() }
    }

    /**
     * This method will not throw; it will log and return null.
     */
    private suspend fun loadServiceConfig(): AuthorizationServiceConfiguration? {
        return suspendCoroutine<AuthorizationServiceConfiguration?> { continuation ->
            log("Attempting to fetch Google auth config")

            AuthorizationServiceConfiguration.fetchFromIssuer(GOOGLE_OPENID_CONNECT_ISSUER_URI) { serviceConfiguration, exception ->
                if (exception != null) {
                    logError("Failed to fetch Google auth config", exception)

                    continuation.resumeWith(Result.success(null))
                } else {
                    if (serviceConfiguration == null) {
                        logError("Fetching Google auth config returned neither a config nor an exception")

                        continuation.resumeWith(Result.success(null))
                    } else {
                        continuation.resumeWith(Result.success(serviceConfiguration))
                    }
                }
            }
        }
    }
}
