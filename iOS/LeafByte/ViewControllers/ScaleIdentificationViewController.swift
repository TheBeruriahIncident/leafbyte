//
//  ScaleIdentificationViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/10/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class ScaleIdentificationViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
    // MARK: - Fields
    
    // These are passed from the previous view.
    var settings: Settings!
    var sourceType: UIImagePickerControllerSourceType!
    var cgImage: CGImage!
    var uiImage: UIImage!
    
    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false
    
    // The current mode can be scrolling or identifying.
    var inScrollingMode = true
    
    var pointOnLeaf: (Int, Int)?
    
    // This is the number of pixels across the scale mark in the image.
    // It's calculated in this view (if possible) and passed forward.
    var scaleMarkPixelLength: Int?
    var scaleMarkEnd1: CGPoint?
    var scaleMarkEnd2: CGPoint?
    
    // Projection from the full base image view to the actual image, so we can check if the touch is within the image.
    var baseImageViewToImage: Projection!
    var baseImageRect: CGRect!
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!
    
    @IBOutlet weak var modeToggleButton: UIButton!
    @IBOutlet weak var clearScaleButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    
    @IBOutlet weak var sampleNumberLabel: UILabel!
    @IBOutlet weak var resultsText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func goHome(_ sender: Any) {
        dismissNavigationController(self: self)
    }
    
    @IBAction func toggleScrollingMode(_ sender: Any) {
        setScrollingMode(!inScrollingMode)
    }
    @IBAction func clearScale(_ sender: Any) {
        scaleMarkPixelLength = nil
        scaleMarkEnd1 = nil
        scaleMarkEnd2 = nil
        drawMarkers()
        resultsText.text = "No scale"
        
        setScrollingMode(true)
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
        
        sampleNumberLabel.text = "Sample \(settings.getNextSampleNumber())"
        
        setScrollingMode(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppearHasRun {
            findScaleMark()
            
            modeToggleButton.isEnabled = true
            clearScaleButton.isEnabled = true
            completeButton.isEnabled = true
            
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
            
            setBackButton(self: self, next: destination)
        } else if segue.identifier == "helpPopover" {
            let popoverViewController = segue.destination
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
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
        if inScrollingMode {
            return
        }

        let candidatePoint = touches.first!.location(in: baseImageView)
        let projectedPoint = baseImageViewToImage.project(point: candidatePoint)
        // Touches outside the image don't matter.
        if !baseImageRect.contains(projectedPoint) {
            return
        }
        
        let indexableImage = IndexableImage(cgImage)
        // Touches in white don't matter.
        let nonWhitePixel = searchForNonWhite(inImage: indexableImage, fromPoint: projectedPoint, checkingNoMoreThan: 90)
        if nonWhitePixel == nil {
            setScaleNotFound()
            setScrollingMode(true)
            return
        }
        
        // Since a non-white section in the image was touched, it may be a scale mark.
        measureScaleMark(fromPointInMark: nonWhitePixel!, inImage: indexableImage, withMinimumLength: 1)
        
        // Switch back to scrolling after each scale mark identified.
        setScrollingMode(true)
    }
    
    // MARK: - Helpers
    
    private func setScrollingMode(_ inScrollingMode: Bool) {
        self.inScrollingMode = inScrollingMode

        gestureRecognizingView.isUserInteractionEnabled = inScrollingMode

        if inScrollingMode {
            modeToggleButton.setTitle("Touch the scale", for: .normal)
        } else {
            modeToggleButton.setTitle("Cancel", for: .normal)
        }
    }
    
    private func findScaleMark() {
        let indexableImage = IndexableImage(cgImage)
        let image = BooleanIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage, withPixelToBoolConversion: { $0.isNonWhite() })
        
        let connectedComponentsInfo = labelConnectedComponents(image: image)
        
        // We're going to find the second biggest occupied component; we assume the biggest is the leaf and the second biggest is the scale mark.
        // As such, filter down to just occupied components.
        let occupiedLabelsAndSizes: [Int: Int] = connectedComponentsInfo.labelToSize.filter { $0.0 > 0 }
        
        // If we have less than two, we don't have a scale mark.
        if occupiedLabelsAndSizes.count < 2 {
            setScaleNotFound()
            return
        }
        
        let sortedOccupiedLabelsAndSizes = occupiedLabelsAndSizes.sorted { $0.1 > $1.1 }
        
        // The leaf is the biggest label.
        let leafLabel = sortedOccupiedLabelsAndSizes[0].key
        pointOnLeaf = connectedComponentsInfo.labelToMemberPoint[leafLabel]!
        
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
        resultsText.text = "Scale found: \(candidateScaleMarkPixelLength) pixels long"
        
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
    
    private func setScaleNotFound() {
        resultsText.text = "Scale not found"
        scaleMarkPixelLength = nil
        scaleMarkEnd1 = nil
        scaleMarkEnd2 = nil
        drawMarkers()
    }
}
