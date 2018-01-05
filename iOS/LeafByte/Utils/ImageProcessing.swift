//
//  ImageProcessing.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Accelerate
import CoreGraphics

func getSuggestedThreshold(image: CGImage) -> Float {
    return otsusMethod(histogram: getLumaHistogram(image: image))
}

// Turn image into a histogram of luma, or intensity.
// The histogram is represented an array with 256 buckets, each bucket containing the number of pixels in that range of intensity.
private func getLumaHistogram(image: CGImage) -> [Int] {
    let pixelData = image.dataProvider!.data!
    var vImage = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(pixelData)),
        height: vImagePixelCount(image.height),
        width: vImagePixelCount(image.width),
        rowBytes: image.bytesPerRow)
    
    
    // https://github.com/PokerChang/ios-card-detector/blob/master/Accelerate.framework/Frameworks/vImage.framework/Headers/Transform.h#L20
    // This vector transforms RGB to luma, or intensity ( https://en.wikipedia.org/wiki/YUV#Conversion_to/from_RGB )
    let matrix: [Int16] = [299, 0, 0, 0,
                           587, 0, 0, 0,
                           114, 0, 0, 0,
                           0, 0, 0, 0]
    let divisor: Int32 = 1000
    
    // same in and out, in place
    vImageMatrixMultiply_ARGB8888(&vImage, &vImage, matrix, divisor, nil, nil, UInt32(kvImageNoFlags))
    
    let alpha = [UInt](repeating: 0, count: 256)
    let luma = [UInt](repeating: 0, count: 256)
    
    let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha) as UnsafeMutablePointer<vImagePixelCount>?
    let lumaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: luma) as UnsafeMutablePointer<vImagePixelCount>?
    
    let rgba = [lumaPtr, alphaPtr, alphaPtr, alphaPtr]
    
    let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: rgba)
    vImageHistogramCalculation_ARGB8888(&vImage, histogram, UInt32(kvImageNoFlags))
    
    let total = luma.map { Int($0) }
    return total
}

private func otsusMethod(histogram: [Int]) -> Float {
    // TODO: check this and use better variables, be better about types
    
    // Use Otsu's method to calculate an initial global threshold
    // Uses the optimized form that maximizes inter-class variance as at https://en.wikipedia.org/wiki/Otsu%27s_method
    let total = histogram.reduce(0, +)
    
    var sumB = 0
    var wB = 0
    var maximum = 0.0
    var level = 0
    let sum1 = zip(Array(0...255), histogram).reduce(0, { $0 + ($1.0 * $1.1) })
    
    for index in 0...255 {
        wB = wB + histogram[index]
        let wF = total - wB
        if (wB == 0 || wF == 0) {
            continue;
        }
        sumB += index * histogram[index]
        let mF = Double(sum1 - sumB) / Double(wF)
        let between = Double(wB * wF) * pow(((Double(sumB) / Double(wB)) - mF), 2);
        if ( between >= maximum ) {
            level = index
            maximum = between
        }
    }
    
    return Float(level) / 255
}
