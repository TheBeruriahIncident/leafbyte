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
    DispatchQueue.main.async {
        viewController.navigationController!.dismiss(animated: true)
    }
}

func finishWithImagePicker(self viewController: UIViewController, info: [UIImagePickerController.InfoKey : Any], selectImage: (CGImage) -> Void) {
    // There may (in theory) contain multiple versions of the image in info; we're not allowing editing, so just take the original.
    guard let selectedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
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
    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm an alert"), style: .default)
    alertController.addAction(okAction)
    
    viewController.present(alertController, animated: true, completion: nil)
}

func requestCameraAccess(self viewController: UIViewController, onSuccess: @escaping () -> Void, onFailure: @escaping () -> Void = {}) {
    AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
        if response {
            onSuccess()
        } else {
            onFailure()
            presentAlert(self: viewController, title: NSLocalizedString("Camera access denied", comment: "Title of the alert that camera access is denied"), message: NSLocalizedString("To allow taking photos for analysis, go to your phone's Settings -> LeafByte and set Camera to ON.", comment: "Explanation of how to give camera access"))
        }
    }
}

func setBackButton(self previousViewController: UIViewController, next nextViewController: UIViewController ) {
    // Make the back button say "Back" rather than the full title of the previous page.
    let backItem = UIBarButtonItem()
    backItem.title = NSLocalizedString("Back", comment: "Title for button to go to previous screen")
    previousViewController.navigationItem.backBarButtonItem = backItem
    
    // Make the back button appear even if there are other buttons.
    nextViewController.navigationItem.leftItemsSupplementBackButton = true
}

func setupScrollView(scrollView: UIScrollView, self viewController: UIScrollViewDelegate) {
    scrollView.delegate = viewController
    scrollView.minimumZoomScale = 0.9;
    scrollView.maximumZoomScale = 50.0
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

func setSampleNumberButtonText(_ sampleNumberButton: UIButton, settings: Settings) {
    sampleNumberButton.setTitle(String.localizedStringWithFormat(NSLocalizedString("Sample %d", comment: "Current sample number"), settings.getNextSampleNumber()), for: .normal)
}

func presentSampleNumberAlert(self viewController: UIViewController, sampleNumberButton: UIButton, settings: Settings) {
    let alert = UIAlertController(title: NSLocalizedString("Sample Number", comment: "Title of alert asking for the new sample number"), message: nil, preferredStyle: .alert)
    
    alert.addTextField { (textField) in
        textField.placeholder = String(settings.getNextSampleNumber())
        textField.keyboardType = UIKeyboardType.numberPad
    }
    
    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the new sample number"), style: .default)
    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm the new sample number"), style: .default, handler: { (_) in
        let newSampleNumber = alert.textFields![0].text!
        
        if !newSampleNumber.isEmpty && Int(newSampleNumber) != nil {
            settings.datasetNameToNextSampleNumber[settings.datasetName] = Int(newSampleNumber)
            settings.serialize()
            setSampleNumberButtonText(sampleNumberButton, settings: settings)
        }
    })
    
    alert.addAction(cancelAction)
    alert.addAction(okAction)
    
    viewController.present(alert, animated: true, completion: nil)
}
