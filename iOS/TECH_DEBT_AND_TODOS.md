Tech debt and things resembling tech debt that we are avoiding changing to avoid the risk of regressions:
* The UI uses UIKit. SwiftUI now exists and is preferred.
* We are keeping the minimum SDK at 9 for now since we have had known users with old devices.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client. However, Google's wire APIs tend to be much stabler than their (often buggy) client libraries, so using our own wrapper may unfortunately be the most reliable option.
* We are using bare-metal AppAuth rather than the Google Sign-In library. We actually originally used the Google Sign-In library, but it's janky and buggy, constantly breaks its API, always requests more access than we need (and the devs won't accept a contribution to allow being more thoughtful about privacy), and requires a higher minimum SDK than we're currently accepting.
* We're using CocoaPods for dependencies. The first-class Swift Package Manager now exists and is preferred, and it would be nice to not check in the sources of our AppAuth dependency. However, Swift Package Manager forces packages to have a minimum dependency at the lowest SDK Apple currently recommends, even if the package supports lower and declares that it supports lower. As such, it clashes with our choice to support clients with older devices.
* We cannot use Dependabot to automatically keep our dependencies up to date until we move from CocoaPods to Swift Dependency Manager.
* NSCoding was the preferred serialization method when LeafByte was originally written. It's now deprecated (with no plans to actually remove it), and Codable is preferred, except there isn't a clear migration path between the two or migration tooling on iOS. Thus, we'd have to be able to read from NSCoding and Codable and only write back to Codable. We could never be sure that all NSCoding data was gone, so we'd have to leave these two paths indefinitely. As such, switching to Codable would add indefinite complexity with little benefit and not even ever remove the deprecated usage.
* The legacy UIImagePickerController required us to request "Privacy - Photo Library Usage" in the plist, while the modern PHPicker runs in a separate process and thus does not require LeafByte to request additional access. We use PHPicker if the device is iOS 14 and thus PHPicker is available, and otherwise fallback on UIImagePickerController. As such, we'd ideally drop that privacy request from the plist in newer iOS versions, but that's not possible. Once our minimum SDK is at least 14, we can delete UIImagePickerController and the privacy request.

Immediate TODOs:
* Add the experimental images from the paper as test cases with margin for error
* Figure why paper data doesn't match leafbyte now, why different devices are different, and why 1.0.0 to 1.1.0 changes (probably start with different devices)
* switch tutorial image to png, comment that jpg loads differently, and make test more flexible; also document that planar homography varies
* Excluding data doesn't work now
* why does topMostMemberPoint change the results
* actually canceling the save-and-next image picker doesnt take you to the main menu
* When dismissing a view back to the main menu, the title bar elements stay for a moment before disappearing
* Test if Metal thresholding is slower, particularly on simulator that is slower
* Check for regressions: Save and next seems weirdly slow. Seeing white when you rotate barcode. Flick when you save and next. 
* When ready for 1.4.0 release, update version in settings, put on test flight, extensively test, and run with debugger watching for errors. extensively test on oldest sdk as well

Lower priority TODOs:
* Proper localization (Probably to Spanish and Chinese in the short term). Much of the groundwork was done (although maybe string catalogs are the current approach), but the Spanish translations were much longer than the English, so we have to make the constraints a bit more flexible to keep the app looking right. Note two relevant disable lint rules.
* Work with multiple leaves. We need to figure how to do this in a way that keeps that app speedy and the UI simple. There's also concern about this reducing accuracy as you'll be zoomed out more.
* Related to the above, consider upping the resolution, perhaps even dynamically based on phone speed. Related: Check if ciToCgImage is faster with CPU rendering https://stackoverflow.com/questions/14402413/getting-a-cgimage-from-ciimage . Note that this may be less accurate, and if so, we may not want to use this regardless

Known bugs to figure out and fix:
* One person has reported crashing when saving to the Files App, and many crash reports show crashing within saveAndNext/handleSerialization. The crash reports give minimal details (not even a line number). We can't figure what would cause this and are attempting to gather more data.
