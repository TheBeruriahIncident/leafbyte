/**
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.fragment

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.constraintlayout.compose.ConstraintLayout
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.utils.GoogleSignInFailureType
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManagerImpl
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.description
import com.thebluefolderproject.leafbyte.utils.load
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.valueForCompose
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.map
import net.openid.appauth.AuthState

private val EVERYTHING_BUT_NUMBERS_REGEX = Regex("[^0-9]")
private val EVERYTHING_BUT_NUMBERS_AND_DECIMALS_REGEX = Regex("[^0-9.]")

enum class AlertType {
    BACK_WITHOUT_DATASET_NAME,
    GOOGLE_SIGN_IN_UNCONFIGURED,
    GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE,
    GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE,
    GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE,
    GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
    GOOGLE_SIGN_IN_NEITHER_SCOPE,
    ;

    companion object {
        fun from(signInFailureType: GoogleSignInFailureType): AlertType =
            when (signInFailureType) {
                GoogleSignInFailureType.UNCONFIGURED -> GOOGLE_SIGN_IN_UNCONFIGURED
                GoogleSignInFailureType.NON_INTERACTIVE_STAGE -> GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE
                GoogleSignInFailureType.INTERACTIVE_STAGE -> GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE
                GoogleSignInFailureType.NO_GET_USER_ID_SCOPE -> GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE
                GoogleSignInFailureType.NO_WRITE_TO_GOOGLE_DRIVE_SCOPE -> GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE
                GoogleSignInFailureType.NEITHER_SCOPE -> GOOGLE_SIGN_IN_NEITHER_SCOPE
            }
    }
}

@Preview(showBackground = true, widthDp = 400, heightDp = 1500) // to show the entire screen without cutoff
@Composable
private fun SettingsScreenPreview() {
    val settings = SampleSettings()
    val googleSignInManager = SampleGoogleSignInManager()
    SettingsScreen(settings, googleSignInManager)
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun SettingsScreenWithAlertPreview() {
    val settings = SampleSettings()
    val googleSignInManager = SampleGoogleSignInManager()
    SettingsScreen(settings, googleSignInManager, AlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE)
}

@Composable
fun SettingsScreen2(
    injectedSettings: Settings?,
    injectedGoogleSignInManager: GoogleSignInManager?,
) {
    val context = LocalContext.current
    val settings = remember { injectedSettings ?: DataStoreBackedSettings(context) }
    val coroutineScope = rememberCoroutineScope()
    val googleSignInManager = remember { injectedGoogleSignInManager ?: GoogleSignInManagerImpl(coroutineScope, context, settings) }

    SettingsScreen(settings, googleSignInManager)
}

@Suppress("detekt:complexity:LongMethod")
@Composable
fun SettingsScreen(
    settings: Settings,
    googleSignInManager: GoogleSignInManager,
    // exposed for @Previews
    initialAlert: AlertType? = null,
) {
    // don't use a MutableStateFlow here! using MutableStateFlow is a "best practice" but it breaks TextFields
    val datasetNameDisplayValue = remember { mutableStateOf(settings.getDatasetName().load()) }
    val scaleMarkLengthDisplayValue = remember { mutableStateOf(settings.getScaleMarkLength().map(Float::toString).load()) }
    val nextSampleNumberDisplayValue = remember { mutableStateOf(settings.getNextSampleNumber().map(Int::toString).load()) }

    val currentAlert: MutableState<AlertType?> = remember { mutableStateOf(initialAlert) }

    val dataSaveLocationDisplayValue = remember { mutableStateOf(settings.getDataSaveLocation().load()) }
    val imageSaveLocationDisplayValue = remember { mutableStateOf(settings.getImageSaveLocation().load()) }
    fun fullySetDataSaveLocation(newSaveLocation: SaveLocation) {
        dataSaveLocationDisplayValue.value = newSaveLocation
        settings.setDataSaveLocation(newSaveLocation)
    }
    fun fullySetImageSaveLocation(newSaveLocation: SaveLocation) {
        imageSaveLocationDisplayValue.value = newSaveLocation
        settings.setImageSaveLocation(newSaveLocation)
    }

    val dataSaveToGoogleSuccess = {
        fullySetDataSaveLocation(SaveLocation.GOOGLE_DRIVE)
    }
    val dataSaveToGoogleFailure = { failure: GoogleSignInFailureType ->
        // fallback to local so that someone who intended to save doesn't accidentally not save at all
        fullySetDataSaveLocation(SaveLocation.LOCAL)
        // and if Google isn't usable for data, it's not usable for images either
        if (imageSaveLocationDisplayValue.value == SaveLocation.GOOGLE_DRIVE) {
            fullySetImageSaveLocation(SaveLocation.LOCAL)
        }

        currentAlert.value = AlertType.from(failure)
    }
    val imageSaveToGoogleSuccess = {
        fullySetImageSaveLocation(SaveLocation.GOOGLE_DRIVE)
    }
    val imageSaveToGoogleFailure = { failure: GoogleSignInFailureType ->
        // fallback to local so that someone who intended to save doesn't accidentally not save at all
        fullySetImageSaveLocation(SaveLocation.LOCAL)
        // and if Google isn't usable for images, it's not usable for data either
        if (dataSaveLocationDisplayValue.value == SaveLocation.GOOGLE_DRIVE) {
            fullySetDataSaveLocation(SaveLocation.LOCAL)
        }

        currentAlert.value = AlertType.from(failure)
    }

    val dataSaveToGoogleLauncher = googleSignInManager.getLauncher(dataSaveToGoogleSuccess, dataSaveToGoogleFailure)
    val imageSaveToGoogleLauncher = googleSignInManager.getLauncher(imageSaveToGoogleSuccess, imageSaveToGoogleFailure)

    // Scale length, scale unit, and next sample number are scoped to the particular dataset
    // Unit will automatically update from the flow from the settings, but scale length and next sample number have a display value in order
    //   to make the editing experience usable and not have the default pop in as soon as you cleared the field
    val onDatasetChange = {
        scaleMarkLengthDisplayValue.value = settings.getScaleMarkLength().load().toString()
        nextSampleNumberDisplayValue.value = settings.getNextSampleNumber().load().toString()
    }

    val isGoogleSignedIn = remember { settings.getAuthState().map(AuthState::isAuthorized) }

    MaterialTheme {
        // need to figure where to put theming
        BackHandler(enabled = datasetNameDisplayValue.value.isBlank()) {
            currentAlert.value = AlertType.BACK_WITHOUT_DATASET_NAME
        }
        Alert(currentAlert)

        Column(
            modifier =
                Modifier
                    .fillMaxSize()
                    .padding(horizontal = 60.dp)
                    .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(5.dp),
        ) {
            Spacer(Modifier.height(20.dp))
            Text("Settings", size = TextSize.SCREEN_TITLE)
            SaveLocationSetting(
                "Data",
                dataSaveLocationDisplayValue,
                setNonGoogleLocation = {
                    fullySetDataSaveLocation(it)
                },
                setLocationToGoogle = {
                    dataSaveLocationDisplayValue.value = SaveLocation.GOOGLE_DRIVE
                    googleSignInManager.signIn(dataSaveToGoogleLauncher, dataSaveToGoogleSuccess, dataSaveToGoogleFailure)
                },
            )
            SaveLocationSetting(
                "Image",
                imageSaveLocationDisplayValue,
                setNonGoogleLocation = {
                    fullySetImageSaveLocation(it)
                },
                setLocationToGoogle = {
                    imageSaveLocationDisplayValue.value = SaveLocation.GOOGLE_DRIVE
                    googleSignInManager.signIn(imageSaveToGoogleLauncher, imageSaveToGoogleSuccess, imageSaveToGoogleFailure)
                },
            )
            DatasetNameSetting(settings, datasetNameDisplayValue, onDatasetChange)
            ScaleLengthSetting(settings, scaleMarkLengthDisplayValue)
            NextSampleNumberSetting(settings, nextSampleNumberDisplayValue)
            ToggleableSetting(
                title = "Scan Barcodes?",
                enabled = dataSaveLocationDisplayValue.value != SaveLocation.NONE,
                currentValue = settings.getUseBarcode().valueForCompose(),
            ) { settings.setUseBarcode(it) }
            ToggleableSetting(
                title = "Save GPS Location?",
                enabled = dataSaveLocationDisplayValue.value != SaveLocation.NONE,
                explanation = "May slow saving",
                currentValue = settings.getSaveGpsData().valueForCompose(),
            ) { settings.setSaveGpsData(it) }
            ToggleableSetting(
                title = "Use Black Background?",
                explanation = "For use with light plant tissue",
                currentValue = settings.getUseBlackBackground().valueForCompose(),
            ) { settings.setUseBlackBackground(it) }
            TextButton(
                enabled = isGoogleSignedIn.valueForCompose(),
                onClick = {
                    if (dataSaveLocationDisplayValue.value == SaveLocation.GOOGLE_DRIVE) {
                        fullySetDataSaveLocation(SaveLocation.LOCAL)
                    }
                    if (imageSaveLocationDisplayValue.value == SaveLocation.GOOGLE_DRIVE) {
                        fullySetImageSaveLocation(SaveLocation.LOCAL)
                    }

                    googleSignInManager.signOut()
                },
            ) {
                Text("Sign out of Google")
            }
            Text("LeafByte was made by Abigail & Zoe Getman-Pickering.")
            Text(
                "Nick Aflitto, Ari Grele, George Stack, Todd Ugine, Jules Davis, Heather Grab, Jose Rangel, Sheyla Finkner, Sheyla " +
                    "Lugay, Fiona MacNeil, and Abby Dittmar all worked on testing the app and contributed ideas for features and " +
                    "improvements. Eric Raboin helped with the projective geometry equations. Nick Aflitto and Julia Miller took " +
                    "photos for the website and tutorial respectively.",
            )
            Text("version .1")
            Spacer(Modifier.height(20.dp))
        }
    }
}

@Composable
@OptIn(ExperimentalMaterial3Api::class)
private fun Alert(currentAlert: MutableState<AlertType?>) {
    if (currentAlert.value == null) {
        return
    }
    log("Displaying settings screen alert for ${currentAlert.value}")

    BasicAlertDialog(
        onDismissRequest = { currentAlert.value = null },
    ) {
        Surface(
            modifier =
                Modifier
                    .wrapContentWidth()
                    .wrapContentHeight(),
            shape = MaterialTheme.shapes.large,
            tonalElevation = AlertDialogDefaults.TonalElevation,
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text(
                    text = getAlertTitle(currentAlert.value),
                    size = TextSize.SCREEN_TITLE,
                    bold = true,
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = getAlertMessage(currentAlert.value),
                )
                Spacer(modifier = Modifier.height(10.dp))
                TextButton(
                    onClick = { currentAlert.value = null },
                    modifier = Modifier.align(Alignment.End),
                ) {
                    Text("OK")
                }
            }
        }
    }
}

fun getAlertTitle(alertType: AlertType?): String =
    when (alertType) {
        AlertType.BACK_WITHOUT_DATASET_NAME ->
            "Dataset name missing"
        AlertType.GOOGLE_SIGN_IN_UNCONFIGURED,
        AlertType.GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE,
        AlertType.GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE,
        ->
            "Google sign-in unsuccessful"
        AlertType.GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE,
        AlertType.GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
        AlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE,
        ->
            "LeafByte not granted access"
        // This handles a (perhaps theoretical) case where the alert is closing but in the middle of one last recompose
        null -> ""
    }

fun getAlertMessage(alertType: AlertType?): String =
    when (alertType) {
        AlertType.BACK_WITHOUT_DATASET_NAME -> "A dataset name is required. Please enter a dataset name."
        AlertType.GOOGLE_SIGN_IN_UNCONFIGURED ->
            "Google sign-in is not configured. Please reach out to leafbyte@zoegp.science so we can fix this."
        AlertType.GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE ->
            "Failed to communicate with Google. Please confirm that you are online and LeafByte has access to the internet."
        AlertType.GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE ->
            "Sign-in to Google was not successful. LeafByte cannot save to Google Drive without a successful sign-in."
        AlertType.GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE ->
            "We must be authorized to identify you if you want to save to Google Drive. We specifically need the ability to identify you " +
                "so that you can edit the same datasheets over the course of multiple LeafByte sessions or to use LeafByte with " +
                "multiple Google accounts. To save to Google Drive, sign in again and grant access."
        AlertType.GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE ->
            "We must be authorized to write to Google Drive in order to save to Google Drive. To save to Google Drive, sign in again and " +
                "grant access."
        AlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE ->
            "We must be authorized to identify you and write to Google Drive if you want to save to Google Drive. We specifically need " +
                "the ability to identify you so that you can edit the same datasheets over the course of multiple LeafByte sessions " +
                "or to use LeafByte with multiple Google accounts. To save to Google Drive, sign in again and grant access."
        // This handles a (perhaps theoretical) case where the alert is closing but in the middle of one last recompose
        null -> ""
    }

@Composable
private fun DatasetNameSetting(
    settings: Settings,
    displayValue: MutableState<String>,
    onDatasetChange: () -> Unit,
) {
    val isInvalid = displayValue.value.isBlank()
    var dropdownIsExpanded by remember { mutableStateOf(false) }
    val previousDatasetNames = settings.getPreviousDatasetNames().valueForCompose()

    SingleSetting("Dataset Name") {
        TextField(
            value = displayValue.value,
            singleLine = true,
            modifier = Modifier.description("Dataset name entry"),
            keyboardOptions =
                KeyboardOptions(
                    keyboardType = KeyboardType.Text,
                    imeAction = ImeAction.Done,
                ),
            onValueChange = {
                // This looks straightforward, but there's something subtle:
                //   if the value is blank, the persistence layer will instead store the default value.
                //   thus, the persisted will diverge from the display value until the user types something.
                //   the user should be blocked from leaving the settings screen until they fill this in, but in case the app is killed
                //     or the user manages to leave the screen, this divergence ensures that they'll still have a valid dataset name.
                displayValue.value = it
                settings.setDatasetName(it)
                onDatasetChange()
            },
            placeholder = {
                Text("Your dataset name")
            },
            supportingText = {
                // Even if valid, there's a space here so that the height doesn't change
                Text(if (isInvalid) "Dataset name is required" else " ")
            },
            isError = isInvalid,
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
                            onDatasetChange()
                        },
                    )
                }
            }
        }
    }
}

@Suppress("detekt:complexity:LongMethod")
@Composable
private fun ScaleLengthSetting(
    settings: Settings,
    displayValue: MutableState<String>,
) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toFloatOrNull() == null
    var dropdownIsExpanded by remember { mutableStateOf(false) }
    val scaleLengthUnit = settings.getScaleLengthUnit().valueForCompose()

    SingleSetting("Scale Length") {
        ConstraintLayout(
            modifier = Modifier.fillMaxWidth(),
        ) {
            val (lengthTextField, unitButton) = createRefs()

            TextField(
                value = displayValue.value,
                singleLine = true,
                keyboardOptions =
                    KeyboardOptions(
                        keyboardType = KeyboardType.Decimal,
                        imeAction = ImeAction.Done,
                    ),
                modifier =
                    Modifier
                        .constrainAs(lengthTextField) { centerTo(parent) }
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
                isError = isInvalid,
            )
            TextButton(
                modifier =
                    Modifier
                        .constrainAs(unitButton) {
                            start.linkTo(lengthTextField.end)
                            baseline.linkTo(lengthTextField.baseline)
                        }.width(IntrinsicSize.Min)
                        .height(IntrinsicSize.Max)
                        .description("Scale length unit selector"),
                onClick = { dropdownIsExpanded = !dropdownIsExpanded },
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
                        },
                    )
                }
            }
        }
        Text("Length of one side of the scale square from dot center to dot center", size = TextSize.FOOTNOTE)
    }
}

@Composable
private fun NextSampleNumberSetting(
    settings: Settings,
    displayValue: MutableState<String>,
) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toIntOrNull() == null

    SingleSetting("Next Sample Number") {
        TextField(
            value = displayValue.value,
            singleLine = true,
            keyboardOptions =
                KeyboardOptions(
                    keyboardType = KeyboardType.Number,
                    imeAction = ImeAction.Done,
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
            isError = isInvalid,
        )
    }
}

@Composable
fun SaveLocationSetting(
    locationSettingName: String,
    currentLocation: MutableState<SaveLocation>,
    setNonGoogleLocation: (SaveLocation) -> Unit,
    setLocationToGoogle: () -> Unit,
) {
    val fullSettingName = remember { "$locationSettingName Save Location" }

    SingleSetting(fullSettingName) {
        SingleChoiceSegmentedButtonRow(
            modifier = Modifier.height(IntrinsicSize.Min),
        ) {
            val options = listOf(SaveLocation.NONE, SaveLocation.LOCAL, SaveLocation.GOOGLE_DRIVE)
            options.forEachIndexed { index, option ->
                val selected = currentLocation.value == option

                SegmentedButton(
                    shape =
                        SegmentedButtonDefaults.itemShape(
                            index = index,
                            count = options.size,
                        ),
                    selected = selected,
                    onClick = {
                        if (option == SaveLocation.GOOGLE_DRIVE) {
                            setLocationToGoogle()
                        } else {
                            setNonGoogleLocation(option)
                        }
                    },
                    icon = {},
                    modifier =
                        Modifier
                            .fillMaxHeight()
                            .description("Set $fullSettingName to ${option.userFacingName}"),
                ) {
                    Text(
                        text = option.userFacingName,
                        size = TextSize.IN_BUTTON,
                        bold = selected,
                    )
                }
            }
        }
    }
}

@Suppress("detekt:style:MagicNumber") // once we fiddle with theme colors, the colors should come from a theme constant
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToggleableSetting(
    title: String,
    enabled: Boolean = true,
    // default is non-empty to ensure size doesn't change when a warning is swapped in
    explanation: String = " ",
    currentValue: Boolean,
    setNewValue: (Boolean) -> Unit,
) {
    SingleSetting(title) {
        Switch(
            modifier = Modifier.description("$title toggle"),
            enabled = enabled,
            checked = currentValue,
            onCheckedChange = { setNewValue(it) },
            thumbContent = {
                if (currentValue) {
                    Icon(
                        painter = painterResource(R.drawable.baseline_check_24),
                        tint = { Color(0xFF6750A4) },
                        contentDescription = "Check mark",
                    )
                }
            },
        )
        Text(
            text = if (enabled) explanation else "Data is not currently being saved",
            color = if (enabled) Color.Unspecified else Color(0xFFB3261E),
            size = TextSize.FOOTNOTE,
        )
    }
}

@Composable
fun SingleSetting(
    title: String,
    content: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier =
            Modifier
                .fillMaxWidth()
                .padding(10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(title)
        content()
    }
}
