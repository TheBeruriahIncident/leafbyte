package com.thebluefolderproject.leafbyte

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import androidx.appcompat.app.AlertDialog
import androidx.core.widget.addTextChangedListener
import androidx.lifecycle.ViewModelProviders
import androidx.preference.EditTextPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat
import java.lang.Exception


// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

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
            //builder.setTitle("Choose an animal")

            val animals = arrayOf("Hello", "Goodbye")
            builder.setItems(animals) { dialog, which ->
                //commit vs apply
                //preferenceManager.sharedPreferences.edit().putString("dataset_name_preference", animals.get(which)).apply()
                //setPreferencesFromResource(R.xml.preferences, rootKey)

                // HACKHACK
                //onCreatePreferences(savedInstanceState, rootKey)

                datasetName.text = animals[which]
            }

            val dialog = builder.create()
            dialog.show()

            true
        }


        val scaleLengthPreference: EditTextPreference = preferenceManager.findPreference("scale_length_preference")!!
        // derived from https://stackoverflow.com/a/59297100/1092672
        scaleLengthPreference.setOnBindEditTextListener(EditTextPreference.OnBindEditTextListener { editText ->
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
        })
    }
}
