/*
 * Copyright © 2019 Abigail Getman-Pickering. All rights reserved.
 */

import com.google.protobuf.gradle.id
import com.google.protobuf.gradle.proto
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    id("com.android.application")
    alias(libs.plugins.kotlin.gradle)
    alias(libs.plugins.android.junit)
//    alias(libs.plugins.secrets)
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
    alias(libs.plugins.dependencyAnalysis)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.detekt)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.protobuf)
    id("jacoco")
}

junitPlatform.jacocoOptions
// junitPlatform.enableStandardTestTask true

jacoco {
    toolVersion = "0.8.14" // N.B. Android Gradle Plugin overrides our version, unclear if that's a bug on them
//    applyTo(Task)
//    applyTo(junitPlatformTest)
}
jacoco.apply {
    toolVersion = "0.8.13"
    reportsDirectory = file("${layout.buildDirectory}/reports")
}

// jacocoTestReport {
//    reports {
//        xml.enabled = true
//        html.enabled = true
//    }
// }

protobuf {
    protoc {
        artifact = "com.google.protobuf:protoc:${libs.protobuf.get().version}"
    }
    generateProtoTasks {
        all().forEach { task ->
            task.plugins {
                id("java") {
                    option("lite")
                    // Adds @javax.annotation.Generated annotation to the generated code for tooling like Jacoco
                    option("annotate_code")
                }
            }
        }
    }
}

detekt {
    config.setFrom("$rootDir/detekt-config.yml")
    buildUponDefaultConfig = true
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
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        resources.excludes.addAll(
            setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0",
                "META-INF/*.kotlin_module",
                "META-INF/*",
            ),
        )
    }

    sourceSets {
        named("main") {
            proto {
                srcDir("src/main/proto")
            }
        }
    }

    // Note that these versions must be kept in sync with the versions in OpenCV"s build.gradle. pull out variables
    compileSdk = 36
    defaultConfig {
        manifestPlaceholders += mapOf("appAuthRedirectScheme" to "com.thebluefolderproject.leafbyte")
        testInstrumentationRunnerArguments +=
            mapOf(
                "runnerBuilder" to "de.mannodermaus.junit5.AndroidJUnitFrameworkBuilder",
                "clearPackageData" to "true",
            )
        applicationId = "com.thebluefolderproject.leafbyte"
        minSdk = 23
        targetSdk = 36
        versionCode = 1
        versionName = "0.1"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        multiDexEnabled = true

        // buildConfigField("String", "GOOGLE_SIGN_IN_CLIENT_ID", secretProperties["googleSignInClientId"])

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

//        java {
//           testCoverage {
//               jacocoVersion = "0.8.13"
//
//           }
//        }
//        debug {
//            enableUnitTestCoverage true
//        }
    }
    testOptions {
        animationsDisabled = true
        unitTests {
            isIncludeAndroidResources = true
        }
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            enableUnitTestCoverage = true
            enableAndroidTestCoverage = true

            isMinifyEnabled = false
        }
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    namespace = "com.thebluefolderproject.leafbyte"

    kotlin {
        jvmToolchain(17)
    }

    tasks.withType<JacocoReport> {
        reports {
            csv.required = true
            xml.required = true
            html.required = true
        }
    }

    tasks.withType<Test> {
        useJUnitPlatform()
        reports.junitXml.required.set(true)
        testLogging {
            exceptionFormat = TestExceptionFormat.FULL
        }
    }

    tasks.named("check") {
        dependsOn("detektMain")
        dependsOn("detektTest")
        dependsOn("detektDebugAndroidTest")
    }

    buildFeatures {
        buildConfig = true
        compose = true
    }
//    compileOptions {
//        sourceCompatibility = JavaVersion.VERSION_1_8
//        targetCompatibility = JavaVersion.VERSION_1_8
//    }
//    kotlinOptions {
//        jvmTarget = "1.8"
//    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.15"
    }
}

configurations {
    all {
        exclude(group = "androidx.compose.ui", module = "ui-test-junit4") // use junit 5

        resolutionStrategy {
            eachDependency {
                val hamcrest = libs.hamcrest.get()
                if ((requested.group == hamcrest.group)) {
                    // prevent Espresso from bringing in Junit 4's ancient Hamcrest and causing duplicate class errors
                    useVersion(hamcrest.version!!)
                }
            }
        }
    }
}

dependencies {
    val implementationDeps =
        listOf(
            fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))),
            libs.activity.compose,
            libs.activity.ktx,
            libs.android.core,
            libs.annotation,
            libs.appauth,
            libs.appcompat,
            libs.collections,
            libs.compose.animation,
            libs.compose.animationCore,
            libs.compose.foundation,
            libs.compose.foundationLayout,
            libs.compose.googleFonts,
            libs.compose.material3,
            libs.compose.runtime,
            libs.compose.ui,
            libs.compose.uiGraphics,
            libs.compose.uiText,
            libs.compose.uiToolingPreview,
            libs.compose.uiUnit,
            libs.constraintlayout,
            libs.coroutines,
            libs.datastore,
            libs.datastore.core,
            libs.kotlin.serialization,
            libs.kotlin.stdlib,
            libs.lifecycle.common,
            libs.lifecycle.runtimeCompose,
            libs.lifecycle.viewmodel,
            libs.navigation.runtime,
            libs.navigation.ui,
            libs.protobuf,
            libs.zoomable,
            platform(libs.compose.bom),
            project(path = ":openCVLibrary343"),
        )
    val debugImplementationDeps =
        listOf(
            libs.compose.uiTestManifest,
            libs.compose.uiTooling,
        )
    implementationDeps.forEach { implementation(it) }
    debugImplementationDeps.forEach { debugImplementation(it) }

    val testImplementationDeps =
        listOf(
            libs.coroutines.test,
            libs.junit,
            libs.kotlin.test,
        )
    val androidTestImplementationDeps =
        listOf(
            libs.android.test,
            libs.compose.uiGeometry,
            libs.compose.uiTest,
            libs.espresso,
            libs.espresso.intents,
            libs.hamcrest,
            libs.junit,
            libs.kotlin.test,
            libs.mockk,
            libs.mockk.core,
            libs.mockk.dsl,
            platform(libs.compose.bom),
        )
    val androidTestRuntimeOnlyDeps =
        listOf(
            libs.android.junit,
            libs.mockk.android,
        )
    testImplementationDeps.forEach { testImplementation(it) }
    androidTestImplementationDeps.forEach { androidTestImplementation(it) }
    androidTestRuntimeOnlyDeps.forEach { androidTestRuntimeOnly(it) }
}
