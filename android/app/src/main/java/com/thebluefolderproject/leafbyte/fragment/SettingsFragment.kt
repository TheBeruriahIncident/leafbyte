/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialogDefaults
import androidx.compose.material3.BasicAlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.tooling.preview.PreviewParameter
import androidx.compose.ui.unit.dp
import androidx.constraintlayout.compose.ConstraintLayout
import androidx.fragment.app.Fragment
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.compose
import com.thebluefolderproject.leafbyte.utils.description
import com.thebluefolderproject.leafbyte.utils.load
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.map

private val EVERYTHING_BUT_NUMBERS_REGEX = Regex("[^0-9]")
private val EVERYTHING_BUT_NUMBERS_AND_DECIMALS_REGEX = Regex("[^0-9.]")

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
                val settings = remember { DataStoreBackedSettings(requireContext()) }

                SettingsScreen(settings)
            }
        }
    }
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
fun SettingsScreen(
    @PreviewParameter(SampleSettingsProvider::class) settings: Settings,
) {
    // don't use a MutableStateFlow here! using MutableStateFlow is a "best practice" but it breaks TextFields
    val datasetNameDisplayValue = remember { mutableStateOf(settings.getDatasetName().load()) }
    val scaleMarkLengthDisplayValue = remember { mutableStateOf(settings.getScaleMarkLength().map(Float::toString).load()) }
    val nextSampleNumberDisplayValue = remember { mutableStateOf(settings.getNextSampleNumber().map(Int::toString).load()) }
    val blankDatasetNameAlertOpen = remember { mutableStateOf(false) }

    MaterialTheme() { // TODO: where to put that
        BackHandler(enabled = datasetNameDisplayValue.value.isBlank()) {
            blankDatasetNameAlertOpen.value = true
        }
        if (blankDatasetNameAlertOpen.value) {
            BlankDatasetNameAlert(blankDatasetNameAlertOpen)
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 60.dp)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(5.dp)
        ) {
            Spacer(Modifier.height(20.dp))
            Text("Settings", size = TextSize.SCREEN_TITLE)
            SaveLocationSetting("Data", settings.getDataSaveLocation().compose()) { settings.setDataSaveLocation(it) }
            SaveLocationSetting("Image", settings.getImageSaveLocation().compose()) { settings.setImageSaveLocation(it) }
            DatasetNameSetting(settings, datasetNameDisplayValue)
            ScaleLengthSetting(settings, scaleMarkLengthDisplayValue)
            NextSampleNumberSetting(settings, nextSampleNumberDisplayValue)
            ToggleableSetting("Scan Barcodes?", currentValue = settings.getUseBarcode().compose()) { settings.setUseBarcode(it) }
            ToggleableSetting("Save GPS Location?", "May slow saving", settings.getSaveGpsData().compose()) { settings.setSaveGpsData(it) }
            ToggleableSetting(
                "Use Black Background?",
                "For use with light plant tissue",
                settings.getUseBlackBackground().compose()
            ) { settings.setUseBlackBackground(it) }
            TextButton(onClick = {}) {
                Text("Sign out of Google")
            }
            Text("LeafByte was made by Abigail & Zoe Getman-Pickering.")
            Text("Nick Aflitto, Ari Grele, George Stack, Todd Ugine, Jules Davis, Heather Grab, Jose Rangel, Sheyla Finkner, Sheyla Lugay, Fiona MacNeil, and Abby Dittmar all worked on testing the app and contributed ideas for features and improvements. Eric Raboin helped with the projective geometry equations. Nick Aflitto and Julia Miller took photos for the website and tutorial respectively.")
            Text("version .1")
            Spacer(Modifier.height(20.dp))
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun BlankDatasetNameAlert(alertOpen: MutableState<Boolean>) {
    BasicAlertDialog(
        onDismissRequest = { alertOpen.value = false }
    ) {
        Surface(
            modifier = Modifier
                .wrapContentWidth()
                .wrapContentHeight(),
            shape = MaterialTheme.shapes.large,
            tonalElevation = AlertDialogDefaults.TonalElevation
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(
                    text = "A dataset name is required. Please enter a dataset name.",
                )
                TextButton(
                    onClick = { alertOpen.value = false },
                    modifier = Modifier.align(Alignment.End)
                ) {
                    Text("OK")
                }
            }
        }
    }
}

@Composable
private fun DatasetNameSetting(settings: Settings, displayValue: MutableState<String>) {
    val isInvalid = displayValue.value.isBlank()
    var dropdownIsExpanded by remember { mutableStateOf(false) }
    val previousDatasetNames = settings.getPreviousDatasetNames().compose()

    SingleSetting("Dataset Name") {
        TextField(
            value = displayValue.value,
            singleLine = true,
            modifier = Modifier.description("Dataset name entry"),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Text,
                imeAction = ImeAction.Done
            ),
            onValueChange = {
                // This looks straightforward, but there's something subtle:
                //   if the value is blank, the persistence layer will instead store the default value.
                //   thus, the persisted will diverge from the display value until the user types something.
                //   the user should be blocked from leaving the settings screen until they fill this in, but in case the app is killed
                //     or the user manages to leave the screen, this divergence ensures that they'll still have a valid dataset name.
                displayValue.value = it
                settings.setDatasetName(it)
            },
            placeholder = {
                Text("Your dataset name")
            },
            supportingText = {
                // Even if valid, there's a space here so that the height doesn't change
                Text(if (isInvalid) "Dataset name is required" else " ")
            },
            isError = isInvalid
        )
        Box(contentAlignment = Alignment.Center) {
            TextButton(
                onClick = { dropdownIsExpanded = !dropdownIsExpanded },
            ) {
                Text("Use previous dataset")
            }
            DropdownMenu(
                expanded = dropdownIsExpanded,
                onDismissRequest = { dropdownIsExpanded = false },
            ) {
                previousDatasetNames.forEach { previousDatasetName ->
                    DropdownMenuItem(
                        text = { Text(previousDatasetName) },
                        onClick = {
                            settings.setDatasetName(previousDatasetName)
                            displayValue.value = previousDatasetName
                            dropdownIsExpanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
private fun ScaleLengthSetting(settings: Settings, displayValue: MutableState<String>) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toFloatOrNull() == null
    var dropdownIsExpanded by remember { mutableStateOf(false) }
    val scaleLengthUnit = settings.getScaleLengthUnit().compose()

    SingleSetting("Scale Length") {
        ConstraintLayout(
            modifier = Modifier.fillMaxWidth()
        ) {
            val (lengthTextField, unitButton) = createRefs()

            TextField(
                value = displayValue.value,
                singleLine = true,
                keyboardOptions = KeyboardOptions(
                    keyboardType = KeyboardType.Decimal,
                    imeAction = ImeAction.Done
                ),
                modifier = Modifier.constrainAs(lengthTextField) { centerTo(parent) }
                    .description("Scale length entry"),
                onValueChange = {
                    // We strip out everything but numbers and decimals, so it's as if typing other characters doesn't do anything
                    val strippedNewStringValue = EVERYTHING_BUT_NUMBERS_AND_DECIMALS_REGEX.replace(it, "")
                    // fallback to an invalid value that the persistence will replace
                    val newFloatValue = strippedNewStringValue.toFloatOrNull() ?: -1f

                    displayValue.value = strippedNewStringValue
                    settings.setScaleMarkLength(newFloatValue)
                },
                placeholder = {
                    Text("Your scale length")
                },
                isError = isInvalid
            )
            TextButton(
                modifier = Modifier
                    .constrainAs(unitButton) { start.linkTo(lengthTextField.end) }
                    .width(IntrinsicSize.Min)
                    .height(IntrinsicSize.Max)
                    .description("Scale length unit selector"),
                onClick = { dropdownIsExpanded = !dropdownIsExpanded }
            ) {
                Text(
                    text = scaleLengthUnit,
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Left,
                )
            }
        }
        Box(contentAlignment = Alignment.Center) {
            DropdownMenu(
                expanded = dropdownIsExpanded,
                onDismissRequest = { dropdownIsExpanded = false },
            ) {
                remember { persistentListOf("mm", "cm", "m", "in", "ft") }.forEach { unit ->
                    DropdownMenuItem(
                        text = { Text(unit) },
                        onClick = {
                            settings.setScaleLengthUnit(unit)
                            dropdownIsExpanded = false
                        }
                    )
                }
            }
        }
        Text("Length of one side of the scale square from dot center to dot center", size = TextSize.FOOTNOTE)
    }
}

@Composable
private fun NextSampleNumberSetting(settings: Settings, displayValue: MutableState<String>) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toIntOrNull() == null

    SingleSetting("Next Sample Number") {
        TextField(
            value = displayValue.value,
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Number,
                imeAction = ImeAction.Done
            ),
            modifier = Modifier.description("Next sample number entry"),
            onValueChange = {
                // We strip out everything but numbers, so it's as if typing other characters doesn't do anything
                val strippedNewStringValue = EVERYTHING_BUT_NUMBERS_REGEX.replace(it, "")
                // fallback to an invalid value that the persistence will replace
                val newIntValue = strippedNewStringValue.toIntOrNull() ?: -1

                displayValue.value = strippedNewStringValue
                settings.setNextSampleNumber(newIntValue)
            },
            isError = isInvalid
        )
    }
}

@Composable
fun SaveLocationSetting(locationSettingName: String, currentLocation: SaveLocation, setNewLocation: (SaveLocation) -> Unit) {
    val fullSettingName = remember { "$locationSettingName Save Location" }

    SingleSetting(fullSettingName) {
        SingleChoiceSegmentedButtonRow {
            val options = listOf(SaveLocation.NONE, SaveLocation.LOCAL, SaveLocation.GOOGLE_DRIVE)
            options.forEachIndexed { index, option ->
                val selected = currentLocation == option

                SegmentedButton(
                    shape = SegmentedButtonDefaults.itemShape(index = index, count = options.size),
                    selected = selected,
                    onClick = { setNewLocation(option) },
                    icon = {},
                    modifier = Modifier.width(100.dp)
                        .description("Set $fullSettingName to ${option.userFacingName}"),
                ) {
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
            modifier = Modifier.description("$title toggle"),
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
