//
//  Homography.swift
//  LeafByte
//
//  Created by Adam Campbell on 7/31/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Accelerate.vecLib.LinearAlgebra
import Foundation

final class Homography {
    private let H: [Double]
    
    init?(toUnitSquareFrom quadrilateral: OrientedQuadrilateral) {
        let x1=Double(quadrilateral.bottomLeft.x)
        let y1=Double(quadrilateral.bottomLeft.y)
        let x2=Double(quadrilateral.bottomRight.x)
        let y2=Double(quadrilateral.bottomRight.y)
        let x3=Double(quadrilateral.topLeft.x)
        let y3=Double(quadrilateral.topLeft.y)
        let x4=Double(quadrilateral.topRight.x)
        let y4=Double(quadrilateral.topRight.y)
        
        let x1p:Double=0
        let y1p:Double=0
        let x2p:Double=1
        let y2p:Double=0
        let x3p:Double=0
        let y3p:Double=1
        let x4p:Double=1
        let y4p:Double=1
        
        let A: [Double] = [
            -x1, -y1, -1, 0, 0, 0, x1*x1p, y1*x1p, x1p,
            0, 0, 0, -x1, -y1, -1, x1*y1p, y1*y1p, y1p,
            -x2, -y2, -1, 0, 0, 0, x2*x2p, y2*x2p, x2p,
            0, 0, 0, -x2, -y2, -1, x2*y2p, y2*y2p, y2p,
            -x3, -y3, -1, 0, 0, 0, x3*x3p, y3*x3p, x3p,
            0, 0, 0, -x3, -y3, -1, x3*y3p, y3*y3p, y3p,
            -x4, -y4, -1, 0, 0, 0, x4*x4p, y4*x4p, x4p,
            0, 0, 0, -x4, -y4, -1, x4*y4p, y4*y4p, y4p,
            0,0,0,0,0,0,0,0,1
        ]
        print(A)
        let matA = la_matrix_from_double_buffer(A, 9, 9, 9, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        let b: [Double] = [
            0,0,0,0,0,0,0,0,1
        ]
        let vecB = la_matrix_from_double_buffer(b, 9, 1, 1, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        let vecCj = la_solve(matA, vecB)
        var cj: [Double] = Array(repeating: 0.0, count: 9)
        
        let status = la_matrix_to_double_buffer(&cj, 1, vecCj)
        if status == la_status_t(LA_SUCCESS) {
            H = cj
        } else {
            return nil
        }
    }
    
    init?(fromUnitSquareTo quadrilateral: OrientedQuadrilateral) {
        let x1p=Double(quadrilateral.bottomLeft.x)
        let y1p=Double(quadrilateral.bottomLeft.y)
        let x2p=Double(quadrilateral.bottomRight.x)
        let y2p=Double(quadrilateral.bottomRight.y)
        let x3p=Double(quadrilateral.topLeft.x)
        let y3p=Double(quadrilateral.topLeft.y)
        let x4p=Double(quadrilateral.topRight.x)
        let y4p=Double(quadrilateral.topRight.y)
        
        let x1:Double=0
        let y1:Double=0
        let x2:Double=1
        let y2:Double=0
        let x3:Double=0
        let y3:Double=1
        let x4:Double=1
        let y4:Double=1
        
        let A: [Double] = [
            -x1, -y1, -1, 0, 0, 0, x1*x1p, y1*x1p, x1p,
            0, 0, 0, -x1, -y1, -1, x1*y1p, y1*y1p, y1p,
            -x2, -y2, -1, 0, 0, 0, x2*x2p, y2*x2p, x2p,
            0, 0, 0, -x2, -y2, -1, x2*y2p, y2*y2p, y2p,
            -x3, -y3, -1, 0, 0, 0, x3*x3p, y3*x3p, x3p,
            0, 0, 0, -x3, -y3, -1, x3*y3p, y3*y3p, y3p,
            -x4, -y4, -1, 0, 0, 0, x4*x4p, y4*x4p, x4p,
            0, 0, 0, -x4, -y4, -1, x4*y4p, y4*y4p, y4p,
            0,0,0,0,0,0,0,0,1
        ]
        let matA = la_matrix_from_double_buffer(A, 9, 9, 9, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        let b: [Double] = [
            0,0,0,0,0,0,0,0,1
        ]
        let vecB = la_matrix_from_double_buffer(b, 9, 1, 1, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        
        let vecCj = la_solve(matA, vecB)
        var cj: [Double] = Array(repeating: 0.0, count: 9)
        
        let status = la_matrix_to_double_buffer(&cj, 1, vecCj)
        if status == la_status_t(LA_SUCCESS) {
            H = cj
        } else {
            return nil
        }
    }
    
    func project(point: CGPoint) -> CGPoint {
        let x = point.x * CGFloat(H[0]) + point.y * CGFloat(H[1]) + CGFloat(H[2])
        let y = point.x * CGFloat(H[3]) + point.y * CGFloat(H[4]) + CGFloat(H[5])
        let scale = point.x * CGFloat(H[6]) + point.y * CGFloat(H[7]) + CGFloat(H[8])
        
        return CGPoint(x: x/scale, y: y/scale)
    }
}
