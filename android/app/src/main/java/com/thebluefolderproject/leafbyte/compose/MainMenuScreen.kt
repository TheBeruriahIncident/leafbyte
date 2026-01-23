/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

@file:Suppress("detekt:naming:MatchingDeclarationName")

package com.thebluefolderproject.leafbyte.compose

import androidx.annotation.VisibleForTesting
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Scaffold
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.MutableState
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshots.SnapshotStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.tooling.preview.Devices
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.thebluefolderproject.leafbyte.R
import com.thebluefolderproject.leafbyte.LeafByteNavKey
import com.thebluefolderproject.leafbyte.settings.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.settings.MockSettings
import com.thebluefolderproject.leafbyte.settings.SaveLocation
import com.thebluefolderproject.leafbyte.settings.Settings
import com.thebluefolderproject.leafbyte.utils.BUTTON_COLOR
import com.thebluefolderproject.leafbyte.utils.Text
import com.thebluefolderproject.leafbyte.utils.TextSize
import com.thebluefolderproject.leafbyte.utils.appendLink
import com.thebluefolderproject.leafbyte.utils.getCameraLauncher
import com.thebluefolderproject.leafbyte.utils.getCameraPhotoUri
import com.thebluefolderproject.leafbyte.utils.getGalleryLauncher
import com.thebluefolderproject.leafbyte.utils.hasCamera
import com.thebluefolderproject.leafbyte.utils.log
import com.thebluefolderproject.leafbyte.utils.valueForCompose
import kotlin.concurrent.atomics.AtomicBoolean
import kotlin.concurrent.atomics.ExperimentalAtomicApi

@OptIn(ExperimentalAtomicApi::class)
@Composable
fun AppAwareMainMenuScreen(backStack: SnapshotStateList<Any>) {
    val context = LocalContext.current
    val settings = remember { DataStoreBackedSettings(context) }

    val currentAlert: MutableState<MainMenuAlertType?> = remember { mutableStateOf(null) }

    val intentInProgress = AtomicBoolean(false)
    val releaseIntentLock = { intentInProgress.store(false) }

    val galleryLauncher =
        getGalleryLauncher(
            backStack = backStack,
            setAlert = { currentAlert.value = it },
            releaseIntentLock = releaseIntentLock,
        )

    val hasCamera = hasCamera()
    val cameraPhotoUri = remember { getCameraPhotoUri(context) } // on startup, we already validated that this uri can be created
    val cameraLauncher =
        getCameraLauncher(
            cameraPhotoUri = cameraPhotoUri,
            backStack = backStack,
            setAlert = { currentAlert.value = it },
            releaseIntentLock = releaseIntentLock,
        )

    MainMenuScreen(
        currentAlert = currentAlert,
        settings = settings,
        openSettings = { backStack.add(LeafByteNavKey.SettingsScreen) },
        startTutorial = { backStack.add(LeafByteNavKey.Tutorial) },
        chooseFromGallery = {
            if (intentInProgress.compareAndSet(expectedValue = false, newValue = true)) {
                log("Launching intent to pick an image from the gallery")
                galleryLauncher.launch(Unit)
            } else {
                log("Ignoring attempt to choose a picture from the gallery after already starting a different intent")
            }
        },
        takeAPhoto = {
            if (intentInProgress.compareAndSet(expectedValue = false, newValue = true)) {
                if (hasCamera) {
                    log("Launching intent to take a photo")
                    cameraLauncher.launch(cameraPhotoUri)
                } else {
                    log("Attempting to take photo without camera")
                    currentAlert.value = MainMenuAlertType.TAKING_PHOTO_WITHOUT_CAMERA
                }
            } else {
                log("Ignoring attempt to take a photo after already starting a different intent")
            }
        },
    )
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun MainMenuPreview() {
    val settings = MockSettings(useBarcode = false)
    PreviewableMainMenuScreen(settings)
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun MainMenuWithBarcodesPreview() {
    val settings =
        MockSettings(dataSaveLocation = SaveLocation.GOOGLE_DRIVE, imageSaveLocation = SaveLocation.GOOGLE_DRIVE, useBarcode = true)
    PreviewableMainMenuScreen(settings)
}

@Preview(showBackground = true, device = Devices.PIXEL)
@Composable
private fun MainMenuWithoutSavingPreview() {
    val settings = MockSettings(dataSaveLocation = SaveLocation.NONE, imageSaveLocation = SaveLocation.NONE)
    PreviewableMainMenuScreen(settings)
}

@Composable
private fun PreviewableMainMenuScreen(settings: Settings) {
    val currentAlert: MutableState<MainMenuAlertType?> = remember { mutableStateOf(null) }

    MainMenuScreen(currentAlert = currentAlert, settings = settings, openSettings = {
    }, startTutorial = {}, chooseFromGallery = {}, takeAPhoto = {})
}

@Composable
@Suppress("detekt:complexity:LongParameterList")
private fun MainMenuScreen(
    currentAlert: MutableState<MainMenuAlertType?>,
    settings: Settings,
    openSettings: () -> Unit,
    startTutorial: () -> Unit,
    chooseFromGallery: () -> Unit,
    takeAPhoto: () -> Unit,
) {
    Scaffold(
        modifier = Modifier.fillMaxSize(),
    ) { scaffoldPaddingValues ->
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
                    .padding(paddingValues = scaffoldPaddingValues)
                    .padding(start = 10.dp, end = 10.dp, top = 10.dp, bottom = 15.dp),
            verticalArrangement = Arrangement.SpaceBetween,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                TextButton(
                    onClick = { startTutorial() },
                ) {
                    Text("Tutorial", color = BUTTON_COLOR)
                }
                TextButton(
                    onClick = { openSettings() },
                ) {
                    Text("Settings", color = BUTTON_COLOR)
                }
            }
            MainTitle()
            GetImageButtons(chooseFromGallery = chooseFromGallery, takeAPhoto = takeAPhoto)
            Text(
                text = getSaveLocationsDescription(settings),
                textAlign = TextAlign.Center,
                size = TextSize.FOOTNOTE,
            )
        }
    }
}

enum class MainMenuAlertType {
    FAILED_TO_TAKE_PHOTO,
    FAILED_TO_CHOOSE_IMAGE_FROM_GALLERY,
    TAKING_PHOTO_WITHOUT_CAMERA,
}

private fun getAlertTitle(alertType: MainMenuAlertType): String =
    when (alertType) {
        MainMenuAlertType.FAILED_TO_TAKE_PHOTO -> "Failed to take photo"
        MainMenuAlertType.FAILED_TO_CHOOSE_IMAGE_FROM_GALLERY -> "Failed to load image"
        MainMenuAlertType.TAKING_PHOTO_WITHOUT_CAMERA -> "No camera found"
    }

private fun getAlertMessage(alertType: MainMenuAlertType): String =
    when (alertType) {
        MainMenuAlertType.FAILED_TO_TAKE_PHOTO ->
            "Failed to take a photo with the camera. Please report this to leafbyte@zoegp.science so we can fix this."
        MainMenuAlertType.FAILED_TO_CHOOSE_IMAGE_FROM_GALLERY ->
            "Failed to load an image from the gallery. Please report this to leafbyte@zoegp.science so we can fix this."
        MainMenuAlertType.TAKING_PHOTO_WITHOUT_CAMERA ->
            "Could not take a photo: no camera was found. Try selecting an existing image instead."
    }

@Composable
private fun MainTitle() {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(id = R.drawable.leafimage),
            contentDescription = "LeafByte's logo, a hand-drawn leaf with a bite taken out",
            Modifier.fillMaxWidth(fraction = .36f),
        )
        Text(text = "LeafByte", size = TextSize.MAIN_TITLE)
        Text(text = "Abigail & Zoe")
        Text(text = "Getman-Pickering")
        Text(
            text =
                buildAnnotatedString {
                    appendLink(anchorText = "FAQs, Help, and Bug Reporting", url = "https://zoegp.science/leafbyte-faqs")
                },
        )
    }
}

@Composable
private fun GetImageButtons(
    chooseFromGallery: () -> Unit,
    takeAPhoto: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
        horizontalArrangement = Arrangement.SpaceAround,
    ) {
        GetImageButton(
            imageResourceId = R.drawable.galleryicon,
            contentDescription = "Image gallery icon",
            onClick = chooseFromGallery,
            displayedDescription = "Choose from Gallery",
        )
        GetImageButton(
            imageResourceId = R.drawable.camera,
            contentDescription = "Camera icon",
            onClick = takeAPhoto,
            displayedDescription = "Take a Photo",
        )
    }
}

@Composable
private fun GetImageButton(
    imageResourceId: Int,
    contentDescription: String,
    onClick: () -> Unit,
    displayedDescription: String,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Image(
            painter = painterResource(id = imageResourceId),
            contentDescription = contentDescription,
            Modifier
                .fillMaxWidth(fraction = .3f)
                .clip(CircleShape)
                .clickable(onClick = onClick),
        )
        Text(displayedDescription)
    }
}

@Composable
private fun getSaveLocationsDescription(settings: Settings): AnnotatedString =
    getSaveLocationsDescription(
        dataSaveLocation = settings.getDataSaveLocation().valueForCompose(),
        imageSaveLocation = settings.getImageSaveLocation().valueForCompose(),
        datasetName = settings.getDatasetName().valueForCompose(),
    )

@VisibleForTesting(otherwise = VisibleForTesting.PRIVATE)
@Suppress("detekt:style:ReturnCount")
fun getSaveLocationsDescription(
    dataSaveLocation: SaveLocation,
    imageSaveLocation: SaveLocation,
    datasetName: String,
): AnnotatedString {
    if (dataSaveLocation == imageSaveLocation) {
        if (dataSaveLocation == SaveLocation.NONE) {
            return buildAnnotatedString {
                append("Data and images are ")
                withStyle(style = SpanStyle(color = Color.Red)) {
                    append("not being saved")
                }
                append(". Go to Settings to change.")
            }
        } else {
            return AnnotatedString(
                "Saving data and images to ${saveLocationToDescription(dataSaveLocation)} under the name $datasetName.",
            )
        }
    } else {
        if (dataSaveLocation == SaveLocation.NONE) {
            return buildAnnotatedString {
                append("Data is ")
                appendNotBeingSaved()
                append('\n')
                append("Saving images to ${saveLocationToDescription(imageSaveLocation)} under the name $datasetName.")
            }
        } else if (imageSaveLocation == SaveLocation.NONE) {
            return buildAnnotatedString {
                append("Saving data to ${saveLocationToDescription(dataSaveLocation)} under the name $datasetName.")
                append('\n')
                append("Images are ")
                appendNotBeingSaved()
            }
        }

        return AnnotatedString(
            "Saving data to ${saveLocationToDescription(
                dataSaveLocation,
            )} and images to ${saveLocationToDescription(imageSaveLocation)} under the name $datasetName.",
        )
    }
}

private fun AnnotatedString.Builder.appendNotBeingSaved() {
    withStyle(style = SpanStyle(color = Color.Red)) {
        append("not being saved")
    }
    append(". Go to Settings to change.")
}

private fun saveLocationToDescription(saveLocation: SaveLocation): String =
    when (saveLocation) {
        SaveLocation.NONE -> "nowhere" // should be unreachable, but avoiding ever throwing
        SaveLocation.LOCAL -> "My Files"
        SaveLocation.GOOGLE_DRIVE -> "Google Drive"
    }
