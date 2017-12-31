//
//  LBFillHolesViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class LBFillHolesViewController: UIViewController, UIScrollViewDelegate {
    
    var baseImage: UIImage?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0;
        scrollView.maximumZoomScale = 3.0
        
        baseImageView.image = baseImage
        baseImageView.contentMode = .scaleAspectFit
        setScrolling(true)
    }
    
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return wrapper
    }
    
    var swiped = false
    var lastPoint = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        lastPoint = (touches.first?.location(in: drawingImageView))!
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
        if (isScrolling) {
            return
        }
        //print("drawing " + String(describing: fromPoint) + " to " + String(describing: toPoint))
        
        UIGraphicsBeginImageContext(drawingImageView.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        drawingImageView.image?.draw(in: CGRect(x: 0, y: 0, width: drawingImageView.frame.size.width, height: drawingImageView.frame.size.height))
        
        context!.move(to: fromPoint)
        context!.addLine(to: toPoint)
        context!.strokePath()
        
        drawingImageView.image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        let currentPoint = touches.first?.location(in: drawingImageView)
        drawLineFrom(fromPoint: lastPoint, toPoint: currentPoint!)
        
        lastPoint = currentPoint!
        
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            drawLineFrom(fromPoint: lastPoint, toPoint: lastPoint)
        }
    }
    
    func setScrolling(_ scrolling: Bool) {
        isScrolling = scrolling
        
        scrollView.isUserInteractionEnabled = scrolling
        
        
        if (scrolling) {
            button.setTitle("Switch to drawing", for: .normal)
        } else {
            button.setTitle("Switch to scrolling", for: .normal)
        }
    }
    
    var isScrolling = true
    
    @IBAction func touchButton(_ sender: Any) {
            setScrolling(!isScrolling)
    }
    
    @IBOutlet weak var wrapper: UIView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
}
