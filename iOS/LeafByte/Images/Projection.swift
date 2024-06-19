//
//  Projection.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/6/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
import UIKit

// Represents a projection from one space to another ( https://en.wikipedia.org/wiki/Projection_(mathematics) ).
// For example, finding the matching pixel in two different spaces that have different dimensions.
final class Projection {
    let scale: Double
    let xOffset: Double
    let yOffset: Double
    let bounds: CGSize

    init(fromView view: UIView, toImageInView image: UIImage) {
        let viewSize = view.frame.size
        let imageSize = image.size

        // Work back to find how the image was scaled into the view.
        let scalingRatioForWidth = imageSize.width / viewSize.width
        let scalingRatioForHeight = imageSize.height / viewSize.height
        let scalingRatio = max(scalingRatioForWidth, scalingRatioForHeight)

        scale = Double(scalingRatio)

        xOffset = Double(imageSize.width - viewSize.width * scalingRatio) / 2
        yOffset = Double(imageSize.height - viewSize.height * scalingRatio) / 2

        bounds = image.size
    }

    init(fromProjection baseProjection: Projection, withExtraXOffset extraXOffset: Double = 0, withExtraYOffset extraYOffset: Double = 0) {
        scale = baseProjection.scale
        xOffset = baseProjection.xOffset + extraXOffset
        yOffset = baseProjection.yOffset + extraYOffset
        bounds = baseProjection.bounds
    }

    init(scale: Double, xOffset: Double, yOffset: Double, bounds: CGSize) {
        self.scale = scale
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.bounds = bounds
    }

    func project(x: Int, y: Int) -> (Int, Int) {
        let (projectedX, projectedY) = project(x: Double(x), y: Double(y))
        return (roundToInt(projectedX), roundToInt(projectedY))
    }

    func project(point: CGPoint, constrain: Bool = true) -> CGPoint {
        let (projectedX, projectedY) = project(x: point.x, y: point.y, constrain: constrain)
        return CGPoint(x: projectedX, y: projectedY)
    }

    func project(x: CGFloat, y: CGFloat, constrain: Bool = true) -> (CGFloat, CGFloat) {
        let (projectedX, projectedY) = project(x: Double(x), y: Double(y), constrain: constrain)
        return (CGFloat(projectedX), CGFloat(projectedY))
    }

    func project(x: Double, y: Double, constrain: Bool = true) -> (Double, Double) {
        // First do the projection.
        let projectedX = x * scale + xOffset
        let projectedY = y * scale + yOffset

        if !constrain {
            return (projectedX, projectedY)
        }

        // Then constrain inside the bounds.
        let constrainedX = min(max(projectedX, 0), Double(bounds.width) - 1)
        let constrainedY = min(max(projectedY, 0), Double(bounds.height) - 1)
        return (constrainedX, constrainedY)
    }
}
