//
//  LBThresholdViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit
import Accelerate

class LBThresholdViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    var image: UIImage?
    let filter = ThresholdFilter()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let threshold = otsu(forHistogram: getHistogram())
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.9;
        scrollView.maximumZoomScale = 10.0
        
        // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_performance/ci_performance.html#//apple_ref/doc/uid/TP30001185-CH10-SW7
        filter.inputImage = CIImage(image: image!, options: [kCIImageColorSpace: NSNull()])
        
        imageView.contentMode = .scaleAspectFit

        setValue(threshold: threshold)
    }
    
    func otsu(forHistogram histogram: [Int]) -> Float {
        // TODO: check this and use better variables, be better about types
        
        // Use Otsu's method to calculate an initial global threshold
        // Uses the optimized form that maximizes inter-class variance as at https://en.wikipedia.org/wiki/Otsu%27s_method
        let total = histogram.reduce(0, +)
        
        var sumB = 0
        var wB = 0
        var maximum = 0.0
        var level = 0
        let sum1 = zip(Array(0...255), histogram).reduce(0, { $0 + ($1.0 * $1.1) })
        
        for index in 0...255 {
            wB = wB + histogram[index]
            let wF = total - wB
            if (wB == 0 || wF == 0) {
                continue;
            }
            sumB += index * histogram[index]
            let mF = Double(sum1 - sumB) / Double(wF)
            let between = Double(wB * wF) * pow(((Double(sumB) / Double(wB)) - mF), 2);
            if ( between >= maximum ) {
                level = index
                maximum = between
            }
        }
        
        print (level)
        return Float(level) / 256
    }
    
    func getHistogram2() -> [Int] {
        
        let size = image!.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        let cgImage = image!.cgImage // TODO: this is sketch and won't always succeed, right??
        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        var histogram = [Int](repeating: 0, count: 256)
        for pixel in pixelData {
            let blue = pixel & 255
            let green = (pixel >> 8) & 255
            let red = (pixel >> 16) & 255
            let intensity = Int(blue + green + red) / 3
            histogram[intensity] += 1
        }
        
        return histogram
    }
    
    func getHistogram() -> [Int] {
        // TODO: this is sketch and won't always succeed, right??
        let img: CGImage = image!.cgImage!
        
        //create vImage_Buffer with data from CGImageRef
        let inProvider: CGDataProvider = img.dataProvider!
        let inBitmapData: CFData = inProvider.data!
        
        //print("height \(img.height) width \(img.width)")
        
        
        var inBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)
        var inBuffer2 = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)

//        for i in 0...100 {
//            let firstPixel = inBuffer.data.load(fromByteOffset: i * 4, as: UInt32.self)
//            print("full value \(firstPixel), a \(firstPixel >> 24), r \((firstPixel >> 16) & 255) , g \((firstPixel >> 8) & 255), b \(firstPixel & 255)")
//        }
        
//        var firstPixel = inBuffer.data.load(fromByteOffset: 0, as: UInt32.self)
//        print("full value \(firstPixel), a \(firstPixel >> 24), r \((firstPixel >> 16) & 255) , g \((firstPixel >> 8) & 255), b \(firstPixel & 255)")
        
        // https://github.com/PokerChang/ios-card-detector/blob/master/Accelerate.framework/Frameworks/vImage.framework/Headers/Transform.h#L20
        let divisor: Int32 = 256
//        let matrix: [Int16] = [0, 0, 0, 0,
//                               0, 0, 0, 0,
//                               0, 0, 0, 0,
//                               0, 0, 0, 0]
//        let matrixS: [[Int16]] = [
//            [1, 0, 0, 0],
//            [0, 1, 0, 0],
//            [0, 0, 1, 0],
//            [0, 0, 0, 1]
//        ]
        
//        let matrixS: [[Int16]] = [
//            [0, 0, 0, 0],
//            [0, 0, 0, 0],
//            [0, 1, 0, 0],
//            [0, 0, 0, 0]
//        ]

//        let matrixS: [[Int16]] = [
//            [256,   0,      0,      0],//sub in divisor
//            [0,     66,     129,    25],
//            [0,     -38,    -74,    112],
//            [0,     112,     -94,    -18]
//        ]

        let matrixS: [[Int16]] = [
            [1000,   0,      0,      0],//sub in divisor
            [0,     114,     587,    299],
            [0,     0,    0,    0],
            [0,     0,     0,    0]
        ]

        
        
//        let matrixS: [[Int16]] = [
//            [256,   1,      0,      0],//sub in divisor
//            [0,     66,     -38,    112],
//            [0,     129,    -74,    -94],
//            [0,     25,     112,    -18]
//        ]
        var matrix: [Int16] = [Int16](repeating: 0, count: 16)
        
        for i in 0...3 {
            for j in 0...3 {
                matrix[(3 - j) * 4 + (3 - i)] = matrixS[i][j]
            }
        }

//        let matrix: [Int16] = [256, 0, 0, 0,
//                               0, 66, -38, 112,
//                               0, 129, -74, -94,
//                               0, 25, 112, -18]
//        let matrix: [Int16] = [-18, 112, 25, 0, //flipped both ways
//                               -94, -74, 129, 0,
//                               112, -38, 66, 0,
//                               0, 0, 0, 256]
//        let matrix: [Int16] = [256, 0, 0, 0,
//                               0, 66, 129, 25,
//                               0, -38, -74, 112,
//                               0, 112, -94, -18]
        //let postBias: [Int32] = [divisor/2, 4224, 32896, 32896]
        //let postBias: [Int32] = [0, 0, 9, 0]
        let postBias: [Int32] = [32896, 32896, 4224, divisor/2]
        //vImageMatrixMultiply_ARGB8888(&inBuffer2, &inBuffer, matrix, 256, nil, postBias, UInt32(kvImageNoFlags))
        vImageMatrixMultiply_ARGB8888(&inBuffer2, &inBuffer, matrix, 1000, nil, nil, UInt32(kvImageNoFlags))
        //vImageMatrixMultiply_ARGB8888(&inBuffer2, &inBuffer, matrix, 2, nil, nil, UInt32(kvImageNoFlags))
        
//        firstPixel = inBuffer.data.load(fromByteOffset: 0, as: UInt32.self)
//        print("full value \(firstPixel), a \(firstPixel >> 24), y \((firstPixel >> 16) & 255) , u \((firstPixel >> 8) & 255), v \(firstPixel & 255)")
        
//        for i in 0...100 {
//            let test = inBuffer.data.load(fromByteOffset: i * 4, as: UInt32.self)
//            print("y \((test >> 16) & 255)")
//        }
        
        let alpha = [UInt](repeating: 0, count: 256)
        let red = [UInt](repeating: 0, count: 256)
        let green = [UInt](repeating: 0, count: 256)
        let blue = [UInt](repeating: 0, count: 256)
        
        let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha) as UnsafeMutablePointer<vImagePixelCount>?
        let redPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: red) as UnsafeMutablePointer<vImagePixelCount>?
        let greenPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: green) as UnsafeMutablePointer<vImagePixelCount>?
        let bluePtr = UnsafeMutablePointer<vImagePixelCount>(mutating: blue) as UnsafeMutablePointer<vImagePixelCount>?
        
        let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]
        
        let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: rgba)
        let error = vImageHistogramCalculation_ARGB8888(&inBuffer, histogram, UInt32(kvImageNoFlags))
        
        // TODO: this memory management makes me nervous, have I allocated anything?
        
    //        print(alpha)
    //        print(red)
    //        print(green)
    //        print(blue)
        
        let total = blue.map { Int($0) }
        //print (total)
        //let total = zip(red, zip(green, blue)).map { Int($0 + $1.0 + $1.1) }
        return total
    }
    
    func setValue(threshold: Float) {
        filter.threshold = threshold
        slider.value = 1 - threshold
        
        imageView.image = convert(cmage: filter.outputImage)
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    @IBAction func backFromThreshold(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func fromMainMenu(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? LBMainMenuViewController, let image = sourceViewController.image {
            
            imageView.image = image
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        setValue(threshold: 1 - sender.value)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "thresholdSet"
        {
            guard let destination = segue.destination as? LBFillHolesViewController else {
                return
            }
            
            destination.baseImage = imageView.image
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
}
