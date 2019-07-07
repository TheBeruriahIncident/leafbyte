package com.thebluefolderproject.leafbyte

import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity

class ResultsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_results)

        val uri = Uri.parse(intent.getStringExtra(ResultsUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)
        val imageView2 = findViewById<ImageView>(R.id.imageView2)
        imageView2.setImageBitmap(bitmap)

    }
}

object ResultsUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
