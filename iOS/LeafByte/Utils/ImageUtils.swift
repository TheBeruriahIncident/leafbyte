//
//  ImageUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/5/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit

func resizeImage(_ image: UIImage, within newBounds: CGSize) -> UIImage {
    // Check if resizing is necessary.
    if (image.size.width <= newBounds.width && image.size.height <= newBounds.height) {
        return image
    }
    
    // Find the resizing ratio that maintains the aspect ratio.
    let resizingRatioForWidth = newBounds.width / image.size.width
    let resizingRatioForHeight = newBounds.height / image.size.height
    let resizingRatio = min(resizingRatioForWidth, resizingRatioForHeight)
    
    let newSize = CGSize(width: image.size.width * resizingRatio, height: image.size.height * resizingRatio)
    
    // Draw into an appropriately sized context to resize.
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext();
    
    return newImage!
}
