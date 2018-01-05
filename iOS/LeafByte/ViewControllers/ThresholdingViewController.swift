//
//  ThresholdingViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit
import Accelerate

class ThresholdingViewController: UIViewController, UIScrollViewDelegate {
    // MARK: - Fields
    
    // Both of these are passed from the main menu view.
    var sourceType: UIImagePickerControllerSourceType!
    var image: UIImage!
    
    let filter = ThresholdingFilter()
    
    // This is the number of pixels across the scale mark in the image.
    // It's calculated in this view (if possible) and passed forward.
    var scaleMarkPixelLength: Int?
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!
    @IBOutlet weak var thresholdSlider: UISlider!
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        gestureRecognizingView.delegate = self
        gestureRecognizingView.minimumZoomScale = 0.9;
        gestureRecognizingView.maximumZoomScale = 10.0
        
        filter.setInputImage(image!)
        
        baseImageView.contentMode = .scaleAspectFit
        scaleMarkingView.contentMode = .scaleAspectFit
        
        // TODO: these should not be here and should probably be async
        // Guess a good threshold to start at; the user can adjust with the slider later.
        let suggestedThreshold = getSuggestedThreshold(image: uiToCgImage(image!))
        setThreshold(suggestedThreshold)
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is thresholdingComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "thresholdingComplete"
        {
            guard let destination = segue.destination as? AreaCalculationViewController else {
                fatalError("Expected the next view to be the area calculation view but is \(segue.destination)")
            }
            
            destination.sourceType = sourceType
            destination.image = baseImageView.image
            destination.scaleMarkPixelLength = scaleMarkPixelLength
        }
    }
    
    // MARK: - UIScrollViewDelegate overrides
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollableView
    }
    
    // MARK: - Actions
    
    // This is called from the back button in the navigation bar.
    @IBAction func backFromThreshold(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        setThreshold(1 - sender.value)
    }
    
    
    
    
    
    
    
    
    
    func setThreshold(_ threshold: Float) {
        filter.threshold = threshold
        thresholdSlider.value = 1 - threshold
        
        baseImageView.image = ciToUiImage(filter.outputImage)
        findScale()
    }
    
    func findScale() {
        let image = IndexableImage(uiToCgImage(baseImageView.image!))
        let width = image.width
        let height = image.height
        
        var groupToPoint = [Int: (Int, Int)]()
        var groupIds = Array(repeating: Array(repeating: 0, count: width), count: height)
        var occupiedGroup = 1
        var emptyGroup = -1
        
        var groupSizes = [Int: Int]()
        
        // TODO: how to best represent this??
        var equivalentGroups = [Set<Int>]()
        
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let occupied = image.getPixel(x: x, y: y).isNonWhite()
                
                // TODO: consider 8 connectivity instead of 4
                // using 4-connectvity
                let westGroup = x > 0 && occupied == image.getPixel(x: x - 1, y: y).isNonWhite()
                    ? groupIds[y][x - 1]
                    : nil
                let northGroup = y > 0 && occupied == image.getPixel(x: x, y: y - 1).isNonWhite()
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
        
        scaleMarkingView.image = nil
        UIGraphicsBeginImageContext(scaleMarkingView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        scaleMarkingView.image?.draw(in: CGRect(x: 0, y: 0, width: scaleMarkingView.frame.size.width, height: scaleMarkingView.frame.size.height))
        
        
        let scaleW = baseImageView.frame.size.width / (baseImageView.image?.size.width)!
        let scaleH = baseImageView.frame.size.height / (baseImageView.image?.size.height)!
        let aspect = fmin(scaleW, scaleH)
        
        
        let xFactor = Float((baseImageView.image?.size.width)!) / Float((baseImageView.image?.size.width)! / aspect)
        let yFactor = Float((baseImageView.image?.size.height)!) / Float((baseImageView.image?.size.height)! / aspect)
        let xOffset = Float((baseImageView.frame.size.width - (baseImageView.image?.size.width)! * aspect) / 2)
        let yOffset = Float((baseImageView.frame.size.height - (baseImageView.image?.size.height)! * aspect) / 2)
        //print("\(xFactor)  \(yFactor) \(xOffset) \(yOffset)")
        
        context?.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        if (scaleGroup != nil) {
            // TODO: we should be using scale class not group
            //var scaleClass: Set<Int>
            for equivalentGroup in equivalentGroups {
                if (equivalentGroup.contains(scaleGroup!)) {
                    //scaleClass = equivalentGroup
                }
            }
            let (xStart, yStart) = groupToPoint[scaleGroup!]!
            
            let a = getFarthestPoint(CGPoint(x: xStart, y: yStart), image: image, width, height)
            let b = getFarthestPoint(a, image: image, width, height)
            
            scaleMarkPixelLength = Int(pow(pow(a.x - b.x, 2) + pow(a.y - b.y, 2), 0.5))
            
            let xAToUse = Int(Float(a.x) * xFactor + xOffset)
            let yAToUse = Int(Float(a.y) * yFactor + yOffset)
            
            let xBToUse = Int(Float(b.x) * xFactor + xOffset)
            let yBToUse = Int(Float(b.y) * yFactor + yOffset)
            
            context?.interpolationQuality = CGInterpolationQuality.none
            context?.setAllowsAntialiasing(false)
            context?.setShouldAntialias(false)
            
            context!.move(to: CGPoint(x: Double(xAToUse) + 0.5, y: Double(yAToUse) + 0.5))
            context!.addLine(to: CGPoint(x: Double(xBToUse) + 0.5, y: Double(yBToUse) + 0.5))
            context!.strokePath()
        }
        
        
        scaleMarkingView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    
    func getFarthestPoint(_ start: CGPoint, image: IndexableImage, _ width: Int, _ height: Int) -> CGPoint {
        var explored = [CGPoint]()
        var queue = [start]
        
        // make this faster, maybe with a distance heuristic
        while !queue.isEmpty {
            let point = queue.remove(at: 0)
            let x = Int(point.x)
            let y = Int(point.y)
            
            if (x > 0 && image.getPixel(x: x - 1, y: y).isNonWhite() && !explored.contains(CGPoint(x: x - 1, y: y)) && !queue.contains(CGPoint(x: x - 1, y: y))) {
                queue.append(CGPoint(x: x - 1, y: y))
            }
            if (x < width - 1 && image.getPixel(x: x + 1, y: y).isNonWhite() && !explored.contains(CGPoint(x: x + 1, y: y)) && !queue.contains(CGPoint(x: x + 1, y: y))) {
                queue.append(CGPoint(x: x + 1, y: y))
            }
            
            if (y > 0 && image.getPixel(x: x, y: y - 1).isNonWhite() && !explored.contains(CGPoint(x: x, y: y - 1)) && !queue.contains(CGPoint(x: x, y: y - 1))) {
                queue.append(CGPoint(x: x, y: y - 1))
            }
            if (y < height - 1 && image.getPixel(x: x, y: y + 1).isNonWhite() && !explored.contains(CGPoint(x: x, y: y + 1)) && !queue.contains(CGPoint(x: x, y: y + 1))) {
                queue.append(CGPoint(x: x, y: y + 1))
            }
            
            explored.append(point)
        }
        
        return explored.popLast()!
    }    
}
