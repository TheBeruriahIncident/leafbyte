//
//  SegueFromRight.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 12/23/17.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import UIKit

// This allows views to transition from the right side over the current view.
final class SegueFromRight: UIStoryboardSegue {
    // MARK: UIStoryboardSegue overrides

    override func perform() {
        let source = self.source
        let destination = self.destination

        source.view.superview?.insertSubview(destination.view, aboveSubview: source.view)
        destination.view.transform = CGAffineTransform(translationX: source.view.frame.size.width, y: 0)

        UIView.animate(
            withDuration: 0.25,
            delay: 0.0,
            options: [],
            animations: {
                destination.view.transform = CGAffineTransform(translationX: 0, y:0)
            },
            completion: { finished in
                // This proooobably is already the main thread, but it's not in the contract, so let's just be sure
                DispatchQueue.main.async {
                    source.present(destination, animated: false, completion: nil)
                }
            }
        )
    }
}
