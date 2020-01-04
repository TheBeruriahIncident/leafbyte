package com.thebluefolderproject.leafbyte

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import androidx.fragment.app.Fragment
import androidx.appcompat.app.AlertDialog
import androidx.preference.EditTextPreference
import androidx.preference.ListPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [SettingsFragment.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [SettingsFragment.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
class SettingsFragment : PreferenceFragmentCompat() {

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.preferences, rootKey)

        val datasetName: EditTextPreference = preferenceManager.findPreference("dataset_name_preference")!!
        val button: Preference = preferenceManager.findPreference("use_previous_dataset")!!
        button.setOnPreferenceClickListener {
            val builder = AlertDialog.Builder(context!!)
            val options = arrayOf("Hello", "Goodbye")
            builder.setItems(options) { dialog, which ->
                datasetName.text = options[which]
            }

            val dialog = builder.create()
            dialog.show()

            true
        }

        val scaleLengthUnitPreference: ListPreference = preferenceManager.findPreference("units_preference")!!

        val scaleLengthPreference: EditTextPreference = preferenceManager.findPreference("scale_length_preference")!!
        // derived from https://stackoverflow.com/a/59297100/1092672
        scaleLengthPreference.setOnBindEditTextListener { editText ->
            try {
                editText.text.toString().toDouble()
            } catch (e: NumberFormatException) {
                editText.error = e.localizedMessage;
    //                        editText.rootView.findViewById(android.R.id.button1)
    //                            .setEnabled(validationError == null);
            }

            editText.addTextChangedListener(object : TextWatcher {
                override fun afterTextChanged(p0: Editable?) {
                    try {
                        p0!!.toString().toDouble()
                    } catch (e: NumberFormatException) {
                        editText.error = e.localizedMessage;


    //                        editText.rootView.findViewById(android.R.id.button1)
    //                            .setEnabled(validationError == null);
                    }
                }

                override fun beforeTextChanged(p0: CharSequence?, p1: Int, p2: Int, p3: Int) {
                }

                override fun onTextChanged(p0: CharSequence?, p1: Int, p2: Int, p3: Int) {
                }
            })
        }
        scaleLengthPreference.summary = scaleLengthPreference.text + " " + scaleLengthUnitPreference.value
        scaleLengthPreference.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { preference: Preference?, newValue: Any? ->
            val newValueString: String = newValue as String;
            // TODO: dont dupe this
            scaleLengthPreference.summary = newValueString + " " + scaleLengthUnitPreference.value
            true
        }

        scaleLengthUnitPreference.onPreferenceChangeListener = Preference.OnPreferenceChangeListener { preference: Preference?, newValue: Any? ->
            val newValueString: String = newValue as String;
            // TODO: dont dupe this
            scaleLengthPreference.summary = scaleLengthPreference.text + " " + newValueString
            true
        }

        val versionPreference: Preference = preferenceManager.findPreference("version")!!
        versionPreference.title = "version " + BuildConfig.VERSION_NAME
    }
}
