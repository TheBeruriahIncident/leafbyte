//
//  GoogleApiUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/21/18.
//  Copyright © 2018 Zoe Getman-Pickering. All rights reserved.
//

import Foundation

func createFolder(name: String, folderId: String? = nil, accessToken: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    createFile(name: name, folderId: folderId, type: "folder", accessToken: accessToken, onFileId: onFolderId, onFailure: onFailure)
}

func createSheet(name: String, folderId: String, accessToken: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    createFile(name: name, folderId: folderId, type: "spreadsheet", accessToken: accessToken, onFileId: onSpreadsheetId, onFailure: onFailure)
}

func appendToSheet(spreadsheetId: String, row: [String], accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    let formattedRow = row.map({"\"\($0)\""}).joined(separator: ",")
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS",
        accessToken: accessToken,
        jsonBody: "{values: [[\(formattedRow)]]}",
        onSuccessfulResponse: { response in onSuccess() },
        onUnsuccessfulResponse: { statusCode, _ in onFailure(isStatusCodeNotFound(statusCode)) },
        onError: { _ in onFailure(false) })
}

func freezeHeader(spreadsheetId: String, accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate",
        accessToken: accessToken,
        jsonBody:
        """
        {
          requests: [
            {
              updateSheetProperties: {
                properties: {
                  sheetId: 0,
                  gridProperties: {
                    frozenRowCount: 1
                  }
                },
                fields: "gridProperties.frozenRowCount"
              }
            }
          ]
        }
        """,
        onSuccessfulResponse: { response in onSuccess() },
        onUnsuccessfulResponse: { statusCode, _ in onFailure(isStatusCodeNotFound(statusCode)) },
        onError: { _ in onFailure(false) })
}

func uploadData(name: String, data: Data, folderId: String, accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    let boundary = "Boundary-\(UUID().uuidString)"

    var body = Data()
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(Data("Content-Type: application/json; charset=UTF-8\r\n\r\n".utf8))
    body.append(Data("{name: \"\(name)\", parents: [\"\(folderId)\"]}\r\n\r\n".utf8))
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(Data("Content-Type: image/png\r\n\r\n".utf8))
    body.append(data)
    body.append(Data("\r\n--\(boundary)--\r\n".utf8))
    
    post(url: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
            accessToken: accessToken,
            body: body,
            contentType: "multipart/related; boundary=\(boundary)",
            onSuccessfulResponse: { _ in onSuccess() },
            onUnsuccessfulResponse: { statusCode, _ in onFailure(isStatusCodeNotFound(statusCode)) },
            onError: { _ in onFailure(false) })
}

private func createFile(name: String, folderId: String?, type: String, accessToken: String, onFileId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    let parentsParam = folderId != nil
        ? " parents: [\"\(folderId!)\"],"
        : ""
    
    post(url: "https://www.googleapis.com/drive/v3/files",
         accessToken: accessToken,
         jsonBody:
         """
         {
           name: \"\(name)\",
           \(parentsParam)
           mimeType: \"application/vnd.google-apps.\(type)\"
         }
         """,
         onSuccessfulResponse: { response in onFileId(response["id"] as! String) },
         onUnsuccessfulResponse: { statusCode, _ in onFailure(isStatusCodeNotFound(statusCode)) },
         onError: { _ in onFailure(false) })
}

private func isStatusCodeNotFound(_ statusCode: Int) -> Bool {
    return statusCode == 404
}
