//
//  GoogleApiUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/21/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import Foundation

func createFolder(name: String, folderId: String? = nil, accessToken: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    createFile(name: name, folderId: folderId, type: "folder", accessToken: accessToken, onFileId: onFolderId, onFailure: onFailure)
}

func createSheet(name: String, folderId: String, accessToken: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    createFile(name: name, folderId: folderId, type: "spreadsheet", accessToken: accessToken, onFileId: onSpreadsheetId, onFailure: onFailure)
}

func appendToSheet(spreadsheetId: String, row: [String], accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    let formattedRow = row.map { "\"\($0)\"" }.joined(separator: ",")
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId)/values/Sheet1:append?valueInputOption=USER_ENTERED&insertDataOption=INSERT_ROWS",
        accessToken: accessToken,
        jsonBody: "{values: [[\(formattedRow)]]}",
        onSuccessfulResponse: { _ in onSuccess() },
        onUnsuccessfulResponse: { statusCode, response in
            print("Failed to append to sheet. Status code: \(statusCode). Response: \(response)")
            return onFailure(isStatusCodeNotFound(statusCode))
        },
        onError: { error in
            print("Failed to append to sheet. Error: \(error)")
            return onFailure(false)
        })
}

func freezeHeader(spreadsheetId: String, accessToken: String, onSuccess: @escaping () -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    post(url: "https://sheets.googleapis.com/v4/spreadsheets/\(spreadsheetId):batchUpdate",
        accessToken: accessToken,
        // swiftlint:disable indentation_width
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
        // swiftlint:enable indentation_width
        onSuccessfulResponse: { _ in onSuccess() },
        onUnsuccessfulResponse: { statusCode, response in
            print("Failed to freeze header. Status code: \(statusCode). Response: \(response)")
            return onFailure(isStatusCodeNotFound(statusCode))
        },
        onError: { error in
            print("Failed to freeze header. Error: \(error)")
            return onFailure(false)
        })
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

    post(
        url: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
        accessToken: accessToken,
        body: body,
        contentType: "multipart/related; boundary=\(boundary)",
        onSuccessfulResponse: { _ in onSuccess() },
        onUnsuccessfulResponse: { statusCode, response in
            print("Failed to upload data. Status code: \(statusCode). Response: \(response)")
            return onFailure(isStatusCodeNotFound(statusCode))
        },
        onError: { error in
            print("Failed to upload data. Error: \(error)")
            return onFailure(false)
        })
}

private func createFile(name: String, folderId: String?, type: String, accessToken: String, onFileId: @escaping (String) -> Void, onFailure: @escaping (_ failedBecauseNotFound: Bool) -> Void) {
    let parentsParam = folderId != nil
        ? " parents: [\"\(folderId!)\"]," // swiftlint:disable:this force_unwrapping
        : ""

    post(
        url: "https://www.googleapis.com/drive/v3/files",
        accessToken: accessToken,
        // swiftlint:disable indentation_width
        jsonBody:
        """
        {
          name: \"\(name)\",
          \(parentsParam)
          mimeType: \"application/vnd.google-apps.\(type)\"
        }
        """,
        // swiftlint:enable indentation_width
        onSuccessfulResponse: { response in
            guard let fileId = response["id"] as? String else {
                print("Could not parse id in response: \(response)")
                return onFailure(false)
            }
            onFileId(fileId)
        },
        onUnsuccessfulResponse: { statusCode, response in
            print("Failed to create file. Status code: \(statusCode). Response: \(response)")
            return onFailure(isStatusCodeNotFound(statusCode))
        },
        onError: { error in
            print("Failed to create file. Error: \(error)")
            return onFailure(false)
        })
}

private func isStatusCodeNotFound(_ statusCode: Int) -> Bool {
    statusCode == 404
}
