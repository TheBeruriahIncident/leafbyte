//
//  LBFillHolesViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//


import UIKit

class LBFillHolesViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    var baseImage: UIImage?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        baseImageView.image = baseImage
        baseImageView.contentMode = .scaleAspectFit
    }
    
    @IBOutlet weak var baseImageView: UIImageView!
}
