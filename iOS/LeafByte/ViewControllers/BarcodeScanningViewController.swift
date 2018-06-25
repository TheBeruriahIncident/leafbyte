//
//  BarcodeScanningViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 2/14/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit
import AVFoundation

@available(iOS 10.0, *)
class BarcodeScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields
    
    let supportedBarcodeTypes = [
        // 2D
        AVMetadataObject.ObjectType.code128,
        AVMetadataObject.ObjectType.ean8,
        AVMetadataObject.ObjectType.ean13,
        AVMetadataObject.ObjectType.upce,
        AVMetadataObject.ObjectType.code39,
        AVMetadataObject.ObjectType.code39Mod43,
        AVMetadataObject.ObjectType.code93,
        AVMetadataObject.ObjectType.interleaved2of5,
        AVMetadataObject.ObjectType.itf14,
        
        // 3D
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.dataMatrix,
        AVMetadataObject.ObjectType.pdf417,
        AVMetadataObject.ObjectType.qr,
    ]
    
    // This is passed from the previous view.
    var settings: Settings!
    
    let captureSession = AVCaptureSession()
    var barcode: String?
    
    let imagePicker = UIImagePickerController()
    
    // This is set while choosing the next image and is passed to the next thresholding view.
    var selectedImage: CGImage?
    
    // MARK: - Actions
    @IBAction func goHome(_ sender: Any) {
        dismissNavigationController(self: self)
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var label: UILabel!
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImagePicker(imagePicker: imagePicker, self: self)
        imagePicker.sourceType = .camera
        
        // Setup the capture session input.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [ .builtInWideAngleCamera ], mediaType: AVMediaType.video, position: .back)
        guard let camera = deviceDiscoverySession.devices.first else {
            fatalError("Failed to get a camera device")
        }
        captureSession.addInput(try! AVCaptureDeviceInput(device: camera))
        
        // Setup the capture session output.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = supportedBarcodeTypes
        
        // Add a view of the camera to the screen.
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.sublayers?.insert(videoPreviewLayer, at: 0)
        
        // Start the capture session.
        captureSession.startRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let destination = segue.destination as? ThresholdingViewController else {
                fatalError("Expected the view inside the navigation controller to be the thresholding view but is  \(String(describing: segue.destination))")
            }
            
            destination.settings = settings
            destination.sourceType = .camera
            destination.image = selectedImage
            destination.inTutorial = false
            destination.barcode = barcode
        }
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate overrides
    
    // Accept the captured barcode.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            return
        }
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedBarcodeTypes.contains(metadataObject.type) {
            captureSession.stopRunning()
            barcode = metadataObject.stringValue!
            label.text = barcode
            
            DispatchQueue.main.async {
                // Pause for 1s to preview what was scanned.
                usleep(1000000)
                
                requestCameraAccess(self: self, onSuccess: {
                    DispatchQueue.main.async {
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        finishWithImagePicker(self: self, info: info, selectImage: { selectedImage = $0 })
    }
    
    // If the image picker is canceled, dismiss it.
    // Also go back to the home screen, to make it consistent that going back from after taking a picture goes to the home screen.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        dismissNavigationController(self: self)
    }
}
