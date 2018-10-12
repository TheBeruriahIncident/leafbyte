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
    var unitPickerData = ["mm", "cm", "m", "in", "ft"]
    
    // MARK: - Outlets
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var datasetName: UITextField!
    @IBOutlet weak var imageSaveLocation: UISegmentedControl!
    @IBOutlet weak var measurementSaveLocation: UISegmentedControl!
    @IBOutlet weak var nextSampleNumber: UITextField!
    @IBOutlet weak var useBarcode: UISwitch!
    @IBOutlet weak var saveGps: UISwitch!
    @IBOutlet weak var blackBackground: UISwitch!
    @IBOutlet weak var scaleMarkLength: UITextField!
    @IBOutlet weak var previousDatasetPicker: UIPickerView!
    @IBOutlet weak var unitPicker: UIPickerView!
    
    @IBOutlet weak var datasetNameLabel: UILabel!
    @IBOutlet weak var useBarcodeLabel: UILabel!
    @IBOutlet weak var saveGpsLabel: UILabel!
    @IBOutlet weak var saveGpsNoteLabel: UILabel!
    
    @IBOutlet weak var scaleMarkUnitButton: UIButton!
    @IBOutlet weak var previousDatasetButton: UIButton!
    @IBOutlet weak var signOutOfGoogleButton: UIButton!
    
    // MARK: - Actions
    
    @IBAction func datasetNameChanged(_ sender: UITextField) {
        datasetNameChanged(sender.text!)
    }
    
    func datasetNameChanged(_ candidateNewName: String) {
        let sanitizedCandidateNewName = candidateNewName
                .replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        
        // Fall back to the default if the box is empty or only brackets.
        var newDatasetName: String!
        if sanitizedCandidateNewName.isEmpty {
            newDatasetName = Settings.defaultDatasetName
        } else {
            newDatasetName = sanitizedCandidateNewName
        }
        
        settings.datasetName = newDatasetName
        // Switch to the next sample number and unit associated with this dataset.
        nextSampleNumber.text = String(settings.initializeNextSampleNumberIfNeeded())
        scaleMarkUnitButton.setTitle(settings.getUnit(), for: .normal)
        settings.serialize()
        
        // Update the box, in case this was a fallback or via the picker.
        datasetName.text = newDatasetName
    }
    
    @IBAction func choosePreviousDataset(_ sender: Any) {
        previousDatasetPickerData = settings.getPreviousDatasetNames()
        previousDatasetPicker.reloadAllComponents()
        
        let currentSelection = previousDatasetPickerData.index(of: settings.datasetName)
        if currentSelection != nil {
            previousDatasetPicker.selectRow(currentSelection!, inComponent: 0, animated: false)
        }
        
        previousDatasetPicker.isHidden = false
    }
    
    @IBAction func chooseUnit(_ sender: Any) {
        unitPicker.reloadAllComponents()
        
        let currentSelection = unitPickerData.index(of: settings.getUnit())
        if currentSelection != nil {
            unitPicker.selectRow(currentSelection!, inComponent: 0, animated: false)
        }
        
        unitPicker.isHidden = false
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
                    DispatchQueue.main.async {
                        self.signOutOfGoogle()
                        self.presentFailedGoogleSignInAlert()
                    }
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
                    DispatchQueue.main.async {
                        self.signOutOfGoogle()
                        self.presentFailedGoogleSignInAlert()
                    }
            })
        } else {
            persistChange()
        }
    }
    
    @IBAction func nextSampleNumberChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        var newNextSampleNumber: Int!
        if sender.text!.isEmpty || Int(sender.text!) == nil {
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
    
    @IBAction func blackBackgroundChanged(_ sender: UISwitch) {
        dismissInput()
        
        settings.useBlackBackground = sender.isOn
        settings.serialize()
    }
    
    @IBAction func scaleMarkLengthChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        var newScaleMarkLength: Double!
        if sender.text!.isEmpty || Double(sender.text!) == nil {
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
        signOutOfGoogle()
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        datasetName.text = settings.datasetName
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.measurementSaveLocation)
        nextSampleNumber.text = String(settings.getNextSampleNumber())
        scaleMarkUnitButton.setTitle(settings.getUnit(), for: .normal)
        saveGps.setOn(settings.saveGpsData, animated: false)
        useBarcode.setOn(settings.useBarcode, animated: false)
        blackBackground.setOn(settings.useBlackBackground, animated: false)
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
        
        unitPicker.dataSource = self
        unitPicker.delegate = self
        unitPicker.isHidden = true
        
        previousDatasetButton.titleLabel!.lineBreakMode = .byWordWrapping
        
        if #available(iOS 10.0, *) {
            useBarcode.isHidden = false
            useBarcodeLabel.isHidden = false
        } else {
            useBarcodeLabel.text = "Barcode Scanning requires iOS 10"
            useBarcodeLabel.isEnabled = false
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Track the current edited fields.
        activeField = textField
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Clear the current edited fields.
        activeField = nil
    }
    
    // MARK: - UIPickerViewDataSource, UIPickerViewDelegate overrides
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return previousDatasetPickerData.count;
        } else {
            return unitPickerData.count;
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return previousDatasetPickerData[row]
        } else {
            return unitPickerData[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            datasetNameChanged(previousDatasetPickerData[row])
        } else {
            settings.datasetNameToUnit[settings.datasetName] = unitPickerData[row]
            settings.serialize()
            
            scaleMarkUnitButton.setTitle(settings.getUnit(), for: .normal)
        }
    }
    
    // MARK: - Helpers
    
    // @objc to allow calling as a Selector.
    @objc private func dismissInput() {
        previousDatasetPicker.isHidden = true
        unitPicker.isHidden = true
        self.view.endEditing(true)
    }
    
    private func signOutOfGoogle() {
        if settings.measurementSaveLocation == .googleDrive {
            settings.measurementSaveLocation = .local
        }
        if settings.imageSaveLocation == .googleDrive {
            settings.imageSaveLocation = .local
        }
        settings.serialize()
        
        measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.measurementSaveLocation)
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        
        GIDSignIn.sharedInstance().signOut()
        updateEnabledness()
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
        
        let anyGoogleDriveSavingEnabled = settings.measurementSaveLocation == .googleDrive || settings.imageSaveLocation == .googleDrive
        signOutOfGoogleButton.isEnabled = anyGoogleDriveSavingEnabled
    }
    
    private func presentFailedGoogleSignInAlert() {
        presentAlert(self: self, title: nil, message: NSLocalizedString("Google sign-in is required for saving to Google Drive", comment: "Shown if Google sign-in fails after choosing to save to Google Drive"))
    }
    
    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    // When the keyboard is to be shown, slide the view up if the keyboard would cover the text field being edited.
    @objc func keyboardWasShown(notification: NSNotification) {
        var visibleFrame = self.view.frame
        
        // The visible frame is covered partially by the status bar, the nav bar, and the keyboard.
        visibleFrame.size.height -= getKeyboardHeight(notification: notification)
        visibleFrame.size.height -= self.navigationController!.navigationBar.frame.height
        visibleFrame.size.height -= UIApplication.shared.statusBarFrame.height
        
        // Account for any scrolling that has already happened.
        visibleFrame.size.height += scrollView.contentOffset.y

        // Check if the field is out of the view.
        if visibleFrame.size.height < activeField!.frame.maxY {
            // Scroll down if so.
            scrollView.contentOffset = CGPoint(x: 0, y: (activeField!.frame.maxY - visibleFrame.size.height) + scrollView.contentOffset.y)
        }
    }
    
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue.size
        return keyboardSize.height
    }
}
