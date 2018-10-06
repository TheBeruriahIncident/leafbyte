//
//  LeafByteTests.swift
//  LeafByteTests
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import XCTest
@testable import LeafByte

final class LeafByteTests: XCTestCase {
    func testThresholdingFilter() {
        let image = uiToCgImage(loadImage(named: "leafWithScale"))
        
        var thresholdedImage: CIImage!
        self.measure {
            let filter = ThresholdingFilter()
            filter.setInputImage(image: image, useBlackBackground: false)
            thresholdedImage = filter.outputImage
        }
        
        let indexableImage = IndexableImage(ciToCgImage(thresholdedImage))
        
        XCTAssert(indexableImage.getPixel(x: 5, y: 5).isInvisible())
        XCTAssert(indexableImage.getPixel(x: 1400, y: 1400).isVisible())
        XCTAssert(indexableImage.getPixel(x: 1820, y: 1690).isVisible())
        XCTAssert(indexableImage.getPixel(x: 1660, y: 1820).isInvisible())
        XCTAssert(indexableImage.getPixel(x: 1740, y: 1820).isVisible())
    }
    
    func testSuggestedThreshold() {
        let uiImage = loadImage(named: "leafWithScale")
        let cgImage = uiToCgImage(uiImage)
        
        var suggestedThreshold: Float!
        self.measure {
            suggestedThreshold = otsusMethod(histogram: getLumaHistogram(image: cgImage))
        }
        
        XCTAssertEqual(139, roundToInt(suggestedThreshold * 255))
    }
    
    func testConnectedComponents() {
        let originalImage = resizeImage(loadImage(named: "leafWithScale"))
        
        let filter = ThresholdingFilter()
        filter.setInputImage(image: originalImage, useBlackBackground: false)
        let thresholdedImage = filter.outputImage!
        
        let indexableImage = IndexableImage(ciToCgImage(thresholdedImage))
        let image = LayeredIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage)

        var connectedComponentsInfo: ConnectedComponentsInfo!
        self.measure {
            connectedComponentsInfo = labelConnectedComponents(image: image)
        }
        
        let whiteAreaSizes = connectedComponentsInfo.labelToSize.filter({ $0.key < 0 }).map({ $0.value.standardPart }).sorted()
        let nonWhiteAreaSizes = connectedComponentsInfo.labelToSize.filter({ $0.key > 0 }).map({ $0.value.standardPart }).sorted()
        
        XCTAssertEqual([3362, 969958], whiteAreaSizes.suffix(2))
        XCTAssertEqual([1169, 105448], nonWhiteAreaSizes.suffix(2))
    }
    
    func testSettingsSerialization() {
        let settings = Settings()
        settings.measurementSaveLocation = .googleDrive
        settings.imageSaveLocation = .googleDrive
        settings.datasetName = "The Tale of Genji"
        settings.saveGpsData = true
        
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
