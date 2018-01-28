//
//  Settings.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/18/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation

// This represents state for the settings. Implementing NSCoding allows this to be serialized and deserialized so that settings last across sessions.
class Settings: NSObject, NSCoding {
    static let defaultDatasetName = "Herbivory Measurement"
    static let defaultNextSampleNumber = 1
    static let defaultScaleMarkLength = 10.0
    
    enum SaveLocation: String {
        case none = "none"
        case local = "local"
        case googleDrive = "googleDrive"
    }
    
    struct PropertyKey {
        static let datasetName = "datasetName"
        static let datasetNameToGoogleFolderId = "datasetNameToGoogleFolderId"
        static let datasetNameToGoogleSheetId = "datasetNameToGoogleSheetId"
        static let datasetNameToNextSampleNumber = "datasetNameToNextSampleNumber"
        static let imageSaveLocation = "imageSaveLocation"
        static let measurementSaveLocation = "measurementSaveLocation"
        static let saveGpsData = "saveGpsData"
        static let scaleMarkLength = "scaleMarkLength"
        static let topLevelGoogleFolderId = "topLevelGoogleFolderId"
    }
    
    var datasetName = Settings.defaultDatasetName
    // These data structures on disk do theoretically grow without bound, but you could use a hundred different datasets every day for a summer and only use ~200 KBs, so it's a truly pathological case where this matters.
    var datasetNameToGoogleFolderId = [String: String]()
    var datasetNameToGoogleSpreadsheetId = [String: String]()
    var datasetNameToNextSampleNumber = [defaultDatasetName: defaultNextSampleNumber]
    var imageSaveLocation = SaveLocation.none
    var measurementSaveLocation = SaveLocation.none
    var saveGpsData = false
    var scaleMarkLength = defaultScaleMarkLength
    var topLevelGoogleFolderId: String?
    
    required override init() {}
    
    // MARK: - NSCoding
    
    // This defines how to deserialize (how to load a saved Settings from disk).
    required init(coder decoder: NSCoder) {
        if let datasetName = decoder.decodeObject(forKey: PropertyKey.datasetName) as? String {
            self.datasetName = datasetName
        }
        if let datasetNameToGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.datasetNameToGoogleFolderId) as? [String: String] {
            self.datasetNameToGoogleFolderId = datasetNameToGoogleFolderId
        }
        if let datasetNameToGoogleSheetId = decoder.decodeObject(forKey: PropertyKey.datasetNameToGoogleSheetId) as? [String: String] {
            self.datasetNameToGoogleSpreadsheetId = datasetNameToGoogleSheetId
        }
        if let datasetNameToNextSampleNumber = decoder.decodeObject(forKey: PropertyKey.datasetNameToNextSampleNumber) as? [String: Int] {
            self.datasetNameToNextSampleNumber = datasetNameToNextSampleNumber
        }
        if let imageSaveLocation = decoder.decodeObject(forKey: PropertyKey.imageSaveLocation) as? String {
            self.imageSaveLocation = SaveLocation(rawValue: imageSaveLocation)!
        }
        if let measurementSaveLocation = decoder.decodeObject(forKey: PropertyKey.measurementSaveLocation) as? String {
            self.measurementSaveLocation = SaveLocation(rawValue: measurementSaveLocation)!
        }
        if decoder.containsValue(forKey: PropertyKey.saveGpsData) {
            self.saveGpsData = decoder.decodeBool(forKey: PropertyKey.saveGpsData)
        }
        if decoder.containsValue(forKey: PropertyKey.scaleMarkLength) {
            self.scaleMarkLength = decoder.decodeDouble(forKey: PropertyKey.scaleMarkLength)
        }
        if let topLevelGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.topLevelGoogleFolderId) as? String {
            self.topLevelGoogleFolderId = topLevelGoogleFolderId
        }
    }
    
    // This defines how to serialize (how to save a Settings to disk).
    func encode(with coder: NSCoder) {
        coder.encode(datasetName, forKey: PropertyKey.datasetName)
        coder.encode(datasetNameToGoogleFolderId, forKey: PropertyKey.datasetNameToGoogleFolderId)
        coder.encode(datasetNameToGoogleSpreadsheetId, forKey: PropertyKey.datasetNameToGoogleSheetId)
        coder.encode(datasetNameToNextSampleNumber, forKey: PropertyKey.datasetNameToNextSampleNumber)
        coder.encode(imageSaveLocation.rawValue, forKey: PropertyKey.imageSaveLocation)
        coder.encode(measurementSaveLocation.rawValue, forKey: PropertyKey.measurementSaveLocation)
        coder.encode(saveGpsData, forKey: PropertyKey.saveGpsData)
        coder.encode(scaleMarkLength, forKey: PropertyKey.scaleMarkLength)
        coder.encode(topLevelGoogleFolderId, forKey: PropertyKey.topLevelGoogleFolderId)
    }
    
    // MARK: - NSObject
    
    override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Settings else {
            return false
        }
        
        return datasetName == other.datasetName
            && datasetNameToGoogleFolderId == other.datasetNameToGoogleFolderId
            && datasetNameToGoogleSpreadsheetId == other.datasetNameToGoogleSpreadsheetId
            && datasetNameToNextSampleNumber == other.datasetNameToNextSampleNumber
            && imageSaveLocation == other.imageSaveLocation
            && measurementSaveLocation == other.measurementSaveLocation
            && saveGpsData == other.saveGpsData
            && scaleMarkLength == other.scaleMarkLength
            && topLevelGoogleFolderId == other.topLevelGoogleFolderId
    }
    
    // MARK: - Helpers
    
    func serialize(at serializedLocation: URL = getUrlForInvisibleFiles()) {
        try! FileManager().createDirectory(at: serializedLocation, withIntermediateDirectories: true)
        NSKeyedArchiver.archiveRootObject(self, toFile: Settings.getSettingsFile(fromContainingFolder: serializedLocation))
    }
    
    func getGoogleFolderId() -> String {
        return datasetNameToGoogleFolderId[datasetName]!
    }
    
    func getGoogleSpreadsheetId() -> String {
        return datasetNameToGoogleSpreadsheetId[datasetName]!
    }
    
    func getNextSampleNumber() -> Int {
        return datasetNameToNextSampleNumber[datasetName]!
    }
    
    func incrementNextSampleNumber() {
        return datasetNameToNextSampleNumber[datasetName]! += 1
    }
    
    func initializeNextSampleNumberIfNeeded() -> Int {
        let nextSampleNumber = datasetNameToNextSampleNumber[datasetName]
        if nextSampleNumber == nil {
            datasetNameToNextSampleNumber[datasetName] = Settings.defaultNextSampleNumber
        }
        
        return datasetNameToNextSampleNumber[datasetName]!
    }
    
    func setGoogleFolderId(_ googleFolderId: String) {
        return datasetNameToGoogleFolderId[datasetName] = googleFolderId
    }
    
    func setGoogleSpreadsheetId(_ googleSpreadsheetId: String) {
        return datasetNameToGoogleSpreadsheetId[datasetName] = googleSpreadsheetId
    }
    
    static func deserialize(from serializedLocation: URL = getUrlForInvisibleFiles()) -> Settings {
        let deserializedData = NSKeyedUnarchiver.unarchiveObject(withFile: getSettingsFile(fromContainingFolder: serializedLocation)) as? Settings
        if deserializedData == nil {
            return Settings()
        }
        
        return deserializedData!
    }
    
    private static func getSettingsFile(fromContainingFolder folder: URL) -> String {
        return folder.appendingPathComponent("settings").path
    }
}
