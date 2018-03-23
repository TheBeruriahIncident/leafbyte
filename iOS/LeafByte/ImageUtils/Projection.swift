//
//  Projection.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

// Represents a projection from one space to another ( https://en.wikipedia.org/wiki/Projection_(mathematics) ).
// For example, finding the matching pixel in two different spaces that have different dimensions.
class Projection {
    static let identity = Projection(xScale: 1, yScale: 1, xOffset: 0, yOffset: 0)
    
    let xScale: Float
    let yScale: Float
    let xOffset: Float
    let yOffset: Float
    
    init(fromImageInView image: UIImage, toView view: UIView ) {
        let viewSize = view.frame.size
        let imageSize = image.size
        
        // Work back to find how the image was scaled into the view.
        let scalingRatioForWidth = viewSize.width / imageSize.width
        let scalingRatioForHeight = viewSize.height / imageSize.height
        let scalingRatio = min(scalingRatioForWidth, scalingRatioForHeight)
        
        xScale = Float(scalingRatio)
        yScale = Float(scalingRatio)
        
        xOffset = Float(viewSize.width - imageSize.width * scalingRatio) / 2
        yOffset = Float(viewSize.height - imageSize.height * scalingRatio) / 2
    }
    
    init(invertProjection baseProjection: Projection) {
        xScale = 1 / baseProjection.xScale
        yScale = 1 / baseProjection.yScale
        xOffset = -baseProjection.xOffset / baseProjection.xScale
        yOffset = -baseProjection.yOffset / baseProjection.yScale
    }
    
    init(fromProjection baseProjection: Projection, withExtraXOffset extraXOffset: Float = 0, withExtraYOffset extraYOffset: Float = 0) {
        xScale = baseProjection.xScale
        yScale = baseProjection.yScale
        xOffset = baseProjection.xOffset + extraXOffset
        yOffset = baseProjection.yOffset + extraYOffset
    }
    
    init(xScale: Float, yScale: Float, xOffset: Float, yOffset: Float) {
        self.xScale = xScale
        self.yScale = yScale
        self.xOffset = xOffset
        self.yOffset = yOffset
    }
    
    func project(x: Int, y: Int) -> (Int, Int) {
        let (projectedX, projectedY) = project(x: Float(x), y: Float(y))
        return (Int(round(projectedX)), Int(round(projectedY)))
    }
    
    func project(point: CGPoint) -> CGPoint {
        let (projectedX, projectedY) = project(x: Float(point.x), y: Float(point.y))
        return CGPoint(x: CGFloat(projectedX), y: CGFloat(projectedY))
    }
    
    func project(x: Float, y: Float) -> (Float, Float) {
        let projectedX = x * xScale + xOffset
        let projectedY = y * yScale + yOffset
        return (projectedX, projectedY)
    }
}
