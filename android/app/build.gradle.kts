import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadProperties = Properties()
val uploadPropertiesFile = rootProject.file("key.properties")
if (uploadPropertiesFile.exists()) {
    uploadPropertiesFile.inputStream().use { uploadProperties.load(it) }
}
fun uploadValue(property: String, environment: String): String? =
    System.getenv(environment)?.takeIf { it.isNotBlank() }
        ?: uploadProperties.getProperty(property)?.takeIf { it.isNotBlank() }

val uploadStore = uploadValue("storeFile", "REDBOX_STORE_FILE")
val uploadStorePassword = uploadValue("storePassword", "REDBOX_STORE_PASSWORD")
val uploadAlias = uploadValue("keyAlias", "REDBOX_KEY_ALIAS")
val uploadKeyPassword = uploadValue("keyPassword", "REDBOX_KEY_PASSWORD")
val hasUploadSigning = listOf(uploadStore, uploadStorePassword, uploadAlias, uploadKeyPassword)
    .all { it != null }

android {
    namespace = "com.sutechs.redbox"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.sutechs.redbox"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadSigning) {
            create("upload") {
                storeFile = rootProject.file(uploadStore!!)
                storePassword = uploadStorePassword
                keyAlias = uploadAlias
                keyPassword = uploadKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasUploadSigning) signingConfig = signingConfigs.getByName("upload")
        }
    }
}

// Never let a missing upload key silently produce a debug-signed store release.
val verifyUploadSigning = tasks.register("verifyUploadSigning") {
    doLast {
        check(hasUploadSigning) {
            "Red Box release signing is missing. Configure android/key.properties " +
                "or REDBOX_STORE_FILE, REDBOX_STORE_PASSWORD, REDBOX_KEY_ALIAS and REDBOX_KEY_PASSWORD."
        }
        check(rootProject.file(uploadStore!!).isFile) { "Upload keystore file was not found." }
        check(!uploadAlias.equals("androiddebugkey", ignoreCase = true)) {
            "The Android debug key cannot be used for a store release."
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyUploadSigning)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
