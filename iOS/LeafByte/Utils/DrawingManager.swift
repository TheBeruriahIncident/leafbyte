//
//  DrawingManager.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

// This class manages drawing on a CGContext.
final class DrawingManager {
    static let lightGreen = UIColor(red: 0.780392156, green: 1.0, blue: 0.5647058823, alpha: 1.0)
    static let darkGreen = UIColor(red: 0.13, green: 1.0, blue: 0.13, alpha: 1.0)
    static let red = UIColor(red: 1.0, green: 0.09677419355, blue: 0.3806451613, alpha: 1.0)
    
    // See "Points and Pixels" at https://www.raywenderlich.com/162315/core-graphics-tutorial-part-1-getting-started for why this exists.
    private static let pixelOffset = 0.5
    
    let context: CGContext
    
    private let projection: Projection
    private let canvasSize: CGSize
    
    init(withCanvasSize canvasSize: CGSize, withProjection baseProjection: Projection? = nil) {
        self.canvasSize = canvasSize
        UIGraphicsBeginImageContext(canvasSize)
        context = UIGraphicsGetCurrentContext()!
        // Make all the drawing precise.
        // This avoids our drawn lines looking blurry (since you can zoom in).
        // It looks particularly bad for the shaded in holes, since the alternating blurred lines look like stripes.
        context.interpolationQuality = CGInterpolationQuality.high
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        if baseProjection == nil {
            self.projection = Projection(scale: 1, xOffset: DrawingManager.pixelOffset, yOffset: DrawingManager.pixelOffset, bounds: canvasSize)
        } else {
            self.projection = Projection(fromProjection: baseProjection!, withExtraXOffset: DrawingManager.pixelOffset, withExtraYOffset: DrawingManager.pixelOffset)
        }
    }
    
    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint) {
        let projectedFromPoint = projection.project(point: fromPoint)
        
        // A line from a point to itself doesn't show up, so draw a 1 pixel rectangle.
        if fromPoint == toPoint {
            context.addRect(CGRect(origin: projectedFromPoint, size: CGSize(width: 1.0, height: 1.0)))
        }
        
        let projectedToPoint = projection.project(point: toPoint)
        
        context.move(to: projectedFromPoint)
        context.addLine(to: projectedToPoint)
        context.strokePath()
    }
    
    func drawLeaf(atPoint point: CGPoint) {
        let projectedPoint = projection.project(point: point)
        
        context.setFillColor(DrawingManager.lightGreen.cgColor)
        
        let starPath = UIBezierPath()
        let start = CGPoint(x: 50, y: 120)
        let otherPoint = CGPoint(x: 120, y: 50)
        starPath.move(to: start)
        starPath.addCurve(to: otherPoint, controlPoint1: CGPoint(x: 50, y: 80), controlPoint2: CGPoint(x: 70, y: 60))
        starPath.addCurve(to: start, controlPoint1: CGPoint(x: 110, y: 100), controlPoint2: CGPoint(x: 90, y: 120))
        starPath.close()
        
        starPath.fill()
    }
    
    func drawX(at point: CGPoint, size: CGFloat) {
        let projectedPoint = projection.project(point: point)
        context.setLineCap(.round)
        
        context.move(to: projectedPoint.applying(CGAffineTransform(translationX: -size, y: -size)))
        context.addLine(to: projectedPoint.applying(CGAffineTransform(translationX: size, y: size)))
        
        context.move(to: projectedPoint.applying(CGAffineTransform(translationX: -size, y: size)))
        context.addLine(to: projectedPoint.applying(CGAffineTransform(translationX: size, y: -size)))
        
        context.strokePath()
    }
    
    func finish(imageView: UIImageView, addToPreviousImage: Bool = false) {
        if addToPreviousImage {
            imageView.image?.draw(in: CGRect(origin: CGPoint.zero, size: canvasSize))
        }
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
}
