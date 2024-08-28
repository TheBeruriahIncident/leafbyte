//
//  ScaleIdentificationViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/10/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
import UIKit

final class ScaleIdentificationViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate {
    // MARK: - Fields

    // These are passed from the previous view.
    // swiftlint:disable implicitly_unwrapped_optional
    var settings: Settings!
    var sourceMode: ImageSourceMode!
    var originalImage: CGImage!
    var cgImage: CGImage!
    var ciImage: CIImage!
    var uiImage: UIImage!
    var inTutorial: Bool!
    var barcode: String?
    // swiftlint:enable implicitly_unwrapped_optional

    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false

    // The current mode can be scrolling or identifying the scale.
    var mode = Mode.scrolling

    enum Mode {
        case scrolling
        case identifyingScale
    }

    var numberOfValidScaleMarks = 0
    var scaleMarks = Array(repeating: CGPoint.zero, count: 4)

    // This is initialized in a call from viewDidAppear.
    // swiftlint:disable:next implicitly_unwrapped_optional
    var connectedComponentsInfo: ConnectedComponentsInfo!

    // These are initialized in viewDidLoad.
    // swiftlint:disable implicitly_unwrapped_optional
    // Projection from the full base image view to the actual image, so we can check if the touch is within the image.
    var baseImageViewToImage: Projection!
    var baseImageRect: CGRect!
    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: - Outlets

    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var scaleMarkingView: UIImageView!

    @IBOutlet weak var scaleIdentificationToggleButton: UIButton!
    @IBOutlet weak var clearScaleButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!

    @IBOutlet weak var sampleNumberButton: UIButton!
    @IBOutlet weak var scaleStatusText: UILabel!

    // MARK: - Actions

    @IBAction func goHome(_: Any) {
        dismissNavigationController(self: self)
    }

    @IBAction func toggleScaleIdentification(_: Any) {
        setScrollingMode(mode == .identifyingScale ? .scrolling : .identifyingScale)

        if mode == .scrolling {
            if numberOfValidScaleMarks < 4 {
                numberOfValidScaleMarks = 0
            } else {
                setScaleFound()
            }
        } else {
            setScaleNotFound()
        }

        drawMarkers()
    }

    @IBAction func clearScale(_: Any) {
        numberOfValidScaleMarks = 0
        drawMarkers()
        scaleStatusText.text = NSLocalizedString("No Scale", comment: "Shown if the user clears the scale")

        setScrollingMode(Mode.scrolling)
    }

    @IBAction func editSampleNumber(_: Any) {
        presentSampleNumberAlert(self: self, sampleNumberButton: sampleNumberButton, settings: settings)
    }

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollView(scrollView: scrollView, self: self)

        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = uiImage
        scaleMarkingView.contentMode = .scaleAspectFit

        // swiftlint:disable:next force_unwrapping
        baseImageViewToImage = Projection(fromView: baseImageView, toImageInView: baseImageView.image!)
        // swiftlint:disable:next force_unwrapping
        baseImageRect = CGRect(origin: CGPoint.zero, size: baseImageView.image!.size)

        setSampleNumberButtonText(sampleNumberButton, settings: settings)

        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewDidAppearHasRun {
            findScaleMark()
            setScrollingMode(Mode.scrolling)

            scaleIdentificationToggleButton.isEnabled = true
            clearScaleButton.isEnabled = true

            if inTutorial {
                self.performSegue(withIdentifier: "helpPopover", sender: nil)
            }

            viewDidAppearHasRun = true
        }
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // If the segue is scaleIdentificationComplete, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "scaleIdentificationComplete" {
            guard let destination = segue.destination as? ResultsViewController else {
                fatalError("Expected the next view to be the area calculation view but is \(segue.destination)")
            }

            destination.settings = settings
            destination.sourceMode = sourceMode
            destination.inTutorial = inTutorial
            destination.barcode = barcode
            destination.originalImage = originalImage

            if numberOfValidScaleMarks == 4 {
                guard let fixedImage = getFixedImage() else {
                    crashGracefully(viewController: self, message: "Failed to process image. Please reach out to leafbyte@zoegp.science with information about your image so we can fix this issue.")
                    return
                }
                destination.cgImage = fixedImage
                destination.uiImage = cgToUiImage(destination.cgImage)
                destination.scaleMarkPixelLength = (destination.cgImage.width + destination.cgImage.height) / 2
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

    // fixContentSize is called from a bunch of spots, but it's necessary; removing any degrades the UX.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fixContentSize()
    }

    // fixContentSize is called from a bunch of spots, but it's necessary; removing any degrades the UX.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        fixContentSize()
    }

    // MARK: - UIPopoverPresentationControllerDelegate overrides

    func adaptivePresentationStyle(for _: UIPresentationController) -> UIModalPresentationStyle {
        UIModalPresentationStyle.none
    }

    // MARK: - UIScrollViewDelegate overrides

    func viewForZooming(in _: UIScrollView) -> UIView? {
        scrollContentView
    }

    // fixContentSize is called from a bunch of spots, but it's necessary; removing any degrades the UX.
    func scrollViewDidEndZooming(_: UIScrollView, with _: UIView?, atScale scale: CGFloat) {
        fixContentSize(scale: scale)
    }

    // MARK: - UIResponder overrides

    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        // Touches don't matter in scrolling mode.
        if mode == .scrolling {
            return
        }

        guard let candidatePoint = touches.first?.location(in: baseImageView) else {
            return
        }
        let projectedPoint = baseImageViewToImage.project(point: candidatePoint)
        // Touches outside the image don't matter.
        if !baseImageRect.contains(projectedPoint) {
            return
        }

        let indexableImage = IndexableImage(cgImage)
        // Touches in white don't matter.
        guard let visiblePixel = searchForVisible(inImage: indexableImage, fromPoint: projectedPoint, checkingNoMoreThan: 10_000) else {
            return
        }

        if mode == .identifyingScale {
            let markNumber: Int
            if numberOfValidScaleMarks == 4 {
                markNumber = 0
            } else {
                markNumber = numberOfValidScaleMarks
            }

            // Since a non-white section in the image was touched, it may be a scale mark.
            let markFound = assessPossibleScaleMark(fromPointInMark: visiblePixel, inImage: indexableImage, withMinimumComponentSize: 1, markNumber: markNumber)
            if markFound {
                if numberOfValidScaleMarks == 4 {
                    numberOfValidScaleMarks = 0
                }

                numberOfValidScaleMarks += 1

                if numberOfValidScaleMarks == 4 {
                    setScaleFound()
                    setScrollingMode(.scrolling)
                }
                drawMarkers()
            }
        }
    }

    // MARK: - Helpers

    private func setScrollingMode(_ mode: Mode) {
        self.mode = mode

        scrollView.isUserInteractionEnabled = mode == .scrolling

        if mode == .scrolling {
            enableScaleIdentification()
        } else if mode == .identifyingScale {
            disableScaleIdentification()
        }
    }

    private func enableScaleIdentification() {
        if numberOfValidScaleMarks < 4 {
            scaleIdentificationToggleButton.setTitle(NSLocalizedString("Touch Scale", comment: "Enters the mode to identify the scale"), for: .normal)
        } else {
            scaleIdentificationToggleButton.setTitle(NSLocalizedString("Change Scale", comment: "Enters the mode to change the scale identification"), for: .normal)
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

        // If we have less than 5 components, we don't have scale marks.
        if occupiedLabelsAndSizes.count < 5 {
            setScaleNotFound()
            numberOfValidScaleMarks = 0
            return
        }

        let sortedOccupiedLabelsAndSizes = occupiedLabelsAndSizes.sorted { $0.1.standardPart > $1.1.standardPart }

        // The leaf is the biggest label and the scale marks are the next biggest labels.
        for markNumber in 0...3 {
            let scaleMarkLabel = sortedOccupiedLabelsAndSizes[markNumber + 1].key

            // Get a point in the scale mark.
            // swiftlint:disable:next force_unwrapping
            let (scaleMarkPointX, scaleMarkPointY) = connectedComponentsInfo.labelToMemberPoint[scaleMarkLabel]!

            let markFound = assessPossibleScaleMark(fromPointInMark: CGPoint(x: scaleMarkPointX, y: scaleMarkPointY), inImage: indexableImage, withMinimumComponentSize: 19, markNumber: markNumber)
            if !markFound {
                setScaleNotFound()
                numberOfValidScaleMarks = 0
                return
            }
        }

        numberOfValidScaleMarks = 4
        drawMarkers()
        setScaleFound()
    }

    private func assessPossibleScaleMark(fromPointInMark startPoint: CGPoint, inImage image: IndexableImage, withMinimumComponentSize minimumComponentSize: Int, markNumber: Int) -> Bool {
        guard let scaleMark = getCentroidOfComponent(inImage: image, fromPoint: startPoint, minimumComponentSize: minimumComponentSize) else {
            // If the mark is too big or too small, we get nil.
            // This allows us to discard noise, as well as objects that are too large and are unlikely to be the scale.
            return false
        }

        // If this is a duplicate mark, skip it.
        if markNumber > 0 {
            for index in 0...(markNumber - 1) {
                if scaleMarks[index] == scaleMark {
                    return false
                }
            }
        }

        scaleMarks[markNumber] = scaleMark

        return true
    }

    private func drawMarkers() {
        // swiftlint:disable:next force_unwrapping
        let drawingManager = DrawingManager(withCanvasSize: baseImageView.image!.size)
        drawingManager.context.setLineWidth(2)
        drawingManager.context.setStrokeColor(DrawingManager.darkRed.cgColor)

        // Draw Xs at each valid point.
        if numberOfValidScaleMarks > 0 && !(numberOfValidScaleMarks == 4 && mode == .identifyingScale) {
            for index in 1...numberOfValidScaleMarks {
                drawingManager.drawX(at: scaleMarks[index - 1], size: 5)
            }
        }

        drawingManager.finish(imageView: scaleMarkingView)
    }

    // Returns nil if the ci image cannot be converted to a cg image. We have no idea why this system libraries sometimes do this, but at least it's very rare.
    private func getFixedImage() -> CGImage? {
        // The coordinate space is flipped for CI.
        let adjustedCenters = scaleMarks.map { point in CGPoint(x: point.x, y: CGFloat(cgImage.height) - point.y) }
        let imageInsideScaleMarks = createImageFromQuadrilateral(in: ciImage, corners: adjustedCenters)
        let sizeToAdjustTo = min(1_200, roundToInt(min(imageInsideScaleMarks.extent.width, imageInsideScaleMarks.extent.height), rule: FloatingPointRoundingRule.down))
        guard let cgImage = ciToCgImage(imageInsideScaleMarks) else {
            return nil
        }
        return resizeImageIgnoringAspectRatioAndOrientation(cgImage, x: sizeToAdjustTo, y: sizeToAdjustTo)
    }

    private func setScaleFound() {
        scaleStatusText.text = NSLocalizedString("Scale Found", comment: "Shown when a scale mark is found")
    }

    private func setScaleNotFound() {
        scaleStatusText.text = NSLocalizedString("Scale Not Found", comment: "Shown when a scale mark is not found")
        drawMarkers()
    }

    // fixContentSize is called from a bunch of spots, but it's necessary; removing any degrades the UX.
    @objc
    func deviceRotated() {
        fixContentSize()
    }

    // If we don't have a scale already, infer it from how zoomed we are.
    private func fixContentSize() {
        fixContentSize(scale: scrollView.zoomScale)
    }

    // The layout engine is buggy and deals very poorly with scroll views after the screen is rotated and won't let you access the whole view, because the content size will be wrong.
    // It gets even worse if you zoom while rotated.
    // We need to fix the content size of the scroll view to be the size of the image, scaled by how much we're zoomed.
    private func fixContentSize(scale: CGFloat) {
        scrollView.contentSize = CGSize(width: baseImageView.frame.width * scale, height: baseImageView.frame.height * scale)
    }
}
