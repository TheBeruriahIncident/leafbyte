//
//  SerializationUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/19/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

let header = [ "Date", "Time", "Sample Number", "Leaf Area (cm2)", "Eaten Area (cm2)", "Percent Eaten" ]
let csvHeader = stringRowToCsvRow(header)

func serialize(settings: Settings, image: UIImage, percentEaten: String, leafAreaInCm2: String?, eatenAreaInCm2: String?) {
    serializeMeasurement(settings: settings, percentEaten: percentEaten, leafAreaInCm2: leafAreaInCm2, eatenAreaInCm2: eatenAreaInCm2)
    // TODO: this is a truly awful hack around the race condition of these different promises resolving. once done prototyping, FIX
    sleep(2)
    serializeImage(settings: settings, image: image)
    
    settings.nextSampleNumber += 1
    settings.serialize()
}

private func serializeMeasurement(settings: Settings, percentEaten: String, leafAreaInCm2: String?, eatenAreaInCm2: String?) {
    if settings.measurementSaveLocation == .none {
        return
    }
    
    // Get date and time in a way amenable to sorting.
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    let formattedDate = formatter.string(from: date)
    formatter.dateFormat = "HH:mm:ss"
    let formattedTime = formatter.string(from: date)
    
    // Form a row useful for any spreadsheet-like format.
    let row = [ formattedDate, formattedTime, String(settings.nextSampleNumber), leafAreaInCm2 ?? "", eatenAreaInCm2 ?? "", percentEaten ]
    
    switch settings.measurementSaveLocation {
    case .local:
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent("\(settings.datasetName).csv")
        // If the file doesn't exist, create with the header.
        initializeFileIfNonexistant(url, withData: csvHeader)
        
        // Add the data to the file.
        let csvRow = stringRowToCsvRow(row)
        appendToFile(url, data: csvRow)
        
    case .googleDrive:
        GoogleSignInManager.initiateSignIn(actionWithAccessToken: {accessToken in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, actionWithFolderId: { folderId in
                getGoogleSpreadsheetId(settings: settings, folderId: folderId, accessToken: accessToken, actionWithSpreadsheetId: { spreadsheetId in
                    appendToSheet(spreadsheetId: spreadsheetId, row: row, accessToken: accessToken)
                })
            })
        })

    default:
        break
    }
}

private func serializeImage(settings: Settings, image: UIImage) {
    if settings.imageSaveLocation == .none {
        return
    }
    
    let filename = "\(settings.datasetName)-\(settings.nextSampleNumber).png"
    let pngImage = UIImagePNGRepresentation(image)!
    
    switch settings.imageSaveLocation {
    case .local:
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent(filename)
        try! pngImage.write(to: url)
        
    case .googleDrive:
        GoogleSignInManager.initiateSignIn(actionWithAccessToken: {accessToken in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, actionWithFolderId: { folderId in
                uploadData(name: filename, data: pngImage, folderId: folderId, accessToken: accessToken)
            })
        })
    
    default:
        break
    }
}

private func stringRowToCsvRow(_ row: [String]) -> Data {
    return (row.joined(separator: ",") + "\n").data(using: String.Encoding.utf8)!
}

private func getTopLevelGoogleFolderId(settings: Settings, accessToken: String, actionWithFolderId: @escaping (String) -> Void) {
    if settings.topLevelGoogleFolderId != nil {
        actionWithFolderId(settings.topLevelGoogleFolderId!)
    } else {
        createFolder(name: "LeafByte", accessToken: accessToken, actionWithFolderId: { folderId in
            settings.topLevelGoogleFolderId = folderId
            settings.serialize()
            
            actionWithFolderId(folderId)
        })
    }
}

private func getDatasetGoogleFolderId(settings: Settings, accessToken: String, actionWithFolderId: @escaping (String) -> Void) {
    let existingFolderId = settings.datasetNameToGoogleFolderId[settings.datasetName]
    if existingFolderId != nil {
        actionWithFolderId(existingFolderId!)
    } else {
        getTopLevelGoogleFolderId(settings: settings, accessToken: accessToken, actionWithFolderId: { topLevelFolderId in
            createFolder(name: settings.datasetName, folderId: topLevelFolderId, accessToken: accessToken, actionWithFolderId: { datasetFolderId in
                settings.datasetNameToGoogleFolderId[settings.datasetName] = datasetFolderId
                settings.serialize()
                
                actionWithFolderId(datasetFolderId)
            })
        })
    }
}

private func getGoogleSpreadsheetId(settings: Settings, folderId: String, accessToken: String, actionWithSpreadsheetId: @escaping (String) -> Void) {
    let existingSpreadsheetId = settings.datasetNameToGoogleSpreadsheetId[settings.datasetName]
    if existingSpreadsheetId != nil {
        actionWithSpreadsheetId(existingSpreadsheetId!)
    } else {
        createSheet(name: settings.datasetName, folderId: folderId, accessToken: accessToken, actionWithSpreadsheetId: { spreadsheetId in
            appendToSheet(spreadsheetId: spreadsheetId, row: header, accessToken: accessToken, andThen: {
                settings.datasetNameToGoogleSpreadsheetId[settings.datasetName] = spreadsheetId
                settings.serialize()
                
                actionWithSpreadsheetId(spreadsheetId)
            })
        })
    }
}