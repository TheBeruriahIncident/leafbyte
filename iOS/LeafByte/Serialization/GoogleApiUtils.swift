//
//  GoogleApiUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/21/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

func appendToSheet(spreadsheetId: String, row: [String], accessToken: String) {
    let formattedRow = row.map({"\"\($0)\""}).joined(separator: ",")
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=RAW&insertDataOption=INSERT_ROWS",
        accessToken: accessToken,
        jsonBody: "{values: [[\(formattedRow)]]}")
}
