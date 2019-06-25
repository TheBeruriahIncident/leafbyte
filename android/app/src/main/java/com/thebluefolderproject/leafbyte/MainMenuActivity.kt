package com.thebluefolderproject.leafbyte

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity

class MainMenuActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_menu)
    }

    fun chooseImageFromGallery(@Suppress(UNUSED) view: View) {
        val imagePickerIntent = Intent(Intent.ACTION_GET_CONTENT, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        MainMenuUtils.configureImagePickerIntent(imagePickerIntent)

        startActivityForResult(
            Intent.createChooser(imagePickerIntent, MainMenuUtils.IMAGE_PICKER_CHOOSER_TITLE),
            MainMenuUtils.IMAGE_PICKER_REQUEST_CODE)
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
            // API level 19 added the ability to
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                type = API_19_ACCEPTED_MIME_TYPE_RANGE
                putExtra(Intent.EXTRA_MIME_TYPES, API_19_ACCEPTED_MIME_TYPES)
            } else {
                type = PRE_API_19_ACCEPTED_MIME_TYPE
            }
        }
    }
}
