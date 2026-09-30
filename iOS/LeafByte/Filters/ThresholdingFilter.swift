//
//  ThresholdingFilter.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 12/30/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreImage
import UIKit

// This Core Image Filter ( https://developer.apple.com/documentation/coreimage/cifilter ) is used to remove the image background via thresholding ( https://en.wikipedia.org/wiki/Thresholding_(image_processing) ).
// Because Core Image saturates images to make them more vibrant by default, we use both a saturated form of the image and one in the original color space.
// This allows us to do the thresholding using the unmanipulated image but only show pixels from the more vibrant image.
final class ThresholdingFilter: CIFilter {
    var threshold: Float = 0.5

    // These are initialized in the entry point.
    // swiftlint:disable implicitly_unwrapped_optional
    private var inputImageOriginalColorSpace: CIImage!
    private var inputImageSaturated: CIImage!
    private var useBlackBackground: Bool!
    // swiftlint:enable implicitly_unwrapped_optional

    func setInputImage(image: CGImage, useBlackBackground: Bool) {
        // Explicitly prevent Core Image from changing the color space, in order to get predictable thresholding. https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html#//apple_ref/doc/uid/TP30001185-CH10-SW7
        inputImageOriginalColorSpace = CIImage(cgImage: image, options: [CIImageOption.colorSpace: NSNull()])
        inputImageSaturated = CIImage(cgImage: image)
        self.useBlackBackground = useBlackBackground
    }

    // MARK: CIFilter overrides

    // Should never be null, and handling this more gracefully is pretty messy
    // swiftlint:disable:next implicitly_unwrapped_optional
    override var outputImage: CIImage! {
        // These are initialized in the entry point.
        // swiftlint:disable:next force_unwrapping
        let arguments: [Any] = [inputImageOriginalColorSpace!, inputImageSaturated!, threshold]
        return getThresholdingKernel().apply(extent: inputImageOriginalColorSpace.extent, arguments: arguments)
    }

    private func getThresholdingKernel() -> CIColorKernel {
        useBlackBackground
            ? Self.blackBackgroundThresholdKernel
            : Self.whiteBackgroundThresholdKernel
    }

    // Static in order to (lazily) compute only once
    private static let whiteBackgroundThresholdKernel: CIColorKernel = {
        getMetalThresholdingKernel(useBlackBackground: false)
    }()

    // Static in order to (lazily) compute only once
    private static let blackBackgroundThresholdKernel: CIColorKernel = {
        getMetalThresholdingKernel(useBlackBackground: true)
    }()

    private static func getMetalThresholdingKernel(useBlackBackground: Bool) -> CIColorKernel {
        guard let url = Bundle.main.url(forResource: "ThresholdingFilter", withExtension: "coreimage.metallib") else {
            fatalError("Invalid url for ThresholdingFilter.coreimage.metallib")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            fatalError("Failed to load ThresholdingFilter.coreimage.metallib: \(error)")
        }

        let functionName = useBlackBackground ? "thresholdBlackBackground" : "thresholdWhiteBackground"
        do {
            return try CIColorKernel(functionName: functionName, fromMetalLibraryData: data)
        } catch {
            fatalError("Failed to load CIColorKernel from ThresholdingFilter.coreimage.metallib: \(error)")
        }
    }
}
