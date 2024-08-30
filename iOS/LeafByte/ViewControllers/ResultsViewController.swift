//
//  ResultsViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 12/24/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import CoreGraphics
import PhotosUI
import UIKit

final class ResultsViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, PHPickerViewControllerDelegate {
    // MARK: - Fields

    // These are passed from the previous view.
    // swiftlint:disable implicitly_unwrapped_optional
    var settings: Settings!
    var sourceMode: ImageSourceMode!
    var originalImage: CGImage!
    var cgImage: CGImage!
    var uiImage: UIImage!
    var scaleMarkPixelLength: Int?
    var inTutorial: Bool!
    var barcode: String?
    var initialConnectedComponentsInfo: ConnectedComponentsInfo!
    // swiftlint:enable implicitly_unwrapped_optional

    // These are initialized in viewDidLoad.
    // swiftlint:disable implicitly_unwrapped_optional
    // Projection from the drawing space back to the base image, so we can check if the drawing is in bounds.
    var userDrawingToBaseImage: Projection!
    var baseImageRect: CGRect!
    // Projection from the drawing space back to the filled holes image, so we can check if an exclusion makes sense.
    var userDrawingToFilledHoles: Projection!
    // swiftlint:enable implicitly_unwrapped_optional

    enum ActionType {
        case drawing
        case exclusion
    }

    struct Action {
        let type: ActionType
        // Each drawing is a list of points to be connected by lines.
        // Each exclusion is a single point.
        let points: [CGPoint]
    }

    // Track the previous actions to enable undoing. Previously we also enabled redoing, but it wasn't useful and just served as clutter.
    var undoBuffer = [Action]()

    // Track the current touch path. If in drawing mode, this list of points will be connected by lines.
    var currentTouchPath = [CGPoint]()

    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    // It seems like this view should only appear once anyways, except that the flicker when the image picker closes counts as an appearance.
    var viewDidAppearHasRun = false

    // The current mode can be scrolling, drawing, or marking excluded consumed area.
    var mode = Mode.scrolling

    enum Mode {
        case scrolling
        case drawing
        case markingExcludedConsumedArea
    }

    // These are initialized from a call from viewDidAppear.
    // Track the actual results.
    var formattedPercentConsumed: String! // swiftlint:disable:this implicitly_unwrapped_optional
    var formattedLeafAreaIncludingConsumedAreaInUnits2: String?
    var formattedConsumedAreaInUnits2: String?

    let imagePicker = UIImagePickerController()
    // This is not weak, because we want to reuse this, but the reference to this class within the delegate is
    // swiftlint:disable:next implicitly_unwrapped_optional weak_delegate
    var pHPickerPresentationControllerDelegate: PHPickerPresentationControllerDelegate! // Cannot be initialized immediately as it needs self

    // This is set while choosing the next image and is passed to the next thresholding view.
    var selectedImage: CGImage?

    // A point on the leaf at which to mark the leaf.
    var pointOnLeaf: (Int, Int)?

    // MARK: - Outlets

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var leafHolesView: UIImageView!
    @IBOutlet weak var markingsView: UIImageView!
    @IBOutlet weak var userDrawingView: UIImageView!
    @IBOutlet weak var grid: UIImageView!

    @IBOutlet weak var drawingToggleButton: UIButton!
    @IBOutlet weak var excludeConsumedAreaToggleButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!

    @IBOutlet weak var sampleNumberButton: UIButton!
    @IBOutlet weak var resultsText: UILabel!
    @IBOutlet weak var notesField: UITextField!

    // MARK: - Actions

    @IBAction func toggleDrawingMode(_: Any) {
        setScrollingMode(mode == .drawing ? .scrolling : .drawing)
    }

    @IBAction func undo(_: Any) {
        // Remove the last action from the buffer.
        undoBuffer.removeLast()

        // Wipe the screen and redo all action except the one we just "undid".
        initializeImage(view: userDrawingView, size: uiImage.size)
        initializeImage(view: markingsView, size: uiImage.size)
        undoBuffer.forEach { drawing in doAction(drawing) }

        // Update the buttons.
        undoButton.isEnabled = !undoBuffer.isEmpty

        self.calculateArea()
    }

    @IBAction func goHome(_: Any) {
        dismissNavigationController(self: self)
    }

    @IBAction func share(_: Any) {
        let imageToShare = getCombinedImage()
        // swiftlint:disable:next force_unwrapping
        let dataToShare = [ imageToShare, resultsText.text! + NSLocalizedString(" Analyzed with LeafByte https://zoegp.science/leafbyte", comment: "Shown after the results when sharing the results, e.g. on social media. Note the leading space that separates from the results") ] as [Any]
        let activityViewController = UIActivityViewController(activityItems: dataToShare, applicationActivities: nil)

        // Exclude activity types that don't make sense here.
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.addToReadingList,
            UIActivity.ActivityType.assignToContact,
            UIActivity.ActivityType.openInIBooks,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.print
        ]

        // Make this work on iPads ( https://stackoverflow.com/questions/25644054/uiactivityviewcontroller-crashing-on-ios8-ipads ).
        activityViewController.popoverPresentationController?.sourceView = self.view

        self.present(activityViewController, animated: true, completion: nil)
    }

    @IBAction func nextImage(_: Any) {
        // Disable to prevent double serializing.
        completeButton.isEnabled = false

        let afterSerialization = {
            // sourceMode is set during segue and is generally implicitly unwrapped; we just have to manually do it for the switch
            // swiftlint:disable:next force_unwrapping
            switch self.sourceMode! {
            case .camera:
                // swiftlint:disable:next trailing_closure
                requestCameraAccess(self: self, onSuccess: {
                    DispatchQueue.main.async {
                        if self.settings.useBarcode {
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "toBarcodeScanning", sender: self)
                            }
                        } else {
                            presentImagePickerOrPHPicker(self: self, presentationControllerDelegate: self.pHPickerPresentationControllerDelegate, imagePicker: self.imagePicker, sourceMode: .camera)
                        }
                    }
                })

            case .photoLibrary:
                DispatchQueue.main.async {
                    presentImagePickerOrPHPicker(self: self, presentationControllerDelegate: self.pHPickerPresentationControllerDelegate, imagePicker: self.imagePicker, sourceMode: .photoLibrary)
                }
            }
        }

        // Record everything before moving on.
        handleSerialization(onSuccess: afterSerialization)
    }

    @IBAction func editSampleNumber(_: Any) {
        presentSampleNumberAlert(self: self, sampleNumberButton: sampleNumberButton, settings: settings)
    }

    @IBAction func excludeConsumedArea(_: Any) {
        setScrollingMode(mode == .markingExcludedConsumedArea ? .scrolling : .markingExcludedConsumedArea)
    }

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        // So UI tests can find the results text
        resultsText.accessibilityIdentifier = "resultsValue"

        setupScrollView(scrollView: scrollView, self: self)
        setupImagePicker(imagePicker: imagePicker, self: self)

        pHPickerPresentationControllerDelegate = PHPickerPresentationControllerDelegate(viewController: self)

        baseImageView.contentMode = .scaleAspectFit
        leafHolesView.contentMode = .scaleAspectFit
        markingsView.contentMode = .scaleAspectFit
        userDrawingView.contentMode = .scaleAspectFit

        baseImageView.image = uiImage
        initializeImage(view: leafHolesView, size: uiImage.size)
        initializeImage(view: markingsView, size: uiImage.size)
        initializeImage(view: userDrawingView, size: uiImage.size)

        // swiftlint:disable:next force_unwrapping
        userDrawingToBaseImage = Projection(fromView: baseImageView, toImageInView: baseImageView.image!)
        // swiftlint:disable:next force_unwrapping
        baseImageRect = CGRect(origin: CGPoint.zero, size: baseImageView.image!.size)

        // swiftlint:disable:next force_unwrapping
        userDrawingToFilledHoles = Projection(fromView: baseImageView, toImageInView: leafHolesView.image!)

        setSampleNumberButtonText(sampleNumberButton, settings: settings)

        setScrollingMode(.scrolling)

        // Setup to get a callback when return is pressed on a keyboard.
        // Note that current iOS is buggy and doesn't show the return button for number keyboards even when enabled; this aims to handle that case once it works.
        notesField.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(deviceRotated), name: UIDevice.orientationDidChangeNotification, object: nil)

        maintainOldModalPresentationStyle(viewController: imagePicker)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !viewDidAppearHasRun {
            let baseImage = IndexableImage(cgImage)
            let combinedImage = LayeredIndexableImage(width: baseImage.width, height: baseImage.height)
            combinedImage.addImage(baseImage)

            // If there is no scale, and thus the image wasn't changed, we may already have these calculations done.
            if initialConnectedComponentsInfo == nil {
                initialConnectedComponentsInfo = labelConnectedComponents(image: combinedImage)
            }

            useConnectedComponentsResults(connectedComponentsInfo: initialConnectedComponentsInfo, image: combinedImage)

            initializeGrid()

            if inTutorial {
                self.performSegue(withIdentifier: "helpPopover", sender: nil)
            }

            viewDidAppearHasRun = true
        }
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let destination = segue.destination as? BackgroundRemovalViewController else {
                fatalError("Expected the next view to be the thresholding view but is \(segue.destination)")
            }

            destination.settings = settings
            destination.sourceMode = sourceMode
            // swiftlint:disable:next force_unwrapping
            destination.image = selectedImage!
            destination.inTutorial = false
        }
        // If the segue is toBarcodeScanning, we're transitioning forward in the main flow, but with barcode scanning.
        else if segue.identifier == "toBarcodeScanning" {
            if #available(iOS 10.0, *) {
                guard let destination = segue.destination as? BarcodeScanningViewController else {
                    fatalError("Expected the next view to be the barcode scanning view but is \(segue.destination)")
                }

                destination.settings = settings
            } else {
                fatalError("Attempting to use barcode scanning pre-iOS 10.0")
            }
        } else if segue.identifier == "helpPopover" {
            setupPopoverViewController(segue.destination, self: self)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
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
    func scrollViewDidEndZooming(_ _: UIScrollView, with _: UIView?, atScale scale: CGFloat) {
        fixContentSize(scale: scale)
    }

    // MARK: - UIResponder overrides

    // Note that these callbacks don't run when in scroll mode, because scrollView isn't enabled for user interaction.
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        // If a user taps outside of the keyboard, close the keyboard.
        dismissKeyboard()

        if mode == .scrolling {
            return
        }

        guard let candidatePoint = touches.first?.location(in: userDrawingView) else {
            return
        }
        // "Drawing" outside the image doesn't count.
        if !isTouchedPointInBaseImage(candidatePoint) {
            return
        }

        currentTouchPath.append(candidatePoint)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        if mode == .scrolling {
            return
        }

        guard let candidatePoint = touches.first?.location(in: userDrawingView) else {
            return
        }
        // Touching outside the image doesn't count.
        if !isTouchedPointInBaseImage(candidatePoint) {
            return
        }

        // If there was a previous point, connect the dots.
        if !currentTouchPath.isEmpty && mode == .drawing {
            // swiftlint:disable:next force_unwrapping
            drawLine(fromPoint: currentTouchPath.last!, toPoint: candidatePoint)
        }

        currentTouchPath.append(candidatePoint)
    }

    override func touchesEnded(_: Set<UITouch>, with _: UIEvent?) {
        if mode == .scrolling {
            return
        }

        // If there were no valid touches, don't create an action.
        if currentTouchPath.isEmpty {
            return
        }

        let action: Action
        if mode == .drawing {
            // If only one point, nothing has been drawn yet.
            if currentTouchPath.count == 1 {
                // swiftlint:disable:next force_unwrapping
                drawLine(fromPoint: currentTouchPath.last!, toPoint: currentTouchPath.last!)
            }

            action = Action(type: .drawing, points: currentTouchPath)
        } else {
            // swiftlint:disable:next force_unwrapping
            let touchedPoint = currentTouchPath.last!

            // If the touched point is not on a filled area, it's likely a mistake, so ignore it.
            let touchedPointInHoles = userDrawingToFilledHoles.project(point: touchedPoint)
            // swiftlint:disable:next force_unwrapping
            guard let leafHolesViewCgImage = uiToCgImage(leafHolesView.image!) else {
                crashGracefully(viewController: self, message: "Failed to process image during exclusion. Please reach out to leafbyte@zoegp.science with information about your image so we can fix this issue.")
                return
            }
            if IndexableImage(leafHolesViewCgImage).getPixel(x: roundToInt(touchedPointInHoles.x), y: roundToInt(touchedPointInHoles.y)).isInvisible() {
                return
            }

            // If the touched point is on the leaf or scale, an exclusion makes no sense, so ignore it.
            // That way a user can tap a bunch trying to get at the excluded area that's within a leaf.
            let touchedPointOnLeaf = userDrawingToBaseImage.project(point: touchedPoint)
            if IndexableImage(cgImage).getPixel(x: roundToInt(touchedPointOnLeaf.x), y: roundToInt(touchedPointOnLeaf.y)).isVisible() {
                return
            }

            action = Action(type: .exclusion, points: [ touchedPoint ])
            doAction(action)
        }

        // Move the current action to the undo buffer.
        undoBuffer.append(action)

        currentTouchPath = []

        // Update the undo button.
        undoButton.isEnabled = true

        self.calculateArea()

        // Switch back to scrolling after each line drawn.
        setScrollingMode(.scrolling)
    }

    // MARK: - UIImagePickerControllerDelegate overrides

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        finishWithImagePicker(self: self, info: info) { selectedImage = $0 }
    }

    // If the image picker is canceled, dismiss it.
    // Also go back to the home screen, to sidestep complications around re-saving the same data (it's as if you're in the original image picker).
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        dismissNavigationController(self: self)
    }

    // MARK: - PHPickerViewControllerDelegate overrides

    @available(iOS 14.0, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        finishWithPHPicker(self: self, picker: picker, didFinishPicking: results, onCancel: {
            // If the phpicker is canceled, go back to the home screen, to sidestep complications around re-saving the same data (it's as if you're in the original image picker).
            dismissNavigationController(self: self)
        }, selectImage: { self.selectedImage = $0 })
    }

    // MARK: - UITextFieldDelegate overrides

    func textFieldDidBeginEditing(_: UITextField) {
        // Disable the gesture recognition so that we can catch touches outside of the keyboard to cancel the keyboard.
        scrollView.isUserInteractionEnabled = false
    }

    // Called when return is pressed on the keyboard.
    func textFieldShouldReturn(_: UITextField) -> Bool {
        dismissKeyboard()
        return true
    }

    // MARK: - Helpers

    // We want to limit touch interactions to points that match up to the base image.
    // Otherwise, since connected components and flood filling are calculated within the base image, those operations will seem broken.
    private func isTouchedPointInBaseImage(_ point: CGPoint) -> Bool {
        let projectedPoint = userDrawingToBaseImage.project(point: point, constrain: false)
        return baseImageRect.contains(projectedPoint)
    }

    // Carry out an action of any type.
    private func doAction(_ action: Action) {
        switch action.type {
        case .drawing:
            drawCompleteDrawing(action.points)

        case .exclusion:
            // Originally this drew an X where things were excluded, but that was determined to just be noise.
            break
        }
    }

    // Draw a complete drawing, made up of a sequence of points.
    private func drawCompleteDrawing(_ drawing: [CGPoint]) {
        drawLine(points: drawing)
    }

    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        drawLine(points: [fromPoint, toPoint])
    }

    private func drawLine(points: [CGPoint]) {
        // swiftlint:disable:next force_unwrapping
        let drawingManager = DrawingManager(withCanvasSize: baseImageView.image!.size, withProjection: userDrawingToBaseImage)
        drawingManager.context.setStrokeColor(DrawingManager.darkGreen.cgColor)
        drawingManager.context.setLineWidth(2)

        if points.count == 1 {
            // swiftlint:disable:next force_unwrapping
            drawingManager.drawLine(from: points.first!, to: points.first!)
        } else {
            for index in 0...points.count - 2 {
                drawingManager.drawLine(from: points[index], to: points[index + 1])
            }
        }

        drawingManager.finish(imageView: userDrawingView, addToPreviousImage: true)
    }

    private func setScrollingMode(_ mode: Mode) {
        self.mode = mode

        scrollView.isUserInteractionEnabled = mode == .scrolling
        grid.isHidden = mode == .scrolling

        if mode == .scrolling {
            enableDrawing()
            enableExcluding()
        } else if mode == .drawing {
            disableDrawing()
            enableExcluding()
        } else if mode == .markingExcludedConsumedArea {
            enableDrawing()
            disableExcluding()
        }
    }

    private func enableDrawing() {
        drawingToggleButton.setTitle(NSLocalizedString("Draw", comment: "Enters the mode to draw leaf edges"), for: .normal)
    }

    private func disableDrawing() {
        drawingToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to draw leaf edges"), for: .normal)
    }

    private func enableExcluding() {
        excludeConsumedAreaToggleButton.setTitle(NSLocalizedString("Exclude Area", comment: "Enters the mode to mark areas to exclude from calculation"), for: .normal)
    }

    private func disableExcluding() {
        excludeConsumedAreaToggleButton.setTitle(NSLocalizedString("Cancel", comment: "Exits the mode to mark areas to exclude from calculation"), for: .normal)
    }

    private func calculateArea() {
        // The BooleanIndexableImage will be a view across both sources of pixels.
        // First we add the base image of the leaf.
        let baseImage = IndexableImage(cgImage)
        let combinedImage = LayeredIndexableImage(width: baseImage.width, height: baseImage.height)
        combinedImage.addImage(baseImage)

        // Then we include any user drawings.
        // swiftlint:disable:next force_unwrapping
        guard let userDrawingViewCgImage = uiToCgImage(userDrawingView.image!) else {
            crashGracefully(viewController: self, message: "Failed to process image during area calculation. Please reach out to leafbyte@zoegp.science with information about your image so we can fix this issue.")
            return
        }
        let userDrawing = IndexableImage(userDrawingViewCgImage)
        combinedImage.addImage(userDrawing)

        // Connected components will identify the label of the leaf (if not using the default point) and any excluded areas.
        var pointsToIdentify = [PointToIdentify]()
        let exclusions = undoBuffer.filter { $0.type == .exclusion }
            .map { userDrawingToBaseImage.project(point: $0.points[0]) }
            .map { PointToIdentify($0) }
        pointsToIdentify.append(contentsOf: exclusions)

        let connectedComponentsInfo = labelConnectedComponents(image: combinedImage, pointsToIdentify: pointsToIdentify)

        useConnectedComponentsResults(connectedComponentsInfo: connectedComponentsInfo, image: combinedImage)
    }

    private func useConnectedComponentsResults(connectedComponentsInfo: ConnectedComponentsInfo, image: LayeredIndexableImage) {
        // swiftlint:disable:next force_unwrapping
        let drawingManager = DrawingManager(withCanvasSize: leafHolesView.image!.size)
        drawingManager.context.setStrokeColor(DrawingManager.lightGreen.cgColor)
        drawingManager.context.setLineWidth(2)
        drawingManager.context.setLineCap(.square)

        let results = Self.useConnectedComponentsResults(connectedComponentsInfo: connectedComponentsInfo, image: image, setNoLeafFound: { setNoLeafFound() }, setPointOnLeaf: { pointOnLeaf = $0 }, drawMarkers: { drawMarkers() }, floodFill: { image, floodStartPoint in floodFill(image: image, fromPoint: floodStartPoint, drawingTo: drawingManager) }, finishWithDrawingManager: { drawingManager.finish(imageView: leafHolesView) })
        guard let results else {
            return
        }

        let consumedAreaInPixels = results.consumedAreaInPixels
        let leafAreaIncludingConsumedAreaInPixels = results.leafAreaIncludingConsumedAreaInPixels
        let percentConsumed = results.percentConsumed

        // Set the result of the calculation, giving absolute area if the scale is set.
        formattedPercentConsumed = formatDouble(withThreeDecimalPoints: percentConsumed)
        if scaleMarkPixelLength != nil {
            let leafAreaIncludingConsumedAreaInUnits2 = convertPixelsToUnits2(leafAreaIncludingConsumedAreaInPixels)
            formattedLeafAreaIncludingConsumedAreaInUnits2 = formatDouble(withThreeDecimalPoints: leafAreaIncludingConsumedAreaInUnits2)
            let consumedAreaInUnits2 = convertPixelsToUnits2(consumedAreaInPixels)
            formattedConsumedAreaInUnits2 = formatDouble(withThreeDecimalPoints: consumedAreaInUnits2)

            // Set the number of lines or else lines past the first are dropped.
            resultsText.numberOfLines = 3
            let unit = settings.getUnit()
            // swiftlint:disable:next force_unwrapping
            resultsText.text = String.localizedStringWithFormat(NSLocalizedString("Total Leaf Area= %@ %@2\nConsumed Leaf Area= %@ %@2\nPercent Consumed= %@%%", comment: "Results including absolute data"), formattedLeafAreaIncludingConsumedAreaInUnits2!, unit, formattedConsumedAreaInUnits2!, unit, formattedPercentConsumed!)
        } else {
            formattedLeafAreaIncludingConsumedAreaInUnits2 = nil
            formattedConsumedAreaInUnits2 = nil
            // swiftlint:disable:next force_unwrapping
            resultsText.text = String.localizedStringWithFormat(NSLocalizedString("Percent Consumed= %@%%", comment: "Results with only relative data"), formattedPercentConsumed!)
        }
    }

    struct Results {
        let consumedAreaInPixels: Int
        let leafAreaIncludingConsumedAreaInPixels: Int

        var percentConsumed: Double {
            Double(consumedAreaInPixels) / Double(leafAreaIncludingConsumedAreaInPixels) * 100
        }
    }

    // This logic is extracted to a static method so that it can be easily tested. This isn't as elegant as it could be if this wasn't retro-fitted, but it's not terrible.
    static func useConnectedComponentsResults(connectedComponentsInfo: ConnectedComponentsInfo, image: LayeredIndexableImage, setNoLeafFound: () -> Void, setPointOnLeaf: ((Int, Int)?) -> Void, drawMarkers: () -> Void, floodFill: (LayeredIndexableImage, CGPoint) -> Void, finishWithDrawingManager: () -> Void) -> Results? {
        let labelsAndSizes = connectedComponentsInfo.labelToSize.sorted { $0.1.total() > $1.1.total() }
        // Assume the largest occupied component is the leaf.
        let leafLabelAndSize = labelsAndSizes.first { $0.key > 0 }

        guard let leafLabelAndSize else {
            // This is a blank image, and trying to calculate area will crash.
            setNoLeafFound()
            return nil
        }
        setPointOnLeaf(connectedComponentsInfo.labelToMemberPoint[leafLabelAndSize.key])
        drawMarkers()

        // swiftlint:disable:next force_unwrapping
        let leafLabels = connectedComponentsInfo.equivalenceClasses.getElementsInClassWith(leafLabelAndSize.key)!
        let leafAreaInPixels = leafLabelAndSize.value.standardPart

        let emptyLabelsAndSizes = labelsAndSizes.filter { $0.key < 0 }

        if emptyLabelsAndSizes.isEmpty {
            // This is a solid image, so calculating area is pointless.
            setNoLeafFound()
            return nil
        }

        let emptyLabelsWithoutBackground = emptyLabelsAndSizes.filter { $0.key != backgroundLabel }

        // Filter out any areas marked for exclusion.
        let labelsToExclude = connectedComponentsInfo.labelsOfPointsToIdentify.values.filter { $0 != leafLabelAndSize.key }
        let emptyLabelsToTreatAsConsumed = emptyLabelsWithoutBackground.filter { !labelsToExclude.contains($0.key) }

        var consumedAreaInPixels = leafLabelAndSize.value.drawingPart
        for emptyLabelAndSize in emptyLabelsToTreatAsConsumed {
            // This component is a hole if it neighbors the leaf (since we already filtered out the background).
            // swiftlint:disable:next force_unwrapping
            if !connectedComponentsInfo.emptyLabelToNeighboringOccupiedLabels[emptyLabelAndSize.key]!.isDisjoint(with: leafLabels) {
                // Add to the consumed size.
                consumedAreaInPixels += emptyLabelAndSize.value.standardPart

                // And fill in the consumed area.
                // swiftlint:disable:next force_unwrapping
                let (floodStartX, floodStartY) = connectedComponentsInfo.labelToMemberPoint[emptyLabelAndSize.key]!

                floodFill(image, CGPoint(x: floodStartX, y: floodStartY))
            }
        }

        finishWithDrawingManager()

        return Results(consumedAreaInPixels: consumedAreaInPixels, leafAreaIncludingConsumedAreaInPixels: leafAreaInPixels + consumedAreaInPixels)
    }

    private func convertPixelsToUnits2(_ pixels: Int) -> Double {
        guard let scaleMarkPixelLength else {
            fatalError("Attempting to calculate absolute area without scale set.")
        }

        return Self.convertPixelsToUnits2(pixels: pixels, scaleMarkPixelLength: scaleMarkPixelLength, scaleMarkLength: settings.scaleMarkLength)
    }

    // Used in testing
    static func convertPixelsToUnits2(pixels: Int, scaleMarkPixelLength: Int, scaleMarkLength: Double) -> Double {
        let unitsPerPixel = scaleMarkLength / Double(scaleMarkPixelLength)
        return pow(unitsPerPixel, 2) * Double(pixels)
    }

    private func formatDouble(withThreeDecimalPoints double: Double) -> String {
        String(format: "%.3f", double)
    }

    private func getCombinedImage() -> UIImage {
        // The markingsView is not included, as it's not pretty in a saved image.
        combineImages([ leafHolesView, userDrawingView, baseImageView ])
    }

    private func setNoLeafFound() {
        resultsText.text = NSLocalizedString("No leaf found", comment: "Shown if the image is not valid to calculate results")
    }

    private func handleSerialization(onSuccess: @escaping () -> Void) {
        let onFailure = { (serializationFailureCause: SerializationFailureCause) in
            switch serializationFailureCause {
            case .googleDrive:
                self.handleGoogleDriveFailure(onSuccess: onSuccess)

            case .gps:
                self.handleGpsFailure()

            case .imageToPng:
                self.handleImageToPngFailure()

            case .writingToFile:
                self.handleWritingToFileFailure()
            }
        }

        serialize(settings: settings, image: cgToUiImage(originalImage), percentConsumed: formattedPercentConsumed, leafAreaInUnits2: formattedLeafAreaIncludingConsumedAreaInUnits2, consumedAreaInUnits2: formattedConsumedAreaInUnits2, barcode: barcode, notes: notesField.text ?? "", callingViewController: self, onSuccess: onSuccess, onFailure: onFailure)
    }

    private func handleGoogleDriveFailure(onSuccess: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("Could not save to Google Drive.", comment: "Shown if saving to Google Drive fails"), preferredStyle: .alert)
            // swiftlint:disable:next trailing_closure
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancels the attempt to save"), style: .default, handler: { _ in
                DispatchQueue.main.async {
                    self.completeButton.isEnabled = true
                }
            })

            // The Files App was added in iOS 11, but saved data can be accessed in iTunes File Sharing in any version.
            var localStorageName: String
            if #available(iOS 11.0, *) {
                localStorageName = NSLocalizedString("Files App", comment: "Name for local storage on iOS 11 and newer")
            } else {
                localStorageName = NSLocalizedString("Phone", comment: "Name for local storage before iOS 11")
            }

            // swiftlint:disable:next trailing_closure
            let switchToLocalAction = UIAlertAction(title: NSLocalizedString("Save to " + localStorageName, comment: "Shown if saving to Google Drive fails, to provide an alternative"), style: .default, handler: { _ in
                DispatchQueue.main.async {
                    if self.settings.dataSaveLocation == .googleDrive {
                        self.settings.dataSaveLocation = .local
                    }
                    if self.settings.imageSaveLocation == .googleDrive {
                        self.settings.imageSaveLocation = .local
                    }
                    self.settings.serialize()

                    self.handleSerialization(onSuccess: onSuccess)
                }
            })
            // swiftlint:disable:next trailing_closure
            let retryAction = UIAlertAction(title: NSLocalizedString("Retry", comment: "Allows attempting to save to Google Drive again"), style: .default, handler: { _ in
                self.handleSerialization(onSuccess: onSuccess)
            })

            alertController.addAction(cancelAction)
            alertController.addAction(switchToLocalAction)
            alertController.addAction(retryAction)

            self.present(alertController, animated: true, completion: nil)
        }
    }

    private func handleGpsFailure() {
        DispatchQueue.main.async {
            presentAlert(self: self, title: NSLocalizedString("Could not get GPS location.", comment: "Title of the alert that GPS location access failed"), message: NSLocalizedString("To confirm that LeafByte has location access, go your phone's Settings -> LeafByte -> Location. If you do not wish to record GPS location, you can turn GPS location saving off in the LeafByte in-app settings.", comment: "Explanation of how to proceed after GPS location access failed"))
            DispatchQueue.main.async {
                self.completeButton.isEnabled = true
            }
        }
    }

    private func handleWritingToFileFailure() {
        DispatchQueue.main.async {
            presentAlert(self: self, title: NSLocalizedString("Could not write file to Files App.", comment: "Title of the alert that writing image to file failed"), message: NSLocalizedString("Is there space on the phone? If so, please reach out to leafbyte@zoegp.science with details so we can fix this issue.", comment: "Explanation of how to proceed after writing image to file failed"))
            DispatchQueue.main.async {
                self.completeButton.isEnabled = true
            }
        }
    }

    private func handleImageToPngFailure() {
        DispatchQueue.main.async {
            presentAlert(self: self, title: NSLocalizedString("Could not process image.", comment: "Title of the alert that converting image to png failed"), message: NSLocalizedString("Is there something unusual about this image? Please reach out to leafbyte@zoegp.science with the image and any details so we can fix this issue.", comment: "Explanation of how to proceed after writing image to png failed"))
            DispatchQueue.main.async {
                self.completeButton.isEnabled = true
            }
        }
    }

    private func drawMarkers() {
        // swiftlint:disable:next force_unwrapping
        let drawingManager = DrawingManager(withCanvasSize: markingsView.image!.size)

        if pointOnLeaf != nil {
            // swiftlint:disable:next force_unwrapping
            drawingManager.drawLeaf(atPoint: CGPoint(x: pointOnLeaf!.0, y: pointOnLeaf!.1), size: 56)
        }

        drawingManager.finish(imageView: markingsView)
    }

    private func initializeGrid() {
        let size = 25
        let drawingManager = DrawingManager(withCanvasSize: grid.frame.size)
        drawingManager.context.setStrokeColor(gray: 0.5, alpha: 0.4)

        for y in stride(from: 0, to: roundToInt(grid.frame.height, rule: .down), by: size) {
            drawingManager.drawLine(from: CGPoint(x: 0, y: y), to: CGPoint(x: grid.frame.width, y: CGFloat(y)))
        }
        for x in stride(from: 0, to: roundToInt(grid.frame.width, rule: .down), by: size) {
            drawingManager.drawLine(from: CGPoint(x: x, y: 0), to: CGPoint(x: CGFloat(x), y: grid.frame.height))
        }

        drawingManager.finish(imageView: grid)
    }

    private func dismissKeyboard() {
        // Reenable gesture recognition if we disabled it for the keyboard.
        scrollView.isUserInteractionEnabled = mode == .scrolling

        self.view.endEditing(true)
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
