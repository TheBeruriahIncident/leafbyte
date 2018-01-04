//
//  IndexableImage.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics

// An image that allows transparently looking up pixels.
class IndexableImage {
    // TODO: reduce memory loads by changing this to 32 bit
    let pixelData: UnsafePointer<UInt8>
    let width: Int
    let height: Int
    
    init(_ cgImage: CGImage) {
        pixelData = CFDataGetBytePtr(cgImage.dataProvider!.data!)
        width = cgImage.width
        height = cgImage.height
    }
    
    func getPixel(x: Int, y: Int) -> Pixel {
        let offset = ((width * y) + x) * 4
        return Pixel(red: pixelData[offset], green: pixelData[offset + 1], blue: pixelData[offset + 2], alpha: pixelData[offset + 3])
    }
    
    // Useful for debugging
    func printInBinary() {
        for x in 0...height - 1 {
            for y in 0...width - 1 {
                let isWhite = getPixel(x: x, y: y).isWhite()
                print(isWhite ? "0" : "1", terminator: "")
            }
            print("")
        }
    }
}
