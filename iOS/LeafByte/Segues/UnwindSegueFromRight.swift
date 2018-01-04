//
//  UnwindSegueFromRight.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/23/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class UnwindSegueFromRight: UIStoryboardSegue {
    override func perform() {
        let source = self.source
        let destination = self.destination
        
        source.view.superview?.insertSubview(destination.view, belowSubview: source.view)
        source.view.transform = CGAffineTransform.init(translationX: 0, y: 0)
        
        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: [],
            animations: {
                source.view.transform = CGAffineTransform.init(translationX: source.view.frame.size.width, y: 0)
            },
            completion: { finished in
                source.dismiss(animated: false, completion: nil)
            }
        )
    }
}
