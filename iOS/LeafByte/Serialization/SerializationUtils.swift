//
//  SerializationUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/19/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

let header = [ "Date", "Time", "Sample Number", "Total Leaf Area (cm2)", "Consumed Leaf Area (cm2)", "Percent Consumed" ]
let csvHeader = stringRowToCsvRow(header)

func serialize(settings: Settings, image: UIImage, percentConsumed: String, leafAreaInCm2: String?, consumedAreaInCm2: String?, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    // Get date and time in a way amenable to sorting.
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    let formattedDate = formatter.string(from: date)
    formatter.dateFormat = "HH:mm:ss"
    let formattedTime = formatter.string(from: date)
    
    serializeMeasurement(settings: settings, percentConsumed: percentConsumed, leafAreaInCm2: leafAreaInCm2, consumedAreaInCm2: consumedAreaInCm2, date: formattedDate, time: formattedTime, onSuccess: {
        serializeImage(settings: settings, image: image, date: formattedDate, time: formattedTime, onSuccess: {
            settings.incrementNextSampleNumber()
            settings.serialize()
            
            onSuccess()
        }, onFailure: onFailure)
    }, onFailure: onFailure)
}

private func serializeMeasurement(settings: Settings, percentConsumed: String, leafAreaInCm2: String?, consumedAreaInCm2: String?, date: String, time: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    if settings.measurementSaveLocation == .none {
        onSuccess()
        return
    }
    
    // Form a row useful for any spreadsheet-like format.
    let row = [ date, time, String(settings.getNextSampleNumber()), leafAreaInCm2 ?? "", consumedAreaInCm2 ?? "", percentConsumed ]
    
    switch settings.measurementSaveLocation {
    case .local:
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent("\(settings.datasetName).csv")
        // If the file doesn't exist, create with the header.
        initializeFileIfNonexistant(url, withData: csvHeader)
        
        // Add the data to the file.
        let csvRow = stringRowToCsvRow(row)
        appendToFile(url, data: csvRow)
        onSuccess()
        
    case .googleDrive:
        GoogleSignInManager.initiateSignIn(onAccessTokenAndUserId: { accessToken, _ in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, onFolderId: { folderId in
                getGoogleSpreadsheetId(settings: settings, folderId: folderId, accessToken: accessToken, onSpreadsheetId: { spreadsheetId in
                    appendToSheet(spreadsheetId: spreadsheetId, row: row, accessToken: accessToken, onSuccess: onSuccess, onFailure: onFailure)
                }, onFailure: onFailure)
            }, onFailure: onFailure)
        }, onError: { _ in () })

    default:
        break
    }
}

private func serializeImage(settings: Settings, image: UIImage, date: String, time: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    if settings.imageSaveLocation == .none {
        onSuccess()
        return
    }
    
    let filename = "\(settings.datasetName)-\(settings.getNextSampleNumber()) (\(date) \(time)).png"
    let pngImage = UIImagePNGRepresentation(image)!
    
    switch settings.imageSaveLocation {
    case .local:
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent(filename)
        try! pngImage.write(to: url)
        onSuccess()
        
    case .googleDrive:
        GoogleSignInManager.initiateSignIn(onAccessTokenAndUserId: { accessToken, _ in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, onFolderId: { folderId in
                uploadData(name: filename, data: pngImage, folderId: folderId, accessToken: accessToken, onSuccess: onSuccess, onFailure: onFailure)
            }, onFailure: onFailure)
        }, onError: { _ in onFailure() })
    
    default:
        break
    }
}

private func stringRowToCsvRow(_ row: [String]) -> Data {
    return (row.joined(separator: ",") + "\n").data(using: String.Encoding.utf8)!
}

private func getTopLevelGoogleFolderId(settings: Settings, accessToken: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    if settings.topLevelGoogleFolderId != nil {
        onFolderId(settings.topLevelGoogleFolderId!)
    } else {
        createFolder(name: "LeafByte", accessToken: accessToken, onFolderId: { folderId in
            settings.topLevelGoogleFolderId = folderId
            settings.serialize()
            
            onFolderId(folderId)
        }, onFailure: onFailure)
    }
}

private func getDatasetGoogleFolderId(settings: Settings, accessToken: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    let existingFolderId = settings.datasetNameToGoogleFolderId[settings.datasetName]
    if existingFolderId != nil {
        onFolderId(existingFolderId!)
    } else {
        getTopLevelGoogleFolderId(settings: settings, accessToken: accessToken, onFolderId: { topLevelFolderId in
            createFolder(name: settings.datasetName, folderId: topLevelFolderId, accessToken: accessToken, onFolderId: { datasetFolderId in
                settings.datasetNameToGoogleFolderId[settings.datasetName] = datasetFolderId
                settings.serialize()
                
                onFolderId(datasetFolderId)
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
}

private func getGoogleSpreadsheetId(settings: Settings, folderId: String, accessToken: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    let existingSpreadsheetId = settings.datasetNameToGoogleSpreadsheetId[settings.datasetName]
    if existingSpreadsheetId != nil {
        onSpreadsheetId(existingSpreadsheetId!)
    } else {
        createSheet(name: settings.datasetName, folderId: folderId, accessToken: accessToken, onSpreadsheetId: { spreadsheetId in
            appendToSheet(spreadsheetId: spreadsheetId, row: header, accessToken: accessToken, onSuccess: {
                settings.datasetNameToGoogleSpreadsheetId[settings.datasetName] = spreadsheetId
                settings.serialize()
                
                onSpreadsheetId(spreadsheetId)
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
}
