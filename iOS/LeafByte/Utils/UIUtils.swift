//
//  UIUtils.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/4/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import AVFoundation
import UIKit

// Dismisses the current navigation controller, showing what is beneath.
func dismissNavigationController(self viewController: UIViewController) {
    viewController.navigationController!.dismiss(animated: true)
}

func finishWithImagePicker(self viewController: UIViewController, info: [String : Any], selectImage: (CGImage) -> Void) {
    // There may (in theory) contain multiple versions of the image in info; we're not allowing editing, so just take the original.
    guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
        fatalError("Expected to find an image under UIImagePickerControllerEditedImage in \(info)")
    }
    
    // We scale it down to make the following operations happen in tolerable time.
    let resizedImage = resizeImage(selectedImage)
    
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

func setBackButton(self previousViewController: UIViewController, next nextViewController: UIViewController ) {
    // Make the back button say "Back" rather than the full title of the previous page.
    let backItem = UIBarButtonItem()
    backItem.title = "Back"
    previousViewController.navigationItem.backBarButtonItem = backItem
    
    // Make the back button appear even if there are other buttons.
    nextViewController.navigationItem.leftItemsSupplementBackButton = true
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
    imagePicker.allowsEditing = false
}

func setupPopoverViewController(_ popoverViewController: UIViewController, self hostingViewController: UIPopoverPresentationControllerDelegate) {
    popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
    popoverViewController.popoverPresentationController!.delegate = hostingViewController
    popoverViewController.popoverPresentationController?.passthroughViews = nil
}

func smoothTransitions(self viewController: UIViewController) {
    // This prevents a black shadow from appearing in the navigation bar during transitions (see https://stackoverflow.com/questions/22413193/dark-shadow-on-navigation-bar-during-segue-transition-after-upgrading-to-xcode-5 ).
    viewController.navigationController!.view.backgroundColor = UIColor.white
}
