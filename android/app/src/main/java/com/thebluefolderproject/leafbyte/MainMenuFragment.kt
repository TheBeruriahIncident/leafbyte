package com.thebluefolderproject.leafbyte

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.AsyncTask
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.Scope
import com.google.api.client.extensions.android.http.AndroidHttp
import com.google.api.client.googleapis.extensions.android.gms.auth.GoogleAccountCredential
import com.google.api.client.json.gson.GsonFactory
import com.google.api.services.drive.Drive
import com.google.api.services.drive.DriveScopes
import com.google.api.services.sheets.v4.Sheets
import com.google.api.services.sheets.v4.model.ValueRange
import java.io.File
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executors


class MainMenuFragment : Fragment() {
    private var listener: OnFragmentInteractionListener? = null

    private val REQUEST_CODE_SIGN_IN = 20

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        (activity as AppCompatActivity).supportActionBar!!.hide()

        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_main_menu, container, false)
        view.findViewById<Button>(R.id.chooseFromGalleryButton).setOnClickListener { chooseImageFromGallery() }
        view.findViewById<Button>(R.id.takePhotoButton).setOnClickListener { takeAPhoto() }
        view.findViewById<Button>(R.id.start_tutorial).setOnClickListener { listener!!.startTutorial() }
        view.findViewById<Button>(R.id.settings).setOnClickListener { listener!!.openSettings() }
        view.findViewById<TextView>(R.id.savingSummary).setText("Dynamically set text about your save location! Potato Potato Potato Potato Potato Potato Potato Potato ")

        //testGoogleApi()

        return view
    }

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
            "choose an image"
        )
    }

    var uri: Uri? = null

    private fun takeAPhoto() {
        if (!activity!!.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
            showAlert(
                "No camera found",
                "Could not take a photo: no camera was found. Try selecting an existing image instead."
            )
            return
        }

        uri = MainMenuUtils.createImageUri(activity!!)
        startActivity(
            MainMenuUtils.createCameraIntent(uri!!),
            MainMenuUtils.CAMERA_REQUEST_CODE,
            "take a photo"
        )
    }

    fun startActivity(intent: Intent, requestCode: Int, actionDescription: String) {
        if (intent.resolveActivity(activity!!.packageManager) == null) {
            showAlert(
                "Could not $actionDescription",
                "Could not $actionDescription: no app was found supporting that action."
            )
            return
        }

        startActivityForResult(intent, requestCode)
    }

    fun showAlert(title: String, message: String) {
        AlertDialog.Builder(activity!!)
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton("OK") { dialog, _ -> dialog.dismiss() }
            .show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        debug("onActivityResult " + resultCode)
        when(resultCode) {
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
        val signInOptions: GoogleSignInOptions = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestScopes(Scope(DriveScopes.DRIVE_FILE))
            .build()
        val client: GoogleSignInClient = GoogleSignIn.getClient(requireContext(), signInOptions)


        val task: AsyncTask<Void, Void, Void> = object : AsyncTask<Void, Void, Void>() {
            override protected fun doInBackground(vararg params: Void): Void? {

                startActivityForResult(
                    client.getSignInIntent(),
                    REQUEST_CODE_SIGN_IN
                )
                return null;
            }
        }
        task.execute()
    }

    private fun handleSignInResult(result: Intent) {
        GoogleSignIn.getSignedInAccountFromIntent(result)
            .addOnSuccessListener { googleAccount: GoogleSignInAccount ->
                debug("Signed in as " + googleAccount.email)

                // Use the authenticated account to sign in to the Drive service.
                val credential: GoogleAccountCredential = GoogleAccountCredential.usingOAuth2(
                    requireContext(), Collections.singleton(DriveScopes.DRIVE_FILE)
                )
                credential.setSelectedAccount(googleAccount.account)
                val drive: Drive = Drive.Builder(
                    AndroidHttp.newCompatibleTransport(),
                    GsonFactory(),
                    credential
                ).setApplicationName("LeafByte")
                    .build()
                val sheets: Sheets = Sheets.Builder(
                    AndroidHttp.newCompatibleTransport(),
                    GsonFactory(),
                    credential
                )
                    .setApplicationName("LeafByte")
                    .build()
                debug("created clients")

                val task: AsyncTask<Void, Void, Void> = object : AsyncTask<Void, Void, Void>() {
                    override protected fun doInBackground(vararg params: Void): Void? {

                        val file = drive.files().create(
                            com.google.api.services.drive.model.File()
                                //.setParents(Collections.singletonList("root"))
                                .setMimeType("application/vnd.google-apps.spreadsheet")
                                .setName("Kahlo // created from android")
                        ).execute()
                            ?: throw IOException("Null result when requesting file creation.")
                        debug("created file " + file.id)

                        sheets.spreadsheets().values().append(
                            file.id, "Sheet1", ValueRange().setValues(
                                listOf(listOf("dog"))
                            )
                        ).setValueInputOption("USER_ENTERED").setInsertDataOption("INSERT_ROWS").execute()
                        debug("appended")
                        return null;
                    }
                }
                task.execute()
            }
            .addOnFailureListener { exception: Exception? ->
                debug(
                    "Unable to sign in." +
                            exception
                )
            }
    }

    private fun processActivityResultData(requestCode: Int, data: Intent) {
        when(requestCode) {
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE -> {
                val imageUri = MainMenuUtils.intentToUri(data)

                listener!!.onImageSelection(imageUri)
            }
            MainMenuUtils.CAMERA_REQUEST_CODE -> {
                // no meaningful response??
                listener!!.onImageSelection(uri!!)
            }
            REQUEST_CODE_SIGN_IN -> {
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
    private val API_19_ACCEPTED_MIME_TYPES = arrayOf(
        PRE_API_19_ACCEPTED_MIME_TYPE,
        "image/png",
        "image/bmp"
    )

    fun intentToUri(data: Intent) : Uri {
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
            imageFile
        )
    }

    private fun createImageFile(externalFilesDir: File): File {
        val timestamp: String = SimpleDateFormat("yyyyMMdd HHmmss").format(Date())
        return externalFilesDir.resolve(timestamp).apply { createNewFile() }
    }
}

