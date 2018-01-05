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
    
    // MARK: - Actions
    
    @IBAction func pickImageFromCamera(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            presentAlert(self: self, title: nil, message: "No available camera")
            return
        }
        
        requestCameraAccess(self: self, onSuccess: { self.presentImagePicker(sourceType: UIImagePickerControllerSourceType.camera) })
    }
    
    @IBAction func pickImageFromPhotoLibrary(_ sender: Any) {
        presentImagePicker(sourceType: UIImagePickerControllerSourceType.photoLibrary)
    }
    
    // Despite having no content, this must exist to enable the programmatic segues back to this view.
    @IBAction func backToMainMenu(segue: UIStoryboardSegue) {}
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupImagePicker(imagePicker: imagePicker, self: self)
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
            
            destination.sourceType = sourceType
            destination.image = selectedImage
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // See imagePickerController() for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }

    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // TODO: Pull out commonalities here
        
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
    
    func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        self.sourceType = sourceType
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
}
