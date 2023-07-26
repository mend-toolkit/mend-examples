import java.io.File
import java.io.FileInputStream
import java.util.*

fun readPropertiesFromFile(file: File): Properties? {
	return if (file.exists()) {
		Properties().apply {
			file.inputStream().use { input -> load(input) }
		}
	} else {
		null
	}
}

println("Loading JFROG Repository")
val projectPropertiesFile = File("gradle.properties")
val projectProperties = readPropertiesFromFile(projectPropertiesFile)

val globalPropertiesFile = gradle.gradleUserHomeDir.resolve("gradle.properties")
val globalProperties = readPropertiesFromFile(globalPropertiesFile)

val repositoryUrl = projectProperties?.getProperty("repositoryUrl") ?: globalProperties?.getProperty("repositoryUrl") ?: System.getenv("MAVEN_REGISTRY")
val repositoryUsername = projectProperties?.getProperty("repositoryUsername") ?: globalProperties?.getProperty("repositoryUsername") :? System.getenv("MAVEN_USER")
val repositoryPassword = projectProperties?.getProperty("repositoryPassword") ?: globalProperties?.getProperty("repositoryPassword") :? System.getenv("MAVEN_PASS")

//Should point to a registry with an upstream remote of: https://plugins.gralde.org/m2/	
val pluginRepositoryUrl = projectProperties?.getProperty("pluginRepositoryUrl") ?: globalProperties?.getProperty("pluginRepositoryUrl") :? System.getenv("GRADLE_PLUGIN_REGISTRY")
val pluginRepositoryUsername = projectProperties?.getProperty("pluginRepositoryUsername") ?: globalProperties?.getProperty("pluginRepositoryUsername") :? System.getenv("GRADLE_PLUGIN_USER")
val pluginRepositoryPassword = projectProperties?.getProperty("pluginRepositoryPassword") ?: globalProperties?.getProperty("pluginRepositoryPassword") :? System.getenv("GRADLE_PLUGIN_PASS")

// Plugin repositories section using the same variables
settingsEvaluated { 
	dependencyResolutionManagement {
		repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
		repositories {
			maven {
				url = uri(repositoryUrl.toString())
				credentials {
					username = repositoryUsername.toString()
					password = repositoryPassword.toString()
				}
			}
		}
	}
	pluginManagement {
		repositories {
			maven {
				url = uri(repositoryUrl.toString())
				credentials {
					username = repositoryUsername.toString()
					password = repositoryPassword.toString()
				}
			}
			maven {
				url = uri(pluginRepositoryUrl.toString())
				credentials {
					username = pluginRepositoryUsername.toString()
					password = pluginRepositoryPassword.toString()
				}
			}
		}
	}
}
