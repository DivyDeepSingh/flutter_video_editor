import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()         // Make sure this is here
        maven { url = uri("https://jitpack.io") }
    }
}

// Custom build directory (optional)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Set build directories for subprojects
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Ensure app is evaluated first
subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Force FFmpeg Kit version to a valid one
configurations.all {
    resolutionStrategy {
        force("com.arthenica:ffmpeg-kit-full:6.1.0")
        // No need to force ffmpeg-kit-https separately; handled internally
    }
}
