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
    // This is never directly used, but since pixelDataPointer is an UnsafePointer, we need to keep this to prevent garbage collection of the pixel data ( https://en.wikipedia.org/wiki/Garbage_collection_(computer_science) ).
    let pixelData: CFData
    // TODO: reduce memory loads by changing this to 32 bit
    let pixelDataPointer: UnsafePointer<UInt8>
    let width: Int
    let height: Int
    
    init(_ cgImage: CGImage) {
        pixelData = cgImage.dataProvider!.data!
        pixelDataPointer = CFDataGetBytePtr(pixelData)
        width = cgImage.width
        height = cgImage.height
    }
    
    func getPixel(x: Int, y: Int) -> Pixel {
        let offset = ((width * y) + x) * 4
        return Pixel(red: pixelDataPointer[offset], green: pixelDataPointer[offset + 1], blue: pixelDataPointer[offset + 2], alpha: pixelDataPointer[offset + 3])
    }
    
    // Useful for debugging: prints the image to the console with 0s for white pixels and 1s for non-white pixels.
    func printInBinary() {
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let isWhite = getPixel(x: x, y: y).isWhite()
                print(isWhite ? "0" : "1", terminator: "")
            }
            print("")
        }
    }
}
