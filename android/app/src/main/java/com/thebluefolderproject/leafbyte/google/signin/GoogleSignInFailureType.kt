/*
 * Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
 */

package com.thebluefolderproject.leafbyte.google.signin

enum class GoogleSignInFailureType {
    UNCONFIGURED,
    NON_INTERACTIVE_STAGE,
    INTERACTIVE_STAGE,
    NO_GET_USER_ID_SCOPE,
    NO_WRITE_TO_GOOGLE_DRIVE_SCOPE,
    NEITHER_SCOPE,
}
