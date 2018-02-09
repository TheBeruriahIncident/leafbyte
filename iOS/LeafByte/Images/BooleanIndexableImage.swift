//
//  BooleanIndexableImage.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/6/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

// This image combines multiple indexable images along with functions that make those images boolean.
// The final image is effectively the sum of those other boolean images.
class BooleanIndexableImage {
    let width: Int
    let height: Int
    
    var imagesWithConvertors = [(IndexableImage, (Pixel) -> Bool)]()
    
    init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    func addImage(_ image: IndexableImage, withPixelToBoolConversion convertor: @escaping (Pixel) -> Bool) {
        imagesWithConvertors.append((image, convertor))
    }
    
    func getPixel(x: Int, y: Int) -> Bool {
        return getLayerWithPixel(x: x, y: y) > -1
    }
    
    // Finds the first image layer which is true, or -1 if no layers are true.
    func getLayerWithPixel(x: Int, y: Int) -> Int {
        for (index, imageWithConvertor) in imagesWithConvertors.enumerated() {
            let (image, convertor) = imageWithConvertor
            if convertor(image.getPixel(x: x, y: y)) {
                return index
            }
        }
        
        return -1
    }
    
    // Useful for debugging: prints the image to the console as 1s and 0s, supporting different modes of what pixels become 1s vs 0s.
    func printInBinary() {
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                print(getPixel(x: x, y: y) ? "1" : "0", terminator: "")
            }
            print("")
        }
    }
}
