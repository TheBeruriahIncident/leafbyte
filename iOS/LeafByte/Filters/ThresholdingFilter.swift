//
//  ThresholdingFilter.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/30/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreImage
import UIKit

// This Core Image Filter ( https://developer.apple.com/documentation/coreimage/cifilter ) is used to remove the image background via thresholding ( https://en.wikipedia.org/wiki/Thresholding_(image_processing) ).
// Because Core Image saturates images to make them more vibrant by default, we use both a saturated form of the image and one in the original color space.
// This allows us to do the thresholding using the unmanipulated image but only show pixels from the more vibrant image.
final class ThresholdingFilter: CIFilter {
    var threshold: Float = 0.5
    
    private var inputImageOriginalColorSpace: CIImage!
    private var inputImageSaturated: CIImage!
    
    private var useBlackBackground: Bool!
    
    func setInputImage(image: CGImage, useBlackBackground: Bool) {
        // Explicitly prevent Core Image from changing the color space, in order to get predictable thresholding. https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html#//apple_ref/doc/uid/TP30001185-CH10-SW7
        inputImageOriginalColorSpace = CIImage(cgImage: image, options: [CIImageOption.colorSpace: NSNull()])
        inputImageSaturated = CIImage(cgImage: image)
        self.useBlackBackground = useBlackBackground
    }
    
    // MARK: CIFilter overrides
    
    override var outputImage: CIImage! {
        let arguments : [Any] = [inputImageOriginalColorSpace, inputImageSaturated, threshold]
        return getThresholdingKernel().apply(extent: inputImageOriginalColorSpace.extent, arguments: arguments)
    }
    
    private func getThresholdingKernel() -> CIColorKernel {
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
        
        return CIColorKernel(source: kernelCode)!
    }
}
