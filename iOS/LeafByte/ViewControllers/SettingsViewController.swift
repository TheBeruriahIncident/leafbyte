//
//  SettingsViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 1/3/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import AppAuth
import UIKit

final class SettingsViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    // MARK: - Fields

    // This was set by the caller.
    // swiftlint:disable:next implicitly_unwrapped_optional
    var settings: Settings!

    var activeField: UITextField?

    var previousDatasetPickerData = [String]()
    var unitPickerData = ["mm", "cm", "m", "in", "ft"]

    // MARK: - Outlets

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var datasetName: UITextField!
    @IBOutlet weak var imageSaveLocation: UISegmentedControl!
    @IBOutlet weak var dataSaveLocation: UISegmentedControl!
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
        // swiftlint:disable:next force_unwrapping
        datasetNameChanged(sender.text!)
    }

    func datasetNameChanged(_ candidateNewName: String) {
        let sanitizedCandidateNewName = candidateNewName
            .replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")

        // Fall back to the default if the box is empty or only brackets.
        let newDatasetName: String
        if sanitizedCandidateNewName.isEmpty {
            newDatasetName = Settings.defaultDatasetName
        } else {
            newDatasetName = sanitizedCandidateNewName
        }

        settings.datasetName = newDatasetName
        // Switch to the next sample number and unit associated with this dataset.
        nextSampleNumber.text = String(settings.initializeNextSampleNumberIfNeeded())
        scaleMarkUnitButton.setTitle(settings.getUnit(), for: .normal)
        settings.serialize(self: self)

        // Update the box, in case this was a fallback or via the picker.
        datasetName.text = newDatasetName
    }

    @IBAction func choosePreviousDataset(_ sender: Any) {
        previousDatasetPickerData = settings.getPreviousDatasetNames()
        previousDatasetPicker.reloadAllComponents()

        let currentSelection = previousDatasetPickerData.firstIndex(of: settings.datasetName)
        if currentSelection != nil {
            // swiftlint:disable:next force_unwrapping
            previousDatasetPicker.selectRow(currentSelection!, inComponent: 0, animated: false)
        }

        previousDatasetPicker.isHidden = false
    }

    @IBAction func chooseUnit(_ sender: Any) {
        unitPicker.reloadAllComponents()

        let currentSelection = unitPickerData.firstIndex(of: settings.getUnit())
        if currentSelection != nil {
            // swiftlint:disable:next force_unwrapping
            unitPicker.selectRow(currentSelection!, inComponent: 0, animated: false)
        }

        unitPicker.isHidden = false
    }

    @IBAction func imageSaveLocationChanged(_ sender: UISegmentedControl) {
        dismissInput()

        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        let persistChange = {
            self.settings.imageSaveLocation = newSaveLocation
            self.settings.serialize(self: self)

            self.updateEnabledness()
        }

        if newSaveLocation == .googleDrive {
            initiateGoogleSignIn(
                onAccessTokenAndUserId: { _, _ in
                    persistChange()
                },
                onError: { cause, _ in
                    DispatchQueue.main.async {
                        self.signOutOfGoogle()
                        presentFailedGoogleSignInAlert(cause: cause, self: self)
                    }
                }, callingViewController: self, settings: settings)
        } else {
            persistChange()
        }
    }

    @IBAction func dataSaveLocationChanged(_ sender: UISegmentedControl) {
        dismissInput()

        let newSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        let persistChange = {
            self.settings.dataSaveLocation = newSaveLocation
            self.settings.serialize(self: self)

            self.updateEnabledness()
        }

        if newSaveLocation == .googleDrive {
            initiateGoogleSignIn(
                onAccessTokenAndUserId: { _, _ in
                    persistChange()
                },
                onError: { cause, _ in
                    DispatchQueue.main.async {
                        self.signOutOfGoogle()
                        presentFailedGoogleSignInAlert(cause: cause, self: self)
                    }
                }, callingViewController: self, settings: settings)
        } else {
            persistChange()
        }
    }

    @IBAction func nextSampleNumberChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        let newNextSampleNumber: Int
        // swiftlint:disable:next force_unwrapping
        if sender.text!.isEmpty || Int(sender.text!) == nil {
            newNextSampleNumber = Settings.defaultNextSampleNumber

            // If we fallback, update the box too.
            nextSampleNumber.text = String(newNextSampleNumber)
        } else {
            // Unparseable case handled above
            // swiftlint:disable:next force_unwrapping
            newNextSampleNumber = Int(sender.text!)!
        }

        settings.datasetNameToNextSampleNumber[settings.datasetName] = newNextSampleNumber
        settings.serialize(self: self)
    }

    @IBAction func saveGpsChanged(_ sender: UISwitch) {
        dismissInput()

        settings.saveGpsData = sender.isOn
        settings.serialize(self: self)
    }

    @IBAction func useBarcodesChanged(_ sender: UISwitch) {
        dismissInput()

        settings.useBarcode = sender.isOn
        settings.serialize(self: self)
    }

    @IBAction func blackBackgroundChanged(_ sender: UISwitch) {
        dismissInput()

        settings.useBlackBackground = sender.isOn
        settings.serialize(self: self)
    }

    @IBAction func scaleMarkLengthChanged(_ sender: UITextField) {
        // Fall back to the default if the box is empty.
        let newScaleMarkLength: Double
        // swiftlint:disable:next force_unwrapping
        if sender.text!.isEmpty || Double(sender.text!) == nil {
            newScaleMarkLength = Settings.defaultScaleMarkLength

            // If we fallback, update the box too.
            scaleMarkLength.text = String(newScaleMarkLength)
        } else {
            // Unparseable case handled above
            // swiftlint:disable:next force_unwrapping
            newScaleMarkLength = Double(sender.text!)!
        }

        settings.scaleMarkLength = newScaleMarkLength
        settings.serialize(self: self)
    }

    @IBAction func signOutOfGoogle(_ sender: Any) {
        signOutOfGoogle()
    }

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        datasetName.text = settings.datasetName
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        dataSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.dataSaveLocation)
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
        dataSaveLocation.setTitle(localStorageName, forSegmentAt: saveLocationToIndex(.local))
        imageSaveLocation.setTitle(localStorageName, forSegmentAt: saveLocationToIndex(.local))

        // Setup to get a callback when return is pressed on a keyboard.
        // Note that current iOS is buggy and doesn't show the return button for number keyboards even when enabled; this aims to handle that case once it works.
        datasetName.delegate = self
        nextSampleNumber.delegate = self
        scaleMarkLength.delegate = self

        updateEnabledness()

        registerForKeyboardNotifications()

        // Make sure touch events aren't intercepted by the scroll view.
        let recog = UITapGestureRecognizer(target: self, action: #selector(Self.dismissInput))
        recog.cancelsTouchesInView = false
        scrollView.addGestureRecognizer(recog)

        previousDatasetPicker.dataSource = self
        previousDatasetPicker.delegate = self
        previousDatasetPicker.isHidden = true

        unitPicker.dataSource = self
        unitPicker.delegate = self
        unitPicker.isHidden = true

        // swiftlint:disable:next force_unwrapping
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
        super.viewWillDisappear(animated)
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
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return previousDatasetPickerData.count
        } else {
            return unitPickerData.count
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
            settings.serialize(self: self)

            scaleMarkUnitButton.setTitle(settings.getUnit(), for: .normal)
        }
    }

    // MARK: - Helpers

    // @objc to allow calling as a Selector.
    @objc
    private func dismissInput() {
        previousDatasetPicker.isHidden = true
        unitPicker.isHidden = true
        self.view.endEditing(true)
    }

    private func signOutOfGoogle() {
        if settings.dataSaveLocation == .googleDrive {
            settings.dataSaveLocation = .local
        }
        if settings.imageSaveLocation == .googleDrive {
            settings.imageSaveLocation = .local
        }
        // Clearing the auth state is counterintuitively actually all we need here. When a user thinks about signing out of Google, they generally don't actually want their whole phone to be signed out of Google, which would likely be a huge inconvenience for them, so we shouldn't initiate an actual sign-out. What they want is for LeafByte itself to not know about their Google sign-in anymore, and all it takes for that is for us to "forget" about their Google sign-in state.
        settings.googleAuthState = nil
        settings.serialize(self: self)

        dataSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.dataSaveLocation)
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)

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
        let dataSavingEnabled = settings.dataSaveLocation != .none
        saveGps.isEnabled = dataSavingEnabled
        saveGpsLabel.isEnabled = dataSavingEnabled
        saveGpsNoteLabel.isEnabled = dataSavingEnabled

        let anySavingEnabled = settings.dataSaveLocation != .none || settings.imageSaveLocation != .none
        datasetName.isEnabled = anySavingEnabled
        datasetNameLabel.isEnabled = anySavingEnabled

        // If there is a Google auth state, there has been a successful sign-in
        signOutOfGoogleButton.isEnabled = settings.googleAuthState != nil
    }

    func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func deregisterFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    // When the keyboard is to be shown, slide the view up if the keyboard would cover the text field being edited.
    @objc
    func keyboardWasShown(notification: NSNotification) {
        var visibleFrame = self.view.frame

        // The visible frame is covered partially by the status bar, the nav bar, and the keyboard.
        visibleFrame.size.height -= getKeyboardHeight(notification: notification)
        if self.navigationController != nil {
            // swiftlint:disable:next force_unwrapping
            visibleFrame.size.height -= self.navigationController!.navigationBar.frame.height
        }
        visibleFrame.size.height -= UIApplication.shared.statusBarFrame.height

        // Account for any scrolling that has already happened.
        visibleFrame.size.height += scrollView.contentOffset.y

        // Check if the field is out of the view.
        if activeField != nil && visibleFrame.size.height < activeField!.frame.maxY { // swiftlint:disable:this force_unwrapping
            // Scroll down if so.
            scrollView.contentOffset = CGPoint(x: 0, y: (activeField!.frame.maxY - visibleFrame.size.height) + scrollView.contentOffset.y)  // swiftlint:disable:this force_unwrapping
        }
    }

    // We want to get the actual value, but this is our fallback https://stackoverflow.com/questions/11284321/what-is-the-height-of-iphones-onscreen-keyboard
    private let defaultKeyboardHeight = CGFloat(200)
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        guard let info = notification.userInfo else {
            return defaultKeyboardHeight
        }
        guard let container = info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue else {
            return defaultKeyboardHeight
        }
        let keyboardSize = container.cgRectValue.size
        return keyboardSize.height
    }
}
