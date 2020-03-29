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

    private fun getAllPreferenceKeys(): List<String> {
        // don't show up for some reason
        val keys = mutableListOf("sign_out_of_google", "use_previous_dataset", "website", "team", "citation", "version")
        keys.addAll(preferenceScreen.sharedPreferences.all.keys)

        return keys
    }

    private fun setup() {
        for (i in 0 until preferenceScreen.preferenceCount) {
            val preference = preferenceScreen.getPreference(i)

            preference.isIconSpaceReserved = false
        }

        getAllPreferenceKeys().forEach { key ->
            val preference: Preference = preferenceManager.findPreference(key)!!
            // every pref needs this or else it's misaligned
            preference.isIconSpaceReserved = false

            if (key == "scale_length") {
                return@forEach
            }
            if (preference is ListPreference) {
                preference.summaryProvider = ListPreference.SimpleSummaryProvider.getInstance()
            } else if (preference is EditTextPreference) {
                preference.summaryProvider = EditTextPreference.SimpleSummaryProvider.getInstance()
            }
        }
    }

    override fun onCreatePreferences(savedInstanceState: Bundle?, rootKey: String?) {
        setPreferencesFromResource(R.xml.preferences_layout, rootKey)

        setup()



        val datasetName: EditTextPreference = preferenceManager.findPreference("dataset_name")!!
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

        val scaleLengthUnitPreference: ListPreference = preferenceManager.findPreference("scale_length_units")!!

        val scaleLengthPreference: EditTextPreference = preferenceManager.findPreference("scale_length")!!
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
        scaleLengthPreference.summary = "Length of one side of the scale square from dot center to dot center\n\n" + scaleLengthPreference.text + " " + scaleLengthUnitPreference.value
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
