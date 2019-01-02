//
//  Extensions.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

extension CGPoint: Hashable {
    // This allows CGPoints to be used in sets.
    public var hashValue: Int {
        return LeafByte.hash(self.x, self.y)
    }
    
    // Calculate the distance between two points ( https://en.wikipedia.org/wiki/Euclidean_distance ).
    public func distance(to other: CGPoint) -> CGFloat {
        return pow(pow(self.x - other.x, 2) + pow(self.y - other.y, 2), 0.5)
    }
}

extension NSMutableAttributedString {
    public func addLink(text: String, url: String) -> NSMutableAttributedString {
        let foundRange = self.mutableString.range(of: text)
        self.addAttribute(.link, value: url, range: foundRange)
        
        return self
    }
}
