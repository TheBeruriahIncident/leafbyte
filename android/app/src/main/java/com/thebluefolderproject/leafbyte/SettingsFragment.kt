package com.thebluefolderproject.leafbyte

import android.content.Context
import android.net.Uri
import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import androidx.appcompat.app.AlertDialog
import androidx.lifecycle.ViewModelProviders
import androidx.preference.EditTextPreference
import androidx.preference.Preference
import androidx.preference.PreferenceFragmentCompat


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

        val button: Preference = preferenceManager.findPreference("use_previous_dataset")!!
        button.setOnPreferenceClickListener {
            debug("clicked")

            val builder = AlertDialog.Builder(context!!)
            //builder.setTitle("Choose an animal")

            val animals = arrayOf("Hello", "Goodbye")
            builder.setItems(animals) { dialog, which ->
                //commit vs apply
                preferenceManager.sharedPreferences.edit().putString("dataset_name_preference", animals.get(which)).apply()
                //setPreferencesFromResource(R.xml.preferences, rootKey)

                // HACKHACK
                onCreatePreferences(savedInstanceState, rootKey)
            }

            val dialog = builder.create()
            dialog.show()

            true
        }
    }
}
