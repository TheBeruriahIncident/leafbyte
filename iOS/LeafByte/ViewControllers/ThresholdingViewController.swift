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
    
    // These are passed from the main menu view.
    var settings: Settings!
    var sourceType: UIImagePickerControllerSourceType!
    var image: CGImage!
    
    let filter = ThresholdingFilter()
    
    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false
    
    var ciImageThresholded: CIImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!
    @IBOutlet weak var histogramImageView: UIImageView!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var sampleNumberLabel: UILabel!
    
    // MARK: - Actions
    
    // This is called from the back button in the navigation bar.
    @IBAction func backFromThreshold(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func goHome(_ sender: Any) {
        dismissNavigationController(self: self)
    }
    
    @IBAction func sliderMoved(_ sender: UISlider) {
        setThreshold(1 - sender.value)
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        // This prevents a black shadow from appearing in the navigation bar during transitions (see https://stackoverflow.com/questions/22413193/dark-shadow-on-navigation-bar-during-segue-transition-after-upgrading-to-xcode-5 ).
        self.navigationController!.view.backgroundColor = UIColor.white
        
        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)
        
        filter.setInputImage(image)
        
        baseImageView.contentMode = .scaleAspectFit
        scaleMarkingView.contentMode = .scaleAspectFit
        histogramImageView.contentMode = .scaleToFill
        
        sampleNumberLabel.text = "Sample \(settings.getNextSampleNumber())"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !viewDidAppearHasRun {
            let lumaHistogram = getLumaHistogram(image: image)
            
            // Guess a good threshold to start at; the user can adjust with the slider later.
            let suggestedThreshold = otsusMethod(histogram: lumaHistogram)
            thresholdSlider.value = 1 - suggestedThreshold
            setThreshold(suggestedThreshold)
            
            // Draw the histogram to make user adjustment easier.
            drawHistogram(lumaHistogram: lumaHistogram)
            
            thresholdSlider.isEnabled = true
            completeButton.isEnabled = true
            
            viewDidAppearHasRun = true
        }
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is thresholdingComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "thresholdingComplete"
        {
            guard let destination = segue.destination as? ScaleIdentificationViewController else {
                fatalError("Expected the next view to be the scale identification view but is \(segue.destination)")
            }
            
            destination.settings = settings
            destination.sourceType = sourceType
            destination.cgImage = ciToCgImage(ciImageThresholded!)
            destination.uiImage = baseImageView.image
            
            setBackButton(self: self)
        }
    }
    
    // MARK: - UIScrollViewDelegate overrides
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollableView
    }
    
    // MARK: - Helpers
    
    private func setThreshold(_ threshold: Float) {
        filter.threshold = threshold
        ciImageThresholded = filter.outputImage
        baseImageView.image = ciToUiImage(ciImageThresholded!)
    }
    
    private func drawHistogram(lumaHistogram: [Int]) {
        let maxValue = lumaHistogram.max()!
        
        let drawingManager = DrawingManager(withCanvasSize: CGSize(width: NUMBER_OF_HISTOGRAM_BUCKETS, height: maxValue))
        for i in 0...NUMBER_OF_HISTOGRAM_BUCKETS - 1 {
            let x = NUMBER_OF_HISTOGRAM_BUCKETS - i - 1
            
            drawingManager.drawLine(from: CGPoint(x: x, y: maxValue), to: CGPoint(x: x, y: maxValue - lumaHistogram[i]))
        }
        drawingManager.finish(imageView: histogramImageView)
    }
}
