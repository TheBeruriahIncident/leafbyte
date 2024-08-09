//
//  TutorialViewController.swift
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 2/7/18.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

import UIKit

final class TutorialViewController: UIViewController {
    // MARK: - Fields

    // These are passed from the previous view.
    // swiftlint:disable implicitly_unwrapped_optional
    var settings: Settings!
    // swiftlint:enable implicitly_unwrapped_optional

    // MARK: - Outlets

    @IBOutlet weak var tutorialSection6: UITextView!

    // MARK: - Actions

    @IBAction func goHome(_: Any) {
        dismissNavigationController(self: self)
    }

    // MARK: - UIViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        let linkedString = NSMutableAttributedString(attributedString: tutorialSection6.attributedText).addLink(text: "the website", url: "https://zoegp.science/leafbyte-faqs")
        tutorialSection6.attributedText = linkedString

        smoothTransitions(self: self)
    }

    // This is called before transitioning from this view to another view.
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // If the segue is continueTutorial, we're transitioning forward in the main flow, and we need to pass our data forward.
        if segue.identifier == "continueTutorial" {
            guard let destination = segue.destination as? BackgroundRemovalViewController else {
                fatalError("Expected the next view to be the thresholding view but is \(segue.destination)")
            }

            destination.settings = settings
            destination.sourceMode = .photoLibrary
            // swiftlint:disable:next force_unwrapping
            destination.image = resizeImage(#imageLiteral(resourceName: "Example Image"))!
            destination.inTutorial = true

            setBackButton(self: self, next: destination)
        }
    }
}
