/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.fragment.app.Fragment
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.IconButton
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize

// TO DO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [TutorialFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [TutorialFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
@Suppress("all")
class TutorialFragment : Fragment() {
    // TODO: Rename and change types of parameters
    private var param1: String? = null
    private var param2: String? = null
    private var listener: OnFragmentInteractionListener? = null

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
    ): View? =
        ComposeView(requireContext()).apply {
            setContent {
                TutorialScreen({ listener!!.doneTutorial() })
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
        fun doneTutorial()
    }

    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment TutorialFragment.
         */
        @JvmStatic // TODO: Rename and change types and number of parameters
        fun newInstance(
            param1: String,
            param2: String,
        ) = TutorialFragment().apply {
            arguments =
                Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
        }
    }
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun TutorialScreenPreview() {
    TutorialScreen({})
}

@OptIn(ExperimentalMaterial3Api::class)
@Suppress("detekt:complexity:LongMethod")
@Composable
fun TutorialScreen(onPressingNext: () -> Unit) {
    Column(
        modifier =
            Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        TopAppBar(
            navigationIcon = {
                TextButton(
                    onClick = { onPressingNext() },
                ) {
                    Text("Back", color = BUTTON_COLOR)
                }
            },
            actions = {
                IconButton(
                    onClick = {},
                ) {
                    Icon(painterResource(id = R.drawable.home), tint = BUTTON_COLOR, contentDescription = null)
                }
            },
            title = {},
        )
        Text(
            text = "LeafByte lets you quickly and accurately measure leaf area and herbivory.",
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = "We use images of leaves like this one:",
            modifier = Modifier.fillMaxWidth(),
        )
        Image(
            painter = painterResource(id = R.drawable.example_leaf),
            contentDescription = "Camera icon",
            @Suppress("detekt:style:MagicNumber")
            Modifier.fillMaxWidth(.7f),
        )
        Text(
            text =
                "Note that the leaf is within four dots that form a square of known size (the \"scale\"). This lets us correct for " +
                    "the angle the image was taken at and determine absolute sizes.*",
            modifier = Modifier.fillMaxWidth(),
        )
        Text(
            text = "You can take a photo or use an image you already have. For the tutorial, we'll just use this image.",
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(modifier = Modifier.height(5.dp))
        Text(
            // TODO link this and iphone
            text = "*See the website for a printout with a scale and other details and tips.",
            modifier = Modifier.fillMaxWidth(),
            size = TextSize.FOOTNOTE,
        )
        Row(
            horizontalArrangement = Arrangement.End,
            modifier = Modifier.fillMaxWidth(),
        ) {
            TextButton(
                onClick = { onPressingNext() },
            ) {
                Text("Next", color = BUTTON_COLOR)
            }
        }
    }
}
