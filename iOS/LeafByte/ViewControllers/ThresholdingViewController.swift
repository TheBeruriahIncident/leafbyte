//
//  ThresholdingViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit
import Accelerate

class ThresholdingViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    var sourceType: UIImagePickerControllerSourceType?
    
    var image: UIImage?
    let filter = ThresholdFilter()
    
    var scale: Int?
    
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
        extraImageLayer.contentMode = .scaleAspectFit

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
        let img: CGImage = (CIImage(image: image!)?.cgImage!)!
        
        //create vImage_Buffer with data from CGImageRef
        let inProvider: CGDataProvider = img.dataProvider!
        let inBitmapData: CFData = inProvider.data!
        
        
        var inBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)
        var inBuffer2 = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)
        
        // https://github.com/PokerChang/ios-card-detector/blob/master/Accelerate.framework/Frameworks/vImage.framework/Headers/Transform.h#L20
        let divisor: Int32 = 256

        let matrixS: [[Int16]] = [
            [1000,   0,      0,      0],//sub in divisor
            [0,     114,     587,    299],
            [0,     0,    0,    0],
            [0,     0,     0,    0]
        ]
        
        var matrix: [Int16] = [Int16](repeating: 0, count: 16)
        
        for i in 0...3 {
            for j in 0...3 {
                matrix[(3 - j) * 4 + (3 - i)] = matrixS[i][j]
            }
        }
        vImageMatrixMultiply_ARGB8888(&inBuffer2, &inBuffer, matrix, 1000, nil, nil, UInt32(kvImageNoFlags))
        
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
        
        let total = blue.map { Int($0) }
        return total
    }
    
    func setValue(threshold: Float) {
        filter.threshold = threshold
        slider.value = 1 - threshold
        
        imageView.image = convert(cmage: filter.outputImage)
        findScale()
    }
    
    func findScale() {
        let cgImage = CIImage(image: imageView.image!)!.cgImage!
        let pixelData: CFData = cgImage.dataProvider!.data!
        // switch to 32 so can read the whole pixel at once
        let width = cgImage.width//Int((image?.size.width)!)
        let height = cgImage.height//Int((image?.size.height)!)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var groupToPoint = [Int: (Int, Int)]()
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
                    groupToPoint[newGroup] = (x, y)
                }
            }
        }
        
        for equivalentGroup in equivalentGroups {
            let first = equivalentGroup.first
            for group in equivalentGroup {
                if group != first! {
                    groupSizes[first!]! += groupSizes[group]!
                    groupSizes[group] = nil
                }
            }
        }
        
        let groupsAndSizes = groupSizes.sorted { $0.1 > $1.1 }
        var leafFound = false; // assume the biggest blob is leaf, second is the scale
        var scaleGroup: Int?
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key > 0) {
                if !leafFound {
                    leafFound = true
                } else {
                    //print("size \(groupAndSize.value)")
                    scaleGroup = groupAndSize.key
                    break
                }
            }
        }
        
        extraImageLayer.image = nil
        UIGraphicsBeginImageContext(extraImageLayer.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        extraImageLayer.image?.draw(in: CGRect(x: 0, y: 0, width: extraImageLayer.frame.size.width, height: extraImageLayer.frame.size.height))
        
        
        let scaleW = imageView.frame.size.width / (imageView.image?.size.width)!
        let scaleH = imageView.frame.size.height / (imageView.image?.size.height)!
        let aspect = fmin(scaleW, scaleH)
        
        
        let xFactor = Float((imageView.image?.size.width)!) / Float((imageView.image?.size.width)! / aspect)
        let yFactor = Float((imageView.image?.size.height)!) / Float((imageView.image?.size.height)! / aspect)
        let xOffset = Float((imageView.frame.size.width - (imageView.image?.size.width)! * aspect) / 2)
        let yOffset = Float((imageView.frame.size.height - (imageView.image?.size.height)! * aspect) / 2)
        //print("\(xFactor)  \(yFactor) \(xOffset) \(yOffset)")
        
        context?.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        if (scaleGroup != nil) {
            var scaleClass: Set<Int>
            for equivalentGroup in equivalentGroups {
                if (equivalentGroup.contains(scaleGroup!)) {
                    scaleClass = equivalentGroup
                }
            }
            let (xStart, yStart) = groupToPoint[scaleGroup!]!
            
            let a = getFarthestPoint(CGPoint(x: xStart, y: yStart), data: data, width, height)
            let b = getFarthestPoint(a, data: data, width, height)
            
            scale = Int(pow(pow(a.x - b.x, 2) + pow(a.y - b.y, 2), 0.5))
            
            //print("\(a)  \(b)")
            
            let xAToUse = Int(Float(a.x) * xFactor + xOffset)
            let yAToUse = Int(Float(a.y) * yFactor + yOffset)
            
            let xBToUse = Int(Float(b.x) * xFactor + xOffset)
            let yBToUse = Int(Float(b.y) * yFactor + yOffset)
            
            //print("\(xAToUse)  \(yAToUse)")
            //print("\(xBToUse)  \(yBToUse)")
            
            context?.interpolationQuality = CGInterpolationQuality.none
            context?.setAllowsAntialiasing(false)
            context?.setShouldAntialias(false)
            
            context!.move(to: CGPoint(x: Double(xAToUse) + 0.5, y: Double(yAToUse) + 0.5))
            context!.addLine(to: CGPoint(x: Double(xBToUse) + 0.5, y: Double(yBToUse) + 0.5))
            context!.strokePath()
        }
        

        
        
//        context?.setStrokeColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
//        context!.move(to: CGPoint(x: xStart, y: yStart))
//        context!.addLine(to: CGPoint(x: 0, y: 0))
//        context!.strokePath()
        
        
//
//
//        context?.setStrokeColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
//
//        context!.move(to: CGPoint(x: extraImageLayer.frame.size.width, y: extraImageLayer.frame.size.height))
//        context!.addLine(to: CGPoint(x: 0, y: 0))
//        context!.strokePath()
//
//        context!.move(to: CGPoint(x: extraImageLayer.frame.size.width, y: 0))
//        context!.addLine(to: CGPoint(x: 0, y: extraImageLayer.frame.size.height))
//        context!.strokePath()
//
//        context?.setStrokeColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
//        context!.move(to: CGPoint(x: Int(300 * xFactor), y: Int(400 * yFactor)))
//        context!.addLine(to: CGPoint(x: 0, y: 0))
//        context!.strokePath()
        
        extraImageLayer.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
//        for y in 0...height - 1 {
//            for x in 0...width - 1 {
//                let currentGroup = groupIds[y][x]
//
//                for foo in equivalentGroups {
//                    if foo.contains(currentGroup) {
//                        groupIds[y][x] = foo.first!
//                    }
//                }
//            }
//        }
    }
    
    @IBOutlet weak var wrapper: UIView!
    @IBOutlet weak var extraImageLayer: UIImageView!
    
    func getBaseGroup(_ equivalentGroups: [Int: Int], _ group: Int) -> Int {
        if let baseGroup = equivalentGroups[group] {
            return getBaseGroup(equivalentGroups, baseGroup)
        }
        
        return group
    }
    
    func getFarthestPoint(_ start: CGPoint, data: UnsafePointer<UInt8>, _ width: Int, _ height: Int) -> CGPoint {
        var explored = [CGPoint]()
        var queue = [start]
        
        // make this faster, maybe with a distance heuristic
        while !queue.isEmpty {
            let point = queue.remove(at: 0)
            let x = Int(point.x)
            let y = Int(point.y)
            
            if (x > 0 && isOccupied(x - 1, y, data, width) && !explored.contains(CGPoint(x: x - 1, y: y)) && !queue.contains(CGPoint(x: x - 1, y: y))) {
                queue.append(CGPoint(x: x - 1, y: y))
            }
            if (x < width - 1 && isOccupied(x + 1, y, data, width) && !explored.contains(CGPoint(x: x + 1, y: y)) && !queue.contains(CGPoint(x: x + 1, y: y))) {
                queue.append(CGPoint(x: x + 1, y: y))
            }
            
            if (y > 0 && isOccupied(x, y - 1, data, width) && !explored.contains(CGPoint(x: x, y: y - 1)) && !queue.contains(CGPoint(x: x, y: y - 1))) {
                queue.append(CGPoint(x: x, y: y - 1))
            }
            if (y < height - 1 && isOccupied(x, y + 1, data, width) && !explored.contains(CGPoint(x: x, y: y + 1)) && !queue.contains(CGPoint(x: x, y: y + 1))) {
                queue.append(CGPoint(x: x, y: y + 1))
            }
            
            explored.append(point)
        }
        
        return explored.popLast()!
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
        if let sourceViewController = sender.source as? MainMenuViewController, let image = sourceViewController.image {
            
            imageView.image = image
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        setValue(threshold: 1 - sender.value)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return wrapper
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "thresholdSet"
        {
            guard let destination = segue.destination as? AreaCalculationViewController else {
                return
            }
            
            destination.baseImage = imageView.image
            destination.scale = scale
            destination.sourceType = sourceType
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
}
