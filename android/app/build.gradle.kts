// we should remove this when our build is a little better (and add more linting and make warnings errors!)
tasks.whenTaskAdded {
    if (this.name.startsWith("lint")) {
        this.enabled = false
    }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("de.mannodermaus.android-junit5")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}


secrets {
    // To add your Maps API key to this project:
    // 1. If the secrets.properties file does not exist, create it in the same folder as the local.properties file.
    // 2. Add this line, where YOUR_API_KEY is your API key:
    //        MAPS_API_KEY=YOUR_API_KEY
    propertiesFileName = "secrets.properties"

    // A properties file containing default secret values. This file can be
    // checked in version control.
    defaultPropertiesFileName = "local.defaults.properties"
}


android {
    packaging {
        resources.excludes.addAll(setOf("META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/license.txt", "META-INF/NOTICE", "META-INF/NOTICE.txt", "META-INF/notice.txt", "META-INF/ASL2.0", "META-INF/*.kotlin_module", "META-INF/*"))
    }

    // Note that these versions must be kept in sync with the versions in OpenCV"s build.gradle. pull out variables
    compileSdk = 35
    defaultConfig {
        testInstrumentationRunnerArguments["runnerBuilder"] = "de.mannodermaus.junit5.AndroidJUnit5Builder"
        applicationId = "com.thebluefolderproject.leafbyte"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "0.1"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true

        manifestPlaceholders["appAuthRedirectScheme"] = "com.thebluefolderproject.leafbyte"

        //buildConfigField("String", "GOOGLE_SIGN_IN_CLIENT_ID", secretProperties["googleSignInClientId"])

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    namespace = "com.thebluefolderproject.leafbyte"

    kotlin {
        jvmToolchain(17)
    }

    tasks.withType<Test> {
        useJUnitPlatform()
        reports.junitXml.required.set(true)
    }
    buildFeatures {
        buildConfig = true
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.legacy:legacy-support-v4:1.0.0")
    implementation("androidx.lifecycle:lifecycle-extensions:2.2.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.6")
    implementation("androidx.navigation:navigation-fragment-ktx:2.8.1")
    implementation("androidx.navigation:navigation-ui-ktx:2.8.1")
    implementation("androidx.preference:preference-ktx:1.2.1")
    implementation("com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava") // HACKHACK: https://stackoverflow.com/questions/56639529/duplicate-class-com-google-common-util-concurrent-listenablefuture-found-in-modu
    implementation("com.google.android.material:material:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.0.0") //pull kotlin version back out
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("com.google.apis:google-api-services-sheets:v4-rev581-1.25.0")
    implementation("com.google.http-client:google-http-client-gson:1.44.2")
    implementation("com.google.api-client:google-api-client-android:2.6.0") {
        exclude(group = "org.apache.httpcomponents")
    }
    implementation("com.google.apis:google-api-services-drive:v3-rev136-1.25.0") {
        exclude(group = "org.apache.httpcomponents")
    }
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    implementation(project(path = ":openCVLibrary343"))
    implementation("net.openid:appauth:0.11.1")

    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("de.mannodermaus.junit5:android-test-core:1.3.0")
    androidTestRuntimeOnly("de.mannodermaus.junit5:android-test-runner:1.3.0")
    androidTestImplementation("com.android.support.test:rules:1.0.2")
    androidTestImplementation("org.junit.jupiter:junit-jupiter:5.10.2")

    androidTestImplementation("de.mannodermaus.junit5:android-test-compose:1.4.0")
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.7.2")

    testImplementation("org.junit.jupiter:junit-jupiter:5.10.2")

    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.2") // For testing coroutines (optional)
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.2") // For testing Android components with coroutines (optional)
}