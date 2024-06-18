# LeafByte on iOS

Xcode is the recommended development environment.
Open iOS/LeafByte.xcworkspace in Xcode to begin work.

Before the app can run properly, you must fill in the the GOOGLE_SIGN_IN_CLIENT_ID and GOOGLE_SIGN_IN_REDIRECT_URL in iOS/LeafByte/Secrets.xcconfig .
First, run `git update-index --assume-unchanged iOS/LeafByte/Secrets.xcconfig` to prevent checking in any secrets.
If you're part of the core LeafByte development team, replace the whole file with the version from leafbyte.app@gmail.com's Google Drive.
If you're an outside contributor (welcome! 😊), you can generate an iOS-type client id using [Google's guide](https://support.google.com/cloud/answer/6158849?hl=en) .
Pull out the appropriate section of the client id to replace FILL_ME_IN.
The boilerplate parts of the client id are already filled in.
Note that the client id is reversed in the redirect url, but you can follow the example and just replace FILL_ME_IN.
If you run into any issues, reach out to <leafbyte@zoegp.science>, and we'd be happy to help!

You should then be able to run the app in a simulator.
If you want to run the app on a real device, after connecting your device and choosing it from the device dropdown, open the top-level LeafByte item.
Under the General tab, choose a valid "Team" (such as your Apple account), associate your device with your account if asked, and accept any messages on your device or computer to allow the connection.

LeafByte uses CocoaPods to manage dependencies (specifically for AppAuth to enable Google Sign-In), but you shouldn't have to worry about that unless you're adding a new dependency. See TECH_DEBT_AND_TODOS.md for context on the use of CocoaPods.
