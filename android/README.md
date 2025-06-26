# LeafByte on Android

In development.

Android Studio is the recommended development environment.
Open the android folder in Android Studio.
You'll need to install the development kit (NDK) within Android Studio.
You should then be able to run the app in a simulator.

Before the app can run with Google Sign-In/Google Drive, you must copy local.defaults.properties to secrets.properties and fill in GOOGLE_SIGN_IN_CLIENT_ID.
(You can skip this process if you're not building a release, and you're ok with Google Sign-In not working during development)
If you're part of the core LeafByte development team, replace the whole file with the version from leafbyte.app@gmail.com's Google Drive.
If you're an outside contributor (welcome! 😊), you can generate an Android-type client id using [Google's guide](https://support.google.com/cloud/answer/6158849?hl=en) .
If you run into any issues, reach out to <leafbyte@zoegp.science>, and we'd be happy to help!

In order to be able to publish releases, you must add a keystore.
You can follow [Google's guide](https://developer.android.com/studio/publish/app-signing#generate-key) or manually run `keytool -genkey -v -keystore keystore.p12 -alias LeafByte -keyalg RSA -keysize 3072 -validity 365000`.
To see your created keystore, run `keytool -keystore .\keystore.p12 -v -list`.

Some useful commands:
- `./gradlew useLatestVersions versionCatalogUpdate` to update dependencies
- `./gradlew dependencies :app:dependencies --write-locks` updates the lock file after changing dependencies.
- `./gradlew buildHealth` to check for dependency issues
- `./gradlew ktlintFormat` to check for ktlint issues and auto-format
- `./gradlew detektMain detektTest detektDebugAndroidTest` to check for detekt issues (running just `./gradlew detekt` is not 
    classpath-aware and thus can't run some checks)
- `./gradlew check` runs all non-instrumented checks
- `./gradlew connectedCheck` runs all instrumented checks
- `./gradlew ktlintFormat buildHealth detektMain detektTest detektDebugAndroidTest` to quickly apply automated fixes and
   do fast checking (does not run any tests)
- `./gradlew check connectedCheck lintVitalRelease` to mostly confirm that the CI build will pass (I have no idea why lintVitalRelease once
    caught something that normal lint didn't)

Regarding Renovate Bot:
- See the dashboard as a GitHub issue at https://github.com/TheBeruriahIncident/leafbyte/issues/195
- See the dashboard on Mend's website, including Renovate logs, at https://developer.mend.io/github/TheBeruriahIncident/leafbyte
- We switched from Dependabot to Renovate Bot because Dependabot became unusable
  (It incorrectly accumulated dependencies in its persistent list of dependencies to ignore with no way to clear the list.
   There are various open tickets about this, e.g. https://github.com/dependabot/dependabot-core/issues/9920)

Regarding code coverage reports:
- To check coverage from unit tests, run `./gradlew jacocoTestReport` and find the report at `- app/build/outputs/unit_test_code_coverage/debugUnitTest/testDebugUnitTest.exec`
- To check coverage from instrumented tests, run `./gradlew connectedCheck` and find the report at `- app/build/reports/coverage/androidTest/debug/connected/report.xml`
- Either file can be opened in Android Studio with "Import External Coverage Report..."
- It's not yet clear why Jacoco generates different formats for unit and instrumented or how to combine the two reports

