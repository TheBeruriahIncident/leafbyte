/*
 * Copyright © 2019 Abigail Getman-Pickering. All rights reserved.
 */

@file:Suppress("all")

package com.thebluefolderproject.leafbyte.fragment

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
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
import com.thebluefolderproject.leafbyte.utils.LayeredIndexableImage
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.labelConnectedComponents
import com.thebluefolderproject.leafbyte.utils.log
import me.saket.telephoto.zoomable.DoubleClickToZoomListener
import me.saket.telephoto.zoomable.ZoomSpec
import me.saket.telephoto.zoomable.rememberZoomableState
import me.saket.telephoto.zoomable.zoomable

//    override fun onCreateView(
//        inflater: LayoutInflater,
//        container: ViewGroup?,
//        savedInstanceState: Bundle?,
//    ): View? {
//
//        val bitmap = model!!.thresholdedImage!!
//
//        log("Trying to find centers: " + bitmap.width + " " + bitmap.height) // TODO swap to center of dots
//        val info = labelConnectedComponents(LayeredIndexableImage(bitmap.width, bitmap.height, bitmap), listOf())
//        log("done labeling")
//
//        val dotLabels =
//            info.labelToSize.entries
//                .filter { entry -> entry.key > 0 }
//                .sortedByDescending { entry -> entry.value.total() }
//                .take(5)
//                .drop(1)
//                .map { entry -> entry.key }
//        // find center of point, draw dot
//        val dotCenters = dotLabels.map { dot -> info.labelToMemberPoint.get(dot)!! }
//
//        val bmOverlay = Bitmap.createBitmap(bitmap.width, bitmap.height, bitmap.config!!)
//        val canvas = Canvas(bmOverlay)
//        val paint = Paint()
//        paint.setColor(Color.RED)
//        canvas.drawBitmap(bitmap, Matrix(), null)
//        dotCenters.forEach { canvas.drawCircle(it.x.toFloat(), it.y.toFloat(), 8.0f, paint) }
//
//        log("Found centers: " + dotCenters)
//
//    }

@Composable
fun ScaleIdentificationScreen(
    bitmap: Bitmap,
    onPressingNext: (scaleMarks: List<Point>) -> Unit,
) {
    log("Trying to find centers: " + bitmap.width + " " + bitmap.height) // TODO swap to center of dots
    val info = labelConnectedComponents(LayeredIndexableImage(bitmap.width, bitmap.height, bitmap), listOf())
    log("done labeling")

    val dotLabels =
        info.labelToSize.entries
            .filter { entry -> entry.key > 0 }
            .sortedByDescending { entry -> entry.value.total() }
            .take(5)
            .drop(1)
            .map { entry -> entry.key }
    // find center of point, draw dot
    val dotCenters = dotLabels.map { dot -> info.labelToMemberPoint.get(dot)!! }

    val bmOverlay = Bitmap.createBitmap(bitmap.width, bitmap.height, bitmap.config!!)
    val canvas = Canvas(bmOverlay)
    val paint = Paint()
    paint.setColor(Color.RED)
    canvas.drawBitmap(bitmap, Matrix(), null)
    dotCenters.forEach { canvas.drawCircle(it.x.toFloat(), it.y.toFloat(), 8.0f, paint) }

    log("Found centers: " + dotCenters)

    Column(
        modifier = Modifier.fillMaxSize(),
    ) {
        Image(
            bitmap = bitmap.asImageBitmap(),
            modifier =
                Modifier.zoomable(
                    state = rememberZoomableState(zoomSpec = ZoomSpec(maxZoomFactor = MAX_ZOOM)),
                    onDoubleClick = DoubleClickToZoomListener.cycle(DOUBLE_TAP_ZOOM),
                ),
            contentDescription = "The leaf with background being removed",
        )
        Row(
            horizontalArrangement = Arrangement.End,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextButton(
                onClick = { onPressingNext(dotCenters) },
            ) {
                Text("Next", color = BUTTON_COLOR)
            }
        }
    }
}
