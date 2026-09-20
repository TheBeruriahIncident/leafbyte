/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.compose

import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.annotation.VisibleForTesting
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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.constraintlayout.compose.ConstraintLayout
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.compose.theme.LeafByteTheme
import com.thebluefolderproject.leafbyte.compose.theme.errorLight
import com.thebluefolderproject.leafbyte.google.signin.GoogleSignInFailureType
import com.thebluefolderproject.leafbyte.google.signin.GoogleSignInManager
import com.thebluefolderproject.leafbyte.google.signin.MockGoogleSignInManager
import com.thebluefolderproject.leafbyte.settings.MockSettings
import com.thebluefolderproject.leafbyte.settings.SaveLocation
import com.thebluefolderproject.leafbyte.settings.Settings
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.TopAppBar
import com.thebluefolderproject.leafbyte.utils.description
import com.thebluefolderproject.leafbyte.utils.load
import com.thebluefolderproject.leafbyte.utils.valueForCompose
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.map
import net.openid.appauth.AuthState

private val EVERYTHING_BUT_NUMBERS_REGEX = Regex("[^0-9]")
private val EVERYTHING_BUT_NUMBERS_AND_DECIMALS_REGEX = Regex("[^0-9.]")

@Composable
fun AppAwareSettingsScreen(
    backStack: SnapshotStateList<Any>,
    settings: Settings,
    googleSignInManager: GoogleSignInManager,
) {
    val focusManager = LocalFocusManager.current

    LeafByteTheme {
        SettingsScreen(
            settings = settings,
            googleSignInManager = googleSignInManager,
            goBack = {
                // TODO pull out the common logic
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
                    // Javadoc doesn't say this is only from API 35, but the linter does, and CI fails otherwise
                    backStack.removeLast()
                } else {
                    backStack.removeAt(backStack.lastIndex)
                }
            },
            closeKeyboard = {
                focusManager.clearFocus()
            },
        )
    }
}

@Suppress("detekt:complexity:LongMethod")
@Composable
fun SettingsScreen(
    settings: Settings,
    googleSignInManager: GoogleSignInManager,
    goBack: () -> Unit,
    closeKeyboard: () -> Unit,
    // exposed for @Previews
    initialAlert: SettingsAlertType? = null,
) {
    // don't use a MutableStateFlow here! using MutableStateFlow is a "best practice" but it breaks TextFields.
    // see https://medium.com/androiddevelopers/effective-state-management-for-textfield-in-compose-d6e5b070fbe5
    val datasetNameDisplayValue = remember { mutableStateOf(settings.getDatasetName().load()) }
    val scaleLengthDisplayValue = remember { mutableStateOf(settings.getScaleLength().map(Float::toString).load()) }
    val nextSampleNumberDisplayValue = remember { mutableStateOf(settings.getNextSampleNumber().map(Int::toString).load()) }

    val currentAlert: MutableState<SettingsAlertType?> = remember { mutableStateOf(initialAlert) }

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

        currentAlert.value = SettingsAlertType.from(failure)
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

        currentAlert.value = SettingsAlertType.from(failure)
    }

    val dataSaveToGoogleLauncher = googleSignInManager.getLauncher(dataSaveToGoogleSuccess, dataSaveToGoogleFailure)
    val imageSaveToGoogleLauncher = googleSignInManager.getLauncher(imageSaveToGoogleSuccess, imageSaveToGoogleFailure)

    val onDatasetChange = {
        // Settings are scoped to the particular dataset. Everything that doesn't have a separate display value will automatically update
        //   from the flow from the settings, but the display values that exist in order to make the editing experience better must be
        //   manually updated
        scaleLengthDisplayValue.value = settings.getScaleLength().load().toString()
        nextSampleNumberDisplayValue.value = settings.getNextSampleNumber().load().toString()
        dataSaveLocationDisplayValue.value = settings.getDataSaveLocation().load()
        imageSaveLocationDisplayValue.value = settings.getImageSaveLocation().load()
    }

    val isGoogleSignedIn = remember { settings.getAuthState().map(AuthState::isAuthorized) }

    val onPressingBack = {
        closeKeyboard()

        if (datasetNameDisplayValue.value.isBlank()) {
            currentAlert.value = SettingsAlertType.BACK_WITHOUT_DATASET_NAME
        } else {
            goBack()
        }
    }

    BackHandler {
        onPressingBack()
    }
    MaterialTheme {
        Scaffold(
            modifier = Modifier.fillMaxSize(),
            topBar = {
                TopAppBar(title = "Settings", onPressingBack = onPressingBack)
            },
        ) { scaffoldPaddingValues ->
            // TODO need to figure where to put theming

            Alert(
                currentAlert = currentAlert,
                getAlertTitle = { getAlertTitle(it) },
                getAlertMessage = { getAlertMessage(it) },
                scaffoldPaddingValues = scaffoldPaddingValues,
            )

            Column(
                modifier =
                    Modifier
                        .fillMaxSize()
                        .padding(scaffoldPaddingValues)
                        .padding(horizontal = 60.dp)
                        .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(5.dp),
            ) {
                val datasetNameIsBlank = datasetNameDisplayValue.value.isBlank()
                val datasetNameIsNotBlank = !datasetNameIsBlank

                DatasetNameSetting(
                    settings = settings,
                    displayValue = datasetNameDisplayValue,
                    isBlank = datasetNameIsBlank,
                    onDatasetChange = onDatasetChange,
                )
                HorizontalDivider(thickness = 2.dp)

                SaveLocationSetting(
                    locationSettingName = "Data",
                    enabled = datasetNameIsNotBlank,
                    currentLocation = dataSaveLocationDisplayValue,
                    setNonGoogleLocation = {
                        fullySetDataSaveLocation(it)
                    },
                    setLocationToGoogle = {
                        dataSaveLocationDisplayValue.value = SaveLocation.GOOGLE_DRIVE
                        googleSignInManager.signIn(dataSaveToGoogleLauncher, dataSaveToGoogleSuccess, dataSaveToGoogleFailure)
                    },
                )
                SaveLocationSetting(
                    locationSettingName = "Image",
                    enabled = datasetNameIsNotBlank,
                    currentLocation = imageSaveLocationDisplayValue,
                    setNonGoogleLocation = {
                        fullySetImageSaveLocation(it)
                    },
                    setLocationToGoogle = {
                        imageSaveLocationDisplayValue.value = SaveLocation.GOOGLE_DRIVE
                        googleSignInManager.signIn(imageSaveToGoogleLauncher, imageSaveToGoogleSuccess, imageSaveToGoogleFailure)
                    },
                )
                ScaleLengthSetting(
                    settings = settings,
                    enabled = datasetNameIsNotBlank,
                    displayValue = scaleLengthDisplayValue,
                )
                NextSampleNumberSetting(
                    settings = settings,
                    enabled = datasetNameIsNotBlank,
                    displayValue = nextSampleNumberDisplayValue,
                )
                ToggleableSetting(
                    title = "Scan Barcodes?",
                    disabledBecauseEmptyDatasetName = datasetNameIsBlank,
                    disabledBecauseNotSavingData = dataSaveLocationDisplayValue.value == SaveLocation.NONE,
                    currentValue = settings.getUseBarcode().valueForCompose(),
                ) { settings.setUseBarcode(it) }
                ToggleableSetting(
                    title = "Save GPS Location?",
                    disabledBecauseEmptyDatasetName = datasetNameIsBlank,
                    disabledBecauseNotSavingData = dataSaveLocationDisplayValue.value == SaveLocation.NONE,
                    explanation = "May slow saving",
                    currentValue = settings.getSaveGpsData().valueForCompose(),
                ) { settings.setSaveGpsData(it) }
                ToggleableSetting(
                    title = "Use Black Background?",
                    disabledBecauseEmptyDatasetName = datasetNameIsBlank,
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
}

enum class SettingsAlertType {
    BACK_WITHOUT_DATASET_NAME,
    GOOGLE_SIGN_IN_UNCONFIGURED,
    GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE,
    GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE,
    GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE,
    GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
    GOOGLE_SIGN_IN_NEITHER_SCOPE,
    ;

    companion object {
        fun from(signInFailureType: GoogleSignInFailureType): SettingsAlertType =
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

private fun getAlertTitle(alertType: SettingsAlertType): String =
    when (alertType) {
        SettingsAlertType.BACK_WITHOUT_DATASET_NAME ->
            "Dataset name missing"
        SettingsAlertType.GOOGLE_SIGN_IN_UNCONFIGURED,
        SettingsAlertType.GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE,
        SettingsAlertType.GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE,
        ->
            "Google sign-in unsuccessful"
        SettingsAlertType.GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE,
        SettingsAlertType.GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
        SettingsAlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE,
        ->
            "LeafByte not granted access"
    }

@VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)
fun getAlertMessage(alertType: SettingsAlertType): String =
    when (alertType) {
        SettingsAlertType.BACK_WITHOUT_DATASET_NAME -> "A dataset name is required. Please enter a dataset name."
        SettingsAlertType.GOOGLE_SIGN_IN_UNCONFIGURED ->
            "Google sign-in is not configured. Please reach out to leafbyte@zoegp.science so we can fix this."
        SettingsAlertType.GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE ->
            "Failed to communicate with Google. Please confirm that you are online and LeafByte has access to the internet."
        SettingsAlertType.GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE ->
            "Sign-in to Google was not successful. LeafByte cannot save to Google Drive without a successful sign-in."
        SettingsAlertType.GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE ->
            "We must be authorized to identify you if you want to save to Google Drive. We specifically need the ability to identify you " +
                "so that you can edit the same datasheets over the course of multiple LeafByte sessions or to use LeafByte with " +
                "multiple Google accounts. To save to Google Drive, sign in again and grant access."
        SettingsAlertType.GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE ->
            "We must be authorized to write to Google Drive in order to save to Google Drive. To save to Google Drive, sign in again and " +
                "grant access."
        SettingsAlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE ->
            "We must be authorized to identify you and write to Google Drive if you want to save to Google Drive. We specifically need " +
                "the ability to identify you so that you can edit the same datasheets over the course of multiple LeafByte sessions " +
                "or to use LeafByte with multiple Google accounts. To save to Google Drive, sign in again and grant access."
    }

@Composable
private fun DatasetNameSetting(
    settings: Settings,
    displayValue: MutableState<String>,
    isBlank: Boolean,
    onDatasetChange: () -> Unit,
) {
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
                Text(if (isBlank) "Dataset name is required" else " ")
            },
            isError = isBlank,
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
        Text(
            "When switching to a previous dataset, LeafByte will restore the settings used for that dataset.",
            textAlign = TextAlign.Center,
        )
    }
}

@Suppress("detekt:complexity:LongMethod")
@Composable
private fun ScaleLengthSetting(
    enabled: Boolean,
    settings: Settings,
    displayValue: MutableState<String>,
) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toFloatOrNull() == null
    var dropdownIsExpanded by remember { mutableStateOf(false) }
    val scaleUnit = settings.getScaleUnit().valueForCompose()

    SingleSetting("Scale Length") {
        ConstraintLayout(
            modifier = Modifier.fillMaxWidth(),
        ) {
            val (lengthTextField, unitButton) = createRefs()

            TextField(
                value = displayValue.value,
                enabled = enabled,
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
                    settings.setScaleLength(newFloatValue)
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
                    text = scaleUnit,
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
                            settings.setScaleUnit(unit)
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
    enabled: Boolean,
    settings: Settings,
    displayValue: MutableState<String>,
) {
    val isInvalid = displayValue.value.isBlank() || displayValue.value.toIntOrNull() == null

    SingleSetting("Next Sample Number") {
        TextField(
            value = displayValue.value,
            enabled = enabled,
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
    enabled: Boolean,
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
                    enabled = enabled,
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

// once we fiddle with theme colors, the colors should come from a theme constant
@Suppress("detekt:complexity:LongParameterList", "detekt:style:MagicNumber")
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ToggleableSetting(
    title: String,
    disabledBecauseEmptyDatasetName: Boolean = false,
    disabledBecauseNotSavingData: Boolean = false,
    // default is non-empty to ensure size doesn't change when a warning is swapped in
    explanation: String = " ",
    currentValue: Boolean,
    setNewValue: (Boolean) -> Unit,
) {
    SingleSetting(title) {
        Switch(
            modifier = Modifier.description("$title toggle"),
            enabled = !disabledBecauseEmptyDatasetName && !disabledBecauseNotSavingData,
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
            text = if (disabledBecauseNotSavingData) "Data is not currently being saved" else explanation,
            color = if (disabledBecauseNotSavingData) errorLight else Color.Unspecified,
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

@Preview(showBackground = true, widthDp = 400, heightDp = 1500) // to show the entire screen without cutoff
@Composable
private fun SettingsScreenPreview() {
    val settings = MockSettings()
    val googleSignInManager = MockGoogleSignInManager()
    LeafByteTheme {
        SettingsScreen(settings, googleSignInManager, {}, {})
    }
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun SettingsScreenWithAlertPreview() {
    val settings = MockSettings()
    val googleSignInManager = MockGoogleSignInManager()
    LeafByteTheme {
        SettingsScreen(settings, googleSignInManager, {}, {}, SettingsAlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE)
    }
}
