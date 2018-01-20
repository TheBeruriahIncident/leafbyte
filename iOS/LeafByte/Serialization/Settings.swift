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
    enum SaveLocation: String {
        case none = "none"
        case local = "local"
        case googleDrive = "googleDrive"
    }
    
    struct PropertyKey {
        static let measurementSaveLocation = "measurementSaveLocation"
        static let imageSaveLocation = "imageSaveLocation"
        static let seriesName = "seriesName"
        static let saveGpsData = "saveGpsData"
    }
    
    var measurementSaveLocation = SaveLocation.none
    var imageSaveLocation = SaveLocation.none
    var seriesName = "Leaf measurements"
    var saveGpsData = false
    
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
        if let seriesName = decoder.decodeObject(forKey: PropertyKey.seriesName) as? String {
            self.seriesName = seriesName
        }
        if decoder.containsValue(forKey: PropertyKey.saveGpsData) {
            self.saveGpsData = decoder.decodeBool(forKey: PropertyKey.saveGpsData)
        }
    }
    
    // This defines how to serialize (how to save a Settings to disk).
    func encode(with coder: NSCoder) {
        coder.encode(measurementSaveLocation.rawValue, forKey: PropertyKey.measurementSaveLocation)
        coder.encode(imageSaveLocation.rawValue, forKey: PropertyKey.imageSaveLocation)
        coder.encode(seriesName, forKey: PropertyKey.seriesName)
        coder.encode(saveGpsData, forKey: PropertyKey.saveGpsData)
    }
    
    // MARK: - NSObject
    
    override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Settings else {
            return false
        }
        
        return measurementSaveLocation == other.measurementSaveLocation
            && imageSaveLocation == other.imageSaveLocation
            && seriesName == other.seriesName
            && saveGpsData == other.saveGpsData
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
