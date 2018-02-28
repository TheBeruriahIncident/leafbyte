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
final class MainMenuViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields
    
    var settings: Settings!
    
    let imagePicker = UIImagePickerController()
    
    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false
    
    // Both of these are set while picking an image and are passed forward to the next view.
    var sourceType: UIImagePickerControllerSourceType?
    var selectedImage: CGImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var savingSummary: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func pickImageFromCamera(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            presentAlert(self: self, title: nil, message: "No available camera")
            return
        }
        
        requestCameraAccess(self: self, onSuccess: {
            if self.settings.useBarcode {
                self.performSegue(withIdentifier: "toBarcodeScanning", sender: self)
            } else {
                self.presentImagePicker(sourceType: UIImagePickerControllerSourceType.camera)
            }
        })
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
        super.viewDidAppear(animated)
        
        if !viewDidAppearHasRun {
            maybeDoGoogleSignIn()
            viewDidAppearHasRun = true
        }
        
        setSavingSummary()
        
        let imageToUse = settings.useBarcode ? "Barcode" : "Camera"
        cameraButton.setBackgroundImage(UIImage(named: imageToUse), for: .normal)
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
            destination.inTutorial = false
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
        // If the segue is toTutorial, we're starting the tutorial, and we need to pass the settings forward.
        else if segue.identifier == "toTutorial" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? TutorialViewController else {
                fatalError("Expected the view inside the navigation controller to be the tutorial view but is  \(String(describing: navigationController.topViewController))")
            }
            
            destination.settings = settings
        }
        // If the segue is toBarcodeScanning, we're starting the main flow, but with barcode scanning at the start instead of image picking.
        else if segue.identifier == "toBarcodeScanning" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? BarcodeScanningViewController else {
                fatalError("Expected the view inside the navigation controller to be the barcode scanning view but is  \(String(describing: navigationController.topViewController))")
            }
            
            destination.settings = settings
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
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
            onAccessTokenAndUserId: { _, _ in () },
            onError: { _ in
                if self.settings.measurementSaveLocation == .googleDrive {
                    self.settings.measurementSaveLocation = .local
                }
                if self.settings.imageSaveLocation == .googleDrive {
                    self.settings.imageSaveLocation = .local
                }
                self.settings.serialize()
                
                presentAlert(self: self, title: nil, message: "Cannot save to Google Drive without Google sign-in")
                self.setSavingSummary()
            })
    }
    
    private func setSavingSummary() {
        let measurementSaveLocation = settings.measurementSaveLocation
        let imageSaveLocation = settings.imageSaveLocation
        
        var savedMessage: String!
        if measurementSaveLocation != .none || imageSaveLocation != .none {
            var savedMessageStart: String!
            if measurementSaveLocation == imageSaveLocation {
                savedMessageStart = "Saving data and images to \(saveLocationToName(measurementSaveLocation))"
            } else {
                let dataSavedMessage = measurementSaveLocation != .none ? "data to \(saveLocationToName(measurementSaveLocation))" : ""
                let imageSavedMessage = imageSaveLocation != .none ? "images to \(saveLocationToName(imageSaveLocation))" : ""
                let savedMessageStartConnector = measurementSaveLocation != .none && imageSaveLocation != .none ? " and " : ""
                
                savedMessageStart = "Saving \(dataSavedMessage)\(savedMessageStartConnector)\(imageSavedMessage)"
            }
            
            // Cap the displayed length of the dataset name.
            let maxDatasetNameLength = 33
            var displayDatasetName: String!
            if settings.datasetName.count > maxDatasetNameLength {
                displayDatasetName = String(settings.datasetName.prefix(maxDatasetNameLength - 3)) + "..."
            } else {
                displayDatasetName = settings.datasetName
            }
            
            savedMessage = "\(savedMessageStart!) under the name \(displayDatasetName!)."
        } else {
            savedMessage = ""
        }
        
        var notSavedMessage: String!
        if measurementSaveLocation == .none || imageSaveLocation == .none {
            var notSavedMessageElements: String!
            if measurementSaveLocation == .none && imageSaveLocation == .none {
                notSavedMessageElements = "Data and images"
            } else if measurementSaveLocation == .none {
                notSavedMessageElements = "Data"
            } else {
                notSavedMessageElements = "Images"
            }
            
            notSavedMessage = "\(notSavedMessageElements!) are not being saved. Go to Settings to change."
        } else {
            notSavedMessage = ""
        }
        
        savingSummary.numberOfLines = 0
        savingSummary.text = "\(savedMessage!)\n\(notSavedMessage!)"
    }
    
    private func saveLocationToName(_ saveLocation: Settings.SaveLocation) -> String {
        switch saveLocation {
        case .none:
            return "none"
        case .local:
            return "the Files App"
        case .googleDrive:
            return "Google Drive"
        }
    }
}
