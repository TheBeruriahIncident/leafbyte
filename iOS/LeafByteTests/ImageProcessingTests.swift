//
//  ImageProcessingTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 12/20/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

@testable import LeafByte
import Testing

struct ImageProcessingTests {
    @Test
    func testThresholdingFilter() throws {
        let image = try #require(uiToCgImage(loadImage(named: "leafWithScale")))

        let filter = ThresholdingFilter()
        filter.setInputImage(image: image, useBlackBackground: false)
        let thresholdedImage = try #require(filter.outputImage)
        let indexableImage = IndexableImage(try #require(ciToCgImage(thresholdedImage)))

        #expect(indexableImage.getPixel(x: 5, y: 5).isInvisible())
        #expect(indexableImage.getPixel(x: 1_400, y: 1_400).isVisible())
        #expect(indexableImage.getPixel(x: 1_820, y: 1_690).isVisible())
        #expect(indexableImage.getPixel(x: 1_653, y: 1_833).isInvisible())
        #expect(indexableImage.getPixel(x: 1_740, y: 1_820).isVisible())
    }

    @Test
    func testSuggestedThreshold() throws {
        let uiImage = loadImage(named: "leafWithScale")
        let cgImage = try #require(uiToCgImage(uiImage))

        let suggestedThreshold = otsusMethod(histogram: getLumaHistogram(image: cgImage))
        #expect(139 == roundToInt(suggestedThreshold * 255))
    }

    @Test
    func testConnectedComponents() throws {
        let originalImage = try #require(resizeImage(loadImage(named: "leafWithScale")))

        let filter = ThresholdingFilter()
        filter.setInputImage(image: originalImage, useBlackBackground: false)
        let thresholdedImage = try #require(filter.outputImage)

        let indexableImage = IndexableImage(try #require(ciToCgImage(thresholdedImage)))
        let image = LayeredIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage)

        let connectedComponentsInfo = labelConnectedComponents(image: image)
        let whiteAreaSizes = connectedComponentsInfo.labelToSize.filter { $0.key < 0 }.map(\.value.standardPart).sorted()
        let nonWhiteAreaSizes = connectedComponentsInfo.labelToSize.filter { $0.key > 0 }.map(\.value.standardPart).sorted()

        #expect([3_358, 970_002] == whiteAreaSizes.suffix(2))
        #expect([1_178, 105_400] == nonWhiteAreaSizes.suffix(2))
    }
}
