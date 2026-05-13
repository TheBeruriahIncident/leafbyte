/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.google.signin

import androidx.activity.compose.ManagedActivityResultLauncher
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.compose.runtime.Composable
import net.openid.appauth.AuthorizationResponse

class MockGoogleSignInManager : GoogleSignInManager {
    override fun signIn(
        launcher: ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?>,
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ) {}

    override fun signOut() {}

    @Composable
    override fun getLauncher(
        onSuccess: () -> Unit,
        onFailure: (GoogleSignInFailureType) -> Unit,
    ): ManagedActivityResultLauncher<GoogleSignInContractInput, AuthorizationResponse?> =
        rememberLauncherForActivityResult(GoogleSignInContract()) {
        }
}
