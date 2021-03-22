//
//  DrawingManager.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/6/18.
//  Copyright © 2018 Zoe Getman-Pickering. All rights reserved.
//

import CoreGraphics
import UIKit

// This class manages drawing on a CGContext.
final class DrawingManager {
    static let lightGreen = UIColor(red: 0.780392156, green: 1.0, blue: 0.5647058823, alpha: 1.0)
    static let darkGreen = UIColor(red: 0.13, green: 1.0, blue: 0.13, alpha: 1.0)
    static let lightRed = UIColor(red: 1.0, green: 0.7529411765, blue: 0.7960784314, alpha: 1.0)
    static let darkRed = UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
    
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
    
    func drawLeaf(atPoint point: CGPoint, size: CGFloat) {
        context.setAlpha(0.5)
        
        // This leaf is drawn with respect to the point where the petiole begins.
        let projectedPoint = projection.project(point: point)
        
        // Draw dot at the specied point to make it clearer what's being marked.
        let dotSize = size / 13
        context.setLineCap(.round)
        context.setStrokeColor(DrawingManager.darkRed.cgColor)
        context.setLineWidth(dotSize + 1)
        context.addEllipse(in: CGRect(origin: CGPoint(x: projectedPoint.x - dotSize, y: projectedPoint.y - dotSize), size: CGSize(width: dotSize * 2, height: dotSize * 2)))
        context.strokePath()
        
        // Draw black outline for the petiole.
        let petioleLength = size * 2 / 7
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1.5)
        context.setLineCap(.square)
        context.move(to: CGPoint(x: projectedPoint.x + 1, y: projectedPoint.y - 1))
        context.addLine(to: CGPoint(x: projectedPoint.x + 0.95 * petioleLength, y: projectedPoint.y - 0.95 * petioleLength))
        context.strokePath()
        
        // Draw dark outline for the leaf.
        let startOfLeaf = CGPoint(x: projectedPoint.x + petioleLength, y: projectedPoint.y - petioleLength)
        context.setFillColor(DrawingManager.darkRed.cgColor)
        drawLeafOutline(leafBase: startOfLeaf, withSize: size, withOffset: 2)
        
        // Draw light "filling" of the leaf.
        context.setFillColor(DrawingManager.lightRed.cgColor)
        drawLeafOutline(leafBase: startOfLeaf, withSize: size)
        
        // Draw petiole and midrib.
        context.setStrokeColor(DrawingManager.darkRed.cgColor)
        context.setLineWidth(1.25)
        context.setLineCap(.round)
        context.move(to: projectedPoint)
        context.addLine(to: CGPoint(x: projectedPoint.x + 3 * petioleLength, y: projectedPoint.y - 3 * petioleLength))
        context.strokePath()
        
        context.setAlpha(1)
    }
    
    private func drawLeafOutline(leafBase: CGPoint, withSize size: CGFloat, withOffset offset: CGFloat = 0) {
        let leafTip = CGPoint(x: leafBase.x + size, y: leafBase.y - size)
        let controlPoint1 = CGPoint(x: leafBase.x + size * 2 / 7, y: leafBase.y - size * 2 / 7)
        let controlPoint2 = CGPoint(x: leafBase.x + size * 4 / 7, y: leafBase.y - size * 4 / 7)
        let deformation = size * 2 / 7
        
        let leafOutline = UIBezierPath()
        leafOutline.move(to: CGPoint(x: leafBase.x - offset, y: leafBase.y + offset))
        leafOutline.addCurve(to: CGPoint(x: leafTip.x + offset, y: leafTip.y - offset), controlPoint1: CGPoint(x: controlPoint1.x - deformation - offset, y: controlPoint1.y - deformation - offset), controlPoint2: CGPoint(x: controlPoint2.x - deformation - offset, y: controlPoint2.y - deformation - offset))
        leafOutline.addCurve(to: CGPoint(x: leafBase.x - offset, y: leafBase.y + offset), controlPoint1: CGPoint(x: controlPoint2.x + deformation + offset, y: controlPoint2.y + deformation + offset), controlPoint2: CGPoint(x: controlPoint1.x + deformation + offset, y: controlPoint1.y + deformation + offset))
        leafOutline.close()
        leafOutline.fill()
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
