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

subprojects {
    afterEvaluate {
        val extension = extensions.findByName("android")
        if (extension != null) {
            val namespaceProperty = extension::class.members.find { it.name == "namespace" }
            if (namespaceProperty != null && (extension as com.android.build.gradle.BaseExtension).namespace == null) {
                // Infer namespace from the package in AndroidManifest.xml if needed, 
                // but usually fixed by setting it explicitly to the plugin id
                val pluginId = project.name
                if (pluginId == "flutter_wear_os_connectivity") {
                    (extension as com.android.build.gradle.BaseExtension).namespace = "com.flutter_wear_os_connectivity"
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
