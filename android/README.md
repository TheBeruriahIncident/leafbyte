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
- `./gradlew check` runs all non-instrumented checks
- `./gradlew connectedCheck` runs all instrumented checks

Regarding code coverage reports:
- To check coverage from unit tests, run `./gradlew jacocoTestReport` and find the report at `- app/build/outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec`
- To check coverage from instrumented tests, run `./gradlew connectedCheck` and find the report at `- app/build/reports/coverage/androidTest/debug/connected/report.xml`
- Either file can be opened in Android Studio with "Import External Coverage Report..."
- It's not yet clear why Jacoco generates different formats for unit and instrumented or how to combine the two reports

