package com.thebluefolderproject.leafbyte

import android.net.Uri
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle

class LeafByteActivity : AppCompatActivity(), MainMenuFragment.OnFragmentInteractionListener {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_leaf_byte)
    }

    override fun onImageSelection(imageUri: Uri) {
        // TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }
}
