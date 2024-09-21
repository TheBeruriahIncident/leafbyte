/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.activity

import android.graphics.Bitmap
import android.net.Uri
import androidx.lifecycle.ViewModel
import com.thebluefolderproject.leafbyte.utils.Point

class WorkflowViewModel : ViewModel() {
    public var uri: Uri? = null
    public var thresholdedImage: Bitmap? = null
    public var scaleMarks: List<Point>? = null
}
