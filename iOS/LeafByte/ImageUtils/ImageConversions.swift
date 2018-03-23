//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreImage
import UIKit

// Caution: These may be slow.
// TODO: benchmark and probably avoid these where possible https://stackoverflow.com/questions/37450696/drawing-a-ciimage-is-too-slow

// Convert a Core Graphics image to a Core Image image.
func cgToCIImage(_ cgImage: CGImage) -> CIImage {
    return CIImage(cgImage: cgImage)
}

// Convert a Core Graphics image to a UI image.
func cgToUiImage(_ cgImage: CGImage) -> UIImage {
    return UIImage(cgImage: cgImage)
}

// Convert a Core Image image to a Core Graphics image.
func ciToCgImage(_ ciImage: CIImage) -> CGImage {
    if ciImage.cgImage != nil {
        return ciImage.cgImage!
    }
    
    // TODO: make this a static const?
    let context: CIContext = CIContext(options: nil)
    return context.createCGImage(ciImage, from: ciImage.extent)!
}

// Convert a Core Image image to a UI image.
func ciToUiImage(_ ciImage: CIImage) -> UIImage {
    // UIImage(ciImage: ciImage) seems obvious, but it distorts the image
    // TODO: figure why, unsure if this other approach is slower
    
    let cgImage = ciToCgImage(ciImage)
    return UIImage(cgImage: cgImage)
}

// Convert a UI image to a Core Graphics image.
func uiToCgImage(_ uiImage: UIImage) -> CGImage {
    if uiImage.cgImage != nil {
        return uiImage.cgImage!
    }
    
    return ciToCgImage(uiToCiImage(uiImage))
}

// Convert a UI image to a Core Image image.
func uiToCiImage(_ uiImage: UIImage) -> CIImage {
    if uiImage.ciImage != nil {
       return uiImage.ciImage!
    }
    
    return CIImage(image: uiImage)!
}
