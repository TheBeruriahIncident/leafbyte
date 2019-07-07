package com.thebluefolderproject.leafbyte

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.widget.ImageView
import android.widget.SeekBar
import androidx.appcompat.app.AppCompatActivity
import org.opencv.imgproc.Imgproc
import android.util.Log
import org.opencv.android.Utils
import org.opencv.core.*
import java.util.*
import org.opencv.core.Scalar
import org.opencv.core.CvType
import org.opencv.core.Mat




class BackgroundRemovalActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_background_removal)

        val uri = Uri.parse(intent.getStringExtra(BackgroundRemovalUtils.IMAGE_URI_EXTRA_KEY))
        val bitmap = BitmapFactory.decodeStream(contentResolver.openInputStream(uri), null, null)
        val imageView = findViewById<ImageView>(R.id.imageView)
        val histogramView = findViewById<ImageView>(R.id.histogram)
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

        val histogram = calculateHistogram(bitmap, histogramView)
        Log.e("ADAM", "$histogram")
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

    fun calculateHistogram(bitmap: Bitmap, histogramView: ImageView) : List<Double> {
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

        val histogram = Mat()


        Imgproc.calcHist(Arrays.asList(grayMat), MatOfInt(0), Mat(), histogram, MatOfInt(256),   MatOfFloat(0f, 256f))
        val histogramList = (0..255).asIterable().map { bin -> histogram.get(bin, 0)[0] }
        val maxValue = (histogramList.max()!! + 1).toInt()

        val color = Scalar (220.0, 0.0, 0.0, 255.0)
        val graphHeight = 100
        val factor = graphHeight.toDouble() / maxValue
        val graphMat = Mat(graphHeight, 256, CvType.CV_8UC3, Scalar(0.0, 0.0, 0.0))
        Log.e("Adam", "$maxValue")


        for(i in 0..255) {
            val bPoint1 = Point(i.toDouble(), graphHeight.toDouble());
            val bPoint2 = Point(i.toDouble(), graphHeight - histogram.get(i, 0)[0] * factor);
            Imgproc.line(graphMat, bPoint1, bPoint2, color, 1, 8, 0);
        }


        val graphBitmap = Bitmap.createBitmap(graphMat.cols(), graphMat.rows(), Bitmap.Config.ARGB_8888)
        Utils.matToBitmap(graphMat, graphBitmap)

        // show histogram
        histogramView.setImageBitmap(graphBitmap)



        return histogramList
    }
}

object BackgroundRemovalUtils {
    const val IMAGE_URI_EXTRA_KEY = "IMAGE_URI"
}
