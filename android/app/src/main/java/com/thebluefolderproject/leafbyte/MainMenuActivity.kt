package com.thebluefolderproject.leafbyte

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.opencv.android.OpenCVLoader
import java.lang.RuntimeException

class MainMenuActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main_menu)

        if (!OpenCVLoader.initDebug()) {
            throw RuntimeException("Failed to initialize OpenCV")
        }
    }

    fun chooseImageFromGallery(@Suppress(UNUSED) view: View) {
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
                val uri = MainMenuUtils.intentToUri(data)

                val backgroundRemovalIntent = Intent(this, BackgroundRemovalActivity::class.java).apply {
                    putExtra(BackgroundRemovalUtils.IMAGE_URI_EXTRA_KEY, uri.toString())
                }
                startActivity(backgroundRemovalIntent)
            }
            else -> throw IllegalArgumentException("Request code: $requestCode")
        }
    }
}

