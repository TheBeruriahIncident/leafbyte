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
        static let datasetNameToNextSampleNumber = "datasetNameToNextSampleNumber"
        static let datasetNameToUserIdToGoogleFolderId = "datasetNameToUserIdToGoogleFolderId"
        static let datasetNameToUserIdToGoogleSpreadsheetId = "datasetNameToUserIdToGoogleSpreadsheetId"
        static let imageSaveLocation = "imageSaveLocation"
        static let measurementSaveLocation = "measurementSaveLocation"
        static let saveGpsData = "saveGpsData"
        static let scaleMarkLength = "scaleMarkLength"
        static let userIdToTopLevelGoogleFolderId = "userIdToTopLevelGoogleFolderId"
    }
    
    var datasetName = Settings.defaultDatasetName
    // These data structures on disk do theoretically grow without bound, but you could use a hundred different datasets every day for a summer and only use ~200 KBs, so it's a truly pathological case where this matters.
    var datasetNameToNextSampleNumber = [defaultDatasetName: defaultNextSampleNumber]
    var datasetNameToUserIdToGoogleFolderId = [String: [String: String]]()
    var datasetNameToUserIdToGoogleSpreadsheetId = [String: [String: String]]()
    var imageSaveLocation = SaveLocation.none
    var measurementSaveLocation = SaveLocation.none
    var saveGpsData = false
    var scaleMarkLength = defaultScaleMarkLength
    var userIdToTopLevelGoogleFolderId = [String: String]()
    
    required override init() {}
    
    // MARK: - NSCoding
    
    // This defines how to deserialize (how to load a saved Settings from disk).
    required init(coder decoder: NSCoder) {
        if let datasetName = decoder.decodeObject(forKey: PropertyKey.datasetName) as? String {
            self.datasetName = datasetName
        }
        if let datasetNameToNextSampleNumber = decoder.decodeObject(forKey: PropertyKey.datasetNameToNextSampleNumber) as? [String: Int] {
            self.datasetNameToNextSampleNumber = datasetNameToNextSampleNumber
        }
        if let datasetNameToUserIdToGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.datasetNameToUserIdToGoogleFolderId) as? [String: [String: String]] {
            self.datasetNameToUserIdToGoogleFolderId = datasetNameToUserIdToGoogleFolderId
        }
        if let datasetNameToUserIdToGoogleSpreadsheetId = decoder.decodeObject(forKey: PropertyKey.datasetNameToUserIdToGoogleSpreadsheetId) as? [String: [String: String]] {
            self.datasetNameToUserIdToGoogleSpreadsheetId = datasetNameToUserIdToGoogleSpreadsheetId
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
        if let userIdToTopLevelGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.userIdToTopLevelGoogleFolderId) as? [String: String] {
            self.userIdToTopLevelGoogleFolderId = userIdToTopLevelGoogleFolderId
        }
    }
    
    // This defines how to serialize (how to save a Settings to disk).
    func encode(with coder: NSCoder) {
        coder.encode(datasetName, forKey: PropertyKey.datasetName)
        coder.encode(datasetNameToNextSampleNumber, forKey: PropertyKey.datasetNameToNextSampleNumber)
        coder.encode(datasetNameToUserIdToGoogleFolderId, forKey: PropertyKey.datasetNameToUserIdToGoogleFolderId)
        coder.encode(datasetNameToUserIdToGoogleSpreadsheetId, forKey: PropertyKey.datasetNameToUserIdToGoogleSpreadsheetId)
        coder.encode(imageSaveLocation.rawValue, forKey: PropertyKey.imageSaveLocation)
        coder.encode(measurementSaveLocation.rawValue, forKey: PropertyKey.measurementSaveLocation)
        coder.encode(saveGpsData, forKey: PropertyKey.saveGpsData)
        coder.encode(scaleMarkLength, forKey: PropertyKey.scaleMarkLength)
        coder.encode(userIdToTopLevelGoogleFolderId, forKey: PropertyKey.userIdToTopLevelGoogleFolderId)
    }
    
    // MARK: - NSObject
    
    override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Settings else {
            return false
        }
        
        return datasetName == other.datasetName
            && datasetNameToNextSampleNumber == other.datasetNameToNextSampleNumber
            && NSDictionary(dictionary: datasetNameToUserIdToGoogleFolderId).isEqual(to: other.datasetNameToUserIdToGoogleFolderId)
            && NSDictionary(dictionary: datasetNameToUserIdToGoogleSpreadsheetId).isEqual(to: other.datasetNameToUserIdToGoogleSpreadsheetId)
            && imageSaveLocation == other.imageSaveLocation
            && measurementSaveLocation == other.measurementSaveLocation
            && saveGpsData == other.saveGpsData
            && scaleMarkLength == other.scaleMarkLength
            && userIdToTopLevelGoogleFolderId == other.userIdToTopLevelGoogleFolderId
    }
    
    // MARK: - Helpers
    
    func serialize(at serializedLocation: URL = getUrlForInvisibleFiles()) {
        try! FileManager().createDirectory(at: serializedLocation, withIntermediateDirectories: true)
        NSKeyedArchiver.archiveRootObject(self, toFile: Settings.getSettingsFile(fromContainingFolder: serializedLocation))
    }
    
    func getGoogleFolderId(userId: String) -> String? {
        return datasetNameToUserIdToGoogleFolderId[datasetName]?[userId]
    }
    
    func getGoogleSpreadsheetId(userId: String) -> String? {
        return datasetNameToUserIdToGoogleSpreadsheetId[datasetName]?[userId]
    }
    
    func getTopLevelGoogleFolderId(userId: String) -> String? {
        return userIdToTopLevelGoogleFolderId[userId]
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
    
    func setGoogleFolderId(userId: String, googleFolderId: String?) {
        if datasetNameToUserIdToGoogleFolderId[datasetName] == nil {
            datasetNameToUserIdToGoogleFolderId[datasetName] = [String: String]()
        }
        
        datasetNameToUserIdToGoogleFolderId[datasetName]![userId] = googleFolderId
    }
    
    func setGoogleSpreadsheetId(userId: String, googleSpreadsheetId: String?) {
        if datasetNameToUserIdToGoogleSpreadsheetId[datasetName] == nil {
            datasetNameToUserIdToGoogleSpreadsheetId[datasetName] = [String: String]()
        }
        
        datasetNameToUserIdToGoogleSpreadsheetId[datasetName]![userId] = googleSpreadsheetId
    }
    
    func setTopLevelGoogleFolderId(userId: String, topLevelGoogleFolderId: String?) {
        userIdToTopLevelGoogleFolderId[userId] = topLevelGoogleFolderId
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
