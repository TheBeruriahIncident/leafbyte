//
//  ThresholdFilter.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/30/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreImage
import Accelerate

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
        
//        let img: CGImage = inputImageColorful.cgImage!
//        let imgProvider: CGDataProvider = img.dataProvider!
//        let imgBitmapData: CFData = imgProvider.data!
//        var imgBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(imgBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)
//        
//        let normed = threshold * 256
//        for i in 2418...2422 {
//            for j in 0...0 {
//                let test = imgBuffer.data.load(fromByteOffset: (i * img.width + j) * 4, as: UInt32.self)
//                
//                let r = Float((test >> 16) & 255)
//                let g = Float((test >> 8) & 255)
//                let b = Float(test & 255)
//                let intensity = 0.114 * r + 0.587 * g + 0.299 * b
//                
//                print(intensity > normed ? "1" : "0", terminator: "")
//            }
//            print("")
//        }
//        
        
        let extent = inputImage.extent
        // multiply by 3 since red, green, and blue are being summed
        // we could simply average the three components, but this saves us dividing by 3 for every pixel
        let arguments : [Any] = [inputImage, inputImageColorful, threshold]
        return thresholdKernel.apply(extent: extent, arguments: arguments)
    }
}

