//
//  LeafByteTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 12/20/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

@testable import LeafByte
import XCTest

// swiftlint:disable force_unwrapping
final class LeafByteTests: XCTestCase {
    func testThresholdingFilter() {
        let image = uiToCgImage(loadImage(named: "leafWithScale"))!

        // This is set within measure.
        // swiftlint:disable:next implicitly_unwrapped_optional
        var thresholdedImage: CIImage!
        self.measure {
            let filter = ThresholdingFilter()
            filter.setInputImage(image: image, useBlackBackground: false)
            thresholdedImage = filter.outputImage
        }

        let indexableImage = IndexableImage(ciToCgImage(thresholdedImage)!)

        XCTAssert(indexableImage.getPixel(x: 5, y: 5).isInvisible())
        XCTAssert(indexableImage.getPixel(x: 1_400, y: 1_400).isVisible())
        XCTAssert(indexableImage.getPixel(x: 1_820, y: 1_690).isVisible())
        XCTAssert(indexableImage.getPixel(x: 1_660, y: 1_820).isInvisible())
        XCTAssert(indexableImage.getPixel(x: 1_740, y: 1_820).isVisible())
    }

    func testSuggestedThreshold() {
        let uiImage = loadImage(named: "leafWithScale")
        let cgImage = uiToCgImage(uiImage)!

        // This is set within measure.
        // swiftlint:disable:next implicitly_unwrapped_optional
        var suggestedThreshold: Float!
        self.measure {
            suggestedThreshold = otsusMethod(histogram: getLumaHistogram(image: cgImage))
        }

        XCTAssertEqual(139, roundToInt(suggestedThreshold * 255))
    }

    func testConnectedComponents() {
        let originalImage = resizeImage(loadImage(named: "leafWithScale"))!

        let filter = ThresholdingFilter()
        filter.setInputImage(image: originalImage, useBlackBackground: false)
        let thresholdedImage = filter.outputImage!

        let indexableImage = IndexableImage(ciToCgImage(thresholdedImage)!)
        let image = LayeredIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage)

        // This is set within measure.
        // swiftlint:disable:next implicitly_unwrapped_optional
        var connectedComponentsInfo: ConnectedComponentsInfo!
        self.measure {
            connectedComponentsInfo = labelConnectedComponents(image: image)
        }

        let whiteAreaSizes = connectedComponentsInfo.labelToSize.filter { $0.key < 0 }.map(\.value.standardPart).sorted()
        let nonWhiteAreaSizes = connectedComponentsInfo.labelToSize.filter { $0.key > 0 }.map(\.value.standardPart).sorted()

        XCTAssertEqual([3_360, 970_005], whiteAreaSizes.suffix(2))
        XCTAssertEqual([1_176, 105_398], nonWhiteAreaSizes.suffix(2))
    }

    func testSettingsSerialization() {
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

        XCTAssertEqual(settings, deserializedSettings)
    }

    func testDeserializeMissingSettings() {
        let url = NSURL.fileURL(withPath: (NSTemporaryDirectory() as NSString).appendingPathComponent("no-settings-here"), isDirectory: true)
        let deserializedSettings = Settings.deserialize(from: url)

        XCTAssertEqual(Settings(), deserializedSettings)
    }

    private func loadImage(named name: String) -> UIImage {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: name, ofType: "jpg") else {
            fatalError("Image \(name) not found")
        }
        guard let image = UIImage(contentsOfFile: path) else {
            fatalError("Image \(name) could not be loaded")
        }
        return image
    }
}
// swiftlint:enable force_unwrapping
