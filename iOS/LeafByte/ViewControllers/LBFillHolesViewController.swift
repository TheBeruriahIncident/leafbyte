//
//  LBFillHolesViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class LBFillHolesViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    var baseImage: UIImage?
    var scale: Int?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.9;
        scrollView.maximumZoomScale = 10.0
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        baseImageView.image = baseImage
        baseImageView.contentMode = .scaleAspectFit
        setScrolling(true)
        
        // TODO: is there a less stupid way to initialize the image??
        UIGraphicsBeginImageContext(drawingImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        drawingImageView.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        
        findSizes()
    }
    
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    @IBOutlet weak var filledHolesImageView: UIImageView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return wrapper
    }
    
    var swiped = false
    var lastPoint = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        lastPoint = (touches.first?.location(in: drawingImageView))!
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        if (isScrolling) {
            return
        }
        //print("drawing " + String(describing: fromPoint) + " to " + String(describing: toPoint))
        
        UIGraphicsBeginImageContext(drawingImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        context?.interpolationQuality = CGInterpolationQuality.none
        context?.setAllowsAntialiasing(false)
        context?.setShouldAntialias(false)
        
        drawingImageView.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        
        context!.move(to: CGPoint(x: fromPoint.x + 0.5, y: fromPoint.y + 0.5))
        context!.addLine(to: CGPoint(x: toPoint.x + 0.5, y: toPoint.y + 0.5))
//        context!.move(to: CGPoint(x: drawingImageView.frame.size.width / 2, y: 0))
//        context!.addLine(to: CGPoint(x: drawingImageView.frame.size.width / 2, y: drawingImageView.frame.size.height))
//        context!.move(to: CGPoint(x: 0, y: 0))
//        context!.addLine(to: CGPoint(x: drawingImageView.frame.size.width / 2, y: 0))
//
//        context!.move(to: CGPoint(x: 0, y: 1))
//        context!.addLine(to: CGPoint(x: drawingImageView.frame.size.width / 2, y: 1))
//
//        context!.move(to: CGPoint(x: 0, y: 2))
//        context!.addLine(to: CGPoint(x: drawingImageView.frame.size.width / 2, y: 2))
        
//        context!.move(to: CGPoint(x: 0, y: 30))
//        context!.addLine(to: CGPoint(x: drawingImageView.frame.size.width, y: 30))
        context!.strokePath()
        
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        let currentPoint = touches.first?.location(in: drawingImageView)
        drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint!)
        
        lastPoint = currentPoint!
        
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        } else {
            findSizes()
        }
    }
    
    func setScrolling(_ scrolling: Bool) {
        isScrolling = scrolling
        
        scrollView.isUserInteractionEnabled = scrolling
        
        
        if (scrolling) {
            button.setTitle("Switch to drawing", for: .normal)
        } else {
            button.setTitle("Switch to scrolling", for: .normal)
        }
    }
    
    var isScrolling = true
    
    @IBAction func touchButton(_ sender: Any) {
            setScrolling(!isScrolling)
    }
    
    func isOccupied(_ x: Int, _ y: Int, _ data: UnsafePointer<UInt8>, _ width: Int, _ dataDrawing: UnsafePointer<UInt8>, _ widthDrawing: Int) -> Bool {
        
        let scaleW = baseImageView.frame.size.width / (baseImageView.image?.size.width)!
        let scaleH = baseImageView.frame.size.height / (baseImageView.image?.size.height)!
        let aspect = fmin(scaleW, scaleH)
        
        
        let xFactor = Float((baseImageView.image?.size.width)!) / Float((baseImageView.image?.size.width)! / aspect)
        let yFactor = Float((baseImageView.image?.size.height)!) / Float((baseImageView.image?.size.height)! / aspect)
        let xOffset = Float((baseImageView.frame.size.width - (baseImageView.image?.size.width)! * aspect) / 2)
        let yOffset = Float((baseImageView.frame.size.height - (baseImageView.image?.size.height)! * aspect) / 2)
        
        let xToUse = Int(Float(x) * xFactor + xOffset)
        let yToUse = Int(Float(y) * yFactor + yOffset)
        
        // WTF WTF WTF, WHY DOES A RANDOM 5 FIX THIS???????????? CHECK ALL OTHER PLACES WHATATATAT
        let offsetDrawing = (((widthDrawing + 5) * yToUse) + xToUse) * 4
//        let redDrawing = dataDrawing[offsetDrawing]
//        let greenDrawing = dataDrawing[(offsetDrawing + 1)]
//        let blueDrawing = dataDrawing[offsetDrawing + 2]
        let alphaDrawing = dataDrawing[offsetDrawing + 3]
        
        
        if alphaDrawing != 0 {
            //print("now thinks \(xToUse) \(yToUse)")
            return true
        }
        
        // should be able to change the pointer type and load all 4 at once
        let offset = ((width * y) + x) * 4
        let red = data[offset]
        let green = data[(offset + 1)]
        let blue = data[offset + 2]
        
        return red != 255 || green != 255 || blue != 255
    }
    
    func findSizes() {
        let cgImage = CIImage(image: baseImage!)!.cgImage!
        let pixelData: CFData = cgImage.dataProvider!.data!
        // switch to 32 so can read the whole pixel at once
        let width = cgImage.width//Int((image?.size.width)!)
        let height = cgImage.height//Int((image?.size.height)!)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let cgImageDrawing = CIImage(image: drawingImageView.image!)!.cgImage!
        let pixelDataDrawing: CFData = cgImageDrawing.dataProvider!.data!
        let widthDrawing = cgImageDrawing.width
        let heightDrawing = cgImageDrawing.height
        let dataDrawing: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelDataDrawing)
        
        
//        print(widthDrawing)
//        print(cgImageDrawing.width)
//        print(heightDrawing)
//        print(cgImageDrawing.height)

//        for y in 0...heightDrawing - 1 {
//            for x in 0...widthDrawing - 1 {
//                let offset = (((widthDrawing + 5) * y) + x) * 4 // WTF WTF WTF, WHY DOES A RANDOM 5 FIX THIS????????????
//                let red = dataDrawing[offset]
//                let green = dataDrawing[(offset + 1)]
//                let blue = dataDrawing[offset + 2]
//                let alpha = dataDrawing[offset + 3]
//
//                let occupied = alpha != 0//red != 255 || green != 255 || blue != 255
//
//                //print("\(red) \(green) \(blue) \(alpha)")
////                if occupied {
////                    print("occupied \(x) \(y)")
////                }
//                print(occupied ? "1" : "0", terminator: "")
//            }
//            print("")
//        }
//
//        print("doggo")
//
//        return
//
        
        
        
        
        
        
        var groupToPoint = [Int: (Int, Int)]()
        var emptyGroupToNeighboringOccupiedGroup = [Int: Int]()
        var groupIds = Array(repeating: Array(repeating: 0, count: width), count: height)
        var occupiedGroup = 1
        var emptyGroup = -1
        
        var groupSizes = [Int: Int]()
        
        // TODO: how to best represent this??
        var equivalentGroups = [Set<Int>]()
        
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let occupied = isOccupied(x, y, data, width, dataDrawing, widthDrawing)
                
                // TODO: consider 8 connectivity instead of 4
                // using 4-connectvity
                let westGroup = x > 0 && occupied == isOccupied(x - 1, y, data, width, dataDrawing, widthDrawing)
                    ? groupIds[y][x - 1]
                    : nil
                let northGroup = y > 0 && occupied == isOccupied(x, y - 1, data, width, dataDrawing, widthDrawing)
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
                        
                        if x > 0 {
                            emptyGroupToNeighboringOccupiedGroup[newGroup] = groupIds[y][x  - 1]
                        } else if y > 0 {
                            emptyGroupToNeighboringOccupiedGroup[newGroup] = groupIds[y - 1][x]
                        }
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
        var backgroundGroup: Int?
        var leafGroup: Int?
        var leafSize: Int?; // assume the biggest blob is leaf, second is the scale
        var scaleGroup: Int?
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key > 0 && leafGroup == nil) {
                leafGroup = groupAndSize.key
                leafSize = groupAndSize.value
            }
            if (groupAndSize.key < 0 && backgroundGroup == nil) {
                backgroundGroup = groupAndSize.key
            }
            
            if (leafGroup != nil && backgroundGroup != nil) {
                break
            }
        }
        
        var leafGroups: Set<Int>?
        var backgroundGroups: Set<Int>?
        for equivalentGroup in equivalentGroups {
            if equivalentGroup.contains(leafGroup!) {
                leafGroups = equivalentGroup
            }
            if equivalentGroup.contains(backgroundGroup!) {
                backgroundGroups = equivalentGroup
            }
            
            if (leafGroups != nil && backgroundGroups != nil) {
                break
            }
        }
        
//        for foo in groupIds {
//            print(foo)
//        }
        
        var leafArea = getArea(pixels: leafSize!)
        var eatenArea: Float = 0.0
        
        //print("coloring in")
        UIGraphicsBeginImageContext(filledHolesImageView.frame.size)
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key < 0) {
                if  !(backgroundGroups?.contains(groupAndSize.key))! && leafGroups!.contains(emptyGroupToNeighboringOccupiedGroup[groupAndSize.key]!) {
                    eatenArea += getArea(pixels: groupAndSize.value)
                    let (startX, startY) = groupToPoint[groupAndSize.key]!
                    colorIn(CGPoint(x: startX, y: startY), data: data, width, height, dataDrawing: dataDrawing, widthDrawing)
                }
            }
        }
        filledHolesImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if scale != nil {
            summary.text = "leaf is \(leafArea) cm2 with \(eatenArea) cm2 or \(eatenArea / leafArea * 100 )% eaten"
        } else {
            summary.text = "leaf is \(eatenArea / leafArea * 100 )% eaten"
        }
    }
    
    func getArea(pixels: Int) -> Float {
        if (scale != nil) {
            return pow(2.0 / Float(scale!), 2) * Float(pixels)
        } else {
            return Float(pixels)
        }
    }
    
    func colorIn(_ start: CGPoint, data: UnsafePointer<UInt8>, _ width: Int, _ height: Int, dataDrawing: UnsafePointer<UInt8>, _ widthDrawing: Int) {
        
        let context = UIGraphicsGetCurrentContext()
        
        filledHolesImageView.image?.draw(in: CGRect(x: 0, y: 0, width: filledHolesImageView.frame.size.width, height: filledHolesImageView.frame.size.height))
        
        
        let scaleW = baseImageView.frame.size.width / (baseImageView.image?.size.width)!
        let scaleH = baseImageView.frame.size.height / (baseImageView.image?.size.height)!
        let aspect = fmin(scaleW, scaleH)
        
        
        let xFactor = Float((baseImageView.image?.size.width)!) / Float((baseImageView.image?.size.width)! / aspect)
        let yFactor = Float((baseImageView.image?.size.height)!) / Float((baseImageView.image?.size.height)! / aspect)
        let xOffset = Float((baseImageView.frame.size.width - (baseImageView.image?.size.width)! * aspect) / 2)
        let yOffset = Float((baseImageView.frame.size.height - (baseImageView.image?.size.height)! * aspect) / 2)
        
        context!.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        
        var explored = [CGPoint]()
        var queue = [start]
        
        while !queue.isEmpty {
            let point = queue.remove(at: 0)
            let x = Int(point.x)
            let y = Int(point.y)
            
            if (x > 0 && !isOccupied(x - 1, y, data, width, dataDrawing, widthDrawing) && !explored.contains(CGPoint(x: x - 1, y: y)) && !queue.contains(CGPoint(x: x - 1, y: y))) {
                queue.append(CGPoint(x: x - 1, y: y))
            }
            if (x < width - 1 && !isOccupied(x + 1, y, data, width, dataDrawing, widthDrawing) && !explored.contains(CGPoint(x: x + 1, y: y)) && !queue.contains(CGPoint(x: x + 1, y: y))) {
                queue.append(CGPoint(x: x + 1, y: y))
            }
            
            if (y > 0 && !isOccupied(x, y - 1, data, width, dataDrawing, widthDrawing) && !explored.contains(CGPoint(x: x, y: y - 1)) && !queue.contains(CGPoint(x: x, y: y - 1))) {
                queue.append(CGPoint(x: x, y: y - 1))
            }
            if (y < height - 1 && !isOccupied(x, y + 1, data, width, dataDrawing, widthDrawing) && !explored.contains(CGPoint(x: x, y: y + 1)) && !queue.contains(CGPoint(x: x, y: y + 1))) {
                queue.append(CGPoint(x: x, y: y + 1))
            }
            
            let xToUse = Int(Float(point.x) * xFactor + xOffset)
            let yToUse = Int(Float(point.y) * yFactor + yOffset)
            
            // TODO: can I do in bulk, or draw single point??
            //print("drawing \(point) at \(xToUse), \(yToUse)")
            context!.fill(CGRect(x: xToUse, y: yToUse, width: 1, height: 1))
            
            
            explored.append(point)
        }
    }
    @IBOutlet weak var summary: UILabel!
    
    @IBOutlet weak var wrapper: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    
    var sourceType: UIImagePickerControllerSourceType?
    
    @IBAction func nextImage(_ sender: Any) {
        // TODO: handle losing access between these two points
        imagePicker.sourceType = sourceType!
        present(imagePicker, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageChosen"
        {
//            guard let navController = segue.destination as? UINavigationController else {
//                print(type(of: segue.destination))
//                return
//                //fatalError("Expected a seque from the main menu to threshold but instead went to: \(segue.destination)")
//            }
            
            guard let destination = segue.destination as? LBThresholdViewController else {
                return
            }
            
            destination.image = nextImage!
            destination.sourceType = sourceType
        }
    }
    
    var nextImage: UIImage?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        
        nextImage = selectedImage
        
        // Dismiss the picker.
        dismiss(animated: false, completion: {() in
            UIView.setAnimationsEnabled(false)
            self.performSegue(withIdentifier: "imageChosen", sender: self)
        })
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
