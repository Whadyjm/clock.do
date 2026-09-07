allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    if (project.name != "app") {
        val applyNamespace = {
            if (project.hasProperty("android")) {
                val androidExt = project.extensions.findByName("android")
                if (androidExt != null) {
                    try {
                        val getNs = androidExt.javaClass.getMethod("getNamespace")
                        val currentNs = getNs.invoke(androidExt)
                        if (currentNs == null) {
                            val setNs = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                            val targetNs = if (project.name == "device_calendar") {
                                "com.builttoroam.devicecalendar"
                            } else {
                                project.group.toString().takeIf { it.isNotEmpty() && it != "unspecified" }
                                    ?: "com.example.${project.name.replace('-', '_')}"
                            }
                            setNs.invoke(androidExt, targetNs)
                        }
                    } catch (_: Exception) {
                        // Ignore if method not present
                    }
                }
            }
        }

        if (project.state.executed) {
            applyNamespace()
        } else {
            project.afterEvaluate {
                applyNamespace()
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
