//
//  PHPickerPresentationControllerDelegate.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 8/25/24.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import Foundation
import UIKit

// This delegate is its own class rather than using the relevant view controller itself to avoid conflict with any other dismissed presentation, e.g. the tutorial popover
class PHPickerPresentationControllerDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
    // Unowned so this doesn't cause a memory cycle if the parent is dismissed
    unowned let viewController: UIViewController

    init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // When the PHPicker is canceled with the cancel button, the picker's completion callback is run. However, it is not run when the picker is canceled by swiping (this inconsistency feels like an iOS bug), so we work around by using this method to see if the PHPicker was canceled with a swipe.
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        dismissNavigationController(self: viewController)
    }
}
