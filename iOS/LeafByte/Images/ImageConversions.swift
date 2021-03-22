//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/4/18.
//  Copyright © 2018 Zoe Getman-Pickering. All rights reserved.
//

import CoreImage
import UIKit

// Caution: Conversions may be slow, avoid where possible.

// Convert a Core Graphics image to a Core Image image.
func cgToCIImage(_ cgImage: CGImage) -> CIImage {
    return CIImage(cgImage: cgImage)
}

// Convert a Core Graphics image to a UI image.
func cgToUiImage(_ cgImage: CGImage) -> UIImage {
    return UIImage(cgImage: cgImage)
}

// Convert a Core Image image to a Core Graphics image.
let context: CIContext = CIContext(options: nil)
func ciToCgImage(_ ciImage: CIImage) -> CGImage {
    // It's appealing to lead with something like:
    // if #available(iOS 10.0, *), ciImage.cgImage != nil {
    //     return ciImage.cgImage!
    // }
    // But it turns out that this gives you a downsampled version.
    
    return context.createCGImage(ciImage, from: ciImage.extent)!
}

// Convert a Core Image image to a UI image.
func ciToUiImage(_ ciImage: CIImage) -> UIImage {
    // UIImage(ciImage: ciImage) seems obvious, but it stretches the image.
    
    let cgImage = ciToCgImage(ciImage)
    return UIImage(cgImage: cgImage)
}

// Convert a UI image to a Core Graphics image.
func uiToCgImage(_ uiImage: UIImage) -> CGImage {
    // It's appealing to lead with something like:
    // if uiImage.cgImage != nil {
    //     return uiImage.cgImage!
    // }
    // But it turns out that this gives you a downsampled version.
    
    return ciToCgImage(uiToCiImage(uiImage))
}

// Convert a UI image to a Core Image image.
func uiToCiImage(_ uiImage: UIImage) -> CIImage {
    if uiImage.ciImage != nil {
       return uiImage.ciImage!
    }
    
    return CIImage(image: uiImage)!
}
