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

1.4.0 (??? ??, 2024, the big 2024 refresh!) (Unreleased)
* The app code has been broadly refreshed and updated to ensure that everything is 2024-compliant and continues working given changes being made by both Apple and Google
* The image selector is now more modern and allows search and zooming in and out of the image list.
* Google Sign-In specifically has been updated to get the minimal possible set of permissions to users' Google Drives (previously Google was granting several permissions we weren't even asking for, so we've rewritten the whole login to avoid that) 
* An issue has been fixed where on newer iOS versions, choosing to take a picture after having removed camera access in the settings would crash instead of displaying an error
* In a specific situation where saving data to Google Drive crashed, the error is now properly shown
* Text during barcode scanning (e.g. previews of what you scanned) is now easier to read
* Various typos are fixed
* Fix potential brief unresponsiveness when initiating barcode scanning
* Thresholding may be slightly faster now that it is rewritten to use the modern Metal language
* In a rare situation where the image chosen in the image picker cannot be loaded, fail gracefully rather than crashing. (This has never been reported to us, and only appears in one crash report, so we don't know when this can actually happen)
* If the barcode scanner is used on a device with no camera, fail gracefully rather than crashing. (We don't know if this can actually ever happen)
* In rare situations where iOS cannot process your chosen image, fail gracefully rather than crashing. (This appears in a crash report, but we don't know the conditions where this actually happens)
* Prevent crashing in an extremely rare (perhaps theoretical) situation where the memory is affected in an odd way while the thresholding screen is prepared
* Prevent crashing in a rare situation where the phone is particularly busy as a new screen finishes sliding out
* Prevent crashing in a rare situation where you manage to return to home while the app is already returning to home
* Fail gracefully rather than crashing when saving a corrupt image that cannot be converted into a png (This appears in a crash report, but we don't know the conditions where this actually happens)
* Fail gracefully rather than crashing when failing to save a file to the Files App (This appears in a crash report, but we don't know the conditions where this actually happens; perhaps no disk space?)
* Prevent crashing when linking to the LeafByte website on very slow internet
* Credit collaborators on the settings page. Make the settings page size correctly across different devices
* More precisely determine the center of oddly-shaped scale marks (previously was only up to about a pixel off)
* Make FAQs and error reporting more obvious on main page
