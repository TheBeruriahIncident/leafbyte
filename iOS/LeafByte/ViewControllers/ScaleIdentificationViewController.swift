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
    
    // This is the number of pixels across the scale mark in the image.
    // It's calculated in this view (if possible) and passed forward.
    var scaleMarkPixelLength: Int?
    var scaleMarkEnd1: CGPoint?
    var scaleMarkEnd2: CGPoint?
    
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
        scaleMarkPixelLength = nil
        scaleMarkEnd1 = nil
        scaleMarkEnd2 = nil
        drawMarkers()
        scaleStatusText.text = NSLocalizedString("No scale", comment: "Shown if the user clears the scale")
        
        setScrollingMode(Mode.scrolling)
    }
    
    @IBAction func editSampleNumber(_ sender: Any) {
        presentSampleNumberAlert(self: self, sampleNumberButton: sampleNumberButton, settings: settings)
    }
    
    // MARK: - UIViewController overrides

    override func viewDidLoad(){
        super.viewDidLoad()

        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)

        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = uiImage
        scaleMarkingView.contentMode = .scaleAspectFit
        
        baseImageViewToImage = Projection(fromView: baseImageView, toImageInView: baseImageView.image!)
        baseImageRect = CGRect(origin: CGPoint.zero, size: baseImageView.image!.size)
        
        setSampleNumberButtonText(sampleNumberButton, settings: settings)
        
        setScrollingMode(Mode.scrolling)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppearHasRun {
            findScaleMark()
            
            leafIdentificationToggleButton.isEnabled = true
            scaleIdentificationToggleButton.isEnabled = true
            clearScaleButton.isEnabled = true
            completeButton.isEnabled = true
            
            if inTutorial {
                self.performSegue(withIdentifier: "helpPopover", sender: nil)
            }
            
            viewDidAppearHasRun = true
        }
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is scaleIdentificationComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "scaleIdentificationComplete"
        {
            guard let destination = segue.destination as? AreaCalculationViewController else {
                fatalError("Expected the next view to be the area calculation view but is \(segue.destination)")
            }
            
            destination.settings = settings
            destination.sourceType = sourceType
            destination.cgImage = cgImage
            destination.uiImage = uiImage
            destination.scaleMarkPixelLength = scaleMarkPixelLength
            destination.scaleMarkEnd1 = scaleMarkEnd1
            destination.scaleMarkEnd2 = scaleMarkEnd2
            destination.inTutorial = inTutorial
            destination.barcode = barcode
            destination.initialConnectedComponentsInfo = connectedComponentsInfo
            destination.pointOnLeaf = pointOnLeaf
            destination.pointOnLeafHasBeenChanged = pointOnLeafHasBeenChanged
            
            setBackButton(self: self, next: destination)
        } else if segue.identifier == "helpPopover" {
            setupPopoverViewController(segue.destination, self: self)
        }
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
        let visiblePixel = searchForVisible(inImage: indexableImage, fromPoint: projectedPoint, checkingNoMoreThan: 200)
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
            pointOnLeaf = (roundToInt(visiblePixel!.x), roundToInt(visiblePixel!.y))
            leafStatusText.text = NSLocalizedString("Leaf found", comment: "Shown when a leaf is found")
            drawMarkers()
        } else if mode == .identifyingScale {
            // Since a non-white section in the image was touched, it may be a scale mark.
            measureScaleMark(fromPointInMark: visiblePixel!, inImage: indexableImage, withMinimumLength: 1)
        }
        
        // Switch back to scrolling after each scale mark identified.
        setScrollingMode(.scrolling)
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
        leafIdentificationToggleButton.setTitle(NSLocalizedString("Touch leaf", comment: "Enters the mode to identify the leaf"), for: .normal)
    }
    
    private func disableLeafIdentification() {
        leafIdentificationToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to identify the leaf"), for: .normal)
    }
    
    private func enableScaleIdentification() {
    scaleIdentificationToggleButton.setTitle(NSLocalizedString("Touch scale", comment: "Enters the mode to identify the scale"), for: .normal)
    }
    
    private func disableScaleIdentification() {
        scaleIdentificationToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to identify the scale"), for: .normal)
    }
    
    private func findScaleMark() {
        let indexableImage = IndexableImage(cgImage)
        let image = LayeredIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage)
        
        connectedComponentsInfo = labelConnectedComponents(image: image)
        
        // We're going to find the second biggest occupied component; we assume the biggest is the leaf and the second biggest is the scale mark.
        // As such, filter down to just occupied components.
        let occupiedLabelsAndSizes: [Int: Size] = connectedComponentsInfo.labelToSize.filter { $0.0 > 0 }
        
        // If we have less than two, we don't have a scale mark.
        if occupiedLabelsAndSizes.count < 2 {
            setScaleNotFound()
            return
        }
        
        let sortedOccupiedLabelsAndSizes = occupiedLabelsAndSizes.sorted { $0.1.standardPart > $1.1.standardPart }
        
        // The leaf is the biggest label.
        let leafLabel = sortedOccupiedLabelsAndSizes[0].key
        pointOnLeaf = connectedComponentsInfo.labelToMemberPoint[leafLabel]!
        leafStatusText.text = NSLocalizedString("Leaf found", comment: "Shown when a leaf is found")
        
        // The scale mark is the second biggest label.
        let scaleMarkLabel = sortedOccupiedLabelsAndSizes[1].key
        
        // Get a point in the scale mark.
        let (scaleMarkPointX, scaleMarkPointY) = connectedComponentsInfo.labelToMemberPoint[scaleMarkLabel]!
        
        measureScaleMark(fromPointInMark: CGPoint(x: scaleMarkPointX, y: scaleMarkPointY), inImage: indexableImage, withMinimumLength: 5)
    }
    
    private func measureScaleMark(fromPointInMark startPoint: CGPoint, inImage image: IndexableImage, withMinimumLength minimumLength: Int) {
        // Find the farthest point in the scale mark away, then the farthest away from that.
        // This represents the farthest apart two points in the scale mark (where farthest refers to the path through the scale mark).
        // This definition of farthest will work for us for thin, straight scale marks, which is what we expect.
        let farthestPoint1 = getFarthestPointInComponent(inImage: image, fromPoint: startPoint)
        let farthestPoint2 = getFarthestPointInComponent(inImage: image, fromPoint: farthestPoint1)
        
        let candidateScaleMarkPixelLength = roundToInt(farthestPoint1.distance(to: farthestPoint2))
        // If the scale mark is too short, it's probably just noise in the image.
        if candidateScaleMarkPixelLength < minimumLength {
            setScaleNotFound()
            return
        }
        
        scaleMarkPixelLength = candidateScaleMarkPixelLength
        scaleMarkEnd1 = farthestPoint1
        scaleMarkEnd2 = farthestPoint2
        scaleStatusText.text = NSLocalizedString("Scale found", comment: "Shown when a scale mark is found")
        
        drawMarkers()
    }
    
    private func drawMarkers() {
        let drawingManager = DrawingManager(withCanvasSize: baseImageView.image!.size)
        
        // Draw a line where we think the scale mark is.
        if scaleMarkPixelLength != nil {
            drawingManager.context.setLineWidth(2)
            drawingManager.context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            drawingManager.drawLine(from: scaleMarkEnd1!, to: scaleMarkEnd2!)
        }
        
        // Draw an outlined star where we think the leaf is.
        if pointOnLeaf != nil {
            drawingManager.drawStar(atPoint: CGPoint(x: pointOnLeaf!.0, y: pointOnLeaf!.1), withSize: 13)
            
            drawingManager.context.setFillColor(DrawingManager.lightGreen.cgColor)
            drawingManager.drawStar(atPoint: CGPoint(x: pointOnLeaf!.0, y: pointOnLeaf!.1), withSize: 10)
        }
        
        drawingManager.finish(imageView: scaleMarkingView)
    }
    
    private func setLeafNotFound() {
        leafStatusText.text = NSLocalizedString("Leaf not found", comment: "Shown when a leaf is not found")
        pointOnLeaf = nil
        drawMarkers()
    }
    
    private func setScaleNotFound() {
        scaleStatusText.text = NSLocalizedString("Scale not found", comment: "Shown when a scale mark is not found")
        scaleMarkPixelLength = nil
        scaleMarkEnd1 = nil
        scaleMarkEnd2 = nil
        drawMarkers()
    }
}
