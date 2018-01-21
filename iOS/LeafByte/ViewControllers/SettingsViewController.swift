//
//  SettingsViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/3/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import GoogleSignIn
import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate {
    var settings: Settings!
    
    // MARK: - Outlets
    
    @IBOutlet weak var measurementSaveLocation: UISegmentedControl!
    @IBOutlet weak var imageSaveLocation: UISegmentedControl!
    @IBOutlet weak var datasetName: UITextField!
    @IBOutlet weak var nextSampleNumber: UITextField!
    @IBOutlet weak var saveGps: UISwitch!
    
    @IBOutlet weak var datasetNameLabel: UILabel!
    @IBOutlet weak var nextSampleNumberLabel: UILabel!
    @IBOutlet weak var saveGpsLabel: UILabel!
    
    @IBOutlet weak var signOutOfGoogleButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func measurementSaveLocationChanged(_ sender: UISegmentedControl) {
        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        maybeDoSignIn(newSaveLocation: newSaveLocation)
        
        settings.measurementSaveLocation = newSaveLocation
        settings.serialize()
        
        updateEnabledness()
        
        // Dismiss the keyboard if it's open.
        self.view.endEditing(true)
    }
    
    @IBAction func imageSaveLocationChanged(_ sender: UISegmentedControl) {
        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        maybeDoSignIn(newSaveLocation: newSaveLocation)
        
        settings.imageSaveLocation = newSaveLocation
        settings.serialize()
        
        updateEnabledness()
        
        // Dismiss the keyboard if it's open.
        self.view.endEditing(true)
    }
    
    @IBAction func datasetNameChanged(_ sender: UITextField) {
        // If the value hasn't changed, return early to avoid unnecessarily resetting the sample number.
        if settings.datasetName == sender.text! {
                return
        }
        
        // Fall back to the default if the box is empty.
        var newDatasetName: String!
        if sender.text!.isEmpty {
            newDatasetName = Settings.defaultDatasetName
            
            // If we fallback, update the box too.
            datasetName.text = newDatasetName
        } else {
            newDatasetName = sender.text!
        }
        
        settings.datasetName = newDatasetName
        settings.nextSampleNumber = 1
        settings.serialize()
        
        nextSampleNumber.text = String(Settings.defaultNextSampleNumber)
    }
    
    @IBAction func nextSampleNumberChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        var newNextSampleNumber: Int!
        if sender.text!.isEmpty {
            newNextSampleNumber = Settings.defaultNextSampleNumber
            
            // If we fallback, update the box too.
            nextSampleNumber.text = String(newNextSampleNumber)
        } else {
            newNextSampleNumber = Int(sender.text!)
        }
        
        settings.nextSampleNumber = newNextSampleNumber
        settings.serialize()
    }
    
    @IBAction func saveGpsChanged(_ sender: UISwitch) {
        settings.saveGpsData = sender.isOn
        settings.serialize()
        
        // Dismiss the keyboard if it's open.
        self.view.endEditing(true)
    }
    
    
    @IBAction func signOutOfGoogle(_ sender: Any) {
        if settings.measurementSaveLocation == .googleDrive {
            settings.measurementSaveLocation = .none
            measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(.none)
        }
        if settings.imageSaveLocation == .googleDrive {
            settings.imageSaveLocation = .none
            imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(.none)
        }
        settings.serialize()
        
        GIDSignIn.sharedInstance().signOut()
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.measurementSaveLocation)
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        datasetName.text = settings.datasetName
        nextSampleNumber.text = String(settings.nextSampleNumber)
        saveGps.setOn(settings.saveGpsData, animated: false)
        
        // Setup to get a callback when return is pressed on a keyboard.
        // Note that current iOS is buggy and doesn't show the return button for number keyboards even when enabled; this aims to handle that case once it works.
        datasetName.delegate = self
        nextSampleNumber.delegate = self
        
        updateEnabledness()
    }
    
    // If a user taps outside of the keyboard, close the keyboard.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: - UITextFieldDelegate overrides
    
    // Called when return is pressed on the keyboard.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: - Helpers
    
    private func indexToSaveLocation(_ index: Int) -> Settings.SaveLocation {
        switch index {
        case 1:
            return Settings.SaveLocation.local
        case 2:
            return Settings.SaveLocation.googleDrive
        default:
            return Settings.SaveLocation.none
        }
    }
    
    private func saveLocationToIndex(_ saveLocation: Settings.SaveLocation) -> Int {
        switch saveLocation {
        case .none:
            return 0
        case .local:
            return 1
        case .googleDrive:
            return 2
        }
    }
    
    // Disable controls that would have no effect.
    private func updateEnabledness() {
        let measurementSavingEnabled = settings.measurementSaveLocation != .none
        saveGps.isEnabled = measurementSavingEnabled
        saveGpsLabel.isEnabled = measurementSavingEnabled
        
        let anySavingEnabled = settings.measurementSaveLocation != .none || settings.imageSaveLocation != .none
        datasetName.isEnabled = anySavingEnabled
        datasetNameLabel.isEnabled = anySavingEnabled
        nextSampleNumber.isEnabled = anySavingEnabled
        nextSampleNumberLabel.isEnabled = anySavingEnabled
        
        let anyGoogleDriveSavingEnabled = settings.measurementSaveLocation == .googleDrive || settings.imageSaveLocation == .googleDrive
        signOutOfGoogleButton.isEnabled = anyGoogleDriveSavingEnabled
    }
    
    // Sign in to Google if necessary.
    private func maybeDoSignIn(newSaveLocation: Settings.SaveLocation) {
        if newSaveLocation != .googleDrive {
            return
        }
        
        GoogleSignInManager.initiateSignIn(actionWithAccessToken: { print($0) })
    }
}
