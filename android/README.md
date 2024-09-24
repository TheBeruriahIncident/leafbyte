# LeafByte on Android

In development.

Android Studio is the recommended development environment.
Open the android folder in Android Studio.
You'll need to install the development kit (NDK) within Android Studio.
You should then be able to run the app in a simulator.

In order to be able to publish releases, you must add a keystore.
You can follow [Google's guide](https://developer.android.com/studio/publish/app-signing#generate-key) or manually run `keytool -genkey -v -keystore keystore.p12 -alias LeafByte -keyalg RSA -keysize 3072 -validity 365000`.
To see your created keystore, run `keytool -keystore .\keystore.p12 -v -list`.

Some useful commands:
- `./gradlew useLatestVersions` to update dependencies
- `./gradlew buildHealth` to check for dependency issues
- `./gradlew ktlintFormat` to check for ktlint issues and auto-format
- `./gradlew detekt` to check for detekt issues
