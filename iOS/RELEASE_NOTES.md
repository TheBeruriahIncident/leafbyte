1.0.0 (Nov 6, 2018)
* Original release

1.1.0 (Jan 2, 2019)
* Scale length is now recorded in data sheets
* No more accidentally swiping back from the drawing page
* Leaf marker is now drawn at the top of the leaf to avoid covering anything
* Undo now uses less memory (relevant on iPhone 5 and before)

1.2.0 (June 19, 2019)
* Greater zoom is now supported (previously the maximum zoom was 10x; now it's 50x)
* Finding scale marks after user selection is now faster (helpful on older devices)
* Sufficiently large objects are ignored during manual scale selection, as they're unlikely to be the scale, and they take a long time to process on older devices

1.3.0 (Oct 9, 2019)
* When data is added to Google Sheets, numbers are properly recognized as numbers
* When Google Sheets are created, headers are frozen
* The "Back" button is now more accurately labeled "Save" on the Settings page

1.4.0 (Sept 5, 2024, the big 2024 refresh!)
* The app code has been broadly refreshed and updated to ensure that everything is 2024-compliant and continues working given changes being made by both Apple and Google
* Starting on August 19, 2024, due to changes by Google, Google sign-in stopped working, although existing logins could continue to be used. This version makes Google sign-in work again.
* LeafByte no longer uses increasing amounts of memory the longer you use it, which previously led to crashes every few hundred images.
* The image selector is now more modern and allows search and zooming in and out of the image list.
* Google Sign-In specifically has been updated to get the minimal possible set of permissions to users' Google Drives (previously Google was granting several permissions LeafByte wasn't even asking for, so we've rewritten the whole login to avoid that) 
* Thresholding may be slightly faster now that it is rewritten to use the modern Metal language
* A black background is put behind thresholded images when processing images with a black background. Previously these images were thresholded to result in white samples on a white background, which was difficult to work with.
* Text during barcode scanning (e.g. previews of what you scanned) is now easier to read
* Potential very brief unresponsiveness when initiating barcode scanning is removed
* FAQs and error reporting are more obvious on the home page
* The settings page is now sized correctly across different devices, and it now credits LeafByte collaborators
* LeafByte more precisely determines the center of oddly-shaped scale marks (it previously could be up to about a pixel off)
* In some rare situations that previously may have crashed, LeafByte no longer crashes: 
    * When linking to the LeafByte website on extremely slow internet
    * When the phone is particularly busy as a new screen finishes sliding out (extremely rare)
    * When you manage to return to the home screen while the app is already returning to the home screen (extremely rare)    
    * When the memory is affected in an odd way while the thresholding screen is prepared (extremely rare and perhaps theoretical)
* For several rare problematic cases, LeafByte now shows an error message rather than just crashing: 
    * When using LeafByte with camera access on a newer iOS version, then going to settings and removing camera access, then trying to take a picture in LeafByte 
    * When saving a corrupt image that cannot be converted into a png (this appears once in a crash report without clear cause)
    * When failing to save a file to the Files App (this appears once in a crash report without clear cause; perhaps the disk was full?)
    * When the image chosen in the image picker cannot be loaded (this appears once in a crash report without clear cause)
    * When iOS itself cannot process your chosen image (this appears once in a crash report without clear cause)
    * When saving data to Google Drive crashes due to malformed data from Google (this is maybe just theoretical)
    * When the barcode scanner is used on a device with no camera (this is maybe just theoretical)
* Various typos are fixed

1.5.0 (???, the big 2026 refresh!)
* After 8 years, our minimum iOS version has been raised from iOS 9 to iOS 15 due to requirements from Apple. We are no longer allowed to publish the app with less than an iOS 15 requirement, even though we are able to support iOS 9 and would like to support iOS 9. We know this affects existing lab devices, and we apologize.
* We've moved to modern, safer image processing calls, which we hope will fix some rare stubborn errors on saving.
* We've used a modern call to fix a (probably completely theoretical) vulnerability when deserializing settings.
* We've removed lots of legacy codepaths throughout the app that supported older iOS versions, making the app easier to maintain and more friendly to external contributors.
* TODO: We've made numbers properly localize. Instead of always presenting in the style 1,234.56, we use the locale of the phone. For example, if your phone is set to German or Georgian, you should see 1.234,56 (and you should be able to also enter numbers using your locale's format).
* TODO: Make tutorial sensible regardless of setting https://github.com/TheBeruriahIncident/leafbyte/issues/513
* TODO: Affordance that sample number is editable https://github.com/TheBeruriahIncident/leafbyte/issues/478
* TODO: fix sylvia's bug
* TODO: fix logged crashes (especially the one with multiple)
* TODO: fix extraneous privacy requests. remove photo library and anything else
* TODO: fix icon colors on new devices/simulators
* TODO: disable swiping while drawing

1.?.?
* Scope all settings to dataset name (maybe move to Codeable?)
* Generally match any changes made in Android
* Loading screen https://github.com/TheBeruriahIncident/leafbyte/issues/452
* iOS settings behavior when not saving https://github.com/TheBeruriahIncident/leafbyte/issues/63
* iOS app check https://github.com/TheBeruriahIncident/leafbyte/issues/37
* improve rotation https://github.com/TheBeruriahIncident/leafbyte/issues/23
* actors for thread safety
