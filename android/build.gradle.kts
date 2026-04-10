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
    pluginManager.withPlugin("com.android.library") {
        val extension = extensions.findByName("android")
        if (extension != null) {
            val namespaceProperty = extension::class.members.find { it.name == "namespace" }
            if (namespaceProperty != null && (extension as com.android.build.gradle.BaseExtension).namespace == null) {
                if (project.name == "flutter_wear_os_connectivity") {
                    (extension as com.android.build.gradle.BaseExtension).namespace = "com.flutter_wear_os_connectivity"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
