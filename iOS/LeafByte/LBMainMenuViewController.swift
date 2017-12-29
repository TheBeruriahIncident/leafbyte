//
//  LBMainMenuViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class LBMainMenuViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        
        //self.navigationController?.popToRootViewController(animated: false)
    }
    
    var open = false
    
    @IBAction func backToMainMenu(segue: UIStoryboardSegue){
        print("here?!")
        //open = true
        
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (open) {
            open = false
            present(imagePicker, animated: false, completion: nil)
        }
        //self.navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func takePicture(_ sender: Any) {
        // TODO: handle case where no given access
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            let alertController = UIAlertController.init(title: nil, message: "No available camera.", preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func choosePictureFromLibrary(_ sender: Any) {
        //imagePicker.modalPresentationStyle = .overCurrentContext
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // The info dictionary may contain multiple representations of the image. You want to use the original.
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
    
        
//        let group = DispatchGroup()
//        group.enter()
//
//        DispatchQueue.main.async( execute: {
//            self.performSegue(withIdentifier: "imageChosen", sender: self)
//            group.leave()
//        })
//
//
//        group.notify(queue: .main) {
//            self.dismiss(animated: true, completion: nil)
//        }
//
        
        
        // Dismiss the picker.
        dismiss(animated: false, completion: {() in self.performSegue(withIdentifier: "imageChosen", sender: self)})
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
