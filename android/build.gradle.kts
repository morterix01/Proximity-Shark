// Repositories are managed in settings.gradle.kts to avoid conflicts with FAIL_ON_PROJECT_REPOS

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Spostiamo qui la logica dei namespace PRIMA di ogni altra valutazione
subprojects {
    project.plugins.whenPluginAdded {
        if (this is com.android.build.gradle.api.AndroidBasePlugin) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            if (android.namespace == null) {
                val name = project.name.replace("-", "_").replace(".", "_")
                android.namespace = "com.$name"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
