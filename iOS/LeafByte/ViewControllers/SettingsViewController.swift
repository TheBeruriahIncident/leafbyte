//
//  SettingsViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 1/3/18.
//  Copyright © 2018 The Blue Folder Project. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    @IBAction func backFromSettings(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
}
