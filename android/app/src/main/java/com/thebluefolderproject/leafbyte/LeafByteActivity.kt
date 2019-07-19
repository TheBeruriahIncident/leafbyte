package com.thebluefolderproject.leafbyte

import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.lifecycle.ViewModelProviders
import androidx.navigation.findNavController
import org.opencv.android.OpenCVLoader
import android.content.ContentResolver



class LeafByteActivity : AppCompatActivity(),
        MainMenuFragment.OnFragmentInteractionListener, BackgroundRemovalFragment.OnFragmentInteractionListener, TutorialFragment.OnFragmentInteractionListener {
    override fun startTutorial() {
        findNavController(R.id.nav_host_fragment).navigate(R.id.tutorialFragment)
    }

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
        findNavController(R.id.nav_host_fragment).navigate(R.id.backgroundRemovalFragment)
    }

    override fun doneTutorial() {
        // TODO: resize here and elsewhere
        model.uri = resourceToUri(R.drawable.example_leaf)
        findNavController(R.id.nav_host_fragment).navigate(R.id.backgroundRemovalFragment)
    }

     fun resourceToUri(resID:Int):Uri {
        return Uri.parse(
            ContentResolver.SCHEME_ANDROID_RESOURCE + "://" +
            getResources().getResourcePackageName(resID) + '/'.toString() +
            getResources().getResourceTypeName(resID) + '/'.toString() +
            getResources().getResourceEntryName(resID)
        )
    }
}
