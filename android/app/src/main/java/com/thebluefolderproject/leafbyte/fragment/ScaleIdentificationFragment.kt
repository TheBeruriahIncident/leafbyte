/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.net.Uri
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
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
import androidx.compose.ui.platform.ComposeView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProviders
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.WorkflowViewModel
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

// TO DO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [ScaleIdentificationFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [ScaleIdentificationFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
@SuppressLint("all")
@Suppress("all")
class ScaleIdentificationFragment : Fragment() {
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null
    private var listener: OnFragmentInteractionListener? = null
    var model: WorkflowViewModel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View? {

        requireActivity().let {
            model = ViewModelProviders.of(requireActivity()).get(WorkflowViewModel::class.java)
        }

        val bitmap = model!!.thresholdedImage!!

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

        return ComposeView(requireContext()).apply {
            setContent {
                ScaleIdentificationScreen(bitmap) { listener!!.doneScaleIdentification(bitmap,dotCenters) }
            }
        }
    }

    override fun onAttach(context: Context) {
        super.onAttach(context)
        if (context is OnFragmentInteractionListener) {
            listener = context
        } else {
            throw RuntimeException(context.toString() + " must implement OnFragmentInteractionListener")
        }
    }

    override fun onDetach() {
        super.onDetach()
        listener = null
    }

    /**
     * This interface must be implemented by activities that contain this
     * fragment to allow an interaction in this fragment to be communicated
     * to the activity and potentially other fragments contained in that
     * activity.
     *
     *
     * See the Android Training lesson [Communicating with Other Fragments]
     * (http://developer.android.com/training/basics/fragments/communicating.html)
     * for more information.
     */
    interface OnFragmentInteractionListener {
        // TODO: Update argument type and name
        fun doneScaleIdentification(thresholdedImage: Bitmap, scaleMarks: List<Point>)
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment ScaleIdentificationFragment.
         */
        @JvmStatic // TODO: Rename and change types and number of parameters
        fun newInstance(
            param1: String,
            param2: String,
        ) = ScaleIdentificationFragment().apply {
            arguments =
                Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
        }
    }
}

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
