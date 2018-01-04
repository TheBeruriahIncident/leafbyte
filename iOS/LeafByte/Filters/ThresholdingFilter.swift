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
class ThresholdingFilter: CIFilter {
    var threshold: Float = 0.5
    
    private var inputImageOriginalColorSpace: CIImage!
    private var inputImageSaturated: CIImage!
    
    // This string represents a routine in the Core Image kernel language that transforms the image one pixel at a time ( https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/ImageUnitTutorial/WritingKernels/WritingKernels.html ).
    private let thresholdingKernel =  CIColorKernel(source:
        // This vector transforms RGB to luma, or intensity ( https://en.wikipedia.org/wiki/YUV#Conversion_to/from_RGB ).
        "  const vec3 rgbToLuma = vec3(0.114, 0.587, 0.299);" +
        // (1, 1, 1) is the color white, and 1 for alpha ( https://en.wikipedia.org/wiki/Alpha_compositing ) makes it solid
        "const vec4 whitePixel = vec4(1.0);" +
        "" +
        // After defining constants to use across all pixels, this is the actual thresholding.
        "kernel vec4 thresholdKernel(sampler originalImage, sampler saturatedImage, float threshold) {" +
        // Since this kernel is applied to each pixel individually, extract the pixels in question.
        "  vec4 originalPixel = sample(originalImage, samplerCoord(originalImage));" +
        "  vec4 saturatedPixel = sample(saturatedImage, samplerCoord(saturatedImage));" +
        "  float luma = dot(originalPixel.rgb, rgbToLuma);" +
        // If the pixel is not intense enough, return white; otherwise, return a pixel of the actual (saturated) image, darkened to make it more distinct from white.
        "  return luma < threshold ? vec4(saturatedPixel.rgb/3.0, 1) : whitePixel;" +
        "}")!
    
    func setInputImage(_ inputImage: UIImage) {
        // Explicitly prevent Core Image from changing the color space, in order to get predictable thresholding. https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html#//apple_ref/doc/uid/TP30001185-CH10-SW7
        inputImageOriginalColorSpace = CIImage(image: inputImage, options: [kCIImageColorSpace: NSNull()])
        inputImageSaturated = CIImage(image: inputImage)
    }
    
    // MARK: CIFilter overrides
    override var outputImage: CIImage! {
        let arguments : [Any] = [inputImageOriginalColorSpace, inputImageSaturated, threshold]
        return thresholdingKernel.apply(extent: inputImageOriginalColorSpace.extent, arguments: arguments)
    }
}

