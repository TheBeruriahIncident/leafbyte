//
//  TestUtils.swift
//  LeafByteTests
//
//  Created by Zoe on 8/29/24.
//  Copyright © 2024 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

func loadImage(named name: String) -> UIImage {
    let bundle = Bundle(for: LeafByteTests.self)
    guard let path = bundle.path(forResource: name, ofType: "png") else {
        fatalError("Image \(name) not found")
    }
    guard let image = UIImage(contentsOfFile: path) else {
        fatalError("Image \(name) could not be loaded")
    }
    return image
}
