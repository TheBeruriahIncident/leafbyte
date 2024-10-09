/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.withLink
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.core.content.FileProvider
import androidx.fragment.app.Fragment
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.isGoogleSignInConfigured
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.logError
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date

@SuppressLint("all")
@Suppress("all")
class MainMenuFragment : Fragment() {
    private var listener: OnFragmentInteractionListener? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        if (isGoogleSignInConfigured()) {
            log("Google Sign-In is configured")
        } else {
            logError("************************************************************\n" +
                    "STOP! Please fill in the secrets.properties file! Google Sign-In is not configured and WILL NOT WORK!\n" +
                    "************************************************************")
        }

        return ComposeView(requireContext()).apply {
            setContent {
                MainMenu()
            }
        }
    }

    @Preview(showBackground = true, device = Devices.PIXEL)
    @Composable
    fun MainMenu() {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                TextButton(
                    onClick = { listener!!.startTutorial() },
                ) {
                    Text("Tutorial")
                }
                TextButton(
                    onClick = { listener!!.openSettings() },
                ) {
                    Text("Settings")
                }
            }
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Image(
                    painter = painterResource(id = R.drawable.leafimage),
                    contentDescription = "LeafByte's logo, a hand-drawn leaf with a bite taken out",
                    Modifier.fillMaxWidth(.3f),
                )
                Text(text = "LeafByte", size = TextSize.MAIN_TITLE)
                Text(text = "Abigail & Zoe")
                Text(text = "Getman-Pickering")
                Text(
                    text =
                        buildAnnotatedString {
                            withLink(
                                link =
                                    LinkAnnotation.Url(
                                        url = "https://zoegp.science/leafbyte-faqs",
                                        styles =
                                            TextLinkStyles(
                                                style =
                                                    SpanStyle(
                                                        color = Color(0xff0000EE),
                                                    ),
                                            ),
                                    ),
                            ) {
                                append("FAQs, Help, and Bug Reporting")
                            }
                        },
                )
            }
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.SpaceAround,
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.galleryicon),
                        contentDescription = "Image gallery icon",
                        Modifier
                            .fillMaxWidth(.3f)
                            .clickable { chooseImageFromGallery() },
                    )
                    Text("Choose from Gallery", modifier = Modifier.clickable { chooseImageFromGallery() })
                }
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.clickable { takeAPhoto() },
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.camera),
                        contentDescription = "Camera icon",
                        Modifier.fillMaxWidth(.3f),
                    )
                    Text("Take a Photo")
                }
            }
            Text("Data and images are not being saved. Go to settings to change.")
        }
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
            "choose an image",
        )
    }

    var uri: Uri? = null

    private fun takeAPhoto() {
        if (!requireActivity().packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
            showAlert(
                "No camera found",
                "Could not take a photo: no camera was found. Try selecting an existing image instead.",
            )
            return
        }

        uri = MainMenuUtils.createImageUri(requireActivity())
        startActivity(
            MainMenuUtils.createCameraIntent(uri!!),
            MainMenuUtils.CAMERA_REQUEST_CODE,
            "take a photo",
        )
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
        val imageFile = createImageFile(context.getExternalFilesDir(Environment.DIRECTORY_PICTURES)!!)
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
