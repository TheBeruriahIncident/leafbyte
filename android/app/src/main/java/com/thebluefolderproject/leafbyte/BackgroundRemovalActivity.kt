package com.thebluefolderproject.leafbyte

import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity

class BackgroundRemovalActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_background_removal)

        val uri = Uri.parse(intent.getStringExtra(BackgroundRemovalUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)
        val imageView = findViewById<ImageView>(R.id.imageView)
        imageView.setImageBitmap(bitmap)
    }
}

object BackgroundRemovalUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
