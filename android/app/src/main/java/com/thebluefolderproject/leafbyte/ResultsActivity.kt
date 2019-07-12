package com.thebluefolderproject.leafbyte

import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.util.DisplayMetrics
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity


class ResultsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_results)

        val uri = Uri.parse(intent.getStringExtra(ResultsUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)

        val paintView = findViewById<PaintView>(R.id.paintView)
        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        paintView.init(metrics)
    }
}

object ResultsUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
