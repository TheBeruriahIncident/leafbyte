include(":app")
include(":openCVLibrary343")

plugins {
    // we need this so the build on Renovate Bot's machines will download Java
    // version catalog doesn't seem to work for convention plugins
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}
