/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.material3.Text
import androidx.compose.ui.platform.ComposeView
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import com.thebluefolderproject.leafbyte.BuildConfig
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.log
import net.openid.appauth.AuthorizationRequest
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationService
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.AuthorizationServiceConfiguration.RetrieveConfigurationCallback
import net.openid.appauth.ResponseTypeValues
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date

@SuppressLint("all")
@Suppress("all")
class MainMenuFragment : Fragment() {
    private var listener: OnFragmentInteractionListener? = null

    private val requestCodeSignIn = 20

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {
        (activity as AppCompatActivity).supportActionBar!!.hide()

        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_main_menu, container, false)
        view.findViewById<Button>(R.id.chooseFromGalleryButton).setOnClickListener { chooseImageFromGallery() }
        view.findViewById<Button>(R.id.takePhotoButton).setOnClickListener { takeAPhoto() }
        view.findViewById<Button>(R.id.start_tutorial).setOnClickListener { listener!!.startTutorial() }
        view.findViewById<Button>(R.id.settings).setOnClickListener { listener!!.openSettings() }
        view.findViewById<TextView>(
            R.id.savingSummary,
        ).setText("Dynamically set text about your save location! Potato Potato Potato Potato Potato Potato Potato Potato ")

        // testGoogleApi()

        return view
    }

//    override fun onCreateView(
//        inflater: LayoutInflater,
//        container: ViewGroup?,
//        savedInstanceState: Bundle?,
//    ): View? {
//        return ComposeView(requireContext()).apply {
//            setContent {
//                Text(text = "Hello world.")
//            }
//        }
//    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        if (context is OnFragmentInteractionListener) {
            listener = context
        } else {
            throw RuntimeException("$context must implement OnFragmentInteractionListener")
        }
    }

    override fun onDetach() {
        super.onDetach()
        listener = null
    }

    private fun chooseImageFromGallery() {
        startActivity(
            MainMenuUtils.IMAGE_PICKER_INTENT,
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE,
            "choose an image",
        )
    }

    var uri: Uri? = null

    private fun takeAPhoto() {
        testGoogleApi()
//        if (!requireActivity().packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
//            showAlert(
//                "No camera found",
//                "Could not take a photo: no camera was found. Try selecting an existing image instead."
//            )
//            return
//        }
//
//        uri = MainMenuUtils.createImageUri(requireActivity())
//        startActivity(
//            MainMenuUtils.createCameraIntent(uri!!),
//            MainMenuUtils.CAMERA_REQUEST_CODE,
//            "take a photo"
//        )
    }

    fun startActivity(
        intent: Intent,
        requestCode: Int,
        actionDescription: String,
    ) {
        if (intent.resolveActivity(requireActivity().packageManager) == null) {
            showAlert(
                "Could not $actionDescription",
                "Could not $actionDescription: no app was found supporting that action.",
            )
            return
        }

        startActivityForResult(intent, requestCode)
    }

    fun showAlert(
        title: String,
        message: String,
    ) {
        AlertDialog.Builder(requireActivity())
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton("OK") { dialog, _ -> dialog.dismiss() }
            .show()
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        log("onActivityResult " + resultCode)
        when (resultCode) {
            AppCompatActivity.RESULT_OK -> {
                if (data == null) {
                    throw IllegalArgumentException("Intent data is null")
                }

                processActivityResultData(requestCode, data)
            }
            AppCompatActivity.RESULT_CANCELED -> {
            }
            else -> throw IllegalArgumentException("Result code: $resultCode")
        }
    }

    fun testGoogleApi() {
        AuthorizationServiceConfiguration.fetchFromIssuer(
            Uri.parse("https://accounts.google.com"),
            RetrieveConfigurationCallback { serviceConfiguration, ex ->
                if (ex != null) {
                    Log.e("tag", "failed to fetch configuration")
                    return@RetrieveConfigurationCallback
                }

                val config2 =
                    AuthorizationServiceConfiguration(
                        Uri.parse("https://accounts.google.com/o/oauth2/auth"),
                        Uri.parse("https://oauth2.googleapis.com/token"),
                    )

                val authRequestBuilder: AuthorizationRequest.Builder =
                    AuthorizationRequest.Builder(
                        // serviceConfiguration!!,  // the authorization service configuration
                        config2,
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

                val authService = AuthorizationService(requireContext())
                val authIntent = authService.getAuthorizationRequestIntent(authRequest)
                startActivity(
                    authIntent,
                    requestCodeSignIn,
                    "Login with Google Sign-In",
                )
            },
        )
    }

    private fun handleSignInResult(result: Intent) {
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

    private fun processActivityResultData(
        requestCode: Int,
        data: Intent,
    ) {
        log("Request succesful " + requestCode)
        when (requestCode) {
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE -> {
                val imageUri = MainMenuUtils.intentToUri(data)

                listener!!.onImageSelection(imageUri)
            }
            MainMenuUtils.CAMERA_REQUEST_CODE -> {
                // no meaningful response??
                listener!!.onImageSelection(uri!!)
            }
            requestCodeSignIn -> {
                handleSignInResult(data)
            }
            else -> throw IllegalArgumentException("Request code: $requestCode")
        }
    }

    interface OnFragmentInteractionListener {
        fun onImageSelection(imageUri: Uri)

        fun startTutorial()

        fun openSettings()
    }
}

@Suppress("all")
object MainMenuUtils {
    const val IMAGE_PICKER_REQUEST_CODE = 1
    const val CAMERA_REQUEST_CODE = 2

    val IMAGE_PICKER_INTENT by lazy {
        val intent = Intent(Intent.ACTION_GET_CONTENT, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)

        with(intent) {
            // API level 19 added the ability to request any of multiple MIME types
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                type = API_19_ACCEPTED_MIME_TYPE_RANGE
                putExtra(Intent.EXTRA_MIME_TYPES, API_19_ACCEPTED_MIME_TYPES)
            } else {
                type = PRE_API_19_ACCEPTED_MIME_TYPE
            }
        }

        intent
    }

    private const val PRE_API_19_ACCEPTED_MIME_TYPE = "image/jpeg"
    private const val API_19_ACCEPTED_MIME_TYPE_RANGE = "image/*"
    private val API_19_ACCEPTED_MIME_TYPES =
        arrayOf(
            PRE_API_19_ACCEPTED_MIME_TYPE,
            "image/png",
            "image/bmp",
        )

    fun intentToUri(data: Intent): Uri {
        if (data.data == null) {
            throw IllegalStateException("Intent data is null")
        }
        return data.data!!
    }

    fun createCameraIntent(photoURI: Uri): Intent {
        return Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
        }
    }

    fun createImageUri(context: Context): Uri {
        val imageFile = createImageFile(context!!.getExternalFilesDir(Environment.DIRECTORY_PICTURES)!!)
        return FileProvider.getUriForFile(
            context,
            "com.thebluefolderproject.leafbyte.fileprovider",
            imageFile,
        )
    }

    private fun createImageFile(externalFilesDir: File): File {
        val timestamp: String = SimpleDateFormat("yyyyMMdd HHmmss").format(Date())
        return externalFilesDir.resolve(timestamp).apply { createNewFile() }
    }
}
