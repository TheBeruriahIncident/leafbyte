import com.google.protobuf.gradle.id
import com.google.protobuf.gradle.proto
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("de.mannodermaus.android-junit5")
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
    id("se.patrikerdes.use-latest-versions")
    id("com.github.ben-manes.versions").version("0.51.0") // Adds dependencyUpdates command to determinate stale dependencies
    id("se.ascp.gradle.gradle-versions-filter").version("0.1.16") // Makes version plugin understand which tags are stable
    id("com.autonomousapps.dependency-analysis")
    id("org.jlleitschuh.gradle.ktlint")
    id("io.gitlab.arturbosch.detekt")
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.0"
    id("com.google.protobuf")
    id("jacoco")
}

junitPlatform.jacocoOptions
// junitPlatform.enableStandardTestTask true

jacoco {
    toolVersion = "0.8.12"
//    applyTo(Task)
//    applyTo(junitPlatformTest)
}
jacoco.apply {
    toolVersion = "0.8.12"
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
        artifact = "com.google.protobuf:protoc:4.29.3"
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
                "META-INF/DEPENDENCIES", "META-INF/LICENSE", "META-INF/LICENSE.txt", "META-INF/license.txt", "META-INF/NOTICE",
                "META-INF/NOTICE.txt", "META-INF/notice.txt", "META-INF/ASL2.0", "META-INF/*.kotlin_module", "META-INF/*",
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
    compileSdk = 35
    defaultConfig {
        manifestPlaceholders += mapOf()
        testInstrumentationRunnerArguments += mapOf()
        testInstrumentationRunnerArguments["runnerBuilder"] = "de.mannodermaus.junit5.AndroidJUnit5Builder"
        applicationId = "com.thebluefolderproject.leafbyte"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "0.1"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
        multiDexEnabled = true

        manifestPlaceholders["appAuthRedirectScheme"] = "com.thebluefolderproject.leafbyte"

        // buildConfigField("String", "GOOGLE_SIGN_IN_CLIENT_ID", secretProperties["googleSignInClientId"])

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

//        java {
//           testCoverage {
//               jacocoVersion = "0.8.12"
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
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.constraintlayout:constraintlayout:2.2.0")
    implementation("androidx.core:core-ktx:1.15.0")
    // implementation("androidx.legacy:legacy-support-v4:1.0.0")
    implementation("androidx.lifecycle:lifecycle-extensions:2.2.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
    implementation("androidx.navigation:navigation-fragment-ktx:2.8.6")
    implementation("androidx.constraintlayout:constraintlayout-compose:1.1.0")
    implementation("androidx.datastore:datastore:1.1.2")
    implementation("androidx.fragment:fragment-ktx:1.8.5")
    implementation("androidx.navigation:navigation-common:2.8.6")
    implementation("androidx.navigation:navigation-runtime-ktx:2.8.6")
    implementation("org.jetbrains.kotlinx:kotlinx-collections-immutable:0.3.8")
//    implementation("androidx.navigation:navigation-ui-ktx:2.8.1")
    implementation("androidx.preference:preference-ktx:1.2.1")
//    implementation("com.google.guava:listenablefuture:9999.0-empty-to-avoid-conflict-with-guava") // HACKHACK: https://stackoverflow.com/questions/56639529/duplicate-class-com-google-common-util-concurrent-listenablefuture-found-in-modu
    // implementation("com.google.android.material:material:1.12.0")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.1.10") // pull kotlin version back out
    implementation("com.google.android.gms:play-services-auth:21.3.0")
//    implementation("com.google.apis:google-api-services-sheets:v4-rev20240826-2.0.0")
//    implementation("com.google.http-client:google-http-client-gson:1.45.0")
//    implementation("com.google.api-client:google-api-client-android:2.7.0") {
//        exclude(group = "org.apache.httpcomponents")
//    }
//    implementation("com.google.apis:google-api-services-drive:v3-rev20240914-2.0.0") {
//        exclude(group = "org.apache.httpcomponents")
//    }

    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.7.6")
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.7.7")

//    compileOnly("org.apache.tomcat:annotations-api:6.0.53") // protobuf uses deprecated @Generated
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
    implementation(project(path = ":openCVLibrary343"))
    implementation("net.openid:appauth:0.11.1")
    // implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("androidx.activity:activity-compose:1.10.0")
    implementation(platform("androidx.compose:compose-bom:2025.01.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    androidTestImplementation(platform("androidx.compose:compose-bom:2025.01.01"))
    // androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("io.mockk:mockk-dsl:1.13.16")
    androidTestImplementation("io.mockk:mockk:1.13.16")
    implementation("androidx.activity:activity-ktx:1.10.0")
    implementation("androidx.compose.foundation:foundation-layout:1.7.7")
    implementation("androidx.compose.foundation:foundation:1.7.7")
    implementation("androidx.compose.runtime:runtime:1.7.7")
    implementation("androidx.compose.ui:ui-text:1.7.7")
    implementation("androidx.compose.ui:ui-unit:1.7.7")

    androidTestImplementation("androidx.compose.ui:ui-geometry:1.7.7")
    androidTestImplementation("androidx.compose.ui:ui-test:1.7.7")
    implementation("androidx.annotation:annotation:1.9.1")
    implementation("androidx.lifecycle:lifecycle-common:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // ktlintRuleset("io.nlopez.compose.rules:ktlint:0.4.12")
    androidTestRuntimeOnly("io.mockk:mockk-android:1.13.16")

    androidTestImplementation("com.android.support.test.uiautomator:uiautomator-v18:2.1.3")
    implementation("me.saket.telephoto:zoomable:0.14.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.6.1")
    // androidTestImplementation("androidx.test:runner:1.6.2")
    // androidTestImplementation("de.mannodermaus.junit5:android-test-core:1.6.0")
    androidTestRuntimeOnly("de.mannodermaus.junit5:android-test-runner:1.6.0")
    androidTestImplementation("com.android.support.test:rules:1.0.2")
    androidTestImplementation("org.junit.jupiter:junit-jupiter-api:5.11.4")

    androidTestImplementation("androidx.test:core:1.6.1")

    implementation("androidx.datastore:datastore-core:1.1.2")
    implementation("com.google.protobuf:protobuf-javalite:4.29.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.10.1")

    // androidTestImplementation("de.mannodermaus.junit5:android-test-compose:1.6.0")
    // debugImplementation("androidx.compose.ui:ui-test-manifest:1.7.7")

    implementation("androidx.compose.animation:animation-core:1.7.7")
    testImplementation("org.jetbrains.kotlin:kotlin-test:2.1.10")
    androidTestImplementation("org.jetbrains.kotlin:kotlin-test:2.1.10")

    testImplementation("org.junit.jupiter:junit-jupiter-api:5.11.4")
    // testImplementation("org.jetbrains.kotlin:kotlin-test-junit:2.1.0")

    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.1")
    debugImplementation("androidx.compose.ui:ui-tooling")
    // debugImplementation("androidx.compose.ui:ui-test-manifest") // For testing coroutines (optional)
    // testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0") // For testing Android components with coroutines (optional)
}
