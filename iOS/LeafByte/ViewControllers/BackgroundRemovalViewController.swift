//
//  ThresholdingViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 12/23/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import Accelerate
import UIKit

final class BackgroundRemovalViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
    let histogramMax = 100
    let fuzzinessThreshold = 400

    // MARK: - Fields

    // These are passed from the previous view.
    var settings: Settings!
    var sourceType: UIImagePickerController.SourceType!
    var image: CGImage!
    var inTutorial: Bool!
    var barcode: String?

    let filter = ThresholdingFilter()

    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false

    var cgImageThresholded: CGImage?
    var ciImageThresholded: CIImage?

    // MARK: - Outlets

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var histogramImageView: UIImageView!
    @IBOutlet weak var thresholdSlider: UISlider!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var sampleNumberButton: UIButton!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var fuzzinessWarning: UIButton!

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

    @IBAction func editSampleNumber(_ sender: Any) {
        presentSampleNumberAlert(self: self, sampleNumberButton: sampleNumberButton, settings: settings)
    }

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        if inTutorial {
            // Since we'll have a real back button, hide our fake back button.
            self.navigationItem.leftBarButtonItems = [self.navigationItem.leftBarButtonItems![1]]
        }

        smoothTransitions(self: self)

        setupScrollView(scrollView: scrollView, self: self)

        filter.setInputImage(image: image, useBlackBackground: settings.useBlackBackground)

        baseImageView.contentMode = .scaleAspectFit
        histogramImageView.contentMode = .scaleToFill

        setSampleNumberButtonText(sampleNumberButton, settings: settings)

        // Disable swiping right to go back in the navigation controller (it gets in the way when zooming/drawing).
        self.navigationController!.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewDidAppearHasRun {
            let lumaHistogram = getLumaHistogram(image: image)

            // Guess a good threshold to start at; the user can adjust with the slider later.
            let suggestedThreshold = otsusMethod(histogram: lumaHistogram)
            thresholdSlider.value = 1 - suggestedThreshold
            setThreshold(suggestedThreshold)

            // Sum the 2 buckets before and after the threshold in the histogram to get the "fuzziness level".
            // If the fuzziness level is above a threshold (different threshold than the main threshold here), the image is warned to be fuzzy.
            // This essentially represents the amount of pixels that'll change if you slightly adjust the slider.
            let intThreshold = roundToInt(suggestedThreshold * Float(numberOfHistogramBuckets))
            let fuzzinessLevel = lumaHistogram[intThreshold - 1...intThreshold + 2].reduce(0, +)
            if fuzzinessLevel > fuzzinessThreshold {
                fuzzinessWarning.isEnabled = true
                fuzzinessWarning.setTitle(NSLocalizedString("Warning: Image may be fuzzy", comment: "Shown if slight adjustments to the slider would have too much effect on the image"), for: .normal)
            }

            // Draw the histogram to make user adjustment easier.
            drawHistogram(lumaHistogram: lumaHistogram)

            thresholdSlider.isEnabled = true
            completeButton.isEnabled = true

            if inTutorial {
                self.performSegue(withIdentifier: "helpPopover", sender: nil)
            }

            viewDidAppearHasRun = true
        }
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is thresholdingComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "thresholdingComplete" {
            guard let destination = segue.destination as? ScaleIdentificationViewController else {
                fatalError("Expected the next view to be the scale identification view but is \(segue.destination)")
            }

            destination.settings = settings
            destination.sourceType = sourceType
            destination.originalImage = image
            destination.cgImage = cgImageThresholded
            destination.ciImage = ciImageThresholded
            destination.uiImage = baseImageView.image
            destination.inTutorial = inTutorial
            destination.barcode = barcode

            setBackButton(self: self, next: destination)
        } else if segue.identifier == "helpPopover" || segue.identifier == "fuzzinessHelpPopover" {
            setupPopoverViewController(segue.destination, self: self)
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate overrides

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    // MARK: - UIScrollViewDelegate overrides

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollContentView
    }

    // MARK: - Helpers

    private func setThreshold(_ threshold: Float) {
        filter.threshold = threshold
        ciImageThresholded = filter.outputImage
        cgImageThresholded = ciToCgImage(ciImageThresholded!)
        baseImageView.image = cgToUiImage(cgImageThresholded!)
    }

    private func drawHistogram(lumaHistogram: [Int]) {
        let drawingManager = DrawingManager(withCanvasSize: CGSize(width: numberOfHistogramBuckets, height: histogramMax))

        let maxValue = lumaHistogram.max()!

        for i in 0...numberOfHistogramBuckets - 1 {
            let x = numberOfHistogramBuckets - i - 1
            let height = roundToInt(Double(histogramMax) * Double(lumaHistogram[i]) / Double(maxValue), rule: .down)

            drawingManager.drawLine(from: CGPoint(x: x, y: histogramMax), to: CGPoint(x: x, y: histogramMax - height))
        }
        drawingManager.finish(imageView: histogramImageView)
    }
}
