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
    var inputImageColorful : CIImage?
    var threshold: Float = 0.95
    
    // http://www.lps.usp.br/hae/apostila/basico/YUV-wikipedia.pdf
    var thresholdKernel =  CIColorKernel(source:
        "kernel vec4 thresholdKernel(sampler image, sampler imageColorful, float threshold) {" +
        "  vec4 pixel = sample(image, samplerCoord(image));" +
        "  vec4 pixelColorful = sample(imageColorful, samplerCoord(imageColorful));" +
        "  float sum = .299 * pixel.r + .587 * pixel.g + .114 * pixel.b;" +
        "  return sum < threshold ? vec4((pixelColorful.r + .0)/30.0, (pixelColorful.g + .0)/30.0, (pixelColorful.b + .0)/30.0, 1) : vec4(1.0);" +
        "}")
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage,
            let inputImageColorful = inputImageColorful,
            let thresholdKernel = thresholdKernel else {
                return nil
        }
        
        let extent = inputImage.extent
        let arguments : [Any] = [inputImage, inputImageColorful, threshold]
        return thresholdKernel.apply(extent: extent, arguments: arguments)
    }
}

