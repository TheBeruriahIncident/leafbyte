/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import androidx.compose.ui.unit.dp
import androidx.fragment.app.Fragment
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.log

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
class SettingsFragment : Fragment() {

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?,
    ): View {
        return ComposeView(requireContext()).apply {
            setContent {
                // TODO: is it bad to be recreating this on every page?
                val settings = remember { DataStoreBackedSettings(requireContext()) }

                Settings(settings)
            }
        }
    }

    @Preview(showBackground = true, device = Devices.PIXEL)
    @Composable
    fun Settings(
        @PreviewParameter(SampleSettingsProvider::class) settings: Settings,
    ) {
        log("top level settings again")

        MaterialTheme() { // TODO: where to put that
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(top = 20.dp, bottom = 20.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text("Settings", size = TextSize.SCREEN_TITLE)
                SaveLocationSetting("Data", settings.dataSaveLocation) { settings.dataSaveLocation = it }
                SaveLocationSetting("Image", settings.imageSaveLocation) { settings.imageSaveLocation = it }
                SingleSetting("Dataset Name") {
                    log("dataset name again")
                    TextField( // TODO: add ime
                        value = settings.datasetName,
                        onValueChange = { settings.datasetName = it },
                        placeholder = {
                            Text("placeholder")
                        },
                    )
                }
                ToggleableSetting("Scan Barcodes?", currentValue = settings.useBarcode) { settings.useBarcode = it }
                ToggleableSetting("Save GPS Location?", "May slow saving", settings.saveGpsData) { settings.saveGpsData = it }
                ToggleableSetting(
                    "Use Black Background?",
                    "For use with light plant tissue",
                    settings.useBlackBackground
                ) { settings.useBlackBackground = it }
            }
        }
    }

    @Composable
    fun SaveLocationSetting(locationSettingName: String, currentLocation: SaveLocation, setNewLocation: (SaveLocation) -> Unit) {
        SingleSetting("$locationSettingName Save Location") {
            SingleChoiceSegmentedButtonRow {
                val options = listOf(SaveLocation.NONE, SaveLocation.LOCAL, SaveLocation.GOOGLE_DRIVE)
                options.forEachIndexed { index, option ->
                    val selected = currentLocation == option

                    SegmentedButton(
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
                        selected = selected,
                        onClick = { setNewLocation(option) },
                        icon = {},
                        modifier = Modifier.width(100.dp),
                    ) {
                        val fontWeight = if(selected) FontWeight.Bold else null
                        Text(option.userFacingName, size = TextSize.IN_BUTTON, bold = selected)
                    }
                }
            }
        }
    }

    @OptIn(ExperimentalMaterial3Api::class)
    @Composable
    fun ToggleableSetting(
        title: String,
        explanation: String? = null,
        currentValue: Boolean,
        setNewValue: (Boolean) -> Unit,
    ) {
        SingleSetting(title) {
            Switch(
                checked = currentValue,
                onCheckedChange = { setNewValue(it) },
                thumbContent = {
                    if (currentValue) {
                        Icon(
                            painter = painterResource(R.drawable.baseline_check_24),
                            tint = { Color(0xFF6750A4) },
                            contentDescription = null,
                        )
                    }
                }
            )
            explanation?.let {
                Text(it, size = TextSize.FOOTNOTE)
            }
        }
    }

    @Composable
    fun SingleSetting(
        title: String,
        content: @Composable ColumnScope.() -> Unit
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(title)
            content()
        }
    }

}
