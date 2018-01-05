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

// Turns an image into a histogram of luma, or intensity.
// The histogram is represented an array with 256 buckets, each bucket containing the number of pixels in that range of intensity.
private func getLumaHistogram(image: CGImage) -> [Int] {
    let pixelData = image.dataProvider!.data!
    var vImage = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(pixelData)),
        height: vImagePixelCount(image.height),
        width: vImagePixelCount(image.width),
        rowBytes: image.bytesPerRow)
    
    // We're about to call vImageMatrixMultiply_ARGB8888, the best documentation of which I've found is in the SDK source: https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.7.sdk/System/Library/Frameworks/Accelerate.framework/Versions/A/Frameworks/vImage.framework/Versions/A/Headers/Transform.h#L21 .
    // Essentially each pixel in the image is a row vector [R, G, B, A] and is post-multiplied by a matrix to create a new transformed image.
    // Because luma = RGB * [.299, .587, .114]' ( https://en.wikipedia.org/wiki/YUV#Conversion_to/from_RGB ), we can use this multiplication to get a luma value for each pixel.
    // The following matrix will replace the first channel of each pixel (previously red) with luma, while zeroing everything else (since nothing else matters to us).
    let matrix: [Int16] = [299, 0, 0, 0,
                           587, 0, 0, 0,
                           114, 0, 0, 0,
                           0,   0, 0, 0]
    // Our matrix can only have integers, but this is accomodated for by having a post-divisor applied to the result of the multiplication.
    // As such, we're actually doing luma = RGB * [299, 587, 114]' / 1000 .
    let divisor: Int32 = 1000
    // This transformation operates in-place pixel by pixel, so we can use the same vImage for input and output.
    vImageMatrixMultiply_ARGB8888(&vImage, &vImage, matrix, divisor, nil, nil, UInt32(kvImageNoFlags))
    
    // Now we're going to use vImageHistogramCalculation_ARGB8888 to get a histogram of each channel in our image.
    // Since luma is the only channel we care about (we zeroed the rest), we'll use a garbage array to catch the other histograms.
    let lumaHistogram = [UInt](repeating: 0, count: 256)
    let lumaHistogramPointer = UnsafeMutablePointer<vImagePixelCount>(mutating: lumaHistogram) as UnsafeMutablePointer<vImagePixelCount>?
    let garbageHistogram = [UInt](repeating: 0, count: 256)
    let garbageHistogramPointer = UnsafeMutablePointer<vImagePixelCount>(mutating: garbageHistogram) as UnsafeMutablePointer<vImagePixelCount>?
    let histogramArray = [lumaHistogramPointer, garbageHistogramPointer, garbageHistogramPointer, garbageHistogramPointer]
    let histogramArrayPointer = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: histogramArray)
    
    vImageHistogramCalculation_ARGB8888(&vImage, histogramArrayPointer, UInt32(kvImageNoFlags))
    
    return lumaHistogram.map { Int($0) }
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
