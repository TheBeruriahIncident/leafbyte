//
//  IndexableImage.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/4/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics

// An image that allows transparently looking up pixels.
final class IndexableImage {
    private static let bytesPerPixel = 4

    // This is never directly used, but since pixelDataPointer is an UnsafePointer, we need to keep this to prevent garbage collection of the pixel data ( https://en.wikipedia.org/wiki/Garbage_collection_(computer_science) ).
    private let pixelData: CFData
    private let pixelDataPointer: UnsafePointer<UInt8>
    private let bytesPerRow: Int

    let width: Int
    let height: Int

    init(_ cgImage: CGImage) {
        pixelData = cgImage.dataProvider!.data!
        pixelDataPointer = CFDataGetBytePtr(pixelData)
        bytesPerRow = cgImage.bytesPerRow
        width = cgImage.width
        height = cgImage.height
    }

    func getPixel(x: Int, y: Int) -> Pixel {
        let offset = bytesPerRow * y + Self.bytesPerPixel * x
        return Pixel(red: pixelDataPointer[offset], green: pixelDataPointer[offset + 1], blue: pixelDataPointer[offset + 2], alpha: pixelDataPointer[offset + 3])
    }

    // Useful for debugging: prints the image to the console as 1s and 0s.
    func printInBinary() {
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let pixel = getPixel(x: x, y: y)

                // Invisible pixels are 0s, visible pixels are 1s.
                print(pixel.isVisible() ? "1" : "0", terminator: "")
            }
            print("")
        }
    }
}
