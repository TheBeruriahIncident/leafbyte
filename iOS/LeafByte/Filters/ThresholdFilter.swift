//
//  ThresholdFilter.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/30/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreImage

class ThresholdFilter: CIFilter
{
    var inputImage : CIImage?
    var threshold: Float = 0.95
    
    // http://www.lps.usp.br/hae/apostila/basico/YUV-wikipedia.pdf
    var thresholdKernel =  CIColorKernel(source:
        "kernel vec4 thresholdKernel(sampler image, float threshold) {" +
        "  vec4 pixel = sample(image, samplerCoord(image));" +
        "  float sum = .299 * pixel.r + .587 * pixel.g + .114 * pixel.b;" +
        "  return sum < threshold ? pixel : vec4(1.0);" +
        "}")
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage,
            let thresholdKernel = thresholdKernel else {
                return nil
        }
        let extent = inputImage.extent
        // multiply by 3 since red, green, and blue are being summed
        // we could simply average the three components, but this saves us dividing by 3 for every pixel
        let arguments : [Any] = [inputImage, threshold]
        return thresholdKernel.apply(extent: extent, arguments: arguments)
    }
}

