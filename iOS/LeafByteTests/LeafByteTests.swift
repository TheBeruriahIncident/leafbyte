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
        XCTAssert(indexableImage.getPixel(x: 1_653, y: 1_833).isInvisible())
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

        XCTAssertEqual([3_358, 970_002], whiteAreaSizes.suffix(2))
        XCTAssertEqual([1_178, 105_400], nonWhiteAreaSizes.suffix(2))
    }

}
// swiftlint:enable force_unwrapping
