//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/5/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import UIKit

// Fills an image view with a blank image.
func initializeImage(view: UIImageView, size: CGSize) {
    UIGraphicsBeginImageContext(size)
    view.image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
}

func resizeImageIgnoringAspectRatioAndOrientation(_ image: CGImage, x: Int, y: Int) -> CGImage {
    // Create the context to draw into.
    let context = CGContext(
        data: nil,
        width: x,
        height: y,
        bitsPerComponent: image.bitsPerComponent,
        bytesPerRow: 0,
        // swiftlint:disable:next force_unwrapping
        space: image.colorSpace!,
        bitmapInfo: image.bitmapInfo.rawValue)! // swiftlint:disable:this force_unwrapping
    context.interpolationQuality = .high

    context.draw(image, in: CGRect(origin: CGPoint.zero, size: CGSize(width: x, height: y)))
    return context.makeImage()! // swiftlint:disable:this force_unwrapping
}

func resizeImage(_ image: UIImage) -> CGImage? {
    resizeImage(image, within: CGSize(width: 1_200, height: 1_200))
}

// See http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/ for some of the gotchas here.
// Code to account for orientation was adapted from there.
func resizeImage(_ image: UIImage, within newBounds: CGSize) -> CGImage? {
    guard let cgImage = uiToCgImage(image) else {
        return nil
    }

    // Check if transformation is necessary.
    if image.imageOrientation == .up && image.size.width <= newBounds.width && image.size.height <= newBounds.height {
        return cgImage
    }

    // Find the resizing ratio that maintains the aspect ratio.
    let resizingRatioForWidth = newBounds.width / image.size.width
    let resizingRatioForHeight = newBounds.height / image.size.height
    let uncappedResizingRatio = min(resizingRatioForWidth, resizingRatioForHeight)
    // Make sure we don't scale up.
    let resizingRatio = min(uncappedResizingRatio, 1)

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
        // swiftlint:disable:next force_unwrapping
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
            // swiftlint:disable:next force_unwrapping
            space: cgImage.colorSpace!,
            bitmapInfo: i)
        i += 1
    }

    let context = maybeContext! // swiftlint:disable:this force_unwrapping
    context.interpolationQuality = .high

    // Consider the orientation of the original image, and rotate/flip as appropriate for the result to be right-side up.
    let transform = getTransformToCorrectUIImage(withOrientation: image.imageOrientation, intoWidth: newWidth, andHeight: newHeight)
    context.concatenate(transform)

    // Actually draw into the context, transposing if need be.
    let drawTransposed: Bool
    switch image.imageOrientation {
    case .left, .leftMirrored, .right, .rightMirrored:
        drawTransposed = true

    default:
        drawTransposed = false
    }
    context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size:
        CGSize(width: drawTransposed ? newHeight : newWidth,
            height: drawTransposed ? newWidth : newHeight)))

    return context.makeImage()! // swiftlint:disable:this force_unwrapping
}

// A UIImage can have various orientations that must be corrected for. This was adapted from http://vocaro.com/trevor/blog/2009/10/12/resize-a-uiimage-the-right-way/ .
private func getTransformToCorrectUIImage(withOrientation orientation: UIImage.Orientation, intoWidth width: CGFloat, andHeight height: CGFloat) -> CGAffineTransform {
    var transform = CGAffineTransform.identity

    // Account for direction by rotating (the translations move the rotated image back "into frame").
    switch orientation {
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
    switch orientation {
    case .upMirrored, .downMirrored:
        transform = transform.translatedBy(x: width, y: 0).scaledBy(x: -1, y: 1)

    case .leftMirrored, .rightMirrored:
        transform = transform.translatedBy(x: height, y: 0).scaledBy(x: -1, y: 1)

    default:
        ()
    }

    return transform
}

// Combine a list of images with equivalent sizes.
func combineImages(_ imageViews: [UIImageView]) -> UIImage {
    // Size the canvas to the first image (which is assumed to be the same as the rest).
    UIGraphicsBeginImageContext(imageViews[0].image!.size) // swiftlint:disable:this force_unwrapping

    // Draw each image into the canvas.
    for imageView in imageViews {
        imageView.image!.draw(at: CGPoint.zero) // swiftlint:disable:this force_unwrapping
    }

    let combinedImage = UIGraphicsGetImageFromCurrentImageContext()! // swiftlint:disable:this force_unwrapping
    UIGraphicsEndImageContext()
    return combinedImage
}

func createImageFromQuadrilateral(in image: CIImage, corners: [CGPoint]) -> CIImage {
    // Find the center as the average of the corners.
    let centerSum = corners.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
    let center = CGPoint(x: centerSum.x / 4, y: centerSum.y / 4)

    // Determine the angle from corner to the center.
    let cornersAndAngles = corners.map { corner -> (CGPoint, CGFloat) in
        let distanceFromCenter = (corner.x - center.x, corner.y - center.y)
        let angle = atan2(distanceFromCenter.1, distanceFromCenter.0)
        return (corner, angle)
    }

    // Sort the corners into order around the center so that we know which corner is which.
    let sortedCorners = cornersAndAngles.sorted { $0.1 > $1.1 }.map { $0.0 }

    return createImageFromQuadrilateral(in: image, bottomLeft: sortedCorners[3], bottomRight: sortedCorners[2], topLeft: sortedCorners[0], topRight: sortedCorners[1])
}

private func createImageFromQuadrilateral(in image: CIImage, bottomLeft: CGPoint, bottomRight: CGPoint, topLeft: CGPoint, topRight: CGPoint) -> CIImage {
    let perspectiveCorrection = CIFilter(name: "CIPerspectiveCorrection")! // swiftlint:disable:this force_unwrapping
    perspectiveCorrection.setValue(image, forKey: kCIInputImageKey)
    perspectiveCorrection.setValue(CIVector(cgPoint: bottomLeft), forKey: "inputBottomLeft")
    perspectiveCorrection.setValue(CIVector(cgPoint: bottomRight), forKey: "inputBottomRight")
    perspectiveCorrection.setValue(CIVector(cgPoint: topLeft), forKey: "inputTopLeft")
    perspectiveCorrection.setValue(CIVector(cgPoint: topRight), forKey: "inputTopRight")

    return perspectiveCorrection.outputImage! // swiftlint:disable:this force_unwrapping
}

// Find the point farthest away from a point within a connected component.
// In other words, find the farthest away point reachable along non-white points.
// Note that farthest away refers to the number of non-white points traversed rather than traditional distance.
// Returns nil if the farthest point is too far away, to allow skipping large objects.
func getFarthestPointInComponent(inImage image: IndexableImage, fromPoint startingPoint: CGPoint) -> CGPoint? {
    let width = image.width
    let height = image.height

    var explored = Set<CGPoint>()
    var queue = Queue()
    queue.enqueue(startingPoint)

    // swiftlint:disable:next implicitly_unwrapped_optional
    var farthestPointSoFar: CGPoint!

    while !queue.isEmpty {
        let point = queue.dequeue()! // swiftlint:disable:this force_unwrapping
        if explored.contains(point) {
            continue
        }

        let x = roundToInt(point.x)
        let y = roundToInt(point.y)

        let westPoint = CGPoint(x: x - 1, y: y)
        if x > 0 && image.getPixel(x: x - 1, y: y).isVisible() && !explored.contains(westPoint) {
            queue.enqueue(westPoint)
        }
        let eastPoint = CGPoint(x: x + 1, y: y)
        if x < width - 1 && image.getPixel(x: x + 1, y: y).isVisible() && !explored.contains(eastPoint) {
            queue.enqueue(eastPoint)
        }
        let southPoint = CGPoint(x: x, y: y - 1)
        if y > 0 && image.getPixel(x: x, y: y - 1).isVisible() && !explored.contains(southPoint) {
            queue.enqueue(southPoint)
        }
        let northPoint = CGPoint(x: x, y: y + 1)
        if y < height - 1 && image.getPixel(x: x, y: y + 1).isVisible() && !explored.contains(northPoint) {
            queue.enqueue(northPoint)
        }

        explored.insert(point)
        farthestPointSoFar = point

        // If we've explored too much, return nil.
        // This keeps us from spending a long time dealing with large objects that are unlikely to be the scale anyways.
        if explored.count > 50_000 {
            return nil
        }
    }

    return farthestPointSoFar
}

// Starting at a point, searches around to find a non-white point, very roughly bounded in search size by maxPixelsToCheck.
// This function is written to be high performance.
// As such, some of the logic is "unrolled" in ways that are uglier but faster.
// Similarly, comparisons inside tight loops are minimized.
func searchForVisible(inImage image: IndexableImage, fromPoint startingPoint: CGPoint, checkingNoMoreThan maxPixelsToCheck: Int) -> CGPoint? {
    let width = image.width
    let height = image.height

    // We're going to spiral out from the startingPoint looking for visible points. The pattern looks like:
    //      10 11 12 13
    //  ...  9  2  3 14 // swiftlint:disable:this period_spacing
    //   23  8  1  4 15
    //   22  7  6  5 16
    //   21 20 19 18 17
    // Note the every two sides of the spiral, the side length increases by 1.
    // E.g. you go up 1, right 1, down 2, left 2, up 3, right 3, down 4...

    // Roughly how many pixels have been checked so far
    var pixelsChecked = 0
    // The current length of a spiral side (increments every two sides)
    var spiralSideLength = 1

    // The current position
    var x = roundToInt(startingPoint.x)
    var y = roundToInt(startingPoint.y)

    // Because we only do this check once per time around the spiral and because the pixels checked is approximate, the maxPixelsToCheck is approximate.
    while pixelsChecked < maxPixelsToCheck {
        // The left side of the spiral, moving north
        if x >= 0 {
            // If we're off the bottom of the image, skip up to the bottom
            var loopStart = 1
            if y < 0 {
                loopStart = 1 - y
                y = 0
            }

            for i in loopStart...spiralSideLength {
                if y >= height {
                    // If we're off the top of the image, skip to the end of this side
                    y += spiralSideLength - i + 1
                    break
                }

                if image.getPixel(x: x, y: y).isVisible() {
                    return CGPoint(x: x, y: y)
                }

                // Move up one spot
                y += 1
            }
        } else {
            // If we're off the left side of the image, skip checking this side
            y += spiralSideLength
        }

        // The top side of the spiral, moving right
        if y < height {
            // If we're off the left of the image, skip over to the left edge
            var loopStart = 1
            if x < 0 {
                loopStart = 1 - x
                x = 0
            }

            for i in loopStart...spiralSideLength {
                if x >= width {
                    // If we're off the top of the image, skip to the end of this side
                    x += spiralSideLength - i + 1
                    break
                }

                if image.getPixel(x: x, y: y).isVisible() {
                    return CGPoint(x: x, y: y)
                }

                // Move over one spot
                x += 1
            }
        } else {
            // If we're off the top side of the image, skip checking this side
            x += spiralSideLength
        }

        // We've done two sides, so increment the side length.
        spiralSideLength += 1

        // The right side of the spiral, moving south
        if x < width {
            // If we're off the top of the image, skip down to the top
            var loopStart = 1
            if y >= height {
                loopStart = y - height + 2
                y = height - 1
            }

            for i in loopStart...spiralSideLength {
                if y < 0 {
                    // If we're off the bottom of the image, skip to the end of this side
                    y -= spiralSideLength - i + 1
                    break
                }

                if image.getPixel(x: x, y: y).isVisible() {
                    return CGPoint(x: x, y: y)
                }

                // Move down one spot
                y -= 1
            }
        } else {
            // If we're off the right side of the image, skip checking this side
            y -= spiralSideLength
        }

        // The bottom side of the spiral, moving left
        if y >= 0 {
            // If we're off the right of the image, skip over to the right edge
            var loopStart = 1
            if x >= width {
                loopStart = x - width + 2
                x = width - 1
            }

            for i in loopStart...spiralSideLength {
                if x < 0 {
                    // If we're off the left of the image, skip to the end of this side
                    x -= spiralSideLength - i + 1
                    break
                }

                if image.getPixel(x: x, y: y).isVisible() {
                    return CGPoint(x: x, y: y)
                }

                // Move over one spot
                x -= 1
            }
        } else {
            // If we're off the bottom side of the image, skip checking this side
            x -= spiralSideLength
        }

        // We've done two sides, so increment the side length.
        spiralSideLength += 1

        // Quickly approximate how many pixels were checked in this circuit.
        pixelsChecked += spiralSideLength * 4
    }

    return nil
}

// Flood fills an image from a point ( https://en.wikipedia.org/wiki/Flood_fill ).
// Assumes that the starting point is "empty" (false) in the boolean image, and draws to the drawing manager.
func floodFill(image: LayeredIndexableImage, fromPoint startingPoint: CGPoint, drawingTo drawingManager: DrawingManager) {
    // This tracks what ranges are already filled in, mapping a y coordinate to a list of x ranges.
    var filledRanges = [Int: [(Int, Int)]]()
    // This is a list of points to fill from.
    var queue: Set<CGPoint> = [startingPoint]

    while !queue.isEmpty {
        // We're going to find the largest horizontal line containing this point that stays in the empty area.
        let point = queue.popFirst()! // swiftlint:disable:this force_unwrapping
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
        drawingManager.drawLine(from: CGPoint(x: leftmostX - 1, y: y), to: CGPoint(x: rightmostX + 1, y: y))

        // Mark the range as filled in so we don't come back to it.
        if filledRanges[y] != nil {
            // swiftlint:disable:next force_unwrapping
            filledRanges[y]!.append((leftmostX, rightmostX))
        } else {
            filledRanges[y] = [(leftmostX, rightmostX)]
        }
    }
}

private func isFilled(x: Int, y: Int, referringTo filledRanges: [Int: [(Int, Int)]]) -> Bool {
    guard let filledXRanges = filledRanges[y] else {
        return false
    }

    return filledXRanges.contains { filledXRange in
        x >= filledXRange.0 && x <= filledXRange.1
    }
}
