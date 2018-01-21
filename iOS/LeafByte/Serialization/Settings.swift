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
    
    enum SaveLocation: String {
        case none = "none"
        case local = "local"
        case googleDrive = "googleDrive"
    }
    
    struct PropertyKey {
        static let measurementSaveLocation = "measurementSaveLocation"
        static let imageSaveLocation = "imageSaveLocation"
        static let datasetName = "datasetName"
        static let nextSampleNumber = "nextSampleNumber"
        static let saveGpsData = "saveGpsData"
        static let datasetNameToGoogleFolderId = "datasetNameToGoogleFolderId"
        static let datasetNameToGoogleSheetId = "datasetNameToGoogleSheetId"
        static let topLevelGoogleFolderId = "topLevelGoogleFolderId"
    }
    
    var measurementSaveLocation = SaveLocation.none
    var imageSaveLocation = SaveLocation.none
    var datasetName = Settings.defaultDatasetName
    var nextSampleNumber = defaultNextSampleNumber
    var saveGpsData = false
    // TODO: handle these getting too large
    var datasetNameToGoogleFolderId = [String: String]()
    var datasetNameToGoogleSpreadsheetId = [String: String]()
    var topLevelGoogleFolderId: String?
    
    required override init() {}
    
    // MARK: - NSCoding
    
    // This defines how to deserialize (how to load a saved Settings from disk).
    required init(coder decoder: NSCoder) {
        if let measurementSaveLocation = decoder.decodeObject(forKey: PropertyKey.measurementSaveLocation) as? String {
            self.measurementSaveLocation = SaveLocation(rawValue: measurementSaveLocation)!
        }
        if let imageSaveLocation = decoder.decodeObject(forKey: PropertyKey.imageSaveLocation) as? String {
            self.imageSaveLocation = SaveLocation(rawValue: imageSaveLocation)!
        }
        if let datasetName = decoder.decodeObject(forKey: PropertyKey.datasetName) as? String {
            self.datasetName = datasetName
        }
        if decoder.containsValue(forKey: PropertyKey.nextSampleNumber) {
            self.nextSampleNumber = decoder.decodeInteger(forKey: PropertyKey.nextSampleNumber)
        }
        if decoder.containsValue(forKey: PropertyKey.saveGpsData) {
            self.saveGpsData = decoder.decodeBool(forKey: PropertyKey.saveGpsData)
        }
        if let datasetNameToGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.datasetNameToGoogleFolderId) as? [String: String] {
            self.datasetNameToGoogleFolderId = datasetNameToGoogleFolderId
        }
        if let datasetNameToGoogleSheetId = decoder.decodeObject(forKey: PropertyKey.datasetNameToGoogleSheetId) as? [String: String] {
            self.datasetNameToGoogleSpreadsheetId = datasetNameToGoogleSheetId
        }
        if let topLevelGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.topLevelGoogleFolderId) as? String {
            self.topLevelGoogleFolderId = topLevelGoogleFolderId
        }
    }
    
    // This defines how to serialize (how to save a Settings to disk).
    func encode(with coder: NSCoder) {
        coder.encode(measurementSaveLocation.rawValue, forKey: PropertyKey.measurementSaveLocation)
        coder.encode(imageSaveLocation.rawValue, forKey: PropertyKey.imageSaveLocation)
        coder.encode(datasetName, forKey: PropertyKey.datasetName)
        coder.encode(nextSampleNumber, forKey: PropertyKey.nextSampleNumber)
        coder.encode(saveGpsData, forKey: PropertyKey.saveGpsData)
        coder.encode(datasetNameToGoogleFolderId, forKey: PropertyKey.datasetNameToGoogleFolderId)
        coder.encode(datasetNameToGoogleSpreadsheetId, forKey: PropertyKey.datasetNameToGoogleSheetId)
        coder.encode(topLevelGoogleFolderId, forKey: PropertyKey.topLevelGoogleFolderId)
    }
    
    // MARK: - NSObject
    
    override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Settings else {
            return false
        }
        
        return measurementSaveLocation == other.measurementSaveLocation
            && imageSaveLocation == other.imageSaveLocation
            && datasetName == other.datasetName
            && saveGpsData == other.saveGpsData
            && datasetNameToGoogleFolderId == other.datasetNameToGoogleFolderId
            && datasetNameToGoogleSpreadsheetId == other.datasetNameToGoogleSpreadsheetId
            && topLevelGoogleFolderId == other.topLevelGoogleFolderId
    }
    
    // MARK: - Helpers
    
    func serialize(at serializedLocation: URL = getUrlForInvisibleFiles()) {
        try! FileManager().createDirectory(at: serializedLocation, withIntermediateDirectories: true)
        NSKeyedArchiver.archiveRootObject(self, toFile: Settings.getSettingsFile(fromContainingFolder: serializedLocation))
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
