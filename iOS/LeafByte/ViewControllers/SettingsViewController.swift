//
//  SettingsViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/3/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import GoogleSignIn
import UIKit

final class SettingsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    // MARK: - Fields
    
    var settings: Settings!
    
    var activeField: UITextField?
    
    var previousDatasetPickerData = [String]()
    
    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var datasetName: UITextField!
    @IBOutlet weak var imageSaveLocation: UISegmentedControl!
    @IBOutlet weak var measurementSaveLocation: UISegmentedControl!
    @IBOutlet weak var nextSampleNumber: UITextField!
    @IBOutlet weak var useBarcode: UISwitch!
    @IBOutlet weak var saveGps: UISwitch!
    @IBOutlet weak var scaleMarkLength: UITextField!
    @IBOutlet weak var previousDatasetPicker: UIPickerView!
    
    @IBOutlet weak var datasetNameLabel: UILabel!
    @IBOutlet weak var nextSampleNumberLabel: UILabel!
    @IBOutlet weak var useBarcodeLabel: UILabel!
    @IBOutlet weak var saveGpsLabel: UILabel!
    @IBOutlet weak var saveGpsNoteLabel: UILabel!
    
    @IBOutlet weak var previousDatasetButton: UIButton!
    @IBOutlet weak var signOutOfGoogleButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func datasetNameChanged(_ sender: UITextField) {
        datasetNameChanged(sender.text!)
    }
    
    func datasetNameChanged(_ candidateNewName: String) {
        // Fall back to the default if the box is empty.
        var newDatasetName: String!
        if candidateNewName.isEmpty {
            newDatasetName = Settings.defaultDatasetName
        } else {
            newDatasetName = candidateNewName
        }
        
        settings.datasetName = newDatasetName
        // Switch to the next sample number associated with this dataset.
        nextSampleNumber.text = String(settings.initializeNextSampleNumberIfNeeded())
        settings.serialize()
        
        // Update the box, in case this was a fallback or via the picker.
        datasetName.text = newDatasetName
    }
    
    @IBAction func choosePreviousDataset(_ sender: Any) {
        previousDatasetPickerData = settings.getPreviousDatasetNames()
        previousDatasetPicker.reloadAllComponents()
        
        previousDatasetPicker.isHidden = false
    }
    
    @IBAction func imageSaveLocationChanged(_ sender: UISegmentedControl) {
        dismissInput()
        
        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        let persistChange = {
            self.settings.imageSaveLocation = newSaveLocation
            self.settings.serialize()
            
            self.updateEnabledness()
        }
        
        if newSaveLocation == .googleDrive {
            GoogleSignInManager.initiateSignIn(
                onAccessTokenAndUserId: { (_, _) in
                    persistChange()
                },
                onError: { _ in
                    // Set the selected index back to the previous selected index; don't allow changing to Google Drive if you can't log-in.
                    self.imageSaveLocation.selectedSegmentIndex = self.saveLocationToIndex(self.settings.imageSaveLocation)
                    self.presentFailedGoogleSignInAlert()
                })
        } else {
            persistChange()
        }
    }
    
    @IBAction func measurementSaveLocationChanged(_ sender: UISegmentedControl) {
        dismissInput()
        
        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        let persistChange = {
            self.settings.measurementSaveLocation = newSaveLocation
            self.settings.serialize()
            
            self.updateEnabledness()
        }
        
        if newSaveLocation == .googleDrive {
            GoogleSignInManager.initiateSignIn(
                onAccessTokenAndUserId: { _, _ in 
                    persistChange()
                },
                onError: { _ in
                    // Set the selected index back to the previous selected index; don't allow changing to Google Drive if you can't log-in.
                    self.measurementSaveLocation.selectedSegmentIndex = self.saveLocationToIndex(self.settings.measurementSaveLocation)
                    self.presentFailedGoogleSignInAlert()
            })
        } else {
            persistChange()
        }
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
        
        settings.datasetNameToNextSampleNumber[settings.datasetName] = newNextSampleNumber
        settings.serialize()
    }
    
    @IBAction func saveGpsChanged(_ sender: UISwitch) {
        dismissInput()
        
        settings.saveGpsData = sender.isOn
        settings.serialize()
    }
    
    @IBAction func useBarcodesChanged(_ sender: UISwitch) {
        dismissInput()
        
        settings.useBarcode = sender.isOn
        settings.serialize()
    }
    
    @IBAction func scaleMarkLengthChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        var newScaleMarkLength: Double!
        if sender.text!.isEmpty {
            newScaleMarkLength = Settings.defaultScaleMarkLength
            
            // If we fallback, update the box too.
            scaleMarkLength.text = String(newScaleMarkLength)
        } else {
            newScaleMarkLength = Double(sender.text!)
        }
        
        settings.scaleMarkLength = newScaleMarkLength
        settings.serialize()
    }
    
    @IBAction func signOutOfGoogle(_ sender: Any) {
        if settings.measurementSaveLocation == .googleDrive {
            settings.measurementSaveLocation = .local
            measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(.none)
        }
        if settings.imageSaveLocation == .googleDrive {
            settings.imageSaveLocation = .local
            imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(.none)
        }
        settings.serialize()
        
        GIDSignIn.sharedInstance().signOut()
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datasetName.text = settings.datasetName
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.measurementSaveLocation)
        nextSampleNumber.text = String(settings.getNextSampleNumber())
        saveGps.setOn(settings.saveGpsData, animated: false)
        useBarcode.setOn(settings.useBarcode, animated: false)
        scaleMarkLength.text = String(settings.scaleMarkLength)
        
        // The Files App was added in iOS 11, but saved data can be accessed in iTunes File Sharing in any version.
        var localStorageName: String
        if #available(iOS 11.0, *) {
            localStorageName = NSLocalizedString("Files App", comment: "Name for local storage on iOS 11 and newer")
        } else {
            localStorageName = NSLocalizedString("Phone", comment: "Name for local storage before iOS 11")
        }
        measurementSaveLocation.setTitle(localStorageName, forSegmentAt: saveLocationToIndex(.local))
        imageSaveLocation.setTitle(localStorageName, forSegmentAt: saveLocationToIndex(.local))
        
        // Setup to get a callback when return is pressed on a keyboard.
        // Note that current iOS is buggy and doesn't show the return button for number keyboards even when enabled; this aims to handle that case once it works.
        datasetName.delegate = self
        nextSampleNumber.delegate = self
        scaleMarkLength.delegate = self
        
        updateEnabledness()
        
        registerForKeyboardNotifications()
        
        // Make sure touch events aren't intercepted by the scroll view.
        let recog = UITapGestureRecognizer(target: self, action: #selector(SettingsViewController.dismissInput))
        recog.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(recog)
        
        previousDatasetPicker.dataSource = self
        previousDatasetPicker.delegate = self
        previousDatasetPicker.isHidden = true
        
        previousDatasetButton.titleLabel!.lineBreakMode = .byWordWrapping
        
        if #available(iOS 9.0, *) {
            saveGps.isHidden = false
            saveGpsLabel.isHidden = false
            saveGpsNoteLabel.isHidden = false
        }
        if #available(iOS 10.0, *) {
            useBarcode.isHidden = false
            useBarcodeLabel.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        deregisterFromKeyboardNotifications()
    }
    
    // If a user taps outside of the keyboard, close the keyboard.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        dismissInput()
    }
    
    // MARK: - UITextFieldDelegate overrides
    
    // Called when return is pressed on the keyboard.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissInput()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField){
        // Track the current edited fields.
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField){
        // Clear the current edited fields.
        activeField = nil
    }
    
    // MARK: - UIPickerViewDataSource, UIPickerViewDelegate overrides
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return previousDatasetPickerData.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return previousDatasetPickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        datasetNameChanged(previousDatasetPickerData[row])
    }
    
    // MARK: - Helpers
    
    // @objc to allow calling as a Selector.
    @objc private func dismissInput() {
        previousDatasetPicker.isHidden = true
        self.view.endEditing(true)
    }
    
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
        saveGpsNoteLabel.isEnabled = measurementSavingEnabled
        
        let anySavingEnabled = settings.measurementSaveLocation != .none || settings.imageSaveLocation != .none
        datasetName.isEnabled = anySavingEnabled
        datasetNameLabel.isEnabled = anySavingEnabled
        nextSampleNumber.isEnabled = anySavingEnabled
        nextSampleNumberLabel.isEnabled = anySavingEnabled
        
        let anyGoogleDriveSavingEnabled = settings.measurementSaveLocation == .googleDrive || settings.imageSaveLocation == .googleDrive
        signOutOfGoogleButton.isEnabled = anyGoogleDriveSavingEnabled
    }
    
    private func presentFailedGoogleSignInAlert() {
        presentAlert(self: self, title: nil, message: NSLocalizedString("Google sign-in is required for saving to Google Drive", comment: "Shown if Google sign-in fails after choosing to save to Google Drive"))
    }
    
    func registerForKeyboardNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func deregisterFromKeyboardNotifications(){
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWasShown(notification: NSNotification){
        // When the keyboard is to be shown, slide the view up if the keyboard would cover the text field being edited.
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
        scrollView.contentInset = contentInsets
        
        var visibleFrame = self.view.frame
        
        visibleFrame.size.height -= keyboardSize.height
        if !visibleFrame.contains(activeField!.frame.origin) {
            let scrollOffsetBuffer = 20
            let scrollOffset = Int(self.view.frame.height - (activeField!.frame.origin.y + activeField!.frame.size.height)) + scrollOffsetBuffer
            
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollOffset), animated: true)
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification){
        // When the keyboard is to be hidden, scroll the view back.
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize.height, 0.0)
        scrollView.contentInset = contentInsets
    }
}
