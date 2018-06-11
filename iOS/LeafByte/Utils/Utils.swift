//
//  Utils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/23/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import Foundation

func roundToInt(_ number: Double, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return Int(number.rounded(rule))
}

func roundToInt(_ number: Float, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return roundToInt(Double(number), rule: rule)
}

func roundToInt(_ number: CGFloat, rule: FloatingPointRoundingRule = .toNearestOrEven) -> Int {
    return roundToInt(Float(number), rule: rule)
}

func hash(_ a: AnyHashable, _ b: AnyHashable) -> Int {
    return a.hashValue &* 31 &+ b.hashValue
}
