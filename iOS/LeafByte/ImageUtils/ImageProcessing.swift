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

private let NUMBER_OF_HISTOGRAM_BUCKETS = 256

// Turns an image into a histogram of luma, or intensity.
// The histogram is represented an array with 256 buckets, each bucket containing the number of pixels in that range of intensity.
private func getLumaHistogram(image: CGImage) -> [Int] {
    let pixelData = image.dataProvider!.data!
    var initialVImage = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(pixelData)),
        height: vImagePixelCount(image.height),
        width: vImagePixelCount(image.width),
        rowBytes: image.bytesPerRow)
    
    // vImageMatrixMultiply_ARGB8888 operates in place, pixel-by-pixel, so it's sometimes possible to use the same vImage for input and output.
    // However, images from UIGraphicsGetImageFromCurrentImageContext, which is where the initial image comes from, are readonly.
    let mutableBuffer = CFDataCreateMutable(nil, image.bytesPerRow * image.height)
    var lumaVImage = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(mutableBuffer)),
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
    vImageMatrixMultiply_ARGB8888(&initialVImage, &lumaVImage, matrix, divisor, nil, nil, UInt32(kvImageNoFlags))
    
    // Now we're going to use vImageHistogramCalculation_ARGB8888 to get a histogram of each channel in our image.
    // Since luma is the only channel we care about (we zeroed the rest), we'll use a garbage array to catch the other histograms.
    let lumaHistogram = [UInt](repeating: 0, count: NUMBER_OF_HISTOGRAM_BUCKETS)
    let lumaHistogramPointer = UnsafeMutablePointer<vImagePixelCount>(mutating: lumaHistogram) as UnsafeMutablePointer<vImagePixelCount>?
    let garbageHistogram = [UInt](repeating: 0, count: NUMBER_OF_HISTOGRAM_BUCKETS)
    let garbageHistogramPointer = UnsafeMutablePointer<vImagePixelCount>(mutating: garbageHistogram) as UnsafeMutablePointer<vImagePixelCount>?
    let histogramArray = [lumaHistogramPointer, garbageHistogramPointer, garbageHistogramPointer, garbageHistogramPointer]
    let histogramArrayPointer = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: histogramArray)
    
    vImageHistogramCalculation_ARGB8888(&lumaVImage, histogramArrayPointer, UInt32(kvImageNoFlags))
    
    return lumaHistogram.map { Int($0) }
}

// Use Otsu's method, an algorithm that takes a histogram of intensities (that it assumes is roughly bimodal, corresponding to foreground and background) and tries to find the cut that separates the two modes ( https://en.wikipedia.org/wiki/Otsu%27s_method ).
// Note that this implementation is the optimized form that maximizes inter-class variance as opposed to minimizing intra-class variance (also described at the above link).
private func otsusMethod(histogram: [Int]) -> Float {
    // The following equations and algorithm are taken from https://en.wikipedia.org/wiki/Otsu%27s_method#Otsu's_Method , and variable names here refer to variable names in equations there.
    
    // We can transform omega0 and mu0Numerator as we go through the loop. Both omega1 and mu1Numerator are easily derivable, since both omegas and muNumerators sum to constants.
    var omega0 = 0
    let sumOfOmegas = histogram.reduce(0, +)
    var mu0Numerator = 0
    // This calculates a dot product.
    let sumOfMuNumerators = zip(Array(0...NUMBER_OF_HISTOGRAM_BUCKETS - 1), histogram).reduce(0, { (accumulator, pair) in
        accumulator + (pair.0 * pair.1) })
    
    var maximumInterClassVariance = 0.0
    var bestCut = 0
    
    for index in 0...NUMBER_OF_HISTOGRAM_BUCKETS - 1 {
        omega0 = omega0 + histogram[index]
        let omega1 = sumOfOmegas - omega0
        if omega0 == 0 || omega1 == 0 {
            continue
        }
        
        mu0Numerator += index * histogram[index]
        let mu1Numerator = sumOfMuNumerators - mu0Numerator
        let mu0 = Double(mu0Numerator) / Double(omega0)
        let mu1 = Double(mu1Numerator) / Double(omega1)
        let interClassVariance = Double(omega0 * omega1) * pow(mu0 - mu1, 2)
        
        if interClassVariance >= maximumInterClassVariance {
            maximumInterClassVariance = interClassVariance
            bestCut = index
        }
    }
    
    return Float(bestCut) / Float(NUMBER_OF_HISTOGRAM_BUCKETS - 1)
}
