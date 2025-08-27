/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.activity

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.graphics.Bitmap
import android.net.Uri
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProviders
import androidx.navigation.NavOptions
import androidx.navigation.findNavController
import androidx.preference.PreferenceManager
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.fragment.BackgroundRemovalFragment
import com.thebluefolderproject.leafbyte.fragment.MainMenuFragment
import com.thebluefolderproject.leafbyte.fragment.ResultsFragment
import com.thebluefolderproject.leafbyte.fragment.ScaleIdentificationFragment
import com.thebluefolderproject.leafbyte.fragment.TutorialFragment
import com.thebluefolderproject.leafbyte.utils.Point
import org.opencv.android.OpenCVLoader

@SuppressLint("all")
@Suppress("all")
class LeafByteActivity :
    AppCompatActivity(),
    MainMenuFragment.OnFragmentInteractionListener,
    BackgroundRemovalFragment.OnFragmentInteractionListener,
    ScaleIdentificationFragment.OnFragmentInteractionListener,
    ResultsFragment.OnFragmentInteractionListener,
    TutorialFragment.OnFragmentInteractionListener {
    override fun openSettings() {
        findNavController(R.id.nav_host_fragment).navigate(R.id.settingsFragment)
    }

    override fun goHome() {
        findNavController(R.id.nav_host_fragment).navigate(R.id.mainMenuFragment)
    }

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

        PreferenceManager
            .getDefaultSharedPreferences(baseContext)
            .edit()
            .clear()
            .apply()

        model = ViewModelProviders.of(this).get(WorkflowViewModel::class.java)
    }

    override fun onImageSelection(imageUri: Uri) {
        // TODO: hide and show properly
        supportActionBar!!.show()
        model.uri = imageUri
        findNavController(R.id.nav_host_fragment).navigate(R.id.backgroundRemovalFragment)
    }

    override fun doneBackgroundRemoval(bitmap: Bitmap) {
        model.thresholdedImage = bitmap
        findNavController(R.id.nav_host_fragment).navigate(R.id.scaleIdentificationFragment)
    }

    override fun doneScaleIdentification(scaleMarks: List<Point>) {
        model.scaleMarks = scaleMarks
        findNavController(R.id.nav_host_fragment).navigate(R.id.resultsFragment)
    }

    override fun doneResults() {
        findNavController(R.id.nav_host_fragment).navigate(
            R.id.backgroundRemovalFragment,
            null,
            NavOptions
                .Builder()
                .setPopUpTo(
                    R.id.mainMenuFragment,
                    false,
                ).build(),
        )
    }

    override fun doneTutorial() {
        // TODO: resize here and elsewhere
        model.uri = resourceToUri(R.drawable.example_leaf)
        findNavController(R.id.nav_host_fragment).navigate(R.id.backgroundRemovalFragment)
    }

    fun resourceToUri(resID: Int): Uri =
        Uri.parse(
            ContentResolver.SCHEME_ANDROID_RESOURCE + "://" +
                getResources().getResourcePackageName(resID) + '/'.toString() +
                getResources().getResourceTypeName(resID) + '/'.toString() +
                getResources().getResourceEntryName(resID),
        )
}
