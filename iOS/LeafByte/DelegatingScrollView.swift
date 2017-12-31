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
        if (self.isDragging) {
            super.touchesBegan(touches, with: event)
        }
        
        self.next?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isDragging) {
            super.touchesMoved(touches, with: event)
        }
        
        self.next?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.isDragging) {
            super.touchesEnded(touches, with: event)
        }
        
        self.next?.touchesEnded(touches, with: event)
    }
}
