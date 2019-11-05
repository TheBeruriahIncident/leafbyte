package com.thebluefolderproject.leafbyte

import android.graphics.Bitmap
import android.net.Uri
import androidx.lifecycle.ViewModel

class WorkflowViewModel : ViewModel() {
    public var uri: Uri? = null
    public var thresholdedImage: Bitmap? = null
    public var scaleMarks: List<Point>? = null
}