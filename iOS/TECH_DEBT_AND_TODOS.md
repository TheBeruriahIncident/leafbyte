Tech debt and things resembling tech debt that we are avoiding changing to avoid the risk of regressions:
* The UI uses UIKit. SwiftUI now exists and is preferred.
* We are keeping the minimum SDK at 9 for now since we have had known users with old devices.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client.
* We are using bare-metal AppAuth rather than the Google Sign-In library. We actually originally used the Google Sign-In library, but it's janky and buggy, always requests more access than we need (and the devs refuse to accept a contribution to be more thoughtful about privacy), and requires a higher minimum SDK than we're currently accepting.

Smaller things that would be good to do:
* Switch from CocoaPods to Swift Package Manager.

Bigger things that would be good to do:
* Proper localization (Probably to Spanish and Chinese in the short term). Much of the groundwork was done (although maybe string catalogs are the current approach), but the Spanish translations were much longer than the English, so we have to make the constraints a bit more flexible to keep the app looking right.
* Work with multiple leaves. We need to figure how to do this in a way that keeps that app speedy and the UI simple. There's also concern about this reducing accuracy as you'll be zoomed out more.

Known bugs to figure out and fix:
* One person has reported crashing when saving to the Files App, and many crash reports show this. We are attempting to gather more data
