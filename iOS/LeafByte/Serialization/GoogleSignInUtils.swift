//
//  GoogleSignInUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/20/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AppAuth

enum GoogleSignInFailureCause {
    case generic
    case noGetUserIdScope
    case noWriteToGoogleDriveScope
    case neitherScope
}

private enum JwtPayloadKey {
    // Short for "subject"
    static let userId = "sub"
    static let scopes = "scope"
}
private enum Scope {
    static let getUserId = "openid"
    static let writeToGoogleDrive = "https://www.googleapis.com/auth/drive.file"
}
private let requiredScopesList = [Scope.getUserId, Scope.writeToGoogleDrive]
private let requiredScopes = Set(requiredScopesList)

private let issuerUrl = URL(string: "https://accounts.google.com")!
// DO NOT CHECK THESE IN.
private let clientId = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SIGN_IN_CLIENT_ID") as! String
private let redirectUrl = URL(string: Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SIGN_IN_REDIRECT_URL") as! String)!
private let incompleteConfigIndicator = "FILL_ME_IN"

func isGoogleSignInConfigured() -> Bool {
    isConfigInitialized(clientId) && isConfigInitialized(redirectUrl.absoluteString)
}

private func isConfigInitialized(_ configValue: String) -> Bool {
    !configValue.isEmpty && !configValue.contains(incompleteConfigIndicator)
}

func initiateGoogleSignIn(
    onAccessTokenAndUserId: @escaping (_ accessToken: String, _ userId: String) -> Void,
    onError: @escaping (_ cause: GoogleSignInFailureCause, _ error: Error?) -> Void,
    callingViewController: UIViewController,
    settings: Settings) {

        tryToUseExistingLogin(
            authState: settings.googleAuthState,
            onAccessTokenAndUserId: onAccessTokenAndUserId,
            ifNoExistingLogin: {
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
                    guard let configuration = configuration else {
                        print("Error retrieving OAuth discovery document: \(error?.localizedDescription ?? "no error information")")
                        return onError(.generic, error)
                    }

                    let request = OIDAuthorizationRequest(
                        configuration: configuration,
                        clientId: clientId,
                        clientSecret: nil,
                        scopes: requiredScopesList,
                        redirectURL: redirectUrl,
                        responseType: OIDResponseTypeCode,
                        additionalParameters: nil)

                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                        print("Error accessing AppDelegate")
                        return onError(.generic, nil)
                    }
                    // This call will automatically protect with PKCE if possible (according to https://github.com/openid/AppAuth-iOS)
                    appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: callingViewController) { authState, error in
                        guard let authState = authState else {
                            print("Did not receive auth state after auth flow: \(error?.localizedDescription ?? "no error information")")
                            return onError(.generic, error)
                        }

                        settings.googleAuthState = authState
                        settings.serialize()

                        useAuthState(authState: authState, onAccessTokenAndUserId: onAccessTokenAndUserId, onError: onError)
                    }
                }
            })
    }

private func tryToUseExistingLogin(
    authState: OIDAuthState?,
    onAccessTokenAndUserId: @escaping (_ accessToken: String, _ userId: String) -> Void,
    ifNoExistingLogin: @escaping () -> Void) {

        guard let authState = authState, authState.isAuthorized else {
            return ifNoExistingLogin()
        }

        useAuthState(authState: authState, onAccessTokenAndUserId: onAccessTokenAndUserId, onError: { _, _ in ifNoExistingLogin() })
    }

private func useAuthState(
    authState: OIDAuthState,
    onAccessTokenAndUserId: @escaping (_ accessToken: String, _ userId: String) -> Void,
    onError: @escaping (_ cause: GoogleSignInFailureCause, _ error: Error?) -> Void) {
        authState.performAction { (accessToken, idToken, error) in
            if error != nil {
                print("Error when getting a fresh token from the existing auth state: \(error!.localizedDescription)")
                return onError(.generic, error)
            }
            guard let accessToken = accessToken else {
                print("No access token received from existing auth state")
                return onError(.generic, nil)
            }
            guard let idToken = idToken else {
                print("Access token available, but no id token received from existing auth state")
                return onError(.generic, nil)
            }
            guard let jwtPayload = extractPayload(fromJwt: idToken) else {
                print("Failed to extract payload from jwt: \(idToken)")
                return onError(.generic, nil)
            }
            guard let googleUserId = jwtPayload[JwtPayloadKey.userId] as? String else {
                print("Failed to retrieve Google user id from jwt payload: \(jwtPayload)")
                return onError(.generic, nil)
            }

            let currentScopes = getGrantedScopes(authState: authState)
            guard requiredScopes.isSubset(of: currentScopes) else {
                print("Don't yet have sufficient access. Current scopes: \(currentScopes)")

                if currentScopes.contains(Scope.getUserId) {
                    return onError(.noWriteToGoogleDriveScope, nil)
                } else if currentScopes.contains(Scope.writeToGoogleDrive) {
                    return onError(.noGetUserIdScope, nil)
                } else {
                    return onError(.neitherScope, nil)
                }
            }

            onAccessTokenAndUserId(accessToken, googleUserId)
        }
}

private func getGrantedScopes(authState: OIDAuthState) -> Set<String> {
    guard let scopeString = authState.scope else {
        // This field is nullable for no documented reason. The contract of the RFC is that this MAY be null in the wire type if all requested scopes were granted. The AppAuth implementation however explicitly hides that from the consumer and fills in the requested scopes for this type if the wire type doesn't contain scopes. So, we don't know why this is null, but we handle it as if it's null for the same reason as the wire type might be.
        return requiredScopes
    }

    let currentScopesList: [String] = scopeString
        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        .components(separatedBy: " ")
    return Set(currentScopesList)
}
