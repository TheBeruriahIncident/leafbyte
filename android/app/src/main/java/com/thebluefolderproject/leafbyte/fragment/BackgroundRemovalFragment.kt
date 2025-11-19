@file:Suppress("all")
/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.content.ContentResolver
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.view.Menu
import android.view.MenuItem
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AlertDialog
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Slider
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableFloatState
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.createExampleImage
import com.thebluefolderproject.leafbyte.utils.createHistogram
import me.saket.telephoto.zoomable.DoubleClickToZoomListener
import me.saket.telephoto.zoomable.ZoomSpec
import me.saket.telephoto.zoomable.rememberZoomableState
import me.saket.telephoto.zoomable.zoomable
import org.opencv.android.Utils
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.MatOfFloat
import org.opencv.core.MatOfInt
import org.opencv.core.Point
import org.opencv.core.Scalar
import org.opencv.imgproc.Imgproc
import java.util.Arrays
import kotlin.math.roundToInt

// fun onCreateView(
//    inflater: LayoutInflater,
//    container: ViewGroup?,
//    savedInstanceState: Bundle?,
// ): View? {
//
//    var bitmap = BitmapFactory.decodeStream(requireActivity().contentResolver.openInputStream(uri), null, null)
//    // TODO: see if scaled decoding is good enough, noting that it's only powers of two
//    bitmap = Bitmap.createScaledBitmap(bitmap!!, 1200, 1200, true)
//
//    val otsu = otsu(bitmap)
//
//    val thresholdedImage = threshold(bitmap, otsu)
//
//    val seekBar = view.findViewById<SeekBar>(R.id.seekBar)
//    seekBar.progress = otsu.roundToInt()
//    seekBar.max = 255
//    seekBar.setOnSeekBarChangeListener(
//        object : SeekBar.OnSeekBarChangeListener {
//            override fun onStartTrackingTouch(p0: SeekBar?) {
//            }
//
//            override fun onStopTrackingTouch(p0: SeekBar?) {
//            }
//
//            override fun onProgressChanged(
//                p0: SeekBar?,
//                p1: Int,
//                p2: Boolean,
//            ) {
//                val bitmap = threshold(bitmap, p1.toDouble())
//                imageView.setImageBitmap(bitmap)
//            }
//        },
//    )
//
//    setHasOptionsMenu(true)
//
//    return ComposeView(requireContext()).apply {
//        setContent {
//            BackgroundRemovalScreen(bitmap) { listener!!.doneBackgroundRemoval(it) }
//        }
//    }
// }

// https://stackoverflow.com/a/17839597/1092672
fun lessResolution(
    resolver: ContentResolver,
    uri: Uri,
    width: Int,
    height: Int,
): Bitmap {
    val reqHeight = height
    val reqWidth = width
    val options = BitmapFactory.Options()
    // First decode with inJustDecodeBounds=true to check dimensions
    options.inJustDecodeBounds = true
    BitmapFactory.decodeStream(resolver.openInputStream(uri), null, options)
    // Calculate inSampleSize
    options.inSampleSize = calculateInSampleSize(options, reqWidth, reqHeight)
    // Decode bitmap with inSampleSize set
    options.inJustDecodeBounds = false
    return BitmapFactory.decodeStream(resolver.openInputStream(uri), null, options)!!
}

private fun calculateInSampleSize(
    options: BitmapFactory.Options,
    reqWidth: Int,
    reqHeight: Int,
): Int {
    val height = options.outHeight
    val width = options.outWidth
    var inSampleSize = 1
    if (height > reqHeight || width > reqWidth) {
        // Calculate ratios of height and width to requested height and width
        val heightRatio = Math.round(height.toFloat() / reqHeight.toFloat())
        val widthRatio = Math.round(width.toFloat() / reqWidth.toFloat())
        // Choose the smallest ratio as inSampleSize value, this will guarantee
        // a final image with both dimensions larger than or equal to the
        // requested height and width.
        inSampleSize = if (heightRatio < widthRatio) heightRatio else widthRatio
    }
    return inSampleSize
}

fun onCreateOptionsMenu(
    context: Context,
    menu: Menu,
) {
    val homeButton = menu.add("Home")
    homeButton.setShowAsAction(MenuItem.SHOW_AS_ACTION_WITH_TEXT or MenuItem.SHOW_AS_ACTION_IF_ROOM)
    homeButton.setIcon(R.drawable.home)
    homeButton.setOnMenuItemClickListener {
        true
    }

    val helpButton = menu.add("Help")
    helpButton.setShowAsAction(MenuItem.SHOW_AS_ACTION_WITH_TEXT or MenuItem.SHOW_AS_ACTION_IF_ROOM)
    helpButton.setIcon(R.drawable.galleryicon)
    helpButton.setOnMenuItemClickListener {
        AlertDialog
            .Builder(context)
            .setMessage(
                "First, we remove any background to leave just the leaf and scale. LeafByte looks at the brightness of different " +
                    "parts of the image to try to do this automatically, but you can move the slider to tweak.\n" +
                    "\n" +
                    "(Above the slider you'll see a histogram of brightnesses in the image; when you move the slider, you're " +
                    "actually choosing what brightnesses count as background vs foreground)",
            ).show()
        true
    }
}

@Suppress("MagicNumber")
fun threshold(
    bitmap: Bitmap,
    threshold: Double,
): Bitmap {
    // first convert bitmap into OpenCV mat object
    val imageMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(4.0),
        )
    val myBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
    Utils.bitmapToMat(myBitmap, imageMat)

    // now convert to gray
    val grayMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(1.0),
        )
    Imgproc.cvtColor(imageMat, grayMat, Imgproc.COLOR_RGB2GRAY, 1)

    // get the thresholded image
    val thresholdMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(1.0),
        )
    Imgproc.threshold(grayMat, thresholdMat, threshold.toDouble(), 255.0, Imgproc.THRESH_BINARY_INV)

    val maskedImageMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(4.0),
        )
    imageMat.copyTo(maskedImageMat, thresholdMat)

    // convert back to bitmap for displaying
    val resultBitmap =
        Bitmap.createBitmap(
            bitmap.width,
            bitmap.height,
            Bitmap.Config.ARGB_8888,
        )
    thresholdMat.convertTo(thresholdMat, CvType.CV_8UC1)
    Utils.matToBitmap(maskedImageMat, resultBitmap)

    return resultBitmap
}

@Suppress("MagicNumber", "UnsafeCallOnNullableType")
fun createHistogram(bitmap: Bitmap): Bitmap {
    // first convert bitmap into OpenCV mat object
    val imageMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(4.0),
        )
    val myBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
    Utils.bitmapToMat(myBitmap, imageMat)

    // now convert to gray
    val grayMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(1.0),
        )
    Imgproc.cvtColor(imageMat, grayMat, Imgproc.COLOR_RGB2GRAY, 1)

    val histogram = Mat()

    Imgproc.calcHist(Arrays.asList(grayMat), MatOfInt(0), Mat(), histogram, MatOfInt(256), MatOfFloat(0f, 255f))
    val histogramList = (0..255).asIterable().map { bin -> histogram.get(bin, 0)[0] }
    val maxValue = (histogramList.maxOrNull()!! + 1).toInt()

    // black
    val color = Scalar(0.0, 0.0, 0.0, 255.0)
    val graphHeight = 100
    val factor = graphHeight.toDouble() / maxValue.toDouble()
    // create transparent background
    val graphMat = Mat(graphHeight, 256, CvType.CV_8UC4, Scalar(0.0, 0.0, 0.0, 0.0))

    for (i in 0..255) {
        val bPoint1 = Point(i.toDouble(), graphHeight.toDouble())
        val bPoint2 = Point(i.toDouble(), graphHeight - histogram.get(i, 0)[0] * factor)
        Imgproc.line(graphMat, bPoint1, bPoint2, color, 1, 8, 0)
    }

    val graphBitmap = Bitmap.createBitmap(graphMat.cols(), graphMat.rows(), Bitmap.Config.ARGB_8888)
    Utils.matToBitmap(graphMat, graphBitmap)

    return graphBitmap
}

@Suppress("MagicNumber")
fun otsu(bitmap: Bitmap): Double {
    // first convert bitmap into OpenCV mat object
    val imageMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(4.0),
        )
    val myBitmap = bitmap.copy(Bitmap.Config.ARGB_8888, true)
    Utils.bitmapToMat(myBitmap, imageMat)

    // now convert to gray
    val grayMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(1.0),
        )
    Imgproc.cvtColor(imageMat, grayMat, Imgproc.COLOR_RGB2GRAY, 1)

    // get the thresholded image
    val thresholdMat =
        Mat(
            bitmap.height,
            bitmap.width,
            CvType.CV_8U,
            Scalar(1.0),
        )
    return Imgproc.threshold(grayMat, thresholdMat, -1.0, 255.0, Imgproc.THRESH_OTSU)
}

const val MAX_ZOOM = 50f
const val DOUBLE_TAP_ZOOM = 4f

@RequiresApi(Build.VERSION_CODES.O)
@Preview(showBackground = true, device = Devices.PIXEL)
@Suppress("detekt:style:MagicNumber")
@Composable
fun preview() {
    val bitmap = createExampleImage()
    LogiclessBackgroundRemovalScreen(
        thresholdedImage = remember { derivedStateOf { bitmap } },
        histogram = createHistogram(),
        thresoldVal = remember { mutableFloatStateOf(100f) },
    ) {}
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BackgroundRemovalScreen(
    originalImage: Bitmap,
    onPressingNext: (Bitmap) -> Unit,
) {
    val histogram = remember { createHistogram(originalImage) }

    val otsu = remember { otsu(originalImage) }
    val threshold = remember { mutableFloatStateOf(otsu.toFloat()) } // threshold is from 0 to 255
    // rounding to re-threshold less often
    val roundedThreshold = remember { derivedStateOf { ((threshold.floatValue * 2).roundToInt()).toFloat() / 2 } }

    // TODO should we also spin this off the main thresh
    val thresholdedImage = remember { derivedStateOf { threshold(originalImage, roundedThreshold.value.toDouble()) } }

    LogiclessBackgroundRemovalScreen(thresholdedImage, histogram, threshold, onPressingNext)
}

// Pulled out since compose preview can't handle linked libraries, like opencv
@Composable
fun LogiclessBackgroundRemovalScreen(
    thresholdedImage: State<Bitmap>,
    histogram: Bitmap,
    thresoldVal: MutableFloatState,
    onPressingNext: (Bitmap) -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize(),
    ) {
        Image(
            bitmap = thresholdedImage.value.asImageBitmap(),
            modifier =
                Modifier.zoomable(
                    state = rememberZoomableState(zoomSpec = ZoomSpec(maxZoomFactor = MAX_ZOOM)),
                    onDoubleClick = DoubleClickToZoomListener.cycle(DOUBLE_TAP_ZOOM),
                ),
            contentDescription = "The  leaf with background being removed",
        )
        Image(
            bitmap = histogram.asImageBitmap(),
            modifier = Modifier.fillMaxWidth(),
            contentScale = ContentScale.FillBounds,
            contentDescription = "A histogram representing intensity values in the image",
        )
        Slider(
            value = thresoldVal.floatValue,
            modifier = Modifier.fillMaxWidth(),
            // TODO maybe limit frequency somehow
            onValueChange = { thresoldVal.floatValue = it.toFloat() },
            valueRange = 0f..255f,
        )
        Row(
            horizontalArrangement = Arrangement.End,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextButton(
                onClick = { onPressingNext(thresholdedImage.value) },
            ) {
                Text("Next", color = BUTTON_COLOR)
            }
        }
    }
}
