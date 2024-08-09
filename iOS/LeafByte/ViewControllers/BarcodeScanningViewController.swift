//
//  BarcodeScanningViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 2/14/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AVFoundation
import UIKit

@available(iOS 10.0, *)
final class BarcodeScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields

    let supportedBarcodeTypes = [
        // 1D
        AVMetadataObject.ObjectType.code128,
        AVMetadataObject.ObjectType.code39,
        AVMetadataObject.ObjectType.code39Mod43,
        AVMetadataObject.ObjectType.code93,
        AVMetadataObject.ObjectType.ean13,
        AVMetadataObject.ObjectType.ean8,
        AVMetadataObject.ObjectType.interleaved2of5,
        AVMetadataObject.ObjectType.itf14,
        AVMetadataObject.ObjectType.upce,

        // 2D
        AVMetadataObject.ObjectType.aztec,
        AVMetadataObject.ObjectType.dataMatrix,
        AVMetadataObject.ObjectType.pdf417,
        AVMetadataObject.ObjectType.qr
    ]

    // This is passed from the previous view.
    // swiftlint:disable implicitly_unwrapped_optional
    var settings: Settings!
    // swiftlint:enable implicitly_unwrapped_optional

    let captureSession = AVCaptureSession()
    // This is initialized in viewDidLoad.
    // swiftlint:disable:next implicitly_unwrapped_optional
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var barcode: String?

    let imagePicker = UIImagePickerController()

    // This is set while choosing the next image and is passed to the next thresholding view.
    var selectedImage: CGImage?

    // MARK: - Actions
    @IBAction func goHome(_: Any) {
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
            crashGracefully(viewController: self, message: "Failed to find any camera on device. Please reach out to leafbyte@zoegp.science with information about your device so we can fix this issue.")
            return
        }
        do {
            captureSession.addInput(try AVCaptureDeviceInput(device: camera))
        } catch {
            print("AVCaptureDeviceInput initialization crashed: \(error)")
            crashGracefully(viewController: self, message: "Camera fails to be AV capture device. Please reach out to leafbyte@zoegp.science with information about your device so we can fix this issue.")
            return
        }

        // Setup the capture session output.
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = supportedBarcodeTypes

        // Add a view of the camera to the screen.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.sublayers?.insert(videoPreviewLayer, at: 0)
        setupViewPreviewLayer()

        // Start the capture session.
        // If this runs on the main thread, we get warnings that it might cause UI unresponsiveness
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        setupViewPreviewLayer()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let destination = segue.destination as? BackgroundRemovalViewController else {
                fatalError("Expected the view inside the navigation controller to be the thresholding view but is  \(String(describing: segue.destination))")
            }

            destination.settings = settings
            destination.sourceMode = .camera
            destination.image = selectedImage
            destination.inTutorial = false
            destination.barcode = barcode
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate overrides

    // Accept the captured barcode.
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            return
        }
        guard let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else {
            return
        }

        if supportedBarcodeTypes.contains(metadataObject.type) {
            captureSession.stopRunning()
            barcode = metadataObject.stringValue
            guard let barcode else {
                return
            }

            label.text = barcode

            DispatchQueue.main.async {
                // Pause for 1s to preview what was scanned.
                usleep(1_000_000)

                // swiftlint:disable:next trailing_closure
                requestCameraAccess(self: self, onSuccess: {
                    DispatchQueue.main.async {
                        self.present(self.imagePicker, animated: true, completion: nil)
                    }
                })
            }
        }
    }

    // MARK: - UIImagePickerControllerDelegate overrides

    func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        finishWithImagePicker(self: self, info: info) { selectedImage = $0 }
    }

    // If the image picker is canceled, dismiss it.
    // Also go back to the home screen, to make it consistent that going back from after taking a picture goes to the home screen.
    func imagePickerControllerDidCancel(_: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        dismissNavigationController(self: self)
    }

    // MARK: - Helpers

    private func setupViewPreviewLayer() {
        videoPreviewLayer.frame = view.layer.bounds

        if let videoPreviewLayerConnection = videoPreviewLayer.connection {
            if #available(iOS 17.0, *) {
                // Left and right need to be swapped to effectively counteract the rotation.
                let videoRotationAngle: CGFloat
                switch UIDevice.current.orientation {
                case .portrait:
                    videoRotationAngle = 90

                case .landscapeRight:
                    videoRotationAngle = 180

                case .landscapeLeft:
                    videoRotationAngle = 0

                case .portraitUpsideDown:
                    videoRotationAngle = 270

                default:
                    videoRotationAngle = 90
                }

                if videoPreviewLayerConnection.isVideoRotationAngleSupported(videoRotationAngle) {
                    videoPreviewLayerConnection.videoRotationAngle = videoRotationAngle
                }
            } else {
                if !videoPreviewLayerConnection.isVideoOrientationSupported {
                    return
                }

                // Left and right need to be swapped to effectively counteract the rotation.
                switch UIDevice.current.orientation {
                case .portrait:
                    videoPreviewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait

                case .landscapeRight:
                    videoPreviewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft

                case .landscapeLeft:
                    videoPreviewLayerConnection.videoOrientation = AVCaptureVideoOrientation.landscapeRight

                case .portraitUpsideDown:
                    videoPreviewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown

                default:
                    videoPreviewLayerConnection.videoOrientation = AVCaptureVideoOrientation.portrait
                }
            }
        }
    }
}
