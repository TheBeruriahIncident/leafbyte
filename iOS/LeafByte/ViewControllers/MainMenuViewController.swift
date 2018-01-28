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
    
    var settings: Settings!
    
    let imagePicker = UIImagePickerController()
    
    // Both of these are set while picking an image and are passed forward to the next view.
    var sourceType: UIImagePickerControllerSourceType?
    var selectedImage: CGImage?
    
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
        
        settings = Settings.deserialize()
        setupImagePicker(imagePicker: imagePicker, self: self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        maybeDoGoogleSignIn()
    }
    
    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? ThresholdingViewController else {
                fatalError("Expected the view inside the navigation controller to be the thresholding view but is  \(String(describing: navigationController.topViewController))")
            }
            
            destination.settings = settings
            destination.sourceType = sourceType
            destination.image = selectedImage
        }
        // If the segue is toSettings, we're transitioning to the settings, and we need to pass the settings forward.
        else if segue.identifier == "toSettings" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? SettingsViewController else {
                fatalError("Expected the view inside the navigation controller to be the settings view but is  \(String(describing: navigationController.topViewController))")
            }
            
            destination.settings = settings
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }

    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        finishWithImagePicker(self: self, info: info, selectImage: { selectedImage = $0 })
    }
    
    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    private func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        self.sourceType = sourceType
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Sign in to Google if necessary.
    private func maybeDoGoogleSignIn() {
        if settings.measurementSaveLocation != .googleDrive && settings.imageSaveLocation != .googleDrive {
            return
        }
        
        GoogleSignInManager.initiateSignIn(
            actionWithAccessToken: { _ in () },
            actionWithError: { _ in
                if self.settings.measurementSaveLocation == .googleDrive {
                    self.settings.measurementSaveLocation = .local
                }
                if self.settings.imageSaveLocation == .googleDrive {
                    self.settings.imageSaveLocation = .local
                }
                self.settings.serialize()
                
                presentAlert(self: self, title: nil, message: "Cannot save to Google Drive without Google sign-in")
            })
    }
}
