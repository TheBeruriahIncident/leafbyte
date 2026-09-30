Tech debt we may be able to improve now:
* The legacy UIImagePickerController required us to request "Privacy - Photo Library Usage" in the plist, while the modern PHPicker runs in a separate process and thus does not require LeafByte to request additional access. We use PHPicker if the device is iOS 14 and thus PHPicker is available, and otherwise fallback on UIImagePickerController. As such, we'd ideally drop that privacy request from the plist in newer iOS versions, but that's not possible. Once our minimum SDK is at least 14, we can delete UIImagePickerController and the privacy request.
* Can we now use the thread safety system?

Tech debt that we can improve in the future:
* Once our minimum iOS version is 18, we can remove our extension to CGPoint to conform to Hashable.

Tech debt and things resembling tech debt that we don't anticipate changing:
* The UI uses UIKit. SwiftUI now exists and is preferred. It's not currently worth the effort and regression risk of a rewrite.
* No Google Drive/Sheets API client existed on iOS at the time of original writing, so we wrote our own wrapper around pure REST. There is now an available client. However, Google's wire APIs tend to be much stabler than their (often buggy) client libraries, so using our own wrapper may unfortunately be the most reliable option.
* We are using bare-metal AppAuth rather than the Google Sign-In library. We actually originally used the Google Sign-In library, but it's janky and buggy, constantly breaks its API, always requests more access than we need (and the devs won't accept a contribution to allow being more thoughtful about privacy), and requires a higher minimum SDK than we're currently accepting.
* NSCoding was the preferred serialization method when LeafByte was originally written. Codable is now preferred. To migrate though, we'd have to be able to read from both NSCoding and Codable and only write back to Codable. We could never be sure that all NSCoding data in the world was gone, so we'd have to leave these two paths indefinitely. As such, switching to Codable would add complexity with little benefit and not even ever remove the deprecated usage. Since NSCoding is still supported (now that NSSecureCoding exists), we're not bothering adding Codable.
