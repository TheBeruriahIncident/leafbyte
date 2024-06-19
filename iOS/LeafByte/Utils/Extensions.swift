//
//  Extensions.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/6/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
import UIKit

extension CGPoint: Hashable {
    // This allows CGPoints to be used in sets.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.x)
        hasher.combine(self.y)
    }

    // Calculate the distance between two points ( https://en.wikipedia.org/wiki/Euclidean_distance ).
    public func distance(to other: CGPoint) -> CGFloat {
        return pow(pow(self.x - other.x, 2) + pow(self.y - other.y, 2), 0.5)
    }
}

public extension NSMutableAttributedString {
    func addLink(text: String, url: String) -> NSMutableAttributedString {
        let foundRange = self.mutableString.range(of: text)
        self.addAttribute(.link, value: url, range: foundRange)

        return self
    }
}
