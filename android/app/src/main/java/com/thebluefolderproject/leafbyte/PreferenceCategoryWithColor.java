package com.thebluefolderproject.leafbyte;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.View;
import android.widget.TextView;

import androidx.preference.PreferenceCategory;
import androidx.preference.PreferenceViewHolder;

public class PreferenceCategoryWithColor extends PreferenceCategory {
    public PreferenceCategoryWithColor(Context context) {
        super(context);
    }
    public PreferenceCategoryWithColor(Context context, AttributeSet attrs) {
        super(context, attrs);
    }
    public PreferenceCategoryWithColor(Context context, AttributeSet attrs,
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
