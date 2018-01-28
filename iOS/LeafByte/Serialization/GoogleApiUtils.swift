//
//  GoogleApiUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/21/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation

func createFolder(name: String, folderId: String? = nil, accessToken: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    createFile(name: name, folderId: folderId, type: "folder", accessToken: accessToken, onFileId: onFolderId, onFailure: onFailure)
}

// TODO: this seemingly in the root for a moment
func createSheet(name: String, folderId: String, accessToken: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    createFile(name: name, folderId: folderId, type: "spreadsheet", accessToken: accessToken, onFileId: onSpreadsheetId, onFailure: onFailure)
}

func appendToSheet(spreadsheetId: String, row: [String], accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    let formattedRow = row.map({"\"\($0)\""}).joined(separator: ",")
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS",
        accessToken: accessToken,
        jsonBody: "{values: [[\(formattedRow)]]}",
        onSuccessfulResponse: { response in onSuccess() },
        onUnsuccessfulResponse: { _ in onFailure() },
        onError: { _ in onFailure() })
}

// TODO: simplify this with multipart upload
func uploadData(name: String, data: Data, folderId: String, accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    let parentsParam = " parents: [{id: \"\(folderId)\"}]"
    
    post(url: "https://www.googleapis.com/drive/v2/files",
        accessToken: accessToken,
        jsonBody: "{title: \"\(name)\",\(parentsParam)}",
        onSuccessfulResponse: { response in
            let fileId = response["id"] as! String
            makeRestCall(method: "PUT",
                 url: "https://www.googleapis.com/upload/drive/v2/files/\(fileId)?uploadType=media",
                 accessToken: accessToken,
                 body: data,
                 contentType: "image/png",
                 onSuccessfulResponse: { _ in onSuccess() },
                 onUnsuccessfulResponse: { _ in onFailure() },
                 onError: { _ in onFailure() })
        }, onUnsuccessfulResponse: { _ in onFailure() },
        onError: { _ in onFailure() })
}

private func createFile(name: String, folderId: String?, type: String, accessToken: String, onFileId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    let parentsParam = folderId != nil
        ? " parents: [{id: \"\(folderId!)\"}],"
        : ""
    
    post(url: "https://www.googleapis.com/drive/v2/files",
         accessToken: accessToken,
         jsonBody: "{title: \"\(name)\",\(parentsParam) mimeType: \"application/vnd.google-apps.\(type)\"}",
         onSuccessfulResponse: { response in onFileId(response["id"] as! String) },
         onUnsuccessfulResponse: { _ in onFailure() },
         onError: { _ in onFailure() })
}
