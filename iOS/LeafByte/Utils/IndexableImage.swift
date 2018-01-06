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
    private static let bytesPerPixel = 4
    
    // This is never directly used, but since pixelDataPointer is an UnsafePointer, we need to keep this to prevent garbage collection of the pixel data ( https://en.wikipedia.org/wiki/Garbage_collection_(computer_science) ).
    private let pixelData: CFData
    // TODO: reduce memory loads by changing this to 32 bit
    private let pixelDataPointer: UnsafePointer<UInt8>
    private let bytesPerRow: Int
    
    private let projection: Projection?
    
    let width: Int
    let height: Int
    
    init(_ cgImage: CGImage, withProjection projection: Projection? = nil) {
        pixelData = cgImage.dataProvider!.data!
        pixelDataPointer = CFDataGetBytePtr(pixelData)
        bytesPerRow = cgImage.bytesPerRow
        self.projection = projection
        width = cgImage.width
        height = cgImage.height
    }
    
    func getPixel(x: Int, y: Int) -> Pixel {
        var xToUse: Int!
        var yToUse: Int!
        if projection != nil {
            let (projectedX, projectY) = projection!.project(x: x, y: y)
            // Swift compiler can't understand the direct assignment.
            (xToUse, yToUse) = (projectedX, projectY)
        } else {
            (xToUse, yToUse) = (x, y)
        }
        
        let offset = bytesPerRow * yToUse + IndexableImage.bytesPerPixel * xToUse
        return Pixel(red: pixelDataPointer[offset], green: pixelDataPointer[offset + 1], blue: pixelDataPointer[offset + 2], alpha: pixelDataPointer[offset + 3])
    }
    
    // Useful for debugging: prints the image to the console as 1s and 0s, supporting different modes of what pixels become 1s vs 0s.
    func printInBinary(mode: BinaryPrintingMode = .blackAndWhite) {
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let pixel = getPixel(x: x, y: y)
                
                var isZero: Bool!
                switch mode {
                case .blackAndWhite:
                    // White pixels are 0s, non-white pixels are 1s.
                    isZero = pixel.isWhite()
                case .visible:
                    // Invisible pixels are 0s, visible pixels are 1s.
                    isZero = pixel.isInvisible()
                }
                
                print(isZero ? "0" : "1", terminator: "")
            }
            print("")
        }
    }
    
    enum BinaryPrintingMode {
        case blackAndWhite, visible
    }
}
