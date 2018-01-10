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
    
    
    
    
    
    
    
    
    
    func setThreshold(_ threshold: Float) {
        filter.threshold = threshold
        thresholdSlider.value = 1 - threshold
        
        baseImageView.image = ciToUiImage(filter.outputImage)
        findScale()
    }
    
    func findScale() {
        let image = IndexableImage(uiToCgImage(baseImageView.image!))
        let booleanImage = BooleanIndexableImage(width: image.width, height: image.height)
        booleanImage.addImage(image, withPixelToBoolConversion: { $0.isNonWhite() })
        
        let connectedComponentsInfo = labelConnectedComponents(image: booleanImage)
        
        let groupsAndSizes = connectedComponentsInfo.labelToSize.sorted { $0.1 > $1.1 }
        var leafFound = false; // assume the biggest blob is leaf, second is the scale
        var scaleGroup: Int?
        for groupAndSize in groupsAndSizes {
            if groupAndSize.key > 0 {
                if !leafFound {
                    leafFound = true
                } else {
                    //print("size \(groupAndSize.value)")
                    scaleGroup = groupAndSize.key
                    break
                }
            }
        }
        
        let drawingManager = DrawingManager(withCanvasSize: scaleMarkingView.frame.size, withProjection: Projection(fromImageInView: baseImageView.image!, toView: baseImageView))
        drawingManager.getContext().setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        if scaleGroup != nil {
            // TODO: we should be using scale class not group
            
            let (xStart, yStart) = connectedComponentsInfo.labelToMemberPoint[scaleGroup!]!
            
            let a = getFarthestPointInComponent(inImage: image, fromPoint: CGPoint(x: xStart, y: yStart))
            let b = getFarthestPointInComponent(inImage: image, fromPoint: a)
            
            scaleMarkPixelLength = Int(pow(pow(a.x - b.x, 2) + pow(a.y - b.y, 2), 0.5))
            
            
            drawingManager.drawLine(from: a, to: b)
        }
        
        drawingManager.finish(imageView: scaleMarkingView)
    }
}
