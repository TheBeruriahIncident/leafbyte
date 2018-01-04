//
//  MainMenuViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/20/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import AVFoundation
import UIKit

class MainMenuViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    @IBAction func backToMainMenu(segue: UIStoryboardSegue){}

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.setAnimationsEnabled(true)
    }
    
    @IBAction func takePicture(_ sender: Any) {
        // TODO: handle case where no given access
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            let alertController = UIAlertController.init(title: nil, message: "No available camera", preferredStyle: .alert)
            
            let okAction = UIAlertAction.init(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
            })
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                self.sourceType = .camera
                self.imagePicker.sourceType = .camera
                self.present(self.imagePicker, animated: true, completion: nil)
            } else {
                let alertController = UIAlertController.init(title: "Camera access denied", message: "To allow taking photos for analysis, go to Settings -> Privacy -> Camera and set LeafByte to ON.", preferredStyle: .alert)
                
                let okAction = UIAlertAction.init(title: "OK", style: .default, handler: {(alert: UIAlertAction!) in
                })
                
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                return
            }
        }
    }
    
    var sourceType: UIImagePickerControllerSourceType?
    
    @IBAction func choosePictureFromLibrary(_ sender: Any) {
        //imagePicker.modalPresentationStyle = .overCurrentContext
        sourceType = .photoLibrary
        
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    var selectedImage: UIImage?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "imageChosen"
        {
            guard let navController = segue.destination as? UINavigationController else {
                print(type(of: segue.destination))
                return
                //fatalError("Expected a seque from the main menu to threshold but instead went to: \(segue.destination)")
            }
            
            guard let destination = navController.topViewController as? ThresholdingViewController else {
                return
            }
            
            destination.image = selectedImage!
            destination.sourceType = sourceType
        }
    }

    // MARK: - UIImagePickerControllerDelegate overrides
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // There may contain multiple versions of the image in info; since we're allowing editing, we want the edited image.
        // Even if the user doesn't edit, this will retrieve the unedited image.
        guard let selectedImage = info[UIImagePickerControllerEditedImage] as? UIImage else {
            fatalError("Expected to find an image under UIImagePickerControllerEditedImage in \(info)")
        }
    
        // TODO: resize the image
        self.selectedImage = selectedImage
        
        dismiss(animated: false, completion: {() in
            // Dismissing and then seguing goes from the image picker to the main menu view to the threshold view.
            // It looks weird to be back at the main menu, so make this transition as short as possible by disabling animation.
            // Animation is re-renabled in this class's viewDidDisappear.
            UIView.setAnimationsEnabled(false)
            self.performSegue(withIdentifier: "imageChosen", sender: self)
        })
    }
    
    // If the image picker is canceled, dismiss it.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
