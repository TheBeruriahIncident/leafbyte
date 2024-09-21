/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProviders
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.WorkflowViewModel
import com.thebluefolderproject.leafbyte.utils.LayeredIndexableImage
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.utils.labelConnectedComponents
import com.thebluefolderproject.leafbyte.utils.log
import org.opencv.android.Utils
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.utils.Converters
import kotlin.math.atan2

// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [ResultsFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [ResultsFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
@SuppressLint("all")
class ResultsFragment : Fragment() {
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
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_results, container, false)

        view.findViewById<Button>(R.id.resultsNext).setOnClickListener { listener!!.doneResults() }

        requireActivity().let {
            model = ViewModelProviders.of(requireActivity()).get(WorkflowViewModel::class.java)
        }

        val bitmap = model!!.thresholdedImage!!

        val corrected = correct(bitmap, model!!.scaleMarks!!)

        view.findViewById<ImageView>(R.id.imageView).setImageBitmap(corrected)

        val info = labelConnectedComponents(LayeredIndexableImage(corrected.width, corrected.height, corrected))
        val pixels =
            info.labelToSize.entries
                .filter { entry -> entry.key > 0 }
                .map { entry -> entry.value }
                .maxByOrNull { it.total() }
        log("Number of pixels: " + pixels)

        return view
    }

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
        val center = Point(dotCenters.sumBy { it.x } / 4, dotCenters.sumBy { it.y } / 4)

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
        fun doneResults()
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment ResultsFragment.
         */
        @JvmStatic // TODO: Rename and change types and number of parameters
        fun newInstance(
            param1: String,
            param2: String,
        ) = ResultsFragment().apply {
            arguments =
                Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
        }
    }
}
