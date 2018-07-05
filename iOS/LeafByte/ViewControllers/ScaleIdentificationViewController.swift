//
//  ScaleIdentificationViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/10/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

final class ScaleIdentificationViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
    // MARK: - Fields
    
    // These are passed from the previous view.
    var settings: Settings!
    var sourceType: UIImagePickerControllerSourceType!
    var cgImage: CGImage!
    var uiImage: UIImage!
    var inTutorial: Bool!
    var barcode: String?
    
    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false
    
    // The current mode can be scrolling or identifying either the scale or leaf.
    var mode = Mode.scrolling
    
    enum Mode {
        case scrolling
        case identifyingScale
        case identifyingLeaf
    }
    
    // Track a point on the leaf at which to mark the leaf and whether the user has changed that point.
    var pointOnLeaf: (Int, Int)?
    var pointOnLeafHasBeenChanged = false
    
    var scaleMarked = false
    var scaleMarks = Array(repeating: CGPoint.zero, count: 4)
    
    var nextScaleMarkToMark = 0
    
    var connectedComponentsInfo: ConnectedComponentsInfo!
    
    // Projection from the full base image view to the actual image, so we can check if the touch is within the image.
    var baseImageViewToImage: Projection!
    var baseImageRect: CGRect!
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!
    
    @IBOutlet weak var leafIdentificationToggleButton: UIButton!
    @IBOutlet weak var scaleIdentificationToggleButton: UIButton!
    @IBOutlet weak var clearScaleButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    
    @IBOutlet weak var sampleNumberButton: UIButton!
    @IBOutlet weak var scaleStatusText: UILabel!
    @IBOutlet weak var leafStatusText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func goHome(_ sender: Any) {
        dismissNavigationController(self: self)
    }
    
    @IBAction func toggleLeafIdentification(_ sender: Any) {
        setScrollingMode(mode == .identifyingLeaf ? .scrolling : .identifyingLeaf)
    }
    
    @IBAction func toggleScaleIdentification(_ sender: Any) {
        setScrollingMode(mode == .identifyingScale ? .scrolling : .identifyingScale)
    }
    
    @IBAction func clearScale(_ sender: Any) {
        scaleMarked = false
        drawMarkers()
        scaleStatusText.text = NSLocalizedString("No scale", comment: "Shown if the user clears the scale")
        
        setScrollingMode(Mode.scrolling)
    }
    
    @IBAction func editSampleNumber(_ sender: Any) {
        presentSampleNumberAlert(self: self, sampleNumberButton: sampleNumberButton, settings: settings)
    }
    
    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)

        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = uiImage
        scaleMarkingView.contentMode = .scaleAspectFit
        
        baseImageViewToImage = Projection(fromView: baseImageView, toImageInView: baseImageView.image!)
        baseImageRect = CGRect(origin: CGPoint.zero, size: baseImageView.image!.size)
        
        setSampleNumberButtonText(sampleNumberButton, settings: settings)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppearHasRun {
            findScaleMark()
            setScrollingMode(Mode.scrolling)
            
            leafIdentificationToggleButton.isEnabled = true
            scaleIdentificationToggleButton.isEnabled = true
            clearScaleButton.isEnabled = true
            completeButton.isEnabled = pointOnLeaf != nil
            
            if inTutorial {
                self.performSegue(withIdentifier: "helpPopover", sender: nil)
            }
            
            viewDidAppearHasRun = true
        }
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is scaleIdentificationComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "scaleIdentificationComplete" {
            guard let destination = segue.destination as? AreaCalculationViewController else {
                fatalError("Expected the next view to be the area calculation view but is \(segue.destination)")
            }
            
            destination.settings = settings
            destination.sourceType = sourceType
            destination.inTutorial = inTutorial
            destination.barcode = barcode
            destination.pointOnLeaf = pointOnLeaf
            destination.pointOnLeafHasBeenChanged = pointOnLeafHasBeenChanged
            
            if scaleMarked {
                destination.cgImage = fix()
                destination.uiImage = cgToUiImage(destination.cgImage)
                destination.scaleMarkPixelLength = (cgImage.width + cgImage.height) / 2
                destination.initialConnectedComponentsInfo = nil
            } else {
                destination.initialConnectedComponentsInfo = connectedComponentsInfo
                destination.cgImage = cgImage
                destination.uiImage = uiImage
                destination.scaleMarkPixelLength = nil
            }
            
            setBackButton(self: self, next: destination)
        } else if segue.identifier == "helpPopover" {
            setupPopoverViewController(segue.destination, self: self)
        }
    }
    
    private func stretchToDots() -> CIImage {
        let adjustedCenters = scaleMarks.map({ point in CGPoint(x: point.x, y: CGFloat(cgImage.height) - point.y) })
        
        let centerSum = adjustedCenters.reduce(CGPoint.zero, { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) })
        let centerOfCenters = CGPoint(x: centerSum.x / 4, y: centerSum.y / 4)
        let centersAndAngles = adjustedCenters.map { center -> (CGPoint, CGFloat) in
            let difference = (center.x - centerOfCenters.x, center.y - centerOfCenters.y)
            let angle = atan2(difference.0, difference.1)//) + Double.pi * 3 / 2
            //let clampedAngle = angle > Double.pi * 2 ? angle - Double.pi * 2 : angle
            return (center, angle)
        }
        
        let sorted = centersAndAngles.sorted(by: { $0.1 > $1.1 })
        let mapped1 = sorted.map {$0.0}
        
        let foos = mapped1.map { inputPoint -> CGPoint in
            let xScale = CGFloat(1)//CGFloat(originalImage.width) / CGFloat(cgImage.width)
            let yScale = xScale//CGFloat(originalImage.height) / CGFloat(cgImage.height)
            
            let foo = CGPoint(x: xScale * inputPoint.x, y: yScale * inputPoint.y)
            return foo
        }
        
        let perspectiveTransform = CIFilter(name: "CIPerspectiveCorrection")!
        //print(forefixing)
        perspectiveTransform.setValue(CIVector(cgPoint: foos[0]),
                                      forKey: "inputBottomLeft")
        perspectiveTransform.setValue(CIVector(cgPoint: foos[1]),
                                      forKey: "inputBottomRight")
        perspectiveTransform.setValue(CIVector(cgPoint: foos[2]),
                                      forKey: "inputTopRight")
        perspectiveTransform.setValue(CIVector(cgPoint: foos[3]),
                                      forKey: "inputTopLeft")
        perspectiveTransform.setValue(cgToCIImage(cgImage),
                                      forKey: kCIInputImageKey)
        
        return perspectiveTransform.outputImage!
    }
    
    private func fix() -> CGImage {
        let middle = stretchToDots()
        let size = min(1200, roundToInt(min(middle.extent.width, middle.extent.height), rule: FloatingPointRoundingRule.down))
        return resizeImageIgnoringAspectRatioAndOrientation(ciToCgImage(middle), x: size, y: size)
    }
    
    
    // MARK: - UIPopoverPresentationControllerDelegate overrides
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: - UIScrollViewDelegate overrides

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollableView
    }

    // MARK: - UIResponder overrides

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Touches don't matter in scrolling mode.
        if mode == .scrolling {
            return
        }

        let candidatePoint = touches.first!.location(in: baseImageView)
        let projectedPoint = baseImageViewToImage.project(point: candidatePoint)
        // Touches outside the image don't matter.
        if !baseImageRect.contains(projectedPoint) {
            return
        }
        
        if mode == .identifyingLeaf {
            pointOnLeafHasBeenChanged = true
        }
        
        let indexableImage = IndexableImage(cgImage)
        // Touches in white don't matter.
        let visiblePixel = searchForVisible(inImage: indexableImage, fromPoint: projectedPoint, checkingNoMoreThan: 10000)
        if visiblePixel == nil {
            if mode == .identifyingLeaf {
                setLeafNotFound()
            } else if mode == .identifyingScale {
                setScaleNotFound()
            }
            setScrollingMode(.scrolling)
            return
        }
        
        if mode == .identifyingLeaf {
            setLeafFound(pointOnLeaf1: (roundToInt(visiblePixel!.x), roundToInt(visiblePixel!.y)))
            drawMarkers()
            
            setScrollingMode(.scrolling)
        } else if mode == .identifyingScale {
            // Since a non-white section in the image was touched, it may be a scale mark.
            let markFound = measureScaleMark(fromPointInMark: visiblePixel!, inImage: indexableImage, withMinimumLength: 1, markNumber: nextScaleMarkToMark)
            if (markFound) {
                nextScaleMarkToMark += 1
                
                if nextScaleMarkToMark == 4 {
                    nextScaleMarkToMark = 1
                    scaleMarked = true
                    
                    setScrollingMode(.scrolling)
                }
            } else {
                nextScaleMarkToMark = 0
                
                setScrollingMode(.scrolling)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func setScrollingMode(_ mode: Mode) {
        self.mode = mode

        gestureRecognizingView.isUserInteractionEnabled = mode == .scrolling

        if mode == .scrolling {
            enableLeafIdentification()
            enableScaleIdentification()
        } else if mode == .identifyingLeaf {
            disableLeafIdentification()
            enableScaleIdentification()
        } else if mode == .identifyingScale {
            enableLeafIdentification()
            disableScaleIdentification()
        }
    }
    
    private func enableLeafIdentification() {
        if pointOnLeaf == nil {
            leafIdentificationToggleButton.setTitle(NSLocalizedString("Touch leaf", comment: "Enters the mode to identify the leaf"), for: .normal)
        } else {
            leafIdentificationToggleButton.setTitle(NSLocalizedString("Change leaf", comment: "Enters the mode to change the leaf identification"), for: .normal)
        }
    }
    
    private func disableLeafIdentification() {
        leafIdentificationToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to identify the leaf"), for: .normal)
    }
    
    private func enableScaleIdentification() {
        if !scaleMarked {
            scaleIdentificationToggleButton.setTitle(NSLocalizedString("Touch scale", comment: "Enters the mode to identify the scale"), for: .normal)
        } else {
            scaleIdentificationToggleButton.setTitle(NSLocalizedString("Change scale", comment: "Enters the mode to change the scale identification"), for: .normal)
        }
    }
    
    private func disableScaleIdentification() {
        scaleIdentificationToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to identify the scale"), for: .normal)
    }
    
    private func findScaleMark() {
        let indexableImage = IndexableImage(cgImage)
        let image = LayeredIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage)
        
        connectedComponentsInfo = labelConnectedComponents(image: image)
        
        // We're going to find the second through fifth biggest occupied components; we assume the biggest is the leaf and the rest are the scale marks.
        // As such, filter down to just occupied components.
        let occupiedLabelsAndSizes: [Int: Size] = connectedComponentsInfo.labelToSize.filter { $0.0 > 0 }
        
        // If we have less than 5, we don't have scale marks.
        if occupiedLabelsAndSizes.count < 5 {
            setLeafNotFound()
            setScaleNotFound()
            return
        }
        
        let sortedOccupiedLabelsAndSizes = occupiedLabelsAndSizes.sorted { $0.1.standardPart > $1.1.standardPart }
        
        // The leaf is the biggest label.
        let leafLabel = sortedOccupiedLabelsAndSizes[0].key
        setLeafFound(pointOnLeaf1: connectedComponentsInfo.labelToMemberPoint[leafLabel]!)
        
        // The scale marks are the next biggest labels.
        for markNumber in 0...3 {
            let scaleMarkLabel = sortedOccupiedLabelsAndSizes[markNumber + 1].key
            
            // Get a point in the scale mark.
            let (scaleMarkPointX, scaleMarkPointY) = connectedComponentsInfo.labelToMemberPoint[scaleMarkLabel]!
            
            let markFound = measureScaleMark(fromPointInMark: CGPoint(x: scaleMarkPointX, y: scaleMarkPointY), inImage: indexableImage, withMinimumLength: 5, markNumber: markNumber)
            if (!markFound) {
                setScaleNotFound()
                return
            }
        }
        
        scaleMarked = true
        setScaleFound()
    }
    
    private func measureScaleMark(fromPointInMark startPoint: CGPoint, inImage image: IndexableImage, withMinimumLength minimumLength: Int, markNumber: Int) -> Bool {
        // Find the farthest point in the scale mark away, then the farthest away from that.
        // This represents the farthest apart two points in the scale mark (where farthest refers to the path through the scale mark).
        // This definition of farthest will work for us for thin, straight scale marks, which is what we expect.
        let farthestPoint1 = getFarthestPointInComponent(inImage: image, fromPoint: startPoint)
        let farthestPoint2 = getFarthestPointInComponent(inImage: image, fromPoint: farthestPoint1)
        
        let candidateScaleMarkPixelLength = roundToInt(farthestPoint1.distance(to: farthestPoint2))
        // If the scale mark is too small, it's probably just noise in the image.
        if candidateScaleMarkPixelLength < minimumLength {
            setScaleNotFound()
            return false
        }
        
        let scaleMark = CGPoint(x: (farthestPoint1.x + farthestPoint2.x) / 2, y: (farthestPoint1.y + farthestPoint2.y) / 2)
        scaleMarks[markNumber] = scaleMark
        
        drawMarkers()
        
        return true
    }
    
    private func drawMarkers() {
        let drawingManager = DrawingManager(withCanvasSize: baseImageView.image!.size)
        drawingManager.context.setLineWidth(2)
        drawingManager.context.setStrokeColor(DrawingManager.darkRed.cgColor)
        
        // Draw Xs at each point
        scaleMarks.forEach({drawingManager.drawX(at: $0, size: 5)})
        
        // Draw an outlined star where we think the leaf is.
        if pointOnLeaf != nil {
            drawingManager.drawLeaf(atPoint: CGPoint(x: pointOnLeaf!.0, y: pointOnLeaf!.1))
        }
        
        drawingManager.finish(imageView: scaleMarkingView)
    }
    
    private func setLeafFound(pointOnLeaf1: (Int, Int)) {
        pointOnLeaf = pointOnLeaf1
        leafStatusText.text = NSLocalizedString("Leaf found", comment: "Shown when a leaf is found")
        completeButton.isEnabled = true
    }
    
    private func setLeafNotFound() {
        completeButton.isEnabled = false
        leafStatusText.text = NSLocalizedString("Leaf not found", comment: "Shown when a leaf is not found")
        pointOnLeaf = nil
        drawMarkers()
    }
    
    private func setScaleFound() {
        scaleStatusText.text = NSLocalizedString("Scale found", comment: "Shown when a scale mark is found")
    }
    
    private func setScaleNotFound() {
        scaleStatusText.text = NSLocalizedString("Scale not found", comment: "Shown when a scale mark is not found")
        scaleMarked = false
        drawMarkers()
    }
}
