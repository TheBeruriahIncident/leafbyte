//
//  GoogleSignInManager.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/20/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import GoogleSignIn

class GoogleSignInManager: NSObject, GIDSignInUIDelegate, GIDSignInDelegate {
    func google() {
        
        
        GIDSignIn.sharedInstance().clientID = "82243022118-vmepc1s96dt76ss9pc46l2kvlo5mom1r.apps.googleusercontent.com"
        
        //adding the delegates
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = [ "https://www.googleapis.com/auth/spreadsheets" ]
        
        GIDSignIn.sharedInstance().signIn()
        
    }
    
    //when the signin complets
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        //if any error stop and print the error
        if error != nil{
            print(error ?? "google error")
            return
        }
        
        
        
        
        
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
