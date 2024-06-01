/**
 * Copyright © 2020 Zoe Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.view

import android.content.Context
import android.util.AttributeSet
import androidx.preference.EditTextPreference

class TrimmingEditTextPreference : EditTextPreference {
    constructor(
        context: Context,
        attrs: AttributeSet?,
        defStyle: Int
    ) : super(context, attrs, defStyle) {
    }

    constructor(context: Context, attrs: AttributeSet?) : super(
        context,
        attrs
    ) {
    }

    constructor(context: Context) : super(context) {}

    override fun setText(text: String?) {
        super.setText(text?.trim())
    }
}