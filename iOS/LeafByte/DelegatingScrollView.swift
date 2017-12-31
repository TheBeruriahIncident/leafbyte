//
//  DelegatingScrollView.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/31/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

class DelegatingScrollView: UIScrollView {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isScrollEnabled) {
            super.touchesBegan(touches, with: event)
        }
        
        self.next?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print ("touchesMoved")
        if (self.isScrollEnabled) {
            super.touchesMoved(touches, with: event)
        }
        
        print ("delegating to " + String(describing: type(of: self.next!)))
        self.next?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isScrollEnabled) {
            super.touchesEnded(touches, with: event)
        }
        
        self.next?.touchesEnded(touches, with: event)
    }
}
