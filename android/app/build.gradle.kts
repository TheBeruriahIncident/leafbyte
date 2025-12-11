/*
 * Copyright © 2019 Abigail Getman-Pickering. All rights reserved.
 */

import com.google.protobuf.gradle.id
import com.google.protobuf.gradle.proto
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    id("com.android.application")
    alias(libs.plugins.kotlin.gradle)
    id("de.mannodermaus.android-junit5")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
    id("se.patrikerdes.use-latest-versions")
    id("com.github.ben-manes.versions").version("0.53.0") // Adds dependencyUpdates command to determinate stale dependencies
    id("se.ascp.gradle.gradle-versions-filter").version("0.1.16") // Makes version plugin understand which tags are stable
    id("com.autonomousapps.dependency-analysis")
    id("org.jlleitschuh.gradle.ktlint")
    id("io.gitlab.arturbosch.detekt")
    alias(libs.plugins.kotlin.compose)
    id("com.google.protobuf")
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
        artifact = "com.google.protobuf:protoc:4.33.1"
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
                "runnerBuilder" to "de.mannodermaus.junit5.AndroidJUnit5Builder",
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
    implementation("androidx.compose.animation:animation:1.10.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:1.9.0")
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    implementation(libs.activity.compose)
    implementation(libs.activity.ktx)
    implementation(libs.annotation)
    implementation(libs.appauth)
    implementation(libs.appcompat)
    implementation(libs.collections)
    implementation(libs.compose.animation)
    implementation(libs.compose.foundation)
    implementation(libs.compose.foundationLayout)
    implementation(libs.compose.material3)
    implementation(libs.compose.runtime)
    implementation(libs.compose.ui)
    implementation(libs.compose.uiGraphics)
    implementation(libs.compose.uiText)
    implementation(libs.compose.uiToolingPreview)
    implementation(libs.compose.uiUnit)
    implementation(libs.constraintlayout.compose)
    implementation(libs.core)
    implementation(libs.coroutines.core)
    implementation(libs.datastore)
    implementation(libs.datastore.core)
    implementation(libs.deprecated.navigation.fragment)
    implementation(libs.kotlin.stdlib)
    implementation(libs.lifecycle.common)
    implementation(libs.lifecycle.runtimeCompose)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.navigation.runtime)
    implementation(libs.navigation.ui)
    implementation(libs.play.auth)
    implementation(libs.preference)
    implementation(libs.protobuf.javalite)
    implementation(libs.telephoto.zoomable)
    implementation(platform(libs.compose.bom))
    implementation(project(path = ":openCVLibrary343"))

    testImplementation(libs.coroutines.test)
    testImplementation(libs.junit5.api)
    testImplementation(libs.kotlin.test)

    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation("androidx.test.espresso:espresso-intents:3.7.0")
    androidTestImplementation("androidx.test:core:1.7.0")
    androidTestImplementation(libs.compose.uiGeometry)
    androidTestImplementation(libs.compose.uiTest)
    androidTestImplementation(libs.hamcrest)
    androidTestImplementation(libs.junit5.api)
    androidTestImplementation(libs.kotlin.test)
    androidTestImplementation(libs.mockk)
    androidTestImplementation(libs.mockk.dsl)
    androidTestImplementation(platform(libs.compose.bom))
    androidTestRuntimeOnly("de.mannodermaus.junit5:android-test-runner:1.9.0") // TODO: why does using libs.junit5.test resolve differently
    androidTestRuntimeOnly(libs.mockk.android)
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.10.0")
    debugImplementation(libs.compose.uiTooling)

    // ktlintRuleset("io.nlopez.compose.rules:ktlint:0.4.12")
    //    implementation("com.google.apis:google-api-services-sheets:v4-rev20240826-2.0.0")
    //    implementation("com.google.http-client:google-http-client-gson:1.45.0")
    //    implementation("com.google.api-client:google-api-client-android:2.7.0") {
    //        exclude(group = "org.apache.httpcomponents")
    //    }
    //    implementation("com.google.apis:google-api-services-drive:v3-rev20240914-2.0.0") {
    //        exclude(group = "org.apache.httpcomponents")
    //    }
}
