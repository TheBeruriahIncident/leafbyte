package com.thebluefolderproject.leafbyte.fragment

import android.content.Context
import android.graphics.*
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProviders
import com.thebluefolderproject.leafbyte.*
import com.thebluefolderproject.leafbyte.utils.Point
import com.thebluefolderproject.leafbyte.activity.WorkflowViewModel
import com.thebluefolderproject.leafbyte.utils.LayeredIndexableImage
import com.thebluefolderproject.leafbyte.utils.labelConnectedComponents
import com.thebluefolderproject.leafbyte.utils.log


// TODO: Rename parameter arguments, choose names that match
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
class ScaleIdentificationFragment : Fragment() {
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null
    private var listener: OnFragmentInteractionListener? = null
    var model: WorkflowViewModel? = null

    var dotCenters: List<Point>? = null;

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment
        val view = inflater.inflate(R.layout.fragment_scale_identification, container, false)

        view.findViewById<Button>(R.id.scaleIdentificationNext).setOnClickListener { listener!!.doneScaleIdentification(dotCenters!!) }

        activity!!.let {
            model = ViewModelProviders.of(activity!!).get(WorkflowViewModel::class.java)
        }

        val bitmap = model!!.thresholdedImage!!
        //view.findViewById<ImageView>(R.id.imageView).setImageBitmap(bitmap)


        log("Trying to find centers: " + bitmap.width + " " + bitmap.height)
        val info = labelConnectedComponents(LayeredIndexableImage(bitmap.width, bitmap.height, bitmap), listOf())
        log("done labeling")

        val dotLabels = info.labelToSize.entries
            .filter { entry -> entry.key > 0 }
            .sortedByDescending { entry -> entry.value.total() }
            .take(5)
            .drop(1)
            .map { entry -> entry.key }
        // find center of point, draw dot
        val dotCenters = dotLabels.map { dot -> info.labelToMemberPoint.get(dot)!! }

        val bmOverlay = Bitmap.createBitmap(bitmap.getWidth(), bitmap.getHeight(), bitmap.getConfig())
        val canvas = Canvas(bmOverlay)
        val paint = Paint()
        paint.setColor(Color.RED)
        canvas.drawBitmap(bitmap, Matrix(), null)
        dotCenters.forEach { canvas.drawCircle(it.x.toFloat(), it.y.toFloat(), 8.0f, paint) }
        view.findViewById<ImageView>(R.id.imageView).setImageBitmap(bmOverlay)

        log("Found centers: " + dotCenters)
        this.dotCenters = dotCenters
        return view
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
        fun doneScaleIdentification(scaleMarks: List<Point>)
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
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            ScaleIdentificationFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}
