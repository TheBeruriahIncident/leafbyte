//
//  LeafByteTests.swift
//  LeafByteTests
//
//  Created by Abigail Getman-Pickering on 8/29/24.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

@testable import LeafByte
import XCTest

// This class uses images from the original LeafByte paper as fixture testing.
// swiftlint:disable force_unwrapping
final class PaperDataTests: XCTestCase {
    private let scaleMarkLengthCm: Double = 17

    func testPaperData() {
        testIndividualFile(filename: "TM2", expectedTotalArea: 60.03, expectedConsumedArea: 0.001)
    }

    private func testIndividualFile(filename: String, expectedTotalArea: Double, expectedConsumedArea: Double) {
        let originalImage = resizeImage(loadImage(named: filename))!

        let suggestedThreshold = otsusMethod(histogram: getLumaHistogram(image: originalImage))
        let filter = ThresholdingFilter()
        filter.threshold = suggestedThreshold
        filter.setInputImage(image: originalImage, useBlackBackground: false)
        let thresholdedImage = filter.outputImage!

        let indexableThresholdedImage = IndexableImage(ciToCgImage(thresholdedImage)!)
        let layeredThresholdedImage = LayeredIndexableImage(width: indexableThresholdedImage.width, height: indexableThresholdedImage.height)
        layeredThresholdedImage.addImage(indexableThresholdedImage)

        let originalConnectedComponentsInfo = labelConnectedComponents(image: layeredThresholdedImage)
        let occupiedLabelsAndSizes: [Int: Size] = originalConnectedComponentsInfo.labelToSize.filter { $0.0 > 0 }
        // Note that these test images all fail to identify the scale, so we use a size heuristic to find the scale
        let scaleMarks = Array(occupiedLabelsAndSizes).filter { $0.1.standardPart > 300 && $0.1.standardPart < 500 }.map {labelAndSize in
            let memberPoint = originalConnectedComponentsInfo.labelToMemberPoint[labelAndSize.key]!

            let scaleMark = getCentroidOfComponent(inImage: indexableThresholdedImage, fromPoint: CGPoint(x: memberPoint.0, y: memberPoint.1), minimumComponentSize: 1)

            XCTAssertNotNil(scaleMark, "No scale mark found for member point \(memberPoint)")
            return scaleMark!
        }
        XCTAssertEqual(scaleMarks.count, 4)

        let correctedImage = ScaleIdentificationViewController.getFixedImage(cgImage: ciToCgImage(thresholdedImage)!, ciImage: thresholdedImage, scaleMarks: scaleMarks)!
        let indexableCorrectedImage = IndexableImage(correctedImage)
        let layeredCorrectedImage = LayeredIndexableImage(width: indexableCorrectedImage.width, height: indexableCorrectedImage.height)
        layeredCorrectedImage.addImage(indexableCorrectedImage)

        let correctedConnectedComponentsInfo = labelConnectedComponents(image: layeredCorrectedImage)
        // swiftlint:disable:next no_empty_block
        let results = ResultsViewController.useConnectedComponentsResults(connectedComponentsInfo: correctedConnectedComponentsInfo, image: layeredThresholdedImage, setNoLeafFound: {}, setPointOnLeaf: { _ in }, drawMarkers: {}, floodFill: { _, _ in }, finishWithDrawingManager: {})!

        let scaleMarkPixelLength = (correctedImage.width + correctedImage.height) / 2
        let totalArea = ResultsViewController.convertPixelsToUnits2(pixels: results.leafAreaIncludingConsumedAreaInPixels, scaleMarkPixelLength: scaleMarkPixelLength, scaleMarkLength: scaleMarkLengthCm)
        let consumedArea = ResultsViewController.convertPixelsToUnits2(pixels: results.consumedAreaInPixels, scaleMarkPixelLength: scaleMarkPixelLength, scaleMarkLength: scaleMarkLengthCm)
        XCTAssertEqual(totalArea, expectedTotalArea, accuracy: tolerance)
        XCTAssertEqual(consumedArea, expectedConsumedArea, accuracy: tolerance)
    }

    // Note that there's a slight tolerance given. There are several possible sources of imprecision:
    // - We've observed that image decompression can give slightly varying pixels, not only with lossy formats like JPEG, but even lossless formats like PNG. This varies not only across devices with the same function call, but across function calls within the same device (e.g. loading an image within a test vs in a PHPicker vs in a UIImagePicker)
    // - This has not been observed, but I wouldn't be surprised if some floating point math could vary across devices, whether because of different precision levels on different CPUs or different orderings of operations
    // - We've observed that the iOS-provided skew correction can vary across devices, although we have only observed a pixel or two different in the resulting image
    // The specific reason why these values are just a bit different from the values in the paper is because of variations in image decompression between the runtime image loading vs the image loading in tests. We can go back and forth between the two and see that specific pixels are different (and neither load exactly the same pixel values as when you open the image itself in an editor). However, if you run the non-test codepath, the values are nearly identical to those in the paper.
    private let tolerance = 0.01
}
// swiftlint:enable force_unwrapping
