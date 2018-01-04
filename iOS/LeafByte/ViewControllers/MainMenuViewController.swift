//
//  MainMenuViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import AVFoundation
import UIKit

// This class controls the main menu view, the first view in the app.
class MainMenuViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields
    
    let imagePicker = UIImagePickerController()
    
    // Both of these are set while picking an image and are passed forward to the next view.
    var sourceType: UIImagePickerControllerSourceType?
    var selectedImage: UIImage?
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        // By allowing editing, we can allow users to crop for "free".
        imagePicker.allowsEditing = true
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? ThresholdingViewController else {
                fatalError("Expected the view inside the navigation controller to be the thresholding view but is  \(navigationController.topViewController!)")
            }
            
            destination.image = selectedImage
            destination.sourceType = sourceType
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // See imagePickerController() for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }
    
    // MARK: - Actions
    
    @IBAction func pickImageFromCamera(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            presentAlert(title: nil, message: "No available camera")
            return
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                self.presentImagePicker(sourceType: UIImagePickerControllerSourceType.camera)
            } else {
                self.presentAlert(title: "Camera access denied", message: "To allow taking photos for analysis, go to Settings -> Privacy -> Camera and set LeafByte to ON.")
            }
        }
    }
    
    @IBAction func pickImageFromPhotoLibrary(_ sender: Any) {
        presentImagePicker(sourceType: UIImagePickerControllerSourceType.photoLibrary)
    }
    
    // Despite having no content, this must exist to enable the programmatic segues back to this view.
    @IBAction func backToMainMenu(segue: UIStoryboardSegue) {}

    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // There may contain multiple versions of the image in info; since we're allowing editing, we want the edited image.
        // Even if the user doesn't edit, this will retrieve the unedited image.
        // TODO: scale seems to be off on UIImagePickerControllerEditedImage, figure
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected to find an image under UIImagePickerControllerEditedImage in \(info)")
        }
    
        // Save the selectedImage off so that during the segue, we can set it onto the thresholding view.
        // TODO: resize the image https://stackoverflow.com/questions/12258280/capturing-photos-with-specific-resolution-using-the-uiimagepickercontroller https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
        self.selectedImage = selectedImage
        
        dismiss(animated: false, completion: {() in
            // Dismissing and then seguing goes from the image picker to the main menu view to the thresholding view.
            // It looks weird to be back at the main menu, so make this transition as short as possible by disabling animation.
            // Animation is re-renabled in this class's viewDidDisappear.
            UIView.setAnimationsEnabled(false)
            self.performSegue(withIdentifier: "imageChosen", sender: self)
        })
    }
    
    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    func presentAlert(title: String?, message: String) {
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction.init(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        self.sourceType = sourceType
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
}
