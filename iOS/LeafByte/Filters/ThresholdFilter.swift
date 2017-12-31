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
    
    var thresholdKernel =  CIColorKernel(source:
        "kernel vec4 thresholdKernel(sampler image, float inputThreshold)\n" +
        "{\n" +
        "  float pass = 1.0;\n" +
        "  float fail = 0.0;\n" +
        "  const vec4    vec_Y = vec4( 0.299, 0.587, 0.114, 0.0 );\n" +
        "  vec4        src = sample(image, samplerCoord(image));\n" +
        "  float        Y = dot( src, vec_Y );\n" +
        "  src.rgb = vec3( compare( Y - inputThreshold, fail, pass));\n" +
        "  return src;\n" +
        "}")
    
    override var outputImage: CIImage! {
        guard let inputImage = inputImage,
            let thresholdKernel = thresholdKernel else {
                return nil
        }
        let extent = inputImage.extent
        let arguments : [Any] = [inputImage, threshold]
        return thresholdKernel.apply(extent: extent, arguments: arguments)
    }
}

