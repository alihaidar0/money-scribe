import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Needs android/app/src/<flavor>/google-services.json for the flavor being built
    // (gitignored; CI writes it from the environment's secret). See docs/environments.md.
    id("com.google.gms.google-services")
}

// Release signing, one key per environment: `android/key.staging.properties` and
// `android/key.production.properties` (local and gitignored; CI writes the file of
// its environment from that environment's secrets). Without the file of a flavor,
// its release build uses the debug key, so pull requests and a fresh clone still
// build. See docs/android-signing.md.
fun loadKeyProperties(fileName: String): Properties? {
    val file = rootProject.file(fileName)
    if (!file.exists()) return null
    return Properties().also { properties ->
        FileInputStream(file).use { properties.load(it) }
    }
}

val stagingKeyProperties = loadKeyProperties("key.staging.properties")
val productionKeyProperties = loadKeyProperties("key.production.properties")

android {
    namespace = "com.alihaidar.money_scribe"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.alihaidar.moneyscribe"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        stagingKeyProperties?.let { keys ->
            create("staging") {
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
                storeFile = keys.getProperty("storeFile")?.let { file(it) }
                storePassword = keys.getProperty("storePassword")
            }
        }
        productionKeyProperties?.let { keys ->
            create("production") {
                keyAlias = keys.getProperty("keyAlias")
                keyPassword = keys.getProperty("keyPassword")
                storeFile = keys.getProperty("storeFile")?.let { file(it) }
                storePassword = keys.getProperty("storePassword")
            }
        }
    }

    // Two environments, installable side by side: staging (the develop branch) and
    // production (the main branch). Production keeps the plain application ID. The
    // flavor names match APP_ENV and the GitHub environments. See docs/environments.md.
    flavorDimensions += "default"
    productFlavors {
        create("staging") {
            dimension = "default"
            applicationIdSuffix = ".staging"
            // Staging can be captured, so the screens can be checked.
            buildConfigField("boolean", "SECURE_WINDOW", "false")
            signingConfig =
                signingConfigs.findByName("staging") ?: signingConfigs.getByName("debug")
        }
        create("production") {
            dimension = "default"
            // The window is secure: blank in the recent apps, no screenshots.
            buildConfigField("boolean", "SECURE_WINDOW", "true")
            signingConfig =
                signingConfigs.findByName("production") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
