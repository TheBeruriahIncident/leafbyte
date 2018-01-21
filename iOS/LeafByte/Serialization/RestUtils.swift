//
//  RestUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/21/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation

func post(url: String, accessToken: String, jsonBody: String, actionWithResponse: @escaping ([String: Any]) -> Void = {response in ()}) {
    makeRestCall(method: "POST", url: url, accessToken: accessToken, body: jsonBody.data(using: .utf8)!, contentType: "application/json", actionWithResponse: actionWithResponse)
}

func makeRestCall(method: String, url urlString: String, accessToken: String, body: Data, contentType: String, actionWithResponse: @escaping ([String: Any]) -> Void = {response in ()}) {
    let url = URL(string: urlString)
    
    var request = URLRequest(url: url!)
    request.httpMethod = method
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.addValue(contentType, forHTTPHeaderField: "Content-Type")
    request.httpBody = body
    
    let session = URLSession(configuration: URLSessionConfiguration.default)
    
    let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
        if error != nil {
            fatalError(String(describing: error!))
        }
        
        var dataString: String?
        var dataJson: [String: Any]?
        if data != nil {
            dataString = String(data: data!, encoding: String.Encoding.utf8)!
            dataJson = try! JSONSerialization.jsonObject(with: data!) as! [String: Any]
        }
        
        if response != nil && (response! as! HTTPURLResponse).statusCode != 200 {
            fatalError("\((response! as! HTTPURLResponse).statusCode) on request to \(urlString): \(dataString ?? "no payload")")
        }
        
        if dataJson != nil {
            actionWithResponse(dataJson!)
        }
    }
    task.resume()
}
