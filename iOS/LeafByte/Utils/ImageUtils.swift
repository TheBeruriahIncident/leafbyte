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
    if image.size.width <= newBounds.width && image.size.height <= newBounds.height {
        return image
    }
    
    // Find the resizing ratio that maintains the aspect ratio.
    let resizingRatioForWidth = newBounds.width / image.size.width
    let resizingRatioForHeight = newBounds.height / image.size.height
    let resizingRatio = min(resizingRatioForWidth, resizingRatioForHeight)
    
    let newSize = CGSize(width: image.size.width * resizingRatio, height: image.size.height * resizingRatio)
    
    let cgImage = uiToCgImage(image)
    
    let context = CGContext(
        data: nil,
        width: Int(newSize.width),
        height: Int(newSize.height),
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: cgImage.bytesPerRow,
        space: cgImage.colorSpace!,
        bitmapInfo: cgImage.bitmapInfo.rawValue)!
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
    
    // TODO: I bet I can get away without this conversion
    return cgToUiImage(context.makeImage()!)
}
