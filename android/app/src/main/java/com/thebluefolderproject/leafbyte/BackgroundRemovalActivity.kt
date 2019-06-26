package com.thebluefolderproject.leafbyte

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.SeekBar
import androidx.appcompat.app.AppCompatActivity
import androidx.core.graphics.set

class BackgroundRemovalActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_background_removal)

        val uri = Uri.parse(intent.getStringExtra(BackgroundRemovalUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)
        val imageView = findViewById<ImageView>(R.id.imageView)
        imageView.setImageBitmap(threshold(bitmap!!, 100))

        val seekBar = findViewById<SeekBar>(R.id.seekBar)
        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onStartTrackingTouch(p0: SeekBar?) {

            }

            override fun onStopTrackingTouch(p0: SeekBar?) {

            }

            override fun onProgressChanged(p0: SeekBar?, p1: Int, p2: Boolean) {
                imageView.setImageBitmap(threshold(bitmap!!, p1 * 2))
            }

        })
    }

    fun threshold(bitmap: Bitmap, threshold: Int): Bitmap {
        val newBitmap = Bitmap.createBitmap(bitmap.width, bitmap.height, Bitmap.Config.ARGB_8888)

        for (x in 0 until bitmap.width) {
            for (y in 0 until bitmap.height) {
                val pixel = bitmap.getPixel(x, y)

                val filter = Color.red(pixel) > threshold

                newBitmap.setPixel(x, y, if (filter) bitmap.getPixel(x, y) else 0)
            }
        }

        return newBitmap
    }
}

object BackgroundRemovalUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
