/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.google.signin

import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.compose.runtime.Composable
import com.thebluefolderproject.leafbyte.BuildConfig
import net.openid.appauth.AuthorizationResponse
import net.openid.appauth.AuthorizationService
import net.openid.appauth.AuthorizationServiceConfiguration

interface GoogleSignInManager {
    fun signIn(
        launcher: ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    )

    fun signOut()

    @Composable
    fun getLauncher(
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>
}

class GoogleSignInContractInput(
    val serviceConfig: AuthorizationServiceConfiguration,
    val authService: AuthorizationService,
)

fun isGoogleSignInConfigured(): Boolean = !BuildConfig.GOOGLE_SIGN_IN_CLIENT_ID.contains("FILL_THIS_IN")
