//
//  GeometryUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 7/19/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

struct OrientedQuadrilateral {
    let bottomLeft: CGPoint
    let bottomRight: CGPoint
    let topLeft: CGPoint
    let topRight: CGPoint
    
    init(bottomLeft: CGPoint, bottomRight: CGPoint, topLeft: CGPoint, topRight: CGPoint) {
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.topLeft = topLeft
        self.topRight = topRight
    }
}


func expand(orientedQuadrilateral quadrilateral: OrientedQuadrilateral, withinBounds bounds: CGRect) -> OrientedQuadrilateral {
    let (a, b) = expandLineSegmentToBounds(linePoint1: quadrilateral.bottomLeft, linePoint2: quadrilateral.topRight, bounds: bounds)
    let (c, d) = expandLineSegmentToBounds(linePoint1: quadrilateral.bottomRight, linePoint2: quadrilateral.topLeft, bounds: bounds)
    
    let center = findIntersection(line1Point1: quadrilateral.bottomLeft, line1Point2: quadrilateral.topRight, line2Point1: quadrilateral.bottomRight, line2Point2: quadrilateral.topLeft)
    
    let distances = [
        center.distance(to: a) / center.distance(to: quadrilateral.bottomLeft),
        center.distance(to: b) / center.distance(to: quadrilateral.topRight),
        center.distance(to: c) / center.distance(to: quadrilateral.bottomRight),
        center.distance(to: d) / center.distance(to: quadrilateral.topLeft),
    ]
    let distanceWeCanExpandBy = distances.min()!
    
    let homo = Homography(toUnitSquareFrom: quadrilateral)
    let test1 = homo!.project(point: quadrilateral.bottomLeft)
    let test2 = homo!.project(point: quadrilateral.topRight)
    let test3 = homo!.project(point: quadrilateral.bottomRight)
    let test4 = homo!.project(point: quadrilateral.topLeft)
    
    let a2 = homo!.project(point: a)
    let b2 = homo!.project(point: b)
    let c2 = homo!.project(point: c)
    let d2 = homo!.project(point: d)
    
    let distancesOut = [a2.distance(to: CGPoint(x: 0, y: 0)), b2.distance(to: CGPoint(x: 1, y: 1)),
                        c2.distance(to: CGPoint(x: 1, y: 0)), d2.distance(to: CGPoint(x: 0, y: 1))]
    let distanceOut = distancesOut.min()!
    //a2+b2=c2, this is c
    //sqrt(2a2)=c
    let offset = distanceOut / sqrt(2)
    
    let homo2 = Homography(fromUnitSquareTo: quadrilateral)
    let a2p = CGPoint(x: a2.x - offset, y: a2.y - offset)
    let b2p = CGPoint(x: b2.x + offset, y: b2.y + offset)
    let c2p = CGPoint(x: c2.x + offset, y: c2.y - offset)
    let d2p = CGPoint(x: d2.x - offset, y: d2.y + offset)
    
    let ap = homo2!.project(point: a2p)
    let bp = homo2!.project(point: b2p)
    let cp = homo2!.project(point: c2p)
    let dp = homo2!.project(point: d2p)
    
    //return OrientedQuadrilateral(bottomLeft: ap, bottomRight: cp, topLeft: dp, topRight: bp)
    
    // TODO: DEAL WITH BEING ON THE EDGE??
//    let distanceToExpandBy = max(0, distanceWeCanExpandBy - 1)
    
    return expand(orientedQuadrilateral: quadrilateral, byDistance: distanceWeCanExpandBy, fromCenter: center);
}

private func expand(orientedQuadrilateral quadrilateral: OrientedQuadrilateral, byDistance distance: CGFloat, fromCenter center: CGPoint) -> OrientedQuadrilateral {
    let a = expandLineSegmentByDistanceOnEachSide(linePoint1: quadrilateral.bottomLeft, linePoint2: quadrilateral.topRight, expansionDistance: distance, fromCenter: center)
    let b = expandLineSegmentByDistanceOnEachSide(linePoint1: quadrilateral.bottomRight, linePoint2: quadrilateral.topLeft, expansionDistance: distance, fromCenter: center)
    
    return OrientedQuadrilateral(bottomLeft: a.0, bottomRight: b.0, topLeft: b.1, topRight: a.1)
}

private func expandLineSegmentByDistanceOnEachSide(linePoint1: CGPoint, linePoint2: CGPoint, expansionDistance: CGFloat, fromCenter center: CGPoint) -> (CGPoint, CGPoint) {
    let expandedLinePoint1 = center + expansionDistance * (linePoint1 - center)
    let expandedLinePoint2 = center + expansionDistance * (linePoint2 - center)
    
    return (expandedLinePoint1, expandedLinePoint2)
}

private func expandLineSegmentToBounds(linePoint1: CGPoint, linePoint2: CGPoint, bounds: CGRect) -> (CGPoint, CGPoint) {
    // Treat the line segment as a line and find all the places it intersects the lines formed by the edges of the bounds, as those are candidates for the limit to expansion.
    var candidatePoints = [CGPoint]()
    
    //
    if linePoint1.x != linePoint2.x {
        candidatePoints.append(findPointGivenXOnLine(linePoint1: linePoint1, linePoint2: linePoint2, x: 0))
        candidatePoints.append(findPointGivenXOnLine(linePoint1: linePoint1, linePoint2: linePoint2, x: bounds.width))
    }
    if linePoint1.y != linePoint2.y {
        candidatePoints.append(findPointGivenYOnLine(linePoint1: linePoint1, linePoint2: linePoint2, y: 0))
        candidatePoints.append(findPointGivenYOnLine(linePoint1: linePoint1, linePoint2: linePoint2, y: bounds.height))
    }
    
    // Some of the points are on the side of point 1 and some on the side of point 2; separate them.
    var point1CandidatePoints = [CGPoint]()
    var point2CandidatePoints = [CGPoint]()
    candidatePoints.forEach { candidatePoint in
        if candidatePoint.distance(to: linePoint1) < candidatePoint.distance(to: linePoint2) {
            point1CandidatePoints.append(candidatePoint)
        } else {
            point2CandidatePoints.append(candidatePoint)
        }
    }
    
    // The closest point is the point where the line segment would go out of bounds.
    let expandedLinePoint1 = point1CandidatePoints.map { (linePoint1.distance(to: $0), $0) }.sorted(by: { $0.0 < $1.0 }).first!.1;
    let expandedLinePoint2 = point2CandidatePoints.map { (linePoint2.distance(to: $0), $0) }.sorted(by: { $0.0 < $1.0 }).first!.1;
    
    return (expandedLinePoint1, expandedLinePoint2)
}


private func findPointGivenXOnLine(linePoint1: CGPoint, linePoint2: CGPoint, x: CGFloat) -> CGPoint {
    // Calculated using the two-point line formula ( https://en.wikipedia.org/wiki/Linear_equation#Two-point_form ).
    return CGPoint(x: x, y: findSlope(linePoint1: linePoint1, linePoint2: linePoint2) * (x - linePoint1.x) + linePoint1.y)
}

private func findPointGivenYOnLine(linePoint1: CGPoint, linePoint2: CGPoint, y: CGFloat) -> CGPoint {
    // Calculated using the two-point line formula ( https://en.wikipedia.org/wiki/Linear_equation#Two-point_form ).
    return CGPoint(x: (y - linePoint1.y) / findSlope(linePoint1: linePoint1, linePoint2: linePoint2) + linePoint1.x, y: y)
}

private func findSlope(linePoint1: CGPoint, linePoint2: CGPoint) -> CGFloat {
    return (linePoint2.y - linePoint1.y) / (linePoint2.x - linePoint1.x)
}

private func findIntersection(line1Point1: CGPoint, line1Point2: CGPoint, line2Point1: CGPoint, line2Point2: CGPoint) -> CGPoint {
    
    // TODO: CRAP, div0
    let line1Slope = (line1Point2.y - line1Point1.y) / (line1Point2.x - line1Point1.x)
    let line2Slope = (line2Point2.y - line2Point1.y) / (line2Point2.x - line2Point1.x)
    
    // Derived from point-point line equations.
    let intersectionX = (line1Slope * line1Point2.x - line1Point2.y - line2Slope * line2Point2.x + line2Point2.y) / (line1Slope - line2Slope)
    let intersectionY = line1Slope * (intersectionX - line1Point2.x) + line1Point2.y
    
    return CGPoint(x: intersectionX, y: intersectionY)
}
