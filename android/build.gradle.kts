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
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val fixNamespace = {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            val name = project.name.replace("-", "_").replace(".", "_")
            android.namespace = "com.$name"
        }
    }

    pluginManager.withPlugin("com.android.application") { fixNamespace() }
    pluginManager.withPlugin("com.android.library") { fixNamespace() }
    pluginManager.withPlugin("com.android.dynamic-feature") { fixNamespace() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
