//
//  LeafByteTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 12/20/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

@testable import LeafByte
import Foundation
import Testing
import XCTest

struct SettingsTests {
    @Test func testSerializationRoundTrip() {
        let settings = Settings()
        settings.datasetName = "The Tale of Genji"
        settings.datasetNameToEpochTimeOfLastUse = ["Le Morte a'Arthur": 1_485, "The Tale of Genji": 1_021]
        settings.datasetNameToNextSampleNumber = ["Le Morte a'Arthur": 10, "The Tale of Genji": 45]
        settings.datasetNameToUnit = ["Le Morte a'Arthur": "cm", "The Tale of Genji": "in"]
        settings.datasetNameToUnitInFirstLocalFile = ["The Tale of Genji": "in"]
        settings.datasetNameToUnitToUserIdToGoogleSpreadsheetId =
            // swiftlint:disable indentation_width
            ["Le Morte a'Arthur":
                ["cm":
                    ["abigailgp": "a"]],
             "The Tale of Genji":
                ["cm":
                    ["zoegp": "b",
                     "abigailgp": "c"],
                 "in":
                    ["abigailgp": "d"]]]
        // swiftlint:enable indentation_width
        settings.imageSaveLocation = .googleDrive
        settings.dataSaveLocation = .googleDrive
        settings.saveGpsData = true
        settings.scaleMarkLength = 32
        settings.useBarcode = true
        settings.useBlackBackground = true
        settings.userIdToTopLevelGoogleFolderId = ["abigailgp": "d", "zoegp": "e"]

        let url = NSURL.fileURL(withPath: NSTemporaryDirectory(), isDirectory: true)
        settings.serialize(at: url)
        let deserializedSettings = Settings.deserialize(from: url)

        #expect(settings == deserializedSettings)
    }

    @Test() func testDeserializingMissingSettings() {
        let url = NSURL.fileURL(withPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("no-settings-here"), isDirectory: true)
        let deserializedSettings = Settings.deserialize(from: url)

        #expect(Settings() == deserializedSettings)
    }
}
