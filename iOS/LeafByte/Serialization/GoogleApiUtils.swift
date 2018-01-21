//
//  GoogleApiUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/21/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

func createFolder(name: String, accessToken: String, actionWithFolderId: @escaping (String) -> Void) {
    post(url: "https://www.googleapis.com/drive/v2/files",
        accessToken: accessToken,
        jsonBody: "{title: \"\(name)\", mimeType: \"application/vnd.google-apps.folder\"}",
        actionWithResponse: { response in actionWithFolderId(response["id"] as! String) })
}

func createSheet(name: String, folderId: String, accessToken: String, actionWithSpreadsheetId: @escaping (String) -> Void) {
    post(url: "https://www.googleapis.com/drive/v2/files",
         accessToken: accessToken,
         jsonBody: "{title: \"\(name)\", parents: [{id: \"\(folderId)\"}], mimeType: \"application/vnd.google-apps.spreadsheet\"}",
         actionWithResponse: { response in actionWithSpreadsheetId(response["id"] as! String) })
}

func appendToSheet(spreadsheetId: String, row: [String], accessToken: String) {
    let formattedRow = row.map({"\"\($0)\""}).joined(separator: ",")
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS",
        accessToken: accessToken,
        jsonBody: "{values: [[\(formattedRow)]]}")
}
