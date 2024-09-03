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
        // swiftlint:disable:next todo
        // TODO: several files are commented out, because scale identification fails. we should fix that, or delete those lines and the associated images

        // testIndividualFile(filename: "AI2", expectedTotalArea: 22.565, expectedConsumedArea: 2.279)
        // testIndividualFile(filename: "CA1", expectedTotalArea: 9.791, expectedConsumedArea: 0.000)
        testIndividualFile(filename: "CO1", expectedTotalArea: 23.951, expectedConsumedArea: 0.992)
        testIndividualFile(filename: "CO2", expectedTotalArea: 25.231, expectedConsumedArea: 1.154)
        testIndividualFile(filename: "CO5", expectedTotalArea: 27.016, expectedConsumedArea: 1.176)
        testIndividualFile(filename: "GB1", expectedTotalArea: 28.366, expectedConsumedArea: 0.000)
        testIndividualFile(filename: "GB2", expectedTotalArea: 50.448, expectedConsumedArea: 4.731)
        testIndividualFile(filename: "GB4", expectedTotalArea: 14.953, expectedConsumedArea: 2.901)
        testIndividualFile(filename: "GB5", expectedTotalArea: 17.474, expectedConsumedArea: 3.126)
        testIndividualFile(filename: "GB6", expectedTotalArea: 22.048, expectedConsumedArea: 6.008)
        // testIndividualFile(filename: "IE1", expectedTotalArea: 7.570, expectedConsumedArea: 0.000)
        testIndividualFile(filename: "MP5", expectedTotalArea: 45.924, expectedConsumedArea: 1.889)
        testIndividualFile(filename: "OR2", expectedTotalArea: 52.046, expectedConsumedArea: 1.318)
        // testIndividualFile(filename: "PB2", expectedTotalArea: 53.341, expectedConsumedArea: 2.096)
        testIndividualFile(filename: "SH2", expectedTotalArea: 9.936, expectedConsumedArea: 0.424)
        testIndividualFile(filename: "SH4", expectedTotalArea: 5.733, expectedConsumedArea: 0.002)
        testIndividualFile(filename: "SH5", expectedTotalArea: 10.136, expectedConsumedArea: 0.354)
        // testIndividualFile(filename: "SP5", expectedTotalArea: 11.411, expectedConsumedArea: 0.967)
        // testIndividualFile(filename: "SS1", expectedTotalArea: 5.898, expectedConsumedArea: 0.538)
        // testIndividualFile(filename: "SS2", expectedTotalArea: 4.920, expectedConsumedArea: 0.208)
        testIndividualFile(filename: "SS3", expectedTotalArea: 4.853, expectedConsumedArea: 0.000)
        testIndividualFile(filename: "SS4", expectedTotalArea: 6.502, expectedConsumedArea: 0.815)
        testIndividualFile(filename: "TH3", expectedTotalArea: 25.632, expectedConsumedArea: 2.422)
        // testIndividualFile(filename: "TH4", expectedTotalArea: 39.763, expectedConsumedArea: 0.001)
        testIndividualFile(filename: "TH5", expectedTotalArea: 30.008, expectedConsumedArea: 1.560)
        testIndividualFile(filename: "TM1", expectedTotalArea: 41.100, expectedConsumedArea: 2.351)
        testIndividualFile(filename: "TM2", expectedTotalArea: 60.034, expectedConsumedArea: 0.002)
        testIndividualFile(filename: "TM4", expectedTotalArea: 53.855, expectedConsumedArea: 2.678)
        // testIndividualFile(filename: "TM5", expectedTotalArea: 42.391, expectedConsumedArea: 3.125)
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
        // Note that these test images often fail to identify the scale, so we use a size heuristic to find the scale
        let scaleMarks = Array(occupiedLabelsAndSizes).filter { $0.1.standardPart > 300 && $0.1.standardPart < 500 }.map {labelAndSize in
            let memberPoint = originalConnectedComponentsInfo.labelToMemberPoint[labelAndSize.key]!

            let scaleMark = getCentroidOfComponent(inImage: indexableThresholdedImage, fromPoint: CGPoint(x: memberPoint.0, y: memberPoint.1), minimumComponentSize: 1)

            XCTAssertNotNil(scaleMark, "No scale mark found for member point \(memberPoint)")
            return scaleMark!
        }
        XCTAssertEqual(scaleMarks.count, 4, "For file \(filename), scale marks not found")

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
        XCTAssertEqual(totalArea, expectedTotalArea, accuracy: tolerance, "For image \(filename), total area was \(totalArea), not \(expectedTotalArea)")
        XCTAssertEqual(consumedArea, expectedConsumedArea, accuracy: tolerance, "For image \(filename), consumed area was \(consumedArea), not \(expectedConsumedArea)")
    }

    // Note that there's a slight tolerance given. There are several possible sources of imprecision:
    // - We've observed that image decompression can give slightly varying pixels, not only with lossy formats like JPEG, but even lossless formats like PNG. This varies not only across devices with the same function call, but across function calls within the same device (e.g. loading an image within a test vs in a PHPicker vs in a UIImagePicker)
    // - This has not been observed, but I wouldn't be surprised if some floating point math could vary across devices, whether because of different precision levels on different CPUs or different orderings of operations
    // - We've observed that the iOS-provided skew correction can vary across devices, although we have only observed a pixel or two different in the resulting image
    // - The scale center calculation has gotten more precise by a pixel or so since the paper data
    // The specific reason why these values are just a bit different from the values in the paper is largely because of variations in image decompression between the runtime image loading vs the image loading in tests. We can go back and forth between the two and see that specific pixels are different (and neither load exactly the same pixel values as when you open the image itself in an editor). However, if you run the non-test codepath, the values are nearly identical to those in the paper.
    private let tolerance = 0.01
}
// swiftlint:enable force_unwrapping
