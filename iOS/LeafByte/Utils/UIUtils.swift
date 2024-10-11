//
//  UIUtils.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/4/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AVFoundation
import PhotosUI
import UIKit

// Dismisses the current navigation controller, showing what is beneath.
func dismissNavigationController(self viewController: UIViewController) {
    DispatchQueue.main.async {
        // Note the ?: if this is nil, I'm guessing it's a weird race condition where the navigation controller has already been dismissed, so there's nothing wrong with just moving on
        viewController.navigationController?.dismiss(animated: true)
    }
}

func setupImagePicker(imagePicker: UIImagePickerController, self viewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
    imagePicker.delegate = viewController
    // Allowing editing to get easy cropping is tempting, but cropping in the image picker is broken in various ways on different devices.
    // For example, on most devices, the crop window will be applied ~10% above where the user chooses, and on some devices, the crop window won't be movable at all.
    imagePicker.allowsEditing = false
}

// viewController must be a PHPickerViewControllerDelegate!
func presentImagePickerOrPHPicker(self viewController: UIViewController, presentationControllerDelegate: UIAdaptivePresentationControllerDelegate, imagePicker: UIImagePickerController, sourceMode: ImageSourceMode) {

    if sourceMode == .photoLibrary, #available(iOS 14.0, *) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        // Use the current format to avoid slow conversions
        configuration.preferredAssetRepresentationMode = .current

        // The picker has been successfully tested with standard photos, bursts, live photos, depth-effect photos, panoramas, and screenshots. It seems like filtering to just .images still includes all of those, but we add all the different types just to make sure sure. Note that we don't include any video types, as they can't be coerced to UIImages.
        var filters: [PHPickerFilter] = [.images, .livePhotos]
        if #available(iOS 15.0, *) {
            filters.append(.panoramas)
            filters.append(.screenshots)
        }
        if #available(iOS 16.0, *) {
            filters.append(.bursts)
            filters.append(.depthEffectPhotos)
        }
        configuration.filter = PHPickerFilter.any(of: filters)

        let picker = PHPickerViewController(configuration: configuration)
        // This is a bit of a hack: we can't take viewController as UIViewController & PHPickerViewControllerDelegate or else the compiler forces us to mark the whole method as only available to iOS 14.0 and up. But, the only view controllers that call this are PHPickerViewControllerDelegate, so this hack should work out.
        guard let delegate = viewController as? PHPickerViewControllerDelegate else {
            crashGracefully(viewController: viewController, message: "App is misconfigured: view controller is not a PHPicker delegate. Please reach out to leafbyte@zoegp.science so we can fix this.")
            return
        }
        picker.delegate = delegate
        picker.presentationController?.delegate = presentationControllerDelegate

        viewController.present(picker, animated: true, completion: nil)
    } else {
        switch sourceMode {
        case .camera:
            imagePicker.sourceType = .camera

        case .photoLibrary:
            imagePicker.sourceType = .photoLibrary
        }

        viewController.present(imagePicker, animated: true, completion: nil)
    }
}

func finishWithImagePicker(self viewController: UIViewController, info: [UIImagePickerController.InfoKey: Any], selectImage: (CGImage) -> Void) {
    // In theory, there may be multiple versions of the image in info. We're not allowing editing, so generally there's only one and we just take the original. However, the crash organizer shows that this isn't always successful, so now we try falling back to an editedImage before failing gracefully with an alert.
    let selectedImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) ?? (info[UIImagePickerController.InfoKey.editedImage] as? UIImage)

    let onDismissingPicker: () -> Void
    if selectedImage != nil {
        // We scale it down to make the following operations happen in tolerable time.
        // swiftlint:disable:next force_unwrapping
        let resizedImage = resizeImage(selectedImage!)

        if resizedImage != nil {
            // Save the selectedImage off so that during the segue, we can set it onto the next view.
            // swiftlint:disable:next force_unwrapping
            selectImage(resizedImage!)

            onDismissingPicker = {
                // Dismissing and then seguing goes from the image picker to the previous view to the next view.
                // It looks weird to be back at the previous view, so make this transition as short as possible by disabling animation.
                // Animation is re-renabled in the previous view's viewDidDisappear.
                UIView.setAnimationsEnabled(false)
                viewController.performSegue(withIdentifier: "imageChosen", sender: viewController)
            }
        } else {
            onDismissingPicker = {
                crashGracefully(viewController: viewController, message: "Failed to resize chosen image. Please reach out to leafbyte@zoegp.science with information about what image you chose so we can fix this issue. Debug info: \(info)")
            }
        }
    } else {
        onDismissingPicker = {
            crashGracefully(viewController: viewController, message: "Failed to open chosen image. Please reach out to leafbyte@zoegp.science with information about what image you chose so we can fix this issue. Debug info: \(info)")
        }
    }

    viewController.dismiss(animated: false, completion: onDismissingPicker)
}

@available(iOS 14.0, *)
func finishWithPHPicker(self viewController: UIViewController, picker: PHPickerViewController, didFinishPicking results: [PHPickerResult], onCancel: @escaping () -> Void = {}, selectImage: @escaping (CGImage) -> Void) { // swiftlint:disable:this no_empty_block
    picker.delegate = nil
    // This logic must be wrapped in the completion callback or you get problems with race conditions. E.g. picker.dismiss seems to also dismiss any view controller that opens before it finishes running, so if the thresholding page opens fast enough, it gets closed.
    picker.dismiss(animated: true) {
        if results.isEmpty {
            // Presumably the user canceled the picker
            onCancel()
            return
        }
        // We only allow one image, so we shouldn't be discarding anything
        let result = results[0]

        // Supposedly iCloud images should be handled transparently by this call, but we don't have access to any iCloud images to test this.
        result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
            guard let image = reading as? UIImage, error == nil else {
                presentAlert(self: viewController, title: nil, message: "Failed to open chosen image. Please reach out to leafbyte@zoegp.science with information about what image you chose so we can fix this issue. Debug info: \(String(describing: error))")
                return
            }

            // We scale it down to make the following operations happen in tolerable time.
            guard let resizedImage = resizeImage(image) else {
                presentAlert(self: viewController, title: nil, message: "Failed to resize chosen image. Please reach out to leafbyte@zoegp.science with information about what image you chose so we can fix this issue. Debug info: \(String(describing: reading))")
                return
            }
            // Save the selectedImage off so that during the segue, we can set it onto the next view.
            selectImage(resizedImage)

            DispatchQueue.main.async {
                // Dismissing and then seguing goes from the image picker to the previous view to the next view.
                // It looks weird to be back at the previous view, so make this transition as short as possible by disabling animation.
                // Animation is re-renabled in the previous view's viewDidDisappear.
                UIView.setAnimationsEnabled(false)
                viewController.performSegue(withIdentifier: "imageChosen", sender: viewController)
            }
        }
    }
}

// There are various cases that we either think are impossible, or have happened in a crash report but we have no idea how. This allows us to return to the main menu with an error, rather than the whole app crashing.
func crashGracefully(viewController: UIViewController, message: String) {
    presentAlert(self: viewController, title: nil, message: message) { _ in
        dismissNavigationController(self: viewController)
    }
}

func presentAlert(self viewController: UIViewController, title: String?, message: String, onAcknowledge: ((UIAlertAction) -> Void)? = nil) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm an alert"), style: .default, handler: onAcknowledge)
    alertController.addAction(okAction)

    DispatchQueue.main.async {
        viewController.present(alertController, animated: true, completion: nil)
    }
}

// swiftlint:disable:next no_empty_block
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
    scrollView.minimumZoomScale = 0.9
    scrollView.maximumZoomScale = 50.0
}

func setupPopoverViewController(_ popoverViewController: UIViewController, self hostingViewController: UIPopoverPresentationControllerDelegate) {
    popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
    popoverViewController.popoverPresentationController?.delegate = hostingViewController
    popoverViewController.popoverPresentationController?.passthroughViews = nil
}

func smoothTransitions(self viewController: UIViewController) {
    // This prevents a black shadow from appearing in the navigation bar during transitions (see https://stackoverflow.com/questions/22413193/dark-shadow-on-navigation-bar-during-segue-transition-after-upgrading-to-xcode-5 ).
    viewController.navigationController?.view.backgroundColor = UIColor.white
}

func setSampleNumberButtonText(_ sampleNumberButton: UIButton, settings: Settings) {
    sampleNumberButton.setTitle(String.localizedStringWithFormat(NSLocalizedString("Sample %@", comment: "Current sample number"), String(settings.getNextSampleNumber())), for: .normal)
}

func presentSampleNumberAlert(self viewController: UIViewController, sampleNumberButton: UIButton, settings: Settings) {
    let alert = UIAlertController(title: NSLocalizedString("Sample Number", comment: "Title of alert asking for the new sample number"), message: nil, preferredStyle: .alert)

    alert.addTextField { textField in
        textField.placeholder = String(settings.getNextSampleNumber())
        textField.keyboardType = UIKeyboardType.numberPad
    }

    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel the new sample number"), style: .default)
    // swiftlint:disable:next trailing_closure
    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "Confirm the new sample number"), style: .default, handler: { _ in
        // swiftlint:disable:next force_unwrapping
        let newSampleNumber = alert.textFields![0].text!
        if newSampleNumber.isEmpty {
            return
        }

        let parsedNewSampleNumber = Int(newSampleNumber)
        if parsedNewSampleNumber != nil {
            settings.datasetNameToNextSampleNumber[settings.datasetName] = parsedNewSampleNumber
            settings.serialize(self: viewController)
            setSampleNumberButtonText(sampleNumberButton, settings: settings)
        } else {
            presentAlert(self: viewController, title: nil, message: "This is not a valid number.")
        }
    })

    alert.addAction(cancelAction)
    alert.addAction(okAction)

    viewController.present(alert, animated: true, completion: nil)
}

func maintainOldModalPresentationStyle(viewController: UIViewController) {
    // the SDK in Xcode 11 has a breaking change in modal presentation style that doesn't work well.
    viewController.modalPresentationStyle = .fullScreen
}

func presentFailedGoogleSignInAlert(cause: GoogleSignInFailureCause, self viewController: UIViewController) {
    let message =
        switch cause {
        case .generic:
            NSLocalizedString("Google sign-in is required for saving to Google Drive", comment: "Shown if Google sign-in fails after choosing to save to Google Drive")

        case .noGetUserIdScope:
            NSLocalizedString("We must be authorized to identify you if you want to save to Google Drive. We specifically need the ability to identify you so that you can edit the same datasheets over the course of multiple LeafByte sessions or to use LeafByte with multiple Google accounts. To save to Google Drive, sign in again and grant access.", comment: "Shown if Google sign-in fails specifically because the user rejected LeafByte access to their user id")

        case .noWriteToGoogleDriveScope:
            NSLocalizedString("We must be authorized to write to Google Drive in order to save to Google Drive. To save to Google Drive, sign in again and grant access.", comment: "Shown if Google sign-in fails specifically because the user rejected LeafByte access to Google Drive")

        case .neitherScope:
            NSLocalizedString("We must be authorized to identify you and write to Google Drive if you want to save to Google Drive. We specifically need the ability to identify you so that you can edit the same datasheets over the course of multiple LeafByte sessions or to use LeafByte with multiple Google accounts. To save to Google Drive, sign in again and grant access.", comment: "Shown if Google sign-in fails specifically because the user rejected all access for LeafByte")
        }

    DispatchQueue.main.async {
        presentAlert(self: viewController, title: nil, message: message)
    }
}

func setImageViewBackground(imageView: UIImageView, settings: Settings) {
    if settings.useBlackBackground {
        imageView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
}
