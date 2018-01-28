//
//  GoogleSignInManager.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/20/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import GoogleSignIn

// This pretends to be a view controller, because the delegate has a runtime requirement of being a view controller.
class GoogleSignInManager: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    // This is a static variable so that it doesn't get garbage collected before the callback.
    static let googleSignInManager = GoogleSignInManager()
    
    var actionWithAccessToken: ((_ accessToken: String) -> Void)!
    var actionWithError: ((_ error: Error) -> Void)!
    
    static func initiateSignIn(actionWithAccessToken: @escaping (_ accessToken: String) -> Void, actionWithError: @escaping (_ error: Error) -> Void) {
        googleSignInManager.actionWithAccessToken = actionWithAccessToken
        googleSignInManager.actionWithError = actionWithError
        googleSignInManager.initiateSignIn()
    }
    
    func initiateSignIn() {
        // This is LeafByte's Google Drive API key.
        GIDSignIn.sharedInstance().clientID = "618315353176-fmg861cbe90sjm4gmsc7cq28c8t9v5ka.apps.googleusercontent.com"
        
        // Only request access to files created by LeafByte.
        GIDSignIn.sharedInstance().scopes = [ "https://www.googleapis.com/auth/drive.file" ]
        
        // Enable callback once the sign-in completes.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Actually do the sign-in.
        GIDSignIn.sharedInstance().signIn()
    }
    
    // Called automatically when sign-in is complete.
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error == nil {
            actionWithAccessToken(user.authentication.accessToken!)
        } else {
            actionWithError(error)
        }
        return
    }
}
