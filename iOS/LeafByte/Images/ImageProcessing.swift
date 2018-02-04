//
//  ImageProcessing.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Accelerate
import CoreGraphics

let NUMBER_OF_HISTOGRAM_BUCKETS = 256

// Turns an image into a histogram of luma, or intensity.
// The histogram is represented as an array with 256 buckets, each bucket containing the number of pixels in that range of intensity.
func getLumaHistogram(image: CGImage) -> [Int] {
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
func otsusMethod(histogram: [Int]) -> Float {
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

class ConnectedComponentsInfo {
    let labelToMemberPoint: [Int: (Int, Int)]
    let emptyLabelToNeighboringOccupiedLabels: [Int: Set<Int>]
    let labelToSize: [Int: Int]
    let equivalenceClasses: UnionFind
    
    init(labelToMemberPoint: [Int: (Int, Int)], emptyLabelToNeighboringOccupiedLabels: [Int: Set<Int>], labelToSize: [Int: Int], equivalenceClasses: UnionFind) {
        self.labelToMemberPoint = labelToMemberPoint
        self.emptyLabelToNeighboringOccupiedLabels = emptyLabelToNeighboringOccupiedLabels
        self.labelToSize = labelToSize
        self.equivalenceClasses = equivalenceClasses
    }
}

// Find all the connected components in an image, that is the contiguous areas that are the same ( https://en.wikipedia.org/wiki/Connected-component_labeling ).
// "Occupied" refers to "true" values in the image, and "empty" refers to "false" values in the image.
// E.g. the leaf and scale mark will be occupied connected components, while the holes in the leaf will be "empty" connected components.
func labelConnectedComponents(image: BooleanIndexableImage) -> ConnectedComponentsInfo {
    let width = image.width
    let height = image.height
    
    // Initialize the structures we'll eventually be returning.
    // Maps a label to a point in that component, allowing us to reconstruct the component later.
    var labelToMemberPoint = [Int: (Int, Int)]()
    // Tells what occupied components surround any empty component.
    var emptyLabelToNeighboringOccupiedLabels = [Int: Set<Int>]()
    // Tells the size of each component.
    var labelToSize = [Int: Int]()
    
    // A matrix the size of the image with the label for each pixel.
    var labelledImage = Array(repeating: Array(repeating: 0, count: width), count: height)
    // A data structure to track what labels actually correspond to the same component (because of the way the algorithm runs, a single blob might get partially marked with one label and partially with another).
    let equivalenceClasses = UnionFind()
    
    // Negative labels will refer to empty components; positive will refer to occupied components.
    // Track what labels to give out next as we create new groups.
    var nextOccupiedLabel = 1
    var nextEmptyLabel = -2
    
    // Use -1 as a special label for the area outside the image.
    let outsideOfImageLabel = -1
    equivalenceClasses.createSubsetWith(outsideOfImageLabel)
    emptyLabelToNeighboringOccupiedLabels[outsideOfImageLabel] = []
    labelToSize[outsideOfImageLabel] = 0
    
    for y in 0...height - 1 {
        for x in 0...width - 1 {
            let isOccupied = image.getPixel(x: x, y: y)
            
            // Check the pixel's neighbors.
            // Note that we're using 4-connectivity ( https://en.wikipedia.org/wiki/Pixel_connectivity ) for speed.
            // Because we've only set the label for pixels we've already iterated over, we only need to check west and north.
            var westIsOccupied: Bool?
            var westLabel: Int?
            if x > 0 {
                westIsOccupied = image.getPixel(x: x - 1, y: y)
                westLabel = labelledImage[y][x - 1]
            }
            var northIsOccupied: Bool?
            var northLabel: Int?
            if y > 0 {
                northIsOccupied = image.getPixel(x: x, y: y - 1)
                northLabel = labelledImage[y - 1][x]
            }
            
            // Determine what label this pixel should have.
            var label: Int!
            if isOccupied == westIsOccupied {
                label = westLabel
                
                // If this pixel matches the west and north, those two ought to be equivalent.
                if isOccupied == northIsOccupied {
                    equivalenceClasses.combineClassesContaining(westLabel!, and: northLabel!)
                }
            } else if isOccupied == northIsOccupied {
                label = northLabel!
            } else {
                // If this pixel matches neither, it's part of a new component.
                if isOccupied {
                    label = nextOccupiedLabel
                    nextOccupiedLabel += 1
                } else {
                    label = nextEmptyLabel
                    nextEmptyLabel -= 1
                }
                
                // Initialize the new label.
                labelToMemberPoint[label] = (x, y)
                emptyLabelToNeighboringOccupiedLabels[label] = []
                labelToSize[label] = 0
                equivalenceClasses.createSubsetWith(label)
            }
            
            // Actually label the pixel and increment size.
            labelToSize[label]! += 1
            labelledImage[y][x] = label
            
            // Update the neighbor map if we have neighboring occupied and empty.
            if isOccupied {
                // Note that these are explicit checks rather just "if !westIsOccupied {", because these values are optional.
                if westIsOccupied == false {
                    emptyLabelToNeighboringOccupiedLabels[westLabel!]!.insert(label)
                }
                if northIsOccupied == false {
                    emptyLabelToNeighboringOccupiedLabels[northLabel!]!.insert(label)
                }
            } else {
                if westIsOccupied == true {
                    emptyLabelToNeighboringOccupiedLabels[label]!.insert(westLabel!)
                }
                if northIsOccupied == true {
                    emptyLabelToNeighboringOccupiedLabels[label]!.insert(northLabel!)
                }
            }

            // Any empty pixels on the edge of the image are part of the "outside of the image" component.
            if !isOccupied && (y == 0 || x == 0 || y == height - 1 || x == width - 1) {
                equivalenceClasses.combineClassesContaining(labelledImage[y][x], and: outsideOfImageLabel)
            }
        }
    }
   
    // -1, the label for the outside of the image, has a fake member point.
    // Let's fix that so it can't break any code that uses the result of this function.
    let outsideOfImageClass = equivalenceClasses.getClassOf(outsideOfImageLabel)!
    let outsideOfImageClassElement = equivalenceClasses.classToElements[outsideOfImageClass]!.first(where: { $0 != outsideOfImageLabel })
    if outsideOfImageClassElement != nil {
        labelToMemberPoint[outsideOfImageLabel] = labelToMemberPoint[outsideOfImageClassElement!]
    } else {
        // -1 is in a class of it's own.
        // This means it's useless, so remove it.
        labelToMemberPoint[outsideOfImageLabel] = nil
        emptyLabelToNeighboringOccupiedLabels[outsideOfImageLabel] = nil
        labelToSize[outsideOfImageLabel] = nil
        equivalenceClasses.classToElements[outsideOfImageClass] = nil
    }
    
    // "Normalize" by combining equivalent labels.
    for equivalenceClassElements in equivalenceClasses.classToElements.values {
        let first = equivalenceClassElements.first
        equivalenceClassElements.filter { $0 != first! }.forEach { label in
            // Normalize labelToSize.
            labelToSize[first!]! += labelToSize[label]!
            labelToSize[label] = nil
            
            // Normalize emptyLabelToNeighboringOccupiedLabels.
            emptyLabelToNeighboringOccupiedLabels[first!]!.formUnion(emptyLabelToNeighboringOccupiedLabels[label]!)
            emptyLabelToNeighboringOccupiedLabels[label] = nil
        }
    }
    
    return ConnectedComponentsInfo(
        labelToMemberPoint: labelToMemberPoint,
        emptyLabelToNeighboringOccupiedLabels: emptyLabelToNeighboringOccupiedLabels,
        labelToSize: labelToSize,
        equivalenceClasses: equivalenceClasses)
}
