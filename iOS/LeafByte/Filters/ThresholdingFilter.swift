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
        if #available(iOS 11.0, *) {
            return getMetalThresholdingKernel(useBlackBackground: false)
        } else {
            return getLegacyThresholdingKernel(useBlackBackground: false)
        }
    }()

    // Static in order to (lazily) compute only once
    private static let blackBackgroundThresholdKernel: CIColorKernel = {
        if #available(iOS 11.0, *) {
            return getMetalThresholdingKernel(useBlackBackground: true)
        } else {
            return getLegacyThresholdingKernel(useBlackBackground: true)
        }
    }()

    @available(iOS 11.0, *)
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

    private static func getLegacyThresholdingKernel(useBlackBackground: Bool) -> CIColorKernel {
        // Normally a leaf is more intense than the background, but with a black background, it's less intense.
        let comparisonOperator = useBlackBackground ? ">" : "<"

        // This string represents a routine in the Core Image kernel language that transforms the image one pixel at a time ( https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/ImageUnitTutorial/WritingKernels/WritingKernels.html ).
        let kernelCode = "kernel vec4 thresholdKernel(sampler originalImage, sampler saturatedImage, float threshold) {" +
            // Since this kernel is applied to each pixel individually, extract the pixels in question.
            "  vec4 originalPixel = sample(originalImage, samplerCoord(originalImage));" +
            "  vec4 saturatedPixel = sample(saturatedImage, samplerCoord(saturatedImage));" +
            // This vector transforms RGB to luma, or intensity ( https://en.wikipedia.org/wiki/YUV#Conversion_to/from_RGB ).
            "  const vec3 rgbToLuma = vec3(0.299, 0.587, 0.114);" +
            "  float luma = dot(originalPixel.rgb, rgbToLuma);" +
            // 0 for alpha ( https://en.wikipedia.org/wiki/Alpha_compositing ) makes it invisible.
            "const vec4 invisiblePixel = vec4(0.0);" +
            // If the pixel is more/less intense (based on the background color), return invisible; otherwise, return a pixel of the actual (saturated) image.
            "  return luma " + comparisonOperator + " threshold ? vec4(saturatedPixel.rgb, 1) : invisiblePixel;" +
            "}"

        // Only null if the kernel code is invalid
        return CIColorKernel(source: kernelCode)! // swiftlint:disable:this force_unwrapping
    }
}
