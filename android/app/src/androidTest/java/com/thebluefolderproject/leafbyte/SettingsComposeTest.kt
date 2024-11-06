package com.thebluefolderproject.leafbyte

import android.net.Uri
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isEnabled
import androidx.compose.ui.test.isNotEnabled
import androidx.compose.ui.test.isNotSelected
import androidx.compose.ui.test.isOff
import androidx.compose.ui.test.isOn
import androidx.compose.ui.test.isSelected
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextReplacement
import androidx.test.espresso.Espresso
import com.thebluefolderproject.leafbyte.fragment.AlertType
import com.thebluefolderproject.leafbyte.fragment.DataStoreBackedSettings
import com.thebluefolderproject.leafbyte.fragment.SaveLocation
import com.thebluefolderproject.leafbyte.fragment.Settings
import com.thebluefolderproject.leafbyte.fragment.SettingsScreen
import com.thebluefolderproject.leafbyte.fragment.clearSettingsStore
import com.thebluefolderproject.leafbyte.fragment.getAlertMessage
import com.thebluefolderproject.leafbyte.utils.GoogleSignInFailureType
import com.thebluefolderproject.leafbyte.utils.GoogleSignInManager
import de.mannodermaus.junit5.compose.ComposeContext
import de.mannodermaus.junit5.compose.createComposeExtension
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import kotlinx.collections.immutable.persistentListOf
import kotlinx.coroutines.flow.Flow
import net.openid.appauth.AuthState
import net.openid.appauth.AuthorizationRequest
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationServiceConfiguration
import net.openid.appauth.TokenRequest
import net.openid.appauth.TokenResponse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.RegisterExtension

@OptIn(ExperimentalTestApi::class)
class SettingsComposeTest {
    @JvmField
    @RegisterExtension
    val extension = createComposeExtension()

    val clock = TestClock()

    private fun runTest(
        initializeSettings: (Settings) -> Unit = {},
        test: ComposeContext.(settings: Settings, googleSignInManager: GoogleSignInManager) -> Unit,
    ) {
        // TODO pull this logic out into a helper (or more likely an abstract class because of the extension field)
        //   probably doesn't make sense to do until the dust settles on moving nav over to compose
        extension.use {
            var settings: Settings? = null
            val googleSignInManager = mockk<GoogleSignInManager>(relaxed = true)

            setContent {
                // clear any prior state (this can't happen in @Before or @After because of Compose complexities)
                clearSettingsStore(LocalContext.current)

                settings = DataStoreBackedSettings(LocalContext.current, clock)
                initializeSettings(settings)
                SettingsScreen(settings, googleSignInManager)
            }

            try {
                test(this, settings!!, googleSignInManager)
            } catch (throwable: Throwable) {
                throw ComposeTestFailureException(this, throwable)
            }
        }
    }

    private fun waitASecond() {
        clock.waitASecond()
    }

    @Test
    fun testInitialState() {
        runTest({ settings ->
            settings.setDataSaveLocation(SaveLocation.GOOGLE_DRIVE)
            settings.setImageSaveLocation(SaveLocation.LOCAL)
            settings.setDatasetName("unique dataset name")
            settings.setScaleMarkLength(26f)
            settings.setScaleLengthUnit("ft")
            settings.setNextSampleNumber(63)
            settings.setUseBarcode(true)
            settings.setSaveGpsData(false)
            settings.setUseBlackBackground(true)
        }) { settings, googleSignInManager ->
            onNodeWithContentDescription("Set Data Save Location to Google Drive").assert(isSelected())
            onNodeWithContentDescription("Set Image Save Location to My Files").assert(isSelected())
            onNodeWithText("unique dataset name").assertExists()
            onNodeWithText("26.0").assertExists()
            onNodeWithText("ft").assertExists()
            onNodeWithText("63").assertExists()
            onNodeWithContentDescription("Scan Barcodes? toggle").assert(isOn())
            onNodeWithContentDescription("Save GPS Location? toggle").assert(isOff())
            onNodeWithContentDescription("Use Black Background? toggle").assert(isOn())
        }
    }

    @Test
    fun testSaveLocations() {
        runTest { settings, googleSignInManager ->
            val dataNone = onNodeWithContentDescription("Set Data Save Location to None")
            val dataLocal = onNodeWithContentDescription("Set Data Save Location to My Files")
            val dataGoogle = onNodeWithContentDescription("Set Data Save Location to Google Drive")
            fun dataSelectionIs(node: SemanticsNodeInteraction) {
                node.assert(isSelected())

                if (node != dataNone) {
                    dataNone.assert(isNotSelected())
                }
                if (node != dataLocal) {
                    dataLocal.assert(isNotSelected())
                }
                if (node != dataGoogle) {
                    dataGoogle.assert(isNotSelected())
                }
            }

            val imageNone = onNodeWithContentDescription("Set Image Save Location to None")
            val imageLocal = onNodeWithContentDescription("Set Image Save Location to My Files")
            val imageGoogle = onNodeWithContentDescription("Set Image Save Location to Google Drive")
            fun imageSelectionIs(node: SemanticsNodeInteraction) {
                node.assert(isSelected())

                if (node != imageNone) {
                    imageNone.assert(isNotSelected())
                }
                if (node != imageLocal) {
                    imageLocal.assert(isNotSelected())
                }
                if (node != imageGoogle) {
                    imageGoogle.assert(isNotSelected())
                }
            }

            testSaveLocation(
                googleSignInManager = googleSignInManager,
                noneButton = dataNone,
                localButton = dataLocal,
                googleButton = dataGoogle,
                selectionIs = ::dataSelectionIs,
                getSaveLocationInSettings = settings::getDataSaveLocation,
                otherLocalButton = imageLocal,
                otherGoogleButton = imageGoogle,
                otherSelectionIs = ::imageSelectionIs,
                getOtherSaveLocationInSettings = settings::getImageSaveLocation,
            )
            testSaveLocation(
                googleSignInManager = googleSignInManager,
                noneButton = imageNone,
                localButton = imageLocal,
                googleButton = imageGoogle,
                selectionIs = ::imageSelectionIs,
                getSaveLocationInSettings = settings::getImageSaveLocation,
                otherLocalButton = dataLocal,
                otherGoogleButton = dataGoogle,
                otherSelectionIs = ::dataSelectionIs,
                getOtherSaveLocationInSettings = settings::getDataSaveLocation,
            )
        }
    }

    /**
     * This abstracts out the logic for testing both data and image save locations
     */
    fun ComposeContext.testSaveLocation(
        googleSignInManager: GoogleSignInManager,
        noneButton: SemanticsNodeInteraction,
        localButton: SemanticsNodeInteraction,
        googleButton: SemanticsNodeInteraction,
        selectionIs: (SemanticsNodeInteraction) -> Unit,
        getSaveLocationInSettings: () -> Flow<SaveLocation>,
        otherLocalButton: SemanticsNodeInteraction,
        otherGoogleButton: SemanticsNodeInteraction,
        otherSelectionIs: (SemanticsNodeInteraction) -> Unit,
        getOtherSaveLocationInSettings: () -> Flow<SaveLocation>,
    ) {
        // *********** First we test the non-Google options ***************
        localButton.performClick()
        selectionIs(localButton)
        assertFlowEquals(SaveLocation.LOCAL, getSaveLocationInSettings())

        noneButton.performClick()
        selectionIs(noneButton)
        assertFlowEquals(SaveLocation.NONE, getSaveLocationInSettings())

        // *********** And now Google ***************
        // precondition is set above, but just in case of refactors
        selectionIs(noneButton)

        val onSuccessSlot = slot<() -> Unit>()
        val onFailureSlot = slot<(GoogleSignInFailureType) -> Unit>()
        every { googleSignInManager.signIn(any(), onSuccess = capture(onSuccessSlot), onFailure = capture(onFailureSlot)) } returns Unit

        // click to save to Google and see that the UI shows that you've done that, but the persistence layer hasn't updated yet
        clearMockedMethodCallCounts(googleSignInManager)
        verify(exactly = 0) { googleSignInManager.signIn(any(), any(), any()) }
        googleButton.performClick()
        verify(exactly = 1) { googleSignInManager.signIn(any(), any(), any()) }
        selectionIs(googleButton)
        assertFlowEquals(SaveLocation.NONE, getSaveLocationInSettings())

        // save these so that new captures don't override them (when we click the otherGoogleButton)
        val onSuccess = onSuccessSlot.captured
        val onFailure = onFailureSlot.captured

        fun testGoogleFailure(
            googleSignInFailureType: GoogleSignInFailureType,
            alertType: AlertType,
        ) {
            // this doesn't make sense in the flow, but we reset the UI and settings to NONE in order to validate the failure callbacks
            noneButton.performClick()
            selectionIs(noneButton)
            assertFlowEquals(SaveLocation.NONE, getSaveLocationInSettings())
            // and we set the other save location setting to GOOGLE to see that it gets switched as well
            otherGoogleButton.performClick()

            onFailure(googleSignInFailureType)

            // Check and dismiss the alert, then validate the new state
            onNodeWithText(getAlertMessage(alertType)).assertExists()
            onNodeWithText("OK").performClick()
            onNodeWithText(getAlertMessage(alertType)).assertDoesNotExist()
            selectionIs(localButton)
            assertFlowEquals(SaveLocation.LOCAL, getSaveLocationInSettings())
            otherSelectionIs(otherLocalButton)
            assertFlowEquals(SaveLocation.LOCAL, getOtherSaveLocationInSettings())
        }
        testGoogleFailure(GoogleSignInFailureType.UNCONFIGURED, AlertType.GOOGLE_SIGN_IN_UNCONFIGURED)
        testGoogleFailure(GoogleSignInFailureType.NON_INTERACTIVE_STAGE, AlertType.GOOGLE_SIGN_IN_NON_INTERACTIVE_STAGE_FAILURE)
        testGoogleFailure(GoogleSignInFailureType.INTERACTIVE_STAGE, AlertType.GOOGLE_SIGN_IN_INTERACTIVE_STAGE_FAILURE)
        testGoogleFailure(GoogleSignInFailureType.NEITHER_SCOPE, AlertType.GOOGLE_SIGN_IN_NEITHER_SCOPE)
        testGoogleFailure(GoogleSignInFailureType.NO_GET_USER_ID_SCOPE, AlertType.GOOGLE_SIGN_IN_NO_GET_USER_ID_SCOPE)
        testGoogleFailure(GoogleSignInFailureType.NO_WRITE_TO_GOOGLE_DRIVE_SCOPE, AlertType.GOOGLE_SIGN_IN_NO_WRITE_TO_GOOGLE_DRIVE_SCOPE)

        // only now do we test the happy path
        onSuccess()
        selectionIs(googleButton)
        assertFlowEquals(SaveLocation.GOOGLE_DRIVE, getSaveLocationInSettings())
    }

    @Test
    fun testDatasetName() {
        runTest { settings, googleSignInManager ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")

            datasetNameField.performTextReplacement("test dataset 123")
            assertFlowEquals("test dataset 123", settings.getDatasetName())
            datasetNameField.assert(hasText("test dataset 123"))

            datasetNameField.performTextClearance()
            assertFlowEquals("Herbivory Data", settings.getDatasetName())
            // the placeholder and explanation are included
            datasetNameField.assert(hasText("Your dataset name"))
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("    \n ")
            assertFlowEquals("Herbivory Data", settings.getDatasetName())
            // it's trimmed before comparison
            datasetNameField.assert(hasText("Dataset name is required"))

            datasetNameField.performTextReplacement("valid")
            assertFlowEquals("valid", settings.getDatasetName())
            datasetNameField.assert(hasText("valid"))

            // confirm unicode works properly
            datasetNameField.performTextReplacement("שלום jalapeño 你好 ")
            assertFlowEquals("שלום jalapeño 你好 ", settings.getDatasetName())
            datasetNameField.assert(hasText("שלום jalapeño 你好 "))
        }
    }

    @Test
    fun testBackButtonWorksNormally() {
        runTest { settings, googleSignInManager ->
            // you can press back to leave the screen
            assertClosesApp {
                Espresso.pressBack()
            }
        }
    }

    @Test
    fun testBackButtonBlockedByEmptyDatasetName() {
        runTest { settings, googleSignInManager ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")
            datasetNameField.performTextClearance() // Put the screen into an invalid state where we shouldn't be allowed to leave

            Espresso.pressBack() // one back to close the keyboard
            val state1 = printScreen()
            Espresso.pressBack() // and one to actually go back
            val state2 = printScreen()
            Espresso.pressBack() // and why not again...
            val state3 = printScreen()
            throw AssertionError("After first back press:\n $state1 \n after second back press \n $state2 \n after extraneous third \n $state3")

            val errorMessage = onNodeWithText(getAlertMessage(AlertType.BACK_WITHOUT_DATASET_NAME))
            errorMessage.assertExists()
            onNodeWithText("OK").performClick()
            errorMessage.assertDoesNotExist()

            // Confirm that the alert returns if we keep pressing back
            Espresso.pressBack()
            errorMessage.assertExists()
            onNodeWithText("OK").performClick()
            errorMessage.assertDoesNotExist()

            datasetNameField.performTextReplacement("non-empty")
            // and now we can leave
            assertClosesApp {
                Espresso.pressBack()
            }
        }
    }

    @Test
    fun testUsePreviousDataset() {
        runTest { settings, googleSignInManager ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")

            datasetNameField.performTextReplacement("test1")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("test3")
            settings.noteDatasetUsed()
            waitASecond()

            assertFlowEquals(persistentListOf("test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("ephemeral")
            assertFlowEquals(persistentListOf("ephemeral", "test3", "test2", "test1"), settings.getPreviousDatasetNames())

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            waitASecond()

            datasetNameField.performTextReplacement("ephemeral2")
            assertFlowEquals(persistentListOf("ephemeral2", "test2", "test3", "test1"), settings.getPreviousDatasetNames())

            onNodeWithText("test2").assertDoesNotExist()
            onNodeWithText("Use previous dataset").performClick()

            val ephemeral2 = onAllNodesWithText("ephemeral2")[1]
            val test2 = onNodeWithText("test2")
            val test3 = onNodeWithText("test3")
            val test1 = onNodeWithText("test1")

            assertTrue(yPositionOf(ephemeral2) < yPositionOf(test2))
            assertTrue(yPositionOf(test2) < yPositionOf(test3))
            assertTrue(yPositionOf(test3) < yPositionOf(test1))

            test3.performClick()
            assertFlowEquals("test3", settings.getDatasetName())
            datasetNameField.assert(hasText("test3"))
        }
    }

    private fun yPositionOf(node: SemanticsNodeInteraction): Float {
        return node.fetchSemanticsNode().boundsInRoot.top
    }

    @Test
    fun testScaleLength() {
        runTest { settings, googleSignInManager ->
            val scaleLengthEntry = onNodeWithContentDescription("Scale length entry")

            scaleLengthEntry.performTextReplacement("15")
            assertFlowEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15"))

            scaleLengthEntry.performTextClearance()
            assertFlowEquals(10f, settings.getScaleMarkLength())
            // the placeholder is included
            scaleLengthEntry.assert(hasText("Your scale length"))

            scaleLengthEntry.performTextReplacement("hello")
            assertFlowEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText(""))

            scaleLengthEntry.performTextReplacement("15.0000")
            assertFlowEquals(15f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0000"))

            scaleLengthEntry.performTextReplacement("15.0.1")
            assertFlowEquals(10f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("15.0.1"))

            scaleLengthEntry.performTextReplacement("-2")
            assertFlowEquals(2f, settings.getScaleMarkLength())
            scaleLengthEntry.assert(hasText("2"))
        }
    }

    @Test
    fun testScaleLengthUnit() {
        runTest { settings, googleSignInManager ->
            assertFlowEquals("cm", settings.getScaleLengthUnit())

            onNodeWithText("cm").performClick()
            onNodeWithText("in").performClick()
            assertFlowEquals("in", settings.getScaleLengthUnit())

            onNodeWithText("in").performClick()
            onNodeWithText("ft").performClick()
            assertFlowEquals("ft", settings.getScaleLengthUnit())
        }
    }

    @Test
    fun testNextSampleNumber() {
        runTest { settings, googleSignInManager ->
            val nextSampleNumberEntry = onNodeWithContentDescription("Next sample number entry")

            nextSampleNumberEntry.performTextReplacement("15")
            assertFlowEquals(15, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("15"))

            nextSampleNumberEntry.performTextClearance()
            assertFlowEquals(1, settings.getNextSampleNumber())

            nextSampleNumberEntry.performTextReplacement("hello")
            assertFlowEquals(1, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText(""))

            nextSampleNumberEntry.performTextReplacement("15.00")
            assertFlowEquals(1500, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1500"))

            nextSampleNumberEntry.performTextReplacement("15.0.1")
            assertFlowEquals(1501, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("1501"))

            nextSampleNumberEntry.performTextReplacement("-2")
            assertFlowEquals(2, settings.getNextSampleNumber())
            nextSampleNumberEntry.assert(hasText("2"))
        }
    }

    @Test
    fun testChangingDatasetChangesOtherSettings() {
        runTest { settings, googleSignInManager ->
            val datasetNameField = onNodeWithContentDescription("Dataset name entry")
            val scaleLengthField = onNodeWithContentDescription("Scale length entry")
            val scaleUnitButton = onNodeWithContentDescription("Scale length unit selector")
            val nextSampleNumberField = onNodeWithContentDescription("Next sample number entry")

            datasetNameField.performTextReplacement("test1")
            settings.noteDatasetUsed()
            scaleLengthField.performTextReplacement("100")
            scaleUnitButton.performClick()
            onNodeWithText("ft").performClick()
            nextSampleNumberField.performTextReplacement("100")

            datasetNameField.performTextReplacement("test2")
            settings.noteDatasetUsed()
            scaleLengthField.performTextReplacement("200")
            scaleUnitButton.performClick()
            onNodeWithText("m").performClick()
            nextSampleNumberField.performTextReplacement("200")

            assertFlowEquals("test2", settings.getDatasetName())
            datasetNameField.assert(hasText("test2"))
            assertFlowEquals(200f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("200"))
            assertFlowEquals("m", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("m"))
            assertFlowEquals(200, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("200"))

            onNodeWithText("Use previous dataset").performClick()
            onNodeWithText("test1").performClick()

            assertFlowEquals("test1", settings.getDatasetName())
            datasetNameField.assert(hasText("test1"))
            assertFlowEquals(100f, settings.getScaleMarkLength())
            scaleLengthField.assert(hasText("100.0"))
            assertFlowEquals("ft", settings.getScaleLengthUnit())
            scaleUnitButton.assert(hasText("ft"))
            assertFlowEquals(100, settings.getNextSampleNumber())
            nextSampleNumberField.assert(hasText("100"))
        }
    }

    @Test
    fun testScanBarcodes() {
        runTest { settings, googleSignInManager ->
            val toggle =
                onNodeWithContentDescription("Scan Barcodes? toggle")
                    .performScrollTo()
            assertFlowEquals(false, settings.getUseBarcode())
            toggle.assert(isOff())

            onNodeWithContentDescription("Set Data Save Location to None")
                .performScrollTo()
                .performClick()
            toggle.performScrollTo()
                .assert(isNotEnabled())
                .performClick()
                .assert(isOff())
            onNodeWithContentDescription("Set Data Save Location to My Files")
                .performScrollTo()
                .performClick()
            toggle.performScrollTo()
                .assert(isEnabled())

            assertFlowEquals(false, settings.getUseBarcode())
            toggle.performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getUseBarcode())
            toggle.performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getUseBarcode())
        }
    }

    @Test
    fun testSaveGps() {
        runTest { settings, googleSignInManager ->
            val toggle =
                onNodeWithContentDescription("Save GPS Location? toggle")
                    .performScrollTo()
            assertFlowEquals(false, settings.getSaveGpsData())
            toggle.assert(isOff())

            onNodeWithContentDescription("Set Data Save Location to None")
                .performScrollTo()
                .performClick()
            toggle.performScrollTo()
                .assert(isNotEnabled())
                .performClick()
                .assert(isOff())
            onNodeWithContentDescription("Set Data Save Location to My Files")
                .performScrollTo()
                .performClick()
            toggle.performScrollTo()
                .assert(isEnabled())

            assertFlowEquals(false, settings.getSaveGpsData())
            toggle.performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getSaveGpsData())
            toggle.performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getSaveGpsData())
        }
    }

    @Test
    fun testUseBlackBackground() {
        runTest { settings, googleSignInManager ->
            assertFlowEquals(false, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle")
                .assert(isOff())
                .performScrollTo()
                .performClick()
                .assert(isOn())
            onNodeWithContentDescription("Check mark").assertExists()
            assertFlowEquals(true, settings.getUseBlackBackground())
            onNodeWithContentDescription("Use Black Background? toggle")
                .performClick()
                .assert(isOff())
            assertFlowEquals(false, settings.getUseBlackBackground())
        }
    }

    @Test
    fun testSignOutOfGoogle() {
        runTest { settings, googleSignInManager ->
            val button = onNodeWithText("Sign out of Google").performScrollTo()

            button.assert(isNotEnabled())
            button.performClick()
            verify(exactly = 0) { googleSignInManager.signOut() }

            val config = AuthorizationServiceConfiguration(Uri.parse("auth endpoint"), Uri.parse("token endpoint"))
            val authRequest =
                AuthorizationRequest.Builder(config, "client id", "code", Uri.parse("redirect"))
                    .build()
            val authResponse =
                AuthorizationResponse.Builder(authRequest)
                    .build()
            val tokenRequest =
                TokenRequest.Builder(config, "client id")
                    .setGrantType("grant")
                    .build()
            val tokenResponse =
                TokenResponse.Builder(tokenRequest)
                    .setAccessToken("access")
                    .setIdToken("id")
                    .build()
            val authState = AuthState(authResponse, tokenResponse, null)
            settings.setAuthState(authState)

            button.assert(isEnabled())
            button.performClick()
            verify(exactly = 1) { googleSignInManager.signOut() }
        }
    }
}
