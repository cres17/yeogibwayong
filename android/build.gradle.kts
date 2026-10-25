allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// usage_stats 1.3.1 still declares SDK 30; AndroidX resources require API 31+.
// Finalize its DSL with the application's SDK without modifying the pub cache.
subprojects {
    plugins.withId("com.android.library") {
        if (project.name == "usage_stats") {
            extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension>("androidComponents") {
                finalizeDsl { library -> library.compileSdk = 36 }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
