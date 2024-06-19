Tech debt and things resembling tech debt that we are avoiding changing to avoid the risk of regressions:
* The UI uses UIKit. SwiftUI now exists and is preferred.
* We are keeping the minimum SDK at 9 for now since we have had known users with old devices.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client. However, Google's wire APIs tend to be much stabler than their (often buggy) client libraries, so using our own wrapper may unfortunately be the most reliable option.
* We are using bare-metal AppAuth rather than the Google Sign-In library. We actually originally used the Google Sign-In library, but it's janky and buggy, constantly breaks its API, always requests more access than we need (and the devs won't accept a contribution to allow being more thoughtful about privacy), and requires a higher minimum SDK than we're currently accepting.
* We're using CocoaPods for dependencies. The first-class Swift Package Manager now exists and is preferred, and it would be nice to not check in the sources of our AppAuth dependency. However, Swift Package Manager forces packages to have a minimum dependency at the lowest SDK Apple currently recommends, even if the package supports lower and declares that it supports lower. As such, it clashes with our choice to support clients with older devices.
* We cannot use Dependabot to automatically keep our dependencies up to date until we move from CocoaPods to Swift Dependency Manager.

Immediate TODOs:
* Make app loudly complain on startup if client id and redirect are not filled in
* Can we resolve or ignore all warnings?
* Proof Google Sign In error messages with Zoe
* Fix weird spacing at the bottom of the tutorial page on newer devices
* Fix the unsafe pointer init warnings
* Make sure memory leak/closure semantics are correct around self, escaping, and weak refs
* Add the experimental images from the paper as test cases
* Check if ciToCgImage is faster with CPU rendering https://stackoverflow.com/questions/14402413/getting-a-cgimage-from-ciimage . Note that this may be less accurate, and if so, we may not want to use this regardless
* Add credits to settings, aligning across iOS, Android, and website
* Investigate all crashes in Crash Organizer
* Check Memory Graph tool and Leaks instrument for any memory leaks
* When ready for 1.4.0 release, update version in settings, put on test flight, extensively test, and run with debugger watching for errors

Lower priority TODOs:
* Proper localization (Probably to Spanish and Chinese in the short term). Much of the groundwork was done (although maybe string catalogs are the current approach), but the Spanish translations were much longer than the English, so we have to make the constraints a bit more flexible to keep the app looking right.
* Work with multiple leaves. We need to figure how to do this in a way that keeps that app speedy and the UI simple. There's also concern about this reducing accuracy as you'll be zoomed out more.
* Switch from the older UIImagePicker to the newer PHPicker
* Add SwiftLint (locally and GitHub action)
* Add static analysis (locally and GitHub action)

Known bugs to figure out and fix:
* One person has reported crashing when saving to the Files App, and many crash reports show crashing within saveAndNext. The crash reports give minimal details (not even a line number). We can't figure what would cause this and are attempting to gather more data.
