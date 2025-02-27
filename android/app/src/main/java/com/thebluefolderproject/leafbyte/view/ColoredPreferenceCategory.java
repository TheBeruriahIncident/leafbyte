/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.view;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.widget.TextView;

import androidx.preference.PreferenceCategory;
import androidx.preference.PreferenceViewHolder;

public class ColoredPreferenceCategory extends PreferenceCategory {
    public ColoredPreferenceCategory(Context context) {
        super(context);
    }
    public ColoredPreferenceCategory(Context context, AttributeSet attrs) {
        super(context, attrs);
    }
    public ColoredPreferenceCategory(Context context, AttributeSet attrs,
                                     int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    public void onBindViewHolder(PreferenceViewHolder holder) {
        super.onBindViewHolder(holder);
        TextView titleView = (TextView) holder.findViewById(android.R.id.title);
        titleView.setTextColor(Color.rgb(0, 87, 75));
    }

}
