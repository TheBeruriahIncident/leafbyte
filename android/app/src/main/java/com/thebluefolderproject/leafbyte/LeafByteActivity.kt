package com.thebluefolderproject.leafbyte

import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProviders
import androidx.navigation.findNavController
import androidx.navigation.fragment.NavHostFragment
import org.opencv.android.OpenCVLoader

class LeafByteActivity : AppCompatActivity(),
        MainMenuFragment.OnFragmentInteractionListener, BackgroundRemovalFragment.OnFragmentInteractionListener {
    lateinit var model: WorkflowViewModel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_leaf_byte)

        if (!OpenCVLoader.initDebug()) {
            throw RuntimeException("Failed to initialize OpenCV")
        }

        model = ViewModelProviders.of(this).get(WorkflowViewModel::class.java)
    }

    override fun onImageSelection(imageUri: Uri) {
        model.uri = imageUri
        debug(model)
        findNavController(R.id.nav_host_fragment).navigate(R.id.backgroundRemovalFragment)
    }
}
