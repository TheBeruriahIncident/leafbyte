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
    @IBOutlet weak var resultsText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func toggleScrollingMode(_ sender: Any) {
        setScrollingMode(!inScrollingMode)
    }
    
    @IBAction func calculate(_ sender: Any) {
        findSizes()
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
        
        UIGraphicsBeginImageContext(userDrawingView.frame.size)
        let context = UIGraphicsGetCurrentContext()!
        
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
        
        // TODO: WTF WTF WTF, WHY DOES A RANDOM 5 FIX THIS???????????? CHECK ALL OTHER PLACES WHATATATAT
        let offsetDrawing = (((widthDrawing + 5) * yToUse) + xToUse) * 4
        let alphaDrawing = dataDrawing[offsetDrawing + 3]
        
        if alphaDrawing != 0 {
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
        let cgImage = uiToCgImage(image!)
        let pixelData: CFData = cgImage.dataProvider!.data!
        // switch to 32 so can read the whole pixel at once
        let width = cgImage.width
        let height = cgImage.height
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        let cgImageDrawing = CIImage(image: userDrawingView.image!)!.cgImage!
        let pixelDataDrawing: CFData = cgImageDrawing.dataProvider!.data!
        let widthDrawing = cgImageDrawing.width
        let dataDrawing: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelDataDrawing)
        
        
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
        
        let leafArea = getArea(pixels: leafSize!)
        var eatenArea: Float = 0.0
        
        UIGraphicsBeginImageContext(leafHolesView.frame.size)
        for groupAndSize in groupsAndSizes {
            if (groupAndSize.key < 0) {
                if  !(backgroundGroups?.contains(groupAndSize.key))! && leafGroups!.contains(emptyGroupToNeighboringOccupiedGroup[groupAndSize.key]!) {
                    eatenArea += getArea(pixels: groupAndSize.value)
                    let (startX, startY) = groupToPoint[groupAndSize.key]!
                    colorIn(CGPoint(x: startX, y: startY), data: data, width, height, dataDrawing: dataDrawing, widthDrawing)
                }
            }
        }
        leafHolesView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if scaleMarkPixelLength != nil {
            resultsText.text = "leaf is \(leafArea) cm2 with \(eatenArea) cm2 or \(eatenArea / leafArea * 100 )% eaten"
        } else {
            resultsText.text = "leaf is \(eatenArea / leafArea * 100 )% eaten"
        }
    }
    
    func getArea(pixels: Int) -> Float {
        if (scaleMarkPixelLength != nil) {
            return pow(2.0 / Float(scaleMarkPixelLength!), 2) * Float(pixels)
        } else {
            return Float(pixels)
        }
    }
    
    func colorIn(_ start: CGPoint, data: UnsafePointer<UInt8>, _ width: Int, _ height: Int, dataDrawing: UnsafePointer<UInt8>, _ widthDrawing: Int) {
        
        let context = UIGraphicsGetCurrentContext()
        
        leafHolesView.image?.draw(in: CGRect(x: 0, y: 0, width: leafHolesView.frame.size.width, height: leafHolesView.frame.size.height))
        
        
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
            context!.fill(CGRect(x: xToUse, y: yToUse, width: 1, height: 1))
            
            
            explored.append(point)
        }
    }
    

}
