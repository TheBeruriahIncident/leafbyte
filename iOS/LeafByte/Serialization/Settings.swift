//
//  Settings.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/18/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AppAuth
import Foundation

// This represents state for the settings. Implementing NSCoding allows this to be serialized and deserialized so that settings last across sessions.
final class Settings: NSObject, NSCoding {
    static let defaultDatasetName = "Herbivory Data"
    static let defaultNextSampleNumber = 1
    static let defaultSaveLocation = SaveLocation.local
    static let defaultScaleMarkLength = 10.0
    static let defaultUnit = "cm"

    enum SaveLocation: String {
        // We redundantly define the string for these enums to ensure that the serialization format is stable, regardless of any future refactors/renames
        // swiftlint:disable redundant_string_enum_value
        case none = "none" // swiftlint:disable:this discouraged_none_name
        case local = "local"
        case googleDrive = "googleDrive"
        // swiftlint:enable redundant_string_enum_value
    }

    private enum PropertyKey {
        // Keeping this string for back-compat.
        static let dataSaveLocation = "measurementSaveLocation"
        static let datasetName = "datasetName"
        static let datasetNameToEpochTimeOfLastUse = "datasetNameToEpochTimeOfLastUse"
        static let datasetNameToNextSampleNumber = "datasetNameToNextSampleNumber"
        static let datasetNameToUnit = "datasetNameToUnit"
        static let datasetNameToUnitInFirstLocalFile = "datasetNameToUnitInFirstLocalFile"
        static let datasetNameToUserIdToGoogleFolderId = "datasetNameToUserIdToGoogleFolderId"
        static let datasetNameToUnitToUserIdToGoogleSpreadsheetId = "datasetNameToUnitToUserIdToGoogleSpreadsheetId"
        static let googleAuthState = "googleAuthState"
        static let imageSaveLocation = "imageSaveLocation"
        static let saveGpsData = "saveGpsData"
        static let scaleMarkLength = "scaleMarkLength"
        static let useBarcode = "useBarcode"
        static let useBlackBackground = "useBlackBackground"
        static let userIdToTopLevelGoogleFolderId = "userIdToTopLevelGoogleFolderId"
    }

    var dataSaveLocation = defaultSaveLocation
    var datasetName = Settings.defaultDatasetName
    // These data structures on disk do theoretically grow without bound, but you could use a hundred different datasets every day for a summer and only use ~200 KBs, so it's a truly pathological case where this matters.
    var datasetNameToEpochTimeOfLastUse = [String: Int]()
    var datasetNameToNextSampleNumber = [defaultDatasetName: defaultNextSampleNumber]
    var datasetNameToUnit = [String: String]()
    // We have a separate file for each unit for a given dataset so that the header is accurate. On Google Drive, these files can all have the same filename, but locally you need unique names. So, the first filename will be just the dataset, while subsequent filenames will have the unit suffixed. To achieve that, we need to track the unit of the first file (the one without a suffix).
    var datasetNameToUnitInFirstLocalFile = [String: String]()
    var datasetNameToUserIdToGoogleFolderId = [String: [String: String]]()
    var datasetNameToUnitToUserIdToGoogleSpreadsheetId = [String: [String: [String: String]]]()
    var googleAuthState: OIDAuthState?
    var imageSaveLocation = defaultSaveLocation
    var saveGpsData = false
    var scaleMarkLength = defaultScaleMarkLength
    var useBarcode = false
    var useBlackBackground = false
    var userIdToTopLevelGoogleFolderId = [String: String]()

    // This empty block is required for overriding
    // swiftlint:disable:next no_empty_block
    override required init() {}

    // MARK: - NSCoding

    // This defines how to deserialize (how to load a saved Settings from disk).
    required init(coder decoder: NSCoder) {
        if let dataSaveLocation = decoder.decodeObject(forKey: PropertyKey.dataSaveLocation) as? String {
            self.dataSaveLocation = SaveLocation(rawValue: dataSaveLocation) ?? Self.defaultSaveLocation
        }
        if let datasetName = decoder.decodeObject(forKey: PropertyKey.datasetName) as? String {
            self.datasetName = datasetName
        }
        if let datasetNameToEpochTimeOfLastUse = decoder.decodeObject(forKey: PropertyKey.datasetNameToEpochTimeOfLastUse) as? [String: Int] {
            self.datasetNameToEpochTimeOfLastUse = datasetNameToEpochTimeOfLastUse
        }
        if let datasetNameToNextSampleNumber = decoder.decodeObject(forKey: PropertyKey.datasetNameToNextSampleNumber) as? [String: Int] {
            self.datasetNameToNextSampleNumber = datasetNameToNextSampleNumber
        }
        if let datasetNameToUnit = decoder.decodeObject(forKey: PropertyKey.datasetNameToUnit) as? [String: String] {
            self.datasetNameToUnit = datasetNameToUnit
        }
        if let datasetNameToUnitInFirstLocalFile = decoder.decodeObject(forKey: PropertyKey.datasetNameToUnitInFirstLocalFile) as? [String: String] {
            self.datasetNameToUnitInFirstLocalFile = datasetNameToUnitInFirstLocalFile
        }
        if let datasetNameToUserIdToGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.datasetNameToUserIdToGoogleFolderId) as? [String: [String: String]] {
            self.datasetNameToUserIdToGoogleFolderId = datasetNameToUserIdToGoogleFolderId
        }
        if let datasetNameToUnitToUserIdToGoogleSpreadsheetId = decoder.decodeObject(forKey: PropertyKey.datasetNameToUnitToUserIdToGoogleSpreadsheetId) as? [String: [String: [String: String]]] {
            self.datasetNameToUnitToUserIdToGoogleSpreadsheetId = datasetNameToUnitToUserIdToGoogleSpreadsheetId
        }
        if decoder.containsValue(forKey: PropertyKey.googleAuthState) {
            // If AppAuth ever changes the format and this decode fails, it should just decode to nil and eventually trigger a new login
            self.googleAuthState = decoder.decodeObject(forKey: PropertyKey.googleAuthState) as? OIDAuthState
        }
        if let imageSaveLocation = decoder.decodeObject(forKey: PropertyKey.imageSaveLocation) as? String {
            self.imageSaveLocation = SaveLocation(rawValue: imageSaveLocation) ?? Self.defaultSaveLocation
        }
        if decoder.containsValue(forKey: PropertyKey.saveGpsData) {
            self.saveGpsData = decoder.decodeBool(forKey: PropertyKey.saveGpsData)
        }
        if decoder.containsValue(forKey: PropertyKey.scaleMarkLength) {
            self.scaleMarkLength = decoder.decodeDouble(forKey: PropertyKey.scaleMarkLength)
        }
        if decoder.containsValue(forKey: PropertyKey.useBarcode) {
            self.useBarcode = decoder.decodeBool(forKey: PropertyKey.useBarcode)
        }
        if decoder.containsValue(forKey: PropertyKey.useBlackBackground) {
            self.useBlackBackground = decoder.decodeBool(forKey: PropertyKey.useBlackBackground)
        }
        if let userIdToTopLevelGoogleFolderId = decoder.decodeObject(forKey: PropertyKey.userIdToTopLevelGoogleFolderId) as? [String: String] {
            self.userIdToTopLevelGoogleFolderId = userIdToTopLevelGoogleFolderId
        }
    }

    // This defines how to serialize (how to save a Settings to disk).
    func encode(with coder: NSCoder) {
        coder.encode(dataSaveLocation.rawValue, forKey: PropertyKey.dataSaveLocation)
        coder.encode(datasetName, forKey: PropertyKey.datasetName)
        coder.encode(datasetNameToEpochTimeOfLastUse, forKey: PropertyKey.datasetNameToEpochTimeOfLastUse)
        coder.encode(datasetNameToNextSampleNumber, forKey: PropertyKey.datasetNameToNextSampleNumber)
        coder.encode(datasetNameToUnit, forKey: PropertyKey.datasetNameToUnit)
        coder.encode(datasetNameToUnitInFirstLocalFile, forKey: PropertyKey.datasetNameToUnitInFirstLocalFile)
        coder.encode(datasetNameToUserIdToGoogleFolderId, forKey: PropertyKey.datasetNameToUserIdToGoogleFolderId)
        coder.encode(datasetNameToUnitToUserIdToGoogleSpreadsheetId, forKey: PropertyKey.datasetNameToUnitToUserIdToGoogleSpreadsheetId)
        coder.encode(googleAuthState, forKey: PropertyKey.googleAuthState)
        coder.encode(imageSaveLocation.rawValue, forKey: PropertyKey.imageSaveLocation)
        coder.encode(saveGpsData, forKey: PropertyKey.saveGpsData)
        coder.encode(scaleMarkLength, forKey: PropertyKey.scaleMarkLength)
        coder.encode(useBarcode, forKey: PropertyKey.useBarcode)
        coder.encode(useBlackBackground, forKey: PropertyKey.useBlackBackground)
        coder.encode(userIdToTopLevelGoogleFolderId, forKey: PropertyKey.userIdToTopLevelGoogleFolderId)
    }

    // MARK: - NSObject

    override func isEqual(_ other: Any?) -> Bool {
        guard let other = other as? Self else {
            return false
        }

        return dataSaveLocation == other.dataSaveLocation
            && datasetName == other.datasetName
            && datasetNameToEpochTimeOfLastUse == other.datasetNameToEpochTimeOfLastUse
            && datasetNameToNextSampleNumber == other.datasetNameToNextSampleNumber
            && datasetNameToUnit == other.datasetNameToUnit
            && datasetNameToUnitInFirstLocalFile == other.datasetNameToUnitInFirstLocalFile
            && NSDictionary(dictionary: datasetNameToUserIdToGoogleFolderId).isEqual(to: other.datasetNameToUserIdToGoogleFolderId)
            && NSDictionary(dictionary: datasetNameToUnitToUserIdToGoogleSpreadsheetId).isEqual(to: other.datasetNameToUnitToUserIdToGoogleSpreadsheetId)
            && imageSaveLocation == other.imageSaveLocation
            && saveGpsData == other.saveGpsData
            && scaleMarkLength == other.scaleMarkLength
            && useBarcode == other.useBarcode
            && useBlackBackground == other.useBlackBackground
            && userIdToTopLevelGoogleFolderId == other.userIdToTopLevelGoogleFolderId
    }

    // MARK: - Helpers

    func serialize(at serializedLocation: URL = getUrlForInvisibleFiles(), self viewController: UIViewController? = nil) {
        do {
            try FileManager().createDirectory(at: serializedLocation, withIntermediateDirectories: true)
            let settingsFile = Self.getSettingsFile(fromContainingFolder: serializedLocation)

            // If this crashes, we may not even be able to catch it as it isn't marked throwing
            NSKeyedArchiver.archiveRootObject(self, toFile: settingsFile.path)
        } catch {
            print("Failed to serialize settings: \(error)")

            guard let viewController else {
                // Just returning isn't great, but it's not clear what more we can do short of crashing the app
                return
            }
            presentAlert(self: viewController, title: "Failed to save settings", message: "Is there space on your phone? Please reach out to leafbyte@zoegp.science with information about your device so we can fix this issue.")
        }
    }

    func getGoogleFolderId(userId: String) -> String? {
        datasetNameToUserIdToGoogleFolderId[datasetName]?[userId]
    }

    func getGoogleSpreadsheetId(userId: String) -> String? {
        datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName]?[getUnit()]?[userId]
    }

    func getTopLevelGoogleFolderId(userId: String) -> String? {
        userIdToTopLevelGoogleFolderId[userId]
    }

    func getUnit() -> String {
        datasetNameToUnit[datasetName] ?? Self.defaultUnit
    }

    func getLocalFilename() -> String {
        if datasetNameToUnitInFirstLocalFile[datasetName] == nil || datasetNameToUnitInFirstLocalFile[datasetName] == getUnit() {
            datasetNameToUnitInFirstLocalFile[datasetName] = getUnit()
            return datasetName
        }

        return datasetName + " [" + getUnit() + "]"
    }

    func getNextSampleNumber() -> Int {
        datasetNameToNextSampleNumber[datasetName]! // swiftlint:disable:this force_unwrapping
    }

    func noteDatasetUsed() {
        datasetNameToEpochTimeOfLastUse[datasetName] = Int(Date().timeIntervalSince1970)
    }

    func getPreviousDatasetNames() -> [String] {
        // Order the previously used datasets by most recently used, then put the current dataset name first on the list.
        var previousDatasets = datasetNameToEpochTimeOfLastUse.sorted { $0.1 > $1.1 }.map(\.key).filter { $0 != datasetName }
        previousDatasets.insert(datasetName, at: 0)
        return previousDatasets
    }

    func incrementNextSampleNumber() {
        datasetNameToNextSampleNumber[datasetName]! += 1  // swiftlint:disable:this force_unwrapping
    }

    func initializeNextSampleNumberIfNeeded() -> Int {
        let nextSampleNumber = datasetNameToNextSampleNumber[datasetName]
        if nextSampleNumber == nil {
            datasetNameToNextSampleNumber[datasetName] = Self.defaultNextSampleNumber
        }

        return datasetNameToNextSampleNumber[datasetName]!  // swiftlint:disable:this force_unwrapping
    }

    func setGoogleFolderId(userId: String, googleFolderId: String?) {
        if datasetNameToUserIdToGoogleFolderId[datasetName] == nil {
            datasetNameToUserIdToGoogleFolderId[datasetName] = [String: String]()
        }

        // swiftlint:disable:next force_unwrapping
        datasetNameToUserIdToGoogleFolderId[datasetName]![userId] = googleFolderId
    }

    func setGoogleSpreadsheetId(userId: String, googleSpreadsheetId: String?) {
        if datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName] == nil {
            datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName] = [String: [String: String]]()
        }

        // swiftlint:disable:next force_unwrapping
        if datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName]![getUnit()] == nil {
            // swiftlint:disable:next force_unwrapping
            datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName]![getUnit()] = [String: String]()
        }

        // swiftlint:disable:next force_unwrapping
        datasetNameToUnitToUserIdToGoogleSpreadsheetId[datasetName]![getUnit()]![userId] = googleSpreadsheetId
    }

    func setTopLevelGoogleFolderId(userId: String, topLevelGoogleFolderId: String?) {
        userIdToTopLevelGoogleFolderId[userId] = topLevelGoogleFolderId
    }

    static func deserialize(from serializedLocation: URL = getUrlForInvisibleFiles()) -> Settings {
        let deserializedData = NSKeyedUnarchiver.unarchiveObject(withFile: getSettingsFile(fromContainingFolder: serializedLocation).path) as? Self

        guard let deserializedData else {
            return Self()
        }

        return deserializedData
    }

    private static func getSettingsFile(fromContainingFolder folder: URL) -> URL {
        folder.appendingPathComponent("settings")
    }
}
