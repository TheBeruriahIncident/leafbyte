//
//  Pixel.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

// A representation of a single pixel.
struct Pixel: Equatable {
    private static let white = Pixel(red: 255, green: 255, blue: 255, alpha: 255)
    
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
    
    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    func isVisible() -> Bool {
        return self.alpha != 0
    }
    
    func isInvisible() -> Bool {
        return self.alpha == 0
    }
    
    func isWhite() -> Bool {
        return self == Pixel.white
    }
    
    func isNonWhite() -> Bool {
        return self != Pixel.white
    }
    
    // MARK: Equatable overrides
    
    static func == (lhs: Pixel, rhs: Pixel) -> Bool {
        return lhs.red == rhs.red
            && lhs.green == rhs.green
            && lhs.blue == rhs.blue
            && lhs.alpha == rhs.alpha
    }
}
