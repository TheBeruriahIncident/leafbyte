//
//  DrawingManager.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class DrawingManager {
    // See "Points and Pixels" at https://www.raywenderlich.com/162315/core-graphics-tutorial-part-1-getting-started for why this exists.
    private static let pixelOffset = Float(0.5)
    
    private let context: CGContext
    private let projection: Projection
    
    init(withCanvasSize canvasSize: CGSize, withProjection baseProjection: Projection = Projection.identity) {
        UIGraphicsBeginImageContext(canvasSize)
        context = UIGraphicsGetCurrentContext()!
        // Make all the drawing precise.
        // This avoids our drawn lines looking blurry (since you can zoom in).
        // It looks particularly bad for the shaded in holes, since the alternating blurred lines look like stripes.
        context.interpolationQuality = CGInterpolationQuality.high
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        self.projection = Projection(fromProjection: baseProjection, withExtraXOffset: DrawingManager.pixelOffset, withExtraYOffset: DrawingManager.pixelOffset)
    }
    
    // TODO: don't expose this?
    func getContext() -> CGContext {
        return context
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        let projectedFromPoint = projection.project(x: Float(fromPoint.x), y: Float(fromPoint.y))
        
        // A line from a point to itself doesn't show up, so draw a 1 pixel rectangle.
        if fromPoint == toPoint {
            context.addRect(CGRect(x: CGFloat(projectedFromPoint.0), y: CGFloat(projectedFromPoint.1), width: CGFloat(1.0), height: CGFloat(1.0)))
        }
        
        let projectedToPoint = projection.project(x: Float(toPoint.x), y: Float(toPoint.y))
        
        context.move(to: CGPoint(x: CGFloat(projectedFromPoint.0), y: CGFloat(projectedFromPoint.1)))
        context.addLine(to: CGPoint(x: CGFloat(projectedToPoint.0), y: CGFloat(projectedToPoint.1)))
        context.strokePath()
    }
    
    func finish(imageView: UIImageView, addToPreviousImage: Bool = false) {
        if addToPreviousImage {
            imageView.image?.draw(in: CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height))
        }
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
}
