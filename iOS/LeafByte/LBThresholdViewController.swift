//
//  LBThresholdViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class LBThresholdViewController: UIViewController, UINavigationControllerDelegate {
    
    var image: UIImage?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        imageView.image = image
    }
    
    @IBAction func backFromThreshold(_ sender: Any) {
        
//        if let navController = self.navigationController {
//            navController.popViewController(animated: true)
//        }
        //self.navigationController?.popViewController(animated: false)
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func fromMainMenu(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? LBMainMenuViewController, let image = sourceViewController.image {
            
            imageView.image = image
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segueing")
        print(segue.identifier)
        if segue.identifier == "imageChosen"
        {
            guard let sender1 = sender as? LBMainMenuViewController else {
                fatalError("Expected a seque from the main menu but instead came from: \(sender)")
            }
            
            imageView.image = sender1.image
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
}
