//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit

// Fills an image view with a blank image.
func initializeImage(view: UIImageView) {
    UIGraphicsBeginImageContext(view.frame.size)
    view.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
}

// See http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/ for some of the gotchas here.
// Code to account for orientation was adapted from there.
func resizeImage(_ image: UIImage, within newBounds: CGSize) -> CGImage {
    let cgImage = uiToCgImage(image)
    
    // Check if transformation is necessary.
    if image.imageOrientation == .up && image.size.width <= newBounds.width && image.size.height <= newBounds.height {
        return cgImage
    }
    
    // Find the resizing ratio that maintains the aspect ratio.
    let resizingRatioForWidth = newBounds.width / image.size.width
    let resizingRatioForHeight = newBounds.height / image.size.height
    let resizingRatio = min(resizingRatioForWidth, resizingRatioForHeight)
    
    // Calculate the new image size.
    let newWidth = image.size.width * resizingRatio
    let newHeight = image.size.height * resizingRatio
    let newWidthRoundedDown = roundToInt(newWidth, rule: .down)
    let newHeightRoundedDown = roundToInt(newHeight, rule: .down)
    
    // Create the context to draw into.
    var maybeContext = CGContext(
        data: nil,
        width: newWidthRoundedDown,
        height: newHeightRoundedDown,
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: 0,
        space: cgImage.colorSpace!,
        bitmapInfo: cgImage.bitmapInfo.rawValue)
    
    // This is an awful hack that I'd love to improve. Sometimes the context isn't created (the initializer returns nil).
    // I can't figure why, but it seems to be that the initializer succceeds when the bitmap info is 1, 2, 5, or 6.
    // I can't find documentation for the bitmap info or why the initializer would fail.
    // My best lead is that those numbers are all within the first 5 bits, which seem to be the alpha info mask.
    // Also, I'm only seeing bits within that mask be set on any bitmap info.
    // So, I try all the different values in that mask in the hopes that one of them will result in a non-nil context.
    var i: UInt32 = 0
    while maybeContext == nil {
        if i == 32 {
            fatalError("Context could not be created")
        }
        
        maybeContext = CGContext(
            data: nil,
            width: newWidthRoundedDown,
            height: newHeightRoundedDown,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace!,
            bitmapInfo: i)
        i += 1
    }
    
    let context = maybeContext!
    context.interpolationQuality = .high
    
    // Consider the orientation of the original image, and rotate/flip as appropriate for the result to be right-side up.
    let transform = getTransformToCorrectUIImage(withOrientation: image.imageOrientation, intoWidth: newWidth, andHeight: newHeight)
    context.concatenate(transform)
    
    // Actually draw into the context, transposing if need be.
    var drawTransposed: Bool!
    switch (image.imageOrientation) {
    case .left, .leftMirrored, .right, .rightMirrored:
        drawTransposed = true
    default:
        drawTransposed = false
    }
    context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size:
        CGSize(width: drawTransposed ? newHeight : newWidth,
               height: drawTransposed ? newWidth : newHeight)))
    
    return context.makeImage()!
}

// A UIImage can have various orientations that must be corrected for. This was adapted from http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/ .
private func getTransformToCorrectUIImage(withOrientation orientation: UIImageOrientation, intoWidth width: CGFloat, andHeight height: CGFloat) -> CGAffineTransform {
    var transform = CGAffineTransform.identity
    
    // Account for direction by rotating (the translations move the rotated image back "into frame").
    switch (orientation) {
    case .down, .downMirrored:
        transform = transform.translatedBy(x: width, y: height).rotated(by: CGFloat.pi)
    case .left, .leftMirrored:
        transform = transform.translatedBy(x: width, y: 0).rotated(by: CGFloat.pi / 2)
    case .right, .rightMirrored:
        transform = transform.translatedBy(x: 0, y: height).rotated(by: -CGFloat.pi / 2)
    default:
        ()
    }
    
    // Account for mirroring by flipping (the translations again move the flipped image back "into frame").
    switch (orientation) {
    case .upMirrored, .downMirrored:
        transform = transform.translatedBy(x: width, y: 0).scaledBy(x: -1, y: 1)
    case .leftMirrored, .rightMirrored:
        transform = transform.translatedBy(x: height, y: 0).scaledBy(x: -1, y: 1)
    default:
        ()
    }
    
    return transform
}

// Combine a list of images with equivalent frames, cropping to the first image.
func combineImages(_ imageViews: [UIImageView]) -> UIImage {
    // Size the canvas to the frame (which is assumed to be the same for all).
    UIGraphicsBeginImageContext(imageViews[0].frame.size)
    
    // Draw each image into the canvas at the same place they appear in their image view.
    for imageView in imageViews {
        imageView.image!.draw(in: getRectForImage(inView: imageView))
    }
    
    // Clip to the area covered by the first image.
    UIGraphicsGetCurrentContext()?.clip(to: getRectForImage(inView: imageViews[0]))
    
    let combinedImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return combinedImage
}

private func getRectForImage(inView view: UIImageView) -> CGRect {
    let projection = Projection(invertProjection: Projection(invertProjection: Projection(fromImageInView: view.image!, toView: view)))
    return CGRect(
        x: CGFloat(projection.xOffset),
        y: CGFloat(projection.yOffset),
        width: view.image!.size.width * CGFloat(projection.scale),
        height: view.image!.size.height * CGFloat(projection.scale))
}

// Find the point farthest away from a point within a connected component.
// In other words, find the farthest away point reachable along non-white points.
// Note that farthest away refers to the number of non-white points traversed rather than traditional distance.
func getFarthestPointInComponent(inImage image: IndexableImage, fromPoint startingPoint: CGPoint) -> CGPoint {
    let width = image.width
    let height = image.height
    
    var explored = Set<CGPoint>()
    var queue = [startingPoint]
    
    var farthestPointSoFar: CGPoint!
    
    while !queue.isEmpty {
        // TODO: use a queue where this isn't O(n)
        let point = queue.removeFirst()
        if explored.contains(point) {
            continue
        }
        
        let x = roundToInt(point.x)
        let y = roundToInt(point.y)
        
        let westPoint = CGPoint(x: x - 1, y: y)
        if x > 0 && image.getPixel(x: x - 1, y: y).isNonWhite() && !explored.contains(westPoint) {
            queue.append(westPoint)
        }
        let eastPoint = CGPoint(x: x + 1, y: y)
        if x < width - 1 && image.getPixel(x: x + 1, y: y).isNonWhite() && !explored.contains(eastPoint) {
            queue.append(eastPoint)
        }
        let southPoint = CGPoint(x: x, y: y - 1)
        if y > 0 && image.getPixel(x: x, y: y - 1).isNonWhite() && !explored.contains(southPoint) {
            queue.append(southPoint)
        }
        let northPoint = CGPoint(x: x, y: y + 1)
        if y < height - 1 && image.getPixel(x: x, y: y + 1).isNonWhite() && !explored.contains(northPoint) {
            queue.append(northPoint)
        }
        
        explored.insert(point)
        farthestPointSoFar = point
    }
    
    return farthestPointSoFar
}

func searchForNonWhite(inImage image: IndexableImage, fromPoint startingPoint: CGPoint, checkingNoMoreThan maxPixelsToCheck: Int) -> CGPoint? {
    let width = image.width
    let height = image.height
    
    var explored = Set<CGPoint>()
    var queue = [startingPoint]

    while !queue.isEmpty && explored.count <= maxPixelsToCheck {
        let point = queue.removeFirst()
        if explored.contains(point) {
            continue
        }
        
        // Stop if we've found non-white.
        if image.getPixel(x: roundToInt(point.x), y: roundToInt(point.y)).isNonWhite() {
            return point
        }
        
        let x = roundToInt(point.x)
        let y = roundToInt(point.y)
        
        let westPoint = CGPoint(x: x - 1, y: y)
        if x > 0 && !explored.contains(westPoint) {
            queue.append(westPoint)
        }
        let eastPoint = CGPoint(x: x + 1, y: y)
        if x < width - 1 && !explored.contains(eastPoint) {
            queue.append(eastPoint)
        }
        let southPoint = CGPoint(x: x, y: y - 1)
        if y > 0 && !explored.contains(southPoint) {
            queue.append(southPoint)
        }
        let northPoint = CGPoint(x: x, y: y + 1)
        if y < height - 1 && !explored.contains(northPoint) {
            queue.append(northPoint)
        }
        
        explored.insert(point)
    }
    
    return nil
}

// Flood fills an image from a point ( https://en.wikipedia.org/wiki/Flood_fill ).
// Assumes that the starting point is "empty" (false) in the boolean image, and draws to the drawing manager.
func floodFill(image: BooleanIndexableImage, fromPoint startingPoint: CGPoint, drawingTo drawingManager: DrawingManager) {
    // This tracks what ranges are already filled in, mapping a y coordinate to a list of x ranges.
    var filledRanges = [Int: [(Int, Int)]]()
    // This is a list of points to fill from.
    var queue: Set<CGPoint> = [startingPoint]
    
    while !queue.isEmpty {
        // We're going to find the largest horizontal line containing this point that stays in the empty area.
        let point = queue.popFirst()!
        let x = roundToInt(point.x)
        let y = roundToInt(point.y)
        // If this point is already filled, we can truncate here.
        if isFilled(x: x, y: y, referringTo: filledRanges) {
            continue
        }
        
        // Check if the points above or below the point should be added to the queue.
        if y < image.height - 1 && !image.getPixel(x: x, y: y + 1) && !isFilled(x: x, y: y + 1, referringTo: filledRanges) {
            queue.insert(CGPoint(x: x, y: y + 1))
        }
        if y > 0 && !image.getPixel(x: x, y: y - 1) && !isFilled(x: x, y: y - 1, referringTo: filledRanges) {
            queue.insert(CGPoint(x: x, y: y - 1))
        }
        // As an optimization, as we move left and right, we only need to consider the above or below points for adding to the queue if we've passed a filled point.
        // This is because otherwise those points would be in the same line that has already been added to the queue above.
        // As such, we need to track eligibility for adding to the queue on both the north and south side.
        let initialEligibleForQueueNorth = y < image.height - 1 && image.getPixel(x: x, y: y + 1)
        let initialEligibleForQueueSouth = y > 0 && image.getPixel(x: x, y: y - 1)
        
        var leftmostX = x
        var eligibleForQueueNorth = initialEligibleForQueueNorth
        var eligibleForQueueSouth = initialEligibleForQueueSouth
        // Move left as far as possible.
        while leftmostX > 0 && !image.getPixel(x: leftmostX - 1, y: y) {
            leftmostX -= 1
            
            // Check if the northern pixel should be added to the queue, and update eligibility.
            if y < image.height - 1 {
                if image.getPixel(x: leftmostX, y: y + 1) {
                    eligibleForQueueNorth = true
                } else if eligibleForQueueNorth {
                    if !isFilled(x: leftmostX, y: y + 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: leftmostX, y: y + 1))
                    }
                    eligibleForQueueNorth = false
                }
            }
            
            // Check if the southern pixel should be added to the queue, and update eligibility.
            if y > 0 {
                if image.getPixel(x: leftmostX, y: y - 1) {
                    eligibleForQueueSouth = true
                } else if eligibleForQueueSouth {
                    if !isFilled(x: leftmostX, y: y - 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: leftmostX, y: y - 1))
                    }
                    eligibleForQueueSouth = false
                }
            }
        }

        var rightmostX = x
        eligibleForQueueNorth = initialEligibleForQueueNorth
        eligibleForQueueSouth = initialEligibleForQueueSouth
        // Move right as far as possible.
        while rightmostX < image.width - 1 && !image.getPixel(x: rightmostX + 1, y: y) {
            rightmostX += 1
            
            // Check if the northern pixel should be added to the queue, and update eligibility.
            if y < image.height - 1 {
                if image.getPixel(x: rightmostX, y: y + 1) {
                    eligibleForQueueNorth = true
                } else if eligibleForQueueNorth {
                    if !isFilled(x: rightmostX, y: y + 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: rightmostX, y: y + 1))
                    }
                    eligibleForQueueNorth = false
                }
            }
            
            // Check if the southern pixel should be added to the queue, and update eligibility.
            if y > 0 {
                if image.getPixel(x: rightmostX, y: y - 1) {
                    eligibleForQueueSouth = true
                } else if eligibleForQueueSouth {
                    if !isFilled(x: rightmostX, y: y - 1, referringTo: filledRanges) {
                        queue.insert(CGPoint(x: rightmostX, y: y - 1))
                    }
                    eligibleForQueueSouth = false
                }
            }
        }
        
        // Draw the horizontal line from the leftmost clear point to the rightmost clear point.
        drawingManager.drawLine(from: CGPoint(x: leftmostX, y: y), to: CGPoint(x: rightmostX, y: y))
        
        // Mark the range as filled in so we don't come back to it.
        if filledRanges[y] != nil {
            filledRanges[y]!.append((leftmostX, rightmostX))
        } else {
            filledRanges[y] = [(leftmostX, rightmostX)]
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
