//
//  Extensions.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics

extension CGPoint: Hashable {
    // This allows CGPoints to be used in sets.
    public var hashValue: Int {
        // This is a classic hash ( https://stackoverflow.com/questions/299304/why-does-javas-hashcode-in-string-use-31-as-a-multiplier ).
        // Note the &s to get wraparound behavior ( https://en.wikipedia.org/wiki/Integer_overflow ).
        return LeafByte.hash(self.x, self.y)
    }
    
    // Calculate the distance between two points ( https://en.wikipedia.org/wiki/Euclidean_distance ).
    public func distance(to other: CGPoint) -> CGFloat {
        return pow(pow(self.x - other.x, 2) + pow(self.y - other.y, 2), 0.5)
    }
}
