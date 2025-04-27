buildscript {
    repositories {
        google()  // Asegúrate de tener este repositorio para los servicios de Google
        mavenCentral()
    }
    dependencies {
        // Utilizamos 'classpath' para agregar las dependencias en Kotlin DSL
        classpath("com.android.tools.build:gradle:7.4.1")  // Asegúrate de que esta línea esté correcta para tu versión de Gradle
        classpath("com.google.gms:google-services:4.3.15")  // Aquí agregamos el classpath para google-services
        //classpath("com.android.tools.build:gradle:8.6.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ajustamos la configuración del directorio de build
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Configuración para limpiar el directorio de build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
