//
//  ThresholdingViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import Accelerate
import UIKit

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
    
    // MARK: - Actions
    
    // This is called from the back button in the navigation bar.
    @IBAction func backFromThreshold(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        setThreshold(1 - sender.value)
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)
        
        filter.setInputImage(image!)
        
        baseImageView.contentMode = .scaleAspectFit
        scaleMarkingView.contentMode = .scaleAspectFit
        
        // Guess a good threshold to start at; the user can adjust with the slider later.
        let suggestedThreshold = getSuggestedThreshold(image: uiToCgImage(image!))
        thresholdSlider.value = 1 - suggestedThreshold
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
    
    // MARK: - Helpers
    
    func setThreshold(_ threshold: Float) {
        filter.threshold = threshold
        baseImageView.image = ciToUiImage(filter.outputImage)
        findScaleMark()
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
        
        scaleMarkPixelLength = Int(round(farthestPoint1.distance(to: farthestPoint2)))
        
        // Draw a line where we think the scale mark is.
        let drawingManager = DrawingManager(withCanvasSize: scaleMarkingView.frame.size, withProjection: Projection(fromImageInView: baseImageView.image!, toView: baseImageView))
        drawingManager.getContext().setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        drawingManager.drawLine(from: farthestPoint1, to: farthestPoint2)
        drawingManager.finish(imageView: scaleMarkingView)
    }
}
