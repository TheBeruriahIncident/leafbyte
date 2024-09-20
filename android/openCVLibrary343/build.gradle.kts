// we should probably update this library


// don't lint their code
tasks.whenTaskAdded {
    if (this.name.startsWith("lint")) {
        this.enabled = false
    }
}

plugins {
    id("com.android.library")
}

android {
    // Note that these versions must be kept in sync with the versions in the main build.gradle
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        //targetSdk = 35
    }

    buildTypes {
        release {
            isMinifyEnabled = false // should this be true?
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.txt")
        }
    }
    buildFeatures {
        aidl = true
        buildConfig = true
    }
    namespace = "org.opencv"
}
