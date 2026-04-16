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

// Fix Namespace ultra-aggressivo per compatibilità AGP 8+
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            android.namespace = "com." + project.name.replace("-", "_").replace(".", "_")
        }
    }
}

// Spostato in fondo per evitare conflitti di valutazione
subprojects {
    if (project.name != "app") {
        // Rimuoviamo la dipendenza forzata che causava l'errore 'already evaluated'
        // project.evaluationDependsOn(":app") 
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
