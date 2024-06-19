//
//  Pixel.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/4/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

// A representation of a single pixel.
struct Pixel: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    func isVisible() -> Bool {
        self.alpha != 0
    }

    func isInvisible() -> Bool {
        self.alpha == 0
    }

    // MARK: Equatable overrides

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.red == rhs.red
            && lhs.green == rhs.green
            && lhs.blue == rhs.blue
            && lhs.alpha == rhs.alpha
    }
}
