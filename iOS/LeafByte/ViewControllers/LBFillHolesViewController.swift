//
//  LBFillHolesViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class LBFillHolesViewController: UIViewController, UIScrollViewDelegate {
    
    var baseImage: UIImage?
    var scale: Int?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.9;
        scrollView.maximumZoomScale = 10.0
        
        baseImageView.image = baseImage
        baseImageView.contentMode = .scaleAspectFit
        setScrolling(true)
        findSizes()
    }
    
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
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
        
        drawingImageView.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        
        context!.move(to: fromPoint)
        context!.addLine(to: toPoint)
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
    
    func isOccupied(_ x: Int, _ y: Int, _ data: UnsafePointer<UInt8>, _ width: Int) -> Bool {
        // should be able to change the pointer type and load all 4 at once
        let offset = ((width * y) + x) * 4
        let red = data[offset]
        let green = data[(offset + 1)]
        let blue = data[offset + 2]
        
        return red != 255 || green != 255 || blue != 255
    }
    
    func findSizes() {
        if scale == nil {
            return
        }
        
        let cgImage = CIImage(image: baseImage!)!.cgImage!
        let pixelData: CFData = cgImage.dataProvider!.data!
        // switch to 32 so can read the whole pixel at once
        let width = cgImage.width//Int((image?.size.width)!)
        let height = cgImage.height//Int((image?.size.height)!)
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
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
        var leafGroup: Int?
        var leafSize: Int?; // assume the biggest blob is leaf, second is the scale
        var scaleGroup: Int?
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key > 0) {
                leafGroup = groupAndSize.key
                leafSize = groupAndSize.value
                break
            }
        }
        
        var leafGroups: Set<Int>?
        for equivalentGroup in equivalentGroups {
            if equivalentGroup.contains(leafGroup!) {
                leafGroups = equivalentGroup
            }
        }
        
        var leafArea = getArea(pixels: leafSize!)
        var eatenArea: Float = 0.0
        
        print(groupsAndSizes)
        
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key < 0) {
                if (scale != nil) {
                    if leafGroups!.contains(emptyGroupToNeighboringOccupiedGroup[groupAndSize.key]!) {
                        eatenArea += getArea(pixels: groupAndSize.value)
                    }
                }
            }
        }
        
        print("leaf is \(leafArea) cm2 with \(eatenArea) cm2 or \(eatenArea / leafArea * 100 )% eaten")
    }
    
    func getArea(pixels: Int) -> Float {
        return pow(2.0 / Float(scale!), 2) * Float(pixels)
    }
    
    @IBOutlet weak var wrapper: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
}
