//
//  AreaCalculationViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class AreaCalculationViewController: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields
    
    // These are passed from the previous view.
    var sourceType: UIImagePickerControllerSourceType!
    var image: UIImage!
    var scaleMarkPixelLength: Int?
    
    // Projection from the drawing space back to the base image, so we can check if the drawing is in bounds.
    var userDrawingToBaseImage: Projection!
    var baseImageRect: CGRect!
    
    // Track the previous, current, and "future" drawings to enable undoing and redoing.
    // Each drawing is a list of points to be connected by lines.
    var undoBuffer = [[CGPoint]]()
    var currentDrawing = [CGPoint]()
    var redoBuffer = [[CGPoint]]()
    
    // The current mode can be scrolling or drawing.
    var inScrollingMode = true
    
    let imagePicker = UIImagePickerController()
    // This is set while choosing the next image and is passed to the next thresholding view.
    var selectedImage: UIImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var gestureRecognizingView: UIScrollView!
    @IBOutlet weak var scrollableView: UIView!
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var userDrawingView: UIImageView!
    @IBOutlet weak var leafHolesView: UIImageView!
    
    @IBOutlet weak var modeToggleButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    
    @IBOutlet weak var resultsText: UILabel!
    
    // MARK: - Actions
    
    @IBAction func toggleScrollingMode(_ sender: Any) {
        setScrollingMode(!inScrollingMode)
    }
    
    @IBAction func undo(_ sender: Any) {
        // Move the drawing from the undo buffer to the redo buffer.
        redoBuffer.append(undoBuffer.popLast()!)
        
        // Wipe the screen and redraw all drawings except the one we just "undid".
        userDrawingView.image = nil
        undoBuffer.forEach { drawing in drawCompleteDrawing(drawing) }
        
        // Update the buttons.
        calculateButton.isEnabled = true
        undoButton.isEnabled = !undoBuffer.isEmpty
        redoButton.isEnabled = true
    }
    
    @IBAction func redo(_ sender: Any) {
        // Move the drawing from the redo buffer to the undo buffer.
        let drawingToRedo = redoBuffer.popLast()!
        undoBuffer.append(drawingToRedo)
        
        // Simpler than undo, we can simply draw this one drawing.
        drawCompleteDrawing(drawingToRedo)
        
        // Update the buttons.
        calculateButton.isEnabled = true
        undoButton.isEnabled = true
        redoButton.isEnabled = !redoBuffer.isEmpty
    }
    
    @IBAction func calculate(_ sender: Any) {
        // Don't allow recalculation until there's a possibility of a different result.
        calculateButton.isEnabled = false
        
        resultsText.text = "Loading"
        // The label won't update until this action returns, so put this calculation on the queue, and it'll be executed right after this function ends.
        DispatchQueue.main.async {
            self.calculateArea()
        }
    }
    
    @IBAction func nextImage(_ sender: Any) {
        imagePicker.sourceType = sourceType
        
        if sourceType == .camera {
            requestCameraAccess(self: self, onSuccess: { self.present(self.imagePicker, animated: true, completion: nil) })
        } else {
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        setupGestureRecognizingView(gestureRecognizingView: gestureRecognizingView, self: self)
        setupImagePicker(imagePicker: imagePicker, self: self)
        
        baseImageView.contentMode = .scaleAspectFit
        baseImageView.image = image
        
        userDrawingToBaseImage = Projection(invertProjection: Projection(fromImageInView: baseImageView.image!, toView: baseImageView))
        baseImageRect = CGRect(origin: CGPoint.zero, size: baseImageView.image!.size)
        
        setScrollingMode(true)
        
        // TODO: is there a less stupid way to initialize the image?? maybe won't need
        UIGraphicsBeginImageContext(userDrawingView.frame.size)
        userDrawingView.image?.draw(in: CGRect(x: 0, y: 0, width: userDrawingView.frame.size.width, height: userDrawingView.frame.size.height))
        userDrawingView.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen"
        {
            guard let destination = segue.destination as? ThresholdingViewController else {
                fatalError("Expected the next view to be the thresholding view but is \(segue.destination)")
            }
            
            destination.sourceType = sourceType
            destination.image = selectedImage
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - UIScrollViewDelegate overrides
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollableView
    }
    
    // MARK: - UIResponder overrides
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // No drawing in scrolling mode.
        if inScrollingMode {
            return
        }
        
        let candidatePoint = (touches.first?.location(in: userDrawingView))!
        // "Drawing" outside the image doesn't count.
        if !isDrawingPointInBaseImage(candidatePoint) {
            return
        }
        
        currentDrawing.append(candidatePoint)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // No drawing in scrolling mode.
        if inScrollingMode {
            return
        }
        
        let candidatePoint = (touches.first?.location(in: userDrawingView))!
        // "Drawing" outside the image doesn't count.
        if !isDrawingPointInBaseImage(candidatePoint) {
            return
        }
        
        // If there was a previous point, connect the dots.
        if !currentDrawing.isEmpty {
            drawLine(fromPoint: currentDrawing.last!, toPoint: candidatePoint)
        }
        
        currentDrawing.append(candidatePoint)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // No drawing in scrolling mode or outside the image.
        if inScrollingMode || currentDrawing.isEmpty {
            return
        }
        
        // If only one point, nothing has been drawn yet.
        if currentDrawing.count == 1 {
            drawLine(fromPoint: currentDrawing.last!, toPoint: currentDrawing.last!)
        }
        
        // Move the current drawing to the undo buffer.
        undoBuffer.append(currentDrawing)
        currentDrawing = []
        // Clear the redo buffer.
        redoBuffer = []
        
        // Update the buttons, allow recalculation now that there's a possibility of a different result.
        calculateButton.isEnabled = true
        undoButton.isEnabled = true
        redoButton.isEnabled = false
    }
    
    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        finishWithImagePicker(self: self, info: info, selectImage: { selectedImage = $0 })
    }
    
    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    // We want to limit drawing interactions to points that match up to the base image.
    // Otherwise, since connected components and flood filling are calculated within the base image, those operations will seem broken.
    private func isDrawingPointInBaseImage(_ point: CGPoint) -> Bool {
        let projectedPoint = userDrawingToBaseImage.project(point: point)
        return baseImageRect.contains(projectedPoint)
    }
    
    // Draw a complete drawing, made up of a sequence of points.
    private func drawCompleteDrawing(_ drawing: [CGPoint]) {
        if drawing.count == 1 {
            drawLine(fromPoint: drawing.first!, toPoint: drawing.first!)
        } else {
            for index in 0...drawing.count - 2 {
                drawLine(fromPoint: drawing[index], toPoint: drawing[index + 1])
            }
        }
    }
    
    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        redoButton.isEnabled = false
        
        let drawingManager = DrawingManager(withCanvasSize: userDrawingView.frame.size)
        drawingManager.drawLine(from: fromPoint, to: toPoint)
        drawingManager.finish(imageView: userDrawingView, addToPreviousImage: true)
    }
    
    private func setScrollingMode(_ inScrollingMode: Bool) {
        self.inScrollingMode = inScrollingMode
        
        gestureRecognizingView.isUserInteractionEnabled = inScrollingMode
        
        if inScrollingMode {
            modeToggleButton.setTitle("Switch to drawing", for: .normal)
        } else {
            modeToggleButton.setTitle("Switch to scrolling", for: .normal)
        }
    }
    
    private func calculateArea() {
        // The BooleanIndexableImage will be a view across both sources of pixels.
        // First we add the base iamge of the leaf.
        let baseImage = IndexableImage(uiToCgImage(image!))
        let combinedImage = BooleanIndexableImage(width: baseImage.width, height: baseImage.height)
        combinedImage.addImage(baseImage, withPixelToBoolConversion: { $0.isNonWhite() })
        
        // Then we include any user drawings.
        let userDrawingProjection = Projection(fromImageInView: baseImageView.image!, toView: baseImageView)
        let userDrawing = IndexableImage(uiToCgImage(userDrawingView.image!), withProjection: userDrawingProjection)
        combinedImage.addImage(userDrawing, withPixelToBoolConversion: { $0.isVisible() })
        
        let connectedComponentsInfo = labelConnectedComponents(image: combinedImage)
        
        let labelsAndSizes = connectedComponentsInfo.labelToSize.sorted { $0.1 > $1.1 }
        
        // Assume the largest occupied component is the leaf.
        let leafLabelAndSize = labelsAndSizes.first(where: { $0.key > 0 })
        if leafLabelAndSize == nil {
            // This is a blank image, and trying to calculate area will crash.
            resultsText.text = "No leaf found"
            return
        }
        let leafLabels = connectedComponentsInfo.equivalenceClasses.getElementsInClassWith(leafLabelAndSize!.key)!
        let leafAreaInPixels = leafLabelAndSize!.value
        
        let emptyLabelsAndSizes = labelsAndSizes.filter { $0.key < 0 }
        
        if emptyLabelsAndSizes.count == 0 {
            // This is a solid image, so calculating area is pointless.
            resultsText.text = "No leaf found"
            return
        }
        
        // Assume the biggest is the background, and everything else is potentially a hole.
        let emptyLabelsWithoutBackground = emptyLabelsAndSizes.dropFirst()
                
        let drawingManager = DrawingManager(withCanvasSize: leafHolesView.frame.size, withProjection: userDrawingProjection)
        drawingManager.getContext().setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        var eatenAreaInPixels = 0
        for emptyLabelAndSize in emptyLabelsWithoutBackground {
            // This component is a hole if it neighbors the leaf (since we already filtered out the background).
            if !connectedComponentsInfo.emptyLabelToNeighboringOccupiedLabels[emptyLabelAndSize.key]!.intersection(leafLabels).isEmpty {
                // Add to the eaten size.
                eatenAreaInPixels += emptyLabelAndSize.value
                
                // And fill in the eaten area.
                let (floodStartX, floodStartY) = connectedComponentsInfo.labelToMemberPoint[emptyLabelAndSize.key]!
                floodFill(image: combinedImage, fromPoint: CGPoint(x: floodStartX, y: floodStartY), drawingTo: drawingManager)
            }
        }
        
        drawingManager.finish(imageView: leafHolesView)
        
        // Set the result of the calculation, giving absolute area if the scale is set.
        let percentEaten = Float(eatenAreaInPixels) / Float(leafAreaInPixels) * 100
        if scaleMarkPixelLength != nil {
            let leafAreaInCm2 = convertPixelsToCm2(leafAreaInPixels)
            let eatenAreaInCm2 = convertPixelsToCm2(eatenAreaInPixels)
            
            resultsText.text = "Leaf is \(formatFloat(withThreeDecimalPoints: leafAreaInCm2)) cm2 with \(formatFloat(withThreeDecimalPoints: eatenAreaInCm2)) cm2 or \(formatFloat(withThreeDecimalPoints: percentEaten))% eaten."
        } else {
            resultsText.text = "Leaf is \(formatFloat(withThreeDecimalPoints: percentEaten))% eaten."
        }
    }
    
    // The scale is assumed to be 2 cm long.
    private func convertPixelsToCm2(_ pixels: Int) -> Float {
        if scaleMarkPixelLength == nil {
            fatalError("Attempting to calculate absolute area without scale set.")
        }
        
        let cmPerPixel = 2.0 / Float(scaleMarkPixelLength!)
        return pow(cmPerPixel, 2) * Float(pixels)
    }
    
    private func formatFloat(withThreeDecimalPoints float: Float) -> String {
        return String(format: "%.3f", float)
    }
}
