package com.thebluefolderproject.leafbyte.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.ActivityResult
import androidx.activity.result.contract.ActivityResultContract
import androidx.compose.runtime.Composable
import com.thebluefolderproject.leafbyte.BuildConfig
import net.openid.appauth.AuthorizationRequest
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationService
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.AuthorizationServiceConfiguration.RetrieveConfigurationCallback
import net.openid.appauth.ResponseTypeValues

// const val requestCodeSignIn = 20

class GoogleSignInContract : ActivityResultContract<Unit, AuthorizationResponse>() {
    override fun createIntent(
        context: Context,
        input: Unit,
    ): Intent {
        TODO("Not yet implemented")
    }

    override fun parseResult(
        resultCode: Int,
        intent: Intent?,
    ): AuthorizationResponse {
        return AuthorizationResponse.fromIntent(intent!!)!! // there's also an exception from intent??
    }
}

fun signInToGoogle(context: Context, launcher: ManagedActivityResultLauncher<Intent, ActivityResult>) {
    log("starting sign in")

    // this needs to not happen on main thread and probably should happen on start up or something
    AuthorizationServiceConfiguration.fetchFromIssuer(
        Uri.parse("https://accounts.google.com"),
        RetrieveConfigurationCallback { serviceConfiguration, ex ->
            if (ex != null) {
                Log.e("tag", "failed to fetch configuration")
                return@RetrieveConfigurationCallback
            }

            val authRequestBuilder: AuthorizationRequest.Builder =
                AuthorizationRequest.Builder(
                    serviceConfiguration!!,
                    // from secret.properties
                    BuildConfig.GOOGLE_SIGN_IN_CLIENT_ID,
                    // the response_type value: we want a code
                    ResponseTypeValues.CODE,
                    // what does the path do
                    Uri.parse("com.thebluefolderproject.leafbyte:/oauth2redirect/google"),
                    // and pre android m, we maybe need to do something else https://github.com/openid/AppAuth-Android
                ) // the redirect URI to which the auth response is sent
            val authRequest =
                authRequestBuilder.setScope(
                    "openid https://www.googleapis.com/auth/drive.file",
                ) // deal with granular permissions?? need to enable it? https://developers.google.com/identity/protocols/oauth2/resources/granular-permissions#test-your-updated-application-on-handling-granular-permissions
                    // .setCodeVerifier(null)
                    .build()

            val authService = AuthorizationService(context)
            val authIntent = authService.getAuthorizationRequestIntent(authRequest)
            launcher.launch(authIntent)
//            context.startActivity(
//                authIntent,
////                requestCodeSignIn,
////                "Login with Google Sign-In",
//            )
        },
    )
}

fun handleSignInResult(result: Intent) {
    val response = AuthorizationResponse.fromIntent(result)!! // there's also an exception from intent??
    val authCode = response.authorizationCode!!
    log("auth code $authCode")

//        GoogleSignIn.getSignedInAccountFromIntent(result)
//            .addOnSuccessListener { googleAccount: GoogleSignInAccount ->
//                log("Signed in as " + googleAccount.email)
//
//                // Use the authenticated account to sign in to the Drive service.
//                val credential: GoogleAccountCredential = GoogleAccountCredential.usingOAuth2(
//                    requireContext(), Collections.singleton(DriveScopes.DRIVE_FILE)
//                )
//                credential.setSelectedAccount(googleAccount.account)
//                val drive: Drive = Drive.Builder(
//                    NetHttpTransport(),
//                    GsonFactory(),
//                    credential
//                ).setApplicationName("LeafByte")
//                    .build()
//                val sheets: Sheets = Sheets.Builder(
//                    NetHttpTransport(),
//                    GsonFactory(),
//                    credential
//                )
//                    .setApplicationName("LeafByte")
//                    .build()
//                log("created clients")
//
//                val task: AsyncTask<Void, Void, Void> = object : AsyncTask<Void, Void, Void>() {
//                    override protected fun doInBackground(vararg params: Void): Void? {
//
//                        val file = drive.files().create(
//                            com.google.api.services.drive.model.File()
//                                //.setParents(Collections.singletonList("root"))
//                                .setMimeType("application/vnd.google-apps.spreadsheet")
//                                .setName("Kahlo // created from android")
//                        ).execute()
//                            ?: throw IOException("Null result when requesting file creation.")
//                        log("created file " + file.id)
//
//                        sheets.spreadsheets().values().append(
//                            file.id, "Sheet1", ValueRange().setValues(
//                                listOf(listOf("dog"))
//                            )
//                        ).setValueInputOption("USER_ENTERED").setInsertDataOption("INSERT_ROWS").execute()
//                        log("appended")
//                        return null;
//                    }
//                }
//                task.execute()
//            }
//            .addOnFailureListener { exception: Exception? ->
//                log(
//                    exception!!
//                )
//            }
}
