// Top-level build file where you can add configuration options common to all sub-projects/modules.

buildscript {
    // ext.kotlin_version = "2.0.0"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.12.1")
        classpath("de.mannodermaus.gradle.plugins:android-junit5:1.13.1.0")
        classpath("com.google.android.libraries.mapsplatform.secrets-gradle-plugin:secrets-gradle-plugin:2.0.1")
        classpath("nl.littlerobots.vcu:plugin:1.0.0")
        // NOTE: Do not place your application dependencies here; they belong
        // in the individual module build.gradle files
    }

    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.github.ben-manes.versions").version("0.52.0") // Adds dependencyUpdates command to determinate stale dependencies
    id("se.ascp.gradle.gradle-versions-filter").version("0.1.16") // Makes version plugin understand which tags are stable
    id(
        "se.patrikerdes.use-latest-versions",
    ).version(
        "0.2.18",
    ) // Adds useLatestVersions command to update dependencies // TODO: delete this and the two it builds on after moving to version catalog
    id("nl.littlerobots.version-catalog-update").version("1.0.0")
    alias(libs.plugins.dependencyAnalysis)
    id("org.jlleitschuh.gradle.ktlint").version("12.3.0")
    id("io.gitlab.arturbosch.detekt").version("1.23.8")
    alias(libs.plugins.kotlin.gradle) apply false
    alias(libs.plugins.kotlin.compose) apply false
    id("com.google.protobuf") version "0.9.5" apply false
    id("jacoco")
}

dependencyAnalysis {
    issues {
        all {
            onAny {
                severity("fail")
                // no idea where "de.mannodermaus.junit5:android-test-core:1.6.0" or de.mannodermaus.junit5:android-test-compose:1.5.0 is coming from
                // androidx.lifecycle:lifecycle-viewmodel and ""-ktx should get ignoreKtx
                // "androidx.navigation:navigation-fragment-ktx used in xml
                exclude(
                    "de.mannodermaus.junit5:android-test-core",
                    "androidx.lifecycle:lifecycle-viewmodel",
                    "androidx.lifecycle:lifecycle-viewmodel-ktx",
                    "androidx.navigation:navigation-fragment-ktx",
                    "de.mannodermaus.junit5:android-test-compose",
                    // needed through some compose magic
                    "androidx.compose.ui:ui-test-manifest",
                )
            }
        }
    }
    structure {
        ignoreKtx(true)
    }
}

tasks.register("clean", Delete::class) {
    delete(layout.buildDirectory)
}

tasks.register("testClasses") // https://stackoverflow.com/questions/36465824/android-studio-task-testclasses-not-found-in-project
