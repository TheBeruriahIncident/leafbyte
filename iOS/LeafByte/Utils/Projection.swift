//
//  Projection.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit

// Represents a projection from one space to another ( https://en.wikipedia.org/wiki/Projection_(mathematics) ).
// For example, finding the matching pixel in two different spaces that have different dimensions.
class Projection {
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
    
    func project(x: Int, y: Int) -> (Int, Int) {
        let projectedX = Int(Float(x) * xScale + xOffset)
        let projectedY = Int(Float(y) * yScale + yOffset)
        return (projectedX, projectedY)
    }
}
