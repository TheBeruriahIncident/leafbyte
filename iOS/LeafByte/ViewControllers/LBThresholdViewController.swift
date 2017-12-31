//
//  LBThresholdViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit
import Accelerate

class LBThresholdViewController: UIViewController, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    var image: UIImage?
    let filter = ThresholdFilter()
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let threshold = otsu(forHistogram: getHistogram())
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.9;
        scrollView.maximumZoomScale = 10.0
        
        filter.inputImage = CIImage(image: image!)
        
        imageView.contentMode = .scaleAspectFit

        setValue(threshold: threshold)
    }
    
    func otsu(forHistogram histogram: [UInt]) -> Float {
        return 0.95
    }
    
    func getHistogram() -> [UInt] {
        let img: CGImage = image!.cgImage!
        
        //create vImage_Buffer with data from CGImageRef
        let inProvider: CGDataProvider = img.dataProvider!
        let inBitmapData: CFData = inProvider.data!
        
        var inBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: CFDataGetBytePtr(inBitmapData)), height: vImagePixelCount(img.height), width: vImagePixelCount(img.width), rowBytes: img.bytesPerRow)
        
        let alpha = [UInt](repeating: 0, count: 256)
        let red = [UInt](repeating: 0, count: 256)
        let green = [UInt](repeating: 0, count: 256)
        let blue = [UInt](repeating: 0, count: 256)
        
        let alphaPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: alpha) as UnsafeMutablePointer<vImagePixelCount>?
        let redPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: red) as UnsafeMutablePointer<vImagePixelCount>?
        let greenPtr = UnsafeMutablePointer<vImagePixelCount>(mutating: green) as UnsafeMutablePointer<vImagePixelCount>?
        let bluePtr = UnsafeMutablePointer<vImagePixelCount>(mutating: blue) as UnsafeMutablePointer<vImagePixelCount>?
        
        let rgba = [redPtr, greenPtr, bluePtr, alphaPtr]
        
        let histogram = UnsafeMutablePointer<UnsafeMutablePointer<vImagePixelCount>?>(mutating: rgba)
        let error = vImageHistogramCalculation_ARGB8888(&inBuffer, histogram, UInt32(kvImageNoFlags))
        
        // TODO: this memory management makes me nervous, have I allocated anything?
        
        let total = zip(red, zip(green, blue)).map { $0 + $1.0 + $1.1 }
        return total
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
