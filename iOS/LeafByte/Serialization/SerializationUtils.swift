//
//  SerializationUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/19/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

let header = [ "Date", "Time", "Latitude (degrees)", "Longitude (degrees)", "Sample Number", "Total Leaf Area (cm2)", "Consumed Leaf Area (cm2)", "Percent Consumed", "Notes" ]
let csvHeader = stringRowToCsvRow(header)

// This is the top-level serialize function.
func serialize(settings: Settings, image: UIImage, percentConsumed: String, leafAreaInCm2: String?, consumedAreaInCm2: String?, notes: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    // Get date and time in a way amenable to sorting.
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    let formattedDate = formatter.string(from: date)
    formatter.dateFormat = "HH:mm:ss"
    let formattedTime = formatter.string(from: date)
    
    let onLocation = { (location: CLLocation?) in
        serializeMeasurement(settings: settings, percentConsumed: percentConsumed, leafAreaInCm2: leafAreaInCm2, consumedAreaInCm2: consumedAreaInCm2, date: formattedDate, time: formattedTime, location: location, notes: notes, onSuccess: {
            serializeImage(settings: settings, image: image, date: formattedDate, time: formattedTime, onSuccess: {
                settings.incrementNextSampleNumber()
                settings.serialize()
                
                onSuccess()
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
    
    if settings.saveGpsData {
        GpsManager.requestLocation(onLocation: onLocation, onError: { _ in onLocation(nil)})
    } else {
        onLocation(nil)
    }
}

// This serializes just the measurement.
private func serializeMeasurement(settings: Settings, percentConsumed: String, leafAreaInCm2: String?, consumedAreaInCm2: String?, date: String, time: String, location: CLLocation?, notes: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void) {
    if settings.measurementSaveLocation == .none {
        onSuccess()
        return
    }
    
    let latitude = location != nil ? formatDouble(withFiveDecimalPoints: location!.coordinate.latitude) : ""
    let longitude = location != nil ? formatDouble(withFiveDecimalPoints: location!.coordinate.longitude) : ""
    
    // Form a row useful for any spreadsheet-like format.
    let row = [ date, time, latitude, longitude, String(settings.getNextSampleNumber()), leafAreaInCm2 ?? "", consumedAreaInCm2 ?? "", percentConsumed, notes ]
    
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
        GoogleSignInManager.initiateSignIn(onAccessTokenAndUserId: { accessToken, userId in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { folderId in
                getGoogleSpreadsheetId(settings: settings, folderId: folderId, accessToken: accessToken, userId: userId, onSpreadsheetId: { spreadsheetId in
                    appendToSheet(spreadsheetId: spreadsheetId, row: row, accessToken: accessToken, onSuccess: onSuccess, onFailure: onFailure)
                }, onFailure: onFailure)
            }, onFailure: onFailure)
        }, onError: { _ in () })

    default:
        fatalError("\(settings.measurementSaveLocation) not handled in switch")
    }
}

// This serializes just the image.
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
        GoogleSignInManager.initiateSignIn(onAccessTokenAndUserId: { accessToken, userId in
            getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { folderId in
                uploadData(name: filename, data: pngImage, folderId: folderId, accessToken: accessToken, onSuccess: onSuccess, onFailure: onFailure)
            }, onFailure: onFailure)
        }, onError: { _ in onFailure() })
    
    default:
        fatalError("\(settings.imageSaveLocation) not handled in switch")
    }
}

private func stringRowToCsvRow(_ row: [String]) -> Data {
    return (row.joined(separator: ",") + "\n").data(using: String.Encoding.utf8)!
}

// Get the folder id for the top-level LeafByte folder containing all datasets.
private func getTopLevelGoogleFolderId(settings: Settings, accessToken: String, userId: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    if let topLevelGoogleFolderId = settings.getTopLevelGoogleFolderId(userId: userId) {
        onFolderId(topLevelGoogleFolderId)
    } else {
        createFolder(name: "LeafByte", accessToken: accessToken, onFolderId: { folderId in
            settings.setTopLevelGoogleFolderId(userId: userId, topLevelGoogleFolderId: folderId)
            settings.serialize()
            
            onFolderId(folderId)
        }, onFailure: onFailure)
    }
}

// Get the folder id for the current dataset. It'll hold both the sheet and the images.
private func getDatasetGoogleFolderId(settings: Settings, accessToken: String, userId: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    if let googleFolderId = settings.getGoogleFolderId(userId: userId) {
        onFolderId(googleFolderId)
    } else {
        getTopLevelGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { topLevelFolderId in
            createFolder(name: settings.datasetName, folderId: topLevelFolderId, accessToken: accessToken, onFolderId: { datasetFolderId in
                settings.setGoogleFolderId(userId: userId, googleFolderId: datasetFolderId)
                settings.serialize()
                
                onFolderId(datasetFolderId)
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
}

// Get the spreadsheet id for sheet for the the current dataset.
private func getGoogleSpreadsheetId(settings: Settings, folderId: String, accessToken: String, userId: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping () -> Void) {
    if let googleSpreadsheetId = settings.getGoogleSpreadsheetId(userId: userId) {
        onSpreadsheetId(googleSpreadsheetId)
    } else {
        createSheet(name: settings.datasetName, folderId: folderId, accessToken: accessToken, onSpreadsheetId: { spreadsheetId in
            appendToSheet(spreadsheetId: spreadsheetId, row: header, accessToken: accessToken, onSuccess: {
                settings.setGoogleSpreadsheetId(userId: userId, googleSpreadsheetId: spreadsheetId)
                settings.serialize()
                
                onSpreadsheetId(spreadsheetId)
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
}

private func formatDouble(withFiveDecimalPoints double: Double) -> String {
    return String(format: "%.5f", double)
}
