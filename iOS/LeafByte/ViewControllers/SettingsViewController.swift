//
//  SettingsViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/3/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    var settings: Settings!
    
    // MARK: - Outlets
    
    @IBOutlet weak var measurementSaveLocation: UISegmentedControl!
    @IBOutlet weak var imageSaveLocation: UISegmentedControl!
    @IBOutlet weak var seriesName: UITextField!
    @IBOutlet weak var saveGps: UISwitch!
    
    // MARK: - Actions
    
    @IBAction func measurementSaveLocationChanged(_ sender: UISegmentedControl) {
        settings.measurementSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        settings.serialize()
    }
    
    @IBAction func imageSaveLocationChanged(_ sender: UISegmentedControl) {
        settings.imageSaveLocation = indexToSaveLocation(sender.selectedSegmentIndex)
        settings.serialize()
    }
    
    @IBAction func seriesNameChanged(_ sender: UITextField) {
        settings.seriesName = sender.text!
        settings.serialize()
    }
    
    @IBAction func saveGpsChanged(_ sender: UISwitch) {
        settings.saveGpsData = sender.isOn
        settings.serialize()
    }
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        measurementSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.measurementSaveLocation)
        imageSaveLocation.selectedSegmentIndex = saveLocationToIndex(settings.imageSaveLocation)
        seriesName.text = settings.seriesName
        saveGps.setOn(settings.saveGpsData, animated: false)
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
        case .local:
            return 1
        case .googleDrive:
            return 2
        default:
            return 0
        }
    }
}
