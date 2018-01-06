//
//  AreaCalculationViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class AreaCalculationViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields
    
    // These are passed from the thresholding view.
    var sourceType: UIImagePickerControllerSourceType!
    var image: UIImage!
    var scaleMarkPixelLength: Int?
    
    // Tracks whether the last gesture (including any ongoing one) was a swipe.
    var swiped = false
    // The last touched point, to enable drawing lines while swiping.
    var lastTouchedPoint = CGPoint.zero
    
    // The current mode can be scrolling or drawing.
    var inScrollingMode = true
    
    let imagePicker = UIImagePickerController()
    // This is set while choosing the next image and is passed to the next thresholding view.
    var selectedImage: UIImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var userDrawingView: UIImageView!
    @IBOutlet weak var leafHolesView: UIImageView!
    
    @IBOutlet weak var modeToggleButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var resultsText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func toggleScrollingMode(_ sender: Any) {
        setScrollingMode(!inScrollingMode)
    }
    
    @IBAction func calculate(_ sender: Any) {
        // Don't allow recalculation until there's a possibility of a different result.
        calculateButton.isEnabled = false
        
        resultsText.text = "Loading"
        // The label won't update until this action returns, so put this calculation on the queue, and it'll be executed right after this function ends.
        DispatchQueue.main.async {
            self.findSizes()
        }
    }
    
    @IBAction func nextImage(_ sender: Any) {
        imagePicker.sourceType = sourceType
        
        if sourceType == .camera {
            requestCameraAccess(self: self, onSuccess: { self.present(self.imagePicker, animated: true, completion: nil) })
        } else {
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)
        setupImagePicker(imagePicker: imagePicker, self: self)
        
        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = image
        
        setScrollingMode(true)
        
        // TODO: is there a less stupid way to initialize the image?? maybe won't need
        UIGraphicsBeginImageContext(userDrawingView.frame.size)
        userDrawingView.image?.draw(in: CGRect(x: 0, y: 0, width: userDrawingView.frame.size.width, height: userDrawingView.frame.size.height))
        userDrawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen"
        {
            guard let destination = segue.destination as? ThresholdingViewController else {
                fatalError("Expected the next view to be the thresholding view but is \(segue.destination)")
            }
            
            destination.sourceType = sourceType
            destination.image = selectedImage
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - UIScrollViewDelegate overrides
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollableView
    }
    
    // MARK: - UIResponder overrides
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        lastTouchedPoint = (touches.first?.location(in: userDrawingView))!
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        let currentPoint = (touches.first?.location(in: userDrawingView))!
        drawLineFrom(fromPoint: lastTouchedPoint, toPoint: currentPoint)
        
        lastTouchedPoint = currentPoint
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            // If it's not a swipe, no line has been drawn.
            drawLineFrom(fromPoint: lastTouchedPoint, toPoint: lastTouchedPoint)
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        finishWithImagePicker(self: self, info: info, selectImage: { selectedImage = $0 })
    }
    
    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        // Do not draw in scrolling mode.
        if (inScrollingMode) {
            return
        }
        
        // Allow recalculation now that there's a possibility of a different result.
        calculateButton.isEnabled = true
        
        UIGraphicsBeginImageContext(userDrawingView.frame.size)
        let context = UIGraphicsGetCurrentContext()!
        
        // TODO: make sure this makes sense later
        // Drawing with width two means that the line will always be connected by 4 connectivity, simplifying the connected components code.
        context.setLineWidth(2)
        context.interpolationQuality = CGInterpolationQuality.none
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        // TODO: does this need to happen every time? clean up context graphics in general
        userDrawingView.image?.draw(in: CGRect(x: 0, y: 0, width: userDrawingView.frame.size.width, height: userDrawingView.frame.size.height))
        
        context.move(to: CGPoint(x: fromPoint.x + 0.5, y: fromPoint.y + 0.5))
        context.addLine(to: CGPoint(x: toPoint.x + 0.5, y: toPoint.y + 0.5))
        context.strokePath()
        
        userDrawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    func setScrollingMode(_ inScrollingMode: Bool) {
        self.inScrollingMode = inScrollingMode
        
        gestureRecognizingView.isUserInteractionEnabled = inScrollingMode
        
        if (inScrollingMode) {
            modeToggleButton.setTitle("Switch to drawing", for: .normal)
        } else {
            modeToggleButton.setTitle("Switch to scrolling", for: .normal)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    func findSizes() {
        let baseImage = IndexableImage(uiToCgImage(image!))
        let combinedImage = BooleanIndexableImage(width: baseImage.width, height: baseImage.height)
        combinedImage.addImage(baseImage, withPixelToBoolConversion: { $0.isNonWhite() })
        
        let userDrawingProjection = Projection(fromImageInView: baseImageView.image!, toView: baseImageView)
        let userDrawing = IndexableImage(uiToCgImage(userDrawingView.image!), withProjection: userDrawingProjection)
        combinedImage.addImage(userDrawing, withPixelToBoolConversion: { $0.isVisible() })
        
        let width = combinedImage.width
        let height = combinedImage.height
        
        var groupToPoint = [Int: (Int, Int)]()
        var emptyGroupToNeighboringOccupiedGroup = [Int: Int]()
        var groupIds = Array(repeating: Array(repeating: 0, count: width), count: height)
        var occupiedGroup = 1
        var emptyGroup = -1
        
        var groupSizes = [Int: Int]()
        
        let equivalentGroups = UnionFind()
        
        for y in 0...height - 1 {
            for x in 0...width - 1 {
                let occupied = combinedImage.getPixel(x: x, y: y)
                
                // using 4-connectvity for speed
                let westGroup = x > 0 && occupied == combinedImage.getPixel(x: x - 1, y: y)
                    ? groupIds[y][x - 1]
                    : nil
                let northGroup = y > 0 && occupied == combinedImage.getPixel(x: x, y: y - 1)
                    ? groupIds[y - 1][x]
                    : nil
                
                // TODO: simplify? use set?
                if westGroup != nil {
                    if northGroup != nil {
                        if westGroup != northGroup {
                            //merge groups
                            
                            equivalentGroups.combineSubsetsContaining(westGroup!, and: northGroup!)
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
                    equivalentGroups.createSubsetWith(newGroup)
                    groupIds[y][x] = newGroup
                    groupSizes[newGroup] = 1
                    groupToPoint[newGroup] = (x, y)
                }
            }
        }
        
        for equivalentGroup in equivalentGroups.subsetIndexToPartitionedElements.values {
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
        for equivalentGroup in equivalentGroups.subsetIndexToPartitionedElements.values {
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
        
        let leafArea = getArea(pixels: leafSize!)
        var eatenArea: Float = 0.0
        
        let drawingManager = DrawingManager(withCanvasSize: leafHolesView.frame.size, withProjection: userDrawingProjection)
        drawingManager.setColorToRed()
        
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key < 0) {
                if  !(backgroundGroups?.contains(groupAndSize.key))! && leafGroups!.contains(emptyGroupToNeighboringOccupiedGroup[groupAndSize.key]!) {
                    eatenArea += getArea(pixels: groupAndSize.value)
                    let (startX, startY) = groupToPoint[groupAndSize.key]!
                    floodFill(CGPoint(x: startX, y: startY), width, height, image: combinedImage, drawingManager: drawingManager)
                }
            }
        }
        drawingManager.finish(imageView: leafHolesView)

        if scaleMarkPixelLength != nil {
            resultsText.text = "leaf is \(String(format: "%.3f", leafArea)) cm2 with \(String(format: "%.3f", eatenArea)) cm2 or \(String(format: "%.3f", eatenArea / leafArea * 100))% eaten"
        } else {
            resultsText.text = "leaf is \(String(format: "%.3f", eatenArea / leafArea * 100))% eaten"
        }
    }
    
    func getArea(pixels: Int) -> Float {
        if (scaleMarkPixelLength != nil) {
            return pow(2.0 / Float(scaleMarkPixelLength!), 2) * Float(pixels)
        } else {
            return Float(pixels)
        }
    }
    
    func floodFill(_ start: CGPoint, _ width: Int, _ height: Int, image: BooleanIndexableImage, drawingManager: DrawingManager) {
        var explored = [Int: [(Int, Int)]]() // y to a list of range
        // TODO: should be a set??
        // TODO: actually, why am I getting repeated values at all
        var queue: Set<CGPoint> = [start]
        
        while !queue.isEmpty {
            let point = queue.popFirst()!
            let x = Int(point.x)
            let y = Int(point.y)
            
            // TODO handle starting top bottom once
            
            var xLeft = x
            var enteringNewSectionNorth = true
            var enteringNewSectionSouth = true
            while xLeft > 0 && !image.getPixel(x: xLeft - 1, y: y) {
                xLeft -= 1
                
                if image.getPixel(x: xLeft, y: y + 1) {
                    enteringNewSectionNorth = true
                } else {
                    if enteringNewSectionNorth {
                        if !isExplored(explored, x: xLeft, y: y + 1) {
                            queue.insert(CGPoint(x: xLeft, y: y + 1))
                        }
                        enteringNewSectionNorth = false
                    }
                }
                if image.getPixel(x: xLeft, y: y - 1) {
                    enteringNewSectionSouth = true
                } else {
                    if enteringNewSectionSouth {
                        if !isExplored(explored, x: xLeft, y: y - 1) {
                            queue.insert(CGPoint(x: xLeft, y: y - 1))
                        }
                        enteringNewSectionSouth = false
                    }
                }
            }
            
            var xRight = x
            while xRight > 0 && !image.getPixel(x: xRight + 1, y: y) {
                xRight += 1
                
                if image.getPixel(x: xRight, y: y + 1) {
                    enteringNewSectionNorth = true
                } else {
                    if enteringNewSectionNorth {
                        if !isExplored(explored, x: xRight, y: y + 1) {
                            queue.insert(CGPoint(x: xRight, y: y + 1))
                        }
                        enteringNewSectionNorth = false
                    }
                }
                if image.getPixel(x: xRight, y: y - 1) {
                    enteringNewSectionSouth = true
                } else {
                    if enteringNewSectionSouth {
                        if !isExplored(explored, x: xRight, y: y - 1) {
                            queue.insert(CGPoint(x: xRight, y: y - 1))
                        }
                        enteringNewSectionSouth = false
                    }
                }
            }
            
            drawingManager.drawLine(from: CGPoint(x: xLeft, y: y), to: CGPoint(x: xRight, y: y))
            
            if explored[y] != nil {
                explored[y]!.append((xLeft, xRight))
            } else {
                explored[y] = [(xLeft, xRight)]
            }
            
        }
    }
    
    private func isExplored(_ explored: [Int: [(Int, Int)]], x: Int, y: Int) -> Bool {
        if let exploredY = explored[y] {
            for range in exploredY {
                if x >= range.0 && x <= range.1 {
                    return true
                }
            }
            
            return false
        } else {
            return false
        }
    }

}
