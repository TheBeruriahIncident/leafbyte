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
import org.opencv.core.CvType
import android.R.attr.bitmap
import org.opencv.imgproc.Imgproc
import org.opencv.core.Scalar
import android.opengl.ETC1.getWidth
import android.opengl.ETC1.getHeight
import android.util.Log
import org.opencv.android.Utils
import org.opencv.core.Core
import org.opencv.core.Mat
import android.R.attr.bitmap
import android.opengl.ETC1.getWidth
import android.opengl.ETC1.getHeight





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
        // first convert bitmap into OpenCV mat object
        val imageMat = Mat(
            bitmap.height, bitmap.width,
            CvType.CV_8U, Scalar(4.0)
        )
        val myBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
        Utils.bitmapToMat(myBitmap, imageMat)

        // now convert to gray
        val grayMat = Mat(
            bitmap.height, bitmap.width,
            CvType.CV_8U, Scalar(1.0)
        )
        Imgproc.cvtColor(imageMat, grayMat, Imgproc.COLOR_RGB2GRAY, 1)

        // get the thresholded image
        val thresholdMat = Mat(
            bitmap.height, bitmap.width,
            CvType.CV_8U, Scalar(1.0)
        )
        Imgproc.threshold(grayMat, thresholdMat, threshold.toDouble(), 255.0, Imgproc.THRESH_BINARY_INV)

        val maskedImageMat = Mat(
            bitmap.height, bitmap.width,
            CvType.CV_8U, Scalar(4.0)
        )
        imageMat.copyTo(maskedImageMat, thresholdMat)

        // convert back to bitmap for displaying
        val resultBitmap = Bitmap.createBitmap(
            bitmap.width, bitmap.height,
            Bitmap.Config.ARGB_8888
        )
        thresholdMat.convertTo(thresholdMat, CvType.CV_8UC1)
        Utils.matToBitmap(maskedImageMat, resultBitmap)

        return resultBitmap
    }
}

object BackgroundRemovalUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
