//
//  SegueFromRight.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class SegueFromRight: UIStoryboardSegue {
    override func perform() {
        let source = self.source
        let destination = self.destination
        
        source.view.superview?.insertSubview(destination.view, aboveSubview: source.view)
        destination.view.transform = CGAffineTransform.init(translationX: source.view.frame.size.width, y: 0)
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: [],
            animations: {
                destination.view.transform = CGAffineTransform.init(translationX: 0, y:0)
            },
            completion: { finished in
                source.present(destination, animated: false, completion: nil)
            }
        )
    }
}
