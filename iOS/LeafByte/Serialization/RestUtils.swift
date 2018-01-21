//
//  RestUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/21/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation

func post(url: String, accessToken: String, jsonBody: String) {
    let url = URL(string: url)
    
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonBody.data(using: .utf8)
    
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
        if error != nil {
            print(error!)
        }
        if data != nil {
            let dataString = String(data: data!, encoding: String.Encoding.utf8)!
            print(dataString)
        }
    }
    task.resume()
}
