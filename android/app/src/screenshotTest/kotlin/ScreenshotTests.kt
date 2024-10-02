package com.thebluefolderproject.leafbyte

import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.tooling.preview.Preview
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen

class ScreenshotTests {
    @Preview(showBackground = true)
    @Composable
    fun SettingsPreview() {
        val settings = DataStoreBackedSettings(LocalContext.current)
        SettingsScreen(settings)
    }
}
