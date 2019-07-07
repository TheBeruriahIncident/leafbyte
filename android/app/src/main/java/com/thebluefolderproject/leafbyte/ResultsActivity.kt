package com.thebluefolderproject.leafbyte

import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity

class ResultsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_results)

        Log.e("ADAM", "results")

        val uri = Uri.parse(intent.getStringExtra(ResultsUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)
        val imageView2 = findViewById<ImageView>(R.id.imageView2)
        //val imageView3 = findViewById<ImageView>(R.id.imageView3)
        //val imageView = ImageView(this)
        imageView2.setImageBitmap(bitmap)
        //imageView3.setImageBitmap(bitmap)

        //val zoomView = ZoomView(this)
        //zoomView.addView(imageView)
        //val zoom = findViewById<ZoomView>(R.id.zoom)
        //zoom.addView(imageView2)

        Log.e("ADAM", "after results")
    }
}

object ResultsUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
