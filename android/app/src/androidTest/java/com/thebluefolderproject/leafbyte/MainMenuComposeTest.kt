package com.thebluefolderproject.leafbyte

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.isOff
import androidx.compose.ui.test.isOn
import androidx.compose.ui.test.isSelected
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import io.mockk.mockk
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension

class MainMenuComposeTest {
    // TODO once we factor to pure compose to fix some listener weirdness
    // test at least one version of the save location description
    // test that clicking settings, tutorial, gallery, barcode, camera, url takes you there
}