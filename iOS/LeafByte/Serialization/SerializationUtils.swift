//
//  SerializationUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/19/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

enum SerializationFailureCause {
    case googleDrive
    case gps
}

// This is the top-level serialize function.
func serialize(settings: Settings, image: UIImage, percentConsumed: String, leafAreaInUnits2: String?, consumedAreaInUnits2: String?, barcode: String?, notes: String, callingViewController: UIViewController, onSuccess: @escaping () -> Void, onFailure: @escaping (SerializationFailureCause) -> Void) {
    // Get date and time in a way amenable to sorting.
    let date = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    let formattedDate = formatter.string(from: date)
    formatter.dateFormat = "HH:mm:ss"
    let formattedTime = formatter.string(from: date)
    
    let onLocation = { (location: CLLocation?) in
        serializeData(settings: settings, percentConsumed: percentConsumed, leafAreaInUnits2: leafAreaInUnits2, consumedAreaInUnits2: consumedAreaInUnits2, date: formattedDate, time: formattedTime, location: location, barcode: barcode, notes: notes, callingViewController: callingViewController, onSuccess: {
            serializeImage(settings: settings, image: image, date: formattedDate, time: formattedTime, callingViewController: callingViewController, onSuccess: {
                settings.incrementNextSampleNumber()
                settings.noteDatasetUsed()
                settings.serialize()
                
                onSuccess()
            }, onFailure: onFailure)
        }, onFailure: onFailure)
    }
    
    if settings.saveGpsData && settings.dataSaveLocation != .none {
        GpsManager.requestLocation(onLocation: onLocation, onError: { _ in onFailure(.gps) })
    } else {
        onLocation(nil)
    }
}

// This serializes just the data.
private func serializeData(settings: Settings, percentConsumed: String, leafAreaInUnits2: String?, consumedAreaInUnits2: String?, date: String, time: String, location: CLLocation?, barcode: String?, notes: String, callingViewController: UIViewController, onSuccess: @escaping () -> Void, onFailure: @escaping (SerializationFailureCause) -> Void) {
    if settings.dataSaveLocation == .none {
        onSuccess()
        return
    }
    
    let latitude = location != nil ? formatDouble(withFiveDecimalPoints: location!.coordinate.latitude) : ""
    let longitude = location != nil ? formatDouble(withFiveDecimalPoints: location!.coordinate.longitude) : ""
    
    // Form a row useful for any spreadsheet-like format.
    let row = [ date, time, latitude, longitude, barcode ?? "", String(settings.getNextSampleNumber()), leafAreaInUnits2 ?? "", consumedAreaInUnits2 ?? "", percentConsumed, notes, String(format: "%.3f", settings.scaleMarkLength) ]
    
    switch settings.dataSaveLocation {
    case .local:
        let localFilename = settings.getLocalFilename()
        settings.serialize()
        
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent("\(localFilename).csv")
        // If the file doesn't exist, create with the header.
        initializeFileIfNonexistant(url, withData: getCsvHeader(settings: settings))
        
        // Add the data to the file.
        let csvRow = stringRowToCsvRow(row)
        appendToFile(url, data: csvRow)
        
        onSuccess()
        
    case .googleDrive:
        initiateGoogleSignIn(onAccessTokenAndUserId: { accessToken, userId in
            appendDataToGoogleDrive(settings: settings, row: row, accessToken: accessToken, userId: userId, onSuccess: onSuccess, onFailure: { onFailure(.googleDrive) })
        }, onError: { _, _ in onFailure(.googleDrive) }, callingViewController: callingViewController, settings: settings)

    default:
        fatalError("\(settings.dataSaveLocation) not handled in switch")
    }
}

private func appendDataToGoogleDrive(settings: Settings, row: [String], accessToken: String, userId: String, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void, alreadyFailedOnce: Bool = false) {
    getGoogleSpreadsheetId(settings: settings, accessToken: accessToken, userId: userId, onSpreadsheetId: { spreadsheetId in
        appendToSheet(spreadsheetId: spreadsheetId, row: row, accessToken: accessToken, onSuccess: onSuccess, onFailure: { (failedBecauseNotFound: Bool) in
            if !failedBecauseNotFound || alreadyFailedOnce {
                onFailure()
                return
            }
            
            // Handle the case where data couldn't be appended because the sheet was deleted.
            settings.setGoogleSpreadsheetId(userId: userId, googleSpreadsheetId: nil)
            settings.serialize()
            
            // Recursive, but set the alreadyFailedOnce flag, so that we can only recurse once.
            appendDataToGoogleDrive(settings: settings, row: row, accessToken: accessToken, userId: userId, onSuccess: onSuccess, onFailure: onFailure, alreadyFailedOnce: true)
        })
    }, onFailure: onFailure)
}

// This serializes just the image.
private func serializeImage(settings: Settings, image: UIImage, date: String, time: String, callingViewController: UIViewController, onSuccess: @escaping () -> Void, onFailure: @escaping (SerializationFailureCause) -> Void) {
    if settings.imageSaveLocation == .none {
        onSuccess()
        return
    }
    
    let filename = "\(settings.datasetName)-\(settings.getNextSampleNumber()) (\(date) \(time)).png"
    let pngImage = image.pngData()!
    
    switch settings.imageSaveLocation {
    case .local:
        let url = getUrlForVisibleFolder(named: settings.datasetName).appendingPathComponent(filename)
        try! pngImage.write(to: url)
        
        onSuccess()
        
    case .googleDrive:
        initiateGoogleSignIn(onAccessTokenAndUserId: { accessToken, userId in
            uploadDataToGoogleDrive(settings: settings, filename: filename, accessToken: accessToken, userId: userId, pngImage: pngImage, onSuccess: onSuccess, onFailure: { onFailure(.googleDrive) })
        }, onError: { _, _ in onFailure(.googleDrive) }, callingViewController: callingViewController, settings: settings)
    
    default:
        fatalError("\(settings.imageSaveLocation) not handled in switch")
    }
}

private func uploadDataToGoogleDrive(settings: Settings, filename: String, accessToken: String, userId: String, pngImage: Data, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void, alreadyFailedOnce: Bool = false) {
    getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { folderId in
        uploadData(name: filename, data: pngImage, folderId: folderId, accessToken: accessToken, onSuccess: onSuccess, onFailure:
            { (failedBecauseNotFound: Bool) in
                if !failedBecauseNotFound || alreadyFailedOnce {
                    onFailure()
                    return
                }
                
                // Handle the case where data couldn't be uploaded because the dataset folder was deleted.
                settings.setGoogleFolderId(userId: userId, googleFolderId: nil)
                settings.serialize()
                
                // Recursive, but set the alreadyFailedOnce flag, so that we can only recurse once.
                uploadDataToGoogleDrive(settings: settings, filename: filename, accessToken: accessToken, userId: userId, pngImage: pngImage, onSuccess: onSuccess, onFailure: onFailure, alreadyFailedOnce: true)
            })
    }, onFailure: onFailure)
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
        }, onFailure: { _ in onFailure() })
    }
}

// Get the folder id for the current dataset. It'll hold both the sheet and the images.
private func getDatasetGoogleFolderId(settings: Settings, accessToken: String, userId: String, onFolderId: @escaping (String) -> Void, onFailure: @escaping () -> Void, alreadyFailedOnce: Bool = false) {
    if let googleFolderId = settings.getGoogleFolderId(userId: userId) {
        onFolderId(googleFolderId)
    } else {
        getTopLevelGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { topLevelFolderId in
            createFolder(name: settings.datasetName, folderId: topLevelFolderId, accessToken: accessToken, onFolderId: { datasetFolderId in
                settings.setGoogleFolderId(userId: userId, googleFolderId: datasetFolderId)
                settings.serialize()
                
                onFolderId(datasetFolderId)
            }, onFailure: { (failedBecauseNotFound: Bool) in
                if !failedBecauseNotFound || alreadyFailedOnce {
                    onFailure()
                    return
                }
                
                // Handle the case where a dataset folder couldn't be created because the top level folder was deleted.
                settings.setTopLevelGoogleFolderId(userId: userId, topLevelGoogleFolderId: nil)
                settings.serialize()
                
                // Recursive, but set the alreadyFailedOnce flag, so that we can only recurse once.
                getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: onFolderId, onFailure: onFailure, alreadyFailedOnce: true)
            })
        }, onFailure: onFailure)
    }
}

// Get the spreadsheet id for sheet for the the current dataset.
private func getGoogleSpreadsheetId(settings: Settings, accessToken: String, userId: String, onSpreadsheetId: @escaping (String) -> Void, onFailure: @escaping () -> Void, alreadyFailedOnce: Bool = false) {
    if let googleSpreadsheetId = settings.getGoogleSpreadsheetId(userId: userId) {
        onSpreadsheetId(googleSpreadsheetId)
    } else {
        getDatasetGoogleFolderId(settings: settings, accessToken: accessToken, userId: userId, onFolderId: { folderId in
            createSheet(name: settings.datasetName, folderId: folderId, accessToken: accessToken, onSpreadsheetId: { spreadsheetId in
                appendToSheet(spreadsheetId: spreadsheetId, row: getHeader(settings: settings), accessToken: accessToken, onSuccess: {
                    freezeHeader(spreadsheetId: spreadsheetId, accessToken: accessToken, onSuccess: {
                        settings.setGoogleSpreadsheetId(userId: userId, googleSpreadsheetId: spreadsheetId)
                        settings.serialize()
                        
                        onSpreadsheetId(spreadsheetId)
                    }, onFailure: { _ in onFailure() })
                }, onFailure: { _ in onFailure() })
            }, onFailure: { (failedBecauseNotFound: Bool) in
                if !failedBecauseNotFound || alreadyFailedOnce {
                    onFailure()
                    return
                }
                
                // Handle the case where a sheet couldn't be created because the dataset folder was deleted.
                settings.setGoogleFolderId(userId: userId, googleFolderId: nil)
                settings.serialize()
                
                // Recursive, but set the alreadyFailedOnce flag, so that we can only recurse once.
                getGoogleSpreadsheetId(settings: settings, accessToken: accessToken, userId: userId, onSpreadsheetId: onSpreadsheetId, onFailure: onFailure, alreadyFailedOnce: true)
            })
        }, onFailure: onFailure)
    }
}

private func getHeader(settings: Settings) -> [String] {
    return [ "Date (year.month.day)", "Time", "Latitude (degrees)", "Longitude (degrees)", "Barcode", "Sample Number", "Total Leaf Area (" + settings.getUnit() + "2)", "Consumed Leaf Area (" + settings.getUnit() + "2)", "Percent Consumed", "Notes", "Scale Length (" + settings.getUnit() + ")"]
}
private func getCsvHeader(settings: Settings) -> Data {
    return stringRowToCsvRow(getHeader(settings: settings))
}

private func formatDouble(withFiveDecimalPoints double: Double) -> String {
    return String(format: "%.5f", double)
}
