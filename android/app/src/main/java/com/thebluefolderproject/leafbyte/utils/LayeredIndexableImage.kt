/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.utils

import android.graphics.Bitmap
import androidx.core.graphics.alpha

class LayeredIndexableImage(
    val width: Int,
    val height: Int,
    val bitmap: Bitmap,
) {
    fun getLayerWithPixel(
        x: Int,
        y: Int,
    ): Int = if (bitmap.getPixel(x, y).alpha > 0) 1 else -1
}
