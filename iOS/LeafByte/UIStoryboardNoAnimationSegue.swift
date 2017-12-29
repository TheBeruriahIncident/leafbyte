//
//  UIStoryboardNoAnimationSegue.swift
//  LeafByte
//
//  Created by Adam Campbell on 12/25/17.
//  Copyright © 2017 The Blue Folder Project. All rights reserved.
//

import UIKit

/*
 Move to the next screen without an animation.
 */
class UIStoryboardNoAnimationSegue: UIStoryboardSegue {
    
    override func perform() {
        self.source.navigationController?.pushViewController(self.destination, animated: false)
    }
}
