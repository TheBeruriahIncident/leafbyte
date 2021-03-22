//
//  GoogleSignInManager.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/20/18.
//  Copyright © 2018 Zoe Getman-Pickering. All rights reserved.
//

import GoogleSignIn

// This pretends to be a view controller to handle Google sign-in, because the delegate has a runtime requirement of being a view controller.
final class GoogleSignInManager: UIViewController, GIDSignInDelegate {
    // This is a static variable so that it doesn't get garbage collected before the callback ( https://en.wikipedia.org/wiki/Garbage_collection_(computer_science) ).
    static let googleSignInManager = GoogleSignInManager()
    
    var onAccessTokenAndUserId: ((_ accessToken: String, _ userId: String) -> Void)!
    var onError: ((_ error: Error) -> Void)!
    var callingViewController: UIViewController!
    
    static func initiateSignIn(onAccessTokenAndUserId: @escaping (_ accessToken: String, _ userId: String) -> Void, onError: @escaping (_ error: Error) -> Void, callingViewController: UIViewController) {
        googleSignInManager.onAccessTokenAndUserId = onAccessTokenAndUserId
        googleSignInManager.onError = onError
        googleSignInManager.callingViewController = callingViewController
        googleSignInManager.initiateSignIn()
    }
    
    func initiateSignIn() {
        // This is LeafByte's Google Drive API key.
        GIDSignIn.sharedInstance().clientID = "618315353176-fmg861cbe90sjm4gmsc7cq28c8t9v5ka.apps.googleusercontent.com"
        
        // Only request access to files created by LeafByte.
        GIDSignIn.sharedInstance().scopes = [ "https://www.googleapis.com/auth/drive.file" ]
        
        // Enable the sign callback below.
        GIDSignIn.sharedInstance().delegate = self
        // Make sign-in viewable by giving the modal a parent.
        GIDSignIn.sharedInstance().presentingViewController = callingViewController
        
        // If not already signed-in
        if !GIDSignIn.sharedInstance().hasPreviousSignIn() {
            // Actually sign in
            GIDSignIn.sharedInstance().signIn()
        } else {
            // Otherwise, restore the existing sign-in
            GIDSignIn.sharedInstance().restorePreviousSignIn()
        }
    }
    
    // MARK: - GIDSignInDelegate overrides
    
    // Called automatically when sign-in is complete.
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            onAccessTokenAndUserId(user.authentication.accessToken!, user.userID)
        } else {
            print("Unsuccessful Google Sign-In: " + error.localizedDescription)
            onError(error)
        }
        return
    }
}
