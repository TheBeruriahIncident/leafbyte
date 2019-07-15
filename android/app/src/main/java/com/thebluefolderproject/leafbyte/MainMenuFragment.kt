package com.thebluefolderproject.leafbyte

import android.app.Activity
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


// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [MainMenuFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [MainMenuFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
class MainMenuFragment : Fragment() {
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_main_menu, container, false)
        view.findViewById<Button>(R.id.chooseFromGalleryButton).setOnClickListener { chooseImageFromGallery() }

        return view
    }

    fun chooseImageFromGallery() {
        val imagePickerIntent = Intent(Intent.ACTION_GET_CONTENT, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        MainMenuUtils.configureImagePickerIntent(imagePickerIntent)

        startActivityForResult(
            Intent.createChooser(imagePickerIntent, MainMenuUtils.IMAGE_PICKER_CHOOSER_TITLE),
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        when(resultCode) {
            Activity.RESULT_OK -> {
                if (data == null) {
                    throw IllegalArgumentException("Intent data is null")
                }

                processActivityResultData(requestCode, data)
            }
            else -> throw IllegalArgumentException("Result code: $resultCode")
        }
    }

    private fun processActivityResultData(requestCode: Int, data: Intent) {
        when(requestCode) {
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE -> {
                Log.e("Adam", "YAY")
//                val uri = MainMenuUtils.intentToUri(data)
//
//                val backgroundRemovalIntent = Intent(this, BackgroundRemovalActivity::class.java).apply {
//                    putExtra(BackgroundRemovalUtils.IMAGE_URI_EXTRA_KEY, uri.toString())
//                }
//                startActivity(backgroundRemovalIntent)
            }
            else -> throw IllegalArgumentException("Request code: $requestCode")
        }
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment MainMenuFragment.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            MainMenuFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}

object MainMenuUtils {
    const val IMAGE_PICKER_CHOOSER_TITLE = "Select Image to Analyze"
    const val IMAGE_PICKER_REQUEST_CODE = 1

    private const val PRE_API_19_ACCEPTED_MIME_TYPE = "image/jpeg"
    private const val API_19_ACCEPTED_MIME_TYPE_RANGE = "image/*"
    private val API_19_ACCEPTED_MIME_TYPES = arrayOf(PRE_API_19_ACCEPTED_MIME_TYPE, "image/png", "image/bmp")

    fun configureImagePickerIntent(intent: Intent) {
        with(intent) {
            // API level 19 added the ability to request any of multiple MIME types
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                type = API_19_ACCEPTED_MIME_TYPE_RANGE
                putExtra(Intent.EXTRA_MIME_TYPES, API_19_ACCEPTED_MIME_TYPES)
            } else {
                type = PRE_API_19_ACCEPTED_MIME_TYPE
            }
        }
    }

    fun intentToUri(data: Intent) : Uri {
        if (data.data == null) {
            throw IllegalStateException("Intent data is null")
        }
        return data.data!!
    }
}

