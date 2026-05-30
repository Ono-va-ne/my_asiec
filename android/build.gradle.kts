allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }

    // Force compatible versions of libraries that require AGP 8.9.1+
    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
            force("androidx.activity:activity-ktx:1.9.3")
            force("androidx.activity:activity:1.9.3")
            force("androidx.core:core-ktx:1.15.0")
            force("androidx.core:core:1.15.0")
            // This one is also causing issues
            force("androidx.navigationevent:navigationevent-android:1.0.1")
        }
    }
}

// Добавьте этот блок для исправления ошибки с Lint
subprojects {
    tasks.configureEach {
        if (name.contains("AarMetadata", ignoreCase = true)) {
            enabled = false
        }
    }
}


val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
