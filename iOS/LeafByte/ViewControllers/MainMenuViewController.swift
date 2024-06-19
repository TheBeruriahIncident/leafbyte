//
//  MainMenuViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 12/20/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AVFoundation
import UIKit

// This class controls the main menu view, the first view in the app.
final class MainMenuViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Fields

    private let leafbyteWebsiteUrl = URL(string: "https://zoegp.science/leafbyte")!

    // This is set in viewDidLoad.
    // swiftlint:disable:next implicitly_unwrapped_optional
    var settings: Settings!

    let imagePicker = UIImagePickerController()

    // Tracks whether viewDidAppear has run, so that we can initialize only once.
    var viewDidAppearHasRun = false

    // Both of these are set while picking an image and are passed forward to the next view.
    var sourceType: UIImagePickerController.SourceType?
    var selectedImage: CGImage?

    // To prevent double tapping from double seguing, we disable segue after the first tap until coming back to this view.
    var segueEnabled = true

    // MARK: - Outlets

    @IBOutlet weak var savingSummary: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cameraLabel: UILabel!

    // MARK: - Actions

    @IBAction func goToSettings() {
        if !segueEnabled {
            return
        }
        segueEnabled = false

        performSegue(withIdentifier: "toSettings", sender: self)
    }

    @IBAction func goToTutorial() {
        if !segueEnabled {
            return
        }
        segueEnabled = false

        performSegue(withIdentifier: "toTutorial", sender: self)
    }

    @IBAction func openWebsite(_ sender: Any) {
        if #available(iOS 10.0, *) {
            // Note that, unlike the deprecated openURL method, this is async, which will hopefully resolve the cryptic crash report on openURL that I'm guessing was a timeout on the main thread
            UIApplication.shared.open(leafbyteWebsiteUrl)
        } else {
            UIApplication.shared.openURL(leafbyteWebsiteUrl)
        }
    }

    @IBAction func pickImageFromCamera(_ sender: Any) {
        if !segueEnabled {
            return
        }
        segueEnabled = false

        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            presentAlert(self: self, title: nil, message: NSLocalizedString("No available camera", comment: "Shown when trying to take a picture if no camera is available, e.g. in a simulator"))
            segueEnabled = true
            return
        }

        requestCameraAccess(self: self, onSuccess: {
            DispatchQueue.main.async {
                if self.settings.useBarcode {
                    self.performSegue(withIdentifier: "toBarcodeScanning", sender: self)
                } else {
                    self.presentImagePicker(sourceType: UIImagePickerController.SourceType.camera)
                }
            }
        }, onFailure: { self.segueEnabled = true })
    }

    @IBAction func pickImageFromPhotoLibrary(_ sender: Any) {
        if !segueEnabled {
            return
        }
        segueEnabled = false

        presentImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary)
    }

    // Despite having no content, this must exist to enable the programmatic segues back to this view.
    @IBAction func backToMainMenu(segue: UIStoryboardSegue) {}

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        settings = Settings.deserialize()
        setupImagePicker(imagePicker: imagePicker, self: self)

        if !isGoogleSignInConfigured() {
            print("************************************************************")
            print("STOP! Please fill in the Secrets.xcconfig file! Google Sign-In is not configured and WILL NOT WORK!")
            print("************************************************************")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        segueEnabled = true

        if !viewDidAppearHasRun {
            maybeDoGoogleSignIn()
            viewDidAppearHasRun = true
        }

        setSavingSummary()

        let imageToUse = settings.useBarcode ? "Barcode" : "Camera"
        cameraButton.setBackgroundImage(UIImage(named: imageToUse), for: .normal)
        cameraLabel.text = settings.useBarcode ? NSLocalizedString("Scan Barcode and\nTake a Photo", comment: "Option for the user") : NSLocalizedString("Take a Photo", comment: "Option for the user")
        cameraLabel.numberOfLines = settings.useBarcode ? 2 : 1

        maintainOldModalPresentationStyle(viewController: imagePicker)
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If the segue is imageChosen, we're transitioning forward in the main flow, and we need to pass the selection forward.
        if segue.identifier == "imageChosen" {
            guard let navigationController = segue.destination as? UINavigationController else {
                fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
            }
            guard let destination = navigationController.topViewController as? BackgroundRemovalViewController else {
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
            if #available(iOS 10.0, *) {
                guard let navigationController = segue.destination as? UINavigationController else {
                    fatalError("Expected the next view to be wrapped in a navigation controller, but next view is \(segue.destination)")
                }
                guard let destination = navigationController.topViewController as? BarcodeScanningViewController else {
                    fatalError("Expected the view inside the navigation controller to be the barcode scanning view but is  \(String(describing: navigationController.topViewController))")
                }

                destination.settings = settings
            } else {
                fatalError("Attempting to use barcode scanning pre-iOS 10.0")
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // See finishWithImagePicker for why animations may be disabled; make sure they're enabled before leaving.
        UIView.setAnimationsEnabled(true)
    }

    // MARK: - UIImagePickerControllerDelegate overrides

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        finishWithImagePicker(self: self, info: info) { selectedImage = $0 }
    }

    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Helpers

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        self.sourceType = sourceType
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }

    // Sign in to Google if necessary.
    private func maybeDoGoogleSignIn() {
        if settings.dataSaveLocation != .googleDrive && settings.imageSaveLocation != .googleDrive {
            return
        }

        initiateGoogleSignIn(
            onAccessTokenAndUserId: { _, _ in () },
            onError: { cause, _ in
                if self.settings.dataSaveLocation == .googleDrive {
                    self.settings.dataSaveLocation = .local
                }
                if self.settings.imageSaveLocation == .googleDrive {
                    self.settings.imageSaveLocation = .local
                }
                self.settings.serialize()

                DispatchQueue.main.async {
                    presentFailedGoogleSignInAlert(cause: cause, self: self)
                    self.setSavingSummary()
                }
            }, callingViewController: self, settings: settings)
    }

    private func setSavingSummary() {
        let dataSaveLocation = settings.dataSaveLocation
        let imageSaveLocation = settings.imageSaveLocation

        let savedMessage: String
        if dataSaveLocation != .none || imageSaveLocation != .none {
            let savedMessageStart: String
            if dataSaveLocation == imageSaveLocation {
                savedMessageStart = String.localizedStringWithFormat(NSLocalizedString("Saving data and images to %@", comment: "Says that both data and images are being saved somewhere"), saveLocationToName(dataSaveLocation))
            } else {
                let dataSavedMessage = dataSaveLocation != .none ? String.localizedStringWithFormat(NSLocalizedString("data to %@", comment: "Says data are being saved somewhere"), saveLocationToName(dataSaveLocation)) : ""
                let imageSavedMessage = imageSaveLocation != .none ? String.localizedStringWithFormat(NSLocalizedString("images to %@", comment: "Says images are being saved somewhere"), saveLocationToName(imageSaveLocation)) : ""
                let savedMessageStartConnector = dataSaveLocation != .none && imageSaveLocation != .none ? NSLocalizedString(" and ", comment: "Conjunction connecting where data and iamges are being saved") : ""

                savedMessageStart = NSLocalizedString("Saving ", comment: "Beginning of message of where things are saved") + "\(dataSavedMessage)\(savedMessageStartConnector)\(imageSavedMessage)"
            }

            // Cap the displayed length of the dataset name.
            let maxDatasetNameLength = 33
            let displayDatasetName: String
            if settings.datasetName.count > maxDatasetNameLength {
                displayDatasetName = String(settings.datasetName.prefix(maxDatasetNameLength - 3)) + "..."
            } else {
                displayDatasetName = settings.datasetName
            }

            savedMessage = savedMessageStart + NSLocalizedString(" under the name ", comment: "Connector saying that something is saved with a certain name") + "\(displayDatasetName)."
        } else {
            savedMessage = ""
        }

        let notSavedMessage: String
        if dataSaveLocation == .none || imageSaveLocation == .none {
            let notSavedMessageElements: String
            if dataSaveLocation == .none && imageSaveLocation == .none {
                notSavedMessageElements = NSLocalizedString("Data and images", comment: "Name for what's being saved")
            } else if dataSaveLocation == .none {
                notSavedMessageElements = NSLocalizedString("Data", comment: "Name for what's being saved")
            } else {
                notSavedMessageElements = NSLocalizedString("Images", comment: "Name for what's being saved")
            }

            notSavedMessage = notSavedMessageElements + NSLocalizedString(" are not being saved. Go to Settings to change.", comment: "Says that something is not being saved")
        } else {
            notSavedMessage = ""
        }

        savingSummary.numberOfLines = 0
        savingSummary.text = "\(savedMessage)\n\(notSavedMessage)"

        // It can be very bad if you unintentionally aren't saving data, so put some text in red.
        if dataSaveLocation == .none {
            let stringToColor = "not being saved"
            let rangeToColor = (savingSummary.text! as NSString).range(of: stringToColor)

            let attributedString = NSMutableAttributedString(string: savingSummary.text!)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: rangeToColor)

            savingSummary.attributedText = attributedString
        }
    }

    private func saveLocationToName(_ saveLocation: Settings.SaveLocation) -> String {
        switch saveLocation {
        case .none:
            return NSLocalizedString("none", comment: "Not saving")

        case .local:
            // The Files App was added in iOS 11, but saved data can be accessed in iTunes File Sharing in any version.
            if #available(iOS 11.0, *) {
                return NSLocalizedString("the Files App", comment: "Name for local storage on iOS 11 and newer")
            } else {
                return NSLocalizedString("the phone", comment: "Name for local storage before iOS 11")
            }

        case .googleDrive:
            return NSLocalizedString("Google Drive", comment: "Name of Google Drive")
        }
    }
}
