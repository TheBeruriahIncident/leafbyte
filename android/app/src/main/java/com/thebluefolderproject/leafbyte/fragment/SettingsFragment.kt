/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import androidx.appcompat.app.AlertDialog
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.fragment.app.Fragment
import androidx.preference.EditTextPreference
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import com.thebluefolderproject.leafbyte.BuildConfig
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.activity.Preferences

/**
 * settings vs preferences
 *
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [SettingsFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [SettingsFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
@SuppressLint("all")
@Suppress("all")
class SettingsFragment : PreferenceFragmentCompat() {
    private fun setup(preferences: Preferences) {
        for (i in 0 until preferenceScreen.preferenceCount) {
            val preference = preferenceScreen.getPreference(i)

            preference.isIconSpaceReserved = false
        }

        preferences.allKeys.forEach { key ->
            val preference: Preference = preferenceManager.findPreference(key)!!
            // every pref needs this or else it's misaligned
            preference.isIconSpaceReserved = false

            if (key == preferences.scaleLengthKey) {
                return@forEach
            }
            if (preference is ListPreference) {
                preference.summaryProvider = ListPreference.SimpleSummaryProvider.getInstance()
            } else if (preference is EditTextPreference) {
                preference.summaryProvider = EditTextPreference.SimpleSummaryProvider.getInstance()
            }
        }
    }

    @Preview(showBackground = true, device = Devices.PIXEL)
    @Composable
    fun Settings() {
        Column(
            modifier = Modifier.fillMaxSize(),
        ) {

        }
    }

    override fun onCreatePreferences(
        savedInstanceState: Bundle?,
        rootKey: String?,
    ) {
        setPreferencesFromResource(R.layout.preferences_layout, rootKey)

        val preferences = Preferences(requireActivity())
        setup(preferences)

        val datasetName: EditTextPreference = preferenceManager.findPreference(preferences.datasetNameKey)!!
        val button: Preference = preferenceManager.findPreference(preferences.usePreviousDatasetKey)!!
        button.setOnPreferenceClickListener {
            val builder = AlertDialog.Builder(requireContext())
            val options = arrayOf("Hello", "Goodbye")
            builder.setItems(options) { dialog, which ->
                datasetName.text = options[which]
            }

            val dialog = builder.create()
            dialog.show()

            true
        }

        val websiteButton: Preference = preferenceManager.findPreference(preferences.websiteKey)!!
        websiteButton.setOnPreferenceClickListener {
            val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse("http://zoegp.science/leafbyte-faqs"))
            startActivity(browserIntent)

            true
        }

        val teamButton: Preference = preferenceManager.findPreference(preferences.teamKey)!!
        teamButton.setOnPreferenceClickListener {
            val builder = AlertDialog.Builder(requireContext())
            builder.setTitle(getString(R.string.preference_team_title))
            builder.setMessage(getString(R.string.preference_team_description))

            val dialog = builder.create()
            dialog.show()

            true
        }

        val scaleLengthUnitPreference: ListPreference = preferenceManager.findPreference(preferences.scaleLengthUnitsKey)!!

        val scaleLengthPreference: EditTextPreference = preferenceManager.findPreference(preferences.scaleLengthKey)!!
        // derived from https://stackoverflow.com/a/59297100/1092672
        scaleLengthPreference.setOnBindEditTextListener { editText ->
            try {
                editText.text.toString().toDouble()
            } catch (e: NumberFormatException) {
                editText.error = e.localizedMessage
                //                        editText.rootView.findViewById(android.R.id.button1)
                //                            .setEnabled(validationError == null);
            }

            editText.addTextChangedListener(
                object : TextWatcher {
                    override fun afterTextChanged(p0: Editable?) {
                        try {
                            p0!!.toString().toDouble()
                        } catch (e: NumberFormatException) {
                            editText.error = e.localizedMessage

                            //                        editText.rootView.findViewById(android.R.id.button1)
                            //                            .setEnabled(validationError == null);
                        }
                    }

                    override fun beforeTextChanged(
                        p0: CharSequence?,
                        p1: Int,
                        p2: Int,
                        p3: Int,
                    ) {
                    }

                    override fun onTextChanged(
                        p0: CharSequence?,
                        p1: Int,
                        p2: Int,
                        p3: Int,
                    ) {
                    }
                },
            )
        }
        scaleLengthPreference.summary = "Length of one side of the scale square from dot center to dot center\n\n" +
            scaleLengthPreference.text + " " + scaleLengthUnitPreference.value
        scaleLengthPreference.onPreferenceChangeListener =
            Preference.OnPreferenceChangeListener { preference: Preference?, newValue: Any? ->
                val newValueString: String = newValue as String
                // TODO: dont dupe this
                scaleLengthPreference.summary = newValueString + " " + scaleLengthUnitPreference.value
                true
            }

        scaleLengthUnitPreference.onPreferenceChangeListener =
            Preference.OnPreferenceChangeListener { preference: Preference?, newValue: Any? ->
                val newValueString: String = newValue as String
                // TODO: dont dupe this
                scaleLengthPreference.summary = scaleLengthPreference.text + " " + newValueString
                true
            }

        val versionPreference: Preference = preferenceManager.findPreference(preferences.versionKey)!!
        versionPreference.title = "version " + BuildConfig.VERSION_NAME
    }
}
