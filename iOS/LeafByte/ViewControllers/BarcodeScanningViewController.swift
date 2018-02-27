//
//  BarcodeScanningViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 2/14/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit
import AVFoundation

class BarcodeScanningViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    private let supportedBarcodeTypes = [
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        
        // Setup the capture session input.
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
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
        view.layer.addSublayer(videoPreviewLayer)
        
        // Start the capture session.
        captureSession.startRunning()
    }
    
    // Accept the captured barcode.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.isEmpty {
            return
        }
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedBarcodeTypes.contains(metadataObject.type) {
            print(metadataObject.stringValue!)
        }
    }
}
