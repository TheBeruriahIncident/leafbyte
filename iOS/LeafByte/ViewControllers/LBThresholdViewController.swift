//
//  LBThresholdViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class LBThresholdViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    var image: UIImage?
    let filter = ThresholdFilter()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.9;
        scrollView.maximumZoomScale = 3.0
        
        filter.inputImage = CIImage(image: image!)
        
        imageView.contentMode = .scaleAspectFit

        // TODO: use otsu's method for better initial threshold
        setValue(threshold: 0.95)
    }
    
    func setValue(threshold: Float) {
        filter.threshold = threshold
        slider.value = 1 - threshold
        
        imageView.image = convert(cmage: filter.outputImage)
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    @IBAction func backFromThreshold(_ sender: Any) {
        self.performSegue(withIdentifier: "backToMainMenu", sender: self)
    }
    
    @IBAction func fromMainMenu(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? LBMainMenuViewController, let image = sourceViewController.image {
            
            imageView.image = image
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        setValue(threshold: 1 - sender.value)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "thresholdSet"
        {
            guard let destination = segue.destination as? LBFillHolesViewController else {
                return
            }
            
            destination.baseImage = imageView.image
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imageView: UIImageView!
}
