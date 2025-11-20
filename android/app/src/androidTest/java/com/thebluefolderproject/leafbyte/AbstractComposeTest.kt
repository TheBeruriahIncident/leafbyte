/**
 * Copyright © 2025 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte

import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import com.thebluefolderproject.leafbyte.activity.NavigationRoot
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import com.thebluefolderproject.leafbyte.utils.log
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import io.mockk.mockk
import org.junit.jupiter.api.extension.RegisterExtension

@OptIn(ExperimentalTestApi::class)
@Suppress("style:ThrowsCount", "style:UnnecessaryAbstractClass")
abstract class AbstractComposeTest(
    val navigateToCorrectScreen: ComposeContext.() -> Unit,
) {
    @RegisterExtension
    private val extension = createComposeExtension()

    private val clock = TestClock()

    protected fun runTest(
        initializeSettings: (Settings) -> Unit = {},
        test: ComposeContext.(settings: Settings, googleSignInManager: GoogleSignInManager) -> Unit,
    ) {
        initializeLogInterception()

        try {
            log("Setting up Compose test")
            extension.use {
                var settings: Settings? = null
                val googleSignInManager = mockk<GoogleSignInManager>(relaxed = true)

                setContent {
                    // clear any prior state (this can't happen in @Before or @After because of Compose complexities)
                    clearSettingsStore(LocalContext.current)

                    settings = DataStoreBackedSettings(LocalContext.current, clock)
                    log("Initializing settings")
                    initializeSettings(settings)

                    log("Starting up Compose app")
                    NavigationRoot(injectedSettings = settings, injectedGoogleSignInManager = googleSignInManager)
                }

                log("Navigating to correct screen for specific test")
                navigateToCorrectScreen(this)

                try {
                    log("Running specific test")
                    test(this, settings!!, googleSignInManager)
                    log("Completed running specific test")
                } catch (throwable: Throwable) {
                    throw ComposeTestFailureException(this, throwable)
                }
            }
        } catch (throwable: Throwable) {
            if (throwable is ComposeTestFailureException) {
                throw throwable
            } else {
                throw ComposeTestFailureException(context = null, throwable)
            }
        }
    }

    protected fun waitASecond() {
        clock.waitASecond()
    }
}
