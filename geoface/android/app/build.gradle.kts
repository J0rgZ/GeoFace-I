plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// PASO 1: AÑADIDO
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use {
        keystoreProperties.load(it)
    }
    // Debug: verificar que se cargaron las propiedades
    println("DEBUG: Propiedades cargadas:")
    println("  storeFile: '${keystoreProperties["storeFile"]}'")
    println("  keyAlias: '${keystoreProperties["keyAlias"]}'")
    println("  storePassword: '${if (keystoreProperties["storePassword"] != null) "***" else "null"}'")
    println("  keyPassword: '${if (keystoreProperties["keyPassword"] != null) "***" else "null"}'")
} else {
    // Si no existe key.properties, intentar usar variables de entorno o valores por defecto
    println("WARNING: key.properties no encontrado. El build de release fallará sin configuración de firma.")
}


android {
    namespace = "com.caeltek.geoface"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.caeltek.geoface"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // PASO 2: AÑADIDO
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                val keyAliasValue = keystoreProperties["keyAlias"] as String?
                val keyPasswordValue = keystoreProperties["keyPassword"] as String?
                val storePasswordValue = keystoreProperties["storePassword"] as String?
                val storeFilePath = keystoreProperties["storeFile"] as String?
                
                if (keyAliasValue != null && keyPasswordValue != null && 
                    storePasswordValue != null && storeFilePath != null) {
                    keyAlias = keyAliasValue
                    keyPassword = keyPasswordValue
                    // El keystore puede estar en android/app/ o en la raíz del proyecto
                    val keystoreFile = if (storeFilePath.startsWith("../")) {
                        // Si la ruta empieza con ../, es relativa desde android/
                        rootProject.file(storeFilePath)
                    } else {
                        // Si no, asumimos que está en android/app/
                        rootProject.file("app/$storeFilePath")
                    }
                    if (keystoreFile.exists()) {
                        storeFile = keystoreFile
                        storePassword = storePasswordValue
                    } else {
                        throw GradleException("El archivo keystore no se encuentra en: ${keystoreFile.absolutePath}")
                    }
                } else {
                    throw GradleException("key.properties está incompleto. Verifica que tenga keyAlias, keyPassword, storePassword y storeFile")
                }
            } else {
                throw GradleException("key.properties no encontrado en android/. Crea el archivo siguiendo el template en android/key.properties.template")
            }
        }
    }

    // PASO 3: MODIFICADO
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
