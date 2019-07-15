package com.thebluefolderproject.leafbyte

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.content.DialogInterface
import android.content.pm.PackageManager


class MainMenuFragment : Fragment() {
    private var listener: OnFragmentInteractionListener? = null

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_main_menu, container, false)
        view.findViewById<Button>(R.id.chooseFromGalleryButton).setOnClickListener { chooseImageFromGallery() }
        view.findViewById<Button>(R.id.takePhotoButton).setOnClickListener { takeAPhoto() }

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
            MainMenuUtils.createImagePickerIntent(),
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE,
            "choose an image")
    }

    private fun takeAPhoto() {
        if (!activity!!.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
            showAlert("No camera found", "Could not take a photo: no camera was found. Try selecting an existing image instead.")
            return
        }

        showAlert("Camera not yet supported", "Working on it!")
    }

    fun startActivity(intent: Intent, requestCode: Int, actionDescription: String) {
        if (intent.resolveActivity(activity!!.packageManager) == null) {
            showAlert("Could not $actionDescription", "Could not $actionDescription: no app was found supporting that action.")
            return
        }

        startActivityForResult(intent, requestCode)
    }

    fun showAlert(title: String, message: String) {
        AlertDialog.Builder(activity)
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton("OK") { dialog, _ -> dialog.dismiss() }
            .show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when(resultCode) {
            Activity.RESULT_OK -> {
                if (data == null) {
                    throw IllegalArgumentException("Intent data is null")
                }

                processActivityResultData(requestCode, data)
            }
            Activity.RESULT_CANCELED -> {}
            else -> throw IllegalArgumentException("Result code: $resultCode")
        }
    }

    private fun processActivityResultData(requestCode: Int, data: Intent) {
        when(requestCode) {
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE -> {
                Log.e("Adam", "YAY")
                val imageUri = MainMenuUtils.intentToUri(data)

                listener!!.onImageSelection(imageUri)
            }
            else -> throw IllegalArgumentException("Request code: $requestCode")
        }
    }

    interface OnFragmentInteractionListener {
        fun onImageSelection(imageUri: Uri)
    }
}

object MainMenuUtils {
    const val IMAGE_PICKER_REQUEST_CODE = 1

    private const val PRE_API_19_ACCEPTED_MIME_TYPE = "image/jpeg"
    private const val API_19_ACCEPTED_MIME_TYPE_RANGE = "image/*"
    private val API_19_ACCEPTED_MIME_TYPES = arrayOf(PRE_API_19_ACCEPTED_MIME_TYPE, "image/png", "image/bmp")

    fun createImagePickerIntent() : Intent {
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

        return intent
    }

    fun intentToUri(data: Intent) : Uri {
        if (data.data == null) {
            throw IllegalStateException("Intent data is null")
        }
        return data.data!!
    }
}

