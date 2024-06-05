Things we are avoiding changing to avoid the risk of regressions:
* The UI uses UIKit. SwiftUI now exists and is preferred.
* We are keeping the minimum SDK at 9 for now since we have had known users with old devices.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client.
* We are on Google Sign-In version 5.0.2. Version 7.0.0 requires us to raise our minimum SDK to 11, so we're not taking that. We could upgrade to 6.2.4, but 6.x.x rewrites the API and would require us to restructure our code for no benefit. (See https://developers.google.com/identity/sign-in/ios/release for the release notes; 6.x.x has nothing relevant to our usage)
* There is now a Google Sign-In package with first-class Swift support, but that requires upgrading to 6.x.x.
* Dependencies are handled through CocoaPods. Swift Package Manager now exists and is preferred, but Google Sign-In doesn't work with SPM until 6.x.x.

