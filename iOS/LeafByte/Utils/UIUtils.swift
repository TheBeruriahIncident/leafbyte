//
//  UIUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import AVFoundation
import UIKit

func finishWithImagePicker(self viewController: UIViewController, info: [String : Any], selectImage: (UIImage) -> Void) {
    // There may (in theory) contain multiple versions of the image in info; we're not allowing editing, so just take the original.
    guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
        fatalError("Expected to find an image under UIImagePickerControllerEditedImage in \(info)")
    }
    
    // We scale it down to make the following operations happen in tolerable time.
    let resizedImage = resizeImage(selectedImage, within: CGSize(width: 400, height: 400))
    
    // Save the selectedImage off so that during the segue, we can set it onto the next view.
    selectImage(resizedImage)
    
    viewController.dismiss(animated: false, completion: {() in
        // Dismissing and then seguing goes from the image picker to the previous view to the next view.
        // It looks weird to be back at the previous view, so make this transition as short as possible by disabling animation.
        // Animation is re-renabled in the previous view's viewDidDisappear.
        UIView.setAnimationsEnabled(false)
        viewController.performSegue(withIdentifier: "imageChosen", sender: viewController)
    })
}

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

// Make the back button say "Back" rather than the full title of the previous page.
func setBackButton(self viewController: UIViewController) {
    let backItem = UIBarButtonItem()
    backItem.title = "Back"
    viewController.navigationItem.backBarButtonItem = backItem
}

func setupGestureRecognizingView(gestureRecognizingView: UIScrollView, self viewController: UIScrollViewDelegate) {
    gestureRecognizingView.delegate = viewController
    gestureRecognizingView.minimumZoomScale = 0.9;
    gestureRecognizingView.maximumZoomScale = 10.0
}

func setupImagePicker(imagePicker: UIImagePickerController, self viewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
    imagePicker.delegate = viewController
    // Allowing editing to get easy cropping is tempting, but cropping in the image picker is broken in various ways on different devices.
    // For example, on most devices, the crop window will be applied ~10% above where the user chooses, and on some devices, the crop window won't be movable at all.
    // TODO: stuff is breaking when I switch back to false, figure
    imagePicker.allowsEditing = false
}
