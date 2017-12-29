//
//  LBThresholdViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class LBThresholdViewController: UIViewController, UINavigationControllerDelegate {
    
    @IBAction func backFromThreshold(_ sender: Any) {
        
//        if let navController = self.navigationController {
//            navController.popViewController(animated: true)
//        }
        //self.navigationController?.popViewController(animated: false)
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
}
