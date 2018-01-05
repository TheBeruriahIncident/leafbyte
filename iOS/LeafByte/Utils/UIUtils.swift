//
//  UIUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import AVFoundation
import UIKit

func presentAlert(self viewController: UIViewController, title: String?, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default)
    alertController.addAction(okAction)
    
    viewController.present(alertController, animated: true, completion: nil)
}

func requestCameraAccess(self viewController: UIViewController, onSuccess: @escaping () -> Void) {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
        if response {
            onSuccess()
        } else {
            presentAlert(self: viewController, title: "Camera access denied", message: "To allow taking photos for analysis, go to Settings -> Privacy -> Camera and set LeafByte to ON.")
        }
    }
}

func setupGestureRecognizingView(gestureRecognizingView: UIScrollView, self viewController: UIScrollViewDelegate) {
    gestureRecognizingView.delegate = viewController
    gestureRecognizingView.minimumZoomScale = 0.9;
    gestureRecognizingView.maximumZoomScale = 10.0
}

func setupImagePicker(imagePicker: UIImagePickerController, self viewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
    imagePicker.delegate = viewController
    // By allowing editing, our users get the ability to crop out shadows for "free".
    imagePicker.allowsEditing = true
}
