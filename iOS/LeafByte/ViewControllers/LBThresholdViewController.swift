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
        // TODO: do we need this other thing?
        filter.inputImageColorful = CIImage(image: image!)//, options: [kCIImageColorSpace: NSNull()])
        
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
        findScale()
//        let pixelData: CFData = CIImage(image: imageView.image!)!.cgImage!.dataProvider!.data!
//        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
//
//        print(Int((image?.size.height)!))
//        print(Int((CIImage(image: imageView.image!)!.cgImage!.height)))
//
//        for y in 2418...2422 {
//            for x in 0...30 {
//                let offset = ((Int((image?.size.width)!) * y) + x) * 4
//                let red = data[offset]
//                let green = data[(offset + 1)]
//                let blue = data[offset + 2]
//                let alpha = data[offset + 3]
//                print ("\(red) \(green) \(blue) \(alpha)")
//            }
//        }
    }
    
    func findScale() {
        let cgImage = CIImage(image: imageView.image!)!.cgImage!
        let pixelData: CFData = cgImage.dataProvider!.data!
        // switch to 32 so can read the whole pixel at once
        let width = cgImage.width//Int((image?.size.width)!)
        let height = cgImage.height//Int((image?.size.height)!)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var groupIds = Array(repeating: Array(repeating: 0, count: width), count: height)
        var occupiedGroup = 1
        var emptyGroup = -1
        
        var groupSizes = [Int: Int]()
        
        // TODO: how to best represent this??
        var equivalentGroups = [Set<Int>]()
        
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let occupied = isOccupied(x, y, data, width)
                // TODO: consider 8 connectivity instead of 4
                // using 4-connectvity
                let westGroup = x > 0 && occupied == isOccupied(x - 1, y, data, width)
                    ? groupIds[y][x - 1]
                    : nil
                let northGroup = y > 0 && occupied == isOccupied(x, y - 1, data, width)
                    ? groupIds[y - 1][x]
                    : nil
                
                // TODO: simplify? use set?
                if westGroup != nil {
                    if northGroup != nil {
                        if westGroup != northGroup {
                            //merge groups
                            
                            var westGroupEquivalence: Set<Int>?
                            var westGroupEquivalenceIndex: Int?
                            var northGroupEquivalence: Set<Int>?
                            var northGroupEquivalenceIndex: Int?
                            for (index, equivalentGroup) in equivalentGroups.enumerated() {
                                if equivalentGroup.contains(westGroup!) {
                                    westGroupEquivalence = equivalentGroup
                                    westGroupEquivalenceIndex = index
                                }
                                if equivalentGroup.contains(northGroup!) {
                                    northGroupEquivalence = equivalentGroup
                                    northGroupEquivalenceIndex = index
                                }
                            }
                            
                            if (westGroupEquivalence == nil && northGroupEquivalence == nil) {
                                equivalentGroups.append([westGroup!, northGroup!])
                            } else if (westGroupEquivalence != nil && northGroupEquivalence != nil) {
                                if (westGroupEquivalence != northGroupEquivalence) {
                                    equivalentGroups[westGroupEquivalenceIndex!].formUnion(northGroupEquivalence!)
                                    equivalentGroups.remove(at: northGroupEquivalenceIndex!)
                                }
                            } else if (westGroupEquivalence != nil) {
                                equivalentGroups[westGroupEquivalenceIndex!].insert(northGroup!)
                            } else if (northGroupEquivalence != nil) {
                                equivalentGroups[northGroupEquivalenceIndex!].insert(westGroup!)
                            } else {
                                assert(false) // shouldn't get here
                            }
                        }
                        groupSizes[northGroup!]! += 1
                        groupIds[y][x] = northGroup!
                    } else {
                        groupSizes[westGroup!]! += 1
                        groupIds[y][x] = westGroup!
                    }
                } else if northGroup != nil {
                    groupSizes[northGroup!]! += 1
                    groupIds[y][x] = northGroup!
                } else {
                    //NEW GROUP
                    var newGroup: Int
                    if (occupied) {
                        newGroup = occupiedGroup
                        occupiedGroup += 1
                    } else {
                        newGroup = emptyGroup
                        emptyGroup -= 1
                    }
                    groupIds[y][x] = newGroup
                    groupSizes[newGroup] = 1
                    
                    if (newGroup == 1314) {
                        let pixelData2: CFData = CIImage(image: image!)!.cgImage!.dataProvider!.data!
                        let data2: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData2)
                        
                        let offset1 = ((width * (y - 1)) + x) * 4
                        let red1 = data[offset1]
                        let green1 = data[(offset1 + 1)]
                        let blue1 = data[offset1 + 2]
                        
                        let offset = ((width * y) + x) * 4
                        let red = data[offset]
                        let green = data[(offset + 1)]
                        let blue = data[offset + 2]
                        
                        let red2 = data2[offset]
                        let green2 = data2[(offset + 1)]
                        let blue2 = data2[offset + 2]
                        
                        let offset11 = ((width * (y + 1)) + x) * 4
                        let red11 = data[offset1]
                        let green11 = data[(offset1 + 1)]
                        let blue11 = data[offset1 + 2]
                        
                        print("whyyy")
                    }
                }
            }
        }
        
        print(equivalentGroups)
        for equivalentGroup in equivalentGroups {
            let first = equivalentGroup.first
            for group in equivalentGroup {
                if group != first! {
                    groupSizes[first!]! += groupSizes[group]!
                    groupSizes[group] = nil
                }
            }
        }
        
        print(groupSizes.sorted(by: { $0.1 < $1.1 }))
        
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let currentGroup = groupIds[y][x]
                
                for foo in equivalentGroups {
                    if foo.contains(currentGroup) {
                        groupIds[y][x] = foo.first!
                    }
                }
            }
        }
        
        for foo in groupIds {
            print(foo)
        }
    }
    
    func getBaseGroup(_ equivalentGroups: [Int: Int], _ group: Int) -> Int {
        if let baseGroup = equivalentGroups[group] {
            return getBaseGroup(equivalentGroups, baseGroup)
        }
        
        return group
    }
    
    func isOccupied(_ x: Int, _ y: Int, _ data: UnsafePointer<UInt8>, _ width: Int) -> Bool {
        // should be able to change the pointer type and load all 4 at once
        let offset = ((width * y) + x) * 4
        let red = data[offset]
        let green = data[(offset + 1)]
        let blue = data[offset + 2]
        
         return red != 255 || green != 255 || blue != 255
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
