Tech debt and things resembling tech debt that we are avoiding changing right now:
* We are keeping the minimum SDK at 9 for now, since we have had known users with old devices. Labs sometimes buy specific devices for lab work, and we don't want to break existing workflows.
* The UI uses UIKit. SwiftUI now exists and is preferred. It's not currently worth the effort and regression risk of a rewrite.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client. However, Google's wire APIs tend to be much stabler than their (often buggy) client libraries, so using our own wrapper may unfortunately be the most reliable option.
* We are using bare-metal AppAuth rather than the Google Sign-In library. We actually originally used the Google Sign-In library, but it's janky and buggy, constantly breaks its API, always requests more access than we need (and the devs won't accept a contribution to allow being more thoughtful about privacy), and requires a higher minimum SDK than we're currently accepting.
* We're using CocoaPods for dependencies. The first-class Swift Package Manager now exists and is preferred, and it would be nice to not check in the sources of our dependencies. However, Swift Package Manager currently forces packages to have a minimum dependency at the lowest SDK Apple currently recommends, even if the package supports lower and declares that it supports lower. As such, it clashes with our choice to support clients with older devices.
* We cannot use Dependabot to automatically keep our dependencies up to date until we move from CocoaPods to Swift Dependency Manager.
* NSCoding was the preferred serialization method when LeafByte was originally written. It's now deprecated (with no plans to actually remove it), and Codable is preferred, except there isn't a clear migration path between the two or migration tooling on iOS. Thus, we'd have to be able to read from NSCoding and Codable and only write back to Codable. We could never be sure that all NSCoding data was gone, so we'd have to leave these two paths indefinitely. As such, switching to Codable would add indefinite complexity with little benefit and not even ever remove the deprecated usage.
* The legacy UIImagePickerController required us to request "Privacy - Photo Library Usage" in the plist, while the modern PHPicker runs in a separate process and thus does not require LeafByte to request additional access. We use PHPicker if the device is iOS 14 and thus PHPicker is available, and otherwise fallback on UIImagePickerController. As such, we'd ideally drop that privacy request from the plist in newer iOS versions, but that's not possible. Once our minimum SDK is at least 14, we can delete UIImagePickerController and the privacy request.
* SwiftLint is stuck on 0.51.0, because newer versions require a higher SDK. However, our CI runs latest SwiftLint.

Immediate TODOs:
* Add the experimental images from the paper as test cases with margin for error (make sure matches paper data), pending finding the images
* Consider upping the resolution, perhaps based on phone model, pending testing with higher resolutions
* When dismissing a view back to the main menu, the title bar elements stay for a moment before disappearing
* Test if Metal thresholding is slower, particularly on simulator that is slower
* Check for regressions: Save and next seems weirdly slow. Seeing white when you rotate barcode. Flick when you save and next.
* Polish release notes and put on the website
* When ready for 1.4.0 release, update version in settings, put on test flight, extensively test, and run with debugger watching for errors. extensively test on oldest sdk as well
