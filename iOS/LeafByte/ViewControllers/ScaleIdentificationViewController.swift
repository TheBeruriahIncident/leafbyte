//
//  ScaleIdentificationViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/10/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class ScaleIdentificationViewController: UIViewController, UIScrollViewDelegate {
    // MARK: - Fields
    
    // These are passed from the previous view.
    var sourceType: UIImagePickerControllerSourceType!
    var image: UIImage!
    
    // The current mode can be scrolling or identifying.
    var inScrollingMode = true
    
    // This is the number of pixels across the scale mark in the image.
    // It's calculated in this view (if possible) and passed forward.
    var scaleMarkPixelLength: Int?
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!
    
    @IBOutlet weak var modeToggleButton: UIButton!
    @IBOutlet weak var clearScaleButton: UIButton!
    
    @IBOutlet weak var resultsText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func toggleScrollingMode(crolling: Any) {
        setScrollingMode(!inScrollingMode)
    }
    @IBAction func clearScale(_ sender: Any) {
        scaleMarkPixelLength = nil
        scaleMarkingView.image = nil
        resultsText.text = "No scale"
    }
    
    // MARK: - UIViewController overrides

    override func viewDidLoad(){
        super.viewDidLoad()

        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)

        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = image

        setScrollingMode(true)
        findScaleMark()
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is scaleIdentificationComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "scaleIdentificationComplete"
        {
            guard let destination = segue.destination as? AreaCalculationViewController else {
                fatalError("Expected the next view to be the area calculation view but is \(segue.destination)")
            }
            
            destination.sourceType = sourceType
            destination.image = image
            destination.scaleMarkPixelLength = scaleMarkPixelLength
        }
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

        let candidatePoint = (touches.first?.location(in: baseImageView))!
        print(candidatePoint)
        print(baseImageView.image?.size)
    }
    
    // MARK: - Helpers
    
    func setScrollingMode(_ inScrollingMode: Bool) {
        self.inScrollingMode = inScrollingMode

        gestureRecognizingView.isUserInteractionEnabled = inScrollingMode

        if inScrollingMode {
            modeToggleButton.setTitle("Touch the scale", for: .normal)
        } else {
            modeToggleButton.setTitle("Back to scrolling", for: .normal)
        }
    }
    
    func findScaleMark() {
        let indexableImage = IndexableImage(uiToCgImage(baseImageView.image!))
        let image = BooleanIndexableImage(width: indexableImage.width, height: indexableImage.height)
        image.addImage(indexableImage, withPixelToBoolConversion: { $0.isNonWhite() })
        
        let connectedComponentsInfo = labelConnectedComponents(image: image)
        
        // We're going to find the second biggest occupied component; we assume the biggest is the leaf and the second biggest is the scale mark.
        // As such, filter down to just occupied components.
        let occupiedLabelsAndSizes: [Int: Int] = connectedComponentsInfo.labelToSize.filter { $0.0 > 0 }
        
        // If we have less than two, we don't have a scale mark.
        if occupiedLabelsAndSizes.count < 2 {
            resultsText.text = "Scale not found"
            return
        }
        
        // The scale mark is the second biggest label.
        let scaleMarkLabel = occupiedLabelsAndSizes.sorted { $0.1 > $1.1 }[1].key
        
        // Get a point in the scale mark.
        let (scaleMarkPointX, scaleMarkPointY) = connectedComponentsInfo.labelToMemberPoint[scaleMarkLabel]!
        
        // Find the farthest point in the scale mark away, then the farthest away from that.
        // This represents the farthest apart two points in the scale mark (where farthest refers to the path through the scale mark).
        // This definition of farthest will work for us for thin, straight scale marks, which is what we expect.
        let farthestPoint1 = getFarthestPointInComponent(inImage: indexableImage, fromPoint: CGPoint(x: scaleMarkPointX, y: scaleMarkPointY))
        let farthestPoint2 = getFarthestPointInComponent(inImage: indexableImage, fromPoint: farthestPoint1)
        
        let candidateScaleMarkPixelLength = Int(round(farthestPoint1.distance(to: farthestPoint2)))
        // If the scale mark is less than 5 pixels long, it's probably just noise in the image.
        if candidateScaleMarkPixelLength < 5 {
            resultsText.text = "Scale not found"
            return
        }
        
        scaleMarkPixelLength = candidateScaleMarkPixelLength
        resultsText.text = "Scale found"
        
        // Draw a line where we think the scale mark is.
        let drawingManager = DrawingManager(withCanvasSize: scaleMarkingView.frame.size, withProjection: Projection(fromImageInView: baseImageView.image!, toView: baseImageView))
        drawingManager.getContext().setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawingManager.drawLine(from: farthestPoint1, to: farthestPoint2)
        drawingManager.finish(imageView: scaleMarkingView)
    }
}
