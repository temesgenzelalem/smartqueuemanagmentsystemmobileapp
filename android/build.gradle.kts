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

// Global fix for AGP 8+ requirements in older plugins
subprojects {
    val patchNamespace = Action<Project> {
        if (hasProperty("android")) {
            val android = extensions.getByName("android") as com.android.build.gradle.BaseExtension
            
            // Force namespace if missing (required for modern AGP)
            if (android.namespace == null) {
                android.namespace = "com.smartqueue.patch." + name.replace("-", ".")
            }
        }
    }

    if (state.executed) {
        patchNamespace.execute(this)
    } else {
        afterEvaluate { patchNamespace.execute(this) }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
