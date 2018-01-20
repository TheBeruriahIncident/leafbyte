//
//  GoogleSignInManager.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/20/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import GoogleSignIn

class GoogleSignInManager: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {
    
    let actionWithAccessToken: (_ accessToken: String) -> Void
    
    init(actionWithAccessToken: @escaping (_ accessToken: String) -> Void) {
        self.actionWithAccessToken = actionWithAccessToken
    }
    
    func initiateSignIn() {
        // This is LeafByte's Google Drive API key.
        GIDSignIn.sharedInstance().clientID = "82243022118-vmepc1s96dt76ss9pc46l2kvlo5mom1r.apps.googleusercontent.com"
        
        // Only request access to files created by LeafByte.
        GIDSignIn.sharedInstance().scopes = [ "https://www.googleapis.com/auth/drive.file" ]
        
        // Enable callback once the sign-in completes.
        // TODO: are both needed? same for protocols
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        
        // Actually do the sign-in.
        GIDSignIn.sharedInstance().signIn()
    }
    
    // Called automatically when sign-in is complete.
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

        // TODO: how to get errors out!??
        //if any error stop and print the error
        if error != nil{
            print(error ?? "google error")
            return
        }
        
        
        
        
        actionWithAccessToken(user.authentication.accessToken!)
        return
        
        let token = user.authentication.accessToken!
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/1Kiw83_ED0nFtDq5TnOCY3IJunocWrsOP9REAHSJ37B8/values/Sheet1!A:A:append?valueInputOption=RAW")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        request.httpBody = "{values: [[\"foo\"]]}".data(using: .utf8)
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization" : "Bearer \(token)"]
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request as URLRequest) {
            (data, response, error) in
            
            print(error)
            
            let dataString =  String(data: data!, encoding: String.Encoding.utf8)
            print(dataString)
            
        }
        
        task.resume()
        
    }
}
