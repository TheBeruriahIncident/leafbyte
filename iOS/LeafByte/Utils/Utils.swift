//
//  Utils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/23/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import Foundation

func roundToInt(_ number: Double) -> Int {
    return Int(round(number))
}

func roundToInt(_ number: Float) -> Int {
    return roundToInt(Double(number))
}

func roundToInt(_ number: CGFloat) -> Int {
    return roundToInt(Float(number))
}
