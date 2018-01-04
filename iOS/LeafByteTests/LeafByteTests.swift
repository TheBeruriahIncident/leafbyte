//
//  LeafByteTests.swift
//  LeafByteTests
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import XCTest
@testable import LeafByte

class LeafByteTests: XCTestCase {
    func testThresholdFilter() {        
        let image = loadImage(named: "leafWithScale")
        
        var thresholdedCiImage: CIImage!
        self.measure {
            let filter = ThresholdingFilter()
            filter.setInputImage(image)
            thresholdedCiImage = filter.outputImage
        }
        
        let indexableImage = IndexableImage(ciToCgImage(thresholdedCiImage))
        
        indexableImage.printInBinary()
        
        XCTAssert(indexableImage.getPixel(x: 5, y: 5).isWhite())
        XCTAssert(!indexableImage.getPixel(x: 1200, y: 1200).isWhite())
    }
    
    private func loadImage(named name: String) -> UIImage {
        let bundle = Bundle(for: type(of: self))
        guard let path = bundle.path(forResource: name, ofType: "jpg") else {
            fatalError("Image \(name) not found")
        }
        guard let image = UIImage(contentsOfFile: path) else {
            fatalError("Image \(name) could not be loaded")
        }
        return image
    }
}
