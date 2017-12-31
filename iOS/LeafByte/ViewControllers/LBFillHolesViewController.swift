//
//  LBFillHolesViewController.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/24/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import CoreGraphics
import UIKit

class LBFillHolesViewController: UIViewController {
    
    var baseImage: UIImage?
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        baseImageView.image = baseImage
        baseImageView.contentMode = .scaleAspectFit
    }
    
    @IBOutlet weak var baseImageView: UIImageView!
    @IBOutlet weak var drawingImageView: UIImageView!
    
    var swiped = false
    var lastPoint = CGPoint.zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        lastPoint = (touches.first?.location(in: drawingImageView))!
    }
    
    func drawLineFrom(fromPoint: CGPoint, toPoint: CGPoint) {
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
}
