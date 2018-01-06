//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit

func resizeImage(_ image: UIImage, within newBounds: CGSize) -> UIImage {
    // Check if resizing is necessary.
    if image.size.width <= newBounds.width && image.size.height <= newBounds.height {
        return image
    }
    
    // Find the resizing ratio that maintains the aspect ratio.
    let resizingRatioForWidth = newBounds.width / image.size.width
    let resizingRatioForHeight = newBounds.height / image.size.height
    let resizingRatio = min(resizingRatioForWidth, resizingRatioForHeight)
    
    let newSize = CGSize(width: image.size.width * resizingRatio, height: image.size.height * resizingRatio)
    
    let cgImage = uiToCgImage(image)
    
    let context = CGContext(
        data: nil,
        width: Int(newSize.width),
        height: Int(newSize.height),
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: 0,
        space: cgImage.colorSpace!,
        bitmapInfo: cgImage.bitmapInfo.rawValue)!
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
    
    // TODO: I bet I can get away without this conversion
    return cgToUiImage(context.makeImage()!)
}

// Flood fills an image from a point ( https://en.wikipedia.org/wiki/Flood_fill ).
// Assumes that the starting point is "empty" (false) in the boolean image, and draws to the drawing manager.
func floodFill(image: BooleanIndexableImage, fromPoint startingPoint: CGPoint, drawingTo drawingManager: DrawingManager) {
    var filledRanges = [Int: [(Int, Int)]]() // y to a list of range
    // TODO: should be a set??
    // TODO: actually, why am I getting repeated values at all
    var queue: Set<CGPoint> = [startingPoint]
    
    while !queue.isEmpty {
        let point = queue.popFirst()!
        
        // TODO: return early
        let x = Int(point.x)
        let y = Int(point.y)
//        if isFilled(x: x, y: y, referringTo: filledRanges) {
//            continue
//        }
        
        // TODO handle starting top bottom once
        
//        if !isFilled(x: x, y: y + 1, referringTo: filledRanges) {
//            queue.insert(CGPoint(x: x, y: y + 1))
//        }
//        if !isFilled(x: x, y: y - 1, referringTo: filledRanges) {
//            queue.insert(CGPoint(x: x, y: y - 1))
//        }
        
        var xLeft = x
        var enteringNewSectionNorth = true
        var enteringNewSectionSouth = true
        while xLeft > 0 && !image.getPixel(x: xLeft - 1, y: y) {
            xLeft -= 1
            
            if image.getPixel(x: xLeft, y: y + 1) {
                enteringNewSectionNorth = true
            } else {
                if enteringNewSectionNorth {
                    if !isFilled(x: xLeft, y: y + 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: xLeft, y: y + 1))
                    }
                    enteringNewSectionNorth = false
                }
            }
            if image.getPixel(x: xLeft, y: y - 1) {
                enteringNewSectionSouth = true
            } else {
                if enteringNewSectionSouth {
                    if !isFilled(x: xLeft, y: y - 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: xLeft, y: y - 1))
                    }
                    enteringNewSectionSouth = false
                }
            }
        }

//        enteringNewSectionNorth = false
//        enteringNewSectionSouth = false
        var xRight = x
        while xRight > 0 && !image.getPixel(x: xRight + 1, y: y) {
            xRight += 1
            
            if image.getPixel(x: xRight, y: y + 1) {
                enteringNewSectionNorth = true
            } else {
                if enteringNewSectionNorth {
                    if !isFilled(x: xRight, y: y + 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: xRight, y: y + 1))
                    }
                    enteringNewSectionNorth = false
                }
            }
            if image.getPixel(x: xRight, y: y - 1) {
                enteringNewSectionSouth = true
            } else {
                if enteringNewSectionSouth {
                    if !isFilled(x: xRight, y: y - 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: xRight, y: y - 1))
                    }
                    enteringNewSectionSouth = false
                }
            }
        }
        
        drawingManager.drawLine(from: CGPoint(x: xLeft, y: y), to: CGPoint(x: xRight, y: y))
        
        if filledRanges[y] != nil {
            filledRanges[y]!.append((xLeft, xRight))
        } else {
            filledRanges[y] = [(xLeft, xRight)]
        }
        
    }
}

private func isFilled(x: Int, y: Int, referringTo filledRanges: [Int: [(Int, Int)]]) -> Bool {
    let filledXRanges = filledRanges[y]
    if filledXRanges == nil {
        return false
    }
    
    return filledXRanges!.contains(where: { filledXRange in
        x >= filledXRange.0 && x <= filledXRange.1 })
}
