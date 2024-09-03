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

1.4.0 (Sept ???, 2024, the big 2024 refresh!) (Unreleased)
* The app code has been broadly refreshed and updated to ensure that everything is 2024-compliant and continues working given changes being made by both Apple and Google
* The image selector is now more modern and allows search and zooming in and out of the image list.
* Google Sign-In specifically has been updated to get the minimal possible set of permissions to users' Google Drives (previously Google was granting several permissions LeafByte wasn't even asking for, so we've rewritten the whole login to avoid that) 
* Thresholding may be slightly faster now that it is rewritten to use the modern Metal language
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
    * When saving a corrupt image that cannot be converted into a png (this appears once in a crash report, but we don't know the conditions where this actually happens)
    * When failing to save a file to the Files App (this appears once in a crash report, but we don't know the conditions where this actually happens; perhaps if the disk is full?)
    * When the image chosen in the image picker cannot be loaded (this appears once in a crash report, but we don't know the conditions where this actually happens)
    * When iOS itself cannot process your chosen image (this appears once in a crash report, but we don't know the conditions where this actually happens)
    * When saving data to Google Drive crashes due to malformed responses from Google (this is maybe just theoretical)
    * When the barcode scanner is used on a device with no camera (this is maybe just theoretical)
* Various typos are fixed
