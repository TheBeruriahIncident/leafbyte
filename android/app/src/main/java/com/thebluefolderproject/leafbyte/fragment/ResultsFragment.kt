/*
 * Copyright © 2019 Abigail Getman-Pickering. All rights reserved.
 */

@file:Suppress("all")

package com.thebluefolderproject.leafbyte.fragment

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.log
import me.saket.telephoto.zoomable.DoubleClickToZoomListener
import me.saket.telephoto.zoomable.ZoomSpec
import me.saket.telephoto.zoomable.rememberZoomableState
import me.saket.telephoto.zoomable.zoomable
import org.opencv.android.Utils
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.utils.Converters
import kotlin.math.atan2

// fun onCreateView(
//    inflater: LayoutInflater,
//    container: ViewGroup?,
//    savedInstanceState: Bundle?,
// ): View? {
//    val bitmap = model!!.thresholdedImage!!
//    val corrected = correct(bitmap, model!!.scaleMarks!!)
//
//    val info = labelConnectedComponents(LayeredIndexableImage(corrected.width, corrected.height, corrected))
//    val pixels =
//        info.labelToSize.entries
//            .filter { entry -> entry.key > 0 }
//            .map { entry -> entry.value }
//            .maxByOrNull { it.total() }
//    log("Number of pixels: " + pixels)
// }

fun correct(
    bitmap: Bitmap,
    dotCenters: List<Point>,
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

    // Find the center as the average of the corners.
    val center = Point(dotCenters.sumOf { it.x } / 4, dotCenters.sumOf { it.y } / 4)

    // Determine the angle from corner to the center.
    val cornersAndAngles =
        dotCenters.map { corner ->
            val angle = atan2((corner.y - center.y).toDouble(), (corner.x - center.x).toDouble())
            Pair(corner, angle)
        }

    // Sort the corners into order around the center so that we know which corner is which.
    val sortedCorners = cornersAndAngles.sortedBy { it.second }.map { it.first }
    log(sortedCorners)

    val size = 1200.0
    val size2 = 1200

    val trans =
        Imgproc.getPerspectiveTransform(
            Converters.vector_Point2f_to_Mat(
                sortedCorners.map {
                    org.opencv.core.Point(
                        it.x.toDouble(),
                        it.y.toDouble(),
                    )
                },
            ),
            Converters.vector_Point2f_to_Mat(
                listOf(
                    org.opencv.core.Point(0.0, size),
                    org.opencv.core.Point(size, size),
                    org.opencv.core.Point(size, 0.0),
                    org.opencv.core.Point(0.0, 0.0),
                ),
            ),
        )

    val output =
        Mat(
            size2,
            size2,
            CvType.CV_8U,
            Scalar(4.0),
        )
    Imgproc.warpPerspective(imageMat, output, trans, Size(size, size))

    // convert back to bitmap for displaying
    val resultBitmap =
        Bitmap.createBitmap(
            size2,
            size2,
            Bitmap.Config.ARGB_8888,
        )
    output.convertTo(output, CvType.CV_8UC1)
    Utils.matToBitmap(output, resultBitmap)

    return resultBitmap
}

@Composable
fun ResultsScreen(
    image: Bitmap,
    onPressingNext: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize(),
    ) {
        Image(
            bitmap = image.asImageBitmap(),
            modifier =
                Modifier.zoomable(
                    state = rememberZoomableState(zoomSpec = ZoomSpec(maxZoomFactor = MAX_ZOOM)),
                    onDoubleClick = DoubleClickToZoomListener.cycle(DOUBLE_TAP_ZOOM),
                ),
            contentDescription = "The leaf with area being measured",
        )
        Row(
            horizontalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextButton(
                onClick = { },
            ) {
                Text("Draw", color = BUTTON_COLOR)
            }
            TextButton(
                onClick = { },
            ) {
                Text("Exclude Area", color = BUTTON_COLOR)
            }
            TextButton(
                onClick = { onPressingNext() },
            ) {
                Text("Next", color = BUTTON_COLOR)
            }
        }
    }
}
