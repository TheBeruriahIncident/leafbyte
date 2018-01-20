//
//  SerializationUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/19/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

func serialize(settings: Settings, image: UIImage, percentEaten: String, leafAreaInCm2: String?, eatenAreaInCm2: String?) {
    switch settings.measurementSaveLocation {
    case .none:
        ()
    case .local:
        let data = "1,4,2\n".data(using: String.Encoding.utf8)!
        let url = getUrlForVisibleFiles().appendingPathComponent("data.csv")
        if let fileHandle = FileHandle(forWritingAtPath: url.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try! data.write(to: url, options: .atomic)
        }
        

    case .googleDrive:
        ()
    }
    
    switch settings.imageSaveLocation {
    case .none:
        ()
    case .local:
        let png = UIImagePNGRepresentation(image)!
        
        let url = getUrlForVisibleFiles().appendingPathComponent("image.png")
        try! png.write(to: url, options: .atomic)
        
        
    case .googleDrive:
        ()
    }
}
